/*  File   : library.d/random.c
    Author : Richard A. O'Keefe
    Updated: 12/10/98
    Purpose: C-coded half of the "random" procedures.

    Adapted from shared code written by the same author; all changes
    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This is an implementation of algorithm AS 183 from the journal
    "Applied Statistics", recoded in C. There is also a version in
    Prolog available to people who cannot use the Quintus Prolog
    foreign function interface.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)98/12/10 random.c	76.1";
#endif

static	int	A = 27134,
		B =  9213,
		C = 17773;
static	int	S = 0x19551011;


void QPRget(a, b, c, s)
    long *a, *b, *c, *s;
    {
	*a = A, *b = B, *c = C, *s = S;
    }


int QPRput(a, b, c, s)
    int a, b, c, s;
    {
	if ((unsigned)(a) >= 30269
	 || (unsigned)(b) >= 30307
	 || (unsigned)(c) >= 30323
	) return 0;
	A = a, B = b, C = c;
	S = s & 0x1FFFFFFF;	/* 29 bits */
	return 1;
    }


double QPRnxt()
    {
	double T = (A = (A*171) % 30269)/30269.0
		 + (B = (B*172) % 30307)/30307.0
		 + (C = (C*170) % 30323)/30323.0;
	return T-(int)T;
    }


int QPRmyb(P, N)
    int P, N;
    {
	double T = (A = (A*171) % 30269)/30269.0
		 + (B = (B*172) % 30307)/30307.0
		 + (C = (C*170) % 30323)/30323.0;
	return (unsigned)(P) > (unsigned)(N) ? 0 : ((int)(T*N))%N < P;
    }


int QPRbit()
    {
	register int r = S;

	r += r;
	if (r & (1<<30)) {
	    S = r^(1<<6 | 1<<2 | 1<<1 | 1);
	    return 1;
	} else {
	    S = r;
	    return 0;
	}
    }

