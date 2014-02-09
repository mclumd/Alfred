%   Package: length
%   Author : Richard A. O'Keefe
%   Updated: 25 Oct 1990
%   Purpose: chopping a list into pieces by length.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(length, [
	append_length/3,			% List x List x Length
	append_length/4,			% List x List x List x Length
	prefix_length/3,			% Whole x Part x Length
	proper_prefix_length/3,			% Whole x Part x Length
	proper_suffix_length/3,			% Whole x Part x Length
	rotate_list/2,				% List x List
	rotate_list/3,				% Integer -> (List x List)
	suffix_length/3,			% Whole x Part x Length
	sublist/3,				% Whole x Part x Length
	sublist/4,				% Whole x Part x Length^2
	sublist/5				% Whole x Part x Length^3
   ]).
:- use_module(library(lists), [
	proper_length/2,
	same_length/3
   ]),
   use_module(library(types), [
	should_be/4
   ]).


/*  The predicates in this file were inspired by some written by
    Edouard Lagache for Automata Design Associates Prolog.  The
    file in question was called stdlist.pro.  No aspect of this
    code imitates any aspect of his code, but it grew out of a
    detailed criticism of said code.

    Most of the predicates in this package can be seen as a
    conjunction of append/3 or some predicate in library(listparts)
    with length/2.  The general convention is that the arguments
    are identical to those of the original in library(listparts)
    with the addition of a new last parameter, the Length of interest.
    The names of the predicates are formed by adding the suffix
    '_length' to the name of the original.

    It may help you when reading this code to note that the general
    pattern is to call <foo>_find when Length is a variable, or to
    call <foo>_make when Length is suitably instantiated.  I take
    the attitude that it is better to make life easier for the user
    of a package by making interfaces as logical as possible than
    to make life easier for me by just implementing half of something.

    The first draft of this package didn't have any error reporting,
    but since {proper_,}suffix_length/3 don't really make sense when
    the List is not proper, I decided to check and report that, and
    having imported one thing from library(types), it seemed good to
    me to follow the precedent set in nth{0,1}/[3,4] and report bad
    Length arguments too.  Why not?

    One thing which may seem odd to you is the placement of the
    Length parameter.  Why does it come last, when it is usually
    an input?  This takes some justifying.  I would point out
    that length/2 has the Length parameter last, and the
    "substring" predicates in library(strings) have all their
    length parameters last.  A selector argument should indeed
    come first, but the Length arguments do not indicate the
    location of an *element* of the Whole list, but the length
    of a sublist (or whatever) of the Whole, and we seem to have
    ended up with a convention of putting such arguments last.
    I have gone to some effort to make these predicates act like
    logical relations, so no argument is to be regarded as more
    of an input or an output than the others.  You can call any
    of these predicates with the Length unbound, and it will work.

    Note that "proper" does not mean "non-empty":  X is a proper
    prefix (suffix) of Y if X is a prefix (suffix) of Y,
    *other than Y itself*.  [] is a proper prefix of [a].

    See also the predicates
	nth0(Index, List, Element)
	nth0(Index, List, Element, Residue)
	nth1(Index, List, Element)
	nth1(Index, List, Element, Residue)
    in library(lists).  They may eventually move here.
*/
sccs_id('"@(#)90/10/25 length.pl	58.1"').



%   length(?List, ?Length)
%   is true when List is a list and Length is a non-negative integer
%   and List has exactly Length elements.  The normal use of this is
%   to find the Length of a given List, but it can be used any way
%   around provided that
%	Length is instantiated, or
%	List   is a proper list.
%   The other predicates in this file are derived pretty much directly
%   from this one.  length/2 is actually built into Quintus Prolog,
%   but if it weren't here's how we'd write it:
/*
length(List, Length) :-
	(   var(Length) ->
	    length_find(List, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    length_make(Length, List)
	;   should_be(integer, Length, 2, length(List,Length))
	).

length_find([], N, N).
length_find([_|List], N0, N) :-
	N1 is N0+1,
	length_find(List, N1, N).

length_make(0, List) :- !,
	List = [].
length_make(N0, [_|List]) :-
	N1 is N0-1,
	length_make(N1, List).
*/



%   append_length(?Prefix, ?Suffix, ?List, ?Length)
%   is true when
%	append(Prefix, Suffix, List) &
%	length(Prefix, Length).
%   The normal use of this is to split a List into a Prefix of
%   a given Length and the corresponding Suffix, but it can be
%   used any way around provided that
%	Length is instantiated, or
%	Prefix is a proper list, or
%	List   is a proper list.

append_length(Prefix, Suffix, List, Length) :-
	(   var(Length) ->
	    append_find(Prefix, Suffix, List, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    append_make(Length, Prefix, Suffix, List)
	;   should_be(integer, Length, 4,
		append_length(Prefix,Suffix,List,Length))
	).

append_find([], List, List, N, N).
append_find([Head|Prefix], Suffix, [Head|List], N0, N) :-
	N1 is N0+1,
	append_find(Prefix, Suffix, List, N1, N).

append_make(0, Prefix, Suffix, List) :- !,
	Prefix = [], Suffix = List.
append_make(N, [Head|Prefix], Suffix, [Head|List]) :-
	M is N-1,
	append_make(M, Prefix, Suffix, List).



%   append_length(?Suffix, ?List, ?Length)
%   is true when there exists a list Prefix such that
%   append_length(Prefix, Suffix, List, Length) is true.
%   When you don't want to know the Prefix, you should call this
%   predicate, because it doesn't construct the Prefix argument,
%   which append_length/4 would do.

append_length(Suffix, List, Length) :-
	(   var(Length) ->
	    append_find(Suffix, List, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    append_make(Length, Suffix, List)
	;   should_be(integer, Length, 3, append_length(Suffix,List,Length))
	).

append_find(List, List, N, N).
append_find(Suffix, [_|List], N0, N) :-
	N1 is N0+1,
	append_find(Suffix, List, N1, N).

append_make(0, Suffix, List) :- !,
	Suffix = List.
append_make(N, Suffix, [_|List]) :-
	M is N-1,
	append_make(M, Suffix, List).



%   prefix_length(?List, ?Prefix, ?Length)
%   is true when
%	prefix(List, Prefix) &
%	length(Prefix, Length).
%   The normal use of this is to find the first Length elements of
%   a given List, but it can be used any way around provided that
%	Length is instantiated, or
%	Prefix is a proper list, or
%	List   is a proper list.
%   It is identical in effect to append_length(Prefix, _, List, Length).

prefix_length(List, Prefix, Length) :-
	(   var(Length) ->
	    prefix_find(Prefix, List, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    prefix_make(Length, Prefix, List)
	;   should_be(integer, Length, 3, prefix_length(List,Prefix,Length))
	).

prefix_find([], _, N, N).
prefix_find([Head|Prefix], [Head|List], N0, N) :-
	N1 is N0+1,
	prefix_find(Prefix, List, N1, N).

prefix_make(0, Prefix, _) :- !,
	Prefix = [].
prefix_make(N, [Head|Prefix], [Head|List]) :-
	M is N-1,
	prefix_make(M, Prefix, List).



%   proper_prefix_length(?List, ?Prefix, ?Length)
%   is true when
%	proper_prefix(List, Prefix) &
%	length(Prefix, Length).
%   The normal use of this is to find the first Length elements of
%   a given List, but it can be used any way around provided that
%	Length is instantiated, or
%	Prefix is a proper list, or
%	List   is a proper list.
%   It is logically equivalent to prefix(Prefix, List, Length), Length > 0.

proper_prefix_length(List, Prefix, Length) :-
	(   var(Length) ->
	    append_find(Prefix, Suffix, List, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    append_make(Length, Prefix, Suffix, List)
	;   should_be(integer, Length, 3,
		proper_prefix_length(List,Prefix,Length))
	),
	Suffix = [_|_].



%   suffix_length(+List, ?Suffix, ?Length)
%   is true when
%	suffix(List, Suffix) &
%	length(Suffix, Length).
%   The normal use of this is to return the last Length elements of
%   a given List.  For this to be sure of termination,
%	List must be a proper list.
%   The predicate suffix/2 in library(listparts) has the same requirement.
%   If Length is instantiated or Suffix is a proper list, this predicate
%   is determinate.

suffix_length(List, Suffix, Length) :-
	proper_length(List, Bound),
	!,
	(   var(Length) ->
	    (   proper_length(Suffix, Length) ->
		suffix_make(Length, Suffix, List, Bound)
	    ;   suffix_find(Suffix, List, Bound, Length)
	    )
	;   integer(Length) ->
	    Length >= 0, Length =< Bound,
	    suffix_make(Length, Suffix, List, Bound)
	;   should_be(integer, Length, 3, suffix_length(List,Suffix,Length))
	).
suffix_length(List, Suffix, Length) :-
	should_be(proper_list, List, 1, suffix_length(List,Suffix,Length)).


suffix_find(List, List, N, N).
suffix_find(Suffix, [_|List], N0, N) :-
	N1 is N0-1,
	suffix_find(Suffix, List, N1, N).

suffix_make(Length, Suffix, List, Bound) :-
	Skip is Bound-Length,
	append_make(Skip, Suffix, List).



%   proper_suffix_length(+List, ?Suffix, ?Length)
%   is true when
%	proper_suffix(List, Suffix) &
%	length(Suffix, Length).
%   The normal use of this is to return the last Length elements of
%   a given List.  For this to be sure of termination,
%	List must be a proper list.
%   The predicate proper_suffix/2 in library(listparts) has the same
%   requirement.  The trouble is that for any given Suffix and Length
%   there are infinitely many compatible Lists.
%   If Length is instantiated or Suffix is a proper list, this predicate
%   is determinate.

proper_suffix_length([Head|Tail], Suffix, Length) :-
	proper_length(Tail, Bound),
	!,
	Bound > 0,		% otherwise it can't have a proper suffix
	(   var(Length) ->
	    (   proper_length(Suffix, Length) ->
		suffix_make(Length, Suffix, Tail, Bound)
	    ;   suffix_find(Suffix, Tail, Bound, Length)
	    )
	;   integer(Length) ->
	    Length >= 0, Length =< Bound,
	    suffix_make(Length, Suffix, Tail, Bound)
	;   should_be(integer, Length, 3,
		proper_suffix_length([Head|Tail],Suffix,Length))
	).
proper_suffix_length(List, Suffix, Length) :-
	should_be(proper_list, List, 1,
	    proper_suffix_length(List,Suffix,Length)).



%   rotate_list(+Amount, ?List, ?Rotated)
%   is true when List and Rotated are lists of the same length, and
%	append(Prefix, Suffix, List) &
%	append(Suffix, Prefix, Rotated) &
%	(   Amount >= 0 & length(Prefix, Amount)
%	|   Amount =< 0 & length(Suffix, Amount)
%	).
%   That is to say, List rotated LEFT by Amount is Rotated.
%   I had two choices with this predicate: I could have it solve for
%   Amount, in which case Amount would have to be bounded, or I could
%   let it accept unbounded Amounts.  I wanted it to be the case that
%	rotate_list(A, X, Y) & rotate_list(B, Y, Z) & plus(A, B, C)
%    => rotate_list(C, X, Z),
%    so I chose to accept unbounded Amounts.  This means that the
%    Amount must already be instantiated.  As it is a strict input,
%    it must come first.

rotate_list(Amount, List, Rotated) :-
	integer(Amount),
	!,
	same_length(List, Rotated, Length),
	Delta is (Amount mod Length + Length) mod Length,
	append_length(Prefix, Suffix, List, Delta),
	append(Suffix, Prefix, Rotated).
rotate_list(Amount, List, Rotated) :-
	should_be(integer, Amount, 1, rotate_list(Amount,List,Rotated)).



%   rotate_list(?List, ?Rotated)
%   is true when rotate_list(1, List, Rotated), but is a bit less
%   heavy-handed.
%   rotate_list(X, Y) rotates X left  one place yielding Y.
%   rotate_list(Y, X) rotates X right one place yielding Y.
%   Either List or Rotated should be a proper list.

rotate_list([Head|Tail], Rotated) :-
	append(Tail, [Head], Rotated).



%   sublist(+Whole, ?Part, ?Before, ?Length, ?After)
%   is true when
%	Whole is a list	-- it must be proper already
%	Part  is a list
%	Whole = Alpha || Part || Omega
%	length(Alpha, Before)
%	length(Part,  Length)
%	length(Omega, After)
%   This is an exact parallel to substring/5 in library(strings),
%   and may be used for similar purposes on lists of character codes.
%   But it can be used to divide a list up many ways:
%	prefix_length(P, W, L) :- sublist(W, P, 0, L, _)
%	suffix_length(S, W, L) :- sublist(W, P, _, L, 0)
%   and so on.  Note that these more specific predicates may be used
%   to solve for Whole, but sublist/5 cannot be.
%  There is more work to be done on these to make them work more ways
%  around.  It would be nice if there were a way to take the logical
%  specification and systematically work out how to code it to work
%  in as many cases as possible.

sublist(Whole, Part, Before) :-
	sublist(Whole, Part, Before, _, _).

sublist(Whole, Part, Before, Length) :-
	sublist(Whole, Part, Before, Length, _).

sublist(Whole, Part, Before, Length, After) :-
	integer(Before),
	(   integer(Length) -> true
	;   var(Length), proper_length(Part, Length)
	),
	!,
	Before >= 0,
	Length >= 0,
	append_make(Before, Suffix, Whole),
	append_make(Length, Part, Rest, Suffix),
	length(Rest, After).
sublist(Whole, Part, Before, Length, After) :-
	proper_length(Whole, LengthOfWhole),	
	(   integer(Before) -> true
	;   var(Before)
	),
	(   integer(After) -> true
	;   var(After)
	),
	(   integer(Length) -> true
	;   nonvar(Length) -> fail
	;   proper_length(Part, Length) -> true
	;   true
	),
	!,
	append_length(Suffix, Whole, Before),	
	(   var(Length) -> true	
	;   Length =< LengthOfWhole-Before
	),
	(   var(After) -> true
	;   After =< LengthOfWhole-Before
	),
	append_length(Part, _, Suffix, Length),
	After is LengthOfWhole-Before-Length.
sublist(Whole, Part, Before, Length, After) :-
	Goal = sublist(Whole,Part,Before,Length,After),
	should_be(proper_list, Whole, 1, Goal),
	should_be(integer, Before, 3, Goal),
	should_be(integer, Length, 4, Goal),
	should_be(integer, After,  5, Goal).


