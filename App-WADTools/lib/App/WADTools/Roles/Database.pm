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

A filename to the C<SQLite> database file.  If the file does not exist, a new
file will be created.

=back

=cut

has filename => (
    is  => q(rw),
#    isa => sub {
#                my $self = shift;
#                die "$self is not a valid filename"
#                    unless (-r $self);
#            },
);

=item dbh

The database handle, provided by the L<DBI> object.

=back

=cut

has dbh => (
    is  => q(rw),
    isa => sub{ ref($_[0]) eq q(DBI) },
);

=head2 Methods

=over

=item new(filename => $filename)

Creates the L<App::WADTools::Roles::Database> object.  Method is automatically
provided by the L<Moo> module as the C<BUILD> method.

Required arguments:

=over

=item filename

The filename of the database file that will be read from and written to.

=back

=item connect()

Connects to the database (calls C<DBI-E<gt>connect> using the C<filename>
attribute).

Optional arguments:

=over

=item check_schema

Checks to see if the schema has already been applied to this database.

=back

If the C<check_schema> param B<was used>, then this method returns the number
of schema blocks applied if the database connection was successful and has had
a schema applied to it, or an L<App::WADTools::Error> object if there was an
error.

If the C<check_schema> param B<was not used>, then this method returns true
(C<1>) if the database connection was successful, or an
L<App::WADTools::Error> object if there was a problem connecting to
the database.

=cut

sub connect {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $check_schema_flag;
    my $dbh = $self->dbh;

    if ( exists $args{check_schema} ) {
        if ( $args{check_schema} ) {
            $check_schema_flag = $args{check_schema};
        }
    }
    $log->debug(q(Connecting to/reading database file ) . $self->filename);
    if ( ! defined $dbh ) {
        $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->filename,"","");
        # turn on unicode handling
        $dbh->{sqlite_unicode} = 1;
        # don't print errors by default, all of the methods in this object are
        # checking $dbh->err after every interaction with the database
        # code
        $dbh->{PrintError} = 0;
        if ( defined $dbh->err ) {
            my $error = App::WADTools::Error->new(
                type    => q(database.connect),
                message => $dbh->errstr,
            );
            return $error;
        } else {
            # save the database handle
            $self->dbh($dbh);
            if ( $check_schema_flag ) {
                # returns the number of schema blocks applied, or an error
                return $self->has_schema;
            } else {
                return 1;
            }
        }
    } else {
        # database connection has already been set up (connection should
        # always be a singleton)
        $log->warn(q(Database connection already set up!));
        $log->warn(q|Database connect() method has previously been called...|);
        return 1;
    }
}

=item create_schema()

Creates a database with a schema as determined by the C<schema> argument.

Required arguments:

=over

=item schema

A data structure that specifies different SQL data definition language (DDL)
commands to run in order to create a database.

=back

=cut

sub create_schema {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check for an existing database connection
    my $error = $self->is_connected;
    return $error if ( ref($error) eq q(App::WADTools::Error));
    my $dbh = $self->dbh;

    $log->logdie(q(Missing 'schema' parameter))
        unless ( defined $args{schema} );

    my $schema = $args{schema};

    # when the schema is stuffed into a hash, the order of the blocks is
    # randomized; we need to always have the 'schema' block be run first, then
    # the other blocks in whatever order
    my @unsorted_blocks = sort(keys(%{$schema}));
    my @schema_blocks;
    # push the 'schema' block on the list of blocks so it's at the front, if
    # the 'schema' block even exists in the *.ini file
    if ( grep(/schema/, @unsorted_blocks) > 0 ) {
        push (@schema_blocks, q(schema));
    }
    foreach my $random_block ( @unsorted_blocks ) {
        # skip the 'default' schema block, and the 'schema' schema block
        next if ( $random_block =~ /^default|^schema/ );
        push(@schema_blocks, $random_block);
    }
    SQL_BLOCK: foreach my $block_name ( @schema_blocks ) {
        # get the hash underneath the $block_name key
        my $block = $schema->{$block_name};
        #$log->debug(q(Dumping schema block: ) . Dumper($block));
        $log->info(qq(Executing SQL schema block: $block_name));
        if ( defined $block->{sql} ) {
            # create the table
            $dbh->do($block->{sql});
            if ( defined $dbh->err ) {
                $log->error(qq(Execution of block '$block_name' failed));
                $log->error(q(Error message: ) . $dbh->errstr);
                my $error = App::WADTools::Error->new(
                    type    => q(database.block_execute),
                    message => $dbh->errstr
                );
                return $error;
            }
        } else {
            $log->error(qq(Block '$block_name' has no SQL key));
            $log->error(qq(Skipping to next SQL block));
            next SQL_BLOCK;
        }
        # add the newly created table to the schema table
        # this statement handle is only valid *after* the `schema` table has
        # been created
        my $sth = $dbh->prepare(
            q|INSERT INTO schema VALUES (NULL, ?, ?, ?, ?, ?)|);
        if ( defined $dbh->err ) {
            $log->error(q('prepare' call to INSERT into 'schema' failed));
            $log->error(q(Error message: ) . $dbh->errstr);
            my $error = App::WADTools::Error->new(
                type    => q(database.schema_insert.prepare),
                message => $dbh->errstr
            );
            return $error;
        }
        $sth->bind_param(1, time);
        $sth->bind_param(2, $block_name);
        $sth->bind_param(3, $block->{description});
        $sth->bind_param(4, $block->{notes});
        $sth->bind_param(5, $block->{checksum});
        my $rv = $sth->execute();
        if ( ! defined $rv ) {
            $log->error(qq(INSERT for schema ID $block_name returned an error: )
                . $sth->errstr);
            return undef;
        } else {
            $log->debug(qq(INSERT for schema ID $block_name changed $rv row));
        }
    }
}

=item has_schema()

Determines if the database specified with the C<filename> attribute has
already had a schema applied to it via L<create_schema>.  Returns ? if the
schema has been applied, and ? if the schema has not been applied.

=cut

sub has_schema {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check for an existing database connection
    my $error = $self->is_connected;
    return $error if ( ref($error) eq q(App::WADTools::Error));
    my $dbh = $self->dbh;

    my $sql = <<SQL;
        SELECT id, date_applied
        FROM schema
        ORDER BY date_applied ASC
SQL
    $log->debug(q(Preparing SQL for querying 'schema' table));
    my $sth = $dbh->prepare($sql);
    if ( defined $dbh->err ) {
        $log->error(q(Checking for schema failed: ) . $dbh->errstr);
        return 0;
    }

    my $schema_rows = 0;
    $log->debug(q(Reading schema entries from 'schema' table));
    $sth->execute;
    if ( defined $sth->err ) {
        $log->warn(q(Execution of schema entries read failed));
        $log->warn(q(Error message: ) . $sth->errstr);
        return 0;
    }
    while ( my @row = $sth->fetchrow_array ) {
        $schema_rows++;
        # "unpack" the row
        #my ($row_id, $date_applied) = @row;
        #$log->debug(qq(Row; id: $row_id, date: $date_applied));
    }

    # return the number of schema rows read from the database; this should
    # roughly correspond to the schema version of the database
    return $schema_rows;
}

=item is_connected()

Determines if the database has already been connected to (the C<connect()>
method has already been called successfully). Returns an empty string if the
database has already been connected to successfully, and an
L<App::WADTools::Error> object if the database connection was never set up (by
calling the C<connect()> method).

=cut

sub is_connected {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check that the database handle has already been set up via a call to
    # connect()
    my $dbh = $self->dbh;
    if ( ! defined $dbh ) {
        my $error = App::WADTools::Error->new(
            type    => q(database.no_connection),
            message => q|connect() never called to set up database handle|,
        );
        return $error;
    } else {
        return q();
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
