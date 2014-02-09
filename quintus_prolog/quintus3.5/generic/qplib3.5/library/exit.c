/*  File   : exit.c
    Author : Richard A. O'Keefe
    Updated: 3/25/94
    Defines: QP_run_exit_forms()

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This file exists for two reasons:
    (1) It is awkward to load the system call exit(2) in a portable way
	without going through a file like this.
    (2) This gives us the opportunity to provide an "onexit" feature.

    The OnExitList is a list of function/argument pairs which will be
    called on exit.  You add a pair to this list by calling

	QP_add_exit_form(function, argument);
    or	cleanup = QP_on_exit(function, argument);
  
    The argument type is here assumed to be a char*.
    You remove a pair from the list by calling

	QP_del_exit_form(cleanup, do_it_now);

    If do_it_now is true, the cleanup form is executed.

    So the kind of thing you might do is

	{
	    FILE *f = fopen(....);
	    long cleanup = QP_add_exit_form(fclose, f);

	    ...
	    QP_del_exit_form(cleanup, 1);
	}

    A way of exiting is to call
	QP_run_exit_forms(exit_code);
    which should also close down the QP streams, but currently doesn't.
    {In fact, the closing of QP streams should be done by putting exit
    forms on this list, then they could be closed from C.}
*/

#ifndef	lint
static	char SCCSid[] = "@(#)94/03/25 exit.c	72.1";
#endif/*lint*/

#include <stdlib.h>
#include "quintus.h"            /* [PM] 3.5 QP_malloc */
#include "malloc.h"

typedef struct exit_form_rec *exit_form_ptr;

struct exit_form_rec
    {
	exit_form_ptr	prev;
	exit_form_ptr	succ;
	void	      (*func)(/*char**/);
	char*		arg;
    };

static struct exit_form_rec header =
    {
	/* prev */	(exit_form_ptr)0,
	/* succ */	(exit_form_ptr)0,
	/* func */	exit,
	/* arg  */	(char*)0
    };


exit_form_ptr QP_add_exit_form(func, arg)
    void (*func)();
    char* arg;
    {
	register exit_form_ptr p = Malloc(exit_form_ptr, sizeof *p);

	if (!header.prev) header.prev = header.succ = &header;
	if (p) {
	    p->prev = header.prev;
	    p->succ = &header;
	    p->func = func;
	    p->arg  = arg;
	    p->prev->succ = p;
	    header.prev = p;
	}
	return p;
    }


void QP_del_exit_form(p, do_it_now)
    register exit_form_ptr p;
    int do_it_now;
    {
	if (!p) return;
	if (!p->prev) return;
	p->prev->succ = p->succ;
	p->succ->prev = p->prev;
	p->prev = p->succ = (exit_form_ptr)0;
	if (do_it_now) (p->func)(p->arg);
	Free(p);
    }


void QP_run_exit_forms(exit_code)
    int exit_code;
    {
	register exit_form_ptr p = &header;

	p->arg = (char*)exit_code;
	if (!p->prev) p->prev = p->succ = p;
	for (;; p = p->prev) (p->func)(p->arg);
	/*NOTREACHED*/
    }


