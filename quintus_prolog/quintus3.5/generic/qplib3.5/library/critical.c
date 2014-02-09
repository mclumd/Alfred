/*  File   : critical.c
    Author : Tom Howland
    Origin : March 1986
    Updated: 3/25/94
    Purpose: Management of critical regions and interrupts

	+========================================================+
	|							 |
	|  Copyright (C) 1987,  Quintus	Computer Systems, Inc.	 |
	|  All rights reserved.					 |
	|							 |
	+========================================================+

Critical regions should be used with segments of code that must
execute without being interrupted (via ^C).  This library file
implements critical regions using the blocking primitives supplied by
the operating system.

A user marks the start of a critical region by a call to
begin_critical().  The end of the critical region is marked by a call
to end_critical().

This library package is discussed more fully in the file critical.pl. */

#ifndef	lint
static  char SCCSid[] = "@(#)94/03/25 critical.c     72.1";
#endif/*lint*/

#include "quintus.h"

#include <signal.h>

static int crit_count = 0;

#if WIN32
#define BLOCK(mask)
#define UNBLOCK(mask)

/* [PM] 3.5 FIXME:
   We should probably use sigprocmask on all UNIXes these days
   We should probably prefer sigblock over sighold on Linux (but sigprocmask would be even better) 
*/
#elif SUNOS4 || AIX
static int mask;
#define BLOCK(mask)	mask = sigblock(sigmask(SIGINT))
#define UNBLOCK(mask)	sigsetmask(mask)

#else
#define BLOCK(mask)	(void) sighold(SIGINT)
#define UNBLOCK(mask)	(void) sigrelse(SIGINT)
#endif

/*----------------------------------------------------------------------+
|   Enter a critical region.  Critical regions can be nested.		|
+----------------------------------------------------------------------*/

void begin_critical()
{
    /* SIGINT is typically bound to ^C */

    if (crit_count++ == 0) {
	BLOCK(mask);
    }
}

/*----------------------------------------------------------------------+
|   Leave a critical region.
+----------------------------------------------------------------------*/

void end_critical()
{
    register int c;

    c = --crit_count;

    if(c) {

	if(c < 0) {

	    crit_count = 0;
	    QP_fprintf(QP_stderr, "ERROR:  too many end_critical/0's.\n");
	}

    } else {

 	UNBLOCK(mask);
    }
}
