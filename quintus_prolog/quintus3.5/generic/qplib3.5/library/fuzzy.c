/*  File   : fuzzy.c
    Author : Richard A. O'Keefe
    Updated: 12/26/89
    Support: for library(fuzzy) -- Knuth-style fuzzy comparison

    This code is Copyright (C) 1989, Quintus Computer Systems, Inc.,
    but it may be used freely provided the copyight notice is preserved and
    Quintus is acknowledged.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)89/12/26 fuzzy.c	36.1";
#endif/*lint*/

#define	PRETTY_CLOSE	0
#define	VERY_CLOSE	1
#define	LESS_THAN	2
#define	GREATER_THAN	3

#ifdef	__STDC__
extern	double	frexp(double, int*);
extern	double	ldexp(double, int);
#else
extern	double	frexp();
extern	double	ldexp();
#endif

static double epsilon = 1.0e-5;

void QPSETFUZZ(x)
    double x;
    {
	epsilon = x;
    }

int QPFUZZCMP(U, V)
    double U, V;
    {
	double t;
	int e_u, e_v;

	if (U < 0.0 && V < 0.0) {
	    /* U and V are both negative.  We want them positive */
	    /* The order of U and V is the same as the order of -V and -U */
	    /* so we have to exchange them as well as change sign */ /* [PM] 3.5 <-- this comment
               was not terminated (the / was a '.') gobbling up the
               next few lines and returning prematurely */

	    t = -U, U = -V, V = t;
	} else
	if (U <= 0.0 || V <= 0.0) {
	    /* either U and V have opposite signs, */
	    /* or at least one of them is +/- 0.0  */
	    return U < V ? LESS_THAN : U > V ? GREATER_THAN : VERY_CLOSE;
	}

	/* now U and V are both strictly positive */
	/* we are likely to need both scale factors, so */
	(void)frexp(U, &e_u);	/* U = F*2**e_u where 0 < F < 1 */
	(void)frexp(V, &e_v);	/* V = G*2**e_v where 0 < G < 1 */

	if (U >= V) {
	    /* there are three possibilities: U :>:, :~:, or :=: V */
	    /* since U >= V, e_u >= e_v, so */
	    /* max(e_u, e_v) = e_u, min(e_u, e_v) = e_v */
	    /* Calculating U-V may underflow, but as long as underflow */
	    /* is flushed to 0, that's ok. */
	    t = U-V;
	    return t > ldexp(epsilon, e_u) ? GREATER_THAN
		 : t > ldexp(epsilon, e_v) ? PRETTY_CLOSE
		 :                           VERY_CLOSE;
	} else {
	    t = V-U;
	    return t > ldexp(epsilon, e_v) ? LESS_THAN
		 : t > ldexp(epsilon, e_u) ? PRETTY_CLOSE
		 :			     VERY_CLOSE;
	}
    }

