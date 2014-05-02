##########################################
# package App::WADTools::Roles::Database #
##########################################
package App::WADTools::Roles::Database;

=head1 NAME

App::WADTools::Roles::Database

=head1 SYNOPSIS

This object provides a C<Database> role to other database objects, and as
such, can't be created directly.

=head1 DESCRIPTION

Provides the C<filename> attribute, and methods dealing with connecting to a
database and checking schema.

=cut

# system modules
# 'Moo' calls 'strictures', which is 'strict' + 'warnings'
use Moo::Role;
use Date::Format;
use DBI;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::WADTools::Error;

=head2 Attributes

=over

=item filename

The path to the file on the filesystem that will be used as the C<SQLite>
database file.  If the special string C<:memory:> is used, then the database
will be stored in memory instead of being created as a file on the filesystem.
For in-memory databases, once this database object goes out of scope and
deleted, the database stored in memory will also be deleted.

=cut

has q(filename) => (
    is      => q(ro),
);

=item dbh

The database handle created by this object.  The database handle is a L<DBI>
object.  The handle is stored in this object so that subsequent database
requests by this object don't need to obtain a new database handle for each
request.

=cut

has dbh => (
    # https://metacpan.org/pod/Moo#has
    # 'rwp' generates a reader like 'ro', but also sets writer to
    # _set_${attribute_name} for attributes that are designed to be written
    # from inside of the class, but read-only from outside.
    is  => q(rwp),
    isa => sub{
        die q('dbh' requires a DBI object) unless ref($_[0]) =~ /^DBI/
    },
);

=back

=head2 Methods

B<NOTE!> Since this is a L<Moo::Role> object, you cannot directly create an
object from it, you need to create an object that consumes this role in order
to use the methods/attributes that this role provides.

=over

=item connect()

Connects to the database (calls C<DBI-E<gt>connect> using the C<filename>
attribute).

This method returns true (C<1>) if the database connection was successful, or
an L<App::WADTools::Error> object if there was a problem connecting to the
database.

=cut

sub connect {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $dbh = $self->dbh;

    $log->debug(q(Connecting to/reading database...));
    if ( ! defined $self->filename || length($self->filename) == 0 ) {
        $log->warn(q|Creating temp database ('filename' attribute is empty)|);
    } elsif ( $self->filename eq q(:memory:) ) {
        $log->info(q|Creating in-memory database ('filename' == ':memory:')|);
    } else {
        $log->debug(q(Database filename: ) . $self->filename);
    }

    if ( ! defined $dbh ) {
        $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->filename,"","");
        # turn on unicode handling
        $dbh->{sqlite_unicode} = 1;
        # don't print errors by default; all of the methods in this object
        # are checking $dbh->err after every interaction with the database
        # code
        $dbh->{PrintError} = 0;
        if ( defined $dbh->err ) {
            my $error = App::WADTools::Error->new(
                level   => q(fatal),
                id      => q(database.connect),
                message => $dbh->errstr,
            );
            $error->log_error;
            return $error;
        } else {
            $log->debug(q(Setting $self->dbh to: ) . $dbh);
            $self->_set_dbh($dbh);
            return 1;
        }
    } else {
        # database connection has already been set up (connection should
        # always be a singleton)
        $log->warn(q|Database connect() method has previously been called;|);
        $log->warn(q(Database connection already set up!));
        return 1;
    }
}

=item is_connected()

Determines if the database has already been connected to (the C<connect()>
method has already been called successfully). Returns a C<1> for "true" if the
database has already been connected to successfully, and an
L<App::WADTools::Error> object if the database connection was never set up (by
calling the C<connect()> method).

=cut

sub is_connected {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check that the database handle has already been set up via a call to
    # connect()
    $log->debug(q(Checking to see if database connection is established));
    my $dbh = $self->dbh;
    if ( ! defined $dbh ) {
        $log->warn(q(Database connection is NOT established));
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(database.no_connection),
            message => q|connect() never called to set up database handle|,
        );
        return $error;
    } else {
        return 1;
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

    perldoc App::WADTools::Roles::Database

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
