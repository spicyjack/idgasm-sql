##################################
# package App::idgasmTools::File #
##################################
package App::idgasmTools::File;

=head1 App::idgasmTools::File

An individual file in C<idGames Archive>.  The information in this object is
taken from the C<*.txt> file that is uploaded with each file to C<idGames
Archive>.  Any issues/inaccuracies are most likely because the C<*.txt> file
was parsed incorrectly or was not parseable.

=cut

use Moo;

=head2 Attributes

=over

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
    isa => sub{ 1 };
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
    isa => sub{ length($_[0]) > 0 };
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

=back

=head2 Methods

=over

=item BUILD() (aka 'new')

Creates the L<App::idgasmTools::File> object, optionally with an error
message.

=cut

1;
