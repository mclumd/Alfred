/* SCCS   : @(#)unixparam.c	72.1 03/25/94
   File   : unixparam.c
   Author : Richard A. O'Keefe & Chung-ping Lan
   Purpose: Source code for io.c

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <fcntl.h>

#include "quintus.h"

#ifdef	DEBUG
#define	FILE_BUFFER_SIZE		16
#define	TTYS_BUFFER_SIZE		16
#else
#define	FILE_BUFFER_SIZE		8192
#define	TTYS_BUFFER_SIZE		256
#endif

/* [PM] 3.5 errno is often a macro these days: extern int errno; */

static int
bad_read(QP_stream *stream)
    {
	stream->errnum = QP_E_CANT_READ;
	return	QP_ERROR;
    }

static int
bad_write(QP_stream *stream)
    {
	stream->errnum = QP_E_CANT_WRITE;
	return	QP_ERROR;
    }

static int
bad_flush(QP_stream *stream)
    {
	stream->errnum = QP_E_CANT_FLUSH;
	return	QP_ERROR;
    }

static int
bad_seek(QP_stream *stream)
    {
	stream->errnum = QP_E_CANT_SEEK;
	return	QP_ERROR;
    }

static int
bad_close(QP_stream *stream)
    {
	stream->errnum = QP_E_CANT_CLOSE;
	return	QP_ERROR;
    }

static char *EmptyPrompt="";

void
QU_stream_param(char *filename, int mode, unsigned char format,
		QP_stream *option)
    {
	option->filename = filename;
	option->mode = mode;
	if ((option->format = format) == QP_DELIM_TTY) {
	    option->max_reclen = TTYS_BUFFER_SIZE;
	    option->seek_type  = QP_SEEK_ERROR;
	} else {
	    option->max_reclen = FILE_BUFFER_SIZE;
	    option->seek_type  = QP_SEEK_PREVIOUS;
	}
	option->line_border = QP_LF;
	option->file_border = QP_EOF;
	option->overflow = QP_OV_FLUSH;
	option->trim = 0;
	option->flush_type = QP_FLUSH_FLUSH;
	option->peof_act   = QP_PASTEOF_ERROR;
	option->errnum = 0;
	option->magic.byteno = 0;
	option->prompt = EmptyPrompt;
	option->read  =	bad_read;
	option->write = bad_write;
	option->close = bad_close;
	option->seek  = bad_seek;
	option->flush = bad_flush;
    }
