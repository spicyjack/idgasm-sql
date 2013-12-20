###################################
# package App::WADTools::Database #
###################################
package App::WADTools::Database;

# system modules
use Date::Format;
use DBI;
use Digest::MD5;
use File::Basename;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Moo;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::WADTools::Error;

# local variables
# store the database handle
my $dbh;

=head1 App::WADTools::Database

Create/read/update/delete an C<idgasm> database file, or records in an
existing database file.

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

=head2 Methods

=over

=item new(filename => $filename)

Creates the L<App::WADTools::Database> object.  Method is automatically
provided by the L<Moo> module as the C<BUILD> method.

Required arguments:

=over

=item filename

The filename of the C<INI> file to read from and possibly write to.

=back

=item add_file(file => $file)

Add an L<App::WADTools::File> object to the database.  Returns true C<1> in
all cases; errors will cause the program to exit.

Required arguments:

=over

=item file

The L<App::WADTools::File> object to add to the database.

=back

=cut

sub add_file {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger("");

    $log->logdie(q(Missing 'file' argument))
        unless(defined($args{file}));
    my $file = $args{file};
    $log->debug(sprintf(q(ID: %5u; ), $file->id)
            . qq(Adding to DB: ) . $file->filename);

    my $file_sql = <<'FILESQL';
        INSERT INTO files VALUES (
            ?, ?, ?, ?, ?,
            ?, ?, ?, ?, ?,
            ?, ?, ?, ?, ?,
            ?, ?, ?)
FILESQL

    ### INSERT FILE
    my $sth_file = $dbh->prepare($file_sql);
    if ( defined $dbh->err ) {
        $log->error(q('prepare' call to INSERT into 'files' failed));
        $log->error(q(Error message: ) . $dbh->errstr);
        my $error = App::WADTools::Error->new(
            type    => q(file_insert_prepare),
            message => $dbh->errstr
        );
        return $error;
    }

    my $bind_counter = 1;
    foreach my $key ( @{$file->attributes} ) {
        # catches 'url', 'idgamesurl' and 'reviews'
        next if ( $key =~ /url|reviews/ );
        #$log->debug(qq(Binding $key -> ) . $file->$key));
        $sth_file->bind_param($bind_counter, $file->$key);
        $bind_counter++;
    }
    #$log->debug(q(Executing 'INSERT' for file ID ) . $file->id);
    # $rv should be anything but 'undef' if the operation was successful
    my $rv = $sth_file->execute();
    if ( ! defined $rv ) {
        $log->error(q(INSERT for file ID ) . $file->id
            . q( returned an error: ) . $sth_file->errstr);
        my $error = App::WADTools::Error->new(
            type    => q(file_insert_execute),
            message => $sth_file->errstr
        );
        return $error;
    } else {
        $log->debug(sprintf(q(ID: %5u; ), $file->id)
            . qq(Successful INSERT of 'file' record));
    }

    ### INSERT VOTES
    my $vote_sql = q|INSERT INTO votes VALUES (?, ?, ?, ?)|;
    my $sth_vote = $dbh->prepare($vote_sql);
    if ( defined $dbh->err ) {
        $log->error(q('prepare' call to INSERT into 'votes' failed));
        $log->error(q(Error message: ) . $dbh->errstr);
        my $error = App::WADTools::Error->new(
            type    => q(vote_insert_prepare),
            message => $dbh->errstr
        );
        return $error;
    }
    my $vote_id = 0;
    my @reviews;
    # if there's no reviews, then $file->reviews will be 'undef'
    if ( defined $file->reviews ) {
        @reviews = @{$file->reviews};
    }
    foreach my $vote ( @reviews ) {
        # increment $vote_id
        $vote_id++;
        $sth_vote->bind_param(1, $vote_id);
        $sth_vote->bind_param(2, $file->id);
        $sth_vote->bind_param(3, $vote->text);
        $sth_vote->bind_param(4, $vote->vote);
        #$log->debug(q(Executing 'INSERT' for file ID/vote ID )
        #    . $file->id . q(/) . $vote_id);
        $rv = $sth_vote->execute();
        # $rv should be anything but 'undef' if the operation was successful
        if ( ! defined $rv ) {
            $log->error(q(INSERT for file ID ) . $file->id
                . q( returned an error: ) . $sth_file->errstr);
            my $error = App::WADTools::Error->new(
                type    => q(vote_insert_execute),
                message => $sth_file->errstr
            );
            return $error;
        } # else {
        #    $log->debug(q('INSERT' of vote for file ID/vote ID )
        #        . $file->id . q(/) . $vote_id . qq( successful));
        #}
    }
    if ( $vote_id > 0 ) {
        $log->debug(sprintf(q(ID: %5u; ), $file->id)
            . qq|Successful INSERT of $vote_id vote(s)|);
    } else {
        $log->debug(sprintf(q(ID: %5u; ), $file->id)
            . q|No votes to INSERT into database|);
    }

    # return 'true'
    return 1;
}

=item connect()

Connects to the database (calls C<DBI-E<gt>connect> using the C<filename>
attribute), and returns true (C<1>) if the connection did not have any errors,
or an L<App::WADTools::Error> object if there was a problem connecting to
the database.

=cut

sub connect {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("");

    $log->debug(q(Connecting to/reading database file ) . $self->filename);
    if ( ! defined $dbh ) {
        $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->filename,"","");
        # turn on unicode handling
        $dbh->{sqlite_unicode} = 1;
        # don't print errors by default, they should be handled by the calling
        # code
        $dbh->{PrintError} = 0;
        if ( defined $dbh->err ) {
            $log->error($dbh->errstr);
            return undef;
        } else {
            return 1;
        }
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
    my $log = Log::Log4perl->get_logger("");

    $log->logdie(q(Missing 'schema' parameter))
        unless ( defined $args{schema} );
    my $schema = $args{schema};
    # prepare the database statement beforehand; use bind_param (below) to set
    # the values inserted into the database

    foreach my $key ( sort(keys(%{$schema})) ) {
        next if ( $key =~ /^$/ );
        my $entry = $schema->{$key};
        #$log->debug(q(Dumping schema entry: ) . Dumper($entry));
        $log->info(qq(Creating table: ) . $entry->{name});
        # create the table table
        $dbh->do($entry->{sql});
        if ( defined $dbh->err ) {
            $log->error(q(CREATE TABLE for ) . $entry->{name} . q( failed));
            $log->error(q(Error message: ) . $dbh->errstr);
            my $error = App::WADTools::Error->new(
                type    => q(create_table),
                message => $dbh->errstr
            );
            return $error;
        }

        # add the newly created table to the schema table
        # this statement handle is only valid *after* the `schema` table has
        # been created
        my $sth = $dbh->prepare(
            q|INSERT INTO schema VALUES (?, ?, ?, ?, ?, ?)|);
        if ( defined $dbh->err ) {
            $log->error(q('prepare' call to INSERT into 'schema' failed));
            $log->error(q(Error message: ) . $dbh->errstr);
            my $error = App::WADTools::Error->new(
                type    => q(schema_insert_prepare),
                message => $dbh->errstr
            );
            return $error;
        }
        $sth->bind_param(1, $key);
        $sth->bind_param(2, time);
        $sth->bind_param(3, $entry->{name});
        $sth->bind_param(4, $entry->{description});
        $sth->bind_param(5, $entry->{notes});
        $sth->bind_param(6, $entry->{checksum});
        my $rv = $sth->execute();
        if ( ! defined $rv ) {
            $log->error(qq(INSERT for schema ID $key returned an error: )
                . $sth->errstr);
            return undef;
        } else {
            $log->debug(qq(INSERT for schema ID $key changed $rv row));
        }
    }
}

=item get_file_by_id()

Queries the database for a L<App::WADTools::File> object in the database with
the ID passed in as the argument.  Returns a L<App::WADTools::File> object if
the file ID was found in the database, or an L<App::WADTools::Error> object
with the C<error_type> of C<file_id_not_found>.

Required arguments:

=over

=item id

An integer value that represents a file ID in the idGames Archive.

=back

=cut

sub get_file_by_id {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger("");

    $log->logdie(q(Missing 'id' parameter))
        unless ( defined $args{id} );
    my $file_id = $args{id};
}

=item get_file_by_path()

Queries the database for a L<App::WADTools::File> object in the database that
matches the C<$path/$filename> arguments passed in.  A valid file path is the
path from the root of the idGames Archive file tree, i.e. the directory
containing the folders C<combos>, Returns a L<App::WADTools::File> object if
the file was found in the database, or an L<App::WADTools::Error> object with
the C<error_type> of C<file_not_found>.

Required arguments:

=over

=item path

The path to the file from the root of the C<idGames Archive>.

=item filename

The filename of the file in C<idGames Archive>.

=back

=cut

sub get_file_by_path  {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger("");

    $log->logdie(q(Missing 'path' parameter))
        unless ( defined $args{path} );
    $log->logdie(q(Missing 'filename' parameter))
        unless ( defined $args{filename} );
    my $path = $args{path};
    my $filename = $args{filename};
}


=item has_schema()

Determines if the database specified with the C<filename> attribute has
already had a schema applied to it via L<create_schema>.  Returns ? if the
schema has been applied, and ? if the schema has not been applied.

=cut


sub has_schema {
    my $self = shift;
    my $log = Log::Log4perl->get_logger("");

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

=cut

1;
