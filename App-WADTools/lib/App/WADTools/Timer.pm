################################
# package App::WADTools::Timer #
################################
package App::WADTools::Timer;

=head1 NAME

App::WADTools::Timer

=head1 SYNOPSIS

 my $timer = App::WADTools::Timer->new();

 my $start_time = $timer->start(name => q(foo));
 # $start_time should now be seconds.milliseconds from epoch

 my $stop_time = $timer->stop(name => q(foo));
 # $stop_time should now be seconds.milliseconds from epoch

 my $time_diff = $timer->time_value_difference(name => q(foo));
 # $time_diff should be seconds.milliseconds between 'start' and 'stop'

 # delete the time
 $timer->delete(name => q(foo));

=head1 DESCRIPTION

Create timers that can be used by different blocks of code, in order to time
the execution of those blocks.

=cut

### System modules
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Moo;
use Time::HiRes qw( gettimeofday tv_interval );

# start times and stop times, used to determine difference between start and
# stop times
my (%_starts, %_stops);

=head2 Methods

=over

=item delete(name => q(foo))

"Deletes" a timer with the name of C<foo>.  If a "start" or "stop" timer
doesn't exist for C<foo>, no errors will be given.  This method will always
return the "success" value of C<1>.

Required arguments:

=over

=item name

The name of the timer to delete.

=back

=cut

sub delete {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing required argument 'name'))
        unless ( exists $args{name} );

    delete($_starts{$args{name}});
    delete($_stops{$args{name}});
    return 1;
}


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

=head1 AUTHOR

Brian Manning, C<< <brian at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker for
this project:

C<< <https://github.com/spicyjack/wadtools/issues> >>.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

    perldoc App::WADTools::idGamesDB

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
