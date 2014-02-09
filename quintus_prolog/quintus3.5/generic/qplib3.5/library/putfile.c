
/*  File   : putfile.c
    Author : Richard A. O'Keefe
    Updated: 09 Oct 1996
    Purpose: Copy the contents of a file to the current output stream.

    The idea is that from time to time you would like to copy the
    contents of a file to the current output stream.  You could do
    that in Prolog, with code like this:

    put_file(FileName) :-
	seeing(Old),
	see(FileName),
	repeat,
	    get0(Char),
	    (   is_endfile(Char) -> true
	    ;   put(Char), fail
	    ),
	!,
	seen,
	see(Old).

    However, doing it in C is significantly faster.
*/

#include <stdio.h>
#include "quintus.h"

#ifndef	lint
static	char SCCSid[] = "@(#)96/10/09 putfile.c	76.1";
#endif/*lint*/


void QP_putfile(FileName)
    char *FileName;
    {
	FILE *input;	
	unsigned char buffer[8192+1];
	int n;

	if (!(input = fopen(FileName, "r"))) {
	    QP_fprintf(QP_stderr, "\n! Can't read file: %s\n", FileName);
	    return;
	}
	while ((n = fread(buffer, 1, sizeof(buffer)-1, input)) > 0) {
	    buffer[n] = 0;
	    QP_puts(buffer);
	}
	fclose(input);
    }

