/* @(#)math.c	26.1 11/16/88 */

/*
	+--------------------------------------------------------+
	| 							 |
        |        Math Library (a C-interface example)            |
        |							 |
        |							 |
	|  Copyright (C) 1985,  Quintus Computer Systems, Inc.   |
	|  All rights reserved.					 |
	|							 |
	+--------------------------------------------------------+ */



/* ----------------------------------------------------------------------
   The math library is supplied with your Unix system.  It contains a
   number of common mathmetical (mostly transcendental) functions.  We
   have added one additional C procedure, qp_cabs.  This was needed
   because the cabs ("complex absolute value") procedure takes a structure
   representing a complex.  Because the C-interface does not directly
   pass struct types, it must pass two floats and have the structure
   constructed by C.  qp_cabs, then, computes the formula:

                          sqrt(X**2 + Y**2)

   ---------------------------------------------------------------------- */
   

#include <math.h>		/* include math library definitions */

#ifdef BSD

extern double cabs();		/* cabs declaration - missing from math.h */

#else

double cabs();

double cabs(pt)
struct {double x,y;} pt;
{
	return( sqrt(pt.x*pt.x+pt.y*pt.y));
}

#endif


double qp_cabs(x,y)		/* C-interface qp_cabs/2 */
    double x,y;
    {
	struct { double a,b;} s;

	s.a = x;		/* construct structure from passed args */
	s.b = y;
	return(cabs(s));	/* return C library cabs/1 results */
    }
