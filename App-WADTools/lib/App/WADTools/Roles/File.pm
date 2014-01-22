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
use File::Basename;
use Log::Log4perl;

### Local modules
use App::WADTools::Timer;

=head2 Attributes

=over

=item filedir

The dirname part of the filepath.  Defaults to C<undef>.

=cut

has q(filedir) => (
    is => q(rw),
    default => sub { undef; },
);

=item filehandle

A filehandle to the file, created as an L<IO::File> object (which inherts from
L<IO::Handle>).

=cut

has q(filehandle) => (
    is   => q(rw),
    isa  => sub {
                die qq('filehandle' is not an 'IO::File', but a ) . ref($_[0])
                    unless ref($_[0]) eq q(IO::File) },
);

=item filename

The filename part of the filepath.  Defaults to C<undef>.

=cut

has q(filename) => (
    is => q(rw),
    default => sub { undef; },
);

=item filepath

The name of the file as it exists on the filesystem.

=cut

has q(filepath) => (
    is => q(rw),
    # check that the file exists
    isa => sub { -f $_[0] },
);

=item md5_checksum

The file's MD5 checksum.  Defaults to C<undef>.

=cut

has q(md5_checksum) => (
    is => q(rw),
    default => sub{ undef },
    #isa
);

=item md5_checksum_gen_time

The time, in seconds, that was required to generate file's MD5 checksum.

=cut

has q(md5_checksum_gen_time) => (
    is => q(rw),
    default => sub{ 0 },
);

=item sha_checksum

The file's SHA1 checksum.  Defaults to C<undef>.

=cut

has q(sha_checksum) => (
    is => q(rw),
    default => sub{ undef },
    #isa
);

=item sha_checksum_gen_time

The time, in seconds, that was required to generate file's SHA checksum.

=cut

has q(sha_checksum_gen_time) => (
    is => q(rw),
    default => sub{ 0 },
);

=back

=head2 Methods

=over

=item generate_filedir_filename

Generates the C<dirname>/C<basename> attributes, by calling L<File::Basename>
on the C<filepath> attribute.

=cut

sub generate_filedir_filename {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $self->filedir(dirname($self->filepath));
    $self->filename(basename($self->filepath));
}

=item generate_filehandle

Creates a read-only L<IO::File> object using the C<filepath> attribute, and
stores it in the C<filehandle> attribute for other objects to use.  Also sets
C<binmode> on the filehandle.

=cut

sub generate_filehandle {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    #$log->debug(q(filepath: ) . $self->filepath);
    $self->filehandle(IO::File->new($self->filepath, q(r)));
    #$log->debug(q(filehandle isa: ) . ref($self->filehandle));
    $self->filehandle->binmode;
}

=item gen_md5_checksum()

Generates a Base64 MD5 checksum of the file using the filehandle that was
created when the L<generate_filehandle()> method was called.  The checksum is
stored in the object's C<md5_checksum> attribute.  This method will also
populate the attribute L<md5_checksum_gen_time> with the elapsed time required
to generate the checksum.  Returns the generated checksum to the caller.

=cut

sub gen_md5_checksum {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $timer = App::WADTools::Timer->new();
    $timer->start(name=> q(generate_md5_checksum));
    my $md5 = Digest::MD5->new();
    $md5->addfile($self->filehandle);
    my $digest = $md5->b64digest;
    $timer->stop(name=> q(generate_md5_checksum));
    $self->md5_checksum($digest);
    $self->md5_checksum_gen_time(
        $timer->time_value_difference(name => q(generate_md5_checksum))
    );

    return $digest;
}

=item gen_sha_checksum()

Generates a Base64 SHA1 checksum of the file using the filehandle that was
created when the L<generate_filehandle()> method was called.  The checksum is
stored in the object's C<sha_checksum> attribute.  This method will also
populate the attribute L<sha_checksum_gen_time> with the elapsed time required
to generate the checksum.  Returns the generated checksum to the caller.

=cut

sub gen_sha_checksum {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $timer = App::WADTools::Timer->new();
    $timer->start(name=> q(generate_sha_checksum));
    my $sha = Digest::SHA->new(q(sha1));
    $sha->addfile($self->filehandle);
    my $digest = $sha->b64digest;
    $timer->stop(name=> q(generate_sha_checksum));
    $self->sha_checksum($digest);
    $self->sha_checksum_gen_time(
        $timer->time_value_difference(name => q(generate_sha_checksum))
    );

    return $digest;
}

=item pad_base64_digest($base64_string)

Pads the output of an MD5 or SHA digest that was output as a Base64 string, so
that other implementations of Base64 will parse this Base64 string correctly.
Implementation taken from comments/code in the C<Digest::SHA> module.  Accepts
a scalar containing the Base64 string to be padded, returns the string padded
with the equals sign C<=> as needed to make the length of the file divisible
by 4.

=cut

sub pad_base64_digest {
    my $self = shift;
    my $base64 = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    while (length($base64) % 4) {
        $base64 .= '=';
    }
    return $base64;
}

=item size

Returns the size of the file, in bytes, or undef if the file is not readable.

=cut

sub size {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # the 'filepath' attribute should already set and checked to verify that
    # it's a valid file
    return -s $self->filepath;
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

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
1;
