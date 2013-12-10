#######################################
# package App::WADTools::RuntimeStats #
#######################################
package App::WADTools::RuntimeStats;

=head1 App::WADTools::RuntimeStats

An object that keeps the following statistics about script execution:

=over

=item Total script execution time

=item Total records successfully requested from C<idGames API>

=item Total records unsuccessfully requested from C<idGames API>

=item Average time between C<idGames API> requests

=back

=cut

use Moo;
use Number::Format; # pretty output of bytes
use Time::HiRes qw( gettimeofday tv_interval );

my (%_starts, %_stops);

=head2 Attributes

=over

=item successful_api_requests

Total records successfully requested from C<idGames API>.  A "successful API
request" is one that returns a C<content> block.

=cut

has q(successful_api_requests) => (
    is  => q(rw),
    isa => sub {$_[0] =~ /\d+/},
);

=item unsuccessful_api_requests

Total records unsuccessfully requested from C<idGames API>.  An "unsuccessful
API request" is one that returns an C<error> block.

=cut

has q(unsuccessful_api_requests) => (
    is  => q(rw),
    isa => sub {$_[0] =~ /\d+/},
);

=item total_http_request_time

The total amount of time making HTTP requests from the C<idGames API>.

=cut

has q(total_http_request_time) => (
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

Stops the timer named C<foo>.  to measure total script execution time.

=cut

sub stop_timer {
    my $self = shift;
    my $timer_name = shift;
    $_stops{$timer_name} = [gettimeofday];
}

=item time_value_difference('foo')

=cut

sub time_value_difference {
    my $self = shift;
    my $timer_name = shift;
    my $log = Log::Log4perl->get_logger();

    return tv_interval ( $_starts{$timer_name}, $_stops{$timer_name});
}

=item write_stats()

Output the runtime stats from the script.

=back

=cut

sub write_stats {
    my $self = shift;
    my %args = @_;

    my $log = Log::Log4perl->get_logger();

    $log->info(q(Calculating runtime statistics...));
    my $nf = Number::Format->new();
    # $_start_time/$_stop_time are local script variables
    my $script_execution_time = $self->time_value_difference(q(program));
    $log->info(qq(- Total script execution time: )
        . sprintf(q|%0.5f second(s)|, $script_execution_time));
    my $average_time_between_http_requests = $script_execution_time
        / ($self->successful_api_requests + $self->unsuccessful_api_requests);
    my $average_http_response_time = $self->total_http_request_time
        / ($self->successful_api_requests + $self->unsuccessful_api_requests);
    $log->info(qq(- Total time spent making HTTP requests: )
        . sprintf(q|%0.5f second(s)|, $self->total_http_request_time));
    $log->info(qq(- Average time between HTTP requests: )
        . sprintf(q|%0.5f second(s)|, $average_time_between_http_requests));
    $log->info(qq(- Average HTTP response time: )
        . sprintf(q|%0.5f second(s)|, $average_http_response_time));
    $log->info(qq(- Total successful API requests: )
        . $self->successful_api_requests);
    $log->info(qq(- Total unsuccessful API requests: )
        . $self->unsuccessful_api_requests);
}

1;
