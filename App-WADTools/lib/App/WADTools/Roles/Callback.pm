###########################################
# package App::WADTools::Roles::Callback #
###########################################
package App::WADTools::Roles::Callback;

=head1 NAME

App::WADTools::Roles::Callback

=head1 SYNOPSIS

 # in another object...
 use Moo;
 with qw(App::WADTools::Roles::Callback);

=head1 DESCRIPTION

A role that provides methods/attributes for working with callbacks.

=cut

### System modules
use Moo::Role;
### System modules
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
# 'Moo' calls 'strictures', which is 'strict' + 'warnings'

### Local modules
use App::WADTools::Error;

=head2 Attributes

=over

=item callback

An object that will receive callbacks from the object that consumes this role.
When a callback method is called, it will include a hash with different
attributes for each callback.

=cut

has q(callback) => (
    # https://metacpan.org/pod/Moo#has
    # 'rwp' generates a reader like 'ro', but also sets writer to
    # _set_${attribute_name} for attributes that are designed to be written
    # from inside of the class, but read-only from outside.
    is  => q(rwp),
    #default => sub { },
);
=back

=head2 Methods

=over

=item check_callbacks(object => $object, check_methods => \@methods)

Checks the object C<$object> for the callback methods listed in the array
reference passed in as C<check_methods>.

Returns an L<App::WADTools::Error> object containing a list of missing
callbacks if any callbacks are missing, otherwise returns true (C<1>).

=cut

sub check_callbacks {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing 'object' argument for check_callbacks method))
        unless (exists $args{object});
    $log->logdie(q(Missing 'check_methods' argument for check_callbacks method))
        unless (exists $args{check_methods});

    my $object = $args{object};
    my @check_methods = @{$args{check_methods}};
    my @missing_methods;
    foreach my $method ( @check_methods ) {
        push(@missing_methods, $method)
            unless ( $object->can($method) );
    }
    if ( scalar(@missing_methods) > 0 ) {
        my $error = App::WADTools::Error->new(
            caller    => __PACKAGE__ . q(.) . __LINE__,
            type      => q(callbacks.check_callbacks.missing_callbacks),
            message   => q(Missing required callbacks for ) . ref($object),
            raw_error => q(Missing callbacks: ) . join(q(, ), @missing_methods),
        );
    }
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

    perldoc App::WADTools::Vote

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
