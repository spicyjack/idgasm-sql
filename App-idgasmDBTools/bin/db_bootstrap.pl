#!/usr/bin/perl -w

# Copyright (c) 2013 by Brian Manning <brian at xaoc dot org>

# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/idgasm-sql/issues

=head1 NAME

B<db_bootstrap.pl> - Bootstrap a database that will contain information about
WAD files stored in C<idGames Archive>.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 perl db_bootstrap.pl [OPTIONS]

 Script options:
 -h|--help          Shows this help text
 -d|--debug         Debug script execution
 -v|--verbose       Verbose script execution
 -c|--colorize      Always colorize script output

 Other script options:
 -i|--input         The input file to read information from
 -o|--output        The output file to write information to
 -s|--checksum      Read the --input file, copy with checksums to --output
 -x|--overwrite     Overwrite file specified as --output
 --create-db        Create a database file using the given INI file
 --create-ini       Create an INI file using schema info in database
 --create-yaml      Create a YAML file using schema info in database

 Example usage:

 # build a database file using the given INI file
 db_bootstrap.pl --input /path/to/db.ini --output sample.db --create-db

You can view the full C<POD> documentation of this file by calling C<perldoc
db_bootstrap.pl>.

=cut

our @options = (
    # script options
    q(debug|d),
    q(verbose|v),
    q(help|h),
    q(colorize|c), # always colorize output
    # other options

    q(output|o=s),
    q(input|i=s),
    q(overwrite|x),
    q(checksum|s),
    q(create-db),
    q(create-ini),
    q(create-yaml),
);

=head1 DESCRIPTION

Creates databases using config specified in INI file.

=head1 OBJECTS

=head2 App::idgasmDBTools::Config

An object used for storing configuration data.

=head3 Object Methods

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
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Log::Log4perl::Level;
use Pod::Usage;

# Data::Dumper gets it's own block, cause it has extra baggage
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local packages
use App::idgasmDBTools::Config;
use App::idgasmDBTools::INIFile;

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

    # check input file before doing any processing
    $log->logdie(qq(Missing '--input' file argument))
        unless ( $cfg->defined(q(input)) );
    $log->logdie(qq(Can't read option file ) . $cfg->get(q(input)) )
        unless ( -r $cfg->get(q(input)) );

    # print a nice banner
    $log->info(qq(Starting db_bootstrap.pl, version $VERSION));
    $log->info(qq(My PID is $$));

    my $db_schema;
    my $parser = App::idgasmDBTools::INIFile->new(
        filename => $cfg->get(q(input)));
    if ( $cfg->defined(q(create-db)) ) {
        $log->debug(q(Running as: --create-db));
        if ( $cfg->get(q(input)) =~ /\.ini$/ ) {
            $db_schema = $parser->read_ini_config();
        } else {
            $log->logdie(q(Don't know how to process file )
                . $cfg->get(q(input)));
        }
    } elsif ( $cfg->defined(q(create-yaml)) ) {
    } elsif ( $cfg->defined(q(create-ini)) ) {
    } elsif ( $cfg->defined(q(checksum)) ) {
        $log->debug(q(Running as: --checksum));
        if ( $cfg->get(q(input)) =~ /\.ini$/ ) {
            # MD5 checksums, for now
            $db_schema = $parser->read_ini_config();
            $db_schema = $parser->md5_checksum(db_schema => $db_schema);
            $parser->dump_schema(
                db_schema  => $db_schema,
                extra_text => q(Post-MD5 checksum),
            );
            $parser->write_ini_config(db_schema => $db_schema);
        } else {
            $log->logdie(q(Don't know how to process file )
                . $cfg->get(q(input)));
        }
    } else {
        $log->logerror(q(Please specify what type of output file to create));
        pod2usage(-exitstatus => 1);
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

    perldoc db_bootstrap.pl

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
