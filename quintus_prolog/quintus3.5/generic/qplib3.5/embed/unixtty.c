/* SCCS   : @(#)unixtty.c	76.1 08/12/98
   File   : unixtty.c
   Author : Richard A. O'Keefe & Chung-ping Lan
   Purpose: Source code for unix tty stream

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <fcntl.h>
#include <errno.h>
#if WIN32
/* [PM] 3.5 FIXME: where is read() etc? */
#else  /* !WIN32 */
#include <unistd.h>             /* [PM] 3.5 read() etc */
#endif /* !WIN32 */

#include "quintus.h"

#define	Min_Buffer_Size		4

struct TtyStream
    {
	QP_stream qpinfo;
	int fd;
	unsigned char buffer[Min_Buffer_Size];
    };

#define CoerceTtyStream(x) ((struct TtyStream *)(x))

static int
tty_read(stream, bufptr, sizeptr)
    QP_stream		*stream;
    unsigned char	**bufptr;
    size_t		*sizeptr;
    {
	int n;
        /* [PM] 3.5 errno is often a macro these days: extern int errno; */
	register struct TtyStream *u = CoerceTtyStream(stream);

#if WIN32
	if (QU_pc_is_console(u->fd))
		n = QU_pc_console_read(u->fd, u->buffer, u->qpinfo.max_reclen);
	else
		n = read(u->fd, (char*)u->buffer, (int)u->qpinfo.max_reclen);
#else
	if (QP_wait_input(u->fd, QP_NO_TIMEOUT) < 0) {
	    u->qpinfo.errnum = errno;
	    return QP_ERROR;
	}
	n = read(u->fd, (char*)u->buffer, (int)u->qpinfo.max_reclen);
#endif
	if (n > 0) {
	    *bufptr  = u->buffer;
	    *sizeptr = n;
	    if (u->buffer[n-1] == '\n')
		return QP_FULL;
	    else
		return QP_PART;
	} else if (n == 0) {
	    *sizeptr = 0;
	    return QP_EOF;
	} else {
	    u->qpinfo.errnum = errno;
	    return QP_ERROR;
	}
    }


static int
tty_write(stream, bufptr, sizeptr)
    QP_stream		*stream;
    unsigned char	**bufptr;
    size_t		*sizeptr;
    {
	struct TtyStream  *u = CoerceTtyStream(stream);
	int		  n, len=(int) *sizeptr;
	char	  	  *buf = (char *) *bufptr;

	if (len==0) {	/* be sure to set *sizeptr and *bufptr */
	    *sizeptr = u->qpinfo.max_reclen;
	    *bufptr = u->buffer;
	    return QP_SUCCESS;
	}
	while ((n = write(u->fd, buf, len)) > 0 && n < len) {
	    buf += n;
	    len -= n;
	}
	if (n >= 0) {
	    *sizeptr = u->qpinfo.max_reclen;
	    *bufptr = u->buffer;
	    return QP_SUCCESS;
	} else {
	    u->qpinfo.errnum = errno;
	    return QP_ERROR;
	}
    }

static int
tty_close(stream)
    QP_stream	*stream;
    {
	struct TtyStream *u = CoerceTtyStream(stream);
	int fd = u->fd;

	QP_free(stream);
	if (close(fd) < 0)
	    return QP_ERROR;
	return QP_SUCCESS;
    }


QP_stream *
QU_tty_open(option, error_num, fd)
    register	QP_stream	*option;
    int		*error_num, fd;
    {
	struct	TtyStream	*stream;

	if (option->seek_type != QP_SEEK_ERROR) {
	    *error_num = QP_E_SEEK_TYPE;
	    return QP_NULL_STREAM;
	}
	stream = (struct  TtyStream *) QP_malloc(sizeof(*stream) +
		    ((option->max_reclen <= Min_Buffer_Size) ? 0 
			: option->max_reclen - Min_Buffer_Size) );
	stream->qpinfo = *option;
	QP_prepare_stream(&stream->qpinfo, stream->buffer);
	stream->fd = fd;
	stream->qpinfo.close = tty_close;
	if (option->mode != QP_READ)  {
	    stream->qpinfo.write = 
	    stream->qpinfo.flush = tty_write;
	} else
	    stream->qpinfo.read  = tty_read;
	return (QP_stream *) stream;
    }
