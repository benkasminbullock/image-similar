#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Imager;
use FindBin '$Bin';
my $photo = "$Bin/../../../xt/lena-gercke.jpg";
my $img = Imager->new ();
$img->read (file => $photo) or die $img->errstr ();
for my $s (1..10) {
    my $size = 100*$s;
    my $out = $img->scale (xpixels => $size, ypixels => $size);
    $out->write (file => "lena-$size.png") or die $out->errstr ();
}

