########################################
# package App::WADTools::Roles::Parser #
########################################
package App::WADTools::Roles::Parser;

=head1 NAME

App::WADTools::Roles::Parser

=head1 SYNOPSIS

 # in another object...
 use Moo;
 with qw(App::WADTools::Roles::Parser);

=head1 DESCRIPTION

A role that provides methods/attributes that are common to both the JSON and
XML parsers.

=cut

### System modules
use Moo::Role;

=head2 Attributes

=over

=item save_textfile

Saves the "textfile", the contents of the C<*.txt> file that is uploaded with
each C<*.zip> file to the C<idGames Archive>.  This can add significant
storage requirements to the database, so by default this attribute is C<0>,
false.

=cut

has q(save_textfile) => (
    is      => q(rw),
    isa     => sub { $_[0] =~ /0|1|n|no|y|yes/i },
    coerce  => sub {
                    my $arg = $_[0];
                    if ( $arg =~ /0|n|no/i ) { return 0; }
                    if ( $arg =~ /1|y|yes/i ) { return 1; }
                },
    default => sub { 0 },
);

=back

=head1 AUTHOR

Brian Manning, C<< <brian at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker for
this project:

C<< <https://github.com/spicyjack/wadtools/issues> >>.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

    perldoc App::WADTools::Vote

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
