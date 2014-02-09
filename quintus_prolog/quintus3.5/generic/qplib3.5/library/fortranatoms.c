/*  File   : fortranatoms.c
    Author : Richard A. O'Keefe
    Updated: 01 Mar 1994
    Purpose: allow Fortran access to Prolog atom names
    Warning: THIS FILE IS OBSOLETE. IT MAY BE WITHDRAWN IN FUTURE RELEASES.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    "foreign functions" coded in C can access Prolog atom names using

	QP_string_from_atom(atom code) -> pointer to atom's name

	QP_atom_from_string(pointer to string) -> atom code

    The purpose of this file is to define two Fortran-callable functions

	integer QPatch(atom, name)
	    integer atom
	    character *(*) name
	    returns as much of the atom name as it can in name.
	    returns the true length as its value.

	integer QPchat(name)
	    character *(*) name
	    analogue of QP_atom_from_string.

    BEWARE!  Much of the time it will be more appropriate to call

	atom = QPchat(string(:lnblnk(string)))

    Note that the f77 compiler forces identifiers to lower case and sticks
    an extra underscore at the end, so the names shown above, and the names
    actually written below, look quite different.

    This file has been superseded by the 2.0 release built-in functions
	integer QP_padded_string_from_atom(atom, name)
	    integer atom
	    character *(*) name
    which does exactly what QPatch does, and
	integer QP_atom_from_padded_string(atom, name)
	    integer atom
	    character *(*) name
    which ignores trailing blanks in name, stores the atom code through
    its atom argument, and returns the true length of the atom.  Note
    the difference: this function ignores trailing blanks, QPchat DOESN'T.
*/

#include "quintus.h"

#ifndef	lint
static	char SCCSid[] = "@(#)94/03/01 fortranatoms.c	71.1";
#endif/*lint*/


int qpatch_(atom, dstptr, dstlen)
    QP_atom  atom;		/* the Prolog atom code */
    register char *dstptr;	/* where the characters are to go */
    register int   dstlen;	/* how many characters caller can take */
    {
	register char *srcptr = QP_string_from_atom(atom);
	register int len = 0;

	while (len < dstlen && (*dstptr++ = *srcptr++)) len++;
	if (len < dstlen) {	/* pad with blanks */
	    int temp = len;
	    while (len < dstlen) *dstptr++ = ' ', len++;
	    return temp;
	} else {		/* truncated on right */
	    while (*srcptr++) len++;
	    return len;
	}
    }


QP_atom qpchat_(srcptr, srclen)
    register char *srcptr;
    register int srclen;
    {
	char buffer[QP_MAX_ATOM+4];
	register char *dstptr = buffer;

	if (srclen >= sizeof buffer) srclen = sizeof buffer - 1;
	while (--srclen >= 0) *dstptr++ = *srcptr++;
	*dstptr = 0;
	return QP_atom_from_string(buffer);
    }


