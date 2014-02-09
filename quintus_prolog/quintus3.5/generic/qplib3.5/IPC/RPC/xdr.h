/*  File   : xdr.h
    Author : Richard A. O'Keefe.
    Updated: 02/03/89
    SCCS:    @(#)89/02/03 xdr.h	28.1
    Purpose: Header for the System V ersatz XDR package.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    The contents of this file were derived from the SUN "Remote Procedure
    Call" manual, particularly chapter 4 and chapter 3.  Most of the
    fields in an XDR handle here are dummies.
*/


#ifndef	__SYSVXDR__
#define __SYSVXDR__

#ifndef	SYS5
#include "rpc/rpc.h"
#else /*SYS5*/

#ifdef	sun
#define	HAS_XDR	1			/* This system has real XDR already */
					/* Edit makefile for other systems  */
#endif

#ifdef	HAS_XDR
#define xdr ydr
#define xdr_bool ydr_bool
#define xdr_bytes ydr_bytes
#define xdr_char ydr_char
#define xdr_double ydr_double
#define xdr_enum ydr_enum
#define xdr_float ydr_float
#define xdr_int ydr_int
#define xdr_long ydr_long
#define xdr_op ydr_op
#define xdr_opaque ydr_opaque
#define xdr_ops ydr_ops
#define xdr_short ydr_short
#define xdr_string ydr_string
#define xdr_test ydr_test
#define xdr_u_char ydr_u_char
#define xdr_u_int ydr_u_int
#define xdr_u_long ydr_u_long
#define xdr_u_short ydr_u_short
#define xdr_void ydr_void
#define xdra_t ydra_t
#define xdrstdio_create ydrstdio_create
#define xdru_t ydru_t
#endif

/*  Strictly speaking, the following #defines should be an
    'enum' declaration.  However, many System V C compilers forbid
	{enumvariable} < {enumconst} or
	switch ({enumvariable})
    which is both excessively odd and entirely incompatible with
    the October 1986 draft of the ANSI C standard.  Similar remarks
    apply to the 'state' variables elsewhere in this directory.
*/

#define xdro_t	   int			/* was 'enum xdr_op' */
#define XDR_ENCODE 0			/* sending data down the stream */
#define	XDR_DECODE 1			/* receiving data from a stream */
#define	XDR_FREE   2			/* freeing data allocated by XDR_DECODE */

#ifndef	bool_t
#define	bool_t int
#define enum_t int
#endif/*bool_t*/

typedef unsigned long xdru_t;		/* ulong in SYS5, u_long in 4.2 */
typedef	char* xdra_t;			/* caddr_t in 4.2 */

typedef bool_t (*xdrproc_t)();
#define	NULL_xdrproc_t ((xdrproc_t)0)

struct xdr_ops
    {
	bool_t	(*x_getlong)();		/* read a u_long from the stream */
	bool_t	(*x_putlong)();		/* write a u_long to the stream */
	bool_t	(*x_getbytes)();	/* read from the stream, like read(2) */
	bool_t	(*x_putbytes)();	/* write to the stream, like write(2) */
	xdru_t	(*x_getpostn)();	/* return stream offset, seek()ish */
	bool_t	(*x_setpostn)();	/* reposition stream, tell()ish */
	xdra_t	(*x_inline)();		/* always NULL */
	void	(*x_destroy)();		/* free private data of this stream */
    };

typedef struct
    {
	xdro_t		x_op;		/* What to do */
	struct xdr_ops* x_ops;		/* Methods */
	xdra_t		x_public;	/* User's data */
	xdra_t		x_private;	/* Private data */
	xdra_t		x_base;		/* Private, for position info */
	int		x_handy;	/* yet another private word */
    }	XDR;


/*  The following record type is for discriminated unions.
    See the XDR manual for details.
*/
struct xdr_discrim
    {
	enum_t		value;
	xdrproc_t	proc;
    };

/*  The x_ops are accessible through the following macros:
*/
#define xdr_getlong(xdrs, lp) \
	(*(xdrs)->x_ops->x_getlong)(xdrs, lp)
#define xdr_putlong(xdrs, lp) \
	(*(xdrs)->x_ops->x_putlong)(xdrs, lp)

#define xdr_getbytes(xdrs, buf, len) \
	(*(xdrs)->x_ops->x_getbytes)(xdrs, buf, len)
#define xdr_putbytes(xdrs, buf, len) \
	(*(xdrs)->x_ops->x_putbytes)(xdrs, buf, len)

#define xdr_getpos(xdrs) \
	(*(xdrs)->x_ops->x_getpos)(xdrs)
#define xdr_setpos(xdrs, pos) \
	(*(xdrs)->x_ops->x_setpos)(xdrs, pos)

#define xdr_inline(xdrs, len) \
	(*(xdrs)->x_ops->x_inline)(xdrs, len)
#define xdr_destroy(xdrs) \
	(*(xdrs)->x_ops->x_destroy)(xdrs)


/*  Functions to create an XDR stream  */

void xdrstdio_create(
	/* XDR *the_xdr_stream_which_is_created */
	/* FILE *the_stdio_stream_it_is_to_be_based_on */
	/* xdro_t what the xdr_stream is to do */
);

/*  xdrmem_create() and xdrrec_create()
    are not currently implemented
*/

/*  Basic transfer functions  */
extern bool_t	xdr_void();
extern bool_t   xdr_int();
extern bool_t   xdr_u_int();
extern bool_t   xdr_long();
extern bool_t   xdr_u_long();
extern bool_t   xdr_short();
extern bool_t   xdr_u_short();
extern bool_t   xdr_bool();
extern bool_t   xdr_enum();
extern bool_t   xdr_array();
extern bool_t   xdr_bytes();
extern bool_t   xdr_opaque();
extern bool_t   xdr_string();
extern bool_t   xdr_union();
extern bool_t   xdr_char();
extern bool_t   xdr_u_char();
extern bool_t   xdr_vector();
extern bool_t   xdr_float();
extern bool_t   xdr_double();
extern bool_t   xdr_reference();
extern bool_t   xdr_pointer();
extern bool_t   xdr_wrapstring();

#endif/*SYS5*/
#endif/*__SYSVXDR__*/

