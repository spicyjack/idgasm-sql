#############################
# App::WADTools::WADIndexer #
#############################
package App::WADTools::WADIndexer;

=head1 NAME

App::WADTools::WADIndexer

=head1 SYNOPSIS

 my $indexer = App::WADTools::WADIndexer->new();
 my $wadfile = $indexer->index(wadfile => q(/path/to/file.wad);
 print q(Levels in this WAD file: ) . join($wadfile->levels) . qq(\n);

=head1 DESCRIPTION

C<WADIndexer> is an object that reads a C<WAD> file, then indexes and/or
catalogs the data contained inside of the C<WAD> file, and returns the indexed
data as an C<App::WADTools::WADFile> object to the caller.

=cut

# system modules
# 'Moo' calls 'strictures', which is 'strict' + 'warnings'
use Data::Hexdumper;
use Fcntl qw(:seek);
use Log::Log4perl;
use Moo;

use constant {
    WAD_DIRECTORY_ENTRY_SIZE => 16,
    WAD_HEADER_SIZE          => 12,
};

=head2 Attributes

=over

=item filename

A filename to the C<SQLite> database file.  If the file does not exist, a new
file will be created.

=back

=cut

has idx_db => (
    is      => q(rw),
    default => sub{ undef; },
    # returns true if the argument is a DBI object
    #isa => sub { (ref($_[0]) eq q(DBI)) ? 1 : 0 },
);

=head2 Methods

=over

=item new(idx_db => $dbh) (aka BUILD)

Creates a new WADIndexer object, returns it to the caller.

Optional arguments:

=over

=item idx_db

The L<DBI> database handle to an existing C<index> database that has already
had the C<connect()> method called on it.  The database is usually created
with the C<db_tool> script and the C<wad_index.ini> schema file.

=back

=item index(unzip_dir => $dir, $files => \@files)

Indexes the contents of a WAD file, and displays the information on the
screen.

Required arguments:

=over

=item unzip_dir

A path to the directory where the C<.zip> file was unzipped

=item files

A reference to an array of filenames that the method should index and
optionally, add to the database.

=back

=cut

sub index {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing 'unzip_dir' argument))
        unless ( defined $args{unzip_dir} );
    $log->logdie(q(Missing 'files' argument))
        unless ( defined $args{files} );

    FILE: foreach my $filename ( @{$args{files}} ) {
        # skip dotfiles
        if ( $filename =~ m!/\.\w+! ) {
            $log->debug(qq(Skipping dotfile '$filename'));
            next FILE;
        }
        my $wadfile = $args{unzip_dir} . q(/) . $filename;
        $log->info(qq(Reading WAD info from '$filename'));
        open(my $WAD, qq(<$wadfile))
            or $log->logdie(qq(Failed to open WAD file '$wadfile': $!));
        my $header;
        # read the header from the WAD file
        my $bytes_read = read( $WAD,$header, WAD_HEADER_SIZE );
        $log->logdie(qq(Failed to read header: $!))
            unless (defined $bytes_read);
        if ( $bytes_read != WAD_HEADER_SIZE ) {
            $log->error(qq(Only read $bytes_read bytes from header));
            $log->logdie(q(Header size is ) . WAD_HEADER_SIZE . q( bytes));
        }
        my ($wad_sig,$num_lumps,$dir_offset) = unpack("a4VV",$header);
        $log->info(qq(WAD signature: $wad_sig));
        $log->info(sprintf(q(Number of lumps in the WAD:  %u lumps),
            $num_lumps));
        $log->debug(sprintf(q(WAD directory start offset: +%u bytes),
            $dir_offset));
        for (my $i = 0; $i <= ($num_lumps - 1); $i++) {
            my $lump_entry;
            # reset bytes read
            $bytes_read = undef;
            # read this lump entry
            $log->debug(q(Reading directory entry at offset: )
                . ($dir_offset + ( $i * WAD_DIRECTORY_ENTRY_SIZE )));
            die(qq(Can't seek WAD directory entry: $!))
                unless (seek($WAD,
                    ($dir_offset
                    + ( $i * WAD_DIRECTORY_ENTRY_SIZE )),
                    SEEK_SET));
            $bytes_read = read($WAD, $lump_entry, WAD_DIRECTORY_ENTRY_SIZE);
            die "Failed to read WAD directory entry: $!"
                unless ( defined $bytes_read );
            die qq(Only read $bytes_read out of ) . WAD_DIRECTORY_ENTRY_SIZE
                . q( bytes in header)
                unless ( $bytes_read == WAD_DIRECTORY_ENTRY_SIZE );
            my ($hex_chars, $data) = split(/::/,
                hexdump(
                    data => $lump_entry,
                    output_format => q(%16C::%d),
            ));
            $log->debug(qq(-> lump raw data: $data));
            # nice header for displaying lump directory entry info
            $log->debug(
                qq(->|lump start | lump size | lump name             |));
            $log->debug(qq(-> $hex_chars));

            my ($lump_start, $lump_size, $lump_name) = unpack(q(VVa8),
                $lump_entry );
            $lump_name =~ s/\0+//g;
            $log->info(sprintf(q(lump %-4u name: %-8s size: %-8u start: %-8x),
                $i + 1, $lump_name, $lump_size, $lump_start));
        }
        close($WAD);
    }
}

=back

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
1;
