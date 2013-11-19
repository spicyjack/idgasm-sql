########################################
# package App::idgasmTools::XMLParser #
########################################
package App::idgasmTools::XMLParser;

=head1 App::idgasmTools::XMLParser

Parse XML text downloaded via HTTP request to C<idGames Archive API>.

=cut

# system modules
#use XML;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Moo;

# local modules
use App::idgasmTools::Error;

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
    #my $json = XML::XS->new->utf8->pretty->allow_unknown;
    my $json;
    my $data_struct = eval{$json->decode($data);};
    if ( $@ ) {
        my $error = App::idgasmTools::Error->new(error_msg => $@);
        return $error;
    } else {
        return $data_struct;
    }
}

1;
