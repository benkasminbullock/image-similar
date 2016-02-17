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
use Image::PNG::Libpng ':all';
my $file = "$Bin/../t/images/chess/chess-300.png";
my $img = Imager->new ();
$img->read (file => $file);
my $is = load_image ($img);
$is->fill_grid ();
$is->write_png ("$Bin/chess-300.png");

my $lenafile = "$Bin/lena-gercke.jpg";
my $imagerlenapng = "$Bin/imager-lena-grey.png";
my $imager = Imager->new ();
$imager->read (file => $lenafile);
my $islena = Image::Similar::load_image_imager ($imager, make_grey_png => 
						$imagerlenapng);
my $islenapng = "image-similar-lena-grey.png";
$islena->write_png ($islenapng);

my $png1 = read_png_file ("$imagerlenapng");
my $png2 = read_png_file ("$islenapng");
my $header1 = $png1->get_IHDR ();
my $header2 = $png2->get_IHDR ();
for my $field (qw/height width/) {
    ok ($header1->{$field} == $header2->{$field}, "$field");
}
my $pixels_diff;
my $rows1 = $png1->get_rows ();
my $rows2 = $png2->get_rows ();
for my $x (0..$header1->{width} - 1) {
    for my $y (0..$header1->{height} - 1) {
	my $pixel1 = substr ($rows1->[$y], $x, 1);
	my $pixel2 = substr ($rows2->[$y], $x, 1);
	if ($pixel1 ne $pixel2) {
	    $pixels_diff = 1;
	}
    }
}
ok (! $pixels_diff, "All the pixels are the same");
unlink $islenapng, $imagerlenapng;
done_testing ();
