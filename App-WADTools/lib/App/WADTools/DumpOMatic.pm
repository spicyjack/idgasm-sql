#########################################
# package App::WADTools::DumpController #
#########################################
package App::WADTools::DumpController;

=head1 NAME

App::WADTools::DumpController

=head1 SYNOPSIS

 # in the 'dump_o_matic' script
 my $controller = App::WADTools::DumpController->new();
 $controller->run();

=head1 DESCRIPTION

A controller (as in, Model-View-Controller design pattern for the
C<dump_o_matic> script.

=cut

# system modules
use Moo;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::WADTools::Error;

=head2 Attributes

=over

=item view

The view object, which controls the user interface shown to the user.

=cut

has q(view) => (
    is  => q(rw),
    #isa => sub{ ref($_[0]) eq q(App::WADTools::Views::DumpOMatic) },
);

=item model

The model object, which will handle reading and updating various databases.

=cut

has q(model) => (
    is  => q(rw),
    #isa => sub{ ref($_[0]) eq q(App::WADTools::DumpModel) },
);

=item ini_map

The L<Config::Std> object containing input and output objects for the object to
work with.  The L<Config::Std> object was created using the C<INI> file
specified by the C<--inifile> switch on the command line.

=cut

has q(ini_map) => (
    is  => q(rw),
    isa => sub{ ref($_[0]) =~ /HASH/ },
);

=item total_records

A count of the total number of records read in from all of the input
databases and written to the output database.

=cut

has q(total_records) => (
    is      => q(rw),
    isa     => sub{ $_[0] =~ /\d+/; },
    default => sub { 0 },
);

=back

=head2 Methods

=over

=item new() (aka 'BUILD')

Creates the L<App::WADTools::DumpController> object and returns it to the
caller.

=item run()

Transfers control of the program to the L<DumpController> object.

=cut

sub run {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $timer_name = q(dump_controller);
    # start the script timer
    my $timer = App::WADTools::Timer->new();
    $timer->start(name => $timer_name);

    my @input_blocks;
    my $output_block;
    # loop over each schema block, sort the blocks into input and output
    INI_BLOCK: foreach my $block_key ( keys(%{$self->ini_map}) ) {
        #print Dumper $block_key;
        $log->debug(qq(Block name: $block_key));
        $log->debug(qq(Block dump:\n) . Dumper($self->ini_map->{$block_key}));
        next if ( $block_key =~ /default/ );
        if ( $block_key =~ /^input/ ) {
            push(@input_blocks, $self->ini_map->{$block_key});
        } elsif ( $block_key =~ /^output/ ) {
            $output_block = $self->ini_map->{$block_key};
        } else {
            $log->warn(qq(Unrecognized block: $block_key));
        }
        $self->total_records($self->total_records + 1);
    }
    #my $out_db = App::WADTools::DBTool->new();

    $timer->stop(name => $timer_name);
    my $total_script_execution_time =
        $timer->time_value_difference(name => $timer_name);

    # FIXME tell the View to dump this stuff out
    #$log->warn(q(Total script execution time: )
    #    . sprintf(q(%0.2f), $total_script_execution_time) . q( seconds));
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

    perldoc App::WADTools::DumpController

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
