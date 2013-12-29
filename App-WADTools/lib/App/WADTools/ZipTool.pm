##########################
# App::WADTools::ZipTool #
##########################
package App::WADTools::ZipTool;

=head1 NAME

App::WADTools::ZipFile

=head1 SYNOPSIS

This object keeps track of a file compressed in C<.zip> format.  This object
will read the contents of the zip file, as well as obtain checksums of the
zipfile.

=head1 DESCRIPTION

Provides a listing of the zipfile's contents, and checksums of the zipfile.

=cut
use Archive::Zip qw(:ERROR_CODES);
use Digest::MD5;
use Digest::SHA;
use Log::Log4perl;
# 'Moo' calls 'strictures', which is 'strict' + 'warnings'
use Moo;

=head2 Attributes

=over

=item zipfile

The zipfile to work with.

=back

=cut

has q(zipfile) => (
    is => q(rw),
    #isa
);

=head2 Methods

=over

=item new(zipfile => $zipfile) (aka BUILD)

Creates a L<App::WADTools::ZipFile> object, and populates the zipfile's object
attributes, including MD5/SHA checksums.

=cut

sub BUILD {
    my $class = shift;
    my %args = @_;
    my $self = bless ({%args}, $class);
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $zip = Archive::Zip->new();
    my $zipfile = $self->zipfile;
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
