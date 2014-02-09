/*  File   : arity.c
    Author : Richard A. O'Keefe.
    Updated: 04/17/89
    Purpose: Runtime support for Arity/Prolog programs ported to Quintus Prolog

    Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)89/04/17 arity.c	31.1";
#endif/*lint*/

static long random_state;
static double random_scale = 1.0/32768.0;

void arity_randomise(seed)
    long seed;
    {
	random_state = seed;
    }

double arity_random()
    {
	return (((random_state = random_state*1103515245 + 12345)
		>> 16) & 32767) * random_scale;
    }

/*  arity_file_length(FileName)
    returns the length of the file in bytes.  There is currently no
    error reporting.  We could have used
	file_property(FileName, size_in_bytes, Length)
*/

#include <sys/types.h>
#include <sys/stat.h>

long arity_file_length(FileName)
    char *FileName;
    {
	struct stat buf;

	if (stat(FileName, &buf)) return -1;
	return buf.st_size;
    }

