#!perl -T

package WADToolsTest::Logging;
# Copyright (c) 2014 Brian Manning <brian at xaoc dot org>
# For support with this file, please file an issue on the GitHub issue tracker
# for this project: https://github.com/spicyjack/wadtools/issues

use strictures 1; # strict + warnings
use Moo::Role;
use Log::Log4perl qw(:no_extra_logdie_message);
#use Data::Dumper;
#$Data::Dumper::Indent = 1;
#$Data::Dumper::Sortkeys = 1;
#$Data::Dumper::Terse = 1;

sub setup_logging {
    my $dirname = dirname($0);
    die qq(ERROR: Can't find config file 'tests.log4perl.cfg' in:\n> $dirname))
        unless ( -f qq($dirname/tests.log4perl.cfg.foo) );
    Log::Log4perl->init_once(qq($dirname/tests.log4perl.cfg));
}

1;
