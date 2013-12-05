####################################
# package App::WADTools::XMLParser #
####################################
package App::WADTools::XMLParser;

=head1 App::WADTools::XMLParser

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
use App::WADTools::Error;
use App::WADTools::File;

=head2 Methods

=over

=item parse(data => $response->content)

Parses the XML content inside of the HTTP response message sent from the
server in response to an C<idGames Archive API> request.  Returns an
L<App::WADTools::File> object if parsing was successful, or a
L<App::WADTools::Error> object if parsing was not successful.

=back

=cut

sub parse {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger("");

    $log->logdie(q(Missing data to parse as argument 'data'))
        unless (exists $args{data});

    my $data = $args{data};
    my $api_meta_version = 0;

    # XML::Fast::xml2hash will die if there are parsing errors; wrap parsing
    # with an eval to handle dying gracefully
    my $parsed_data = eval{XML::Fast::xml2hash($data);};
    if ( $@ ) {
        my $error = App::WADTools::Error->new(
            error_msg => qq(Error parsing XML content; $@),
        );
        return ($error, $api_meta_version);
    } elsif ( exists $parsed_data->{q(idgames-response)}->{content} ) {
        my $content = $parsed_data->{q(idgames-response)}->{content};
        $log->warn(qq(Dumping content:\n) . Dumper($content));
        $log->debug(q(Successfully parsed XML content block));
        my $file = App::WADTools::File->new();
        # go through all of the attributes in the content object, copy
        # them to the same attributes in this File object
        my @attribs = @{$file->attributes};
        $log->debug(q(Populating File attributes...));
        foreach my $key ( @attribs ) {
            $file->{$key} = $content->{$key};
            next if ( $key eq q(textfile) );
            #$log->debug(qq(  $key: >) . $file->$key . q(<));
        }
        return ($file, $api_meta_version);
    } elsif ( exists $parsed_data->{q(idgames-response)}->{error} ) {
        my $error = App::WADTools::Error->new(
            error_msg => q(Received 'error' response to API query),
            content_block => $parsed_data->{q(idgames-response)}->{error},
        );
        return ($error, $api_meta_version);
    } else {
        my $error = App::WADTools::Error->new();
        $error->error_msg(q(Received undefined response to API query));
        return ($error, $api_meta_version);
    }

    # we shouldn't get this far
    $log->logdie(q(XMLParser reached end of parse block without branching));
}

1;
