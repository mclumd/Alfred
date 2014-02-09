/* SCCS   : @(#)unixraw.c	75.1 06/28/95
   File   : unixraw.c
   Author : Richard A. O'Keefe & Chung-ping Lan
   Purpose: Source code for unix binary stream

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdio.h>
#if WIN32
#include <io.h>
#else
#include <unistd.h>
#endif
#include <fcntl.h>
#include <errno.h>

#include "quintus.h"

/*  The following three functions support Unix I/O on files with no
    breaking things into records.  This is the best case for us.
*/

#define	Min_Buffer_Size		4

struct RawStream
    {
	QP_stream qpinfo;
	int fd;
	size_t last_rdsize;
	unsigned char buffer[Min_Buffer_Size];
    };

#define CoerceRawStream(x) ((struct RawStream *)(x))

static int
raw_read(QP_stream *stream, unsigned char **bufptr, size_t *sizeptr)
    {
	int n;
	register struct RawStream *u = CoerceRawStream(stream);

	u->qpinfo.magic.byteno += u->last_rdsize;
	u->last_rdsize = 0;
	n = read(u->fd, (char*)u->buffer, (int)u->qpinfo.max_reclen);
	if (n > 0) {
	    *bufptr  = u->buffer;
	    *sizeptr = n;
	    u->last_rdsize = n;
	    return QP_FULL;
	} else if (n == 0) {
	    *sizeptr = 0;
	    return QP_EOF;
	} else {
	    u->qpinfo.errnum = errno;
	    return QP_ERROR;
	}
    }


static int
raw_write(QP_stream *stream, unsigned char **bufptr, size_t *size)
    {
	struct RawStream  *u = CoerceRawStream(stream);
	int 		  n, len=(int) *size;
	char	  	  *buf = (char *) *bufptr;

	while ((n = write(u->fd, buf, len)) > 0 && n < len) {
	    buf += n;
	    len -= n;
	}
	if (n >= 0) {
	    u->qpinfo.magic.byteno += *size;
	    *size = u->qpinfo.max_reclen;
	    return QP_SUCCESS;
	} else {
	    u->qpinfo.errnum = errno;
	    return QP_ERROR;
	}
    }

static int
raw_close(QP_stream *stream)
    {
	struct RawStream *u = CoerceRawStream(stream);
	int fd = u->fd;

	QP_free(stream);
	if (close(fd) < 0)
	    return QP_ERROR;
	return QP_SUCCESS;
    }

static int
raw_seek(QP_stream *stream, union QP_cookie *qpmagic, int whence,
	 unsigned char **bufptr, size_t *sizeptr)
    {
	struct RawStream *u = CoerceRawStream(stream);
	off_t	new_offset;

	switch (whence) {
	case QP_BEGINNING:
	    new_offset = lseek(u->fd, qpmagic->byteno, SEEK_SET);
	    break;
	case QP_CURRENT:
	    /* The curren location of file pointer is different from 
		what the user think it is due to buffering.
		The magic field will be brought upto date by the caller of
		this function, so just seek to that position first. */
	    if (lseek(u->fd, stream->magic.byteno, SEEK_SET) == -1) {
		stream->errnum = errno;
		return QP_ERROR;
	    }
	    new_offset = lseek(u->fd,  qpmagic->byteno, SEEK_CUR);
	    break;
	case QP_END:
	    new_offset = lseek(u->fd, qpmagic->byteno, SEEK_END);
	    break;
	default:
	    stream->errnum = QP_E_INVAL;
	    return QP_ERROR;
	}
	if (new_offset == -1) {	/* error in seeking */
	    stream->errnum = errno;
	    return QP_ERROR;
	}
	stream->magic.byteno = new_offset;
	*bufptr  = u->buffer;
	*sizeptr = (stream->mode == QP_READ) ? 0 : stream->max_reclen;
	u->last_rdsize = 0;
	return QP_SUCCESS;
     }

QP_stream *
QU_raw_open(register QP_stream *option, int *error_num, int fd)
    {
	struct	RawStream	*stream;

	if (option->seek_type == QP_SEEK_RECORD) {
	     *error_num = QP_E_SEEK_TYPE;
	    return QP_NULL_STREAM;
	}
	stream = (struct  RawStream *) QP_malloc(sizeof(*stream)
		 + ((option->max_reclen <= Min_Buffer_Size) ? 0
			: option->max_reclen - Min_Buffer_Size) );
	stream->qpinfo = *option;
	QP_prepare_stream(&stream->qpinfo, stream->buffer);
	stream->fd = fd;
	stream->last_rdsize = 0;
	stream->qpinfo.close = raw_close;
	if (option->seek_type != QP_SEEK_ERROR)
	    stream->qpinfo.seek  = raw_seek;
	if (option->mode != QP_READ)  {
	    stream->qpinfo.write = 
	    stream->qpinfo.flush = raw_write;
	} else
	    stream->qpinfo.read  = raw_read;
	return (QP_stream *) stream;
    }
