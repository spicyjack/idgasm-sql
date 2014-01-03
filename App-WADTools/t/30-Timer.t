#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( q(App::WADTools::Timer) );
}

diag( qq(\nTesting App::Mayhem $App::WADTools::Timer::VERSION,\nPerl $], $^X) );

my $timer = App::WADTools::Timer->new();
ok(ref($timer) eq q(App::WADTools::Timer),
    q(Successfully created App::WADTools::Timer object));

# FIXME
# - Test doing time value diffs for timers that are not in the start/stop hash
# - Test starting timers that are already started, and stopping timers that
# haven't been started yet
