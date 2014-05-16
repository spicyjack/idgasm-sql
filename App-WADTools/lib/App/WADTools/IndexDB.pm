##################################
# package App::WADTools::IndexDB #
##################################
package App::WADTools::IndexDB;

=head1 NAME

App::WADTools::IndexDB

=head1 SYNOPSIS

 my $db = App::WADTools::IndexDB->new(filename => q(/path/to/index.db));
 # check that the database already has a schema applied to it
 my $result = $db->connect( check_schema => 1 );
 if ( ref($result) eq q(App::WADTools::Error) ) {
     # something bad happened
 }
 # returns a App::WADTools::WADFile object
 my $wad = $db->get_wad( keysum => $keysum );

 # returns a App::WADTools::ZipInfo object
 my $zipinfo = $db->get_zipinfo( keysum => $keysum );

=head1 DESCRIPTION

Provides the C<wadindex> script the ability to create/read/update/delete the
database that is used by the script to index C<WAD> files.

This object consumes the L<App::WADTools::Role::Database> role.  See the POD
for the role object for more information on methods/attributes it provides.

=cut

### System modules
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
# 'Moo' calls 'strictures', which is 'strict' + 'warnings'
use Moo;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

### Local modules
use App::WADTools::Timer;

### Roles
# App::WADTools::Roles::Database uses App::WADTools::Error, so it's
# automatically available here too
with qw(
    App::WADTools::Roles::Database
    App::WADTools::Roles::DatabaseSchema
    App::WADTools::Roles::Callback
);

=head2 Attributes

=over

=item add_wadfile_time

The time, in seconds, that was required to add the WAD file to the database.
This parameter is set during the L<add_wadfile()> method call, and can be read
immediately after program control returns from that method.

=cut

has q(add_wadfile_time) => (
    is      => q(rw),
    default => sub{ 0 },
);

=item add_zipfile_time

The time, in seconds, that was required to add the ZIP file to the database.
This parameter is set during the L<add_zipfile()> method call, and can be read
immediately after program control returns from that method.

=cut

has q(add_zipfile_time) => (
    is      => q(rw),
    default => sub{ 0 },
);

=back

=head2 Callbacks

As this object runs, it will invoke 'callback methods' in the calling object
to signal a change in state or to update the caller with the current status of
the request.  When a callback method is invoked, it will pass key/value
attributes back to the caller as a Perl hash, as documented in each callback
method below.

This object checks that the following callbacks are implemented by the caller;

=over

=item request_success

The database request has finished successfully.  The return hash will include
the C<id> key/value pair, which will indicate what event triggered the
C<request_success> call.

=item request_failure

The database request failed for some reason.  The return hash will include the
C<error> key/value pair, which will contain a L<App::WADTools::Error> object,
and a C<id> key/value pair, which will indicate what event triggered the
C<request_failure> call.

=item update

This method is called when this object wants to update the status of a
database request which is still processing.  The return hash will include the
C<id> key/value pair, which will indicate what event triggered the
C<update> call, and the C<message> key/value pair, which will be an
update message of some kind that can be passed along to the user (via a
C<View> object).

=back


=head2 Methods

=over

=item new() (AKA BUILD)

Creates the L<App::WADTools::idGamesDB> object.  A check is also made to see
if required attribute C<callback> was set by the caller; if the attribute was
not set, then the method will return an C<App::WADTools::Error> object to the
caller, otherwise, returns the L<App::WADTools::idGamesDB> object to the
caller.

=cut

sub BUILD {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    if ( ! defined $self->callback ) {
        # can't return things in BUILD, you must die, or do this kind of setup
        # in a method, which can return something
        $log->logdie(q(IndexDB missing required callback object));
    }
    my $callbacks_check = $self->check_callbacks(
        object => $self->callback,
        check_methods => [qw(update request_success request_failure)],
    );
    if ( ref($callbacks_check) eq q(App::WADTools::Error) ) {
        $log->fatal($callbacks_check->message);
        $log->logdie($callbacks_check->raw);
    }
}

=item add_wadfile(wadfile => $wadfile)

Add an L<App::WADTools::WADFile> object to the database, specifically, adding
information about the WAD file itself, along with any levels that the WAD file
provides to the appropriate database tables.  Returns true C<1> if the insert
was successful, or an L<App::WADTools::Error> object if there was a problem
inserting the WAD file object into the database.

Required arguments:

=over

=item wadfile

The L<App::WADTools::WADFile> object to add to the database.

=back

=cut

sub add_wadfile {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check for an existing database connection
    my $error = $self->is_connected;
    return $error if ( ref($error) eq q(App::WADTools::Error));
    my $dbh = $self->dbh;

    $log->logdie(q(Missing 'wadfile' argument))
        unless(defined($args{wadfile}));
    $log->logdie(q(Missing 'zip_keysum' argument))
        unless(defined($args{zip_keysum}));
    my $wadfile = $args{wadfile};
    my $zip_keysum = $args{zip_keysum};

    $log->debug(sprintf(q(keysum: %8s; ), $wadfile->keysum)
        . q(Adding to index DB));
    $log->debug(q|(Filepath: | . $wadfile->filepath . q|)|);

    ### INSERT WAD file into 'wads'
    # start the timer
    my $timer = App::WADTools::Timer->new();
    $timer->start(name => q(add_wadfile));
    # set up the SQL
    my $wad_sql = q|INSERT INTO wads VALUES (?, ?, ?, ?, ?, ?, ?)|;
    my $sth_wads = $dbh->prepare($wad_sql);
    if ( defined $dbh->err ) {
        $log->error(q('prepare' call to INSERT into 'wads' failed));
        $log->error(q(Error message: ) . $dbh->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(index-db.wads-insert.prepare),
            message => $dbh->errstr
        );
        return $error;
    }
    $sth_wads->bind_param(1, $wadfile->keysum);
    $sth_wads->bind_param(2, $zip_keysum );
    $sth_wads->bind_param(3, 0);
    $sth_wads->bind_param(4, $wadfile->filename);
    $sth_wads->bind_param(5, $wadfile->size);
    $sth_wads->bind_param(6, $wadfile->md5_checksum);
    $sth_wads->bind_param(7, $wadfile->sha_checksum);
    #$log->debug(q(Executing 'INSERT' for file ID/vote ID )
    #    . $wadfile->id . q(/) . $vote_id);
    my $rv = $sth_wads->execute();
    # $rv should be anything but 'undef' if the operation was successful
    if ( ! defined $rv ) {
        $log->error(q(INSERT for keysum ') . $wadfile->keysum
            . q(' returned an error: ) . $sth_wads->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(index-db.wads-insert.execute),
            message => $sth_wads->errstr
        );
        return $error;
    } else {
        $log->debug(sprintf(q(keysum: %8s; INSERT -> 'wads' successful!),
            $wadfile->keysum));
    }

    ### INSERT level(s) into 'levels_to_wads'
    my $level_sql = q|INSERT INTO levels_to_wads VALUES (?, ?)|;
    my $sth_level = $dbh->prepare($level_sql);
    if ( defined $dbh->err ) {
        $log->error(q('prepare' call to INSERT into 'levels_to_wads' failed));
        $log->error(q(Error message: ) . $dbh->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(index-db.levels_to_wads-insert.prepare),
            message => $dbh->errstr
        );
        return $error;
    }

    # exit here if there are no levels to add to the database
    if ( ! defined $wadfile->levels ) {
        # stop the timer, get the elapsed time
        $timer->stop(name => q(add_wadfile));
        $self->add_wadfile_time(
            $timer->time_value_difference(name => q(add_wadfile))
        );
        return 1;
    }

    # there are levels in this WAD file; add them to the database
    foreach my $level ( @{$wadfile->levels} ) {
        $sth_level->bind_param(1, $wadfile->keysum);
        $sth_level->bind_param(2, $level);
        $log->debug(sprintf(q(keysum: %8s; ), $wadfile->keysum)
            . qq(Adding level to DB: $level));
        $rv = $sth_level->execute();
        # $rv should be anything but 'undef' if the operation was successful
        if ( ! defined $rv ) {
            $log->error(q(INSERT keysum/level returned an error: )
                . $sth_level->errstr);
            my $error = App::WADTools::Error->new(
                level   => q(fatal),
                id      => q(index-db.levels_to_wads-insert.execute),
                message => $sth_level->errstr
            );
            return $error;
        } else {
            $log->debug(sprintf(q(keysum/level: %8s/%4s; ),
                $wadfile->keysum, $level)
                . q(INSERT -> 'levels_to_wads' successful),
            );
        }
    }

    # stop the timer, get the elapsed time
    $timer->stop(name => q(add_wadfile));
    $self->add_wadfile_time(
        $timer->time_value_difference(name => q(add_wadfile))
    );

    # return 'true'
    return 1;
}

=item add_zipfile(zipfile => $zipfile)

Add an L<App::WADTools::ZipFile> object to the database.  Returns true C<1> if
the insert was successful, or an L<App::WADTools::Error> object if there was a
problem inserting the L<App::WADTools::ZipFile> object into the database.

Required arguments:

=over

=item zipfile

The L<App::WADTools::ZipFile> object to add to the database.

=back

=cut

sub add_zipfile {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check for an existing database connection
    my $error = $self->is_connected;
    return $error if ( ref($error) eq q(App::WADTools::Error));
    my $dbh = $self->dbh;

    $log->logdie(q(Missing 'zipfile' argument))
        unless(defined($args{zipfile}));
    my $zipfile = $args{zipfile};

    $log->debug(sprintf(q(keysum: %8s; ), $zipfile->keysum)
        . q(Adding to index DB));
    $log->debug(q|(Filepath: | . $zipfile->filepath . q|)|);

    ### INSERT WAD file into 'zipfiles'
    # set up the timer
    my $timer = App::WADTools::Timer->new();
    $timer->start(name => q(add_zipfile));
    # set up the SQL
    my $wad_sql = q|INSERT INTO zipfiles VALUES (?, ?, ?, ?, ?, ?)|;
    my $sth_wads = $dbh->prepare($wad_sql);
    if ( defined $dbh->err ) {
        $log->error(q('prepare' call to INSERT into 'zipfiles' failed));
        $log->error(q(Error message: ) . $dbh->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(index-db.zipfiles-insert.prepare),
            message => $dbh->errstr
        );
        return $error;
    }
    $sth_wads->bind_param(1, $zipfile->keysum);
    $sth_wads->bind_param(2, 0);
    $sth_wads->bind_param(3, $zipfile->filename);
    $sth_wads->bind_param(4, $zipfile->size);
    $sth_wads->bind_param(5, $zipfile->md5_checksum);
    $sth_wads->bind_param(6, $zipfile->sha_checksum);
    #$log->debug(q(Executing 'INSERT' for file ID/vote ID )
    #    . $wadfile->id . q(/) . $vote_id);
    my $rv = $sth_wads->execute();
    # $rv should be anything but 'undef' if the operation was successful
    if ( ! defined $rv ) {
        $log->error(q(INSERT for keysum ') . $zipfile->keysum
            . q(' returned an error: ) . $sth_wads->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(index-db.zipfiles-insert.execute),
            message => $sth_wads->errstr
        );
        return $error;
    } else {
        $log->debug(sprintf(q(keysum: %8s; INSERT -> 'zipfiles' successful!),
            $zipfile->keysum));
    }

    # stop the timer, get the elapsed time
    $timer->stop(name => q(add_zipfile));
    $self->add_zipfile_time(
        $timer->time_value_difference(name => q(add_zipfile))
    );

    # return 'true'
    return 1;
}

=item get_file_by_id()

Queries the database for a L<App::WADTools::File> object in the database with
the ID passed in as the argument.  Returns a L<App::WADTools::File> object if
the file ID was found in the database, or an L<App::WADTools::Error> object
with the C<id> of C<file_id_not_found>.

Required arguments:

=over

=item id

An integer value that represents a file ID in the idGames Archive.

=back

=cut

sub get_file_by_id {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check for an existing database connection
    my $error = $self->is_connected;
    return $error if ( ref($error) eq q(App::WADTools::Error));
    my $dbh = $self->dbh;

    $log->logdie(q(Missing 'id' parameter))
        unless ( defined $args{id} );
    my $file_id = $args{id};

    my $sql = q(SELECT * FROM files WHERE id = ?);
    $log->debug(q(Prepare: querying for file from file ID));
    $log->debug(qq(Prepare: SQL: $sql));

    # prepare the SQL
    my $sth = $dbh->prepare($sql);
    if ( defined $dbh->err ) {
        $log->warn(q(Preparing query for file failed));
        $log->warn(q(Error message: ) . $dbh->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(index-db.get_file_by_id.prepare),
            message => $dbh->errstr
        );
        return $error;
    }

    # bind params
    $log->debug(qq(Binding query params; 1: $file_id));
    $sth->bind_param(1, $file_id);

    # execute the SQL
    $log->debug(q(Calling $sth->execute));
    $sth->execute;
    if ( defined $sth->err ) {
        $log->warn(q(Executing query for file failed));
        $log->warn(q(Error message: ) . $sth->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(index-db.get_file_by_id.execute),
            message => $dbh->errstr
        );
        return $error;
    }

    $log->debug(q(Retrieving row via fetchrow_arrayref));
    my $row = $sth->fetchrow_arrayref;
    # return $row as an undefined value if there are no rows returned from the
    # database query
    return $row unless ( defined $row );
    #$log->debug(q(dump: ) . Dumper $row);
    my $file = $self->unserialize_file(db_row => $row);
    $log->debug(qq(File ID ) . $file->id . q( has path: )
        . $file->dir . q(/) . $file->filename);
    return $file;
}

=item get_file_by_path()

Queries the database for a L<App::WADTools::File> object in the database that
matches the C<$path/$filename> arguments passed in.  A valid file path is the
path from the root of the idGames Archive file tree, i.e. the directory
containing the folders C<combos>, C<deathmatch>, C<historic>, C<idstuff>, etc.
Returns a L<App::WADTools::File> object if the file was found in the database,
or an L<App::WADTools::Error> object with the error C<id> of
C<file_not_found>.

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
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    # check for an existing database connection
    my $error = $self->is_connected;
    return $error if ( ref($error) eq q(App::WADTools::Error));
    my $dbh = $self->dbh;

    $log->logdie(q(Missing 'path' parameter))
        unless ( defined $args{path} );
    $log->logdie(q(Missing 'filename' parameter))
        unless ( defined $args{filename} );

    my $path = $args{path};
    my $filename = $args{filename};
    my $sql = q(SELECT * FROM files WHERE dir = ? AND filename = ?);
    $log->debug(q(Prepare: querying for file ID from dir/filename));
    $log->debug(qq(Prepare: SQL: $sql));

    # prepare the SQL
    my $sth = $dbh->prepare($sql);
    if ( defined $dbh->err ) {
        $log->warn(q(Preparing query for file failed));
        $log->warn(q(Error message: ) . $dbh->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(index-db.get_file_by_path.prepare),
            message => $dbh->errstr
        );
        return $error;
    }

    # bind params
    $log->debug(qq(Binding query params; 1: $path, 2: $filename));
    $sth->bind_param(1, $path);
    $sth->bind_param(2, $filename);

    # execute the SQL
    $log->debug(q(Calling $sth->execute));
    $sth->execute;
    if ( defined $sth->err ) {
        $log->warn(q(Executing query for file failed));
        $log->warn(q(Error message: ) . $sth->errstr);
        my $error = App::WADTools::Error->new(
            level   => q(fatal)
            id      => q(index-db.get_file_by_path.execute),
            message => $dbh->errstr
        );
        return $error;
    }

    $log->debug(q(Retrieving row via fetchrow_arrayref));
    my $row = $sth->fetchrow_arrayref;
    # return $row as an undefined value if there are no rows returned from the
    # database query
    return $row unless ( defined $row );
    #$log->debug(q(dump: ) . Dumper $row);
    my $file = $self->unserialize_file(db_row => $row);
    $log->debug(qq(File ID for ) . $file->dir . q(/) . $file->filename
        . q( is ) . $file->id);
    return $file;
}

=item unserialize_file(db_row => $row)

Accepts a row from a database query of the C<files> table, and unserializes
the file object into a L<App::WADTools::File> object.   Returns the
unserialized C<File> object if there were no errors, or an
L<App::WADTools::Error> object if there was an error.

Required arguments:

=over

=item db_row

The row from a query of the C<files> table, obtained with a call to
C<$sth-E<gt>fetchrow_arrayref()> from a L<DBI> database handle.

=back

=cut

sub unserialize_file {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->logdie(q(Missing 'db_row' parameter))
        unless ( exists $args{db_row} );

    my $db_row = $args{db_row};
    my @row = @{$db_row};
    # create the $file object that will be returned after it is unserialized
    my $file = App::WADTools::File->new();
    # bind params; bind params start counting at '1'
    my $column = 0;
    foreach my $key ( @{$file->attributes} ) {
        # skip the 'url', 'idgamesurl' and 'reviews' fields
        next if ( $key =~ /url|reviews/ );
        #$log->debug(qq(Unserializing: '$key' -> ') . $row[$column] . q('));
        # $file->{$key} needs the curly braces
        $file->{$key} = $row[$column];
        # go to the next column in the row array
        $column++;
    }
    return $file;
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

    perldoc App::WADTools::IndexDB

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
