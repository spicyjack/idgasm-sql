###########################################
# package App::WADTools::View::GenericCLI #
###########################################
package App::WADTools::View::GenericCLI;

### System Modules
use 5.010;
use Moo;

=head1 NAME

App::WADTools::Views::CLI::Generic

=head1 SYNOPSIS

 my $view = App::WADTools::Views::CLI::Generic->new();
 my $controller = Some::Controller->new(view => $view);

 # in the Some::Controller object...
 $self->view->update_status(q(This is a status update));
 $self->view->update_view(<information for the view to update>);

=head1 DESCRIPTION

A generic CLI "view" object, that will accept C<View> callbacks and write them
to STDOUT.

=head2 Attributes

This object has no attributes.

=head2 Methods

=over

=item update_status()

Write a status message to C<STDOUT>.

=back

=cut

sub update_status{
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    say q(Update: ) . $args{level} . q(:) . $args{id};
    say q(Update: ) . $args{message};
}

1;
