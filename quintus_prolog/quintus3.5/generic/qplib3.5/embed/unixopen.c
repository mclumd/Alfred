/* SCCS   : @(#)unixopen.c	75.3 06/29/95
   File   : unixopen.c
   Author : Chung-ping Lan
   Purpose: Source code for io.c

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#if WIN32
#include <io.h>
#include "pcux.h"
#else
#include <unistd.h>
#endif
#include <fcntl.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>             /* [PM] 3.5 strcmp */

#include "quintus.h"

#ifndef O_BINARY
#define O_BINARY	0
#endif

char	*DefaultTtyName = "/PROLOG DEFAULT TTYS";

QP_stream *
QU_fdopen(QP_stream *option, char *sys_option, int *error_num, int file_des)
    {
	QP_stream	*stream;
	extern QP_stream *QU_tty_open(), *QU_text_open(), *QU_raw_open();

	if (sys_option && *sys_option != '\0') {
	    *error_num = QP_E_SYS_OPTION;
	    return QP_NULL_STREAM;
	}
	*error_num = 0;
	if (option->format == QP_FMT_UNKNOWN) {
	    if (isatty(file_des))
		option->format = QP_DELIM_LF;
	    else if (option->line_border == QP_NOLB && option->trim == 0)
		option->format = QP_VAR_LEN;	/* binary file */
	    else
		option->format = QP_DELIM_LF;
	}
	switch (option->mode) {
	case QP_READ:
	case QP_WRITE:
	    option->magic.byteno = 0;
	    if (option->seek_type != QP_SEEK_ERROR) {
		struct stat	statbuf;

		if (fstat(file_des, &statbuf) == 0 &&
			(statbuf.st_mode & S_IFMT) == S_IFREG)
		    if ((option->magic.byteno =
	    			lseek(file_des, 0L, SEEK_CUR))==-1) {
			*error_num = errno;
			return QP_NULL_STREAM;
		    }
	    }
	    break;
	case QP_APPEND:
	    if ((option->magic.byteno=lseek(file_des, 0L, SEEK_END))==-1) {
		 *error_num = errno;
		return QP_NULL_STREAM;
	    }
	    break;
	default:
	    *error_num = QP_E_BAD_MODE;
	    return QP_NULL_STREAM;
	}
	switch (option->format) {
	case QP_DELIM_TTY:
	    stream = QU_tty_open(option, error_num, file_des);
	    break;
	case QP_DELIM_LF:
	    stream = QU_text_open(option, error_num, file_des);
	    break;
	case QP_VAR_LEN:
	    stream = QU_raw_open(option, error_num, file_des);
	    break;
	default:
	    *error_num = QP_E_BAD_FORMAT;
	    return QP_NULL_STREAM;
	}
	return stream;
    }

QP_stream *
QU_open(QP_stream *option,
	char *sys_option,         /* not useful in this version */
	int *error_num)
    {
	QP_stream	*stream;
	int		fd, o_binary;
	char		*filename;
	struct stat	statbuf;

	*error_num = 0;
	if (! (filename = option->filename)) {
	    *error_num = QP_E_FILENAME;
	    return QP_NULL_STREAM;
	}

	o_binary = (option->format == QP_VAR_LEN) ? O_BINARY : 0;

	switch (option->mode) {
	case QP_READ:
	    fd = open(filename, o_binary|O_RDONLY, 0000);
	    break;
	case QP_WRITE:
	    fd = open(filename, o_binary|O_WRONLY|O_CREAT|O_TRUNC, 0666);
	    break;
	case QP_APPEND:
	    fd = open(filename, o_binary|O_WRONLY|O_CREAT, 0666);
	    break;
	default:
	    *error_num = QP_E_BAD_MODE;
	    return QP_NULL_STREAM;
	}
	if (fd < 0) {
	    *error_num = errno;
	    return QP_NULL_STREAM;
	}
	if (fstat(fd, &statbuf) == 0) {
	    if ((statbuf.st_mode & S_IFMT) == S_IFDIR) {
		(void) close(fd);
		*error_num = QP_E_DIRECTORY;
		return QP_NULL_STREAM;
	    }
	}
	if (option->format == QP_DELIM_TTY && !(isatty(fd)) ) {
	    *error_num = QP_E_BAD_FORMAT;
	    (void) close(fd);
	    return QP_NULL_STREAM;
	}
	if ((stream = QU_fdopen(option, sys_option, error_num, fd))
			== QP_NULL_STREAM) {
	    (void) close(fd);
	    return QP_NULL_STREAM;
	}
	if (stream->format == QP_DELIM_TTY) {
	    char	*tty_id;
	    if ((! (tty_id = ttyname(fd)))
			|| (strcmp(tty_id, "/dev/tty") == 0))
		tty_id = DefaultTtyName;
	    (void) QP_add_tty(stream, tty_id);
	}
	return stream;
    }

