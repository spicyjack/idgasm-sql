#!/usr/bin/env perl
##!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

package WADToolsTest::DBToolTest;
use Moo; # includes 'strictures 1'
use File::Temp;
use Test::More tests => 25;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

use constant {
    UPDATE          => 0,
    REQUEST_SUCCESS => 1,
    REQUEST_FAILURE => 2,
};

# provides 'setup_logging' method, which checks to see that the config file is
# available
with qw(WADToolsTest::Role::SetupLogging);

my @_test_callbacks_list;

sub run {
    my $self = shift;

    my $VERSION = $App::WADTools::DBTool::VERSION || q(git-dev);
    diag( qq(\nTesting App::WADTools::DBTool )
        . qq($VERSION,\n)
        . qq(Perl $],\n$^X)
    );

BEGIN {
    use_ok( q(App::WADTools::Config) );
    use_ok( q(App::WADTools::DBTool) );
    # local test object for testing callbacks from DBTool
    use_ok( q(WADToolsTest::DBCallback) );
}

    # needs Log::Log4perl loaded first (above)
    $self->setup_logging;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger
    isa_ok( $log, q(Log::Log4perl::Logger) );

    my $file; # a test App::WADTools::File object
    my $rv; # generic return value
    my $ini_file = q(../../sql_schemas/wadindex.ini);
    my $out_file = File::Temp->new();

    my ($db_tool, $return);

    # Create an App::WADTools::DBTool object
    # - View missing
    # - Config missing
    # - Database filename provided
    $db_tool = App::WADTools::DBTool->new(
        filename => q(:memory:),
    );
    is( ref($db_tool), q(App::WADTools::DBTool),
        q(Created object: ) . ref($db_tool));

    $return = $db_tool->run();
    is( ref($return), q(App::WADTools::Error),
        q(Calling DBTool->run with missing View + Config results in error));
    is( $return->id, q(dbtool.run.missing_config),
        q(ID of returned Error object: ) . $return->id);

    ### Create an App::WADTools::DBTool object
    # - View set to $self
    # - Config missing
    # - Database filename provided
    $db_tool = App::WADTools::DBTool->new(
        view     => $self,
        filename => q(:memory:),
    );
    is( ref($db_tool), q(App::WADTools::DBTool),
        q(Created object: ) . ref($db_tool));

    $return = $db_tool->run();
    is( ref($return), q(App::WADTools::Error),
        q(Calling DBTool->run with with missing Config results in error));
    is( $return->id, q(dbtool.run.missing_config),
        q(ID of returned Error object: ) . $return->id);
    is( $return->level, q(fatal),
        q(Error level for the returned Error object is: ) . $return->level);

    ### Create an App::WADTools::DBTool object
    # - View set to $self
    # - Config provided
    # - Database filename provided
    my $cfg = App::WADTools::Config->new(options => []);
    $cfg->set(q(create-db), 1);
    $cfg->set(q(input), $ini_file);
    is( ref($cfg), q(App::WADTools::Config),
        q(Created a valid App::WADTools::Config object));
    is( $cfg->get(q(create-db)), 1,
        q(App::WADTools::Config has valid 'create-db' attribute));
    is( $cfg->get(q(input)), $ini_file,
        q(App::WADTools::Config has valid 'input' attribute));

    # should be 8 "execute block" callbacks, and one "success" callback
    @_test_callbacks_list = qw(
        database_schema.execute_block
        database_schema.execute_block
        database_schema.execute_block
        database_schema.execute_block
        database_schema.execute_block
        database_schema.execute_block
        database_schema.execute_block
        database_schema.execute_block
        database_schema.apply_schema
    );
    $db_tool = App::WADTools::DBTool->new(
        view     => $self,
        filename => q(:memory:),
        config   => $cfg,
    );
    is( ref($db_tool), q(App::WADTools::DBTool),
        q(Created object: ) . ref($db_tool));
    $return = $db_tool->run();
    is(scalar(@_test_callbacks_list), 0, q(Received all expected callbacks));
}

sub update {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $expected_callback = shift(@_test_callbacks_list);
    $log->info(qq(Expecting callback: $expected_callback));
    ok(defined $args{id} && $args{id} eq $expected_callback,
        qq(Received update callback: $expected_callback));
    $log->debug(q(update; arguments: ) . join(q(, ), @_));
}

sub request_success {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $expected_callback = shift(@_test_callbacks_list);
    $log->info(qq(Expecting callback: $expected_callback));
    ok(defined $args{id} && $args{id} eq $expected_callback,
        qq(Received request_success callback: $expected_callback));
    $log->debug(q(request_success; arguments: ) . join(q(, ), @_));
}

package main;
use strictures 1; # strict + warnings

# located in this file, below...
my $test = WADToolsTest::DBToolTest->new();
$test->run();

exit 0;
