/*  File   : charsio.c
    Author : Fernando C. N. Pereira (, Jim Crammond)
    Updated: 12/10/98
    Purpose: Support for Prolog streams with I/O to character lists.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdio.h>
#include <errno.h>
#include "quintus.h"
#include "malloc.h"

#define TRUE	1
#define FALSE	0

#define DEF_BS_SIZE	128	/* default size of output byte stream data */

#ifndef	lint
static	char SCCSid[] = "@(#)98/12/10 charsio.c	76.1";
#endif/*lint*/


typedef unsigned char byte;	/* if we put(210) we don't expect -46 back! */

/* Structure that keeps track of the position and size of a byte stream */
/* The sizes are (unsigned) because that is what the C library routines */
/* want (just ask Lint if you don't believe me).			*/

typedef struct byte_stream
    {
	QP_stream qpinfo;
	unsigned size;		/* size of stream data vector */
	unsigned left;		/* number of characters left */
	int exhausted;		/* no more data */
	byte *data;		/* stream data */
	byte *curr;		/* current character pointer */
    } *Byte_stream;


/* Allocate a byte vector of given size */

byte *new_byte_vector(size, dotp)
    long size;		/* number of bytes */
    long dotp;		/* 3 if " . " to be appended */
    {
	byte *vector = Malloc(byte *,size+dotp);

	if (vector && dotp) {
	    vector[size+0] = ' ';
	    vector[size+1] = '.';
	    vector[size+2] = ' ';
	}
	return vector;
    }


/* Free a byte vector */

void free_byte_vector(vector)
    byte *vector;
    {
	QP_free(vector);
    }


/* Store byte and increment byte pointer */

byte *store_byte(chr, ptr)
    long chr;		/* int, not byte, as Prolog passes +integer */
    byte *ptr;
    {
	*ptr++ = chr;
	return ptr;
    }


/* Fetch byte and increment byte pointer */

byte *fetch_byte(chrp, ptr)
    long *chrp;		/* int, not byte, as Prolog passes -integer */
    byte *ptr;
    {
	*chrp = *ptr++;
	return ptr;
    }


/* Return current data of a byte stream */

long byte_stream_contents(bs, vecp)
    Byte_stream bs;
    byte **vecp;
    {
	*vecp = bs->data;		/* current stream data */
	return bs->size - bs->left;	/* how much is valid data */
    }    


/* Actually free the space used by a byte stream.
   Use only for input byte streams and for output byte streams
   which have been closed and whose contents have been extracted.
*/

void free_byte_stream(bs)
    register Byte_stream bs;
    {
	if ((!bs) || (!bs->exhausted)) return;	/* precaution */
	if (bs->data) {			/* if data vector still allocated */
	    QP_free(bs->data);		/* free it */
	    bs->data = NULL;
	}
	QP_free((byte *)bs);		/* free byte stream handle */
    }


/* Get characters from a byte stream */

static int bs_read(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    byte	**bufptr;
    size_t	*sizeptr;
    {
	Byte_stream bs = (Byte_stream) qpstream;
	register byte *p, *q;
	int	ret, len = qpstream->max_reclen;

	if (bs->exhausted)		/* at end of data */
	{   *sizeptr = 0;
	    return QP_EOF;
	}

	if (bs->left < len) len = bs->left;


	/*  make next line of data available.
	 *  p starts at current position and scans chars until a newline is
	 *  found or end of buffer, q, is reached. p then points to the next
	 *  current position.
	 */
	p = bs->curr;
	q = p + len;
	ret = QP_PART;
	while (p < q)
	{	if (*p++ == '\n')
		{	ret = QP_FULL;
			break;
		}
	}

	*bufptr = bs->curr;		/* set bufptr to start of data */
	*sizeptr = p - bs->curr;	/* set sizeptr to length of data */
	bs->curr = p;
	bs->left -= *sizeptr;

	if (bs->left == 0)
	    	bs->exhausted = TRUE;	/* none left - mark stream finished */

	return ret;
    }



/* Put characters on a byte stream */

static int bs_write(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    byte	**bufptr;
    size_t	*sizeptr;
    {
	Byte_stream bs = (Byte_stream) qpstream;
#if 0                           /* [PM] 3.5 unused */
	char	*buf = (char *) *bufptr;
#endif /* unused */
	register byte *p = bs->data;
	register int n = *sizeptr;

	/*  a buffer (byte stream) is provided in advance for the higher
	 *  level o/p functions to write into. Here, we just ensure there
	 *  is space for more. If not, a new larger buffer is allocated and
	 *  data copied from the old one.
	 */

	/* move pointers to end of new data */
	p = bs->curr;
	bs->curr += n;
	bs->left -= n;

	while (bs->left == 0) {
	    register byte *q;

	    /*  allocate new buffer  */
	    n = bs->size;
	    q = Malloc(byte *,2*n);
	    if (!q) {			/* No space available */
		bs->exhausted = TRUE;
		qpstream->errnum = ENOMEM;
		return QP_ERROR;	/* fail */
	    }

	    p = bs->data;
	    while (n) *q++ = *p++, n--;	/* copy the old data */
	    QP_free(bs->data);		/* free the old data */

	    n = bs->size;
	    p = q - n;
	    bs->data = p;		/* the new data vector */
	    bs->curr = q;		/* point to first new byte */
	    bs->size += n;		/* the new data vector size */
	    bs->left = n;		/* how much new space */
	}

	*bufptr = bs->curr;
	*sizeptr = bs->left;
	return QP_SUCCESS;
    }



/* Close an input byte stream.
   Stream data and our stream handle are freed because neither
   Quintus Prolog I/O nor our code will be able to refer to them anyway.
*/

static int bs_iclose(qpstream)
    QP_stream *qpstream;
    {
	Byte_stream bs = (Byte_stream) qpstream;

	bs->exhausted = TRUE;		/* otherwise it won't really go */
	free_byte_stream(bs);		/* deallocate data block&header */
	return QP_SUCCESS;
    }


/* Close output byte stream.
   Just mark it as exhausted, but do not free its space because
   byte_stream_contents will want to get the output data for higher-level code. 
   The stream handle and the data vector will have to be freed explicitly
   by calling free_byte_stream.
*/

static int bs_oclose(qpstream)
    QP_stream *qpstream;
    {
	Byte_stream bs = (Byte_stream) qpstream;

	bs->exhausted = TRUE;
	return QP_SUCCESS;
    }


/* Make a Quintus Prolog stream that reads its characters
   from a byte vector of given size.  Return success/failure.
*/

long stream_from_byte_vector(vector, size, streamp)
    byte *vector;
    long size;
    QP_stream **streamp;
    {
	register Byte_stream handle;	/* byte stream handle */
	QP_stream *option;

	handle = Malloc(Byte_stream, sizeof *handle);
	if (!handle) return ENOMEM;	/* failed to allocate stream info */

	/* fill the stream structure */
	handle->size = handle->left = size;
	handle->data = handle->curr = vector;
	handle->exhausted = FALSE;

	/* get default stream options */
	option = &handle->qpinfo;
	QU_stream_param("", QP_READ, QP_DELIM_LF, option);

	option->max_reclen = DEF_BS_SIZE;
	option->read = bs_read;
	option->close = bs_iclose;
	option->seek_type = QP_SEEK_ERROR;

	/* set Prolog system fields and register the stream */
	QP_prepare_stream(&handle->qpinfo, handle->data);
	if (QP_register_stream(&handle->qpinfo) == QP_ERROR) {
	   (void) bs_oclose(&handle->qpinfo);
	   return EMFILE;
	}

	*streamp = &handle->qpinfo;
	return 0;
    }


/* Make a Quintus Prolog stream that writes its characters
   to a byte vector pointed to by a handle block (handlep).
*/

long stream_to_byte_vector(handlep, streamp)
    Byte_stream *handlep;
    QP_stream **streamp;
    {
	register Byte_stream handle;	/* byte stream handle */
	byte *vector;
	QP_stream *option;

	*streamp = QP_NULL_STREAM;

	vector = Malloc(byte *, DEF_BS_SIZE); /* initial stream data */
	if (!vector) return ENOMEM;	/* failed to allocate initial data */

	handle = Malloc(Byte_stream, sizeof *handle);
	if (!handle) {			/* failed to allocate stream handle */
	    QP_free(vector);		/* free useless initial data */
	    return ENOMEM;		/* fail */
	}

	/* fill the stream structure */
	handle->size = handle->left = DEF_BS_SIZE;
	handle->data = handle->curr = vector;
	handle->exhausted = FALSE;
	*handlep = handle;

	/* get default stream options */
	option = &handle->qpinfo;
	QU_stream_param("", QP_WRITE, QP_DELIM_LF, option);

	option->max_reclen = DEF_BS_SIZE;
	option->write = bs_write;
	option->flush = bs_write;
	option->close = bs_oclose;
	option->seek_type = QP_SEEK_ERROR;

	/* set Prolog system fields and register the stream */
	QP_prepare_stream(&handle->qpinfo, handle->data);
	if (QP_register_stream(&handle->qpinfo) == QP_ERROR) {
	   (void) bs_oclose(&handle->qpinfo);
	   return EMFILE;
	}

	*streamp = &handle->qpinfo;
	return 0;
    }
