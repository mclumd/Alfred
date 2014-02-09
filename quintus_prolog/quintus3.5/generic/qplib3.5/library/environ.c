/*  File   : environ.c
    Author : Richard A. O'Keefe
    Updated: 3/1/94
    Purpose: Provide access to UNIX environment variables,
	     and to the command line arguments.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    The function 'QAnvrn' is meant to be called only from
    environ.pl.  It backtracks over the elements of the
    "environ" vector, returning them as pairs of strings.
    This is rather hacky, so don't interrupt it!  After it
    is all over, the environ vector (hence getenv()) can
    be used again by C code.

    For access to the argument vector, we depend on the undocumented
    fact that exec builds the following structure in high memory:

		+--------+
		|  argc	 |	a 32-bit integer
		+--------+
		| argv[0]|	points to a string
		+--------+
		   ...
		+--------+
		| argv[n]|	last argument pointer, argc=n+1
		+--------+
		|  NULL  |	terminates argv[] sequence
		+--------+
*environ ------>| envv[0]|	first environment VAR=val string
		+--------+
		   ...
		+--------+
		| envv[m]|	m is not directly available
		+--------+
		|  NULL  |	terminates environment variables
		+--------+
		  bodies	The string bodies are higher

    That is, working backwards from environ, we find first NULL,
    then the arguments, which are pointers pointing HIGHER than
    environ, and finally the argument count, which is a smallish
    number.  In fact the maximum number of bytes in the argument
    list is 10240, and it takes at least 1 byte per argument,
    so this number must be in the range 0..10240.

    The variable argc is initialised to -1.  If it has some other
    value, it and the other variables have been initialised by
    QAargc.  We return -1 if anything looks suspicious.
*/

#include "quintus.h"
#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>              /* [PM] 3.5 sprintf */
#include <string.h>             /* [PM] 3.5 strlen */

#ifndef	lint
static	char SCCSid[] = "@(#)94/03/01 environ.c	71.2";
#endif/*lint*/

#ifdef WIN32
#include <process.h>
#else
#include <unistd.h>             /* [PM] 3.5 getpid */
extern	char**	environ;
#endif

static	int	argc = -1;
static	char**	argv;	/* will point to argv[0] */
static	char**	argp;	/* runs along argv[] */


char *QAnext()
    {
	return *argp++;
    }


int QAargc()
    {
	if (argc < 0) {
#ifdef WIN32
	    argc = QP_argc;
	    argv = QP_argv;
#else /*unix*/
	    int k;
	    char *arg;

	    argv = environ;
	    if (*--argv) return -1;	/* should be NULL */
	    for (k = 0; ; k++) {
		if (k >= 10240) return -1;
		arg = *--argv;
		if (arg < (char*)environ) break;
	    }
	    if ((int)arg != k) return -1;
	    argc = k;
	    argv++;
#endif
	}
	argp = argv;
	return argc;
    }


/*  QA bige -- By Integer Get from Environment
    is given an index into environ and returns two strings and a result code.
    I rely on the index parameter being counted up from 0.
    Temporary assumption: no environment variable has more than 80
    characters in its name.
*/
int QAbige(index, variable, value)
    int index;
    char **variable;
    char **value;
    {
	static char buffer[81];
	register char *p, *q;
	
	if (!(p = environ[index])) {
	    *variable = "", *value = "";
	    return -1;
	}
	for (q = buffer; *p != '=' && (*q++ = *p++); ) ;
	if (!*p) {
	    *variable = "NO", *value = "=";
	    return -2;
	}
	*q = 0, p++;
	*variable = buffer, *value = p;
	return 0;
    }


/*  QA bnge  -- By Name Get from Environment
    is given a name to look up in the environment and returns a
    string and an error code.
*/
int QAbnge(variable, value)
    char *variable;
    char **value;
    {
	register char *p = getenv(variable);

	if (p) {
	    *value = p;
	    return 0;
	} else {
	    *value = "";
	    return -1;
	}
    }


/*  QA evxn  -- Environment Variable Expand Name
    is given a C string possibly containing references to environment
    variables, and returns a Prolog atom in which all such references
    have been expanded.  The possible cases are

	$<layout>	A dollar sign followed by a space, tab, or newline
			is taken as a literal dollar.  This is copied from
			the C shell.

	$$		A pair of dollar signs is replaced by the process
			identifier (see man 2 getpid) of the Prolog process
			expressed as 1-6 decimal digits.  This is copied
			from the Bourne and C shells both.

	$<alnums>	A sequence of letters, digits, and underscores
			is looked up in the environment, and replaced
			by the value that getenv() finds.

	$(stuff)	These four forms are identical in effect.  They
	$[stuff]	let you use environment variables with arbitrary
	$<stuff>	names, but their main point is that you can put
	${stuff}	a letter, digit, or underscore after them.

	$<other>	The dollar sign is taken literally, and the
			<other> character is processed.  (<layout>
			characters, you will recall, are discarded.)

    For example, suppose
	$HOST		is goonshow
	$USER		is bloodnok
	$HOME		is /usr/bloodnok
	$TERM		is vt100
    Then
	$HOME/thingy	is /usr/bloodnok/thingy
	${HOST}_${USER}	is goonshow_bloodnok
	$HOST_$USER	would look for a variable HOST_
	${TERM}-np	is vt100-np
	$<TERM>2	is vt1002
	$TERM2		would look for a variable TERM2
	/tmp/$USER$$	might be /tmp/bloodnok1234
	$ USER$		would be $USER$

    If all goes well, QAevxn returns 0.
    If an error is detected, it returns a character which identifies
    the error:
	')', ']', '>', or '}'	$( was found but the ) was missing, &c.
	'e'			An environment variable didn't exist.
	'o'			The result was too long for an atom.
*/
int QAevxn(source, result)
    char *source;
    QP_atom *result;
    {
	char buffer[QP_MAX_ATOM+8];
	char *limit = buffer+QP_MAX_ATOM;
	register char *s, *d, *t;
	register int c, x;

        /* initialize output argument to avoid a range error */
        *result = QP_atom_from_string("[]");

	s = source, d = buffer, t = limit;
	while ((c = *s++)) {
	    if (c != '$') {
		if (d >= t) return 'o';
		*d++ = c;
	    } else
	    switch (c = *s++) {
		default:
		    if (!isalnum(c)) {
			if (d >= t) return 'o';
			--s;
			*d++ = '$';
			break;
		    }
		    t = d;
		    do *d++ = c; while ((c = *s++), isalnum(c) || c == '_');
		    --s;
		    goto lookup;
		case ' ': case '\t': case '\n':
		    if (d >= t) return 'o';
		    *d++ = '$';
		    break;
		case '$':		/* $$ = process id */
		    x = getpid();
		    (void)sprintf(d, "%d", x);
		    d += strlen(d);
		    if (d >= t) return 'o';
		    break;
		case '(':
		    x = ')'; goto bracketed;
		case '[':
		    x = ']'; goto bracketed;
		case '<':
		    x = '>'; goto bracketed;
		case '{':
		    x = '}';
bracketed:	    t = d;
		    while ((c = *s++) && c != x) *d++ = c;
		    if (!c) return x;
lookup:		    *d = '\0';
		    d = getenv(t);
		    if (!d) return 'e';
		    if (t+strlen(d) >= limit) return 'o';
		    while ((c = *d++)) *t++ = c;
		    d = t, t = limit;
	    }
	}
	*d = '\0';
	*result = QP_atom_from_string(buffer);
	return 0;
    }
