#################################
# package App::WADTools::DBTool #
#################################
package App::WADTools::DBTool;

=head1 NAME

App::WADTools::DBTool

=head1 SYNOPSIS

 # in the 'dump_o_matic' script
 my $db_tool = App::WADTools::DBTool->new();

=head1 DESCRIPTION

A tool that can read from and write to different database files, using a set
of tables that are given as part of the read/write commands.

This module is usually paired with L<App::WADTools::DumpController>, so that
the controller creates many L<App::WADTools::DBTool> objects, and coordinates
reading/writing data amongst them.

=cut

### System modules
use Moo;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

### Local modules
use App::WADTools::Error;

### Roles consumed
with qw(App::WADTools::Roles::Database);

=head2 Attributes

=over

=item controller

Required attribute.

The L<DumpController> object to send callbacks to.  Depending on what
L<DumpController> is being notified of, it will forward information on to the
C<View> object so that the user interface can be updated.

=cut

has q(controller) => (
    is      => q(rw),
    default => sub { },
    isa     => sub {
        # return a 1 if these callback methods are available, 0 otherwise
        ( $_[0]->can(q(request_update))
        && $_[0]->can(q(request_success))
        && $_[0]->can(q(request_failure)) ) ? 1 : 0;
    },

);

=back

=head2 Methods

=over

=item new() (aka 'BUILD')

Creates the L<App::WADTools::DBTool> object and returns it to the
caller.

=item db_connect()

Connects to the specified database, using the filename specified by the
C<filename> parameter.

=cut

=back

=head1 AUTHOR

Brian Manning, C<< <brian at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker for
this project:

C<< <https://github.com/spicyjack/wadtools/issues> >>.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

    perldoc App::WADTools::DBTool

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
