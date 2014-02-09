/*  File   : ipcerror.c
    Author : David S. Warren
    Updated: %G%
    Purpose: Report I/O errors.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdio.h>
#include "ipcerror.h"

#ifndef	lint
static	char SCCSid[] = "%Z%%E% %M%	%I%";
#endif/*lint*/


void IOError(message)	/* print out an i/o error message */
    char *message;	/* This is almost identical to perror() */
    {
	switch (errno) {
	    case ESOCKUI:
	        fprintf(stderr, "\n** Error %s: ", message);
		fprintf(stderr, "sockets are unimplemented\n");
		break;
	    case EFSMBLK:
	        fprintf(stderr, "\n** Error %s: ", message);
		fprintf(stderr, "connection in wrong state\n");
		break;
	    default:
	        perror(message);
		break;
	}
    }


void XDRerror(message)	/* print out an error message */
    char *message;
    {
	fprintf(stderr, "** XDR Error: %s\n", message);
    }


