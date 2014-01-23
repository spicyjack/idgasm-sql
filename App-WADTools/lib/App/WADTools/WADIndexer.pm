#############################
# App::WADTools::WADIndexer #
#############################
package App::WADTools::WADIndexer;

=head1 NAME

App::WADTools::WADIndexer

=head1 SYNOPSIS

 my $indexer = App::WADTools::WADIndexer->new();
 my $wadfile = $indexer->index_wad(
    path     => q(/path/to/wadfiles),
    filename => q(file.wad),
 );
 print q(Levels in this WAD file: ) . join($wadfile->levels) . qq(\n);

=head1 DESCRIPTION

C<WADIndexer> is an object that reads a C<WAD> file, then indexes and/or
catalogs the data contained inside of the C<WAD> file, and returns the indexed
data as an C<App::WADTools::WADFile> object to the caller.

=cut

### System modules
# 'Moo' calls 'strictures', which is 'strict' + 'warnings'
use Data::Hexdumper;
use Fcntl qw(:seek); # for random byte access to files
use Log::Log4perl;
use Moo;

### Local modules
use App::WADTools::Error;
use App::WADTools::WADFile;

use constant {
    WAD_DIRECTORY_ENTRY_SIZE => 16,
    WAD_HEADER_SIZE          => 12,
};

my $lump_level_regex = qr/^MAP[0-4][0-9]$|^E[1-4]M[1-9]$/;

=head2 Attributes

=over

=item wad_index_time

The time required to index the WAD file.

=cut

has q(wad_index_time) => (
    is      => q(rw),
    default => sub{ 0 },
);

=back

=head2 Methods

=over

=item new() (aka BUILD)

Creates a new WADIndexer object, returns it to the caller.

=item index_wad_list(unzip_dir => $dir, $files => \@files)

Indexes a list of WAD files, and displays the information on the screen.

Required arguments:

=over

=item unzip_dir

A path to the directory where the C<.zip> file was unzipped

=item files

A reference to an array of filenames that the method should index and
return to the caller.

=back

=cut

sub index_wad_list {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing 'unzip_dir' argument))
        unless ( defined $args{unzip_dir} );
    $log->logdie(q(Missing 'files' argument))
        unless ( defined $args{files} );

    my @wadlist;
    my $total_wad_index_time = 0;
    FILE: foreach my $filename ( @{$args{files}} ) {
        # skip dotfiles
        if ( $filename =~ m!/\.\w+! ) {
            $log->debug(qq(Skipping dotfile '$filename'));
            next FILE;
        }
        my $wadpath = $args{unzip_dir} . q(/) . $filename;
        my $wadfile = $self->index_wad(
            path         => $args{path},
            wad_filename => $filename
        );
        if ( $wadfile->can(q(is_error)) ) {
            $log->error("Error indexing WAD file;");
            $wadfile->log_error();
        } else {
            $total_wad_index_time += $self->wad_index_time;
            # push the indexed WAD onto the list of WADs
            push(@wadlist, $wadfile);
        }
    }
    # set the total accumulated time required to index all of the WADs
    $self->wad_index_time($total_wad_index_time);
    return @wadlist;
}

=item index_wad(wadpath => q(/path/to/file.wad))

Indexes the contents of a WAD file, and displays the information on the
screen.  Returns an L<App::WADTools::WADFile> object if the WAD file argument
could be read and parsed, returns C<undef>, if the file is not parseable (file
is a "dotfile" for example), or an L<App::WADTools::Error> object if there was
an error indexing the WAD file.

Required arguments:

=over

=item wadpath

The path to a WAD file.

=back

=cut

sub index_wad {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing 'path' argument))
        unless ( defined $args{path} );
    $log->logdie(q(Missing 'filename' argument))
        unless ( defined $args{filename} );

    # create local variables from method arguments
    my $filename = $args{filename};
    my $path = $args{path};
    my $wad_path = $path . q(/) . $filename;

    # skip dotfiles
    if ( $filename =~ m!/\.\w+! ) {
        $log->info(qq(Skipping dotfile '$filename'));
        return undef;
    }

    # create the WADFile object here
    my $wadfile = App::WADTools::WADFile->new(
        filepath     => $wad_path,

    );
    # generate_filehandle() and generate_dirname_basename() is already called
    # in the BUILD method
    $wadfile->gen_md5_checksum();
    $wadfile->gen_sha_checksum();

    $log->info(qq(Reading WAD info from '$filename'));
    # start the timer
    my $timer = App::WADTools::Timer->new();
    $timer->start(name => q(index_wad));
    my $status = open(my $WAD, qq(<$wad_path));

    if ( ! defined $status ) {
        $log->logdie(qq(Failed to open WAD file '$wad_path': $!));
        my $error = App::WADTools::Error->new(
            caller    => __PACKAGE__ . q(.) . __LINE__,
            type      => q(wadindexer.index_wad.opening_file),
            message   => qq(Can't open file: $wad_path),
            raw_error => qq(Error code: $!),
        );
        # stop the timer
        $timer->stop(name => q(index_wad));
        # calculate the time difference
        $self->wad_index_time(
            $timer->time_value_difference(name => q(index_wad))
        );
        return $error;
    }
    my $header;



    # read the header from the WAD file
    my $bytes_read = read( $WAD, $header, WAD_HEADER_SIZE );
    $log->logdie(qq(Failed to read header: $!))
        unless (defined $bytes_read);
    if ( $bytes_read != WAD_HEADER_SIZE ) {
        $log->error(qq(Only read $bytes_read bytes from header));
        $log->logdie(q(Header size is ) . WAD_HEADER_SIZE . q( bytes));
        my $error = App::WADTools::Error->new(
            caller    => __PACKAGE__ . q(.) . __LINE__,
            type      => q(wadindexer.index_wad.read_header),
            message   => qq(Read only $bytes_read bytes from WAD header),
            raw_error => q(Expected WAD header size: ) . WAD_HEADER_SIZE,
        );
        # stop the timer
        $timer->stop(name => q(index_wad));
        # calculate the time difference
        $self->wad_index_time(
            $timer->time_value_difference(name => q(index_wad))
        );
        return $error;
    }

    # Unpack the header and add to the wadfile object
    my ($wad_id,$num_lumps,$dir_offset) = unpack("a4VV",$header);
    $wadfile->wad_id($wad_id);
    $wadfile->num_of_lumps($num_lumps);

    $log->info(q(WAD ID: ) . $wadfile->wad_id);
    $log->info(sprintf(q(Number of lumps in the WAD:  %8u lumps),
        $wadfile->num_of_lumps));
    $log->debug(sprintf(q(WAD directory start offset: +%8u bytes),
        $dir_offset));
    if ( $dir_offset > $wadfile->size ) {
        my $error = App::WADTools::Error->new(
            caller    => __PACKAGE__ . q(.) . __LINE__,
            type      => q(wadindexer.index_wad.dir_offset_larger_than_file),
            message   => qq|Directory offset is larger than WAD file size|,
            raw_error => qq|Directory offset: $dir_offset; |
                . qq|WAD file size: | . $wadfile->size,
        );
        # stop the timer
        $timer->stop(name => q(index_wad));
        # calculate the time difference
        $self->wad_index_time(
            $timer->time_value_difference(name => q(index_wad))
        );
        return $error;
    }
    for (my $i = 0; $i <= ($num_lumps - 1); $i++) {
        my $lump_entry;
        # reset bytes read
        $bytes_read = undef;
        # read this lump entry
        $log->debug(q(Reading directory entry at offset: )
            . ($dir_offset + ( $i * WAD_DIRECTORY_ENTRY_SIZE )));
        $log->logdie(qq(Can't seek WAD directory entry: $!))
            unless (
        my $seek_status = seek($WAD,
                ($dir_offset
                + ( $i * WAD_DIRECTORY_ENTRY_SIZE )),
                SEEK_SET));
        # check the status of the seek
        if ( ! $seek_status ) {
            my $error = App::WADTools::Error->new(
                caller    => __PACKAGE__ . q(.) . __LINE__,
                type      => q(wadindexer.index_wad.seek_directory_entry),
                message   => qq(Could not seek to directory entry # $i),
                raw_error => qq(Error code: $!),
            );
            # stop the timer
            $timer->stop(name => q(index_wad));
            # calculate the time difference
            $self->wad_index_time(
                $timer->time_value_difference(name => q(index_wad))
            );
            return $error;
        }

        $bytes_read = read($WAD, $lump_entry, WAD_DIRECTORY_ENTRY_SIZE);
        # check for a successful read
        if ( ! defined $bytes_read || $bytes_read < WAD_DIRECTORY_ENTRY_SIZE ) {
            my $error = App::WADTools::Error->new(
                caller    => __PACKAGE__ . q(.) . __LINE__,
                type      => q(wadindexer.index_wad.read_directory_entry),
                message   => qq(Read $bytes_read bytes from WAD directory),
                raw_error => qq(Error code: $!),
            );
            # stop the timer
            $timer->stop(name => q(index_wad));
            # calculate the time difference
            $self->wad_index_time(
                $timer->time_value_difference(name => q(index_wad))
            );
            return $error;
        }
        # use split to parse the output of a hexdump with a special format
        my ($hex_chars, $data) = split(/::/,
            hexdump(
                data => $lump_entry,
                output_format => q(%16C::%d))
        );
        $log->debug(qq(-> lump raw data: $data));
        # nice header for displaying lump directory entry info
        $log->debug(
            qq(->|lump start | lump size | lump name             |));
        $log->debug(qq(-> $hex_chars));

        # get the start, size and name of the lump via unpack()
        my ($lump_start, $lump_size, $lump_name) = unpack(q(VVa8),
            $lump_entry );

        # strip trailing 'NUL' characters
        $lump_name =~ s/\0+//g;

        # - detect lump name here using the regex
        # - add level lumps to WADFile
        if ( $lump_name =~ $lump_level_regex ) {
            $log->debug(qq(Lump name matched regex; lump name: $lump_name));
            my @levels;
            if ( defined $wadfile->levels ) {
                @levels = @{$wadfile->levels};
            }
            push(@levels, $lump_name);
            $log->debug(q(Total levels for this WAD; )
                . scalar(@levels) . q( levels));
            $log->debug(join(q(, ), @levels));
            $wadfile->levels(\@levels);
        }

        $log->info(sprintf(q(lump %-4u: %-8s size: %-8u start: %-8x),
            $i + 1, $lump_name, $lump_size, $lump_start));
    }
    close($WAD);

    # stop the timer
    $timer->stop(name => q(index_wad));
    # calculate the time difference
    $self->wad_index_time(
        $timer->time_value_difference(name => q(index_wad))
    );

    return $wadfile;
}

=back

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
1;
