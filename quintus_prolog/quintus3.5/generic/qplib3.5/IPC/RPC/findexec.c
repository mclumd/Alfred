/*  File   : findexec.c
    Author : Richard A. O'Keefe
    Updated: 11/01/88
    Defines: find_executable()

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    find_executable(CommandName, SearchPath, Buffer, MaxBufLen)

	CommandName	the name of a file to be executed.

	SearchPath	a string similar to the UNIX environment
			variable $PATH specifying a sequence of
			directories to look for CommandName in.

	Buffer		where the fully expanded file name is to go.

	MaxBufLen	how many characters (including the trailing
			NUL) may be written to Buffer.

    If all goes well, find_executable returns Buffer.
    Otherwise it returns NULL.

    The SearchPath is a sequence of elements separated by colons ":".
    An element may be
	<empty>		try the current directory
	.		try the current directory
	$foo		switch over to environment variable $foo
	<Directory>	try Directory/CommandName
			Elements like this should be absolute,
			but this is not yet checked.

    Note that an initial ~[user] or $var in the CommandName is NOT
    supported.

    If CommandName begins with "/", it is checked as it stands,
    and the SearchPath is not tried.

    If CommandName does not begin with a "/", each element of the
    SearchPath is tried in turn.  A NULL SearchPath is taken as
    "$PATH", but an empty SearchPath is taken as ".".
    
    We use access(2) to determine whether we have found the right
    version of the file.  This doesn't actually mean that we have
    found a file which can be executed, just one which LOOKS as
    if it can be executed.

    The idea is that you can use ".:$PATH" or "~:$PATH" to try
    another directory before trying $PATH.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/01 findexec.c	27.2";
#endif/*lint*/

#define	Strcpy	(void)strcpy
#define	Strncpy	(void)strncpy

#include "fcntl.h"
#define	NullS ((char*)0)

#if 1                           /* [PM] 3.5 */
#include <stdlib.h>             /* getenv() */
#include <unistd.h>             /* access() */

#else  /* pre 3.5 */
extern	char *getenv();
#endif /* pre 3.5 */

#ifdef	SYS5
#include <string.h>
#define	get_working_directory(Buffer, MaxBufLen) \
	!(getcwd(Buffer, MaxBufLen))

extern char *getcwd();

#else /*4BSD*/

#include <strings.h>
#include <sys/param.h>

static int get_working_directory(Buffer, MaxBufLen)
    char *Buffer;
    int MaxBufLen;
    {
	char scratch[MAXPATHLEN+2];

	if (!getwd(scratch)) return 1;
	if (strlen(scratch) >= MaxBufLen) return 1;
	Strcpy(Buffer, scratch);
	return 0;
    }

#endif/*SYS5*/


char *find_executable(CommandName, SearchPath, Buffer, MaxBufLen)
    char *CommandName;
    char *SearchPath;
    char *Buffer;
    int  MaxBufLen;
    {
	char *p;
	int a;
	int L;

	if (*CommandName == '/') {
	    /*  It is already absolute  */
	    if (strlen(CommandName) >= MaxBufLen) return NullS;
	    Strcpy(Buffer, CommandName);
	    return Buffer;
	}

	/*  It is not absolute  */
	L = MaxBufLen-1-strlen(CommandName);
	if (!SearchPath) SearchPath = "$PATH";
BACK:	while (*SearchPath) {
	    p = SearchPath;
	    while (*SearchPath && *SearchPath != ':') SearchPath++;
	    if (p == SearchPath || (p+1 == SearchPath && *p == '.')) { /* [PM] added () around && to avoid gcc warning */
		if (get_working_directory(Buffer, MaxBufLen)) return NullS;
		a = strlen(Buffer);
		if (a >= L) return NullS;
	    } else
	    if (p+1 == SearchPath && *p == '~') {
		p = getenv("HOME");
		if (!p) return NullS;
		a = strlen(p);
		if (a >= L) return NullS;
		Strcpy(Buffer, p);
	    } else
	    if (*p == '$') {
		a = SearchPath-p;
		if (a > L) return NullS;
		Strncpy(Buffer, p+1, a-1);
		Buffer[a-1] = '\0';
		SearchPath = getenv(Buffer);
		if (!SearchPath) return NullS;
		goto BACK;
	    } else {
		a = SearchPath-p;
		if (a >= L) return NullS;
		Strncpy(Buffer, p, a);
	    }
	    Buffer[a] = '/';
	    Strcpy(Buffer+(a+1), CommandName);
	    if (!access(Buffer, X_OK)) return Buffer;
	    if (*SearchPath) SearchPath++;
	}

	/* if all else fails, try the current directory */

	if (get_working_directory(Buffer, MaxBufLen)) return NullS;
	a = strlen(Buffer);
	if (a >= L) return NullS;
	Buffer[a] = '/';
	Strcpy(Buffer+(a+1), CommandName);
	if (!access(Buffer, X_OK)) return Buffer;

	/* no more places to try */
	return NullS;
    }

