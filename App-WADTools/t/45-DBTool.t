#!/usr/bin/env perl
##!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

package WADToolsTest::DBToolTest;
use Moo; # includes 'strictures 1'
use Test::More tests => 15;
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
    $ini = App::WADTools::INIFile->new(
        filename => q(../../sql_schemas/wadindex.ini));
    ok(ref($ini) eq q(App::WADTools::INIFile),
        q(Successfully created App::WADTools::INIFile object));
    my $ini_map = $ini->read_ini_config();
    ok(ref($ini_map) =~ /Config::Std/,
        q(Received Config::Std object reading valid INI file));

    my ($db_tool, $return);

    # Create an App::WADTools::DBTool object
    # - View missing
    # - Config missing
    # - Database filename provided
    $db_tool = App::WADTools::DBTool->new(
        filename => q(:memory:),
    );
    ok(ref($db_tool) eq q(App::WADTools::DBTool),
        q(Created object: ) . ref($db_tool));

    $return = $db_tool->run();
    ok( ref($return) eq q(App::WADTools::Error),
        q(Calling DBTool->run with missing View + Config results in error));
    ok( $return->id eq q(dbtool.run.missing_config),
        q(Error object returned by DBTool->run returned ID: ) . $return->id);

    ### Create an App::WADTools::DBTool object
    # - View set to $self
    # - Config missing
    # - Database filename provided
    $db_tool = App::WADTools::DBTool->new(
        view     => $self,
        filename => q(:memory:),
    );
    ok(ref($db_tool) eq q(App::WADTools::DBTool),
        q(Created object: ) . ref($db_tool));

    $return = $db_tool->run();
    ok( ref($return) eq q(App::WADTools::Error),
        q(Calling DBTool->run with with missing Config results in error));
    ok( $return->id eq q(dbtool.run.missing_config),
        q(Error object returned by DBTool->run returned ID: ) . $return->id);
    ok( $return->level eq q(fatal),
        q(Error level for the returned Error object is: ) . $return->level);

    ### Create an App::WADTools::DBTool object
    # - View set to $self
    # - Config provided
    # - Database filename provided
    $db_tool = App::WADTools::DBTool->new(
        view     => $self,
        filename => q(:memory:),
        # FIXME add a test/mock Config object here
    );
    ok(ref($db_tool) eq q(App::WADTools::DBTool),
        q(Created object: ) . ref($db_tool));

    $return = $db_tool->run();

}

sub request_update {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->debug(q(request_update; arguments: ) . join(q(, ), @_));

    note(q(45-DBTool: received 'request_update' call));
    $log->info(q(Expecting callback: ) . $self->expected_callback);
    ok(defined $args{type} && $args{type} eq $self->expected_callback,
        q(Received callback: ) . $self->expected_callback);
    # reset expected_callback
    $self->expected_callback(q());
}

package main;
use strictures 1; # strict + warnings

# located in this file, below...
my $test = WADToolsTest::DBToolTest->new();
$test->run();

exit 0;
