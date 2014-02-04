#!perl -T

# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

use strictures 1; # strict + warnings
use Test::More tests => 1;

BEGIN {
    use_ok( q(App::WADTools::ZipFile) );
}

my $VERSION = $App::WADTools::ZipFile::VERSION || q(git-dev);
diag( qq(\nTesting App::WADTools::ZipFile )
    . $App::WADTools::ZipFile::VERSION
    . qq(,\n)
    . qq(Perl $], $^X)
);

my $zipfile = App::WADTools::ZipFile->new();
ok(ref($zipfile) eq q(App::WADTools::ZipFile),
    q(Successfully created App::WADTools::ZipFile object));

# Test ideas:
# - Try to create a zip file with a non-existant file
#   - Will need to trap with eval{}
# - Use a test zip file
#   - Verify the @members array gets populated
#   - Try to extract files to a temp directory
