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

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::idgasmTools::Error;
use App::idgasmTools::File;

=head2 Methods

=over

=item parse(data => $response->content)

Parses the JSON content inside of the HTTP response message sent from the
server in response to an C<idGames Archive API> request.  Returns an
L<App::idgasmTools::File> object if parsing was successful, or a
L<App::idgasmTools::Error> object if parsing was not successful.

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
    if ( $@ ) {
        my $error = App::idgasmTools::Error->new(
            error_msg => qq(Error parsing JSON content; $@),
        );
        return $error;
    } else {
        #$log->debug(q(Dumping JSON parser output:));
        #$log->debug(Dumper $parsed_data);
        if ( exists $parsed_data->{content} ) {
            my $content = $parsed_data->{content};
            #$log->warn(qq(Dumping content:\n) . Dumper($content));
            my $file = App::idgasmTools::File->new();
            # go through all of the attributes in the content object, copy
            # them to the same attributes in this File object
            my @attribs = @{$file->file_attributes};
            $log->debug(q(Populating File attributes...));
            foreach my $key ( @attribs ) {
                if ( defined $content->{$key} ) {
                    $file->{$key} = $content->{$key};
                } else {
                    $file->{$key} = q();
                }
                next if ( $key eq q(textfile) );
                $log->debug(qq(  $key: >) . $file->$key . q(<));
            }
            return $file
        } elsif ( exists $parsed_data->{error} ) {
            my $error = App::idgasmTools::Error->new(
                error_msg => q(Received 'error' response to API query),
                content_block => $parsed_data->{error},
            );
            return $error;
        } else {
            my $error = App::idgasmTools::Error->new();
            $error->error_msg(q(Received undefined response to API query));
            return $error;
        }
    }
    # we shouldn't get this far
    $log->logdie(q(JSONParser reached end of parse block without branching));
}

1;
