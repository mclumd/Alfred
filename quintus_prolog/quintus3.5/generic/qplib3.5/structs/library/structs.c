/*  File   : structs.c
    Author : Peter Schachte
    Updated: 06/01/94
    Purpose: to allow access to C/Pascal data structures from Prolog

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved

    This file provides access to memory locations to the structs
    package.  Actual functions supplied include the following:

	    _Sget_atom(pointer, offset)
	    _Sget_string(pointer, offset)

	    _Sput_atom(pointer, offset, newvalue)
	    _Sput_string(pointer, offset, newvalue)

    Other types are accessed and set using the is/2 and assign/2
    Prolog primitives.

*/


#ifndef	lint
static	char SCCSid[] = "@(#)94/06/01 structs.c     20.1";
#endif	/* lint */

#include "quintus.h"

QP_atom _Sget_atom(pointer, offset)
char *pointer;
int offset;
{
	return *(QP_atom *)(pointer+offset);
}


char *_Sget_string(pointer, offset)
char *pointer;
int offset;
{
	return *(char **)(pointer+offset);
}

void                            /* [PM] 3.5 was missing return type */
_Sput_atom(pointer, offset, newvalue)
char *pointer;
int offset;
QP_atom newvalue;
{
	/*
	 *  slots are initialized to zeros on 'new' - an impossible value
	 *  for an atom, so we can tell if we need to unregister the old atom
	 */
	QP_atom oldvalue = (*(QP_atom *)(pointer+offset));
	if (oldvalue != 0)
		QP_unregister_atom(oldvalue);

	QP_register_atom(newvalue);
	(*(QP_atom *)(pointer+offset)) = newvalue;
}

void                            /* [PM] 3.5 was missing return type */
_Sput_string(pointer, offset, newvalue)
char *pointer;
int offset;
char *newvalue;
{
	(*(char **)(pointer+offset)) = newvalue;
}
