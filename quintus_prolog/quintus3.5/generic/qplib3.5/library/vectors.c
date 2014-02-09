/*  File   : vector.c
    Author : Richard A. O'Keefe
    Updated: 04/20/99
    Purpose: support for library(vector)

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/

/*  We currently support four kinds of vectors:
	CVECT : character vectors (char*)
	IVECT : integer vectors (long*)
	SVECT : single-precision floating-point vectors (float*)
	DVECT : double-precision floating-point vectors (double*)
    A vector has four parts:
	- a fill pointer
	- a type code
	- a size (number of elements)
	- a body
    The layout has been cunningly hacked so that a character vector
    looks exactly like the kind of character vector you get from
    QP_string_from_atom, so character vectors built this way can
    be given directly to the routines in strings.c, for example.
    Unfortunately, this means that no vector can have more than
    65,535 elements.  Does this restriction really matter?
    The layout also ensures that -- provided QPvectors are allocated
    on "double" boundaries -- the elements of the body will be
    properly aligned.  That is why it matters that the header should
    be a multiple of 8 bytes long.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)99/04/20 vectors.c	76.1";
#endif/*lint*/

#include "malloc.h"
#include "quintus.h"            /* [PM] 3.5 QP_malloc */

#define	CVECT 0
#define IVECT 1
#define SVECT 2
#define DVECT 3

static unsigned type_size[] =
    {
	sizeof (char),	/* CVECT */
	sizeof (long),	/* IVECT */
	sizeof (float),	/* SVECT */
	sizeof (double)	/* DVECT */
    };

typedef struct
    {
	union {
	    char*	cptr;
	    long*	iptr;
	    float*	fptr;
	    double*	dptr;
	} fill_pointer;
	unsigned short	type_code;
	unsigned short	number_of_elements;
	union {
	    char	cvec[sizeof (double)/sizeof (char)];
	    long	ivec[sizeof (double)/sizeof (long)];
	    float	fvec[sizeof (double)/sizeof (float)];
	    double	dvec[sizeof (double)/sizeof (double)];
	} vector_body;
    } QPvector;

typedef char* POINTER;
#define Null (POINTER)0

/*  The following macros convert between a QPvector pointer and
    a pointer of the appropriate type.
*/

#define	Cvecptr(vec) (vec->vector_body.cvec)
#define Ivecptr(vec) (vec->vector_body.ivec)
#define Svecptr(vec) (vec->vector_body.fvec)
#define Dvecptr(vec) (vec->vector_body.dvec)

#define QPvecsiz (sizeof (QPvector) - sizeof (double))

/*  It is the caller's responsibility to ensure that Xptrvec()
    is only applied to objects returned by QVmake(), which will
    be properly aligned.  So we muzzle Lint.  When C compilers
    support the ANSI C (void*) construct, pointer casting will
    be easy.  For now, Lint does NOT like it when we case the
    result of malloc to some other type, so...
*/
#ifdef	lint
static QPvector dummy_vector_header;
	/*ARGSUSED*/
static QPvector *Xptrvec(p) POINTER p; {return &dummy_vector_header;}
#else /*real*/
#define Xptrvec(ptr) ((QPvector*)((POINTER)(ptr)-QPvecsiz))
#endif/*lint*/


POINTER QVmake(size, code)
    unsigned size;
    int code;
    {
	register QPvector* p;

	if (code < CVECT || code > DVECT) return Null;
	if (size >= 65536) return Null;
	p = Malloc(QPvector *, QPvecsiz + size*type_size[code]);
	if (!p) return Null;
	p->type_code = code;
	p->number_of_elements = size;
	switch (code) {
	    case CVECT: p->fill_pointer.cptr = Cvecptr(p); break;
	    case IVECT: p->fill_pointer.iptr = Ivecptr(p); break;
	    case SVECT: p->fill_pointer.fptr = Svecptr(p); break;
	    case DVECT: p->fill_pointer.dptr = Dvecptr(p); break;
	}
	return Cvecptr(p);
    }


int QVsize(ptr)
    register POINTER ptr;
    {
	if (ptr == Null) return -1;
	return Xptrvec(ptr)->number_of_elements;
    }


void QVrset(ptr)
    POINTER ptr;
    {
	register QPvector* p = Xptrvec(ptr);

	switch (p->type_code) {
	    case CVECT: p->fill_pointer.cptr = Cvecptr(p); break;
	    case IVECT: p->fill_pointer.iptr = Ivecptr(p); break;
	    case SVECT: p->fill_pointer.fptr = Svecptr(p); break;
	    case DVECT: p->fill_pointer.dptr = Dvecptr(p); break;
	}
    }


int QVIpsh(element, ptr)
    int element;
    POINTER ptr;
    {
	register QPvector* p;

	if (ptr == Null) return -1;
	p = Xptrvec(ptr);
	switch (p->type_code) {
	    case CVECT: *(p->fill_pointer.cptr)++ = element; break;
	    case IVECT: *(p->fill_pointer.iptr)++ = element; break;
	    case SVECT: *(p->fill_pointer.fptr)++ = element; break;
	    case DVECT: *(p->fill_pointer.dptr)++ = element; break;
	}
	return 0;
    }


int QVDpsh(element, ptr)
    double element;
    POINTER ptr;
    {
	register QPvector* p;

	if (ptr == Null) return -1;
	p = Xptrvec(ptr);
	switch (p->type_code) {
	    case CVECT: return -2;
	    case IVECT: return -2;
	    case SVECT: *(p->fill_pointer.fptr)++ = element; break;
	    case DVECT: *(p->fill_pointer.dptr)++ = element; break;
	}
	return 0;
    }


int QVnext(ptr, ival, fval)
    POINTER ptr;
    long  *ival;
    double *fval;
    {
	register QPvector* p;

	if (ptr == Null) return -1;
	p = Xptrvec(ptr);
	switch (p->type_code) {
	    case CVECT: *ival = *(p->fill_pointer.cptr)++;
			*fval = 0.0; break;
	    case IVECT: *ival = *(p->fill_pointer.iptr)++;
			*fval = 0.0; break;
	    case SVECT: *fval = *(p->fill_pointer.fptr)++;
			*ival = 0; break;
	    case DVECT: *fval = *(p->fill_pointer.dptr)++;
			*ival = 0; break;
	}
	return p->type_code;
    }


void QVkill(ptr)
    POINTER ptr;
    {
	Free(ptr-QPvecsiz);
    }


/*  QVIget(ptr, inx, &ival) is used to get an element of an integer vector.
     0 => ptr and inx are ok, ival has element
    -1 => ptr is not valid
    -2 => ptr points to a vector of the wrong type.
    -3 => inx is not valid
*/
int QVIget(ptr, inx, ival)
    POINTER ptr;
    int inx;
    long *ival;
    {
	register QPvector* p;

	if (ptr == Null) return -1;
	p = Xptrvec(ptr);
	if ((unsigned)(--inx) >= p->number_of_elements) return -3;
	switch (p->type_code) {
	    case CVECT: *ival = Cvecptr(p)[inx]; return 0;
	    case IVECT: *ival = Ivecptr(p)[inx]; return 0;
	    default:    return -2;
	}
    }


int QVFget(ptr, inx, fval)
    POINTER ptr;
    int inx;
    double *fval;
    {
	register QPvector* p;

	if (ptr == Null) return -1;
	p = Xptrvec(ptr);
	if ((unsigned)(--inx) >= p->number_of_elements) return -3;
	switch (p->type_code) {
	    case SVECT: *fval = Svecptr(p)[inx]; return 0;
	    case DVECT: *fval = Dvecptr(p)[inx]; return 0;
	    default:    return -2;
	}
    }


int QVIput(ptr, inx, ival)
    POINTER ptr;
    int inx;
    int ival;
    {
	register QPvector* p;

	if (ptr == Null) return -1;
	p = Xptrvec(ptr);
	if ((unsigned)(--inx) >= p->number_of_elements) return -3;
	switch (p->type_code) {
	    case CVECT: Cvecptr(p)[inx] = ival; return 0;
	    case IVECT: Ivecptr(p)[inx] = ival; return 0;
	    default:    return -2;
	}
    }


int QVFput(ptr, inx, fval)
    POINTER ptr;
    int inx;
    double fval;
    {
	register QPvector* p;

	if (ptr == Null) return -1;
	p = Xptrvec(ptr);
	if ((unsigned)(--inx) >= p->number_of_elements) return -3;
	switch (p->type_code) {
	    case SVECT: Svecptr(p)[inx] = fval; return 0;
	    case DVECT: Dvecptr(p)[inx] = fval; return 0;
	    default:    return -2;
	}
    }


int QVtype(ptr)
    POINTER ptr;
    {
	register QPvector* p;

	if (ptr == Null) return -1;
	p = Xptrvec(ptr);
	return p->type_code;
    }


