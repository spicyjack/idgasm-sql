########################################
# package App::idgasmTools::XMLParser #
########################################
package App::idgasmTools::XMLParser;

=head1 App::idgasmTools::XMLParser

Parse XML text downloaded via HTTP request to C<idGames Archive API>.

=cut

# system modules
use XML::Fast;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Moo;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::idgasmTools::Error;

=head2 Methods

=over

=item parsing_module

The Perl module that was used to parse the XML data.

=cut

has q(parsing_module) => (
    is      => q(ro),
    default => q(XML::Fast),
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

    # XML::Fast::xml2hash will die if there are parsing errors; wrap parsing
    # with an eval to handle dying gracefully
    my $parsed_data = eval{XML::Fast::xml2hash($data);};
    #$log->debug(q(Dumping ) . $self->parsing_module . qq( output:\n)
    #    . Dumper $parsed_data);
    if ( $@ ) {
        my $error = App::idgasmTools::Error->new(error_msg => $@);
        return $error;
    } else {
        return $parsed_data;
    }
}

1;
