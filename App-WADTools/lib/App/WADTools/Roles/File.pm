##############################
# App::WADTools::Roles::File #
##############################
package App::WADTools::Roles::File;

=head1 NAME

App::WADTools::Roles::File

=head1 SYNOPSIS

Common Methods dealing with file handling.

=head1 DESCRIPTION

This role contains methods common to both L<App::WADTools::ZipFile> and
L<App::WADTools::WADFile>, including getting file attributes from the
filesystem (file size, creation date, etc) and checksumming files.

=cut

### System modules
# 'Moo::Role' calls 'strictures', which is 'strict' + 'warnings'
use Moo::Role;
use Digest::MD5;
use Digest::SHA;
use Log::Log4perl;

=head2 Attributes

=over

=item file

The file that this role will work with.

=cut

has q(file) => (
    is => q(rw),
    # TODO check for a valid file here
    #isa
);

=item md5_checksum

The file's MD5 checksum

=cut

has q(md5_checksum) => (
    is => q(rw),
    default => sub{ q() },
    #isa
);

=item sha_checksum

The file's SHA1 checksum.

=cut

has q(sha_checksum) => (
    is => q(rw),
    default => sub{ q() },
    #isa
);

=head2 Methods

=over

=item gen_md5_checksum

Generates the MD5 checksum of the file stored in the C<file> attribute, stores
the checksum in the C<md5_checksum> attribute, and also returns it to the
caller.

=cut

sub gen_md5_checksum {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger
}

=item gen_sha_checksum

Generates the SHA checksum of the file stored in the C<file> attribute, stores
the checksum in the C<sha_checksum> attribute, and also returns it to the
caller.

=cut

sub gen_sha_checksum {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger
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

    perldoc App::WADTools::Roles::File

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
1;
