/*  File   : openfiles.h
    Author : Richard A. O'Keefe
    SCCS   : @(#)94/01/31 openfiles.h	71.1
    Purpose: Header file for openfiles.c
*/

#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

#ifdef WIN32
static char NullFileName[] = "nul:";
#else
static char NullFileName[] = "/dev/null";
#endif

#include "quintus.h"
#include "malloc.h"

typedef struct FIrec		/* File Information record */
    {
	char*	file_name;	/* the absolute name of the file */
	off_t	file_size;	/* the size of the file in bytes */
	time_t	file_date;	/* last modification time of file*/
    }   FIrec, *FIptr;


typedef struct MFrec		/* Multiple File record */
    {
	FILE*	stdio_stream;	/* connected to current file */
	FIptr	next_file_info;	/* points to next file to open */
	int	files_left;	/* number of unopened files */
	struct FIrec info[1];	/* dummy */
    }   MFrec, *MFptr;

