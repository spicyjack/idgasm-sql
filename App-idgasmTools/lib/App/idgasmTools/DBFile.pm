####################################
# package App::idgasmTools::DBFile #
####################################
package App::idgasmTools::DBFile;

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
use App::idgasmTools::Error;

# local variables
# store the database handle
my $dbh;

our $VERSION = 0.002;

=head1 App::idgasmTools::DBFile

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

=item new()

Creates the L<App::idgasmTools::DBFile> object.  Method is automatically
provided by the L<Moo> module as the C<BUILD> method.

Required arguments:

=over

=item filename

The filename of the C<INI> file to read from and possibly write to.

=back

=item connect()

Connects to the database (calls C<DBI-E<gt>connect> using the C<filename>
attribute), and returns true (C<1>) if the connection did not have any errors,
or an L<App::idgasmTools::Error> object if there was a problem connecting to
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
        $log->error(q(Execution of schema entries read failed));
        $log->error(q(Error message: ) . $sth->errstr);
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
        $log->debug(qq(Creating table for: ) . $entry->{name});
        # create the table table
        $dbh->do($entry->{sql});
        if ( defined $dbh->err ) {
            $log->error(q(CREATE TABLE for ) . $entry->{name} . q( failed));
            $log->error(q(Error message: ) . $dbh->errstr);
            my $error = App::idgasmTools::Error->new(error_msg => $dbh->errstr);
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
            my $error = App::idgasmTools::Error->new(error_msg => $dbh->errstr);
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

=item add_file()

Add an L<App::idgasmTools::File> object to the database.

Required arguments:

=over

=item file_obj

The L<App::idgasmTools::File> object to add to the database.

=back

=cut

sub add_file {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger("");

    $log->logdie(q(Missing 'file_obj' argument))
        unless(defined($args{file_obj}));
    my $file = $args{file_obj};
    $log->debug(q(Received file object; id: ) . $file->id
        . q(, filename: ) . $file->filename);

    my $filesql = <<'FILESQL';
        INSERT INTO files VALUES (
            ?, ?, ?, ?, ?,
            ?, ?, ?, ?, ?,
            ?, ?, ?, ?, ?,
            ?, ?, ?)
FILESQL
    my $sth = $dbh->prepare($filesql);
    if ( defined $dbh->err ) {
        $log->error(q('prepare' call to INSERT into 'files' failed));
        $log->error(q(Error message: ) . $dbh->errstr);
        my $error = App::idgasmTools::Error->new(error_msg => $dbh->errstr);
        return $error;
    }

    my $bind_counter = 1;
    foreach my $key ( @{$file->attributes} ) {
        # catches 'url', 'idgamesurl' and 'reviews'
        next if ( $key =~ /url|reviews/ );
        #$log->debug(qq(Binding $key -> ) . $file->$key));
        $sth->bind_param($bind_counter, $file->$key);
        $bind_counter++;
    }
    $log->debug(q(Calling 'execute' for file ID ) . $file->id);
    my $rv = $sth->execute();
    if ( ! defined $rv ) {
        $log->error(q(INSERT for file ID ) . $file->id
            . q( returned an error: ) . $sth->errstr);
        my $error = App::idgasmTools::Error->new(error_msg => $sth->errstr);
        return $error;
    } else {
        $log->debug(qq(INSERT for file ID ) . $file->id . qq( successful));
    }
    # FIXME what to return?  An error object if there's an error, what to
    # return for success?
}

=back

=cut

1;
