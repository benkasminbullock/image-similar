package Image::Similar;
use warnings;
use strict;
require Exporter;
use base 'Exporter';
our @EXPORT_OK = qw/
		       load_image
		   /;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use Image::PNG::Libpng ':all';
use Image::PNG::Const;
use Scalar::Util 'looks_like_number';
use Carp;

use constant (
    # Constants used for combining red, green, and blue values. These
    # values are taken from the L<Imager> source code.
    red => 0.222,
    green => 0.707,
    blue => 0.071,
    # bytes per pixel for rgb
    rgb_bytes => 3,
    # bytes per pixel for rgba
    rgb_bytes => 4,
    # Maximum possible grey pixel
    maxgreypixel => 255,
    half => 0.5,
);

our $VERSION = '0.03';
require XSLoader;
XSLoader::load ('Image::Similar', $VERSION);

# Remember children: We Must Never Include "round" In The Perl Core
# Modules, because that would be convenient and useful and we would
# not be able to behave like a bunch of stupid, passive-aggressive
# dipshits by pointing people to the insane drivel in perlfaq, but
# just have a simple solution that actually works.

sub round
{
    my ($float) = @_;
    return int ($float + half);
}

sub new
{
    my ($class, %options) = @_;
    my $is = {};
    for my $field (qw/height width/) {
	if ($options{$field}) {
	    if (! looks_like_number ($options{$field})) {
		carp "$field value doesn't look like a number";
	    }
	    $is->{$field} = $options{$field};
	}
	else {
	    carp "Missing option $field";
	    return;
	}
    }
#    print "$is->{height} $is->{width}\n";
    $is->{image} = Image::Similar::Image::isnew ($is->{width}, $is->{height});
#    print "Finished isnew with $is->{image}\n";
    bless $is, $class;
    return $is;
}

sub fill_grid
{
    my ($s) = @_;
    $s->{image}->fill_grid ();
    return;
}

# Load an image assuming it's from Imager.

sub load_image_imager
{
    my ($imager, %options) = @_;
    my $grey = $imager->convert (preset => 'gray');
    if ($options{make_grey_png}) {
	$grey->write (file => $options{make_grey_png});
    }
    my $height = $grey->getheight ();
    my $width = $grey->getwidth ();
    my $is = Image::Similar->new (height => $height, width => $width);
    for my $y (0..$height - 1) {
#	print "$y\n";
	my @scanline = $grey->getscanline (y => $y);
	for my $x (0..$width - 1) {
	    # Dunno a better way to do this, please shout if you do.
	    my ($greypixel, undef, undef, undef) = $scanline[$x]->rgba ();
	    if ($greypixel < 0 || $grey > maxgreypixel) {
		carp "Pixel value $greypixel at $x, $y is not allowed, need 0-255 here";
		next;
	    }
#	    print "x, y, grey = $x $y $greypixel\n";
	    $is->{image}->set_pixel ($x, $y, $greypixel);
	}
    }
    $is->fill_grid ();
    return $is;
}

# # C<$libpng_ok> is set to a true value if Image::PNG::Libpng has
# # already successfully been loaded.

# my $libpng_ok;

# # Load Image::PNG::Libpng.

# sub load_libpng
# {
#     if ($libpng_ok) {
# 	return 1;
#     }
#     my $use_ok = eval "use Image::PNG::Libpng;";
#     if (! $use_ok || $@) {
# 	carp "Error loading Image::PNG::Libpng: $@";
# 	return;
#     }
#     $libpng_ok = 1;
#     return 1;
# }

sub load_image_libpng
{
    my ($image) = @_;
#    load_libpng () or return;
    my $ihdr = $image->get_IHDR ();
    my $height = $ihdr->{height};
    my $width = $ihdr->{width};
    my $is = Image::Similar->new (height => $height,
				  width => $width);
    my $rows = $image->get_rows ();
    if ($ihdr->{color_type} == PNG_COLOR_TYPE_GRAY) {
	# GRAY
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $grey = ord (substr ($rows->[$y], $x, 1));
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    elsif ($ihdr->{color_type} == PNG_COLOR_TYPE_GRAY_ALPHA) {
	# GRAY_ALPHA
	carp 'Discarding alpha channel and ignoring background';
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $grey = ord (substr ($rows->[$y], $x * 2, 1));
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    elsif ($ihdr->{color_type} == PNG_COLOR_TYPE_RGB ||
	   $ihdr->{color_type} == PNG_COLOR_TYPE_RGB_ALPHA) {
	# RGB or RGBA

	# $offset is the number of bytes per pixel.
	my $offset = rgb_bytes;
	if ($ihdr->{color_type} == PNG_COLOR_TYPE_RGB_ALPHA) {
	    $offset = rgba_bytes;
	    # We should try to use the alpha channel to blend in a
	    # background colour here, but we don't.
	    carp 'Discarding alpha channel and ignoring background';
	}
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $r = ord (substr ($rows->[$y], $x * $offset, 1));
		my $g = ord (substr ($rows->[$y], $x * $offset + 1, 1));
		my $b = ord (substr ($rows->[$y], $x * $offset + 2, 1));
		# https://metacpan.org/pod/distribution/Imager/lib/Imager/Transformations.pod
		my $grey = red * $r + green * $g + blue * $b;
		$grey = round ($grey);
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    else {
	carp "Cannot handle image of colour type $ihdr->{color_type}";
    }
    $is->fill_grid ();
    return $is;
}

sub load_image
{
    my ($image) = @_;
    my $imtype = ref $image;
    if ($imtype eq 'Imager') {
	return load_image_imager ($image);
    }
    elsif ($imtype eq 'Image::PNG::Libpng') {
	return load_image_libpng ($image);
    }
    carp "Unknown object type $imtype, cannot load this image";
    return undef;
}

sub write_png
{
    my ($is, $filename) = @_;
#    load_libpng () or return;
    my $png = Image::PNG::Libpng::create_write_struct ();
    $png->set_IHDR ({
	height => $is->{height},
	width => $is->{width},
	bit_depth => 8,
	color_type => 0,     # Image::PNG::Const::PNG_COLOR_TYPE_GRAY,
    });
    my $rows = $is->{image}->get_rows ();
    if (scalar (@{$rows}) != $is->{height}) {
	die "Error: bad numbers: $is->{height} != " . scalar (@{$rows});
    }
    $png->set_rows ($rows);
    $png->write_png_file ($filename);
    return;
}

sub diff
{
    my ($s1, $s2) = @_;
    return $s1->{image}->image_diff ($s2->{image});
}

sub signature
{
    my ($s) = @_;
    return $s->{image}->signature ();
}

1;
