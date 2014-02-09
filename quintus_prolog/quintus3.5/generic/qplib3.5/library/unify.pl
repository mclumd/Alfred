%   Module : unify
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Purpose: sound unification

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(unify, [
	unify/2
   ]).
:- use_module(library(occurs), [
	free_of_var/2			% implements the occurs check.
   ]).

sccs_id('"@(#)89/08/29 unify.pl    33.1"').


%   unify(X, Y)
%   is true when the two terms X and Y unify *with* the occurs check.

unify(X, Y) :-
    (	nonvar(X), nonvar(Y) ->
	functor(X, F, N),
	functor(Y, F, N),
	unify(N, X, Y)
    ;   nonvar(X) /* var(Y) */ ->
	free_of_var(Y, X),		% Y does not occur in X
	Y = X
    ;   nonvar(Y) /* var(X) */ ->
	free_of_var(X, Y),		% X does not occur in Y
	X = Y
    ;	/* var(X), var(Y) */
	X = Y				% unify(X, X) despite X
    ).					% occurring in X!

unify(N, X, Y) :-
    (	N < 1 -> true
    ;	arg(N, X, Xn),
	arg(N, Y, Yn),
	unify(Xn, Yn),
	M is N-1,
	unify(M, X, Y)
    ).

