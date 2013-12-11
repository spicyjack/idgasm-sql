########################################
# package App::WADTools::Roles::Parser #
########################################
package App::WADTools::Roles::Parser;

=head1 App::WADTools::Roles::Parser

A role for methods/attributes common to both the JSON and XML parsers.

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

=cut

1;
