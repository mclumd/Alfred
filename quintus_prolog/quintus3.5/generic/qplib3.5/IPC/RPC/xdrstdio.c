/*  File   : xdrstdio.c
    Author : Richard A. O'Keefe.
    Updated: 11/01/88
    Defines: xdrstdio_create

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    Note that this file is empty for 4.xBSD systems, which already have
    XDR and sockets anyway.  The file name should have been
    xdrstdio_create.c, but we pander to old UNIXes with short names.
*/

#ifdef	SYS5

#include <stdio.h>
#include "xdr.h"

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/01 xdrstdio.c	27.1";
#endif/*lint*/


#define ROUND_UP(count) count = (count+3) &~ 3
    /*	It is part of the XDR standard that everything is a multiple
	of four bytes long.  This is therefore NOT machine-specific.
	The assumption that sizeof (long) == 4 in the next two
	functions IS machine-specific, but not so you'd notice.
    */

static bool_t stdio_getlong(xdrs, lp)
    XDR *xdrs;
    long *lp;
    {
	return fread(lp, sizeof *lp, 1, (FILE*)xdrs->x_private) == 1;
    }

static bool_t stdio_putlong(xdrs, lp)
    XDR *xdrs;
    long *lp;
    {
	return fwrite(lp, sizeof *lp, 1, (FILE*)xdrs->x_private) == 1;
    }

static bool_t stdio_getbytes(xdrs, buf, bytecount)
    XDR *xdrs;
    char *buf;
    xdru_t bytecount;
    {
	ROUND_UP(bytecount);
	return fread(buf, 1, bytecount, (FILE*)xdrs->x_private) == bytecount;
    }

static bool_t stdio_putbytes(xdrs, buf, bytecount)
    XDR *xdrs;
    char *buf;
    xdru_t bytecount;
    {
	ROUND_UP(bytecount);
	return fwrite(buf, 1, bytecount, (FILE*)xdrs->x_private) == bytecount;
    }

static xdru_t stdio_getpostn(xdrs)
    XDR *xdrs;
    {
	return ftell((FILE*)xdrs->x_private);
    }

static bool_t stdio_setpostn(xdrs, pos)
    XDR *xdrs;
    xdru_t pos;
    {
	return fseek((FILE*)xdrs->x_private, pos, 0);
    }

						/*ARGSUSED*/
static xdra_t stdio_inline(xdrs, bytecount)
    XDR *xdrs;
    xdru_t bytecount;
    {
	return (xdra_t)0;
    }

						/*ARGSUSED*/
static void stdio_destroy(xdrs)
    XDR *xdrs;
    {
	/* do nothing: the caller must close his hown stream */
    }


static struct xdr_ops stdio_ops =
    {
	stdio_getlong,
	stdio_putlong,
	stdio_getbytes,
	stdio_putbytes,
	stdio_getpostn,
	stdio_setpostn,
	stdio_inline,
	stdio_destroy
    };


void xdrstdio_create(xdrs, fp, x_op)
    register XDR *xdrs;
    FILE *fp;
    xdro_t x_op;
    {
	xdrs->x_op      = x_op;
	xdrs->x_ops     = &stdio_ops;
	xdrs->x_public  = (xdra_t)0;
	xdrs->x_private = (xdra_t)fp;
	xdrs->x_base    = (xdra_t)0;
	xdrs->x_handy   = 0;
    }

#endif/*SYS5*/

