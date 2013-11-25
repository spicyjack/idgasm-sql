########################################
# package App::idgasmTools::JSONParser #
########################################
package App::idgasmTools::JSONParser;

=head1 App::idgasmTools::JSONParser

Parse JSON text downloaded via HTTP request to C<idGames Archive API>.

=cut

# system modules
use JSON;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Moo;

# local modules
use App::idgasmTools::Error;

=head2 Methods

=over

=item parsing_module

The Perl module that was used to parse the XML data.

=cut

has q(parsing_module) => (
    is      => q(ro),
    default => q(JSON),
);

=head2 Methods

=over

=item parse(data => $response->content)

Parses the content inside of the HTTP response message sent from the server in
response to an C<idGames Archive API> request.  Returns a reference to a
complex data structure that represents the parsed data if parsing was
successful, or a L<App::idgasmTools::Error> object if parsing was not
successful.

=cut

sub parse {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger("");

    $log->logdie(q(Missing data to parse as argument 'data'))
        unless (exists $args{data});

    my $data = $args{data};
    my $json = JSON::XS->new->utf8->pretty->allow_unknown;
    # wrap decode() in an eval to handle parsing errors
    my $parsed_data = eval{$json->decode($data);};
    $log->debug(q(Dumping ) . $self->parse_module . qq( output:\n)
        . Dumper $parsed_data);
    if ( $@ ) {
        my $error = App::idgasmTools::Error->new(error_msg => $@);
        return $error;
    } else {
        return $parsed_data;
    }
}

1;
