# This runs a test written in C for the benefit of the Perl test framework.

use warnings;
use strict;
use utf8;
use Deploy 'do_system';
use FindBin '$Bin';
chdir ("$Bin/..") or die $!;
do_system ("make -f mymakefile similar-image-test > /dev/null");
do_system ("./similar-image-test");

