#!/usr/bin/env perl
##!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

package WADToolsTest::INIFileTest;
use Moo; # includes 'strictures 1'
use Test::More tests => 5;
use File::Basename;
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

#has q(expected_callback) => (
#    is      => q(rw),
#    default => sub { q() },
#);

# 2014-03-27 - brian
# - INIFile doesn't use callbacks, so it doesn't need to be inside it's own
# object, but it may use callbacks the future, so I'm leaving it this way for
# now
sub run {
    my $self = shift;

my $VERSION = $App::WADTools::INIFile::VERSION || q(git-dev);
diag( qq(\nTesting App::WADTools::INIFile )
    . qq(version '$VERSION',\n)
    . qq(Perl $],\n$^X)
);


# need to test this here, as the test plan is not available in package::main
BEGIN {
    use_ok( q(App::WADTools::INIFile) );
}

    # from WADToolsTest::Role::SetupLogging
    #my $dirname = dirname($0);
    #die qq(ERROR: Can't find config file 'tests.log4perl.cfg' in:\n> $dirname)
    #    unless ( -f qq($dirname/tests.log4perl.cfg) );
    #Log::Log4perl->init_once(qq($dirname/tests.log4perl.cfg));

    $self->setup_logging;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger
    isa_ok($log, q(Log::Log4perl::Logger));

    my $file; # a test App::WADTools::File object
    my $rv; # generic return value
    my $ini;

    #$self->expected_callback(REQUEST_FAILURE);

    my $ini_map;
    ### Call INI with bogus file
    eval{ App::WADTools::INIFile->new(filename => q(/path/to/bogus/file.ini));};
    ok($@, qq(App::WADTools::INIFile died using non-existant INI file));

    ### Call INI with valid file
    $ini = App::WADTools::INIFile->new(
        filename => q(testdata/idgames_dump_sql_blocks.ini));
    ok(ref($ini) eq q(App::WADTools::INIFile),
        q(Successfully created App::WADTools::INIFile object));
    $ini_map = $ini->read_ini_config();
    ok(ref($ini_map) =~ /Config::Std/,
        q(Received Config::Std object reading valid INI file));
}

# 2014-03-27 - brian
# - This method isn't used, because INIFile currently doesn't use callbacks,
# but may in the future, so I'm leaving it here for now
#sub request_update {
#    my $self = shift;
#    my %args = @_;
#    my $log = Log::Log4perl->get_logger(""); # "" = root logger
#
#    $log->debug(q(db_request_cb arguments: ) . join(q(, ), @_));
#    $log->info(q(25-INIFile: received 'request_update' call));
#    if ( ! $self->expected_callback ) {
#        $log->info(q(25-INIFile: received 'request_update' call));
#        $log->info(q(Expecting callback: ) . $self->expected_callback);
#        ok(defined $args{type} && $args{type} eq $self->expected_callback,
#            q(Received callback: ) . $self->expected_callback);
#        $self->expected_callback(q());
#    }
#}

#done_testing();

package main;
use strictures 1; # strict + warnings

# located in this file, below...
my $test = WADToolsTest::INIFileTest->new();
$test->run();

exit 0;


