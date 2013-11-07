#######################################
# package App::idgasmDBTools::INIFile #
#######################################
package App::idgasmDBTools::INIFile;
use Config::Std;
use Digest::MD5;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Moo;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

=head1 App::idgasmDBTools::INIFile

INIFileure/manage script options using L<Getopt::Long>.

=head2 Attributes

=over

=item filename

A filename to the C<INI> file that should be parsed.

=cut

has filename => (
    is      => q(rw),
    isa     => sub { die "$_[0] is not a valid filename" unless (-r $_[0]) },
);

=back

=head2 Methods

=over

=item new()

Creates the L<App::idgasmDBTools::INIFile> object.  Method is automatically
provided by the L<Moo> module as the C<BUILD> method.

=item md5_checksum()

Generates an C<MD5> checksum for each database transaction in the C<INI> file,
and appends the checksum to the C<INI> checksum field for that transaction.
Returns a reference to the updated C<INI> file as a reference to a
L<Config::Std> hash.

=cut

sub md5_checksum {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("");

    my $db_schema = $self->read_ini_config();
    # go through each field in each record of the INI file, and build a scalar
    # that combines all of the fields so a checksum can be generated against
    # the combined fields
    my $digest = Digest::MD5->new();
    my $data;
    foreach my $block_id ( sort(keys(%{$db_schema})) ) {
        $log->debug(qq(Parsing schema block: $block_id));
        my %block = %{$db_schema->{$block_id}};
        foreach my $block_key ( qw( description notes sql ) ){
            #$log->debug(qq(  $block_key: ) . $block{$block_key});
            $data .= $block{$block_key};
        }
        $log->debug(q(Combined fields are ) . length($data)
            . q| byte(s) in size|);
        $digest->add($data);
        my $checksum = $digest->b64digest;
        $log->debug(qq(Checksum: $checksum));
        $block{checksum} = $checksum;
        $db_schema->{$block_id} = \%block;
    }
    $log->debug(Dumper $db_schema);
    return $db_schema;
}

=item read_ini_config()

Reads the INI file specified by the C<filename> attribute, and returns a
reference to the hash data structure set up by C<Config::Std>.

=cut

sub read_ini_config {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("");

    my $db_schema;
    my $foo = $self->filename;
    $log->debug(q(Reading INI file ) . $self->filename);
    if ( -r $self->filename ) {
        read_config($self->filename => $db_schema);
        $log->debug(qq(Database schema dump...\n)
            . qq(==== Database Schema Dump Begins ====\n)
            . Dumper($db_schema)
            . q(==== Database Schema Dump Ends ====));
        my @transactions = keys(%{$db_schema});
        $log->debug(qq(Database transaction keys are: ));
        $log->debug(q(-> ) . join(qq(, ), sort(@transactions)));
        return $db_schema;
    } else {
        $log->logdie(q(Can't read INI file!));
    }
}

1;
