%   Package: term_depth
%   Author : Richard A. O'Keefe
%   Updated: 04/15/99
%   Purpose: Find or check the depth of a term.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  Many resolution-based theorem provers impose a Depth Bound on the
    terms they create.  Not the least of the reasons for this is to
    stop infinite loops.  This module exports five predicates:

	term_depth(Term, Depth)
	depth_bound(Term, Bound)

	term_size(Term, Size)
	size_bound(Term, Bound)

	length_bound(List, Bound)

    term_depth calculates the depth of the term, using the definition
	term_depth(Var) = 0
	term_depth(Const) = 0
	term_depth(F(T1,...,Tn)) = 1+max(term_depth(T1),...,term_depth(Tn))

    Mostly, we couldn't care less what the depth of a term is, provided
    it is below some fixed bound.  depth_bound checks that the depth of
    the given term is below the bound (which is assumed to be an integer
    >= 1), without ever finding out what the depth actually is.

    term_size calculates the size of the term, defined to be the number
    of constant and function symbols in it.  (Note that this is a lower
    bound on the size of any term instantiated from it, and that
    instantiating any variable to a non-variable must increase the size.
    This latter property is why we don't count variables as 1.)

	term_size(Var) = 0
	term_size(Const) = 1
	term_size(F(T1,...,Tn)) = 1+term_size(T1)+...+term_size(Tn).

    size_bound(Term, Bound) is true if the size of Term is less than
    or equal to the Bound (assumed to be an integer >= 0).  Note that
    size_bound/2 and depth_bound/2 will always terminate.

    length_bound(List, Bound) is true when List is a list having at
    most Bound elements.  Bound must be instantiated.  If List ends
    with a variable, it will be instantiated to successively longer
    proper lists, up to the length permitted by the Bound.  This was
    added when I noticed that the depth of a list of constants is
    its length, and we already have a length/2, but did not have a
    length_bound.

    In the DEC-10 Prolog library, this was depth.pl, defining
    depth_of_term/2 and depth_bound/2.
*/

:- module(term_depth, [
	depth_bound/2,
	length_bound/2,
	size_bound/2,
	term_depth/2,
	term_size/2
   ]).

:- mode
	depth_bound(+, +),
	    depth_bound(+, +, +),
	length_bound/2,
	size_bound(+, +),
	    size_bound(+, +, -),
		size_bound(+, +, -),
	term_depth(+, ?),
	    term_depth(+, +, +, -),
	term_size(+, ?),
	    term_size(+, +, +, ?).

sccs_id('"@(#)99/04/15 termdepth.pl	76.1"').


%   depth_bound(+Term, +Bound)
%   is true when the term_depth (q.v.) of Term is no greater than Bound,
%   that is, when constructor functions are nested no more than Bound deep.
%   Later variable bindings may invalidate this bound.  To find the
%   (current) depth, use term_depth/2.

depth_bound(Compound, Bound) :-
	nonvar(Compound),
	functor(Compound, _, Arity),
	Arity > 0,
	!,
	Bound > 0,		% this is the test!
	Limit is Bound-1,
	depth_bound(Arity, Compound, Limit).
depth_bound(_, _).


depth_bound(N, Compound, Limit) :-
    (	N =:= 0 -> true
    ;	arg(N, Compound, Arg),
	depth_bound(Arg, Limit),
	M is N-1,
	depth_bound(M, Compound, Limit)
    ).



%   length_bound(?List, +Bound)
%   is true when the length of List is no greater than Bound.  It can be
%   used to enumerate Lists up to the bound.  See also bnd/[2,3,4] in
%   library(morelists).  Its companion is length/2, which is built in.

length_bound([], Bound) :-
	Bound >= 0.
length_bound([_|List], Bound) :-
	Bound > 0,
	Limit is Bound-1,
	length_bound(List, Limit).



%   size_bound(+Term, +Bound)
%   is true when the number of constant and function symbols in Term is
%   (currently) at most Bound.  If Term is non-ground, later variable
%   bindings may invalidate this bound.  To find the (current) size, use
%   term_size/2.

size_bound(Term, Bound) :-
	size_bound(Term, Bound, _).


size_bound(Term, Bound, Left) :-
    (	var(Term) -> Left = Bound
    ;/* nonvar(Term) */
	functor(Term, _, Arity),
	Bound > 0,		% this is the test!
	Limit is Bound-1,
	size_bound(Arity, Term, Limit, Left)
    ).


size_bound(N, Term, Limit, Left) :-
    (	N =:= 0 ->
	Left is Limit
    ;	arg(N, Term, Arg),
	size_bound(Arg, Limit, Limit1),
	M is N-1,
	size_bound(M, Term, Limit1, Left)
    ).



%   term_depth(+Term, ?Depth)
%   calculates the Depth of a Term, using the definition
%	term_depth(Var) = 0
%	term_depth(Const) = 0
%	term_depth(F(T1,...,Tn)) = 1+max(term_depth(T1),...,term_depth(Tn))

term_depth(Compound, Depth) :-
	nonvar(Compound),
	functor(Compound, _, Arity),
	Arity > 0,
	!,
	term_depth(Arity, Compound, 0, ArgDepth),
	Depth is ArgDepth+1.
term_depth(_, 0).


term_depth(N, Compound, SoFar, Depth) :-
    (	N =:= 0 ->
	Depth is SoFar
    ;   arg(N, Compound, Arg),
	term_depth(Arg, ArgDepth),
	(   ArgDepth > SoFar -> Accum is ArgDepth
	;   /* otherwise */     Accum is SoFar
	),
	M is N-1,
	term_depth(M, Compound, Accum, Depth)
    ).



%   term_size(+Term, ?Size)
%   calculates the Size of a Term, defined to be the number of constant and
%   function symbol occurrences in it.

term_size(Term, Size) :-
    (	var(Term) -> Size = 0
    ;/* nonvar(Term) */
	functor(Term, _, Arity),
	term_size(Arity, Term, 1, Size)
    ).


term_size(N, NonVar, SoFar, Size) :-
    (	N =:= 0 ->
	Size is SoFar
    ;   arg(N, NonVar, Arg),
	term_size(Arg, ArgSize),
	Accum is SoFar+ArgSize,
	M is N-1,
	term_size(M, NonVar, Accum, Size)
    ).

