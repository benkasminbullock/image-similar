package Image::Similar;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/
		   load_image
	       /;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load ('Image::Similar', $VERSION);
use Scalar::Util 'looks_like_number';

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
	for my $x (0..$width -1) {
	    # Dunno a better way to do this, please shout if you do.
	    my ($grey, undef, undef, undef) = $scanline[$x]->rgba ();
	    if ($grey < 0 || $grey > 255) {
		carp "Pixel value $grey at $x, $y is not allowed, need 0-255 here";
		next;
	    }
#	    print "x, y, grey = $x $y $grey\n";
	    $is->{image}->set_pixel ($x, $y, $grey);
	}
    }
    $is->fill_grid ();
    return $is;
}

sub load_image_libpng
{
    eval "use Image::PNG::Libpng;";
    if ($@) {
	carp "Error loading Image::PNG::Libpng: $@";
	return undef;
    }
    my ($image) = @_;
#    print "Loading $image\n";
    my $ihdr = $image->get_IHDR ();
    my $height = $ihdr->{height};
my $width = $ihdr->{width};
    my $is = Image::Similar->new (height => $height,
				  width => $width);
    my $rows = $image->get_rows ();
    if ($ihdr->{color_type} == 0) {
	# GRAY
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $grey = ord (substr ($rows->[$y], $x, 1));
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    elsif ($ihdr->{color_type} = 4) {
	# GRAY_ALPHA
	carp "Discarding alpha channel and ignoring background";
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $grey = ord (substr ($rows->[$y], $x * 2, 1));
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    elsif ($ihdr->{color_type} = 2 || $ihdr->{color_type} == 6) {
	# RGB or RGBA
	my $offset = 3;
	if ($ihdr->{color_type} == 6) {
	    $offset = 4;
	    carp "Discarding alpha channel and ignoring background";
	}
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $r = ord (substr ($rows->[$y], $x * $offset, 1));
		my $g = ord (substr ($rows->[$y], $x * $offset + 1, 1));
		my $b = ord (substr ($rows->[$y], $x * $offset + 2, 1));
		# https://metacpan.org/pod/distribution/Imager/lib/Imager/Transformations.pod
		my $grey = 0.222 * $r + 0.707 * $g + 0.071 * $b;
		$grey = int ($grey + 0.5);
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
    eval "use Image::PNG::Libpng;";
    if ($@) {
	carp "write_png requires you to install Image::PNG::Libpng";
	return;
    }
    my $png = Image::PNG::Libpng::create_write_struct ();
    $png->set_IHDR ({
	height => $is->{height},
	width => $is->{width},
	bit_depth => 8,
	color_type => 0,     # Image::PNG::Const::PNG_COLOR_TYPE_GRAY,
    });
    my $rows = $is->{image}->get_rows ();
    if (scalar (@$rows) != $is->{height}) {
	die "Error: bad numbers: $is->{height} != " . scalar (@$rows);
    }
    $png->set_rows ($rows);
    $png->write_png_file ($filename);
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
