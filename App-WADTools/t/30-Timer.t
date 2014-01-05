#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( q(App::WADTools::Timer) );
}

diag( qq(\nTesting App::WADTools::Timer )
    . $App::WADTools::Timer::VERSION
    . qq(,\n)
    . qq(Perl $], $^X)
);

my $timer = App::WADTools::Timer->new();
ok(ref($timer) eq q(App::WADTools::Timer),
    q(Successfully created App::WADTools::Timer object));

# Test ideas:
# - Test doing time value diffs for timers that are not in the start/stop hash
# - Test starting timers that are already started, and stopping timers that
# haven't been started yet
