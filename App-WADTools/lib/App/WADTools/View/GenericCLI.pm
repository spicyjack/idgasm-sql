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

 my $view = App::WADTools::Views::CLI::Generic->new(cfg => $config);
 my $controller = Some::Controller->new(view => $view);

 # in the Some::Controller object...
 $self->view->update(q(This is a status update));
 $self->view->request_success(q(Information about request success));

=head1 DESCRIPTION

A generic CLI "view" object, that will accept C<View> callbacks and write them
to STDOUT.

=head2 Attributes

=item config

An L<App::WADTools::Config> object.

=cut

has q(config) => (
    is  => q(ro),
    isa => sub{ ref($_[0]) =~ /Config/ },
);

=item colorize

A flag to tell the L<GenericCLI> object whether or not to colorize the output
of the module.  When a L<GenericCLI> object is created, it checks the
L<App::WADTools::Config> object to see if the C<--colorize> flag was used, as
well as checking whether C<STDOUT> is connected to a terminal or a pipe, and
sets this flag to C<1> (true, colorize) or C<0> (false, don't colorize)
accordingly.

=cut

has q(colorize) => (
    is      => q(rwp),
    isa     => sub{ $_[0] =~ /[01]/ },
    default => sub { 0 },
);

=head2 Methods

=over

=item new(cfg => $config)

Creates a L<GenericCLI> object and returns it to the caller.

Required arguments:

=over

=item cfg

An L<App::WADTools::Config> object.  The L<Config> object is used to determine
things like input and output files, file formats, output colorization, and so
on.

=back

=cut

sub BUILD {
    my $self = shift;

    my $cfg = $self->config;
    if ( -t STDOUT || $cfg->defined(q(colorize)) ) {
        # this is how you set attribs when "is => q(rwp)" is used
        $self->_set_colorize(1);
    }
}
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
    if ( exists $args{lvl} && exists $_prefix{lvl} ) {
        $level = $args{lvl};
    } elsif ( exists $args{level} && exists $_prefix{level} ) {
        $level = $args{level};
    } else {
        # set a default level of "info"
        $level = q(info);
    }

    if ( exists $args{msg} ) {
        $message = $args{msg};
    } elsif ( exists $args{message} ) {
        $message = $args{message};
    } else {
        # default message that hopefully warns the user that something's wrong
        warn q(Received an 'update' call without a 'message' argument);
        $message = q(Default update message);
    }

    if ( $self->colorize ) {
        say colored([$_colors{$level}], $_prefix{$level} . $args{message});
    } else {
        say $_prefix{$level} . $args{message};
    }
}

=item request_success()

Indicate to the user that the current request is complete, and was successful.

=cut

sub request_success {
    my $self = shift;
    my %args = @_;

    my $message;

    if ( exists $args{msg} ) {
        $message = $args{msg};
    } elsif ( exists $args{message} ) {
        $message = $args{message};
    } else {
        # default message that hopefully warns the user that something's wrong
        warn q(Received an 'request_success' call without a 'message' argument);
        $message = q(Default update message);
    }

    #say q(Success! ) . $args{message};
    if ( $self->colorize ) {
        say colored([$_colors{success}], $message);
    } else {
        say $message;
    }
}

=item request_failure()

Indicate to the user that the current request is complete, and the request
failed.  Also show the reason for the request failure.

=back

=cut

sub request_failure {
    my $self = shift;
    my %args = @_;

    my $message;

    if ( exists $args{msg} ) {
        $message = $args{msg};
    } elsif ( exists $args{message} ) {
        $message = $args{message};
    } else {
        # default message that hopefully warns the user that something's wrong
        warn q(Received an 'request_success' call without a 'message' argument);
        $message = q(Default update message);
    }

    #say q(Failure! ) . $args{message} . q| (| . $args{id} . q|)|;
    if ( $self->colorize ) {
        say colored([$_colors{failure}], $message);
    } else {
        say $message;
    }
}

1;
