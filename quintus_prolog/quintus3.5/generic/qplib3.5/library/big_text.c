/*  File   : big_text.c
    Author : Richard A. O'Keefe
    Updated: 12/10/98
    Purpose: C support for big_text.pl

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    BEWARE : This code is only serially re-usable, and does little
    	     error checking.  It is only intended to support big_text.pl,
	     and is adequate for that.  It is not meant for general use.
*/

#include <stdio.h>
#include <string.h>
#ifdef unix
#include <unistd.h>
#endif

static	FILE *sink = NULL;

#ifdef	L_tmpnam
static	char scratch_file_name[L_tmpnam+1];
#else
static	char scratch_file_orig[] = "/usr/tmp/QPBT_XXXXXX";
static	char scratch_file_name[sizeof scratch_file_orig];
#endif

#ifndef	lint
static	char SCCSid[] = "@(#)98/12/10 big_text.c	76.1";
#endif/*lint*/

char *QBshow()
    {
#ifdef WIN32
	static char tty[] = "con";
#else
	static char tty[] = "/dev/tty";
#endif

	sink = fopen(tty, "w");
	return tty;
    }

char *QBopen()
    {
#ifdef	L_tmpnam
	(void)tmpnam(scratch_file_name);
	sink = fopen(scratch_file_name, "w");
#else
	int fd;
	(void)strcpy(scratch_file_name, scratch_file_orig);
	fd = mkstemp(scratch_file_name);
	sink = fdopen(fd, "w");
#endif
	return scratch_file_name;
    }

void QBrename(newname)
    char *newname;
    {
	(void)fclose(sink);
	sink = NULL;
	/* We should really check the return codes here */
	/* Better still, big_text.pl should use library(files) */
	(void)unlink(newname);
	(void)rename(scratch_file_name, newname);
    }

void QBclose()
    {
	(void)fclose(sink);
	sink = NULL;
    }

void QBdelete()
    {
	/* We should really check the return code here */
	/* Better still, aropen.pl should use library(files) */
	(void)unlink(scratch_file_name);
    }

void QBchar(c)
    long c;
    {
	putc(c, sink);
    }

void QBatom(s)
    char *s;
    {
	fputs(s, sink);
    }

long QBfile(file, offset, length)
    char *file;
    long offset;
    long  length;
    {
	FILE *source;
	char buffer[4096];

	if ((source = fopen(file, "r")) == NULL) return -1;
	if (fseek(source, offset, 0) < 0) {
	    (void)fclose(source);
	    return -1;
	}
	while (length >= sizeof buffer) {
	    (void)fread( buffer, sizeof buffer, 1, source);
	    (void)fwrite(buffer, sizeof buffer, 1, sink);
	    length -= sizeof buffer;
	}
	if (length > 0) {
	    (void)fread( buffer, length, 1, source);
	    (void)fwrite(buffer, length, 1, sink);
	}
	(void)fclose(source);
	return 0;
    }

long QBtell()
    {
	return ftell(sink);
    }

