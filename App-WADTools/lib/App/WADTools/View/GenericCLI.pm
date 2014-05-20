###########################################
# package App::WADTools::View::GenericCLI #
###########################################
package App::WADTools::View::GenericCLI;

### System Modules
use 5.010;
use Moo;
use Term::ANSIColor;

my %_colors = (
    trace   => q(white on_black),
    debug   => q(bright_white on_black),
    info    => q(blue on_black),
    warn    => q(yellow on_black),
    error   => q(red on_black),
    fatal   => q(magenta on_black),
    success => q(green on_black),
    failure => q(red on_black),
);

my %_prefix = (
    trace => q(T: ),
    debug => q(D: ),
    info  => q(I: ),
    warn  => q(W: ),
    error => q(E: ),
    fatal => q(F: ),
);

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

=item update()

Show an update of the current request to the user.  Accepts the following
arguments:

=over

=item level (alias: 'lvl')

Optional argument: the log level, one of C<trace>, C<debug>, C<info>, C<warn>,
C<error>, C<fatal>.  If no log level arugment is used, the log level defaults
to B<info>.

=item message (alias: 'msg')

Required argument: The message to be output.

=back

=cut

sub update {
    my $self = shift;
    my %args = @_;

    my ($level, $message);
    if ( exists $args{lvl} ) {
        $level = $args{lvl};
    } elsif ( exists $args{level} ) {
        $level = $args{level};
    } else {
        $level = q(info);
    }
    say colored([$_colors{$args{level}}],
        $_prefix{$args{level}} . $args{message});
}

=item request_success()

Indicate to the user that the current request is complete, and was successful.

=cut

sub request_success {
    my $self = shift;
    my %args = @_;

    say colored([$_colors{success}], $args{message});
    #say q(Success! ) . $args{message};
}

=item request_failure()

Indicate to the user that the current request is complete, and the request
failed.  Also show the reason for the request failure.

=back

=cut

sub request_failure {
    my $self = shift;
    my %args = @_;

    say colored([$_colors{failure}], $args{message});
    #say q(Failure! ) . $args{message} . q| (| . $args{id} . q|)|;
}

1;
