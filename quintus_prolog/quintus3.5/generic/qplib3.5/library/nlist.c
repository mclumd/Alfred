/*  File   : nlist.c
    Author : Richard A. O'Keefe
    Updated: %G%
    Purpose: Support for nlist.pl -- interface to Unix nlist(3) function.

    Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef	lint
static	char SCCSid[] = "%Z%%E% %M%	%I%";
#endif/*lint*/

#ifndef i386

#include <nlist.h>
#include "malloc.h"


struct nlist *allocate_name_list_vector(n)
    int n;
    {
	struct nlist *p = Malloc(struct nlist *, (n+1)*sizeof *p);

	if (p) p[n].n_name = (char*)0;
	return p;
    }

void set_name_list_name(n, nl, name)
    int n;
    struct nlist *nl;
    char *name;			/* RELY ON THIS BEING STATIC! */
    {
	nl[n].n_name = name;
    }

int get_name_list_type_and_value(n, nl, value)
    int n;
    struct nlist *nl;
    unsigned long *value;
    {
	*value = nl[n].n_value;
	return nl[n].n_type;
    }

void free_name_list_vector(nl)
    struct nlist *nl;
    {
	Free(nl);
    }

#endif

