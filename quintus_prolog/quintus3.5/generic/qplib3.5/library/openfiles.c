/*  File   : openfile.c (formerly openfiles.c)
    Author : Richard A. O'Keefe, Jim Crammond
    Updated: 5/30/95
    Purpose: open a sequence of files for reading as one Prolog stream.
    SeeAlso: openfiles.pl

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/
#ifndef	lint
static	char SCCSid[] = "@(#)95/05/30 openfiles.c	75.1";
#endif/*lint*/

#include <stdio.h>
#include <sys/types.h>
#include <errno.h>
#include <sys/stat.h>
#include <fcntl.h>

#ifdef unix
#include <unistd.h>
#endif

#ifdef WIN32
#include <io.h>
#endif

#include "quintus.h"
#include "eaccess.h"
#include "malloc.h"

#ifndef R_OK
#define R_OK	4
#endif

typedef struct FIrec		/* File Information record */
    {
	char*	file_name;	/* the absolute name of the file */
	off_t	file_size;	/* the size of the file in bytes */
	time_t	file_date;	/* last modification time of file*/
    }   FIrec, *FIptr;


typedef struct MFrec		/* Multiple File record */
    {
	QP_stream qpinfo;
	int	fileid;		/* connected to current file */
	int	files_left;	/* number of unopened files */
	char	*chars_ptr;	/* position in buffer */
	int	chars_left;	/* number of chars in buffer */
	FIptr	next_file_info;	/* points to next file to open */
	char	buffer[BUFSIZ];	/* input buffer */
	FIrec	info[1];	/* dummy */
    }   MFrec, *MFptr;

static	char	NullFileName[] = "/dev/null";


static int mf_read(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    char	**bufptr;
    size_t	*sizeptr;
    {
	register MFptr handle = (MFptr) qpstream;
	struct	stat sbuf;
	char	*path=NULL;	/* [MC] 3.5 was used uninitialized */
	register char *p, *q;
	int	ret;

	/*  read more data into buffer  */
	if (handle->chars_left == 0)
	{   int n;

	    while ((n = read(handle->fileid, handle->buffer,
				sizeof(handle->buffer))) == 0)
	    {   (void) close(handle->fileid);
		if (handle->files_left == 0)
		    return QP_EOF;

		while (handle->files_left-- > 0)
		{   path = handle->next_file_info->file_name;
		    if ((handle->fileid = open(path, O_RDONLY, 0)) >= 0 &&
						    stat(path, &sbuf) == 0)
		        break;	/* got file */

		    QP_fprintf(QP_stderr,"! Lost file ignored: %s\n", path);
		    handle->next_file_info++;
	        }

                /* [PM] 3.5 FIXME: this uses uninited sbuf and path
                   and increments next_file_info too far unless the
                   while loop above exited at the explicit break
                   statement */

	        if ( sbuf.st_size != handle->next_file_info->file_size ||
		        sbuf.st_mtime != handle->next_file_info->file_date )
		    QP_fprintf(QP_stderr,"! Altered file accepted: %s\n", path);

		handle->next_file_info++;
	    }

	    if (n < 0)
	    {	
	        qpstream->errnum = errno ? errno : QP_E_CANT_READ;
	        return QP_ERROR;
	    }

	    handle->chars_ptr = handle->buffer;
	    handle->chars_left = n;
	}

	/*  make next line of data available  */
	p = handle->chars_ptr;
	q = p + handle->chars_left;
	ret = QP_PART;
	while (p < q)
	{   if (*p++ == '\n')		/*  found end of record  */
	    {	ret = QP_FULL;
		break;
	    }
	}

	*bufptr = handle->chars_ptr;
	*sizeptr = p - handle->chars_ptr;
	handle->chars_ptr = p;
	handle->chars_left = q - p;
	return ret;
    }


static int mf_close(qpstream)
    QP_stream *qpstream;
    {
	register MFptr handle = (MFptr) qpstream;

	(void) close(handle->fileid);
	Free(handle);
	return QP_SUCCESS;
    }



/*  QMFmake(N)
    allocates and partly initialises a Multiple File record capable of
    holding references to N files.  Note that if space runs out, it is
    possible for QMFmake to return NULL.
*/

MFptr QMFmake(N)
    int N;
    {
	register MFptr result =
	    Malloc(MFptr, sizeof (MFrec) + (N-1)*sizeof (FIrec));

	if (result)
	{   result->fileid = -1;
	    result->next_file_info = &(result->info[0]);
	    result->files_left = N;
	}
	return result;
    }

/*  QMFnext(path, handle)
    adds an entry to the info[] slot of a Multiple File record.  It
    assumes that there can be no overflow.  What is does check is
    that the file exists, is readable, and is not a directory.  If
    anything goes wrong, the MF record is freed and the error code
    is returned to 'pass file name', which prints an error message
    and fails.
*/

int QMFnext(path, handle)
    char *path;
    register MFptr handle;
    {
	struct stat sbuf;
	int result = 0;
	
	if (stat(path, &sbuf))
	    result = errno;
	else if (sbuf.st_mode & S_IFDIR)
	    result = EISDIR;
	else if (saccess(&sbuf, R_OK))
	    result = errno;
	else if (handle)
	{   register FIptr info = handle->next_file_info;

	    info->file_name = path;
	    info->file_size = sbuf.st_size;
	    info->file_date = sbuf.st_mtime;
	    handle->next_file_info++;
	}

	if (result && handle)
	    Free(handle);

	return result;
    }



/*  QMFopen(handle, &streamcode)
    is given a Multiple File record and tries to open it.  This involves
    opening a stream (which for uniformity is always set up reading
    from the null device).  If this goes wrong, the handle is freed and
    an error code returned.
*/

int QMFopen(handle, StreamCode)
    MFptr handle;
    QP_stream **StreamCode;
    {
	QP_stream *option;

	*StreamCode = QP_NULL_STREAM;
	if ((handle->fileid = open(NullFileName, O_RDONLY, 0)) < 0)
	{	Free(handle);
		return EMFILE;
	}
	handle->next_file_info = &(handle->info[0]);
	handle->chars_left = 0;

	/*  get default stream options  */
	option = &handle->qpinfo;
	QU_stream_param("", QP_READ, QP_DELIM_LF, option);

	/*  modify appropriate options  */
	option->max_reclen = sizeof(handle->buffer);
	option->read = mf_read;
	option->close = mf_close;
	option->seek_type = QP_SEEK_ERROR;

	/*  set Prolog system fields and register the stream  */
	if (QP_register_stream(&handle->qpinfo) == QP_ERROR)
	{	(void) mf_close(&handle->qpinfo);
		return EMFILE;
	}

	*StreamCode = &handle->qpinfo;
	return 0;
    }

