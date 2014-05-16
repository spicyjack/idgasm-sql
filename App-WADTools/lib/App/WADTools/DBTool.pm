#################################
# package App::WADTools::DBTool #
#################################
package App::WADTools::DBTool;

=head1 NAME

App::WADTools::DBTool

=head1 SYNOPSIS

 # in the 'db_tool' script
 my $controller = App::WADTools::DBTool->new();
 $controller->run();

=head1 DESCRIPTION

A controller (as in, Model-View-Controller design pattern) for the C<db_tool>
script.

=cut

# system modules
use Moo;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::WADTools::Error;
use App::WADTools::idGamesDB;
use App::WADTools::INIFile;
use App::WADTools::Timer;

=head2 Attributes

=over

=item view

The view object, which controls the user interface shown to the user.

=cut

has q(view) => (
    # https://metacpan.org/pod/Moo#has
    # 'rwp' generates a reader like 'ro', but also sets writer to
    # _set_${attribute_name} for attributes that are designed to be written
    # from inside of the class, but read-only from outside.
    is  => q(rwp),
    isa => sub{ ref($_[0]) =~ /View/ },
);

=item model

The model object, which will handle reading and updating various databases.

=cut

has q(model) => (
    is => q(rwp),
    isa => sub{ ref($_[0]) =~ /Model/i },
);

=item config

The L<App::WADTools::Config> object, which sets up what actions this object
will perform, and also what files those actions will be performed on.

=cut

has q(config) => (
    is => q(ro),
    isa => sub{ ref($_[0]) =~ /Config/ },
);

=item filename

The filename of the database file to create.  Accepts a special parameter,
C<:memory:>, which creates a temporary database in memory.  If this parameter
is C<undef> when the L<run()> method is called, the parameter C<output> from
the L<Config> object will be used instead.

=cut

has q(filename) => (
    is => q(rwp),
);


=back

=head2 Methods

=over

=item new()

Creates the L<App::WADTools::DBTool> object and returns it to the
caller.

=item run()

Transfers control of the program to the L<DBTool> object.

=cut

sub run {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    my $cfg = $self->config;
    my $view = $self->view;

    if ( ! defined $cfg && ref($cfg) !~ /App::WADTools::Config/ ) {
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(dbtool.run.missing_config),
            message => qq(App::WADTools::Config object missing/unavailable),
        );
        return $error;
    }

    if ( ! defined $view && ref($view) !~ /App::WADTools::View/ ) {
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(dbtool.run.missing_view),
            message => qq(App::WADTools::View object missing/unavailable),
        );
        return $error;
    }

    # start the script timer
    my $timer = App::WADTools::Timer->new();
    $log->debug(q(Starting timer for: ) . __PACKAGE__);
    $timer->start(name => __PACKAGE__);

    my $db_schema;
    my $ini_file = App::WADTools::INIFile->new(
        filename => $cfg->get(q(input)));
    if ( ref($ini_file) eq q(App::WADTools::Error) ) {
        $view->request_failure(
            level => q(fault),
            id    => q(dbtool.inifile.create),
            msg   => q(Error opening INI file ') . $cfg->get(q(input)) . q(')
        );
    }
    if ( ! defined $self->filename || length($self->filename) == 0 ) {
        my $output_file = $cfg->get(q(output));
        $log->debug(qq(Setting output filename to: $output_file));
        $self->_set_filename($output_file);
        $log->debug(q(Filename is now: ) . $self->filename);
    }

    if ( $cfg->defined(q(create-db)) ) {
        # FIXME view
        #$log->warn(q(Creating database file ) . $cfg->get(q(output));
        $log->warn(q(Creating database file ) . $self->filename);
        if ( $cfg->get(q(input)) =~ /\.ini$/ ) {
            $db_schema = $ini_file->read_ini_config();
            #$ini_file->dump_schema(
            #    db_schema  => $db_schema,
            #    extra_text => q(Dump called from --create-db block),
            #);
            $log->debug(q(Parsing schema metadata;));
            $log->debug(q(  Epoch:    )
                . $db_schema->{q(default)}->{q(schema_epoch)});
            $log->debug(q(  Date:     )
                . $db_schema->{q(default)}->{q(schema_date)});
            $log->debug(q(  Notes:    )
                . $db_schema->{q(default)}->{q(schema_notes)});
            if ( exists $db_schema->{q(default)}->{q(base_url)} ) {
                $log->debug(q(  Base URL: )
                    . $db_schema->{q(default)}->{q(base_url)});
            }
            my $db = App::WADTools::idGamesDB->new(
                filename => $self->filename,
                callback => $self,
            );

            # FIXME view
            $log->warn(q(Checking for existing schema...));
            $log->warn(q|(Note: errors checking for schema are harmless)|);
            my $schema_entries = $db->has_schema;
            if ( $schema_entries == 0 ) {
                # FIXME view
                $log->warn(q(DB schema empty, calling 'apply_schema'));
                $db->apply_schema(schema => $db_schema);
            } elsif ( $schema_entries->can(q(is_error)) ) {
                $schema_entries->log_error();
                # FIXME view
                $log->logdie(q(Error connecting to the database));
            } else {
                # FIXME view
                $log->warn(q(DB schema has already been populated;));
                $log->warn(qq(Schema has $schema_entries entries));
            }
            # FIXME view
            $log->warn(q(DB schema creation complete!));
        } else {
            $timer->stop(name => __PACKAGE__);
            my $error = App::WADTools::Error->new(
                level     => q(fatal),
                id        => q(dbtool.unknown_file_type),
                message   => q(Don't know how to process file ')
                    . $cfg->get(q(input)) . q('),
            );
            # FIXME view
            return $error;
        }
    } elsif ( $cfg->defined(q(create-yaml)) ) {
    } elsif ( $cfg->defined(q(create-ini)) ) {
    } elsif ( $cfg->defined(q(checksum)) ) {
        # FIXME view
        $log->warn(q(Checksumming database schema INI file...));
        if ( $cfg->get(q(input)) =~ /\.ini$/ ) {
            # MD5 checksums, for now
            $db_schema = $ini_file->read_ini_config();
            $db_schema = $ini_file->md5_checksum(db_schema => $db_schema);
            $ini_file->dump_schema(
                db_schema  => $db_schema,
                extra_text => q(Dump called post-MD5 checksum),
            );
            my $filesize = $ini_file->write_ini_config(
                db_schema => $db_schema
            );
            if ( ref($filesize) eq q(App::WADTools::Error) ) {
                # FIXME view
                $log->error(q(Writing config file returned an error!));
                $log->logdie(q(Error message: ) . $filesize->error_msg);
            } else {
                # FIXME view
                $log->warn(q(Wrote file ) . $ini_file->filename);
                $log->warn(q(File size: ) . $filesize . q| byte(s)|);
            }
        } else {
            # FIXME view
            $log->logdie(q(Don't know how to process file )
                . $cfg->get(q(input)));
        }
    } else {
        $timer->stop(name => __PACKAGE__);
        my $error = App::WADTools::Error->new(
            level   => q(fatal),
            id      => q(dbtool.unknown_option),
            message => q(Please specify a valid script action),
        );
        # FIXME view
        return $error;
    }

    $timer->stop(name => __PACKAGE__);
    my $total_script_execution_time =
        $timer->time_value_difference(name => __PACKAGE__);
}

=item request_update()

Callback for updating the status of an ongoing request.

=cut

sub request_update {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->debug(q(Received request_update callback from: ) . $args{id});
    $self->view->request_update(%args);
}

=item request_success()

Callback for indicating a request was successful.

=cut

sub request_success {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->debug(q(Received request_success callback from: ) . $args{id});
    $self->view->request_success(%args);
}

=item request_failure()

Callback for indicating a request failed.

=cut

sub request_failure {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger

    $log->debug(q(Received request_failure callback from: ) . $args{id});
    $self->view->request_failure(%args);
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

    perldoc App::WADTools::DBTool

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013-2014 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
