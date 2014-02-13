#!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

use strictures 1; # strict + warnings
use Test::File;
use Test::More tests => 11;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

BEGIN {
    use_ok( q(Log::Log4perl), qw(:no_extra_logdie_message));
    use_ok( q(File::Basename)); # used to find log4perl config file
    use_ok( q(Moo) );
    use_ok( q(App::WADTools::idGamesDB) );
    use_ok( q(App::WADTools::INIFile) );
}

### Roles consumed
#with qw(App::WADTools::Role::Callback);

my $VERSION = $App::WADTools::idGamesDB::VERSION || q(git-dev);

diag( qq(\nTesting App::WADTools::idGamesDB )
    . $VERSION
    . qq(,\n)
    . qq(Perl $], $^X)
);

# set up Log4perl
my $dirname = dirname($0);
file_exists_ok(qq($dirname/tests.log4perl.cfg),
    q(log4perl config file exists for testing));
Log::Log4perl->init_once(qq($dirname/tests.log4perl.cfg));
my $log = Log::Log4perl->get_logger();
isa_ok($log, q(Log::Log4perl::Logger));

# check App::WADTools::idGamesDB
my $db = App::WADTools::idGamesDB->new();
ok(ref($db) eq q(App::WADTools::idGamesDB),
    q(Successfully created App::WADTools::idGamesDB object));

# check App::WADTools::INIFile
# use the current idgames_db_dump.ini schema file
my $ini = App::WADTools::INIFile->new(
    filename => q(../../sql_schemas/idgames_db_dump.ini));
ok(ref($ini) eq q(App::WADTools::INIFile),
    q(Successfully created App::WADTools::INIFile object));

# - Create a schema using 'create_schema'
my $db_schema = $ini->read_ini_config();
$db->create_schema(schema => $db_schema);

# - Insert some records, make sure callbacks for record insertion are received
my $test_ini = App::WADTools::INIFile->new(
    filename => q(data/idgames_dump_sql_blocks.ini));
ok(ref($ini) eq q(App::WADTools::INIFile),
    q(Successfully created App::WADTools::INIFile object));
my $test_blocks = $test_ini->read_ini_config();
ok(ref($test_blocks) eq q(Config::Std::Hash),
    qq(Config::Std::Hash object created from INI file));
$db->create_schema(schema => $test_blocks);
# - use get_file_by_path to retrieve records
# - see code in 'db_tool' for ideas of how you can quickly create databases

# - Create a schema that has blocks with no SQL key
#   - Verify that there are no errors, the block should be skipped, and a
#   warning message shown to the user
