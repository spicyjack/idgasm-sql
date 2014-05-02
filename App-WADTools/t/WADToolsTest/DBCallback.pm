#!perl -T

package WADToolsTest::DBCallback;
# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

use strictures 1; # strict + warnings
use Moo;
use Log::Log4perl qw(:no_extra_logdie_message);
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

sub db_request_callback {
    my $self = shift;
    my %args = @_;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger
    $log->info(q(DBCallback: received 'db_request_success' callback call));
    if ( exists $args{id} ) {
        $log->info(q(callback id: ) . $args{id});
    }
}

sub db_request_failure {
    my $self = shift;
    my $log = Log::Log4perl->get_logger(""); # "" = root logger
    $log->warn(q(received 'db_request_failure' callback call));
}
