##########################
# App::WADTools::ZipTool #
##########################
package App::WADTools::ZipTool;
use strict;
use warnings;
use Archive::Zip qw(:ERROR_CODES);
use Log::Log4perl;

=head2 App::WADTools::ZipTool

An object used for storing configuration data.

=head3 Object Methods

=over

=item new(zipfile => $zipfile )

Creates an C<Archive::Zip> object and processes requests for information about
the zipfile.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless ({%args}, $class);
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $zip = Archive::Zip->new();
    my $zipfile = $self->{filename};
    $log->debug(qq(Reading zipfile: $zipfile));
    $log->logdie(qq(Can't read zipfile $zipfile))
        unless ( $zip->read($zipfile) == AZ_OK );
    $self->{_zip} = $zip;
    $log->debug("Calling zip->members");
    my @member_objs = $zip->members();
    my @members;
    foreach my $member ( @member_objs ) {
        push(@members, $member->fileName);
    }
    $self->{_members} = \@members;
    return $self;
}

=item get_zip_members( )

Returns all of the files contained inside of the zipfile.

=cut

sub get_zip_members {
    my $self = shift;
    my $zip = $self->{_zip};
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    return @{$self->{_members}};
}

=item extract_files(files => \@files)

Extracts all of the files listed in the array C<@files> from the zipfile and
returns a scalar containing the path to the temporary directory that the files
were extracted into.

=cut

sub extract_files {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $zip = $self->{_zip};
    my $tempdir = $args{tempdir};

    my %file_temp_opts;
    if ( defined $tempdir ) {
        %file_temp_opts = (
            DIR         => $tempdir,
            TEMPLATE    => qq(wadindex.XXXXXXXX),
        );
    } else {
        %file_temp_opts = (
            TMPDIR      => 1,
            TEMPLATE    => qq(wadindex.XXXXXXXX),
        );
    }
    my $dh = File::Temp->newdir(%file_temp_opts);

    $log->debug(qq(Created temp dir ) . $dh->dirname);
    foreach my $file ( @{$args{files}} ) {
        $log->debug(qq(- extracting: $file));
        my $temp_file = $dh->dirname . q(/) . $file;
        my $unzip_status = eval{$zip->extractMemberWithoutPaths(
            $file, $temp_file);};
        if ( $unzip_status != AZ_OK ) {
            $log->error(qq(Could not unzip $file));
            return undef;
        }
        $log->debug(q(- done extracting: ) . $file);
    }
    return $dh;
}

=back

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
1;
