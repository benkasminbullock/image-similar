#include <stdio.h>
#include "similar-image.h"

#define OK(test, counter, message, ...) {	\
	counter++;				\
	if (test) {				\
	    printf ("ok %d - ", counter);	\
	}					\
	else {					\
	    printf ("not ok %d - ", counter);	\
	}					\
	printf (message, ## __VA_ARGS__);	\
	printf (".\n");				\
    }


static void
test_xo_yo_to_direction (int * test)
{
    int direction;
    int xo, yo;
    simage_status_t status;
    direction = xo_yo_to_direction (-1, -1);
    OK (direction == 0, (*test), "%d should be 0\n", direction);
    status = direction_to_xo_yo (direction, & xo, & yo);
    OK (status == simage_ok, (*test), "status is OK");
    OK (xo == -1, (*test), "got correct value %d for xo", xo);
    OK (yo == -1, (*test), "got correct value %d for yo", yo);
    direction = xo_yo_to_direction (-1, 0);
    OK (direction == 3, (*test), "%d should be 3\n", direction);
    status = direction_to_xo_yo (direction, & xo, & yo);
    OK (status == simage_ok, (*test), "status is OK");
    OK (xo == -1, (*test), "got correct value %d for xo", xo);
    OK (yo == 0, (*test), "got correct value %d for yo", yo);
    direction = xo_yo_to_direction (1, 1);
    OK (direction == 7, (*test), "%d should be 7\n", direction);
    status = direction_to_xo_yo (direction, & xo, & yo);
    OK (status == simage_ok, (*test), "status is OK");
    OK (xo == 1, (*test), "got correct value %d for xo", xo);
    OK (yo == 1, (*test), "got correct value %d for yo", yo);
    status = direction_to_xo_yo (100, & xo, & yo);
    OK (status != simage_ok, (*test), "bad status for impossible direction");
}

static void
test_x_y_to_entry (int * test)
{
    int entry;
    int expect;
    entry = x_y_to_entry (0, 0);
    expect = 0;
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    entry = x_y_to_entry (1, 0);
    expect = 1;
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    entry = x_y_to_entry (0, 1);
    expect = 9;
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    entry = x_y_to_entry (8, 8);
    expect = 80;
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    expect = -1;
    entry = x_y_to_entry (-1, 0);
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    entry = x_y_to_entry (1, 10);
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    entry = x_y_to_entry (10, 1);
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    entry = x_y_to_entry (10, 10);
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    entry = x_y_to_entry (1, -1);
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
    entry = x_y_to_entry (-1, -1);
    OK (entry == expect, (*test), "%d should be %d", entry, expect);
}

static void
test_inside (int * test)
{
    int cell;
    int direction;
    cell = 0;
    direction = 4;
    OK (inside (cell, direction), (*test), "%d %d is inside", cell, direction);
    cell = 0;
    direction = 0;
    OK (! inside (cell, direction), (*test), "%d %d is not inside", cell, direction);
    cell = 80;
    direction = 0;
    OK (inside (cell, direction), (*test), "%d %d is inside", cell, direction);
    cell = 80;
    direction = 7;
    OK (! inside (cell, direction), (*test), "%d %d is not inside", cell, direction);
}

int main ()
{
    // Test directioner.
    int test;
    test = 0;

    test_xo_yo_to_direction (& test);
    test_x_y_to_entry (& test);
    test_inside (& test);
    // Print the test plan.
    printf ("1..%d\n", test);
    return 0;
}
