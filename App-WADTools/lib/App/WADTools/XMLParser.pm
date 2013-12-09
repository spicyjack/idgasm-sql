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
use App::WADTools::Vote;

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
    my $api_version = 0;

    # XML::Fast::xml2hash will die if there are parsing errors; wrap parsing
    # with an eval to handle dying gracefully
    my $parsed_data = eval{XML::Fast::xml2hash($data);};
    # first check, was the XML parsed correctly
    if ( $@ ) {
        # no, an error occured parsing the XML
        my $error = App::WADTools::Error->new(
            error_msg => qq(Error parsing XML content; $@),
        );
        return ($error, $api_version);
    } else {
        # yes, XML parsed correctly
        # snarf tha API version
        #$log->debug(qq(Dumping parsed_data:\n) . Dumper($parsed_data));
        $api_version = $parsed_data->{q(idgames-response)}->{q(-version)};
        $log->debug(qq(API meta version from response: $api_version));
    }

    # now, see what kind of API request was made
    if ( exists $parsed_data->{q(idgames-response)}->{error} ) {
        # an error was returned from the API
        my $error = App::WADTools::Error->new(
            error_msg => q(Received 'error' response to API query),
            content_block => $parsed_data->{q(idgames-response)}->{error},
        );
        return (error => $error, api_version => $api_version);
    } elsif ( exists $parsed_data->{q(idgames-response)}->{content}->{file} ) {
        # a 'latestfiles' request
        $log->debug(q(Received a response for a 'latestfiles' request));
        my $latestfiles
            = $parsed_data->{q(idgames-response)}->{content}->{file};
        #$log->debug(qq(Dumping parsed latestfiles:\n) . Dumper($latestfiles));
        my @return_files;
        foreach my $latestfile ( @{$latestfiles} ) {
            $log->debug(q(Creating partial File object for file ID: )
                . $latestfile->{id});
            my $file = App::WADTools::File->new(partial => 1);
            my @attribs = keys(%{$latestfile});
            foreach my $key ( @attribs ) {
                $file->{$key} = $latestfile->{$key};
                next if ( $key eq q(textfile) );
                #$log->debug(qq(  $key: >) . $file->$key . q(<));
            }
            push(@return_files, $file);
        }
        return (files => \@return_files, api_version => $api_version);
    } elsif ( exists $parsed_data->{q(idgames-response)}->{content}->{id} ) {
        # a 'get' request
        $log->debug(q(Received a response for a 'get' request));
        my $content = $parsed_data->{q(idgames-response)}->{content};
        #$log->debug(qq(Dumping get request:\n) . Dumper($content));
        $log->debug(q(Successfully parsed XML content block));
        my $file = App::WADTools::File->new();
        # go through all of the attributes in the content object, copy
        # them to the same attributes in this File object
        my @attribs = @{$file->attributes};
        $log->debug(q(Populating File attributes for file ID: )
            . $content->{id});
        foreach my $key ( @attribs ) {
            # don't save the textfile entry right now
            next if ( $key eq q(textfile) );
            #$log->debug(qq(  $key: >) . $content->{$key} . q(<));
            if ( $key ne q(reviews) ) {
                $file->{$key} = $content->{$key};
            } else {
                $log->debug(q(Adding reviews block to 'votes' table));
                my @file_reviews = @{$content->{reviews}->{review}};
                my @reviews;
                my $total_reviews = 0;
                my $review_sum = 0;
                foreach my $file_review ( @file_reviews ) {
                    my $review = App::WADTools::Vote->new();
                    $review->text($file_review->{text});
                    $review->vote($file_review->{vote});
                    #$log->debug(qq(  vote: ) . $review->vote
                    #    . q(; vote length: ) . length($review->text));
                    $review_sum += $review->vote;
                    $total_reviews++;
                    push(@reviews, $review);
                }
                # assign the parsed reviews to the file object
                $file->reviews(\@reviews);
                my $average_review = $review_sum / $total_reviews;
                $log->debug(q(File ) . $file->id
                    . qq( has $total_reviews reviews, )
                    . qq(with an average score of )
                    . sprintf(q(%0.2f), $average_review));
            }
        }
        return (file => $file, api_version => $api_version);
    } else {
        my $error = App::WADTools::Error->new();
        $error->error_msg(q(Received undefined response to API query));
        return ($error, $api_version);
    }

    # we shouldn't get this far
    $log->logdie(q(XMLParser reached end of parse block without branching));
}

1;
