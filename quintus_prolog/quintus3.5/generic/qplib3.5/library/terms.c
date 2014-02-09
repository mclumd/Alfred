/*  File   : terms.c
    Author : Richard A. O'Keefe
    Updated: 3/1/94
    Purpose: pass terms between Prolog and C

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/
#include <stdio.h>
#include <stdlib.h>             /* [PM] 3.5 free() */
#include "terms.h"

#ifndef	lint
static	char SCCSid[] = "@(#)94/03/01 terms.c	71.1";
#endif/*lint*/

#if 0                           /* [PM] 3.5 rely on systems headers. This conflicts with Win32 type */
extern char *calloc();
#endif /* 0 */
static TermP p0, p;

/*  QTallo(Size) is told the number of cells that the term will
    occupy, and either allocates enough space for it (returning
    0) or complains that it can't (returning -1).  p and p0 are
    set either to the address of the new block or to NULL.
*/
int QTallo(Size)
    unsigned int Size;			/* number of cells to allocate */
    {
	p = NULL;			/* default value means failure */
	if (Size < 65536) p = (TermP)calloc(Size, sizeof *p);
	return (p0 = p) ? 0 : -1;	/* p0 stays put, p travels */
    }


/*  In all these operations, p travels, while p0 is left pointing
    to the beginning of the term.  QTaddr is called after the term
    has been copied into the C world, and returns the address of
    the copy.  As usual, 0 means success, -1 means failure.
*/
int QTaddr(Address)
    TermP *Address;			/* points AFTER number of vars */
    {
	return (*Address = p0) ? 0 : -1;
    }


/*  QTfree(Address) deallocates the record.  Note that we can't call
    free() directly, for two reasons: the first is that we can only
    bind one Prolog predicate to any one C function (at the moment),
    and the second is that some translation of the address might be
    necessary (which is why I have been careful with casts in this
    file).  Better error checking should be done.
*/
void QTfree(Address)
    TermP Address;
    {
	Ignore free((char*)Address);
    }


void QTpshV(V)				/* push a variable number */
    int V;
    {
	*p++ = V;
    }


void QTpshF(F)				/* push a floating point number */
    float F;
    {
	*p++ = -2;
	*(float*)p++ = F;
    }


void QTpshI(I)				/* push an integer */
    int I;				/* (QTpshV pushes an integer code; */
    {					/* this pushes the integer "tag" -1 */
	*p++ = -1;			/* and then an integer value I) */
	*p++ = I;
    }


void QTpshA(A, N)			/* push a symbol/arity pair */
    QP_atom A;				/* atom code */
    int N;				/* arity >= 0 */
    {
	*p++ = N;			/* arity doubles as tag */
	*(QP_atom*)p++ = A;
    }


void QTinit(Address)			/* prepare to read a term */
    TermP Address;
    {
	p0 = p = Address;
    }


int QTnxtI()				/* return a tag or integer value */
    {
	return *p++;
    }


QP_atom QTnxtA()			/* return an atom code */
    {
	return *(QP_atom*)p++;
    }


float QTnxtF()
    {
	return *(float*)p++;
    }


/*  Forward Polish is quite a pretty representation, but it has the
    disadvantage that it can be quite tricky to maneuver around in
    it.
	skipterms(X, n)
    takes a pointer somewhere into the middle of a Polish term, and
    skips the first n (sub-)terms it finds there.  It returns a
    pointer to the next cell after the last (sub-)term skipped.
	skipterm(X)
    skips just one term.  The main point of this routine is to show
    you how to move around in Polish terms.
*/
TermP skipterms(X, n)
    register TermP X;			/* points to first term to skip */
    register int n;			/* number of terms to skip */
    {
	register int k;

	while (--n >= 0) {
	    k = *X++;			/* fetch & skip tag/arity */
	    if (k >= -2) {		/* not a variable */
		X++;			/* skip intval, floatval, or name */
		if (k > 0) n += k;	/* more to skip */
	    }
	}
	return X;
    }


TermP skipterm(X)
    TermP X;
    {
	return skipterms(X, 1);
    }


/*  termsvars(X, n, Min, Max)
    traverses the first n (sub-)terms starting at X, and returns in
    Min/Max the smallest/greatest variable number found; or -1 if
    no variables were found.  Note the step k = 3-k which converts
    a variable tag/code to a variable number such as numbervars/3
    might have assigned.  You can use this to test whether the n
    (sub-)terms at X are ground by checking for Min < 0.
    termvars(X, Min, Max)
    traverses a single term.  Both functions return an updated X value.
*/
TermP termsvars(X, n, Min, Max)
    register TermP X;			/* points to first term to check */
    register int n;			/* number of terms to check */
    int *Min;				/* smallest variable # (-1 if none) */
    int *Max;				/* greatest variable # (-1 if none) */
    {
	register int k;
	register int min, max;

	min = -1, max = -1;

	while (--n >= 0) {
	    k = *X++;			/* fetch & skip tag/arity */
	    if (k < -2) {		/* it is a variable */
		k = 3-k;		/* convert to variable number */
		if (k > max) max = k; else
		if ((unsigned)k < (unsigned)min) min = k;
	    } else {			/* not a variable */
		X++;			/* skip intval, floatval, or name */
		if (k > 0) n += k;	/* more terms to check */
	    }
	}
	*Min = min, *Max = max;
	return X;
    }


TermP termvars(X, Min, Max)
    TermP X;
    int *Min, *Max;
    {
	return termsvars(X, 1, Min, Max);
    }


/*  fprinterm(streamcode, X)
    writes the term represented by X onto the given stream.
    printerm(X)
    writes the term represented by X onto the current output stream.
    These are Prolog streams, see QP_fprintf() in the Manual.
    The output is very similar to display/1 or write_canonical/1;
    note that atoms are NEVER quoted.
*/
TermP fprinterm(stream, X)
    QP_stream *stream;
    register  TermP X;
    {
	if (IsCompound(X)) {
	    register int N = Arity(X);

	    Ignore QP_fprintf(stream, "%s(", String(X));
	    X += 2;
	    while (--N >= 0) {
		X = fprinterm(stream, X);
		QP_fputc((N == 0 ? ')' : ','), stream);
	    }
	} else
	if (IsVar(X)) {
	    Ignore QP_fprintf(stream, "_%d", VarNo(X));
	    X++;
	} else {
	    if (IsAtom(X)) {
		QP_fputs(String(X), stream);
	    } else
	    if (IsInteger(X)) {
		Ignore QP_fprintf(stream, "%d", IntegerVal(X));
	    } else {
		Ignore QP_fprintf(stream, "%#g", FloatVal(X));
	    }
	    X += 2;
	}
	return X;
    }


TermP printerm(X)
    TermP X;
    {
	return fprinterm(QP_curout, X);
    }
