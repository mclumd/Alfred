/* SCCS   : @(#)oldio.c	75.1 06/28/95
   File   : oldio.c
   Author : Chung-ping Lan
   Purpose: Source code for old I/O functions

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdio.h>

#include "quintus.h"

#define	SET_IO_ERROR(S,E)	((S->errnum=(E)), QP_ERROR)
#define	UPDATE_UNIX_MAGIC(S, B)	((B)=(S)->magic.byteno+\
				 ((S)->line_len-(S)->n_char))


#undef	QP_getc
#undef	QP_putc

/*
   The following functions are kept for backward compatiablility.
*/

int
QP_getc(void)
    {
	int	c;
	if ((c = QP_fgetc(QP_curin)) == QP_ERROR)
	    return EOF;
	return c;
    }

int
QP_sgetc(QP_stream *stream)
    {
	int c;
	if ((c = QP_fgetc(stream)) == QP_ERROR)
	    return EOF;
	return c;
    }

int
QP_putc(int c)
    {
	int	rtn;

	if ((rtn = QP_fputc(c, QP_curout)) == QP_ERROR)
	    return EOF;
	return rtn;
    }

int
QP_sputc(int c, QP_stream *stream)
    {
	int	rtn;

	if ((rtn =  QP_fputc(c, stream)) == QP_ERROR)
	    return EOF;
	return rtn;
    }

int
QP_sputs(unsigned char *string, QP_stream *stream)
    {
	int	rtn;

	if ((rtn = QP_fputs(string, stream)) == QP_ERROR)
	    return EOF;
	return rtn;
    }

#include <stdarg.h>

int
QP_sprintf(QP_stream * stream, char * format, ...)
    {
	va_list		argsptr;
	int		rtn_val;

	va_start(argsptr, format);
	rtn_val = QP_vfprintf(stream, format, argsptr);
	va_end(argsptr);
	return (rtn_val == QP_ERROR) ? EOF : rtn_val;
    }



