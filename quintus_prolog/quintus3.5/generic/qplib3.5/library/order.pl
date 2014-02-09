%   Package: order
%   Author : Richard A. O'Keefe
%   Updated: 05 Jan 1993
%   Defines: comparison predicates with usual argument order.

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(order, [
	number_order/3,
	ordset_order/3,
	set_order/3,
	term_order/3
   ]).
:- use_module(library(basics), [
	member/2			% for set_order/3
   ]).

sccs_id('"@(#)93/01/05 order.pl	66.1"').

/*  The usual convention for Prolog operations is INPUTS before OUTPUTS.
    The built-in predicate compare/3 violates this.  We're sorry about
    that, but that's the way it was in DEC-10 Prolog, and Quintus isn't
    in the business of breaking other people's working code.  What we
    *can* do is provide an additional interface.

    We suggest that you reserve predicate names "compare*" for things
    which (perhaps after closure on initial arguments) have the same
    argument order as compare/3.  Names "<type>_order" are recommended
    for predicates following the inputs-before-outputs convention.
    Here are four.  Please suggest more.

    The convention I have adopted here is that if the first two
    arguments are not comparable, the predicate fails.  This is done for
    sets (unordered and ordered), and _should_ be done for floats.
*/

%   number_order(+X, +Y, ?R)
%   is true when X and Y are numbers and R is <, =, or > according as
%   X < Y, X =:= Y, or X > Y.  Note that if X =:= Y, it does not follow
%   that X=Y; one of them might be a float and the other an integer, or
%   one of them might be +0.0 and the other -0.0.  {This version gets
%   IEEE "unordered" comparisons wrong--it should fail quietly.}

number_order(X, Y, R) :-
	number(X), number(Y),
	( X < Y -> R = <
	; X > Y -> R = >
	;          R = =
	).


%   term_order(+X, +Y, ?R)
%   is true when X and Y are arbitrary terms, and R is <, =, or > according
%   as X @< Y, X == Y, or X @> Y.  This is the same as compare/3, except
%   for the argument order.

term_order(X, Y, R) :-
	compare(R, X, Y).



%   set_order(+Xs, +Ys, ?R)
%   is true when R is <, =, or > according as Xs is a subset of Ys,
%   equivalent to Ys, or a superset of Ys.  Xs and Ys are lists representing
%   sets in the style of library(sets), where this will shortly move.

set_order(Xs, Ys, R) :-
	(   member(X, Xs), \+ member(X, Ys) ->
	    /* Xs has a member not in Ys, so "=" and "<" are ruled out */
	    Mask1 = 2'001
	;   /* Xs has no elements not in Ys, so ">" is ruled out */
	    Mask1 = 2'110
	),
	(   member(Y, Ys), \+ member(Y, Xs) ->
	    /* Ys has a member not in Xs, so "=" and ">" are ruled out */
	    Mask2 is Mask1 /\ 2'100
	;   /* Ys has no elements not in Xs, so "<" is ruled out */
	    Mask2 is Mask1 /\ 2'011
	),
	(   Mask2 /\ 2'100 =\= 0 -> R = <
	;   Mask2 /\ 2'001 =\= 0 -> R = >
	;   Mask2 /\ 2'010 =\= 0 -> R = =
	).


%   ordset_order(+Xs, +Ys, ?R)
%   is true when R is <, =, or > according as Xs is a subset of Ys,
%   equal to Ys, or a superset of Ys.  Xs and Ys are ordered lists which
%   represent sets in the style of library(ordsets).

ordset_order(Xs, Ys, R) :-
	ordset_order(Xs, Ys, 2'111, R).

ordset_order([], Ys, Mask0, Mask) :-
	ordset_order1(Ys, Mask0, Mask).
ordset_order([X|Xs], Ys, Mask0, Mask) :-
	ordset_order1(Ys, X, Mask0, Mask, Xs).

ordset_order1([], Mask, R) :-
	(   Mask /\ 2'100 =\= 0 -> R = <
	;   Mask /\ 2'001 =\= 0 -> R = >
	;   Mask /\ 2'010 =\= 0 -> R = =
	).
ordset_order1([_|_], Mask, <) :-
	Mask /\ 2'100 =\= 0.

ordset_order1([], _, Mask, >, _) :-
	Mask /\ 2'001 =\= 0.
ordset_order1([Y|Ys], X, Mask, RR, Xs) :-
	compare(R, X, Y),
	ordset_order12(R, Ys, Mask, RR, Xs, X, Y).

ordset_order12(=, Ys, Mask, R, Xs, _, _) :-
	ordset_order(Xs, Ys, Mask, R).
ordset_order12(<, Ys, Mask0, R, Xs, _, Y) :-
	Mask1 is Mask0 /\ 2'001,
	ordset_order2(Xs, Y, Mask1, R, Ys).
ordset_order12(>, Ys, Mask0, R, Xs, X, _) :-
	Mask1 is Mask0 /\ 2'100,
	ordset_order1(Ys, X, Mask1, R, Xs).

ordset_order2([], _, Mask, <, _) :-
	Mask /\ 2'100 =\= 0.
ordset_order2([X|Xs], Y, Mask, RR, Ys) :-
	compare(R, X, Y),
	ordset_order12(R, Ys, Mask, RR, Xs, X, Y).

