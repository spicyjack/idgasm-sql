################################
# App::WADTools::Roles::Keysum #
################################
package App::WADTools::Roles::Keysum;

=head1 NAME

App::WADTools::Roles::Keysum

=head1 SYNOPSIS

Generate a C<keysum>, or a checksum that is used as a unique key.

=head1 DESCRIPTION

The C<keysum> of a file is a combination of a file's C<directory>,
C<filename>, and C<size>.

=cut

### System modules
# 'Moo::Role' calls 'strictures', which is 'strict' + 'warnings'
use Moo::Role;
use Digest::CRC;
use Digest::MD5;
use Digest::SHA;
#use Math::Base36 qw(encode_base36);
use Math::BaseCalc;
#use POSIX qw(strtol);
use Log::Log4perl;

# more ideas on converting to base36:
# - # http://stackoverflow.com/questions/2670869/whats-the-best-way-to-do-base36-arithmetic-in-perl
# - https://metacpan.org/pod/Math::BaseCalc
# - https://metacpan.org/pod/Math::Int2Base
# - strol in # https://metacpan.org/pod/release/RJBS/perl-5.18.2/ext/POSIX/lib/POSIX.pod#FUNCTIONS

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

=item generate_base36_checksum(data => $data)

Using the data passed in as C<$data>, generate an MD5 checksum of the data,
and then convert it to C<Base36> (L<http://en.wikipedia.org/wiki/Base36>).

Returns the converted data to the caller, or C<undef> if there was an error.

Required arguments:

=over

=item data

The data to use for the MD5 checksum.  The output of the MD5 checksum is
converted to C<Base36> prior to returning it to the caller.

=cut

sub generate_base36_checksum {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing required argument 'data'))
        unless ( exists $args{data} );

    $log->debug(q(Data: ) . $args{data});
    # for conversion of the checksum to decimal
    my $hex_to_dec = Math::BaseCalc->new(digits => q(hex));
    my $dec_to_base36 = Math::BaseCalc->new(
        digits => [q(0) .. q(9), q(a) .. q(z)],
    );
    # create the checksum context
    #my $ctx = Digest::CRC->new(type => "crc16");
    my $ctx = Digest::CRC->new(type => "crc32");
    # add data to the context
    $ctx->add($args{data});
    # get a hex digest, convert to decimal
    my $digest = $hex_to_dec->from_base($ctx->hexdigest);
    $log->debug(qq(Decimal digest of data: $digest));
    # convert to base36
    #use App::WADTools::Timer;
    #my $timer = App::WADTools::Timer->new();

=begin COMMENT

    $timer->start(name => q(posix));
    my ($base36, $num_unparsed) = POSIX::strtol($digest, 36);
    $timer->stop(name => q(posix));
    $log->debug(qq(POSIX time:          ) . sprintf(q|%0.8f second(s)|,
        $timer->time_value_difference(name => q(posix)))
    );
    $timer->delete(name => q(posix));
    $log->debug(qq(POSIX digest:          $base36));
    $log->debug(qq(Unparsed: $num_unparsed));
    $log->debug(qq(Translation errors: $!));

    $timer->start(name => q(encode_base36));
    $base36 = lc(encode_base36($digest));
    $timer->stop(name => q(encode_base36));
    $log->debug(qq(Math::Base36 time:   ) . sprintf(q|%0.8f second(s)|,
        $timer->time_value_difference(name => q(encode_base36)))
    );
    $timer->delete(name => q(encode_base36));
    $log->debug(qq(Math::Base36 digest:   $base36));

=end COMMENT

=cut

    #$timer->start(name => q(math_basecalc));
    # then convert the decimal digest to Base36
    my $base36 = $dec_to_base36->to_base($digest);
    #$timer->stop(name => q(math_basecalc));
    #$log->debug(qq(Math::BaseCalc checksum compute time: )
    #    . sprintf(q|%0.8f second(s)|,
    #    $timer->time_value_difference(name => q(math_basecalc)))
    #);
    #$timer->delete(name => q(math_basecalc));
    #$log->debug(qq(Math::BaseCalc digest: $base36));

    # lowercase alpha to prevent confusion over similar characters
    # (0/O, 1/L, 8/B, 5/S; http://en.wikipedia.org/wiki/Base36)
    # - not needed if it's decided to use Math::BaseCalc
    #$base36 = lc($base36);
    #$log->debug(qq(Converted Base36 keysum: $base36));

    return $base36
}

=item generate_keysum()

Generate a unique C<key> (called a B<keysum>, C<key> + C<checksum>), using the
MD5 checksum of the B<filename> + B<file size> + B<file's MD5 checksum>, and
converted to C<base36> (L<http://en.wikipedia.org/wiki/Base36>) notation.
Stores the keysum in the L<keysum> parameter, as well as returning it to the
caller.

=cut

sub generate_keysum {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $self->keysum($self->generate_base36_checksum(
        data => $self->filename . q(:) . $self->size)
    );
    $log->debug(qq(Created keysum: ) . $self->keysum);
    return $self->keysum;
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
