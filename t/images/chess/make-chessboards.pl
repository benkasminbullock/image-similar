#!/home/ben/software/install/bin/perl

# Make PNG images of chessboards

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Cairo;
# http://www.lemoda.net/cairo/cairo-tutorial/line.html
for my $s (1..20) {
    my $size = $s * 100;
    my $surface = Cairo::ImageSurface->create ('rgb24', $size, $size);
    my $cr = Cairo::Context->create ($surface);
    for my $x (0..7) {
	for my $y (0..7) {
	    my $bw = $x + $y;
	    if ($bw % 2 == 0) {
		# White
		$cr->set_source_rgb (1, 1, 1);
	    }
	    else {
		# Black
		$cr->set_source_rgb (0, 0, 0);
	    }
	    # Draw a square of the chessboard.
	    $cr->rectangle ($x/8*$size, $y/8*$size,
			    ($x+1)/8*$size, ($y+1)/8*$size);
	    $cr->fill ();
	}
    }
    $surface->write_to_png ("$Bin/chess-$size.png");
}
