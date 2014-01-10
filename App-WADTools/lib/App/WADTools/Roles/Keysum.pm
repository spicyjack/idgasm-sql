################################
# App::WADTools::Roles::Keysum #
################################
package App::WADTools::Roles::Keysum;

=head1 NAME

App::WADTools::Roles::Keysum

=head1 SYNOPSIS

Generate a C<keysum>, or a checksum that is used as a unique key.

=head1 DESCRIPTION

Generate a C<keysum>, or a checksum that is used as a unique key.

=cut

### System modules
# 'Moo::Role' calls 'strictures', which is 'strict' + 'warnings'
use Moo::Role;
use Digest::MD5;
use Digest::SHA;
use Log::Log4perl;

=head2 Attributes

=over

=item keysum

The file's C<keysum>, or a combination of B<directory>, B<filename>, and
B<file size>.

=cut

has q(keysum) => (
    is   => q(rw),
    isa  => sub { 1 },
);

=back

=head2 Methods

=over

=item generate_keysum()

Generate a unique C<key> (called a B<keysum>, C<key> + C<checksum>), using the
MD5 checksum of the B<filename> + B<file size> + B<file's MD5 checksum>, and
converted to C<base36> (L<http://en.wikipedia.org/wiki/Base36>) notation.
Stores the keysum in the L<keysum> parameter, as well as returning it to the
caller.

=cut

sub generate_keysum {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $md5 = Digest::MD5->new();
    $md5->add($self->dir . $self->filename . $self->size);
    my $digest = $md5->hexdigest;
    $log->debug(qq(Computed keysum MD5 of $digest));
    my $base36 = encode_base36(hex $md5->hexdigest);
    $log->debug(qq(Converted MD5 keysum to base36: $base36));
    $self->keysum($base36);
    return $base36
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

    perldoc App::WADTools::Roles::Keysum

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
1;
