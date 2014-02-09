/*
    File   : rpc.h
    Author : mark spotswood
    Updated: 01/15/88
    SCCS   : @(#)rpc.h	71.1  22 Jan 1994
    Purpose: definitions needed for remote procedure call functions.




*/
#ifndef __RPC_HEADER__
#define __RPC_HEADER__

/* ----------------------------------------------------------------------
   The following definitions  are a subset of the rpc include files used
   in SunOS 3.2.
   Copyright (C) 1984, Sun Microsystems, Inc.
   ---------------------------------------------------------------------- */

#ifndef __TYPES_RPC_HEADER__
#define __TYPES_RPC_HEADER__

#define bool_t  int
#define enum_t  int
#define FALSE   (0)
#define TRUE    (1)
#define __dontcare__    -1
#ifndef NULL
#       define NULL 0
#endif

#define mem_alloc(bsize)        malloc(bsize)
#define mem_free(ptr, bsize)    free(ptr)
#include <sys/types.h>

#endif !__TYPES_RPC_HEADER__

#include <netinet/in.h>

#ifndef __XDR_HEADER__
#define __XDR_HEADER__

enum xdr_op {
	XDR_ENCODE=0,
	XDR_DECODE=1,
	XDR_FREE=2
};

typedef	bool_t (*xdrproc_t)();

typedef struct {
	enum xdr_op	x_op;		/* operation; fast additional param */
	struct xdr_Aops {
		bool_t	(*x_getlong)();	/* get a long from underlying stream */
		bool_t	(*x_putlong)();	/* put a long to " */
		bool_t	(*x_getbytes)();/* get some bytes from " */
		bool_t	(*x_putbytes)();/* put some bytes to " */
		u_int	(*x_getpostn)();/* returns bytes off from beginning */
		bool_t  (*x_setpostn)();/* lets you reposition the stream */
		long *	(*x_inline)();	/* buf quick ptr to buffered data */
		void	(*x_destroy)();	/* free privates of this xdr_stream */
	} *x_ops;
	caddr_t 	x_public;	/* users' data */
	caddr_t		x_private;	/* pointer to private data */
	caddr_t 	x_base;		/* private used for position info */
	int		x_handy;	/* extra private word */
} XDR;

#define XDR_GETLONG(xdrs, longp)			\
	(*(xdrs)->x_ops->x_getlong)(xdrs, longp)
#define xdr_getlong(xdrs, longp)			\
	(*(xdrs)->x_ops->x_getlong)(xdrs, longp)

#define XDR_PUTLONG(xdrs, longp)			\
	(*(xdrs)->x_ops->x_putlong)(xdrs, longp)
#define xdr_putlong(xdrs, longp)			\
	(*(xdrs)->x_ops->x_putlong)(xdrs, longp)

#define XDR_GETBYTES(xdrs, addr, len)			\
	(*(xdrs)->x_ops->x_getbytes)(xdrs, addr, len)
#define xdr_getbytes(xdrs, addr, len)			\
	(*(xdrs)->x_ops->x_getbytes)(xdrs, addr, len)

#define XDR_PUTBYTES(xdrs, addr, len)			\
	(*(xdrs)->x_ops->x_putbytes)(xdrs, addr, len)
#define xdr_putbytes(xdrs, addr, len)			\
	(*(xdrs)->x_ops->x_putbytes)(xdrs, addr, len)

#define XDR_GETPOS(xdrs)				\
	(*(xdrs)->x_ops->x_getpostn)(xdrs)
#define xdr_getpos(xdrs)				\
	(*(xdrs)->x_ops->x_getpostn)(xdrs)

#define XDR_SETPOS(xdrs, pos)				\
	(*(xdrs)->x_ops->x_setpostn)(xdrs, pos)
#define xdr_setpos(xdrs, pos)				\
	(*(xdrs)->x_ops->x_setpostn)(xdrs, pos)

#define	XDR_INLINE(xdrs, len)				\
	(*(xdrs)->x_ops->x_inline)(xdrs, len)
#define	xdr_inline(xdrs, len)				\
	(*(xdrs)->x_ops->x_inline)(xdrs, len)

#define	XDR_DESTROY(xdrs)				\
	if ((xdrs)->x_ops->x_destroy) 			\
		(*(xdrs)->x_ops->x_destroy)(xdrs)
#define	xdr_destroy(xdrs)				\
	if ((xdrs)->x_ops->x_destroy) 			\
		(*(xdrs)->x_ops->x_destroy)(xdrs)

#endif !__XDR_HEADER__

#endif !__RPC_HEADER__


