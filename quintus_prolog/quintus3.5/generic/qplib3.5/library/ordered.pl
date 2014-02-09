%   Package: ordered
%   Author : Richard A. O'Keefe
%   Updated: 01 Jun 1989
%   Purpose: Define the "ordered" predicates.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(ordered, [
	ordered/1,
	ordered/2,
	max_member/2,
	min_member/2,
	max_member/3,
	min_member/3,
	select_max/3,
	select_max/4,
	select_min/3,
	select_min/4
   ]).
:- meta_predicate
	ordered(2, +),
	    ordered_0(+, 2),
	    ordered_1(+, +, 2),
	max_member(2, +, ?),
	    max_member_1(+, +, ?, 2),
	min_member(2, +, ?),
	    min_member_1(+, +, ?, 2),
	select_min(2, ?, +, ?),
	    sel_min_gen(+, ?, 2, ?),
		sel_min_gen(+, ?, +, 2, -, ?),
	select_max(2, ?, +, ?),
	    sel_max_gen(+, ?, 2, ?),
		sel_max_gen(+, ?, +, 2, -, ?).
:- use_module(library(call), [
	call/3
   ]).


/*  BEWARE!!
    This is still an unsupported package.
    In snapshot 22 (12-Jan-88) the first two arguments of the
    {max,min}_member/[2,3] predicates were swapped so that the
    element now precedes this list.  This makes the argument
    order of these predicates compatible with basics:member/2,
    and more than that, it makes them compatible with the
    select_{max,min}/[3,4] predicates in this very package.
	max_member(Pred, Member, List) :- select_max(Pred, Member, List, _).
    and so on.
*/

/* pred
	ordered(list(T)),
	    ordered_1(list(T), T),
	ordered(void(T,T), list(T)),
	    ordered_1(list(T), T, void(T,T)),
	max_member(S, list(S)),
	    max_member_1(list(S), S, S),
	min_member(S, list(S)),
	    min_member_1(list(S), S, S),
	max_member(void(T,T), T, list(T)),
	    max_member_1(list(T), T, T, void(T,T)),
	min_member(void(T,T), T, list(T)),
	    min_member_1(list(T), T, T, void(T,T)),
	select_min(S, list(S), list(S)),
	    sel_min_trm(list(S), list(S), S),
		sel_min_trm(list(S), list(S), S, list(S), list(S)),
	select_max(S, list(S), list(S)),
	    sel_max_trm(list(S), list(S), S),
		sel_max_trm(list(S), list(S), S, list(S), list(S)),
	select_min(void(T,T), T, list(T), list(T)),
	    sel_min_gen(list(T), list(T), void(T,T), T),
		sel_min_gen(list(T), list(T), T, void(T,T), list(T), list(T)),
	select_max(void(T,T), T, list(T), list(T)),
	    sel_max_gen(list(T), list(T), void(T,T), T),
		sel_max_gen(list(T), list(T), T, void(T,T), list(T), list(T)).
*/

sccs_id('"@(#)89/06/01 ordered.pl	32.1"').


%   ordered(+List)
%   is true when List is a list of terms [T1,T2,...,Tn] such that
%   for all k in 2..n Tk-1 @=< Tk, i.e. T1 @=< T2 @=< T3 ...
%   The output of keysort/2 is always ordered, and so is that of
%   sort/2.  Beware: just because a list is ordered does not mean
%   that it is the representation of an ordered set; it might contain
%   duplicates.  E.g. L = [1,2,2,3] & sort(L,M) => ordered(L) & M\=L.

ordered([]).
ordered([Head|Tail]) :-
	ordered_1(Tail, Head).

ordered_1([], _).
ordered_1([Head|Tail], Left) :-
	Left @=< Head,
	ordered_1(Tail, Head).



%   ordered(+P, +[T1,T2,...,Tn])
%   is true when P(T1,T2) & P(T2,T3) & ...   That is, if you take
%   P as a "comparison" predicate like @=<, the list is ordered.
%   This is good for generating prefixes of sequences,
%   e.g. L = [1,_,_,_,_], ordered(times(2), L) yields L = [1,2,4,8,16].

ordered(P, List) :- ordered_0(List, P).

ordered_0([], _).
ordered_0([Head|Tail], Relation) :-
	ordered_1(Tail, Head, Relation).

ordered_1([], _, _).
ordered_1([Head|Tail], Left, Relation) :-
	call(Relation, Left, Head),
	ordered_1(Tail, Head, Relation).



/*  Here we define four predicates:

	min_member(Minimum <- Set)
	max_member(Maximum <- Set)

	min_member(Pred, Minimum <- Set)
	max_member(Pred, Maximum <- Set)

    Set is always a list, Minimum (or Maximum) is a member of that
    list, and it is a least (greatest) element under the standard
    ordering on terms (under the '@=<'-like ordering Pred).

    Before 12-Jan-88, the argument order was not the same as the
    argument order of member/2 or the select_{max,min}/[3,4]
    predicates.  It is now.  The old order was more beautiful,
    but consistency is a greater beauty.
*/

%   max_member(?Xmax, +[X1,...,Xn])
%   unifies Xmax with the maximum (in the sense of @=<) of X1,...,Xn.
%   If the list is empty, it fails quietly.

max_member(Maximum, [Head|Tail]) :-
	max_member_1(Tail, Head, Maximum).


max_member_1([], Maximum, Maximum).
max_member_1([Head|Tail], Max, Maximum) :-
	Head @=< Max,
	!,
	max_member_1(Tail, Max, Maximum).
max_member_1([Head|Tail], _, Maximum) :-
	max_member_1(Tail, Head, Maximum).



%   min_member(?Xmin, +[X1,...,Xn])
%   unifies Xmin with the minimum (in the sense of @=<) of X1,...,Xn.
%   If the list is empty, it fails quietly.

min_member(Minimum, [Head|Tail]) :-
	min_member_1(Tail, Head, Minimum).


min_member_1([], Minimum, Minimum).
min_member_1([Head|Tail], Min, Minimum) :-
	Min @=< Head,
	!,
	min_member_1(Tail, Min, Minimum).
min_member_1([Head|Tail], _, Minimum) :-
	min_member_1(Tail, Head, Minimum).



%   max_member(+P, ?Xmax, +[X1,...,Xn])
%   unifies Xmax with the maximum element of [X1,...,Xn], as defined
%   by the comparison predicate P, which should act like @=< .

max_member(Pred, Maximum, [Head|Tail]) :-
	max_member_1(Tail, Head, Maximum, Pred).


max_member_1([], Maximum, Maximum, _).
max_member_1([Head|Tail], Max, Maximum, Pred) :-
	call(Pred, Head, Max),
	!,
	max_member_1(Tail, Max, Maximum, Pred).
max_member_1([Head|Tail], _, Maximum, Pred) :-
	max_member_1(Tail, Head, Maximum, Pred).



%   min_member(+P, ?Xmin, +[X1,...,Xn])
%   unifies Xmin with the minimum element of [X1,...,Xn], as defined
%   by the comparison predicate P, which should act like @=< .

min_member(Pred, Minimum, [Head|Tail]) :-
	min_member_1(Tail, Head, Minimum, Pred).


min_member_1([], Minimum, Minimum, _).
min_member_1([Head|Tail], Min, Minimum, Pred) :-
	call(Pred, Min, Head),
	!,
	min_member_1(Tail, Min, Minimum, Pred).
min_member_1([Head|Tail], _, Minimum, Pred) :-
	min_member_1(Tail, Head, Minimum, Pred).



/*  Here we define four predicates:

	select_min(Minimum, Set, Residue)
	select_max(Maximim, Set, Residue)

	select_min(Pred, Minimum, Set, Residue)
	select_max(Pred, Maximum, Set, Residue)

    The general idea is that they select an item out of a list in the
    style of select/3 (see library(sets)), and that item is the left-
    most (minimum,maximum) using the (standard term ordering @=<, the
    ordering defined by Pred).  An earlier version of this file used
    arithmetic ordering as the default; this was changed to use term
    ordering for consistency with orderd/2 and library(ordprefix).

    Set is always a list, Minimum (or Maximum) is a member of that
    list, and Residue is the whole of Set except for the one element.
    We could have defined select_min/3 this way:

    select_min(Minimum, Set, Residue) :-
	    append(Front, [Minimum|Back], Set),
	    append(Front, Back, Residue),
	    forall(member(X,Front), \+(X =< Minimum)),
	    forall(member(X,Back),     Minimum =< X ).

    That is, Minimum is less than every element preceding it in Set,
    and less than or equal to every element following it in Set.
    The two predicates with a Pred argument use that instead of =< .
    The advantage of this code is that it uses O(N) comparisons,
    whereas the more obvious code could do O(N^2).

    With these routines, we could define selection sort:

	ssort([], []).
	ssort(List, [Minimum|Sorted]) :-
		select_min(Minimum, List, Rest),
		ssort(Rest, Sorted).

    Considering the requirements for this kind of use led directly
    to the code in this file.
*/


%   select_min(?Element, +Set, ?Residue)
%   unifies Element with the smallest (in the sense of @=<) element
%   of Set, and Residue with a list of all the other elements.

select_min(Element, Set, Residue) :-
	sel_min_trm(Set, Residue, Element).


sel_min_trm([Head|Tail], Residue, Element) :-
	sel_min_trm([Head|Tail], Residue, Head, List1, Residue1),
	!,
	sel_min_trm(List1, Residue1, Element).
sel_min_trm([Head|Tail], Tail, Head).


sel_min_trm([], _, _, _, _) :- !, fail.
sel_min_trm([Head|Tail], [Head|Residue], Current, List1, Residue1) :-
	Current @=< Head,
	!,
	sel_min_trm(Tail, Residue, Current, List1, Residue1).
sel_min_trm(List, Residue, _, List, Residue).  % non-empty list!



%   select_min(+Pred, ?Element, +Set, ?Residue)
%   find the least Element of Set, i.e. Pred(Element,X) for all X in Set.

select_min(Pred, Element, Set, Residue) :-
	sel_min_gen(Set, Residue, Pred, Element).


sel_min_gen([Head|Tail], Residue, Pred, Element) :-
	sel_min_gen([Head|Tail], Residue, Head, Pred, List1, Residue1),
	!,
	sel_min_gen(List1, Residue1, Pred, Element).
sel_min_gen([Head|Tail], Tail, _, Head).


sel_min_gen([], _, _, _, _, _) :- !, fail.
sel_min_gen([Head|Tail], [Head|Residue], Current, Pred, List1, Residue1) :-
	call(Pred, Current, Head),
	!,
	sel_min_gen(Tail, Residue, Current, Pred, List1, Residue1).
sel_min_gen(List, Residue, _, _, List, Residue).  % non-empty list!



%   select_max(?Element, +Set, ?Residue)
%   unifies Element with the (leftmost) maximum element of the Set,
%   and Residue to the other elements in the same order.


select_max(Element, Set, Residue) :-
	sel_max_trm(Set, Residue, Element).


sel_max_trm([Head|Tail], Residue, Element) :-
	sel_max_trm([Head|Tail], Residue, Head, List1, Residue1),
	!,
	sel_max_trm(List1, Residue1, Element).
sel_max_trm([Head|Tail], Tail, Head).


sel_max_trm([], _, _, _, _) :- !, fail.
sel_max_trm([Head|Tail], [Head|Residue], Current, List1, Residue1) :-
	Head @=< Current,
	!,
	sel_max_trm(Tail, Residue, Current, List1, Residue1).
sel_max_trm(List, Residue, _, List, Residue).  % non-empty list!



%   select_max(+Pred, ?Element, +Set, ?Residue)
%   find the greatest Element of Set, i.e. Pred(X,Element) for all X in Set.

select_max(Pred, Element, Set, Residue) :-
	sel_max_gen(Set, Residue, Pred, Element).


sel_max_gen([Head|Tail], Residue, Pred, Element) :-
	sel_max_gen([Head|Tail], Residue, Head, Pred, List1, Residue1),
	!,
	sel_max_gen(List1, Residue1, Pred, Element).
sel_max_gen([Head|Tail], Tail, _, Head).


sel_max_gen([], _, _, _, _, _) :- !, fail.
sel_max_gen([Head|Tail], [Head|Residue], Current, Pred, List1, Residue1) :-
	call(Pred, Head, Current),
	!,
	sel_max_gen(Tail, Residue, Current, Pred, List1, Residue1).
sel_max_gen(List, Residue, _, _, List, Residue).  % non-empty list!


/*  BEGIN TEST CODE  /*

test :-
	test([3,1,4,1,5,9]).

test(L) :-
	max_member(Max1, L), write(max1=Max1), nl,
	min_member(Min1, L), write(min1=Min1), nl,
	max_member(=<, Max2, L), write(max2=Max2), nl,
	min_member(=<, Min2, L), write(min2=Min2), nl,
	select_max(Max3, L, Res1), write((max3=Max3,res1=Res1)), nl,
	select_min(Min3, L, Res3), write((min3=Min3,res3=Res3)), nl,
	select_max(=<, Max4, L, Res2), write((max4=Max4,res2=Res2)), nl,
	select_min(=<, Min4, L, Res4), write((min4=Min4,res4=Res4)), nl.

/* END TEST CODE */

