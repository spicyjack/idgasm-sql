################################
# package App::WADTools::Timer #
################################
package App::WADTools::Timer;

=head1 App::WADTools::Timer

Timers that can be used by different blocks of code to time the execution of
those blocks.

=cut

use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Moo;
use Time::HiRes qw( gettimeofday tv_interval );

# start times and stop times, used to determine difference between start and
# stop times
my (%_starts, %_stops);

=head2 Methods

=over

=item start(name => q(foo))

"Starts" a timer with the name of C<foo>.  Returns the start time as a UNIX
epoch time value.

Required arguments:

=over

=item name

The name of the timer to start.  The name of the timer is used later on when
stopping the timer, and when calculating the difference between start and stop
times.

=back

=cut

sub start {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing required argument 'name'))
        unless ( exists $args{name} );

    $_starts{$args{name}} = [gettimeofday];
    my ($seconds, $microseconds) = $_starts{$args{name}};
    return $seconds . q(.) . $microseconds;
}

=item stop(name => q(foo))

"Stops" a timer with the name of C<foo>.  Returns the stop time as a UNIX
epoch time value if a timer with the same name was started, or C<undef> if no
timer with the same name was ever started.

Required arguments:

=over

=item name

The name of the timer to stop.  "Stopping" a timer that was never "started"
will result in C<undef> being returned to the caller.

=back

=cut

sub stop_timer {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing required argument 'name'))
        unless ( exists $args{name} );

    # check to see that $self->start was called with the same 'name'
    # no sense in stopping a timer that was never started
    if ( exists ($_stops{$args{name}}) ) {
        $_stops{$args{name}} = [gettimeofday];
        my ($seconds, $microseconds) = $_stops{$args{name}};
        return $seconds . q(.) . $microseconds;
    } else {
        # nope, no timer with this name was ever started; return 'undef'
        return undef;
    }
}

=item time_value_difference(name => q(foo))

Takes the 'start' timer value for C<foo>, and the 'stop' timer value for
C<foo>, calculates the difference between the two times, and returns this time
value difference to the caller.

Required arguments:

=over

=item name

The name of the timer to compute the difference between the start and stop
times.  Calling this method with a timer was never started or stopped, will
result in C<undef> being returned to the caller.

=back

=cut

sub time_value_difference {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing required argument 'name'))
        unless ( exists $args{name} );

    # check to see that $self->start was called with the same 'name'
    # no sense in stopping a timer that was never started
    if ( exists($_starts{$args{name}}) && exists($_stops{$args{name}}) ) {
        return tv_interval( $_starts{$args{name}}, $_stops{$args{name}});
    } else {
        return undef;
    }
}

=back

=cut

1;
