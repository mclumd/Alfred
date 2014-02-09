/*  File   : aropen.c
    Author : Richard A. O'Keefe
    Updated: 12/10/98
    Purpose: Reading members of UNIX archive files.
    SeeAlso: aropen.pl, man 5 ar, man 1 ar

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This file defines
	QARopen(+Archive, +Member, -Stream) -> Errno
    which is the guts of opening an archive member.  Basically,
    we open a UNIX stdio stream to the Archive file, and search
    it sequentially for the Member.  (This is the best we can do,
    given that UNIX ar(5) files were not designed to be searched
    rapidly.)  If we find the Member, we create a Prolog stream
    for it, and return its stream code.  If not, we return a
    suitable error code.

    For comparison, you might like to look at charsio.{c,pl}
    and crypt.{c,pl} which also open user-defined streams.

    Basically, a UNIX ar(5) file has the form

	<magic><member>*
    where
	<magic> = "!<ARCH>!\n"
    and a <member> has the form
	<header><contents><pad>
    where
	<header> is an ar_hdr record describing the member,
	<contents> is the characters comprising the member,
	<pad> is 0 or 1 linefeeds, padding <contents> to an
	even number of characters.

    Two of the errors we can report are not standard unix errors,
    but are listed in library(errno) just for this operation.
    They are
	ENOTARCH == 997	Archive is not a well formed ar(5) file
	ENOTMEMB == 998	Archive is ok, but Member isn't in it.

    In System V/386 there are *two* ar(5) formats, one identified as
    "PORTAR" and one identified as "PORT5AR".  Only the one identified
    as "PORTAR" is truly portable, and that is the one we want.  Note
    that most versions of UNIX do not have PORT5AR at all.
*/
#undef	PORT5AR
#define	PORTAR  1

#include <stdio.h>
#include <ar.h>
#include <errno.h>

#include "quintus.h"
#include "qerrno.h"
#include "malloc.h"

#ifdef AIX
/* RS6000 only has its own ar format... */
#define	SARMAG	SAIAMAG
#define	ARMAG	AIAMAG
#define	ARFMAG	AIAFMAG
#define	ar_fmag	_ar_name.ar_fmag
#define	ar_name	_ar_name.ar_name
#endif


#ifndef	lint
static	char SCCSid[] = "@(#)98/12/10 aropen.c	76.1";
#endif/*lint*/

extern int strncmp(/*char^,char^,int*/);
/* [PM] 3.5 errno is often a macro these days: extern int errno; */


typedef struct ArRecord
    {
	QP_stream qpinfo;
	int	counter;	/* bytes remaining in stream */
	FILE*	archive_stream;	/* stdio stream for whole file */
	char	buffer[4];	/* mini-buffer to return chars */
    }  *ArHandle;


static int ar_read(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    char	**bufptr;
    size_t	*sizeptr;
    {
	register ArHandle stream = (ArHandle) qpstream;
	register int	c;

	if (--stream->counter < 0) return QP_EOF;

	if ((c = getc(stream->archive_stream)) < 0)
	{	qpstream->errnum = (errno) ? errno : QP_E_CANT_READ;
		return QP_ERROR;
	}

	stream->buffer[0] = (char) c;
	*bufptr = stream->buffer;
	*sizeptr = 1;
	return (c == '\n') ? QP_FULL : QP_PART;
    }


static int ar_close(qpstream)
    QP_stream	*qpstream;
    {
	register ArHandle stream = (ArHandle) qpstream;

	(void)fclose(stream->archive_stream);
	Free(stream);
	return QP_SUCCESS;
    }


/*  strpadeql(str, pad, len) is true when the NUL-terminated
    string str and the blank-padded counted string pad FOR len
    are equal.
*/
static int strpadeql(str, pad, len)
    register char *str;
    register char *pad;
    register int len;
    {
	register int chr;

	while ((chr = *str++))
	    if (--len < 0 || *pad++ != chr)
	        return 0;
	while (--len >= 0)
	    if (*pad++ != ' ')
		return 0;
	return 1;
    }


/*  strntol(str, len) converts the counted string str FOR len to
    an integer; it ignores everything but digits on the assumption
    that the ignored characters are padding and decoration.
*/
static long int strntol(str, len)
    register char *str;
    register int len;
    {
	register int dig;
	register long int ans = 0;

	while (--len >= 0)
	    if ((unsigned)(dig = *str++ - '0') < 10)
		ans = ans*10 + dig;
	return ans;
    }


long QARopen(Archive, Member, StreamCode)
    char *Archive;
    char *Member;
    QP_stream  **StreamCode;
    {
	register ArHandle stream;
	register FILE *archive_stream;
	char magic[SARMAG];
	long len;
	struct ar_hdr header;
	QP_stream *option;

	*StreamCode = QP_NULL_STREAM;		/* not a valid stream code */
	archive_stream = fopen(Archive, "r");
	if (!archive_stream) return errno;
	if (fread(magic, 1, SARMAG, archive_stream) != SARMAG
	 || strncmp(magic, ARMAG, SARMAG)) {
	    (void)fclose(archive_stream);
	    return ENOTARCH;
	}
	for (;;) {
	    len = fread((char*)&header, 1, sizeof header, archive_stream);
	    if (len <= 0) {
		(void)fclose(archive_stream);
		return ENOTMEMB;
	    } else
	    if (len != sizeof header
	     || strncmp(header.ar_fmag, ARFMAG, sizeof header.ar_fmag)) {
		(void)fclose(archive_stream);
		return ENOTARCH;
	    }
	    len = strntol(header.ar_size, sizeof header.ar_size);
	    if (strpadeql(Member, header.ar_name, sizeof header.ar_name)) {
		stream = Malloc(ArHandle, sizeof *stream);
		if (!stream) {
		    (void)fclose(archive_stream);
		    return ENOMEM;
		}
		stream->counter = len;
		stream->archive_stream = archive_stream;
		/* we've opened Archive, found Member, allocated
		   and initialised an ArHandle to give Prolog.
		   Now we have to talk Prolog into accepting it.
		*/

		/*  get default stream options  */
		option = &stream->qpinfo;
		QU_stream_param(Archive, QP_READ, QP_DELIM_LF, option);

		/*  modify appropriate options  */
		option->max_reclen = 1;
		option->read = ar_read;
		option->close = ar_close;
		option->seek_type = QP_SEEK_ERROR;

		/*  set Prolog system fields and register the stream  */
		QP_prepare_stream(&stream->qpinfo,
					(unsigned char *)stream->buffer);
		if (QP_register_stream(&stream->qpinfo) == QP_ERROR) {
		   (void) ar_close(&stream->qpinfo);
		   return EMFILE;
		}

		*StreamCode = &stream->qpinfo;
		return 0;
	    }
	    /* This is not the member we're looking for.  Skip it. */
	    if (len&1) len++;
	    if (fseek(archive_stream, len, 1) < 0) {
		(void)fclose(archive_stream);
		return ENOTARCH;
	    }
	}
    }

