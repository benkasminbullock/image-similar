#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "image-similar-perl.c"

typedef image_similar_t * Image__Similar;

MODULE=Image::Similar PACKAGE=Image::Similar

PROTOTYPES: DISABLE

BOOT:
	/* Image__Similar_error_handler = perl_error_handler; */

