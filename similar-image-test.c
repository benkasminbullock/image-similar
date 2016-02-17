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
test_xo_yo_to_count (int * test)
{
    int count;
    count = xo_yo_to_count (-1, -1);
    OK (count == 0, (*test), "%d should be 0\n", count);
    count = xo_yo_to_count (-1, 0);
    OK (count == 3, (*test), "%d should be 3\n", count);
    count = xo_yo_to_count (1, 1);
    OK (count == 7, (*test), "%d should be 7\n", count);
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

int main ()
{
    // Test counter.
    int test;
    test = 0;

    test_xo_yo_to_count (& test);
    test_x_y_to_entry (& test);
    // Print the test plan.
    printf ("1..%d\n", test);
    return 0;
}
