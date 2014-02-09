/* SCCS   : @(#)makestream.c	69.1 09/07/93
   File   : makestream.c
   Author : Richard A. O'Keefe & Chung-ping Lan
   Purpose: Source code for QP_make_stream()

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

/*----------------------------------------------------------------------+
|									|
|    int QP_make_stream(handle, <functions>, &stream)			|
|	makes an unbuffered stream which calls getp(handle) to read	|
|	a character, putp(c, handle) to write a character, and		|
|	closep(handle) to close the stream.  The other functions are	|
|	not called at the moment.  Given that the new transput stuff	|
|	is based on transferring complete records (whenever it can)	|
|	and this is based on transferring single characters, we have	|
|	to box clever.  In fact, we could do rather better than the	|
|	code here, except that I decided that we ought to preserve	|
|	the old behaviour of putp() being called precisely as soon	|
|	as a character was available for output, and getp() being	|
|	called only when an input character was demanded.  For input,	|
|	we say that the stream is a QP_DELIM_LF stream, and exploit the	|
|	fact that the ->read function need not deliver ALL of a 	|
|	record at once, but may report that it has delivered part of	|
|	it.  Two other choices are possible:				|
|	    format = QP_DELIM_CR, trim = 1, line_border = QP_CR		|
|	    format = QP_VAR_LEN,  trim = 0, line_border = QP_NOLB	|
|	For output, we specify zero-character records to indicate 	|
|	it's an unbuffered case.  Because there is only one "n_char" 	|
|	variable, mixing input and output on the same stream won't	|
|	work, although it would in the old system.  However, that	|
|	was never made clear , and mixed input and output doesn't	|
|	work for other streams nor was it used to.			|
|									|
+----------------------------------------------------------------------*/

#include <errno.h>

#include "quintus.h"

struct OldStream
    {
	QP_stream	qpinfo;
	char		*handle;	
	int (*getp)();
	int (*putp)();
	int (*flushp)();
	int (*eofp)();
	int (*clearp)();
	int (*closep)();
	unsigned char buffer[4];
    };

#define CoerceOldStream(stream) ((struct OldStream *)(stream))

				/*ARGSUSED*/
static int Old_failio(char *x)
    {
	return -1;
    }


				/*ARGSUSED*/
static int Old_putfail(int c, char *x)
    {
	return -1;
    }


static int Old_read(QP_stream *Stream, unsigned char **p, long int *l)
    {
	int c;
	register struct OldStream *o = CoerceOldStream(Stream);

	c = (o->getp)(o->handle);
	if (c < 0)
	    return QP_EOF;
	o->buffer[0] = c;
	*p = o->buffer;
	*l = 1;
	return c == o->qpinfo.line_border ? QP_FULL : QP_PART;
    }


static int Old_write(QP_stream *Stream, unsigned char **p, long int *l)
    {
	register struct OldStream *o = CoerceOldStream(Stream);
	register unsigned char *bp = *p;
	register long	n = *l;

	while (--n >= 0)
	    if ((o->putp)(*bp++, o->handle) < 0)
		return QP_ERROR;
	*p = o->buffer;
	*l = 0;
	return QP_OK;
    }
	

static int Old_force(QP_stream *Stream, unsigned char **p, long int *l)
    {
	register struct OldStream *o = CoerceOldStream(Stream);
	
	if (Old_write(Stream, p, l) == QP_ERROR)
	    return QP_ERROR;
	if ( (o->flushp)(o->handle) < 0)
	    return QP_ERROR;
	return QP_OK;
    }


static int Old_close(QP_stream *Stream)
    {
	register struct OldStream *o = CoerceOldStream(Stream);
	
	if ( (o->closep)(o->handle) < 0)
	    return QP_ERROR;
	(void) QP_free((char *) o);
	return QP_OK;
    }


int QP_make_stream(char *handle, int (*getp) (/* ??? */),
		   int (*putp) (/* ??? */), int (*flushp) (/* ??? */),
		   int (*eofp) (/* ??? */), int (*clearp) (/* ??? */),
		   int (*closep) (/* ??? */), QP_stream **stream)
    {
	register struct OldStream *o;

	if (!(getp) && !(putp))
	    return 0;
	o = (struct OldStream *) QP_malloc(sizeof *o);
	if (!o) { errno = ENOMEM; return 0; }
	QU_stream_param("", (getp) ? QP_READ : QP_WRITE, QP_DELIM_LF,
					&o->qpinfo);
	o->handle = handle;
	o->getp = getp ? getp : Old_failio;
	o->putp = putp ? putp : Old_putfail;
	o->flushp = flushp ? flushp : Old_failio;
	o->eofp = eofp ? eofp : Old_failio;
	o->clearp = clearp ? clearp : Old_failio;
	o->closep = closep ? closep : Old_failio;
	o->qpinfo.buffer = o->buffer;
	o->qpinfo.max_reclen = (getp) ? 1 : 0;
	/* make sure the stream will simulate old i/o stream */
	o->qpinfo.line_border = QP_LF;
	o->qpinfo.file_border = -1;
	o->qpinfo.overflow   =  QP_OV_FLUSH;
	o->qpinfo.seek_type  = QP_SEEK_ERROR;
	o->qpinfo.flush_type = QP_FLUSH_FLUSH;
	QP_prepare_stream(&o->qpinfo, o->buffer);
	o->qpinfo.read = Old_read;
	o->qpinfo.write = Old_write;
	o->qpinfo.flush = Old_force;
	o->qpinfo.close = Old_close;
	*stream = &o->qpinfo;
	if (QP_register_stream(*stream) == QP_ERROR) {
	    (void) o->qpinfo.close(&o->qpinfo);
	    return 0;
	}
	return 1;
    }

