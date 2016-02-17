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
our $VERSION = '0.01';
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

# Load an image assuming it's from Imager.

sub load_image_imager
{
    my ($imager) = @_;
    my $grey = $imager->convert (preset => 'gray');
    my $height = $grey->getheight ();
    my $width = $grey->getwidth ();
    my $is = Image::Similar->new (height => $height, width => $width);
    for my $y (0..$height - 1) {
#	print "$y\n";
	my @scanline = $imager->getscanline (y => $y);
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
    return $is;
}

sub load_image
{
    my ($image) = @_;
    my $imtype = ref $image;
    if ($imtype eq 'Imager') {
	return load_image_imager ($image);
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

sub fill_grid
{
my ($s) = @_;
$s->{image}->fill_grid ();
}


1;
