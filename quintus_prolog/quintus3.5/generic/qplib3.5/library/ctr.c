/*  File   : ctr.c
    Author : Richard A. O'Keefe.
    Updated: 11/2/88
    Purpose: "Counter Predicates" support.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This file supports 32 counters numbered 0..31 (in fact, as
    the Arity manual does not say what happens when out of range
    indices are used, any integer is taken modulo 32).  Why was
    the range extended?  So I could use this package in library
    routines and not interfere with existing Arity code.
    Each routine returns the old value of its counter.
*/


#ifndef	lint
static	char SCCSid[] = "@(#)88/11/02 ctr.c	27.2";
#endif/*lint*/

long ctr[32];	/* These counters are visible to other C code */

#define	CTR_INC 0
#define	CTR_DEC 1
#define	CTR_SET 2

long ctr_val(Counter)
    int Counter;
    {
	return ctr[Counter&31];
    }

void ctr_op2(Counter, NewValue, Op)
    int Counter;
    long NewValue;
    int Op;
    {
	switch (Op) {
	    case CTR_INC: ctr[Counter&31] += NewValue; break;
	    case CTR_DEC: ctr[Counter&31] -= NewValue; break;
	    case CTR_SET: ctr[Counter&31]  = NewValue; break;
	}
    }

long ctr_op3(Counter, NewValue, Op)
    int Counter;
    long NewValue;
    int Op;
    {
	register long *p = &ctr[Counter&31];
	register long OldValue = *p;

	switch (Op) {
	    case CTR_INC: *p += NewValue; break;
	    case CTR_DEC: *p -= NewValue; break;
	    case CTR_SET: *p  = NewValue; break;
	}
	return OldValue;
    }

