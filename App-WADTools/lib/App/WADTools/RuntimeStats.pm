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

my ($_start_time, $_stop_time);

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

=back

=head2 Methods

=over

=item start_timer()

Starts the internal timer, used to measure total script execution time.

=cut

sub start_timer {
    $_start_time = [gettimeofday];
}

=item stop_timer()

Stops the internal timer, used to measure total script execution time.

=cut

sub stop_timer {
    $_stop_time = [gettimeofday];
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
    my $script_execution_time = tv_interval ( $_start_time, $_stop_time );
    $log->info(qq(- Total script execution time: )
        . sprintf(q|%0.2f second(s)|, $script_execution_time));
    my $average_request_time = $script_execution_time
        / ($self->successful_api_requests + $self->unsuccessful_api_requests);
    $log->info(qq(- Average request time: )
        . sprintf(q|%0.2f second(s)|, $average_request_time));
    $log->info(qq(- Total successful API requests: )
        . $self->successful_api_requests);
    $log->info(qq(- Total unsuccessful API requests: )
        . $self->unsuccessful_api_requests);
}

1;
