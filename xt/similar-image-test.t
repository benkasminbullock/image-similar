use warnings;
use strict;
use utf8;
use Deploy 'do_system';
use FindBin '$Bin';
chdir ("$Bin/..") or die $!;
do_system ("make -f mymakefile similar-image-test > /dev/null");
do_system ("prove ./similar-image-test");
