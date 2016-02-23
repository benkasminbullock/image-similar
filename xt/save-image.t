# This tests whether the module can correctly read in data by first
# reading in a file, then writing the data out again as a PNG, then
# comparing the data in the PNG output by the module with the data in
# the PNG output by Image::PNG::Libpng.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Image::Similar 'load_image';
use Imager;
use Image::PNG::Libpng '0.42', ':all';
my $file = "$Bin/../t/images/chess/chess-300.png";
my $chessout = "$Bin/chess-300.png";
if (-f $chessout) {
    unlink $chessout or die $!;
}
my $img = Imager->new ();
$img->read (file => $file);
my $is = load_image ($img);
$is->write_png ($chessout);

my $lenafile = "$Bin/lena-gercke.jpg";
my $imagerlenapng = "$Bin/imager-lena-grey.png";
my $imager = Imager->new ();
$imager->read (file => $lenafile);
my $islena = Image::Similar::load_image_imager ($imager, make_grey_png => 
						$imagerlenapng);
my $islenapng = "image-similar-lena-grey.png";
$islena->write_png ($islenapng);

ok (png_compare ($islenapng, $imagerlenapng) == 0, "images have the same data");
unlink $islenapng, $imagerlenapng;
done_testing ();
if (-f $chessout) {
    unlink $chessout or die $!;
}
