/*  File   : @(#)socketio.c	75.1 05/15/95
    Author : Tom Howland
    Purpose: buffered Prolog streams connected to sockets

    Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

    This is IPC/TCP/socketio.c

*/

#include <errno.h>

#ifdef WIN32
#include <winsock.h>
#else  /* !WIN32 */
#include <sys/types.h>
#include <sys/socket.h>
#endif  /* !WIN32 */
#include "quintus.h"
#include "socketio.h"
#include "tcp.h"                /* [PM] 3.5+ tcp_errno */

#ifndef	lint
static char *SCCS_ID = "@(#)socketio.c	75.1 05/15/95 Copyright (C) 1990 Quintus";
#endif

/* 
  socket_read() is very similar to tty_read() in unixtty.c.
*/

static int socket_read(stream, bufptr, sizeptr)
    QP_stream		*stream;
    unsigned char	**bufptr;    
    long int		*sizeptr;
{
    register struct socket_input_stream *u = CoerceSocketInputStream(stream);
    register int n;
    /* [PM] 3.5 errno is often a macro these days: extern int errno; */

    if (QP_wait_input(u->fd, QP_NO_TIMEOUT) < 0) {
       u->qpinfo.errnum = tcp_errno();
       return QP_ERROR;
    }
    n = recv(u->fd, (char*)u->buffer, (int)u->qpinfo.max_reclen, 0);
    if (n > 0) {
	*bufptr  = u->buffer;
	*sizeptr = n;
	return QP_FULL;
    } else if (n == 0) {
	*sizeptr = 0;
	return QP_EOF;
    } else {
        u->qpinfo.errnum = tcp_errno();
	return QP_ERROR;
    }
}

static int
socket_write(stream, bufptr, sizeptr)
    QP_stream		*stream;
    unsigned char	**bufptr;
    long int		*sizeptr;
{
    struct socket_output_stream  *u = CoerceSocketOutputStream(stream);
    int n, len=(int) *sizeptr;
    char *buf = (char *) *bufptr;
    
    while ((n = send(u->fd, buf, len, 0)) > 0 && n < len) {
	buf += n;
	len -= n;
    }
    if (n >= 0) {
	*sizeptr = SocketBufferSize;
	*bufptr = u->buffer;
	return QP_SUCCESS;
    } else {
	/* disable flushing on close */
        stream->char_ptr = stream->buffer;

	/* indicate an error */
	u->qpinfo.errnum = tcp_errno();
	return QP_ERROR;
    }
}

static int socket_close(stream)
    QP_stream	*stream;
{
    QP_free(stream);
    return QP_SUCCESS;
}

int socket_io_open_input(fd, stream)
    int		fd;
    QP_stream	**stream;
{

    register struct socket_input_stream *u;
    register QP_stream *s;

    u = CoerceSocketInputStream(QP_malloc(sizeof(*u)));
    if (u == NULL)
	return -1;

    s = &(u->qpinfo);
    QU_stream_param("socket stream", QP_READ, QP_VAR_LEN, s);
    s->read = socket_read;
    s->line_border = -1;
    s->seek_type = QP_SEEK_ERROR;
    s->max_reclen = InputSocketBufferSize;
    s->close = socket_close;
    QP_prepare_stream(s, u->buffer);

    u->fd = fd;

    if(QP_register_stream(s) == QP_ERROR) {
	(void) socket_close(s);
	return -1;
    }

    *stream = s;

    return 0;
}

int socket_io_open_output(fd, stream)
    int		fd;
    QP_stream	**stream;
{

    register struct socket_output_stream *u;
    register QP_stream *s;

    u = CoerceSocketOutputStream(QP_malloc(sizeof(*u)));
    if (u == NULL)
	return -1;

    s = &(u->qpinfo);
    QU_stream_param("socket stream", QP_WRITE, QP_VAR_LEN, s);
    s->line_border = -1;
    s->write = s->flush = socket_write;
    s->seek_type = QP_SEEK_ERROR;
    s->max_reclen = SocketBufferSize;
    s->close = socket_close;
    QP_prepare_stream(s, u->buffer);

    u->fd = fd;

    if(QP_register_stream(s) == QP_ERROR) {
	(void) socket_close(s);
	return -1;
    }

    *stream = s;

    return 0;
}
