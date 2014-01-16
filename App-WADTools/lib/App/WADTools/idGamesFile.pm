######################################
# package App::WADTools::idGamesFile #
######################################
package App::WADTools::idGamesFile;

=head1 App::WADTools::idGamesFile

An individual file in C<idGames Archive>.  The information in this object is
taken from the C<*.txt> file that is uploaded with each file to C<idGames
Archive>.  Any issues/inaccuracies are most likely because the C<*.txt> file
was parsed incorrectly or was not parseable.

=cut

### System modules
use Digest::MD5;
use Moo;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

### Local modules
use App::WADTools::Error;

### Roles consumed
with qw(App::WADTools::Roles::Keysum);

=head2 Attributes

=over

=item partial

A boolean flag signifying that this file is a partial record, and does not
have all of the information about the file from the C<idGames Archive>.
Partial files are usually created from using the C<latestfiles> API request.
Valid values are in the regex C</0|1|y|n/i>.

=cut

has q(partial) => (
    is      => q(rw),
    isa     => sub { $_[0] =~ /0|1|n|no|y|yes/i },
    coerce  => sub {
                    my $arg = $_[0];
                    if ( $arg =~ /0|n|no/i ) { return 0; }
                    if ( $arg =~ /1|y|yes/i ) { return 1; }
                },
    default => sub { 0 },
);

=item base_url

The base URL path to the file. The file's full path is made up of B<base URL>
+ B<dir> + B<filepath>.

=cut

has q(base_url) => (
    is  => q(rw),
);

=item id

The file's C<idGames Archive> ID number.

=cut

has q(id) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /\d+/ },
);

=item title

The file's title, if one was used (some files don't have a title).

=cut

has q(title) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item dir

Directory under the root of C<idGames Archive> that contains this file.

=cut

has q(dir) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /^\/.*/ },
);

=item filename

The file's name.

=cut

has q(filename) => (
    is  => q(rw),
    isa => sub{ length($_[0]) > 0 },
);


=item size

The file's size, in bytes.

=cut

has q(size) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /\d+/ },
);

=item age

The file's age, or the epoch date when the file was added to C<idGames
Archive>.

=cut

has q(age) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /\d+/ },
);

=item date

The string date when the file was added to C<idGames Archive>.

=cut

has q(date) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /\d{4}-\d{2}-\d{2}/ },
);

=item author

The file's author.

=cut

has q(author) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item email

The author's e-mail.

=cut

has q(email) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /[\w\-\.]+@[\w\-\.]+/ },
);

=item description

The description of the file, as provided by the author.

=cut

has q(description) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item credits

Credits for resources that the WAD author(s) used.

=cut

has q(credits) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item base

The base resources that the WAD author(s) used to build this WAD.

=cut

has q(base) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item buildtime

A textual description for how long the WAD took to build (and possibly
[play]test).

=cut

has q(buildtime) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item editors

The editing tools that were used to build this WAD.

=cut

has q(editors) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item bugs

Known bugs that are present in the WAD file.

=cut

has q(bugs) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item textfile

The contents of the C<*.txt> file that was uploaded with the original file to
C<idGames Archive>.

=cut

has q(textfile) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item rating

The file's average rating, as rated by users of the Doomworld
C<idGames Archive> front end.

=cut

has q(rating) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /\d\.\d+/ },
);

=item votes

The number of votes that this file has received.

=cut

has q(votes) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /\d+/ },
);

=item url

The URL for the C<idGames Archive> page for this file.

=cut

has q(url) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /http:\/\/www\.doomworld\.com\/idgames\/\?id=\d+/ },
);

=item idgamesurl

The idgames protocol URL for this file.

=cut

has q(idgamesurl) => (
    is  => q(rw),
    isa => sub{ $_[0] =~ /idgames:\/\/\d+/ },
);

=item reviews

An array reference that contains all reviews for this file (as
L<App::WADTools::Vote objects).

=cut

has q(reviews) => (
    is  => q(rw),
    isa => sub{ 1 },
);

=item file_attributes

An array reference to an array that contains all of the attribute keys for a
C<idGamesFile> object.  Great for using for enumerating all of the file's
attrubtes.

=cut

has q(attributes) => (
    is  => q(ro),
    default => sub { [qw(
        keysum id title dir filename size age date author email description
        credits base buildtime editors bugs textfile rating votes reviews )]
        },
);

=back

=head2 Methods

=over

=item new() (aka BUILD)

Creates the L<App::WADTools::idGamesFile> object.  You can populate individual
attributes in the object by passing them as part of the object constructor.
See the L<SYNOPSIS> section for an example.

=back

=cut

1;
