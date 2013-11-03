######################################
# package App::idgasmDBTools::INIFile #
######################################
package App::idgasmDBTools::INIFile;

=head1 App::idgasmDBTools::INIFile

INIFileure/manage script options using L<Getopt::Long>.

=cut

use Moo;

=head2 Attributes

=over

=item optoions

An C<ArrayRef> to an array containing script options, in L<Getopt::Long> format.

=cut

has q(options) => (
    is      => q(rw),
    isa     => q(ArrayRef[Str]),
);

=back

=head2 Methods

=over

=item new()

Creates the L<App::idgasmDBTools::INIFile> object

=item read_config(filename => $filename)

Reads the INI file specified by C<filename>, and returns a reference to the
hash data structure set up by C<Config::Std>.

=cut

sub read_config {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger("");

    $log->logdie(q(Missing argument 'filename'))
        unless (defined $args{filename});
    $log->logdie(q(Can't read file ) . $args{filename})
        unless (-r $args{filename});

    my $db_schema;
    read_config($args{filename} => $db_schema);
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
