#############################
# App::WADTools::WADIndexer #
#############################
package App::WADTools::WADIndexer;
use strict;
use warnings;
use Data::Hexdumper;
use Fcntl qw(:seek);
use Log::Log4perl;
use Moo;

use constant {
    WAD_DIRECTORY_ENTRY_SIZE => 16,
    WAD_HEADER_SIZE          => 12,
};

=head2 App::WADTools::WADIndexer

An object used for storing configuration data.

=head3 Object Methods

=over

=item new( ) (aka BUILD)

Creates a new WADIndexer object, returns it to the caller.

=cut

=item index( )

Indexes the contents of a WAD file, and displays the information on the
screen.

=cut

sub index {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger();

    $log->logdie(q(Missing 'tempdir' argument))
        unless ( defined $args{tempdir} );
    $log->logdie(q(Missing 'files' argument))
        unless ( defined $args{files} );

    FILE: foreach my $filename ( @{$args{files}} ) {
        # skip dotfiles
        if ( $filename =~ m!/\.\w+! ) {
            $log->debug(qq(Skipping dotfile '$filename'));
            next FILE;
        }
        my $wadfile = $args{tempdir} . q(/) . $filename;
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
                $i, $lump_name, $lump_size, $lump_start));
        }
        close($WAD);
    }
}

=back

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
1;
