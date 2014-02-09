/* SCCS   : @(#)unixtext.c	75.1 06/28/95
   File   : unixtext.c
   Author : Richard A. O'Keefe & Chung-ping Lan
   Purpose: Source code for unix text stream

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdio.h>
#if WIN32
#include <io.h>
#else
#include <unistd.h>
#endif
#include <errno.h>

#include "quintus.h"

#define CoerceTextStream(x) ((struct TextStream *)(x))

#define Min_Buffer_Size		4

struct TextStream
    {
	QP_stream qpinfo;
	int fd;			 /* file descriptor */
	unsigned char *left_ptr; /* points to text not yet returned */
	size_t left_size;	 /* counts remaining characters */
	size_t last_size;	 /* size of last record */
	unsigned char buffer[Min_Buffer_Size];
	/* There must be at least one character here for a sentinel */
    };


/*  Reading from a TextStream, we have
		       <-left_size->
	+-------------+------------+-------+
	|has been read| to be read |empty  |
	+-------------+------------+-------+
		      ^ left_ptr
    If there is no remaining text to be read, we have to read another
    block from the disc.  Otherwise, there are two cases:  the end of
    the record is inside the block (return QP_FULL) or it is not
    (return QP_PART).  In IBM jargon, this is a LOCATE mode read,
    because we do not move the contents of the buffer anywhere else.
*/

static int
text_read(stream, bufptr, sizeptr)
    QP_stream		*stream;
    unsigned char	**bufptr;    
    size_t		*sizeptr;
    {
	register struct TextStream *u = CoerceTextStream(stream);
	register unsigned char *s;
	register int n;

	s = u->left_ptr;
	n = u->left_size;
	u->qpinfo.magic.byteno += u->last_size;
	u->last_size = 0;
	if (n == 0) {
	    n = read(u->fd, (char*)u->buffer, (int)u->qpinfo.max_reclen);
	    if (n > 0) {
		s = u->buffer;
		u->left_ptr  = s;		
		u->left_size = n;
		s[n] = '\n';	/* post the sentinel */
	    } else if (n == 0) {
		*sizeptr = 0;
		return QP_EOF;
	    } else {
		u->qpinfo.errnum = errno;
		return QP_ERROR;
	    }
	}
	*bufptr = s;
	while (*s++ != '\n') ;	/* stopped by the sentinel, if naught else */
	n = s-u->left_ptr;
	if (n > u->left_size) {
	    *sizeptr = u->last_size = u->left_size;
	    u->left_size = 0;
	    return QP_PART;
	} else {
	    *sizeptr = u->last_size = n;
	    u->left_size   -= n;
	    u->left_ptr     = s;
	    return QP_FULL;
	}
    }


/*  Writing to a TextStream, we have
			 <-- left_size -->
	+---------------+----------------+
	|has been filled|empty		 |
	+---------------+----------------+
			^ left_ptr

    What we want to do here is LOCATE mode writes.

    The last_size field is redundant for this procedure.
    It would be prettier if we eliminated them, but the cost is slight.
*/
static int
text_write(stream, bufptr, sizeptr)
    QP_stream		*stream;
    unsigned char	**bufptr;
    register size_t	*sizeptr;
    {
	register struct TextStream *u = CoerceTextStream(stream);

	/*  We do not have to do any copying because the output  */
	/*  has already been placed in the right buffer.  All we */
	/*  have to do is adjust the counters, and write out the */
	/*  current buffer if it is full.  */

	if (*sizeptr >= u->left_size) {	/* the buffer is now full */
	    register unsigned char	*p;
	    register int	n, len;
	   
	    p   = u->buffer;
	    len = u->qpinfo.max_reclen + (*sizeptr-u->left_size);
	    while ((n = write(u->fd, (char *)p, len)) > 0 && n < len) {
		p += n;
		len -= n;
	    }
	    if (n < 0) {
		u->qpinfo.errnum = errno;
		return QP_ERROR;
	    }
	    u->left_ptr  = u->buffer;
	    u->left_size = u->qpinfo.max_reclen;
	} else {
	    u->left_ptr  += *sizeptr;
	    u->left_size -= *sizeptr;
	}
	u->qpinfo.magic.byteno += *sizeptr;
	*bufptr  = u->left_ptr;
	*sizeptr = u->left_size;	/* maximum size left in buffer */
	return QP_SUCCESS;
    }

/* text_flush() is similar to text_write().
   text_flush() will actually write out the buffer regardless
   the buffer is full or not
*/
static int
text_flush(stream, bufptr, sizeptr)
    QP_stream		*stream;
    unsigned char	**bufptr;
    register size_t	*sizeptr;
    {
	register struct TextStream *u = CoerceTextStream(stream);
	register unsigned char	*p;
	register int	n, len;
	   
	p   = u->buffer;
	len = u->qpinfo.max_reclen - u->left_size + *sizeptr;;
	if (len > u->qpinfo.max_reclen)
	    len = *sizeptr = u->qpinfo.max_reclen;
	while ((n = write(u->fd, (char *)p, len)) > 0 && n < len) {
	    p += n;
	    len -= n;
	}
	if (n < 0) {
	    u->qpinfo.errnum = errno;
	    return QP_ERROR;
	}
	u->left_ptr  = u->buffer;
	u->left_size = u->qpinfo.max_reclen;
	u->qpinfo.magic.byteno += *sizeptr;
	*bufptr  = u->left_ptr;
	*sizeptr = u->left_size;	/* maximum size left in buffer */
	return QP_SUCCESS;
    }

static int
text_seek(stream, qpmagic, whence, bufptr, sizeptr)
     QP_stream		*stream;
     union QP_cookie	*qpmagic;
     int		whence;
     unsigned char	**bufptr;
     size_t		*sizeptr;
     {
	struct TextStream *u = CoerceTextStream(stream);
	off_t		offset;

	/* only needs to support for QP_FROM_TOP since TextStream only
		supports seeking type of QP_SEEK_PREVIOUS */
	switch (whence) {
	case QP_BEGINNING:
	    if ((offset = lseek(u->fd, qpmagic->byteno, SEEK_SET)) == -1) {
		stream->errnum = errno;
		return QP_ERROR;
	    }
	    stream->magic.byteno = offset;
	    *bufptr  = u->buffer;
	    *sizeptr = u->left_size =
			(stream->mode == QP_READ) ? 0 : stream->max_reclen;
	    u->left_ptr  = u->buffer;
	    u->last_size = 0;
	    return QP_SUCCESS;
	case QP_CURRENT:
	case QP_END:
	default:
	    stream->errnum = QP_E_INVAL;
	    return QP_ERROR;
	}
     }


static int
text_close(stream)
    QP_stream	*stream;
    {
	struct TextStream *u = CoerceTextStream(stream);
	int fd = u->fd;

	/* If the write function is changed or reassinged to some
	   other function, the close function should also
	   be changed accorndingly.
	*/
	if (u->qpinfo.write == text_write && u->left_ptr != u->buffer) {
	    int		  n;
	    unsigned char *p=u->buffer;
	    long	  len = u->left_ptr - p;
	    while ((n = write(u->fd, (char *)p, len)) > 0 && n < len) {
		p += n;
		len -= n;
	    }
	}
	QP_free(stream);
	if (close(fd) < 0)
	    return QP_ERROR;
	return QP_SUCCESS;
    }


QP_stream *
QU_text_open(option, error_num, fd)
    register	QP_stream	*option;
    int		*error_num, fd;
    {
	int	extra_size;
	struct	TextStream	*stream;

	if (option->seek_type == QP_SEEK_RECORD ||
		option->seek_type == QP_SEEK_BYTE) {
	    *error_num = QP_E_SEEK_TYPE;
	    return QP_NULL_STREAM;
	}
	/* Need one extra byte for text_read */
	if ((extra_size=option->max_reclen-(Min_Buffer_Size-1)) < 0)
	    extra_size = 0;
	stream = (struct TextStream *) QP_malloc(
			extra_size + sizeof(struct TextStream));
	stream->qpinfo = *option;
	QP_prepare_stream(&stream->qpinfo, stream->buffer);
	stream->fd = fd;
	stream->left_ptr  = stream->buffer;
	stream->left_size = (option->mode == QP_READ) ? 0
				: option->max_reclen;
	stream->last_size = 0;
	stream->qpinfo.close = text_close;
	if (option->seek_type != QP_SEEK_ERROR)
	    stream->qpinfo.seek  = text_seek;
	if (option->mode != QP_READ)  {
	    stream->qpinfo.write = text_write;
	    stream->qpinfo.flush = text_flush;
	} else
	    stream->qpinfo.read  = text_read;
	return (QP_stream *) stream;
    }
