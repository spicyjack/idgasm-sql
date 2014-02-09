######################################
# package App::WADTools::idGamesFile #
######################################
package App::WADTools::idGamesFile;

=head1 NAME

App::WADTools::idGamesFile

=head1 SYNOPSIS


 my $file = App::WADTools::idGamesFile->new();

 # the idGamesFile object keeps a list of it's attributes in the
 # "attributes" attribute
 my @attribs = @{$file->attributes};

 # go through all of the attributes in the $content object, copy
 # them to the same attributes in this File object
 # $content is a data structure representing a JSON or XML idGames API
 # response, parsed by one of the parsers provided by WADTools;

 foreach my $key ( @attribs ) {
    $file->{$key} = $content->{$key};
 }

 # dump the contents of this 'file' object as an INI-format SQL schema block
 my $ini_schema = $file->dump_ini_block;

=head1 DESCRIPTION

Information about an individual file in C<idGames Archive>.  The information in
this object was obtained by making API requests against the C<idGames Archive
API> (C</idgames>).  The information in the C<idGames Archive> was obtained by
parsing the C<*.txt> file that is uploaded with each file to C<idGames
Archive>.  Any issues/inaccuracies are most likely because the C<*.txt> file
was parsed incorrectly or was not in a parseable format, meaning the WAD
author did not use the C<idGames Archive> template file when he/she uploaded
their WAD.

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
L<App::WADTools::Vote> objects).

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
    # 'reviews' is in the attribute list even though it's an array; when the
    # File object is added to the database, the 'reviews' array is stripped
    # out and added to a different table in the database
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

=item dump_ini_block()

Dumps the current C<App::WADTools::idGamesFile> object as an "INI-block", or a
block of text in C<INI> format that can be read by other modules/scripts in
the C<WADTools> suite.

=cut

sub dump_ini_block {
    my $self = shift;

    # note that the 'reviews' attribute is not used below, as 'reviews' are in
    # their own table
    my $return = q|description: File object for file ID |
        . $self->id . qq|\n|
        . qq|notes: This is a file object that has been converted to INI\n|
        . qq|     : format by App::WADTools::idGamesFile->dump_ini_block\n|
        . qq|sql: INSERT INTO files VALUES (\n|;
    my @dont_quote = qw(id size age rating votes);
    foreach my $field ( @{$self->attributes} ) {
        # skip the fields we don't want to dump, because they're either too
        # hard to escape (textfile), or in a different table (reviews)
        next if ( $field =~ /reviews|textfile/ );
        # decide whether or not to quote the field; if the field needs to be
        # quoted, make sure you escape the existing quotes first
        if ( defined $self->$field ) {
            if ( scalar(grep(/$field/, @dont_quote)) > 0 ) {
                $return .= q(   : ) . $self->$field . qq(,\n);
            } else {
                my $field_contents = $self->$field;
                $field_contents =~ s/"/\\"/g;
                $return .= q(   : ") . $field_contents . qq(",\n);
            }
        } else {
            $return .= qq(   : "",\n);
        }
    }

    my $digest = Digest::MD5->new();
    # we want to checksum only 'description', 'notes', and 'sql'
    $digest->add($return);
    $return .= q(checksum: ) . $digest->b64digest . qq(\n\n);
    $return = q([) . $self->id . qq(]\n) . $return;
    return $return;
}

=back

=head1 AUTHOR

Brian Manning, C<< <brian at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker for
this project:

C<< <https://github.com/spicyjack/wadtools/issues> >>.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

    perldoc App::WADTools::idGamesFile

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
