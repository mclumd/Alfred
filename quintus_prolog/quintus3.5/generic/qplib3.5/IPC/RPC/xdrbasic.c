/*  File   : xdrbasic.c
    Author : Richard A. O'Keefe.
    Updated: 01/22/94
    Defines: The basic transfer functions.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    Note that this file is empty in
    4.xBSD systems, as they have sockets and XDR anyway.
*/

#ifdef	SYS5

#include <stdio.h>
#if 0                           /* [PM] 3.5 stdlib.h should suffice on all sane systems */
#include <malloc.h>
#endif /* 0 */
#include <stdlib.h>
#include "xdr.h"

#ifndef	lint
static	char SCCSid[] = "@(#)94/01/22 xdrbasic.c	71.1";
#endif/*lint*/

						/*ARGSUSED*/
bool_t xdr_void(xdrs)
    XDR *xdrs;
    {
	return 1;
    }


#define one_word_transfer(Name, Type) \
    bool_t Name(xdrs, arg) \
	XDR *xdrs; \
	Type *arg; \
	{ \
	    xdru_t local; \
	    switch (xdrs->x_op) { \
		case XDR_FREE: \
		    return 1; \
		case XDR_ENCODE: \
		    local = (xdru_t) *arg; \
		    return xdr_putlong(xdrs, &local); \
		case XDR_DECODE: \
		    if (xdr_getlong(xdrs, &local)) { \
			*arg = (Type)local; \
			return 1; \
		    } \
		default: \
		    return 0; \
	    } \
	}

#define n_word_transfer(Name, Type) \
    bool_t Name(xdrs, arg) \
	XDR *xdrs; \
	Type *arg; \
	{ \
	    switch (xdrs->x_op) { \
		case XDR_FREE: \
		    return 1; \
		case XDR_ENCODE: \
		    return xdr_putbytes(xdrs, arg, sizeof (Type)); \
		case XDR_DECODE: \
		    return xdr_getbytes(xdrs, arg, sizeof (Type)); \
		default: \
		    return 0; \
	    } \
	}

one_word_transfer(xdr_int, int)
one_word_transfer(xdr_u_int, unsigned int)
one_word_transfer(xdr_long, long)
one_word_transfer(xdr_u_long, unsigned long)
one_word_transfer(xdr_short, short)
one_word_transfer(xdr_u_short, unsigned short)
one_word_transfer(xdr_char, char)
one_word_transfer(xdr_u_char, unsigned char)
one_word_transfer(xdr_bool, bool_t)
one_word_transfer(xdr_enum, enum_t)

n_word_transfer(xdr_float, float)
n_word_transfer(xdr_double, double)

/*  strnlen(src, len)
    returns the number of characters up to the first NUL in src, or len,
    whichever is smaller.  This is the same as strnend(src,len)-src.
*/
static int strnlen(s, n)
    register char *s;
    register int n;
    {
	register int L;
	
	for (L = 0; --n >= 0 && *s++; L++) ;
	return L;
    }

bool_t xdr_string(xdrs, sp, maxlength)
    register XDR *xdrs;
    char **sp;
    xdru_t maxlength;
    {
	int L, r;

	switch (xdrs->x_op) {
	    case XDR_ENCODE:
		L = strnlen(*sp, maxlength);
		return xdr_putlong(xdrs, &L) && xdr_putbytes(xdrs, *sp, L);
	    case XDR_DECODE:
		if (!xdr_getlong(xdrs, &L)) return 0;
		if (L > maxlength) return 0;
		if (!*sp && !(*sp = malloc(L+1))) return 0;
		r = xdr_getbytes(xdrs, *sp, L);
		(*sp)[L] = '\0';	/* plant NUL byte */
		return r;
	    case XDR_FREE:
		if (*sp) free(*sp), *sp = (char*)0;
		return 1;
	    default:
		return 0;
	}
    }


bool_t xdr_bytes(xdrs, bpp, lp, maxlength)
    register XDR *xdrs;
    char **bpp;
    xdru_t *lp;
    xdru_t maxlength;
    {

	switch (xdrs->x_op) {
	    case XDR_ENCODE:
		return xdr_putlong(xdrs, lp) && xdr_putbytes(xdrs, *bpp, *lp);
	    case XDR_DECODE:
		if (!xdr_getlong(xdrs, lp)) return 0;
		if (*lp > maxlength) return 0;
		if (!*bpp && !(*bpp = malloc(*lp))) return 0;
		return xdr_getbytes(xdrs, *bpp, *lp);
	    case XDR_FREE:
		if (*bpp) free(*bpp), *bpp = (char*)0;
		return 1;
	    default:
		return 0;
	}
    }


bool_t xdr_opaque(xdrs, p, len)
    XDR *xdrs;
    char *p;
    xdru_t len;
    {
	switch (xdrs->x_op) {
	    case XDR_FREE:
		return 1;
	    case XDR_ENCODE:
		return xdr_putbytes(xdrs, p, len);
	    case XDR_DECODE:
		return xdr_getbytes(xdrs, p, len);
	    default:
		return 0;
	}
    }


#endif/*SYS5*/

