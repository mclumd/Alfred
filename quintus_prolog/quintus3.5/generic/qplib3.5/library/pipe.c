
/*  File   : pipe.c
    Author : Richard A. O'Keefe, Jim Crammond
    Updated: 06/15/94
    Purpose: Support for Prolog I/O from/to pipes.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdio.h>
#include <errno.h>
#include "quintus.h"
#include "malloc.h"

#ifndef	lint
static	char SCCSid[] = "@(#)94/06/15 pipe.c	73.1";
#endif/*lint*/

#ifdef WIN32
#define popen  _popen
#define pclose _pclose
#endif

typedef struct PipeStream
    {
	QP_stream	qpinfo;
	FILE		*pipe_stream;	/* stdio pipe stream */
	char		buffer[4];	/* one char buffer */
    } *PipeHandle;


static int p_read(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    char	**bufptr;
    size_t	*sizeptr;
    {
	register PipeHandle stream = (PipeHandle) qpstream;
	register int	c;

	if ((c = getc(stream->pipe_stream)) < 0)
	{	if (ferror(stream->pipe_stream))
		{	
		        qpstream->errnum = errno ? errno : QP_E_CANT_READ;
			return QP_ERROR;
		}
		return QP_EOF;
	}

	stream->buffer[0] = c;
	*bufptr = stream->buffer;
	*sizeptr = 1;
	return (c == '\n') ? QP_FULL : QP_PART;
    }

static int p_write(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    char	**bufptr;
    size_t	*sizeptr;
    {
	register PipeHandle stream = (PipeHandle) qpstream;

	if (*sizeptr == 1)
		if (putc(*bufptr[0], stream->pipe_stream) < 0)
		{	
			qpstream->errnum = (errno) ? errno : QP_E_CANT_WRITE;
			return QP_ERROR;
		}

	*bufptr = stream->buffer;
	*sizeptr = 0;
	return QP_SUCCESS;
    }

static int p_flush(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    char	**bufptr;
    size_t	*sizeptr;
    {
	register PipeHandle stream = (PipeHandle) qpstream;
	int ret;

	ret = p_write(qpstream, bufptr, sizeptr);
	fflush(stream->pipe_stream);
	return ret;
    }
       
static int p_close(qpstream)
    QP_stream	*qpstream;
    {
	register PipeHandle stream = (PipeHandle) qpstream;

	(void) pclose(stream->pipe_stream);
	Free(stream);
	return QP_SUCCESS;
    }


int QUpopen(Command, Direction, StreamCode)
    char	*Command;	/* the command to be executed via popen() */
    int		Direction;	/* 0 = read, 1 = write */
    QP_stream	**StreamCode;	/* the stream created here */
    {
	static int qpmode[] = {QP_READ, QP_WRITE};
#ifdef WIN32
	static char *pmode[] = {"rb", "wb"};
#else
	static char *pmode[] = {"r", "w"};
#endif
	PipeHandle stream;
	QP_stream *option;

	*StreamCode = QP_NULL_STREAM;

	stream = Malloc(PipeHandle, sizeof *stream);
	if (!stream)
		return ENOMEM;

	if ((stream->pipe_stream = popen(Command, pmode[Direction])) == NULL)
		return EPIPE;

	option = &stream->qpinfo;
	QU_stream_param("", qpmode[Direction], QP_DELIM_LF, option);

	if (Direction == 0)
	{	option->read = p_read;
		option->max_reclen = 1;
	}
	else
	{	option->write = p_write;
		option->flush = p_flush;
		option->max_reclen = 0;
		/* line buffered pipe */
		setvbuf(stream->pipe_stream, NULL, _IOLBF, 0);
	}
	option->close = p_close;
	option->seek_type = QP_SEEK_ERROR;

	/*  set Prolog system fields and register the stream  */
	QP_prepare_stream(&stream->qpinfo, (unsigned char *)stream->buffer);
	if (QP_register_stream(&stream->qpinfo) == QP_ERROR)
	{   (void) p_close(&stream->qpinfo);
	    return EMFILE;
	}

	*StreamCode = &stream->qpinfo;
	return 0;
    }

