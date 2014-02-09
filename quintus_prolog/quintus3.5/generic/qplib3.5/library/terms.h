/*  File   : terms.h
    Author : Richard A. O'Keefe
    SCCS   : @(#)94/03/03 terms.h	71.1
    Purpose: include file for users of terms.c/library(terms)

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef	IsVar
#include "quintus.h"

#define	Ignore	(void)
typedef long int *TermP;

/*  See the file terms.doc for an explanation of the data structure we use.
    We assume that long int and float both occupy 4 bytes = 32 bits.
*/

#define	IsVar(X)	(*(X) < -2)
#define	IsNonVar(X)	(*(X) >= -2)
#define	IsFloat(X)	(*(X) == -2)
#define	IsInteger(X)	(*(X) == -1)
#define	IsNumber(X)	((unsigned)(*(X)+2) < 2)
#define	IsAtom(X)	(*(X) == 0)
#define	IsSymbol(X)	(*(X) == 0)
#define	IsAtomic(X)	((unsigned)(*(X)+2) < 3)
#define	IsConstant(X)	((unsigned)(*(X)+2) < 3)
#define	IsCompound(X)	(*(X) > 0)
#define	IsSimple(X)	(*(X) <= 0)
#define	IsCallable(X)	(*(X) >= 0)

/*	Use this only when X is known to be callable */
#define	Arity(X)	(*(X))

/*	Use this only when X is known to be callable */
#define	Name(X)		(QP_atom)(*((X)+1))

/*	Use this only when X is known to be callable */
#define	String(X)	QP_string_from_atom(Name(X))

/*	Use this only when X is known to be a variable */
#define	VarNo(X)	(-3 - *(X))

/*	Use this only when X is known to be an integer */
#define	IntegerVal(X)	(*((X)+1))

/*	Use this only when X is known to be a float */
#define	FloatVal(X)	(*((float*)(X) +1))

/*	Use this only when X is known to be a number */
#define	NumberVal(X)	(IsInteger(X) ? IntegerVal(X) : FloatVal(X))



extern	int	QTallo();
extern	int	QTaddr();
extern	void	QTpshA();
extern	void	QTpshF();
extern	void	QTpshI();
extern	void	QTpshV();
extern	void	QTinit();
extern	QP_atom	QTnxtA();
extern	int	QTnxtI();
extern	float	QTnxtF();
extern	TermP	skipterms(), skipterm();
extern	TermP	fprinterm(), printerm();
extern	TermP	termsvars(), termvars();

#endif/*IsVar*/

