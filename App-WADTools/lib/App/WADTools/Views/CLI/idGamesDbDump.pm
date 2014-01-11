####################################################
# package App::WADTools::Views::CLI::idGamesDbDump #
####################################################
package App::WADTools::Views::CLI::idGamesDbDump;

=head1 App::WADTools::Views::CLI::idGamesDbDump

The CLI "view" object for the script C<idgames_db_dump>.  Displays updates
from the C<idgames_db_dump> script, as well as runtime statistics at the end
of script execution.

The following ѕtatistics are displayed:

=over

=item Total script execution time

=item Total records successfully requested from C<idGames API>

=item Total records unsuccessfully requested from C<idGames API>

=item Average time between C<idGames API> requests

=back

=cut

use Moo;
use Number::Format; # pretty output of bytes

=head2 Attributes

=over

=item program_time_value_diff

The amount of time the program took to run, that is, start-to-finish process
API requests against the C<idGames API>.

=cut

has q(program_time_value_diff) => (
    is  => q(rw),
    isa => sub {$_[0] =~ /[\d\.]+/},
);

=item successful_api_requests

Total records successfully requested from C<idGames API>.  A "successful API
request" is one that returns a C<content> block.

=cut

has q(successful_api_requests) => (
    is  => q(rw),
    isa => sub {$_[0] =~ /\d+/},
);

=item total_http_request_time

The total amount of time making HTTP requests from the C<idGames API>.

=cut

has q(total_http_request_time) => (
    is  => q(rw),
    isa => sub {$_[0] =~ /[\d\.]+/},
);

=item unsuccessful_api_parses

Total API responses that could not be parsed (for whatever reason).  Usually
means a badly formed API response message from the server.

=cut

has q(unsuccessful_api_parses) => (
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

=item write_stats()

Output the runtime stats from the script.

=back

=cut

sub write_stats {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->info(q(Calculating runtime statistics...));
    my $nf = Number::Format->new();

    # calculate some things before displaying
    my $average_time_between_http_requests = $self->program_time_value_diff
        / ($self->successful_api_requests + $self->unsuccessful_api_requests);
    my $average_http_response_time = $self->total_http_request_time
        / ($self->successful_api_requests + $self->unsuccessful_api_requests);

    # start the output display
    $log->info(qq(- Total script execution time: )
        . sprintf(q|%0.5f second(s)|, $self->program_time_value_diff));
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
    $log->info(qq(- Total unsuccessful API parses: )
        . $self->unsuccessful_api_parses);
}

1;
