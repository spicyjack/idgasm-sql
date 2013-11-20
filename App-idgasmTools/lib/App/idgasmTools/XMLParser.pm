########################################
# package App::idgasmTools::XMLParser #
########################################
package App::idgasmTools::XMLParser;

=head1 App::idgasmTools::XMLParser

Parse XML text downloaded via HTTP request to C<idGames Archive API>.

=cut

# system modules
#use XML::Twig;
#use XML::LibXML;
use XML::Parser;
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
    # XML::Twig
    #my $document = eval{$xml->parse($data);};
    #my $xml = XML::LibXML->new();
    # XML::LibXML
    #my $xml = XML::LibXML->new();
    #my $document = eval{$xml->load_xml(string => \$data);};
    #my $root = $document->getDocumentElement();
    # XML::Parser
    my $xml = XML::Parser->new( Style => q(Tree) );
    my $document = eval{$xml->parse($data);};
    $log->debug(qq(Dumping:\n) . Dumper $document);
    if ( $@ ) {
        my $error = App::idgasmTools::Error->new(error_msg => $@);
        return $error;
    } else {
        return $document;
    }
}

1;
