################################################
# package App::WADTools::Roles::DatabaseSchema #
################################################
package App::WADTools::Roles::DatabaseSchema;

=head1 NAME

App::WADTools::Roles::DatabaseSchema

=head1 SYNOPSIS

 package My::Database;
 use Moo;
 with qw(App::WADTools::Roles::DatabaseSchema);

 # in another module or script, create the database object
 $db = My::Database->new(filename => q(/path/to/file.db));

 # must connect to the database before you can check for schema
 my $db_connect = $db->connect();

 my $check_schema = $db->check_schema()
 if ( ref($check_schema) eq q(App::WADTools::Error) ) {
    # handle errors with database schema here...
 }


=head1 DESCRIPTION

This object provides a C<DatabaseSchema> role to provide functions for working
with database schemas.


Provides and methods dealing with connecting to a
database and checking schema.

=cut

# system modules
# 'Moo' calls 'strictures', which is 'strict' + 'warnings'
use Moo::Role;
use DBI;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::WADTools::Error;

=head2 Attributes

No attributes.

=head2 Methods

Since this is a L<Moo::Role> object, it must be consumed by another module by
using the C<with()> keyword, in order to tell C<Moo> to find and consume that
role.

=over

=item apply_schema()

Applies the schema passed in using the required C<schema> argument.  A
C<schema> object is created by reading in a specially formatted C<INI> file
using the module L<App::WADTools::INIFile>, which then gets converted to the
correct data structure for this method to apply to the database.

Returns either C<1> if all of the SQL calls were successful, or an
L<App::WADTools::Error> object if any of the SQL calls failed.

Required arguments:

=over

=item schema

A data structure that specifies different SQL data definition language (DDL)
commands to run in order to create a database.

=back

=cut

sub apply_schema {
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
                $log->error(qq(Execution of schema block '$block_name' failed));
                $log->error(q(Error message: ) . $dbh->errstr);
                my $error = App::WADTools::Error->new(
                    caller  => __PACKAGE__ . q(.) . __LINE__,
                    type    => q(database.schema_block.execute_sql),
                    message => $dbh->errstr
                );
                return $error;
            }
        } elsif ( defined $block->{params} ) {
            # verify the SQL predicate exists
            my $sql_predicate = $block->{sql_predicate};
            if ( ! defined $sql_predicate ) {
                $log->error(qq(Missing SQL predicate from block '$block_name'));
                my $error = App::WADTools::Error->new(
                    caller  => __PACKAGE__ . q(.) . __LINE__,
                    type    => q(database.schema_block.execute_params),
                    message =>
                        qq(Missing SQL predicate from block '$block_name'),
                );
                return $error;
            }
            # "cast" params to an array
            my @params = @{$block->{params}};
            if ( scalar(@params) == 0 ) {
                $log->error(qq(Missing SQL params from block '$block_name'));
                my $error = App::WADTools::Error->new(
                    caller  => __PACKAGE__ . q(.) . __LINE__,
                    type    => q(database.schema_block.execute_params),
                    message => qq(Missing SQL params from block '$block_name'),
                );
                return $error;
            }
            my @bind_placeholders;
            for (my $i = 0; $i < scalar(@params); $i++) {
                push(@bind_placeholders, q(?));
            }
            my $sql = qq|$sql_predicate (|
                . join(q(, ), @bind_placeholders) . q|)|;
            #$log->debug(q(Dumping SQL statement for predicate/params;));
            #$log->debug($sql);
            # create the table
            $dbh->do($sql, undef, @params);
            if ( defined $dbh->err ) {
                $log->error(qq(Execution of schema block '$block_name' failed));
                $log->error(q(Error message: ) . $dbh->errstr);
                my $error = App::WADTools::Error->new(
                    caller  => __PACKAGE__ . q(.) . __LINE__,
                    type    => q(database.schema_block.execute),
                    message => $dbh->errstr,
                );
                return $error;
            }
        } else {
            $log->error(qq(Block '$block_name' has no 'sql' key));
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
                caller  => __PACKAGE__ . q(.) . __LINE__,
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
            my $error = App::WADTools::Error->new(
                caller  => __PACKAGE__ . q(.) . __LINE__,
                type    => q(database.schema_insert.execute),
                message => $dbh->errstr
            );
            return $error;
        } else {
            $log->debug(qq(INSERT of ID $block_name into 'schema' )
                 . qq(changed $rv row));
        }
    }
    return 1;
}

=item has_schema()

Determines if the database specified with the C<filename> attribute has
already had a schema applied to it via L<apply_schema>.  Returns C<0> if the
schema has not been applied, and the number of rows in the C<schema> table if
the schema has been applied.

=cut

sub has_schema {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check for an existing database connection
    my $error = $self->is_connected;
    return $error if ( $error->can(q(is_error)) );
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

=back

=head1 AUTHOR

Brian Manning, C<< <brian at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker for
this project:

C<< <https://github.com/spicyjack/wadtools/issues> >>.

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

    perldoc App::WADTools::Roles::DatabaseSchema

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
