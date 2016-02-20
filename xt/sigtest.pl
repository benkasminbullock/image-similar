#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Imager;
use lib '/home/ben/projects/image-similar/blib/lib';
use lib '/home/ben/projects/image-similar/blib/arch';
use Image::Similar 'load_image';
my $i = Imager->new ();
my @files = ('xt/lena-gercke.jpg', 't/images/lenagercke/lena-200.png');
for my $file (@files) {
$i->read (file => $file) or die $i->errstr ();
my $is = load_image ($i);
print $is->signature (), "\n";
}
