/* Given two grey images, compare them using the algorithm described
   in "An Image Signature for Any Kind of Image" by H. Chi Wong,
   Marshall Bern and David Goldberg, 2002. */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "similar-image.h"

#ifdef HEADER

/* A point in the grid. */

typedef struct point {
    double average_grey_level;
    int d[8];
}
point_t;

#define SIZE 9

typedef struct simage {
    /* The width of the image in pixels. */
    unsigned int width;
    /* The height of the image in pixels. */
    unsigned int height;
    /* The image data. */
    unsigned char * data;
    /* The P-value for this image, see equation in article. */
    unsigned int p;
    /* The grid of values. */
    point_t grid[SIZE*SIZE];
	double w10;
	double h10;
}
simage_t;

typedef enum {
    simage_ok,
    /* malloc failed. */
    simage_memory_failure,
    /* x or y is outside the image dimensions. */
    simage_status_bounds,
}
simage_status_t;

#endif /* def HEADER */

#define CHECK_XY(s,x,y) {			\
	if (x > s->width || x < 0) {		\
	    return simage_status_bounds;	\
	}					\
	if (y > s->height || y < 0) {		\
	    return simage_status_bounds;	\
	}					\
    }

simage_status_t
simage_dump (simage_t * s)
{
    printf ("{\n");
    printf ("\"width\":%d,\n", s->width);
    printf ("\"height\":%d,\n", s->height);
    printf ("\"p\":%d,\n", s->p);
    printf ("\"dummy\":0\n");
    printf ("}\n");
    return simage_ok;
}

simage_status_t
simage_init (simage_t * s, unsigned int width, unsigned int height)
{
    unsigned int p;
    /* The minimum of the width and the height. */
    unsigned int min_w_h;
    s->data = calloc (width * height, sizeof (unsigned char));
    if (! s->data) {
	return simage_memory_failure;
    }
    s->height = height;
    s->width = width;
    s->p = 2;
    min_w_h = width;
    if (height < min_w_h) {
	min_w_h = height;
    }
    p = (unsigned int) (floor (0.5 + ((double) min_w_h)/20.0));
    if (p > s->p) {
	s->p = p;
    }
    simage_dump (s);
    return simage_ok;
}

simage_status_t
simage_free (simage_t * s)
{
    if (s->data) {
	free (s->data);
    }
    return simage_ok;
}

simage_status_t
simage_set_pixel (simage_t * s, int x, int y, unsigned char grey)
{
    CHECK_XY (s, x, y);
    s->data[x * s->height + y] = grey;
    return simage_ok;
}

simage_status_t
simage_fill_entry (simage_t * s, int i, int j)
{
    double total;
    int px;
    int py;
    double xd;
    double yd;
    int x_min;
    int y_min;
    int x_max;
    int y_max;

    xd = (i + 1) * s->w10;
    yd = (j + 1) * s->h10;
    x_min = round (xd - s->p / 2.0);
    y_min = round (yd - s->p / 2.0);
    x_max = round (xd + s->p / 2.0);
    y_max = round (yd + s->p / 2.0);
    total = 0.0;
    for (px = x_min; px <= x_max; px++) {
	if (px < 0 || px >= s->width) {
	    fprintf (stderr, "overflow %d\n", px);
	}
	for (py = y_min; py <= y_max; py++) {
	    if (py < 0 || py >= s->height) {
		fprintf (stderr, "overflow %d\n", py);
	    }
	    total += s->data[px * s->width + py];
	}
    }
    int size = (x_max - x_min + 1) * (y_max - y_min + 1);
    printf ("%d %d %d %d %g %d\n", x_min, y_min, x_max, y_max,
	    total, (int) round (total / ((double) size)));
    return simage_ok;
}

simage_status_t
simage_fill_grid (simage_t * s)
{
    int i;
    int j;
    s->w10 = ((double) s->width) / 10.0;
    s->h10 = ((double) s->height) / 10.0;
    for (i = 0; i < SIZE; i++) {
	for (j = 0; j < SIZE; j++) {
	    simage_fill_entry (s, i, j);
	}
    }
    return simage_ok;
}
