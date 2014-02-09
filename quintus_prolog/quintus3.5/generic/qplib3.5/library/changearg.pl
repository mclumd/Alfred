%   Module : change_arg
%   Author : Richard A. O'Keefe
%   Updated: 17 Dec 1987
%   Purpose: use terms as one-dimensional arrays

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(change_arg, [
	change_arg/4,
	change_arg/5,
	change_arg0/4,
	change_arg0/5,
	change_functor/5,
	change_path_arg/4,
	change_path_arg/5,
	swap_args/4,
	swap_args/6
   ]).
:- use_module(library(samefunctor), [
	same_functor/3
   ]).
:- mode
	change_arg(+, ?, ?, ?),
	change_arg(+, ?, ?, ?, ?),
	change_arg0(+, ?, ?, ?),
	change_arg0(+, ?, ?, ?, ?),
	change_functor(?, ?, ?, ?, ?),
	change_path_arg(+, ?, ?, ?),
	change_path_arg(+, ?, ?, ?, ?),
	swap_args(+, +, ?, ?),
	swap_args(+, +, ?, ?, ?, ?),
	'change arg'(+, +, +),
	'change arg'(+, +, +, +),
	'change arg'(+, +, +, +, +),
	'gen change'(+, +, ?, -, +, ?).

sccs_id('"@(#)87/12/17 changearg.pl	21.1"').


/*  The predicates in this file enable one to treat Prolog terms as
    one-dimensional vectors.  Currently, these vectors cannot have more
    than 255 elements.

	change_arg lets you replace an element
	swap_args  lets you swap two elements

    The cost of either operation is O(N), where the term has N
    arguments.  See library(logarr) for a better way of handling
    updatable arrays.

    Several of these predicates are multidirectional.  Indeed, the
    only predicates which cannot solve for argument positions are
    now swap_args/[4,6].  For example, (OldTerm,NewTerm) may not
    both be variables in change_arg/[4,5], but there is no other
    restriction.  This multidirectionality is courtesy of
    same_functor/3, which exists to make multidirectional term-
    hacking code easier to write.  The argument number enumeration
    functionality uses a cut-down version of between/3 fused with
    arg/3, 'gen change'/6.
*/



%   change_arg(?K, ?OldTerm, ?NewTerm, ?NewArg)
%   is true when OldTerm and NewTerm are equal except that the
%   Kth argument of NewTerm is NewArg.  Either OldTerm or
%   NewTerm should be instantiated, but there is no other
%   restriction.  In particular, K may be a variable.

change_arg(K, OldTerm, NewTerm, NewArg) :-
	change_arg(K, OldTerm, _, NewTerm, NewArg).


%   change_arg(?K, ?OldTerm, ?OldArg, ?NewTerm, ?NewArg)
%   is true when OldTerm and NewTerm are equal except that the
%   Kth argument of OldTerm is OldArg and the Kth argument of
%   NewTerm is NewArg.  This can be used all the ways that
%   change_arg/4 can, in particular,
%	change_arg(K, O, X, N, Y) and
%	change_arg(K, N, Y, O, X)
%   have exactly the same effect.  To add one to an element of
%   an "array", one might for example write
%	change_arg(K, OldArray, X, NewArray, Y),
%	plus(X, 1, Y)
%   which is bidirectional.

change_arg(K, OldTerm, OldArg, NewTerm, NewArg) :-
	integer(K),
	!,
	same_functor(OldTerm, NewTerm, N),
	N > 0,
	arg(K, OldTerm, OldArg),
	arg(K, NewTerm, NewArg),
	'change arg'(N, K, OldTerm, NewTerm).
change_arg(K, OldTerm, OldArg, NewTerm, NewArg) :-
	var(K),
	!,
	same_functor(OldTerm, NewTerm, N),
	N > 0,
	'gen change'(N, OldTerm, OldArg, K, NewTerm, NewArg).



%   'gen change' backtracks K down N, trying to replace each
%   argument in turn.  As it walks from right to left, it
%   fills in the arguments to the right of K, and whenever it
%   succeeds in replacing a Kth argument it calls 'change arg'
%   to fill in the arguments to the left.  Backtracking will
%   undo the assignments to the left, but not the assignments
%   to the right, so the cost of backtracking over all the
%   results is O(N*N) calls to arg.

'gen change'(1, OldTerm, OldArg, 1, NewTerm, NewArg) :- !,
	arg(1, OldTerm, OldArg),
	arg(1, NewTerm, NewArg).
'gen change'(N, OldTerm, OldArg, N, NewTerm, NewArg) :-
	arg(N, OldTerm, OldArg),
	arg(N, NewTerm, NewArg),
	M is N-1,
	'change arg'(M, OldTerm, NewTerm).
'gen change'(N, OldTerm, OldArg, K, NewTerm, NewArg) :-
	arg(N, OldTerm, SameArg),
	arg(N, NewTerm, SameArg),
	M is N-1,
	'gen change'(M, OldTerm, OldArg, K, NewTerm, NewArg).



%   change_arg0(?K, ?OldTerm, ?NewTerm, ?NewArg)
%   is like change_arg(K, OldTerm, NewTerm, NewArg), except
%   that K=0 is allowed, in which case the principal function
%   symbol is changed.  Do not use this in new programs; use
%   change_arg/4 or change_functor/5 directly.

change_arg0(K, OldTerm, NewTerm, NewArg) :-
	change_arg0(K, OldTerm, _, NewTerm, NewArg).


%   change_arg0(?K, ?OldTerm, ?OldArg, ?NewTerm, ?NewArg)
%   is like change_arg(K, OldTerm, OldArg, NewTerm, NewArg)
%   except that K=0 is allowed, in which case the principal function
%   symbol is changed.  Do not use this in new programs; use
%   change_arg/5 or change_functor/5 directly.   The order in which
%   values for K are enumerated is NOT DEFINED.

change_arg0(K, OldTerm, OldArg, NewTerm, NewArg) :-
	var(K),
	!,
	(   K = 0,
	    change_functor(OldTerm, OldArg, NewTerm, NewArg, _)
	;   same_functor(OldTerm, NewTerm, N),
	    'gen change'(N, OldTerm, OldArg, K, NewTerm, NewArg)
	).
change_arg0(K, OldTerm, OldArg, NewTerm, NewArg) :-
	integer(K),
	(   K =:= 0 ->
	    change_functor(OldTerm, OldArg, NewTerm, NewArg, _)
	;   same_functor(OldTerm, NewTerm, N),
	    arg(K, OldTerm, OldArg),
	    arg(K, NewTerm, NewArg),
	    'change arg'(N, K, OldTerm, NewTerm)
	).



%   change_functor(?OldTerm, ?OldSymbol, ?NewTerm, ?NewSymbol, ?Arity)
%   is true when OldTerm and NewTerm are identical terms, except that
%   the functor of OldTerm is OldSymbol/Arity, and
%   the functor of NewTerm is NewSymbol/Arity.
%   This is similar to same_functor/3 in some respects, such as the
%   fact that any of the arguments can be solved for.
%   If OldTerm and NewSymbol are instantiated,
%   or NewTerm and OldSymbol are instantiated,
%   or NewSymbol, OldSymbol, and Arity are instantiated,
%   that is enough information to proceed.
%   Note that OldSymbol or NewSymbol may be a number, in which case
%   Arity must be 0.

change_functor(OldTerm, OldSymbol, NewTerm, NewSymbol, Arity) :-
	(   number(OldSymbol) ->
	    Arity = 0,
	    OldTerm = OldSymbol,
	    NewTerm = NewSymbol,
	    atomic(NewTerm)
	;   number(NewSymbol) ->
	    Arity = 0,
	    NewTerm = NewSymbol,
	    OldTerm = OldSymbol,
	    atomic(OldTerm)
	;   %   at this point, we know OldSymbol and NewSymbol are not
	    %   numbers.  They should therefore be atoms or variables.
	    (	nonvar(OldTerm), atom(NewSymbol) ->
		functor(OldTerm, OldSymbol, Arity),
		functor(NewTerm, NewSymbol, Arity)
	    ;	nonvar(NewTerm), atom(OldSymbol) ->
		functor(NewTerm, NewSymbol, Arity),
		functor(OldTerm, OldSymbol, Arity)
	    ;   integer(Arity), Arity >= 0,
		atom(OldSymbol), atom(NewSymbol) ->
		functor(OldTerm, OldSymbol, Arity),
		functor(NewTerm, NewSymbol, Arity)
	    ;	%  this error message should be made more precise.
		format(user_error, '~N! Bad arguments to ~q~n! Goal: ~q~n', [
		    change_functor/5,
		    change_functor(OldTerm,OldSymbol,NewTerm,NewSymbol,Arity)]),
		fail
	    ),
	    'change arg'(Arity, OldTerm, NewTerm)
	).




%   swap_args(+First, +Second, ?OldTerm, ?NewTerm)
%   is true when OldTerm and NewTerm are identical except that
%   the First argument of OldTerm is the Second argument of NewTerm
%   and vice versa.  It is bidirectional, but First and Second
%   *must* be bound to integers; swap_args will not find them.

swap_args(First, Second, OldTerm, NewTerm) :-
	swap_args(First, Second, OldTerm, _, NewTerm, _).


%   swap_args(+First, +Second, ?OldTerm, ?OldArg, ?NewTerm, ?NewArg)
%   is true when OldArg/NewArg are the First/Second arguments
%   of OldTerm and the Second/First arguments of NewTerm.
%   This is bidirectional, but First and Second *must* be
%   bound to integers; swap_args will not find them.

swap_args(First, Second, OldTerm, OldArg, NewTerm, NewArg) :-
	same_functor(OldTerm, NewTerm, N),
	arg(First,  OldTerm, OldArg),
	arg(Second, OldTerm, NewArg),
	arg(First,  NewTerm, NewArg),
	arg(Second, NewTerm, OldArg),
	(   First > Second -> 'change arg'(N, First, Second, OldTerm, NewTerm)
	;   First < Second -> 'change arg'(N, Second, First, OldTerm, NewTerm)
	;   OldTerm = NewTerm
	).



%   'change arg'(+N, +OldTerm, +NewTerm)
%   is true when the first N arguments of OldTerm and NewTerm
%   are equal.  We switch to this from 'change arg'/4 when
%   the Kth argument has been ignored.  That is for efficiency.
%   Note that N = 0 is possible.

'change arg'(0, _, _) :- !.
'change arg'(N, OldTerm, NewTerm) :-
	arg(N, OldTerm, Arg),
	arg(N, NewTerm, Arg),
	M is N-1,
	'change arg'(M, OldTerm, NewTerm).



%   'change arg'(+N, +K, +OldTerm, +NewTerm)
%   is true when the first N arguments of OldTerm and NewTerm are
%   equal, ignoring the Kth argument (we know that 1 =< K =< N).
%   For efficiency, we switch to this from 'change arg'/5 when
%   the First argument has been ignored.

'change arg'(0, _, _, _) :- !.
'change arg'(K, K, OldTerm, NewTerm) :- !,
	M is K-1,
	'change arg'(M, OldTerm, NewTerm).
'change arg'(N, K, OldTerm, NewTerm) :-
	arg(N, OldTerm, Arg),
	arg(N, NewTerm, Arg),
	M is N-1,
	'change arg'(M, K, OldTerm, NewTerm).



%   'change arg'(+N, +First, +Second, +OldTerm, +NewTerm)
%   is true when the first N arguments of OldTerm and NewTerm are
%   equal, ignoring the First and Second arguments.  (We know
%   that 1 =< Second < First =< N).

'change arg'(0, _, _, _, _) :- !.
'change arg'(First, First, Second, OldTerm, NewTerm) :- !,
	M is First-1,
	'change arg'(M, Second, OldTerm, NewTerm).
'change arg'(N, First, Second, OldTerm, NewTerm) :-
	arg(N, OldTerm, Arg),
	arg(N, NewTerm, Arg),
	M is N-1,
	'change arg'(M, First, Second, OldTerm, NewTerm).



%   change_path_arg(?Path, ?OldTerm, ?NewTerm, ?NewSubTerm)
%   is true when OldTerm and NewTerm are identical except at the
%   position identified by Path, where NewTerm has NewSubTerm.
%   change_path_arg/4 is to change_arg/4 as path_arg/3 is to arg/3.
%   This predicate used to be called replace/4 in the Dec-10 library.
%   change_path_arg([1,1,2,2], 2*x^2+2*x+1=0, y, 2*x^2+2*y+1=0) is an example.
%   It can be used lots of ways around, like change_arg/4.
%   The Path can be generated, but OldTerm or NewTerm should then be ground.
 
change_path_arg(Path, OldTerm, NewTerm, NewSubTerm) :-
	change_path_arg(Path, OldTerm, _, NewTerm, NewSubTerm).


%   change_path_arg(?Path, ?OldTerm, ?OldSubTerm, ?NewTerm, ?NewSubTerm)
%   is true when OldTerm and NewTerm are identical except at the
%   position identified by Path, where OldTerm has OldSubTerm and
%   NewTerm has NewSubTerm.  Note that, like change_arg/5, it is
%   symmetric in the last four arguments:
%	change_path_arg(Path, O, X, N, Y)	and
%	change_path_arg(Path, N, Y, O, X)
%   have exactly the same effect.  The Path can be generated, but in
%   that case OldTerm or NewTerm should be ground.
%
%   What is this for?
%
%   Suppose you have a set of rewrite rules rewrite_rule(Lhs,Rhs)
%   which you want exhaustively applied to a term.  You could write
%	waterfall(Expr, Final) :-
%		path_arg(Path, Expr, Lhs),
%		rewrite_rule(Lhs, Rhs),
%		change_path_arg(Path, Expr, Modified, Rhs),
%		!,
%		waterfall(Modified, Final).
%	waterfall(Expr, Expr).

change_path_arg([], OldTerm, OldTerm, NewTerm, NewTerm).
change_path_arg([Head|Tail], OldTerm, OldSubTerm, NewTerm, NewSubTerm) :-
	integer(Head),
	!,
	same_functor(OldTerm, NewTerm, N),
	arg(Head, OldTerm, OldArg),
	arg(Head, NewTerm, NewArg),
	'change arg'(N, Head, OldTerm, NewTerm),
	change_path_arg(Tail, OldArg, OldSubTerm, NewArg, NewSubTerm).
change_path_arg([Head|Tail], OldTerm, OldSubTerm, NewTerm, NewSubTerm) :-
	var(Head),
	!,
	same_functor(OldTerm, NewTerm, N),
	N > 0,
	'gen change'(N, OldTerm, OldArg, Head, NewTerm, NewArg),
	change_path_arg(Tail, OldArg, OldSubTerm, NewArg, NewSubTerm).

