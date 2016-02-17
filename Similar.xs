#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "similar-image.h"
#include "image-similar-perl.c"

#define SIMAGE_CALL(x) x

typedef simage_t * Image__Similar__Image;

MODULE=Image::Similar PACKAGE=Image::Similar::Image

PROTOTYPES: DISABLE

Image::Similar::Image
isnew (width, height);
	int width;
	int height;
CODE:
	Newxz (RETVAL, 1, simage_t);
	SIMAGE_CALL (simage_init (RETVAL, width, height));
OUTPUT:
	RETVAL

void
DESTROY (image)
	Image::Similar::Image image;
CODE:
	SIMAGE_CALL (simage_free (image));
	Safefree (image);

void
set_pixel (image, x, y, grey)
	Image::Similar::Image image
	int x
	int y
	unsigned char grey
CODE:
	//printf ("%d %d\n", x, y);
	SIMAGE_CALL (simage_set_pixel (image, x, y, grey));

AV *
get_rows (image)
	Image::Similar::Image image
PREINIT:
	int y;
CODE:
	RETVAL = newAV ();
	for (y = 0; y < image->height; y++) {
	    //printf ("%d\n", y);
	    av_push (RETVAL, newSVpv ((const char *) image->data + y * image->width, image->width));
	}
OUTPUT:
	RETVAL

void
fill_grid (image)
	Image::Similar::Image image
CODE:
	SIMAGE_CALL (simage_fill_grid (image));
