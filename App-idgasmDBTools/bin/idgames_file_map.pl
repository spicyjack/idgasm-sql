#!/usr/bin/perl -w

# Copyright (c) 2013 by Brian Manning <brian at xaoc dot org>

# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/idgasm-tools/issues

=head1 NAME

B<idgames_file_map.pl> - Build a mapping of filenames to file ID's from the
files stored in C<idGames Archive>.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 perl idgames_file_map.pl [OPTIONS]

 Script options:
 -h|--help          Shows this help text
 -d|--debug         Debug script execution
 --debug-noexit     Don't exit script when --debug is used
 -v|--verbose       Verbose script execution
 -c|--colorize      Always colorize script output

 Other script options:
 -o|--output        The output file to write information to
 -x|--overwrite     Overwrite any existing files used as --output
 --no-random-wait   Don't use random pauses between GET requests

 Example usage:

 # build a database file using the given INI file
 idgames_file_map.pl --output /path/to/output.txt

You can view the full C<POD> documentation of this file by calling C<perldoc
idgames_file_map.pl>.

=cut

our @options = (
    # script options
    q(debug|d),
    q(debug-noexit),
    q(verbose|v),
    q(help|h),
    q(colorize|c), # always colorize output
    # other options

    q(output|o=s),
    q(overwrite|x),
    q(random-wait!),
);

=head1 DESCRIPTION

B<idgames_file_map.pl> - Build a mapping of filenames to file ID's from the
files stored in C<idGames Archive>.

=cut

################
# package main #
################
package main;

# pragmas
use 5.010;
# https://metacpan.org/pod/strictures
use strictures 1;
use utf8;

# system packages
use Carp;
use Config::Std;
use JSON::XS;
use HTTP::Status;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Log::Log4perl::Level;
use LWP::UserAgent;
use Pod::Usage;

# Data::Dumper gets it's own block, cause it has extra baggage
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local packages
use App::idgasmDBTools::Config;

    binmode(STDOUT, ":utf8");
    # create a logger object
    my $cfg = App::idgasmDBTools::Config->new(options => \@options);

    # dump and bail if we get called with --help
    if ( $cfg->defined(q(help)) ) { pod2usage(-exitstatus => 1); }

    # Start setting up the Log::Log4perl object
    my $log4perl_conf = qq(log4perl.rootLogger = WARN, Screen\n);
    if ( $cfg->defined(q(verbose)) && $cfg->defined(q(debug)) ) {
        die(q(Script called with --debug and --verbose; choose one!));
    } elsif ( $cfg->defined(q(debug)) ) {
        $log4perl_conf = qq(log4perl.rootLogger = DEBUG, Screen\n);
    } elsif ( $cfg->defined(q(verbose)) ) {
        $log4perl_conf = qq(log4perl.rootLogger = INFO, Screen\n);
    }

    # Use color when outputting directly to a terminal, or when --colorize was
    # used
    if ( -t STDOUT || $cfg->get(q(colorize)) ) {
        $log4perl_conf .= q(log4perl.appender.Screen )
            . qq(= Log::Log4perl::Appender::ScreenColoredLevels\n);
    } else {
        $log4perl_conf .= q(log4perl.appender.Screen )
            . qq(= Log::Log4perl::Appender::Screen\n);
    }

    $log4perl_conf .= qq(log4perl.appender.Screen.stderr = 1\n)
        . qq(log4perl.appender.Screen.utf8 = 1\n)
        . qq(log4perl.appender.Screen.layout = PatternLayout\n)
        . q(log4perl.appender.Screen.layout.ConversionPattern )
        # %r: number of milliseconds elapsed since program start
        # %p{1}: first letter of event priority
        # %4L: line number where log statement was used, four numbers wide
        # %M{1}: Name of the method name where logging request was issued
        # %m: message
        # %n: newline
        . qq|= [%8r] %p{1} %4L (%M{1}) %m%n\n|;
        #. qq( = %d %p %m%n\n)
        #. qq(= %d{HH.mm.ss} %p -> %m%n\n);

    # create a logger object, and prime the logfile for this session
    Log::Log4perl::init( \$log4perl_conf );
    my $log = get_logger("");

    # check output file before doing any processing
    $log->logdie(qq(Missing '--output' file argument))
        unless ( $cfg->defined(q(output)) );
#    $log->logdie(qq(Can't write output file ) . $cfg->get(q(output)) )
#        unless ( -w $cfg->get(q(output)) );
    $log->logdie(qq(Won't overwrite file) . $cfg->get(q(output))
        . q( without '­-overwrite' option))
        if ( -e $cfg->get(q(output)) && ! $cfg->defined(q(overwrite)) );

    # print a nice banner
    $log->info(qq(Starting idgames_file_map.pl, version $VERSION));
    $log->info(qq(My PID is $$));

    # start at file ID 1, keep going until you get a "error" response instead
    # of a "content" response in the JSON
    # Note: file ID '0' is invalid
    my $file_id = 1;
    my $ua = LWP::UserAgent->new(agent => qq(idgames_file_map.pl $VERSION));
    my $idgames_url = q(http://www.doomworld.com/idgames/api/api.php?);
    $idgames_url .= q(action=get&);
    $idgames_url .= q(out=json&);
    # See https://metacpan.org/pod/LWP#An-Example for a POST example
    GET_JSON: while (1) {
        my $fetch_url =  $idgames_url . qq(id=$file_id);
        $log->debug(qq(Fetching $fetch_url));
        my $req = HTTP::Request->new(GET => $fetch_url);
        my $resp = $ua->request($req);
        if ( $resp->is_success ) {
            #$log->info($resp->content);
            #$log->info(qq(file ID: $file_id; ) . status_message($resp->code));
            my $json = JSON::XS->new->utf8->pretty;
            my $msg = $json->decode($resp->content);
            if ( exists $msg->{content} ) {
                my $content = $msg->{content};
                my $full_path = $content->{dir} . $content->{filename};
                $log->info(status_message($resp->code)
                    . sprintf(q( ID: %5u; ), $file_id)
                    . qq(path: $full_path));
            } elsif ( exists $msg->{error} ) {
                $log->logerr(qq(ID: $file_id; Received error response));
                $log->logerr(Dumper($msg));
            }
        } else {
            $log->info($resp->status_line);
        }
        $file_id++;
        if ( $log->is_debug ) {
            if ( ! $cfg->defined(q(debug-noexit)) && $file_id > 20 ) {
                last GET_JSON;
            }
        }
    }

=cut

=back

=head1 AUTHOR

Brian Manning, C<< <brian at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker for
this project:

C<< <https://github.com/spicyjack/public/issues> >>.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

    perldoc idgames_file_map.pl

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# конец!
# vim: set shiftwidth=4 tabstop=4
