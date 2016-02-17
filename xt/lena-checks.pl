#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Imager;
use Image::PNG::Libpng ':all';
use lib '/home/ben/projects/image-similar/blib/lib';
use lib '/home/ben/projects/image-similar/blib/arch';
use Image::Similar 'load_image';
my $lena = Imager->new ();
$lena->read (file => "$Bin/../xt/lena-gercke.jpg");
my $img = load_image ($lena);
goto skip;
for my $s (1..10) {
    my $size = $s * 100;
    my $lenax = Imager->new ();
    my $file = "$Bin/../t/images/lenagercke/lena-$size.png";
    $lenax->read (file => $file);
#    print "loading $file\n";
    my $imgx = load_image ($lenax);
#    print "OK $file\n";
    print "$size: diff = " , $img->diff ($imgx), "\n";
}
print "original: diff = ", $img->diff ($img), "\n";
skip:
my $chess2000 = read_png_file ("$Bin/../t/images/chess/chess-2000.png");
my $chess2000is = load_image ($chess2000);
for my $s (1..10) {
    my $size = $s * 100;
my $chessx = read_png_file ("$Bin/../t/images/chess/chess-$size.png");
my $chessis = load_image ($chessx);
print "$size: diff = ", $img->diff ($chessis), "\n";
print "$size: diff = ", $chess2000is->diff ($chessis), "\n";
}
