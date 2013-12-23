#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

=pod

    my $file = $db->get_file_by_path(
        path     => $short_path . q(/),
        filename => $filename,
    );
    if ( defined $file ) {
        $log->info(qq(Path/filename matched file ID ) . $file->id
            . q( in database));
        # quick test for round-trip-ability
        my $roundtrip = $db->get_file_by_id(id => $file->id);
        if ( ! defined $roundtrip ) {
            $log->logdie(q(Could not round-trip by file ID for )
                . $file->id);
        }
    }

=cut
