#!/usr/bin/env perl
##!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

package WADToolsTest::DBToolTest;
use Moo; # includes 'strictures 1'
use Test::More tests => 44;
#use Test::More; # using done_testing() at the end of this test
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

use constant {
    REQUEST_UPDATE  => 0,
    REQUEST_SUCCESS => 1,
    REQUEST_FAILURE => 2,
};

# provides 'setup_logging' method, which checks to see that the config file is
# available
with qw(WADToolsTest::Role::SetupLogging);

has q(expected_callback) => (
    is      => q(rw),
    default => sub { q() },
);

sub run {
    my $self = shift;

    my $VERSION = $App::WADTools::DBTool::VERSION || q(git-dev);
    diag( qq(\nTesting App::WADTools::DBTool )
        . qq($VERSION,\n)
        . qq(Perl $],\n$^X)
    );

BEGIN {
    use_ok( q(App::WADTools::DBTool) );
    use_ok( q(App::WADTools::INIFile) );
    # local test object for testing callbacks from DBTool
    use_ok( q(WADToolsTest::DBCallback) );
}

    # needs Log::Log4perl loaded first (above)
    $self->setup_logging;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger
    isa_ok($log, q(Log::Log4perl::Logger));

    my $file; # a test App::WADTools::File object
    my $rv; # generic return value
    my $ini;

    # check App::WADTools::INIFile
    # use the current idgames_db_dump.ini schema file
    $self->expected_callback(REQUEST_FAILURE);

    ### Call INI with valid file
    $ini = App::WADTools::INIFile->new(filename => q(data/dbtool_test.ini));
    ok(ref($ini) eq q(App::WADTools::INIFile),
        q(Successfully created App::WADTools::INIFile object));
    my $ini_map = $ini->read_ini_config();
    ok(ref($ini) =~ /Config::Std/,
        q(Received Config::Std object reading valid INI file));

    ### Create App::WADTools::DBTool object
    my $db_tool = App::WADTools::DBTool->new(
        view     => $self,
        filename => q(:memory:),
    );
    ok(ref($db_tool) eq q(App::WADTools::DBTool),
        q(Successfully created App::WADTools::DBTool object));
    $db_tool->run();
}

sub request_update {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->debug(q(db_request_cb arguments: ) . join(q(, ), @_));

    if ( $self->expected_callback ) {
        $log->info(q(40-DBTool: received 'db_request_cb' call));
    } else {
        $log->info(q(40-DBTool: received 'db_request_cb' call));
        $log->info(q(Expecting callback: ) . $self->expected_callback);
        ok(defined $args{type} && $args{type} eq $self->expected_callback,
            q(Received callback: ) . $self->expected_callback);
        $self->expected_callback(q());
    }
}

package main;
use strictures 1; # strict + warnings

# located in this file, below...
my $test = WADToolsTest::DBToolTest->new();
$test->run();

exit 0;
