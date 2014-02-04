#!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

use strictures 1; # strict + warnings
use Test::More tests => 2;

BEGIN {
    use_ok( q(App::WADTools::idGamesDB) );
}

my $VERSION = $App::WADTools::idGamesDB::VERSION || q(git-dev);

diag( qq(\nTesting App::WADTools::idGamesDB )
    . $VERSION
    . qq(,\n)
    . qq(Perl $], $^X)
);

my $db = App::WADTools::idGamesDB->new();
ok(ref($db) eq q(App::WADTools::idGamesDB),
    q(Successfully created App::WADTools::idGamesDB object));

# Test ideas:
# - Create a schema that has blocks with no SQL key
#   - Verify that there are no errors, the block should be skipped, and a
#   warning message shown to the user
