###############################
# package App::WADTools::Vote #
###############################
package App::WADTools::Vote;

=head1 App::WADTools::Vote

An individual vote for a file in the C<idGames Archive>.  The information in
this object is read directly from C<idGames Archive>, and comes from the vote
information entered in by reviewers submitting reviews to C<idGames Archive>.

=cut

# system modules
use Moo;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::WADTools::Error;

=head2 Attributes

=over

=item id

The vote ID in the C<idGames Archive> database.

=cut

has q(id) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /\d+/ },
);

=item file_id

The file ID that this vote is associated with

=cut

has q(file_id) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /\d+/ },
);

=item text

The text of the user's vote, which may include the user's signature/name.
This field can be empty.

=cut

has q(text) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item vote

The vote for this file as submitted by the user, an integer from one to five,
representing the number of stars the user gave this file.

=cut

has q(vote) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /[1-5]/ },
);

=back

=head2 Methods

=over

=item BUILD() (aka 'new')

Creates the L<App::WADTools::Vote> object, optionally with an error
message.

=back

=cut

1;
