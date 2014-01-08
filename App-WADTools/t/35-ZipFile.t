#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( q(App::WADTools::ZipFile) );
}

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
