%   Package: varnumbers
%   Author : Richard A. O'Keefe
%   Updated: 31 Mar 1988
%   Purpose: Inverse of numbervars/3

%   The idea was copied from NU Prolog, but the source code is
%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(varnumbers, [
	numbervars/1,
	varnumbers/2,
	varnumbers/3
   ]).

:- use_module(library(types), [
	must_be_integer/3
   ]).

sccs_id('"@(#)88/03/31 varnumbers.pl	26.1"').


/*  There is a built-in predicate called numbervars/3 which makes a term
    ground by binding the variables in it to subterms of the form $VAR(N)
    where N is an integer.  Most of the calls to numbervars/3 look like
	numbervars(Term, 0, _)
    which can be abbreviated to
	numbervars(Term)
    if you use this package.

    varnumbers/3 is a partial inverse to numbervars/3:
	varnumbers(Term, N0, Copy)
    unifies Copy with a copy of Term in which subterms of the form
    $VAR(N) where N is an integer not less than N0 (that is, subterms
    which might have been introduced by numbervars/3 with second argument
    N0) have been consistently replaced by new variables.  Since 0 is the
    usual second argument of numbervars/3, there is also
	varnumbers(Term, Copy)

    This provides a facility whereby a Prolog-like data base can be
    kept as a term.  For example, we might represent append/3 thus:
	Clauses = [
	    (append([], '$VAR'(0), '$VAR'(0)) :- true),
	    (append(['$VAR'(0)|'$VAR'(1), '$VAR'(2), ['$VAR'(0)|'$VAR(3)]) :-
		append('$VAR'(1), '$VAR'(2), '$VAR'(3)))
	]
    and we might access clauses from it by doing
	prove(Goal, Clauses) :-
		member(Clause, Clauses),
		varnumbers(Clause, (Goal:-Body)),
		prove(Goal).

    I'm afraid this has been thrown together in an hour.  More work needs
    to be done to make it easy to follow.  It has, however, been tested.
*/

%   numbervars(+Term)
%   makes Term ground by binding variables to subterms $VAR(N) with
%   values of N ranging from 0 up.

numbervars(Term) :-
	numbervars(Term, 0, _).


%   varnumbers(+Term, ?Copy)
%   succeeds when Term was a term producing by calling numbervars(Term)
%   and Copy is a copy of Term with such subterms replaced by variables.

varnumbers(Term, Copy) :-
	varnumbers(Term, 0, Copy).

%   varnumbers(+Term, +N0, ?Copy)
%   succeeds when Term was a term produced by calling
%	numbervars(Term, N0, N)
%   {so that all subterms $VAR(X) have integer(X), X >= N0}
%   and Copy is a copy of Term with such subterms replaced by variables.

varnumbers(Term, N0, Copy) :-
	(   integer(N0) ->
	    B0 is N0-1,
	    max_var_number(Term, B0, B1),
	    Nvars is B1-B0,		% number of variables to be created
	    (   Nvars >= 256 ->
		make_map(Nvars, Map),
		apply_map(Term, N0, Map, Copy)
	    ;	Nvars > 0 ->
		functor(Map, '', Nvars),
		apply_small_map(Term, B0, Map, Copy)
	    ;	Nvars =:= 0 ->
		Copy = Term
	    )
	;   must_be_integer(N0, 2, varnumbers(Term,N0,Copy))
	).


%.  max_var_number(+Term, +B0, -B)

max_var_number('$VAR'(N), B0, B) :- integer(N), !,
	( N > B0 -> B = N ; B = B0 ).
max_var_number(Var, B, B) :- var(Var), !.
max_var_number(Term, B0, B) :-
	functor(Term, _, N),
	max_var_number(N, Term, B0, B).

max_var_number(N, Term, B0, B) :-
	(   N =:= 0 -> B = B0
	;   M is N-1,
	    arg(N, Term, Arg),
	    max_var_number(Arg, B0, B1),
	    max_var_number(M, Term, B1, B)
	).


%.  apply_small_map(+Term, +B0, +Map, -Copy)

apply_small_map('$VAR'(N), B0, Map, Var) :-
	integer(N),
	I is N-B0,
	I > 0,
	!,
	arg(I, Map, Var).
apply_small_map(Var, _, _, Copy) :- var(Var), !,
	Copy = Var.
apply_small_map(Term, B0, Map, Copy) :-
	functor(Term, F, N),
	functor(Copy, F, N),
	apply_small_map(N, Term, B0, Map, Copy).

apply_small_map(N, Term, B0, Map, Copy) :-
	(   N =:= 0 -> true
	;   M is N-1,
	    arg(N, Term, Term_N),
	    arg(N, Copy, Copy_N),
	    apply_small_map(Term_N, B0, Map, Copy_N),
	    apply_small_map(M, Term, B0, Map, Copy)
	).


%.  apply_map(+Term, +N0, +Map, -Copy)

apply_map('$VAR'(N), N0, Map, Var) :-
	integer(N),
	I is N-N0,
	I >= 0,
	!,
	map_get(Map, I, Var).
apply_map(Var, _, _, Copy) :- var(Var), !,
	Copy = Var.
apply_map(Term, N0, Map, Copy) :-
	functor(Term, F, N),
	functor(Copy, F, N),
	apply_map(N, Term, N0, Map, Copy).

apply_map(N, Term, N0, Map, Copy) :-
	(   N =:= 0 -> true
	;   M is N-1,
	    arg(N, Term, Term_N),
	    arg(N, Copy, Copy_N),
	    apply_map(Term_N, N0, Map, Copy_N),
	    apply_map(M, Term, N0, Map, Copy)
	).


make_map(N, Map) :-
    (	N < 256 ->
	functor(Map, '', N)
    ;	A is (N+7)>>3,
	make_map(A, M1), make_map(A, M2),
	make_map(A, M3), make_map(A, M4),
	make_map(A, M5), make_map(A, M6),
	make_map(A, M7), make_map(A, M8),
	Map = +(M1,M2,M3,M4,M5,M6,M7,M8)
    ).

map_get(Map, N, Var) :-
	functor(Map, F, _),
	map_get(F, Map, N, Var).

map_get(+, Map, N, Var) :-
	I is (N/\7) + 1,
	M is (N>>3),
	arg(I, Map, Sub),
	map_get(Sub, M, Var).
map_get('', Map, N, Var) :-
	I is N+1,
	arg(I, Map, Var).

