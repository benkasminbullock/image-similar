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
#define DIRECTIONS 8

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
    simage_status_bad_image,
}
simage_status_t;

typedef enum {
    much_darker = -2,
    darker = -1,
    same = 0,
    lighter = 1,
    much_lighter = 2,
}
comparison_t;

#endif /* def HEADER */

#define CALL(x) {					\
	simage_status_t status;				\
	status = x;					\
	if (status != simage_ok) {			\
	    fprintf (stderr, "%s:%d: error %d\n",	\
		     __FILE__, __LINE__, status);	\
	    return status;				\
	}						\
    }

#define CHECK_XY(s,x,y) {			\
	if (x > s->width || x < 0) {		\
	    return simage_status_bounds;	\
	}					\
	if (y > s->height || y < 0) {		\
	    return simage_status_bounds;	\
	}					\
    }

#define OUTSIDE -1

/* Given x and y coordinates, return the part of the grid which
   corresponds to that. */

int x_y_to_entry (int x, int y)
{
    int entry;
    if (x < 0 || x >= SIZE) {
	return OUTSIDE;
    }
    if (y < 0 || y >= SIZE) {
	return OUTSIDE;
    }
    entry = y * SIZE + x;
    if (entry < 0 || entry >= SIZE * SIZE) {
	fprintf (stderr, "%s:%d: overflow %d\n", __FILE__, __LINE__, entry);
	return OUTSIDE;
    }
    return entry;
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
    //    simage_dump (s);
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
    s->data[y * s->width + x] = grey;
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
    int size;
    int entry;
    int grey;
    xd = (i + 1) * s->w10;
    yd = (j + 1) * s->h10;
    x_min = round (xd - s->p / 2.0);
    y_min = round (yd - s->p / 2.0);
    x_max = round (xd + s->p / 2.0);
    y_max = round (yd + s->p / 2.0);
    total = 0.0;
    for (py = y_min; py <= y_max; py++) {
	if (py < 0 || py >= s->height) {
	    fprintf (stderr, "overflow %d\n", py);
	}
	for (px = x_min; px <= x_max; px++) {
	    if (px < 0 || px >= s->width) {
		fprintf (stderr, "overflow %d\n", px);
	    }
	    total += s->data[py * s->width + px];
	}
    }
    size = (x_max - x_min + 1) * (y_max - y_min + 1);
    grey = (int) round (total / ((double) size));
    if (grey < 0 || grey >= 256) {
	fprintf (stderr, "%s:%d: bad average grey value %d.\n",
		 __FILE__, __LINE__, grey);
	return simage_status_bounds;
    }
    entry = x_y_to_entry (i, j);
    if (entry == OUTSIDE) {
	fprintf (stderr, "%s:%d: bounds error with %d %d -> %d\n",
		 __FILE__, __LINE__, i, j, entry);
	return simage_status_bounds;
    }
    s->grid[entry].average_grey_level = grey;
    return simage_ok;
}

/* Go around the image and make the average values for each of the
   points on the grid. */

simage_status_t
simage_fill_entries (simage_t * s)
{
    int i;
    int j;
    if (s->width == 0 || s->height == 0) {
	fprintf (stderr, "%s:%d: empty image w/h %d/%d.\n",
		 __FILE__, __LINE__, s->width, s->height);
	return simage_status_bad_image;
    }
    s->w10 = ((double) s->width) / ((double) (SIZE + 1));
    s->h10 = ((double) s->height) / ((double) (SIZE + 1));
    for (i = 0; i < SIZE; i++) {
	for (j = 0; j < SIZE; j++) {
	    CALL (simage_fill_entry (s, i, j));
	}
    }
    return simage_ok;
}

/* Given offsets xo and yo, return the array offset for the difference
   array which corresponds to that. */

int xo_yo_to_count (int xo, int yo)
{
    int count;
    if (xo <= 0 && yo <= 0) {
	count = (xo + 1) + 3 * (yo + 1);
    }
    else {
	// Adjust for not having a centre square, so +1, +1 is 7, not 8.
	count = (xo + 1) + 3 * (yo + 1) - 1;
    }
    return count;
}

simage_status_t
count_to_xo_yo (int count, int * xo, int * yo)
{
    if (count < 3) {
	* yo = -1;
	* xo = count - 1;
	return simage_ok;
    }
    if (count < 5) {
	* yo = 0;
	if (count == 3) {
	    * xo = -1;
	}
	else if (count == 4) {
	    * xo = 1;
	}
	else {
	    return simage_status_bounds;
	}
	return simage_ok;
    }
    if (count < DIRECTIONS) {
	* yo = 1;
	* xo = count - 6;
	return simage_ok;
    }
    fprintf (stderr, "%s:%d: count %d >= DIRECTIONS %d.\n",
	     __FILE__, __LINE__, count, DIRECTIONS);
    return simage_status_bounds;
}

int diff (int thisgrey, int thatgrey)
{
    int d;
    d = thisgrey - thatgrey;
    if (d >= -2 && d <= 2) {
	return same;
    }
    else if (d > 100) {
	return much_darker;
    }
    else if (d > 2) {
	return darker;
    }
    else if (d < -100) {
	return much_lighter;
    }
    else if (d < -2) {
	return lighter;
    }
    else {
	fprintf (stderr, "%s:%d: mysterious d value %d\n",
		 __FILE__, __LINE__, d);
	return same;
    }
}

/* Make the difference between two adjoining points. */

simage_status_t
simage_make_point_diffs (simage_t * s, int x, int y)
{
    int xo;
    int yo;
    int thisgrey;
    int thisentry;
    point_t * thispoint;
    thisentry = x_y_to_entry (x, y);
    /* Make 100% sure that we don't try to access outside the "grid" array
       within "s". */
    if (thisentry == OUTSIDE) {
	fprintf (stderr, "%s:%d: entry outside grid %d %d %d\n",
		 __FILE__, __LINE__, x, y, thisentry);
	return simage_status_bounds;
    }
    thispoint = & s->grid[thisentry];
    thisgrey = thispoint->average_grey_level;
    for (xo = -1; xo <= 1; xo++) {
	for (yo = -1; yo <= 1; yo++) {
	    int thatentry;
	    int count;
	    int thatgrey;
	    if (xo == 0 && yo == 0) {
		// Skip the middle square, since this would be the
		// difference between us and ourselves.
		continue;
	    }
	    thatentry = x_y_to_entry (x + xo, y + yo);
	    if (thatentry == OUTSIDE) {
		// Skip entries which are outside the grid, which
		// happens e.g. if x = 0 and xo = -1.
		continue;
	    }
	    // Get the grey level of the other point
	    thatgrey = s->grid[thatentry].average_grey_level;
	    // turn xo, yo into an array offset "count".
	    count = xo_yo_to_count (xo, yo);
	    // Put the difference into d[count] of the current point.
	    thispoint->d[count] = diff (thisgrey, thatgrey);
	    //	    fprintf (stderr, "# %d %d %d\n", thisentry, count, thispoint->d[count]);
	}
    }
    return simage_ok;
}

/* Make the array of differences between adjoining points. */

simage_status_t
simage_make_differences (simage_t * s)
{
    int cell;
    for (cell = 0; cell < SIZE * SIZE; cell++) {
	int x;
	int y;
	x = cell % SIZE;
	y = cell / SIZE;
	CALL (simage_make_point_diffs (s, x, y));
    }
    return simage_ok;
}

#define MAXDIM 10000

simage_status_t
simage_check_image (simage_t * s)
{
    if (s->width == 0 || s->height == 0) {
	fprintf (stderr, "%s:%d: empty image w/h %d/%d.\n",
		 __FILE__, __LINE__, s->width, s->height);
	return simage_status_bad_image;
    }
    if (s->width > MAXDIM || s->height > MAXDIM) {
	fprintf (stderr, "%s:%d: oversize image w/h %d/%d.\n",
		 __FILE__, __LINE__, s->width, s->height);
	return simage_status_bad_image;
    }
    return simage_ok;
}

simage_status_t
simage_fill_grid (simage_t * s)
{
    CALL (simage_check_image (s));
    CALL (simage_fill_entries (s));
    CALL (simage_make_differences (s));
    return simage_ok;
}

simage_status_t
simage_diff (simage_t * s1, simage_t * s2, double * total_diff)
{
    int total;
    int total1;
    int total2;
    int cell;
    total = 0;
    total1 = 0;
    total2 = 0;
    for (cell = 0; cell < SIZE * SIZE; cell++) {
	int direction;
	for (direction = 0; direction < DIRECTIONS; direction++) {
	    int diff;
	    int s1cd;
	    int s2cd;
	    s1cd = s1->grid[cell].d[direction];
	    s2cd = s2->grid[cell].d[direction];
	    diff = s1cd - s2cd;
	    // Add the squares of the values to the totals.
	    total += diff * diff;
	    total1 += s1cd * s1cd;
	    total2 += s2cd * s2cd;
	}
    }
    if (total1 == 0 && total2 == 0) {
	*total_diff = 0.0;
	return simage_ok;
    }
    *total_diff = ((double) total) / ((double)(total1 + total2));
    return simage_ok;
}

	    /* Check whether this direction and cell point to another
	       cell or are outside the image. */

int inside (int cell, int direction)
{
    int x;
    int y;
    int xo;
    int yo;
    int nextcell;
    x = cell % SIZE;
    y = cell / SIZE;
    count_to_xo_yo (direction, & xo, & yo);
    nextcell = x_y_to_entry (x + xo, y + yo);
    if (nextcell == OUTSIDE) {
	return 0;
    }
    return 1;
}


simage_status_t
simage_signature (simage_t * s, char ** signature_ptr, int * signature_length)
{
    int cell;
    int max_size;
    int sl;
    char * signature;
    max_size = DIRECTIONS * SIZE * SIZE;
    signature = calloc (max_size + 1, sizeof (unsigned char));
    if (! signature) {
	fprintf (stderr, "%s:%d: memory error.\n", __FILE__, __LINE__);
	return simage_memory_failure;
    }
    sl = 0;
    for (cell = 0; cell < SIZE * SIZE; cell++) {
	int direction;
	for (direction = 0; direction < DIRECTIONS; direction++) {
	    if (inside (cell, direction)) {
		int value;
		value = s->grid[cell].d[direction] + 2 + '0';
		if (value < '0' || value > '5') {
		    fprintf (stderr, "%s:%d: overflow %d at cell=%d direction=%d",
			     __FILE__, __LINE__, value, cell, direction);
		    return simage_status_bounds;
		}
		signature[cell * DIRECTIONS + direction] = (char) value;
		sl++;
	    }
	}
    }
    * signature_ptr = signature;
    * signature_length = sl;
    
    return simage_ok;
}

simage_status_t simage_free_signature (char * signature)
{
    free (signature);
    return simage_ok;
}

