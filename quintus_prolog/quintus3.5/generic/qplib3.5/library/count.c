/*  File   : count.c
    Author : Richard A. O'Keefe.
    Updated: 03/12/99
    Purpose: Support for count.pl

    Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdlib.h>             /* [PM] 3.5 abort */
#include <string.h>             /* [PM] 3.5 memcpy */
#include "quintus.h"            /* [PM] 3.5 QP_malloc, QP_free */

#ifndef	lint
static	char SCCSid[] = "@(#)99/03/12 count.c	76.1";
#endif/*lint*/

static	unsigned CountLimit = 0;
static	unsigned long *CountTable = (unsigned long *) 0;

void increment_(n)
    unsigned n;
    {
	if (CountTable && n < CountLimit) CountTable[n]++;
    }

void clear_counts()
    {
	register unsigned long *p = CountTable;
	register unsigned long *q = p + CountLimit;

	if (p) while (p != q) *p++ = 0;
    }

unsigned long read_counter(n)
    unsigned n;
    {
	if (CountTable && n < CountLimit) return CountTable[n];
	return 0;
    }

void add_counter(n)
    unsigned n;
    {
	register unsigned long *p;
	register unsigned long *q;

	if (n < CountLimit) return;
	if (!CountTable) {
	    if (n < 20)
		n = 20;
	    p = (unsigned long *)QP_malloc(n * sizeof *p);
	    if (!p) abort();
	    CountTable = p;
	    q = p + n;
	} else {
	    if (n < ((5*CountLimit)>>2)+10)
		n = ((5*CountLimit)>>2)+10;
	    p = (unsigned long *)QP_malloc(n * sizeof *p);
	    if (!p) abort();
	    memcpy(p, CountTable, CountLimit * sizeof *p);
	    QP_free(CountTable);
	    CountTable = p;
	    q = p + n;
	    p = p + CountLimit;
	}
	CountLimit = n;    
	while (p != q) *p++ = 0;
    }

