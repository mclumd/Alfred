%   Package: vsets
%   Author : Richard A. O'Keefe
%   Updated: 06 Sep 1990
%   Purpose: 

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(vsets, [
	make_vset/2,			% Integer -> Vset
	vset_member/2,			% Integer x Vset ->
	vset_del_element/2,		% Integer x Vset ->
	intersect_vsets/2,		% Vset x Vset ->
	portray_vset/1			% Vset ->
   ]).

sccs_id('"@(#)90/09/06 vsets.pl	56.2"').

/*  This package implements small sets of non-negative integers.
    In this version, a set may have up to 254 elements (because a
    compound term may have up to 255 elements).  It would not be
    hard to lift this limit, and if this ever becomes a supported
    package that will be done.

    The point of this package is to have a representation for
    sets where unifying S1 with S2
    -- has the result represent the intersection of S1 and S2
    -- fails if the intersection would be empty.
    The idea is that you are carrying around a set of constraints
    and you want to combine these constraints fast, and you only
    want to pursue a particular branch of the search tree while
    there is at least one element left by the constraints.  It
    is particularly useful for "features" in grammars.

    Richard A. O'Keefe got this trick from
    Fernando C. N. Pereira who figured it out after
    Alain Colmerauer told him it could be done.

    The idea is that you represent a subset of {1..N} by a term
	vset(X_0, X_1, ..., X_N)
    such that
	X_0 = 0		\ any two distinct constants
	X_N = 1		/ may be used for X_0 and X_N
	X_i = X_{i-1}	if i is *NOT* in the set.

    That is, X_i and X_{i-1} are *different* (\==) if i IS in the set,
    or they are the same (==) if i is NOT in the set.

    make_vset(+N, -Vset) makes a vset representing {1..N}, so all the
    arguments of the term are different.

    vset_member(?N, +Vset) is true when N is an integer which is
    (currently) in Vset.

    vset_del_element(+N, +Vset) succeeds when N is in range for Vset
    and is no longer in Vset (it need not have been in Vset before),
    and Vset\N is still not empty.

    Think of vset_del_element/2 as "closing a swtich".  When the last
    switch in the series is closed, Prolog tries to unify the 0 and 
    the 1, and that can't be done, so the attempt fails.

    intersect_vsets(+Vset1, +Vset2) just unifies the two Vsets.  The
    switches which are closed in the result are the union of the
    switches which are closed in the two Vsets (which are identical
    afterwards), which is to say that the result represents the
    intersection.  If the intersection is empty, the call fails.

    You can use the same trick to for unions, where sets start out
    empty, may have elements added, but may not be the whole set.
*/


make_vset(M, Set) :-
	integer(M), M >= 1,
	N is M+1,
	functor(Set, vset, N),
	arg(1, Set, 0),
	arg(N, Set, 1).


vset_member(I, Set) :-
	functor(Set, vset, N),
	(   integer(I) ->
	    I >= 1, I < N
	;   var(I) ->
	    'in vset'(N, I)
	),
	J is I+1,
	arg(I, Set, ArgI),
	arg(J, Set, ArgJ),
	ArgI \== ArgJ.

'in vset'(N, I) :-
	(   N > 2 ->
	    M is N-1,
	    ( I = M ; 'in vset'(M, I) )
	;   N =:= 2 ->
	    I = 1
	).
  

vset_del_element(I, Set) :-
	functor(Set, vset, N),
	(   integer(I) ->
	    I >= 1, I < N
	;   var(I) ->
	    'in vset'(N, I)
	),
	J is I+1,
	arg(I, Set, Arg),
	arg(J, Set, Arg).


intersect_vsets(X, X).


portray_vset(Term) :-
	functor(Term, vset, N),
	write('vset'),
	portray_vset(1, N, Term, 0'{).

portray_vset(I, N, Term, Char) :-
	(   I =:= N -> put(0'})
	;   J is I+1,
	    arg(I, Term, ArgI),
	    arg(J, Term, ArgJ),
	    (   ArgI == ArgJ ->
		portray_vset(J, N, Term, Char)
	    ;   put(Char),
		write(I),
		portray_vset(J, N, Term, 0',)
	    )
	).

