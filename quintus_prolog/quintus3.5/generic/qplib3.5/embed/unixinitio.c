/* SCCS   : @(#)unixinitio.c	72.1 03/21/94
   File   : unixinitio.c
   Author : Richard A. O'Keefe & Chung-ping Lan
   Purpose: Source code for QU_initio();

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#if WIN32
/* [PM] 3.5 FIXME: where is isatty */
#else  /* !WIN32 */
#include <unistd.h>             /* [PM] 3.5 isatty */
#endif /* !WIN32 */

#include "quintus.h"


/* The maximum pipe size is 4096, but we need to at least reserve
	one extra byte for LF which might be added by QI_output() */
#ifdef	DEBUG
#define	TTY_BUFSIZ		16
#define	MAX_FIFO_BUFSIZ		16
#else
#define	TTY_BUFSIZ		128
#define	MAX_FIFO_BUFSIZ		4092
#endif

extern	QP_stream *QU_fdopen(QP_stream *, char *, int *, int);
extern	char	  *DefaultTtyName;	/* declared in unixopen.c */

/*
    This I/O initialization function only handles three possible
    types of file, a tty file , a pipe and an ordinary file
*/
#include <stdio.h>
int
QU_initio(QP_stream **user_input, QP_stream **user_output,
	  QP_stream **user_error, int act_astty, int *error_num)
    {
	int		fd, is_tty;
	struct	stat	statbuf;
	QP_stream	option, *streams[3], *prompt_stream;
	extern char	*ttyname(int);

	for (fd=2; fd >= 0 ; --fd) {
	    is_tty = isatty(fd);
	    QU_stream_param((is_tty) ? "/dev/tty" : "",
		(fd) ? QP_WRITE : QP_READ,
		(is_tty || act_astty) ? QP_DELIM_TTY : QP_DELIM_LF,
		&option);
	    if (is_tty || act_astty) {
		/* make sure other parameters are right  */
		/* make QP_stderr unbuffered */
		/* option.max_reclen = (fd != 2) ? TTY_BUFSIZ : 0; */
		option.max_reclen = TTY_BUFSIZ;
		option.seek_type  = QP_SEEK_ERROR;
		if (fd == 0)
		    option.peof_act = QP_PASTEOF_RESET;
	    } else  {
		if (fstat(fd, &statbuf) < 0) {
		    *error_num = errno;
		    return QP_ERROR;
		}
		if ((statbuf.st_mode & S_IFIFO) == S_IFIFO) {
		    option.max_reclen = MAX_FIFO_BUFSIZ;
                    option.seek_type  = QP_SEEK_ERROR;
		} else 
#if HAVE_ST_BLKSIZE
		option.max_reclen = statbuf.st_blksize;
#else
	        option.max_reclen = 8192;
#endif
	    }
	    option.mode = (fd) ? QP_WRITE : QP_READ;
	    if ((streams[fd]=QU_fdopen(&option,"",error_num,fd))
				==QP_NULL_STREAM)
		return QP_ERROR;
	    /* Calling ttyname() on a fd opened as "/dev/tty"
	       may return "/dev/tty" even it is connected to a
	       pseudo terminal.  To prevent such case, we modify
	       the value of DefaultTtyName here */
	    if (is_tty) {
		char	*tty_id;
		if (! (tty_id = ttyname(fd)) )
		    tty_id = DefaultTtyName;
		else
		    DefaultTtyName = tty_id;
		(void) QP_add_tty(streams[fd], tty_id);
	    } else if (act_astty)
		(void) QP_add_tty(streams[fd], "/PROLOG INITIAL STREAMS");
	}
	(streams[0])->filename="USER$INPUT";
	*user_input  = streams[0];
	(streams[1])->filename="USER$OUTPUT";
	*user_output = streams[1];
	(streams[2])->filename="USER$ERROR";
	*user_error  = streams[2];
	if ((streams[0])->format == QP_DELIM_TTY
		&& (streams[1])->format != QP_DELIM_TTY
		&& (streams[2])->format != QP_DELIM_TTY) {
	    char *tty_id;
	    /* create an output stream for prompt */
	    QU_stream_param(isatty(0) ? "/dev/tty" : "", QP_WRITE,
				QP_DELIM_TTY, &option);
	    option.max_reclen = TTY_BUFSIZ;
	    option.seek_type = QP_SEEK_ERROR;
	    if ((prompt_stream=QU_fdopen(&option, "",error_num, 0))
				==QP_NULL_STREAM)
		return QP_ERROR; 
	    (void) QP_register_stream(prompt_stream);
	    if (! (tty_id = ttyname(0)) )
		tty_id = "/PROLOG DEFAULT TTYS";
	    (void) QP_add_tty(prompt_stream, tty_id);
	}
	return QP_SUCCESS;
    }
