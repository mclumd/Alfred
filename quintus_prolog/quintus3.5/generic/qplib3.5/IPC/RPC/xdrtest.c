/*  File   : xdrtest.c
    Author : Richard A. O'Keefe
    Updated: 01 Nov 1988
    Purpose: test the System V dummy XDR routines.
*/

#include <stdio.h>
#include "xdr.h"

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/01 xdrtest.c	27.1";
#endif/*lint*/


struct test
    {
	char	c;
	long	l;
	char *	s;
	char	b[10];
    };

static char frobbitz[] = "frobbitz";

struct test original =
    {	'*',
	21345689,
	frobbitz,
	{8,6,9,2,5,0,6,4,9,1}
    };

void print_test(x)
    register struct test *x;
    {
	int i;
	printf("#S(test");
	printf(" :c '%c'", x->c);
	printf(" :l %d", x->l);
	printf(" :s \"%s\"", x->s);
	printf(" :b #10(");
	for (i = 0; i < 10; i++) printf("%d%c", x->b[i], (i==9?')':' '));
	printf(")\n");
    }

struct test copy;

bool_t xdr_test(xdrs, thing)
    XDR *xdrs;
    struct test *thing;
    {
	return
	    xdr_char(xdrs, &(thing->c)) &&
	    xdr_long(xdrs, &(thing->l)) &&
	    xdr_string(xdrs, &(thing->s), 20) &&
	    xdr_opaque(xdrs, thing->b, sizeof thing->b);
    }

main()
    {
	FILE *f;
	XDR xdr;

	f = fopen("#", "w");
	xdrstdio_create(&xdr, f, XDR_ENCODE);
	printf("before ENCODE: "); print_test(&original);
	if (!xdr_test(&xdr, &original)) {
	    printf("ENCODE failed\n");
	    abort();
	}
	xdr_destroy(&xdr);
	fclose(f);
	printf("after  ENCODE: "); print_test(&original);
	f = fopen("#", "r");
	xdrstdio_create(&xdr, f, XDR_DECODE);
	if (!xdr_test(&xdr, &copy)) {
	    printf("DECODE failed\n");
	    abort();
	}
	printf("after  DECODE: "); print_test(&copy);
	xdr_destroy(&xdr);
	fclose(f);
    }

