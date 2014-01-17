#################################
# package App::WADTools::Config #
#################################
package App::WADTools::Config;

=head1 App::WADTools::Config

Configure/manage script options using L<Getopt::Long>.

=cut

use English qw( -no_match_vars );
use Getopt::Long;
use Moo;

=head2 Attributes

=over

=item args

A scalar containing the command line that was used to call this program.
Meant to be used with logging so that the exact command that was run can be
seen and duplicated

=cut

has q(args) => (
    is  => q(rw),
);

=item options

An C<ArrayRef> to an array containing script options, in L<Getopt::Long> format.

=cut

has q(options) => (
    is  => q(rw),
    isa => sub {
                my $self = shift;
                die q(Argument 'options' is not an ARRAY reference)
                    unless ( ref($self) eq q(ARRAY) );
            },
);

=back

=head2 Methods

=over

=item BUILD() (aka 'new')

Creates the L<App::WADTools::Config> object, parses options from the
command line via L<Getopt::Long>, and returns the object to the caller.
=cut

sub BUILD {
    my $self = shift;

    # can't continue without script options in Getopt::Long format
    die qq(Missing 'options' array to Config object)
        unless ( defined $self->options );

    # save a copy of the command line arguments so they can be displayed
    $self->args(join(q( ), @ARGV));

    # script arguments
    my %args;

    # parse the command line arguments (if any)
    my $parser = Getopt::Long::Parser->new();

    # pass in a reference to the args hash as the first argument
    $parser->getoptions( \%args, @{$self->options} );

    # assign the args hash to this object so it can be reused later on
    $self->{_args} = \%args;

    # set a flag if we're running on 'MSWin32'
    if ( $OSNAME eq q(MSWin32) ) {
        $self->set(is_mswin32 => 1);
    }

    # return this object to the caller
    return $self;
}

=item get($key)

Returns the scalar value of the key passed in as C<key>, or C<undef> if the
key does not exist in the L<App::WADTools::Config> object.

=cut

sub get {
    my $self = shift;
    my $key = shift;
    # turn the args reference back into a hash with a copy
    my %args = %{$self->{_args}};

    if ( exists $args{$key} ) { return $args{$key}; }
    return undef;
}

=item set(key => $value)

Sets in the L<App::WADTools::Config> object the key/value pair passed in
as arguments.  Returns the old value if the key already existed in the
L<App::WADTools::Config> object, or C<undef> otherwise.

=cut

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    # turn the args reference back into a hash with a copy
    my %args = %{$self->{_args}};

    if ( exists $args{$key} ) {
        my $oldvalue   = $args{$key};
        $args{$key}    = $value;
        $self->{_args} = \%args;
        return $oldvalue;
    } else {
        $args{$key}    = $value;
        $self->{_args} = \%args;
    } # if ( exists $args{$key} )
    return undef;
}

=item get_args( )

Returns a hash containing the parsed script arguments.

=cut

sub get_args {
    my $self = shift;
    # hash-ify the return arguments
    return %{$self->{_args}};
}

=item defined($key)

Returns "true" (C<1>) if the value for the key passed in as C<key> is
C<defined>, and "false" (C<0>) if the value is undefined, or the key doesn't
exist.

=back

=cut

sub defined {
    my $self = shift;
    my $key = shift;
    # turn the args reference back into a hash with a copy
    my %args = %{$self->{_args}};

    # Can't use Log4perl here, since it hasn't been set up yet
    if ( exists $args{$key} ) {
        #warn qq(exists: $key\n);
        if ( defined $args{$key} ) {
            #warn qq(defined: $key; ) . $args{$key} . qq(\n);
            return 1;
        }
    }
    return 0;
}

1;
