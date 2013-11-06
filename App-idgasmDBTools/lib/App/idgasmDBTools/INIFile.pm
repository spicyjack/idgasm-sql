#######################################
# package App::idgasmDBTools::INIFile #
#######################################
package App::idgasmDBTools::INIFile;
use Digest::MD5;
use Moo;

=head1 App::idgasmDBTools::INIFile

INIFileure/manage script options using L<Getopt::Long>.

=head2 Attributes

=over

=item filename

A filename to the C<INI> file that should be parsed.

=cut

has q(filename) => (
    is      => q(rw),
    isa     => sub { die "$_[0] is not a valid filename" unless -r $_[0] },
);

=back

=head2 Methods

=over

=item new()

Creates the L<App::idgasmDBTools::INIFile> object.  Method is automatically
provided by the L<Moo> module.

=item md5_checksum()

Generates an C<MD5> checksum for each database transaction in the C<INI> file,
and appends the checksum to the C<INI> checksum field for that transaction.

=cut

sub md5_checksum {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("");
}

=item read_config()

Reads the INI file specified by the C<filename> attribute, and returns a
reference to the hash data structure set up by C<Config::Std>.

=cut

sub read_config {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("");

    my $db_schema;
    read_config($self->filename => $db_schema);
    $log->debug(qq(Database schema dump...\n)
        . qq(==== Database Schema Dump Begins ====\n)
        . Dumper($db_schema)
        . q(==== Database Schema Dump Ends ====));
    my @transactions = keys(%{$db_schema});
    $log->debug(qq(Database transaction keys are:\n)
        . join(qq(\n), @transactions)
        . qq(\n));
    return $db_schema;
}

1;
