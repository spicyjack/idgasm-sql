#!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

# Ideas for more tests:
# - Create a schema that has blocks with no SQL key
#   - Verify that there are no errors, the block should be skipped, and a
#   warning message shown to the user

use strictures 1; # strict + warnings
use Test::File;
#use Test::More tests => 11;
use Test::More; # using done_testing() at the end of this test
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

BEGIN {
    use_ok( q(Log::Log4perl), qw(:no_extra_logdie_message));
    use_ok( q(File::Basename)); # used to find test config, and for test files
    use_ok( q(Moo) );
    use_ok( q(App::WADTools::idGamesDB) );
    use_ok( q(App::WADTools::INIFile) );
}

my @test_ids = qw(
    12671 12849 12747 12430 12782 12363
    12835 12349 13024 12815 12415 12371
);

my @test_paths = qw(
   themes/hr/hr2final.zip
   levels/doom2/Ports/a-c/ch133.zip
   levels/doom2/Ports/d-f/dwforums3.zip
   docs/editing/doomrefrh.zip
   levels/doom2/Ports/g-i/grove.zip
   levels/doom2/Ports/a-c/action.zip
   levels/doom2/Ports/0-9/3057hub1.zip
   levels/doom2/Ports/s-u/tremor.zip
   levels/doom2/Ports/v-z/zdmcmp1.zip
   levels/doom/p-r/phobos-v.zip
   levels/doom2/Ports/d-f/decade.zip
   levels/doom2/Ports/megawads/cchest2.zip
);

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

my $file; # a test App::WADTools::File object
my $rv; # generic return value

### Create App::WADTools::idGamesDB object
my $db = App::WADTools::idGamesDB->new();
ok(ref($db) eq q(App::WADTools::idGamesDB),
    q(Successfully created App::WADTools::idGamesDB object));

### Database is_connected()
# - this should fail because 'connect()' hasn't been called yet
$rv = $db->is_connected;
ok(ref($rv) eq q(App::WADTools::Error),
    q(Check for database connection fails as expected; ) . $rv->type);

### Database connect()
$rv = $db->connect;
ok($rv == 1, q|DB connect() call successful|);

# check App::WADTools::INIFile
# use the current idgames_db_dump.ini schema file
my $ini = App::WADTools::INIFile->new(
    filename => q(../../sql_schemas/idgames_db_dump.ini));
ok(ref($ini) eq q(App::WADTools::INIFile),
    q(Successfully created App::WADTools::INIFile object));

### Create a schema using 'apply_schema'
my $db_schema = $ini->read_ini_config();
$rv = $db->apply_schema(schema => $db_schema);
ok($rv == 1, q(apply_schema applied database schema without errors));

### Run $db->has_schema
$rv = $db->has_schema();
ok($rv == 5, q(Schema table has 5 entries));

### Insert some records, make sure callbacks for record insertion are received
# - Read in the test INI with live File objects
my $test_ini = App::WADTools::INIFile->new(
    filename => q(data/idgames_dump_sql_blocks.ini));
ok(ref($ini) eq q(App::WADTools::INIFile),
    q(Successfully created App::WADTools::INIFile object));
# - Create the schema object with live SQL
my $test_blocks = $test_ini->read_ini_config();
ok(ref($test_blocks) eq q(Config::Std::Hash),
    qq(Config::Std::Hash object created from INI file));
$rv = $db->apply_schema(schema => $test_blocks);

# other possible ways to do this...
#$rv = $db->run_sql_insert(sql_predicate => $scalar, sql_params => @array);
#$rv = $db->run_sql_insert(table => $scalar, sql_params => @array);
#$rv = $db->insert_data(table => $scalar, sql_params => @array);

# check the schema table again, it should now have 5 + scalar(@test_ids)
$rv = $db->has_schema();
my $total_schema_entries = 5 + scalar(@test_ids);
ok($rv == $total_schema_entries,
    qq(Schema table now has $total_schema_entries entries));

# negative test case
$file = $db->get_file_by_id(id => 1);
ok($file->can(q(is_error)),
    q(Request for non-existant file ID returns Error object));
ok($file->type =~ /file_id_not_found/,
    q(Error 'type' returned includes 'file_id_not_found' string));

# - use get_file_by_id to retrieve records
foreach my $file_id ( @test_ids ) {
    $file = $db->get_file_by_id(id => $file_id);
    if ( ref($file) eq q(App::WADTools::Error) ) {
        die $file->log_error;
    }
    ok($file->id == $file_id,
        qq|Retrieved File object by ID (id=$file_id)|);
}

# negative test case
$file = $db->get_file_by_path(path => q(/path/to), filename => q(⁄foo.wad));
ok($file->can(q(is_error)),
    q(Request for non-existant file ID returns Error object));
ok($file->type =~ /file_path_not_found/,
    q(Error 'type' returned includes 'file_path_not_found' string));

# - use get_file_by_path to retrieve records
foreach my $file_path ( @test_paths ) {
    my ($filename, $path) = fileparse($file_path);
    $file = $db->get_file_by_path(path => $path, filename => $filename);
    ok($file->dir eq $path && $file->filename eq $filename,
        qq|Retrieved File object by path ($file_path)|);
}

done_testing();
