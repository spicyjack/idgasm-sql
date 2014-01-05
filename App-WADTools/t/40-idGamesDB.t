#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( q(App::WADTools::idGamesDB) );
}

diag( qq(\nTesting App::WADTools::idGamesDB )
    . $App::WADTools::idGamesDB::VERSION
    . qq(,\n)
    . qq(Perl $], $^X)
);

my $db = App::WADTools::idGamesDB->new();
ok(ref($timer) eq q(App::WADTools::idGamesDB),
    q(Successfully created App::WADTools::idGamesDB object));

# Test ideas:
# - Create a schema that has blocks with no SQL key
#   - Verify that there are no errors, the block should be skipped, and a
#   warning message shown to the user
