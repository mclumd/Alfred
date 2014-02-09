/*  File   : statistics.c
    Author : Richard A. O'Keefe
    Updated: 12/10/98
    Purpose: Provide the "page-faults" statistic

    Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

    Choice : What counts as a "page fault"?  I chose to make it ru_majflt
	     rather than (say) ru_majflt+ru_minflt, because the ones that
	     do I/O are the limiting factor.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)98/12/10 statistics.c	76.1";
#endif/*lint*/

#if SUNOS4 || AIX
#include <errno.h>             /* [PM] 3.5 errno */
#include <sys/time.h>
#include <sys/resource.h>

int QPageN(total, increment)
    long *total, *increment;
    {
	struct rusage r_usage;
        /* [PM] 3.5 errno is often a macro these days: extern int errno; */
	static int o_p_faults = 0;

	if (getrusage(RUSAGE_SELF, &r_usage) < 0) return errno;
	*increment = r_usage.ru_majflt - o_p_faults;
	o_p_faults = r_usage.ru_majflt;
	*total = o_p_faults;
	return 0;
    }

#else

int QPageN(total, increment)
    int *total, *increment;
    {
	return 96 /* EUNIMP */;
    }

#endif
