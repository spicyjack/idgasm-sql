##########################
# App::WADTools::WADFile #
##########################
package App::WADTools::WADFile;

=head1 NAME

App::WADTools::WADFile

=head1 SYNOPSIS

 my $wad = Archive::WADTools::WADFile->new( file => $wadfile );
 my $wad_members = $wad->get_wad_members;
 print q(WAD members: ) . join(q(, ), @{$wad_members});
 $wad->extract_members(files => $wad_members, $tempdir => q(/tmp));

=head1 DESCRIPTION

This object manages files compressed in C<WAD> format.  This object can
provide a listing of the contents of a WAD file, as well as obtain checksums
of the WAD file.  This object inherits methods and attributes from
L<App::WADTools::Roles::File>; please see the documentation for that role for
more information on the methods/attributes it provides.

=cut

### System modules
# 'Moo' calls 'strictures', which is 'strict' + 'warnings'
use Moo;
use Log::Log4perl;

### Roles
with qw(
    App::WADTools::Roles::File
    App::WADTools::Roles::Keysum
);

=head2 Attributes

=over

=item levels

A list of level lumps (levels) that this C<WAD> file provides.

=cut

has q(levels) => (
    is      => q(rw),
    isa     => sub { ref($_[0]) =~ /ARRAY/ },
    default => sub { [] },
);

=item lumps

A list of L<App::WADTools::WADLump> lump objects (levels) that this C<WAD>
file provides.  A L<App::WADTools::WADLump> object describes individual lumps
inside the C<WAD> file.

=cut

has q(lumps) => (
    is      => q(rw),
    isa     => sub { ref($_[0]) =~ /ARRAY/ },
    default => sub { [] },
);

=item num_of_lumps

The number of lumps contained in this WAD.  Provided by counting the number of
members in the array that's contained in the L<lumps> attribute.

=cut

has q(num_of_lumps) => (
    is      => q(rw),
    isa     => sub { $_[0] =~ /\d+/ },
    default => sub { 0 },
);

=item wad_filename

The WAD's filename inside the the containing C<.zip> file.

=cut

has q(wad_filename) => (
    is => q(rw),
);

=item wad_id

The WAD's "ID", or type of WAD.  Can be either C<IWAD> or C<PWAD>.

=cut

has q(wad_id) => (
    is => q(rw),
    # either IWAD or PWAD, case sensitive, nothing else allowed
    isa => sub { $_[0] =~ /[IP]WAD/; },
);

=back

=head2 Methods

=over

=item new(filepath => $wad_path) (aka BUILD)

Creates a L<App::WADTools::WADFile> object with the file passed in as
C<wadfile> in the constructor.  This method populates the WAD file's object
attributes, including MD5/SHA checksums.

Required arguments:

=over

=item filepath

The full path to the C<*.wad> file that this object will work with.

=back

=cut

sub BUILD {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->debug(q(Reading file: ) . $self->filepath);

    # generate filehandle is called here, because the Role won't run a BUILD
    # method prior to this BUILD method being run
    # the checksum methods use filehandles, not filenames
    $self->generate_filehandle();
    $self->generate_filedir_filename();
    return $self;
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

    perldoc App::WADTools::WADFile

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
1;
