#!/usr/bin/env perl
##!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

package main;
use strictures 1; # strict + warnings

my $VERSION = $App::WADTools::DBTool::VERSION || q(git-dev);
diag( qq(\nTesting App::WADTools::DBTool )
    . $VERSION
    . qq(,\n)
    . qq(Perl $], $^X)
);

# located in this file, below...
my $test = WADToolsTest::DBToolTest->new();
$test->run();

exit 0;

package WADToolsTest::DBToolTest;
use Moo; # includes 'strictures 1'
use Test::More tests => 44;
#use Test::More; # using done_testing() at the end of this test
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# provides 'setup_logging' method, which checks to see that the config file is
# available
with qw(WADToolsTest::Logging);

has q(expected_callback) => (
    is      => q(rw),
    default => sub { q() },
);

sub run {
    my $self = shift;

BEGIN {
    use_ok( q(Log::Log4perl), qw(:no_extra_logdie_message));
    use_ok( q(File::Basename)); # used to find test config, and for test files
    use_ok( q(App::WADTools::DBTool) );
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

    # check App::WADTools::INIFile
    # use the current idgames_db_dump.ini schema file
    my $ini = App::WADTools::INIFile->new(
        filename => q(data/dbtool_test.ini));
    ok(ref($ini) eq q(App::WADTools::INIFile),
        q(Successfully created App::WADTools::INIFile object));
    my $ini_map = $ini->read_ini_config();

    ### Create App::WADTools::DBTool object
    my $db_tool = App::WADTools::DBTool->new(
        controller => $self,
        filename => q(:memory:),
    );
    ok(ref($db_tool) eq q(App::WADTools::DBTool),
        q(Successfully created App::WADTools::DBTool object));
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

#done_testing();
