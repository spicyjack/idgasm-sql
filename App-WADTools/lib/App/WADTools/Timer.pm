################################
# package App::WADTools::Timer #
################################
package App::WADTools::Timer;

=head1 App::WADTools::Timer

Timers for different parts of script execution.

=cut

use Moo;
use Number::Format; # pretty output of bytes
use Time::HiRes qw( gettimeofday tv_interval );

# start times and stop times, used to determine difference between start and
# stop times
my (%_starts, %_stops);

=head2 Attributes

=over

=item foo

A foo attribute.

=cut

has q(foo) => (
    is  => q(rw),
    #isa => sub {$_[0] =~ /\d+/},
);

=back

=head2 Methods

=over

=item start_timer('foo')

Starts a timer with the name of C<foo>.

=cut

sub start_timer {
    my $self = shift;
    my $timer_name = shift;
    $_starts{$timer_name} = [gettimeofday];
}

=item stop_timer('foo')

Stops the timer named C<foo>.

=cut

sub stop_timer {
    my $self = shift;
    my $timer_name = shift;
    $_stops{$timer_name} = [gettimeofday];
}

=item time_value_difference('foo')

Takes the 'start' timer value for C<foo>, and the 'stop' timer value for
C<foo>, calculates the difference between the two values, and returns this
value to the caller.

=cut

sub time_value_difference {
    my $self = shift;
    my $timer_name = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    return tv_interval ( $_starts{$timer_name}, $_stops{$timer_name});
}

1;
