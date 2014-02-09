%   Package: bags
%   Author : Richard A. O'Keefe
%   Updated: 14 Jan 1991
%   Purpose: Bag Utilities
%   SeeAlso: ordsets, maps

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  A bag B is a function from a set dom(B) to the non-negative integers.
    For the purposes of this module, a bag is constructed from two functions:
	
	bag		- creates an empty bag
	bag(E, M, B)	- extends the bag B with a new (NB!) element E
			  which occurs with multiplicity M, and which
			  precedes all elements of B in Prolog's order.

    A bag is represented by a Prolog term mirroring its construction.  There
    is one snag with this: what are we to make of
	bag(f(a,Y), 1, bag(f(X,b), 1, bag))	?
    As a term it has two distinct elements, but f(a,b) will be reported as
    occurring in it twice.  But according to the definition above,
	bag(f(a,b), 1, bag(f(a,b), 1, bag))
    is not the representation of any bag, that bag is represented by
	bag(f(a,b), 2, bag)
    alone.  We are apparently stuck with a scheme which is only guaranteed
    to work for "sufficiently instantiated" terms, but then, that's true of 
    a lot of Prolog code.

    The reason for insisting on the order is to make union and 
    intersection linear in the sizes of their arguments.
    library(ordsets) does the same for ordinary sets.

    empty_bag/1, bag_add_element/[3,4], and bag_del_element/[3,4]
    were added at the suggestion of NCR.
*/

:- module(bags, [
	bag_add_element/3,
	bag_add_element/4,
	bag_del_element/3,
	bag_del_element/4,
	bag_intersect/2,
	bag_intersection/2,
	bag_intersection/3,
	bag_max/2,
	bag_max/3,
	bag_min/2,
	bag_min/3,
	bag_subtract/3,
	bag_to_list/2,
	bag_to_ord_set/2,
	bag_to_ord_set/3,
	bag_to_set/2,
	bag_to_set/3,
	bag_union/2,
	bag_union/3,
	checkbag/2,
	empty_bag/1,
	is_bag/1,
	length/3,
	list_to_bag/2,
	make_sub_bag/2,
	mapbag/2,
	mapbag/3,
	member/3,
	memberchk/3,
	portray_bag/1,
	somebag/2,
	somechkbag/2,
	test_sub_bag/2
   ]).
:- meta_predicate
	checkbag(2, +),
	    check_bag(+, 2),
	mapbag(1, +),
	    map_bag(+, 1),
	mapbag(2, +, -),
	    map_bag_list(+, -, 2),
	somebag(2, +),
	somechkbag(2, +).

:- use_module(library(call), [
	call/2,
	call/3
   ]).

:- mode
	addkeys(+, -),
	bag_add_element(+, +, ?),
	bag_add_element(+, +, +, ?),
	    bag_add_element_1(+, +, +, ?),
		bag_add_element_1(+, +, +, ?, +, +, +),
	bag_del_element(+, +, ?),
	bag_del_element(+, +, +, ?),
	    bag_del_element_1(+, +, +, ?),
		bag_del_element_1(+, +, +, ?, +, +, +),
	bag_intersection(+, ?),
	    bag_intersection_3(+, +, ?),
	bag_intersection(+, +, ?),
	    bag_intersection(+, +, +, +, ?),
		bag_intersection(+, +, +, +, +, +, +, ?),
	bag_intersect(+, +),
	    bag_intersect(+, +, +, +, +, +, +),
	bag_subtract(+, +, ?),
	    bag_subtract_1(+, +, +, +, ?),
	    bag_subtract_2(+, +, +, +, ?),
		bag_subtract(+, +, +, +, +, +, +, ?),
	bag_to_list(+, ?),
	    bag_to_list(+, ?, +, +),
	bag_to_ord_set(+, ?),
	bag_to_ord_set(+, +, ?),
	bag_to_set(+, ?),
	bag_to_set(+, +, ?),
	bag_union(+, ?),
	    bag_union(+, +, ?, ?),
	bag_union(+, +, ?),
	    bag_union(+, +, +, +, ?),
		bag_union(+, +, +, +, +, +, +, ?),
	bagform(+, ?),
	    bagform(+, +, +, -, -),
	bag_max(+, ?),
	bag_min(+, ?),
	    bag_scan(+, +, +, +, ?),
	bag_max(+, ?, ?),
	bag_min(+, ?, ?),
	    bag_scan(+, +, +, +, ?, ?),
	checkbag(2, +),
	    check_bag(+, 2),
	countdown(+, -),
	empty_bag(?),
	is_bag(+),
	    is_bag(+, +),
	length(+, ?, ?),
	    length(+, +, ?, +, ?),
	list_to_bag(+, -),
	make_sub_bag(+, -),
	mapbag(1, +),
	    map_bag(+, 1),
	mapbag(+, +, -),
	    map_bag_list(+, -, 2),
	member(?, ?, +),
	memberchk(+, ?, +),
	portray_bag(+),
	    portray_bag(+, +, +),
		portray_bag(+, +),
	somebag(+, +),
	somechkbag(+, +),
	test_sub_bag(+, +),
	    test_sub_bag(+, +, +, +, +, +, +).

sccs_id('"@(#)91/01/14 bags.pl	61.1"').


%   is_bag(+Bag)
%   recognises proper well-formed bags.  You can pass variables to is_bag/1,
%   and it will reject them, just like is_list/1, is_ord_set/1, and so on.

is_bag(-) :- !, fail.		% catch and reject variables.
is_bag(bag).			% can't be a variable, clause 1 catches them.
is_bag(bag(E,M,B)) :-
	integer(M), M > 0,
	is_bag(B, E).


is_bag(-, _) :- !, fail.	% catch and reject variables.
is_bag(bag, _).			% can't be a variable, clause 1 catches them.
is_bag(bag(E,M,B), P) :-
	E @> P,
	integer(M), M > 0,
	is_bag(B, E).



%   portray_bag(+Bag)
%   writes a bag to the current output stream in a pretty form so that
%   you can easily see what it is.  Note that a bag written out this
%   way can NOT be read back in.  For that, use write_canonical/1.
%   The point of this predicate is that you can add a directive
%	:- add_portray(portray_bag).
%   to have bags displayed nicely by print/1 and the debugger.
%   This will print things which are not fully instantiated, which is
%   mainly of interest for debugging this module.

portray_bag(bag) :-
	write('Bag{'), write('}').
portray_bag(bag(E,M,B)) :-
	write('Bag{'), portray_bag(B, E, M), write('}').


portray_bag(B, E, M) :- var(B), !,
	portray_bag(E, M), write(' | '), write(B).
portray_bag(bag(F,N,B), E, M) :- !,
	portray_bag(E, M), write(', '),
	portray_bag(B, F, N).
portray_bag(bag, E, M) :- !,
	portray_bag(E, M).
portray_bag(B, E, M) :-
	portray_bag(E, M), write(' | '), write(B).


portray_bag(E, M) :-
	print(E), write(':'), write(M).



%   If bags are to be as useful as lists, we should provide mapping
%   predicates similar to those for lists.  Hence
%	checkbag(Pred, Bag)		- applies Pred(Element, Count)
%	mapbag(Pred, Bag)		- applies Pred(Element)
%	mapbag(Pred, BagIn, BagOut)	- applies Pred(Element, Answer)
%	somebag(Pred, Bag)		- applies Pred(Element, Count)
%	somechkBag(Pred, Bag)		- applies Pred(Element, Count)
%   Note that mapbag does NOT give the Count to Pred, but preserves it.
%   It wouldn't be hard to apply Pred to four arguments if it wants them.



%   checkbag(+Pred, +Bag)
%   is true when Bag is a Bag{E1:M1, ..., En:Mn} with elements Ei
%   of multiplicity Mi, and Pred(Ei, Mi) is true for each i.

checkbag(Pred, Bag) :-
	check_bag(Bag, Pred).


check_bag(bag, _).
check_bag(bag(Element,Multiplicity,Bag), Pred) :-
	call(Pred, Element, Multiplicity),
	check_bag(Bag, Pred).



%   mapbag(+Pred, +Bag)
%   is true when Bag is a Bag{E1:M1, ..., En:Mn} with elements Ei
%   of multiplicity Mi, and Pred(Ei) is true for each element Ei.
%   The multiplicities are ignored:  if you don't want this, use checkbag/2.

mapbag(Pred, Bag) :-
	map_bag(Bag, Pred).


map_bag(bag, _).
map_bag(bag(Element,_,Bag), Pred) :-
	call(Pred, Element),
	map_bag(Bag, Pred).



%   mapbag(+Pred, +OldBag, -NewBag)
%   is true when OldBag is a Bag{E1:M1, ..., En:Mn} and NewBag is a
%   Bag{F1:M'1, ..., Fn:M'n} and the elements of OldBag and NewBag
%   are related by Pred(Ei, Fj).  What happens is that the elements
%   of OldBag are mapped, and then the result is converted to a bag,
%   so there is no positional correspondence between Ei and Fj.
%   Even when Pred is bidirectional, mapbag/3 is NOT.  OldBag should
%   satisfy is_bag/1 before mapbag/3 is called.

mapbag(Pred, BagIn, BagOut) :-
	map_bag_list(BagIn, Listed, Pred),
	keysort(Listed, Sorted),
	bagform(Sorted, BagOut).


map_bag_list(bag, [], _).
map_bag_list(bag(Element,Multiplicity,Bag), [R-Multiplicity|L], Pred) :-
	call(Pred, Element, R),
	map_bag_list(Bag, L, Pred).



%   somebag(+Pred, +Bag)
%   is true when Bag is a Bag{E1:M1, ..., En:Mn} with elements Ei of
%   multiplicity Mi and Pred(Ei, Mi) is true of some element Ei and
%   its multiplicity.  There is no version which ignores the Mi.

somebag(Pred, bag(Element,Multiplicity,_)) :-
	call(Pred, Element, Multiplicity).
somebag(Pred, bag(_,_,Bag)) :-
	somebag(Pred, Bag).



%   somechkbag(+Pred, +Bag)
%   is like somebag(Pred, Bag), but commits to the first solution it
%   finds.  For example, if p(X,X,_), somechk(p(X), Bag) would be an
%   analogue of memberchk/2 for bags.

somechkbag(Pred, bag(Element,Multiplicity,_)) :-
	call(Pred, Element, Multiplicity),
	!.
somechkbag(Pred, bag(_,_,Bag)) :-
	somechkbag(Pred, Bag).



%   bag_to_list(+Bag, ?List)
%   converts a Bag{E1:M1, ..., En:Mn} to a list where each element
%   appears as many times as its multiplicity requires.  For example,
%   Bag{a:1, b:3, c:2} would be converted to [a,b,b,b,c,c].

bag_to_list(bag, []).
bag_to_list(bag(Element,Multiplicity,Bag), List) :-
	Multiplicity > 0,		% should be redundant
	bag_to_list(Multiplicity, List, Element, Bag).


bag_to_list(N, [Element|List], Element, Bag) :-
	(   N =:= 1 ->
	    bag_to_list(Bag, List)
	;   M is N-1,			% M > 0
	    bag_to_list(M, List, Element, Bag)
	).



%   bag_to_ord_set(+Bag, ?Ordset)
%   converts a Bag{E1:M1, ..., En:Mn} to a list where each element
%   appears once without its multiplicity.  The result is always an
%   ordered (representation of a) set, suitable for processing by
%   library(ordsets).  See also bag_to_list/2.

bag_to_ord_set(bag, []).
bag_to_ord_set(bag(Element,_,Bag), [Element|Ordset]) :-
	bag_to_ord_set(Bag, Ordset).



%   bag_to_ord_set(+Bag, +Threshold, ?Ordset)
%   given a Bag{E1:M1, ..., En:Mn} returns a list in standard order of
%   the set of elements {Ei | Mi >= Threshold}.  The result is an Ordset.

bag_to_ord_set(Bag, Threshold, Ordset) :-
	bag_to_set(Bag, Threshold, Ordset).



%   list_to_bag(+List, ?Bag)
%   converts a List to a Bag representing the same multi-set.
%   Each element of the List appears once in the Bag together
%   with the number of times it appears in the List.

list_to_bag(L, B) :-
	addkeys(L, K),
	keysort(K, S),
	bagform(S, B).


addkeys([], []).
addkeys([Head|Tail], [Head-1|Rest]) :-
	addkeys(Tail, Rest).


bagform([], bag).
bagform([Element-M|Tail], bag(Element,N,B)) :-
	bagform(Tail, Element, M, N, Rest),
	bagform(Rest, B).


bagform([Element-M|Tail], Element, N0, N, Rest) :- !,
	N1 is N0+M,
	bagform(Tail, Element, N1, N, Rest).
bagform(Rest, _, N, N, Rest).



%   bag_to_set(+Bag, ?Set)
%   converts a Bag{E1:M1, ..., En:Mn} to a list which represents the
%   Set {E1, ..., En}.  The order of elements in the result is not
%   defined:  for a version where the order is defined use bag_to_ord_set/2.

bag_to_set(bag, []).
bag_to_set(bag(Element,_,Bag), [Element|Set]) :-
	bag_to_set(Bag, Set).



%   bag_to_set(+Bag, +Threshold, ?Set)
%   given a Bag{E1:M1, ..., En:Mn} returns a list which represents the
%   Set of elements {Ei | Mi >= Threshold}.  Because the Bag is sorted,
%   the result is necessarily an ordered set.

bag_to_set(bag, _, []).
bag_to_set(bag(_,Multiplicity,Bag), Threshold, Set) :-
	Multiplicity < Threshold,
	!,
	bag_to_set(Bag, Threshold, Set).
bag_to_set(bag(Element,_,Bag), Threshold, [Element|Set]) :-
	bag_to_set(Bag, Threshold, Set).



%   empty_bag(?Bag)
%   is true when Bag is the representation of an empty bag.  It can be
%   used both to make and to recognise empty bags.

empty_bag(bag).



%   member(?Element, ?Multiplicity, +Bag)
%   is true when Element appears in the multi-set represented by Bag
%   with the indicated Multiplicity.  Bag should be instantiated,
%   but Element and Multiplicity may severally be given or solved for.

member(Element, Multiplicity, bag(Element,Multiplicity,_)).
member(Element, Multiplicity, bag(_,_,Bag)) :-
	member(Element, Multiplicity, Bag).



%   memberchk(+Element, ?Multiplicity, +Bag)
%   is true when Element appears in the multi-set represented by Bag,
%   with the indicated Multiplicity.  It should only be used to check
%   whether a given element occurs in the Bag, or whether there is an
%   element with the given Multiplicity.  Note that guessing the
%   multiplicity and getting it wrong may force the wrong choice of
%   clause, but the result will be correct if is_bag(Bag).

memberchk(Element, Multiplicity, bag(Element,Multiplicity,_)) :- !.
memberchk(Element, Multiplicity, bag(_,_,Bag)) :-
	memberchk(Element, Multiplicity, Bag).



%   bag_max(+Bag, ?CommonestElement)
%   unifies CommonestElement with the element of Bag which occurs
%   most often, picking the leftmost element if several have this
%   multiplicity.  To find the multiplicity as well, use bag_max/3.
%   bag_max/2 and bag_min/2 break ties the same way.

bag_max(bag(E0,M0,B), E) :-
	bag_scan(B, E0, M0, 1, E).


%   bag_min(+Bag, ?RarestElement)
%   unifies RarestElement with the element of Bag which occurs
%   least often, picking the leftmost element if several have this
%   multiplicity.  To find the multiplicity as well, use bag_min/3.
%   bag_max/2 and bag_min/2 break ties the same way, so
%	bag_max(Bag, Elt), bag_min(Bag, Elt)
%   is true only when all the elements of Bag have the same multiplicity.

bag_min(bag(E0,M0,B), E) :-
	bag_scan(B, E0, M0, -1, E).

bag_min(bag, Emin, _, Emin).
bag_min(bag(E1,M1,B), E0, M0, Emin) :-
    (	M1 < M0 ->
	bag_min(B, E1, M1, Emin)
    ;/* M1 >=M0 */
	bag_min(B, E0, M0, Emin)
    ).


%.  bag_scan(+Bag, +E0, +M0, +Sign, ?E)
%   generalises bag_{max,min}/2.  They share a common routine, at a small
%   cost in efficiency, to make it impossible for them to break ties
%   differently.

bag_scan(bag, E, _, _, E).
bag_scan(bag(E1,M1,B), E0, M0, Sign, E) :-
	(   (M1-M0)*Sign > 0 ->
	    bag_scan(B, E1, M1, Sign, E)
	;/* (M1-M0)*Sign =< 0 */
	    bag_scan(B, E0, M0, Sign, E)
	).



%   bag_max(+Bag, ?CommonestElement, ?Multiplicitu)
%   unifies CommonestElement with the element of Bag which occurs
%   most often, and Multiplicity with the multiplicity of that element.
%   If there are several elements with the same greatest multiplicity,
%   the left-most is returned.  bag_min/3 breaks ties the same way.

bag_max(bag(E0,M0,B), E, M) :-
	bag_scan(B, E0, M0, 1, E, M).


%   bag_min(+Bag, ?RarestElement)
%   unifies RarestElement with the element of Bag which occurs
%   least often, and Multiplicity with the multiplicity of that element.
%   If there are several elements with the same least multiplicity,
%   the left-most is returned.  bag_max/3 breaks ties the same way, so
%	bag_max(Bag, Elt, Mult), bag_min(Bag, Elt, Mult)
%   is true only when all the elements of Bag have multiplicity Mult.

bag_min(bag(E0,M0,B), E, M) :-
	bag_scan(B, E0, M0, -1, E, M).


%.  bag_scan(+Bag, +E0, +M0, +Sign, ?E, ?M)
%   generalises bag_{max,min}/3.  They share a common routine, at a small
%   cost in efficiency, to make it impossible for them to break ties
%   differently.

bag_scan(bag, E, M, _, E, M).
bag_scan(bag(E1,M1,B), E0, M0, Sign, E, M) :-
	(   (M1-M0)*Sign > 0 ->
	    bag_scan(B, E1, M1, Sign, E, M)
	;/* (M1-M0)*Sign =< 0 */
	    bag_scan(B, E0, M0, Sign, E, M)
	).



%   length(+Bag, ?BagCardinality, ?SetCardinality)
%   unifies BagCardinality with the total cardinality of the multi-set
%   Bag (the sum of the multiplicities of its elements) and
%   SetCardinality with the number of distinct elements.
%   length(B, BC, SC) & bag_to_list(B, L) & bag_to_set(B, S)
%   --> length(L, BC) & length(S, SC).

length(B, BL, SL) :-
	length(B, 0, BL, 0, SL).

length(bag,	   BL, BL, SL, SL).
length(bag(_,M,B), BA, BL, SA, SL) :-
	BB is BA+M, SB is SA+1,
	length(B, BB, BL, SB, SL).


%  sub_bag, if it existed, could be used two ways: to test whether one bag
%  is a sub_bag of another, or to generate all the sub_bags.  The two uses
%  need different implementations.


%   make_sub_bag(+Bag, ?SubBag)
%   enumerates the sub-bags of Bag, unifying SubBag with each of them in
%   turn.  The order in which the sub-bags are generated is such that if
%   SB2 is a sub-bag of SB1 which is a sub-bag of Bag, SB1 is generated
%   before SB2.  In particular, Bag is enumerated first and bag last.

make_sub_bag(bag, bag).
make_sub_bag(bag(Element,M,B), bag(Element,N,C)) :-
	countdown(M, N),
	make_sub_bag(B, C).
make_sub_bag(bag(_,_,B), C) :-
	make_sub_bag(B, C).

countdown(M, M).
countdown(M, N) :-
	M > 1, K is M-1,
	countdown(K, N).



%   test_sub_bag(+Bag, +SubBag)
%   is true when SubBag is (already) a sub-bag of Bag.  That is,
%   each element of SubBag must occur in Bag with at least the
%   same multiplicity.  If you know SubBag, you should use this
%   to test, not make_sub_bag/2.

test_sub_bag(bag, _).
test_sub_bag(bag(E1,M1,B1), bag(E2,M2,B2)) :-
	compare(C, E1, E2),
	test_sub_bag(C, E1, M1, B1, E2, M2, B2).

test_sub_bag(>, E1, M1, B1, _, _, bag(E2,M2,B2)) :-
	compare(C, E1, E2),
	test_sub_bag(C, E1, M1, B1, E2, M2, B2).
test_sub_bag(=, E1, M1, B1, E1, M2, B2) :-
	M1 =< M2,
	test_sub_bag(B1, B2).


%   bag_union(+Bag1, +Bag2, ?Union)
%   unifies Union with the multi-set union of bags Bag1 and Bag2.

bag_union(bag, Bag2, Bag2).
bag_union(bag(E1,M1,B1), Bag2, Union) :-
	bag_union(Bag2, E1, M1, B1, Union).

bag_union(bag, E1, M1, B1, bag(E1,M1,B1)).
bag_union(bag(E2,M2,B2), E1, M1, B1, Union) :-
	compare(Order, E1, E2),
	bag_union(Order, E1, M1, B1, E2, M2, B2, Union).

bag_union(<, E1, M1, B1, E2, M2, B2, bag(E1,M1,Union)) :-
	bag_union(B1, E2, M2, B2, Union).
bag_union(>, E1, M1, B1, E2, M2, B2, bag(E2,M2,Union)) :-
	bag_union(B2, E1, M1, B1, Union).
bag_union(=, E1, M1, B1, _,  M2, B2, bag(E1,M3,Union)) :-
	M3 is M1+M2,
	bag_union(B1, B2, Union).



%   bag_union(+ListOfBags, ?Union)
%   is true when ListOfBags is given as a proper list of bags and Union
%   is their multi-set union.  Letting K be the length of ListOfBags,
%   and N the sum of the sizes of its elements, the cost is of order
%   N.lg(K). The auxiliary routine
%   bag_union_3(N, L, U, R)
%   is true when the multi-set union of the first N sets in L is U and
%   R is the remaining elements of L.

bag_union(ListOfBags, Union) :-
	length(ListOfBags, NumberOfBags),
	bag_union_3(NumberOfBags, ListOfBags, Union, []).

bag_union_3(0, R, bag, R) :- !.
bag_union_3(1, [U|R], U, R) :- !.
bag_union_3(2, [A,B|R], U, R) :- !,
	bag_union(A, B, U).
bag_union_3(N, R0, U, R) :-
	P is N>>1,	% |first  half of list|
	Q is N- P,	% |second half of list|
	bag_union_3(P, R0, A, R1),
	bag_union_3(Q, R1, B, R),
	bag_union(A, B, U).



%   bag_intersection(+Bag1, +Bag2, ?Intersection)
%   unifies Intersection with the multi-set intersection
%   of bags Bag1 and Bag2.

bag_intersection(bag, _, bag).
bag_intersection(bag(E1,M1,B1), Bag2, Intersection) :-
	bag_intersection(Bag2, E1, M1, B1, Intersection).

bag_intersection(bag, _, _, _, bag).
bag_intersection(bag(E2,M2,B2), E1, M1, B1, Intersection) :-
	compare(Order, E1, E2),
	bag_intersection(Order, E1, M1, B1, E2, M2, B2, Intersection).

bag_intersection(<, _,  _,  B1, E2, M2, B2, Intersection) :-
	bag_intersection(B1, E2, M2, B2, Intersection).
bag_intersection(>, E1, M1, B1, _,  _,  B2, Intersection) :-
	bag_intersection(B2, E1, M1, B1, Intersection).
bag_intersection(=, E1, M1, B1, _,  M2, B2, bag(E1,M3,Intersection)) :-
	( M1 < M2 -> M3 = M1 ; M3 = M2 ),	%  M3 is min(M1,M2)
	bag_intersection(B1, B2, Intersection).



%   bag_intersection(+ListOfBags, ?Intersection)
%   is true when ListOfBags is given as a non-empty proper list of Bags
%   and Intersection is their intersection.  The intersection of an
%   empty list of Bags would be the universe with infinite multiplicities!

bag_intersection([Bag|Bags], Intersection) :-
	bag_intersection_3(Bags, Bag, Intersection).


bag_intersection_3([], Intersection, Intersection).
bag_intersection_3([Bag|Bags], Intersection0, Intersection) :-
	bag_intersection(Bag, Intersection0, Intersection1),  
	bag_intersection_3(Bags, Intersection1, Intersection).



%   bag_intersect(+Bag1, +Bag2)
%   is true when the multi-sets Bag1 and Bag2 have at least one
%   element in common.

bag_intersect(bag(E1,M1,B1), bag(E2,M2,B2)) :-
	compare(C, E1, E2),
	bag_intersect(C, E1, M1, B1, E2, M2, B2).

bag_intersect(<, _, _, bag(E1,M1,B1), E2, M2, B2) :-
	compare(C, E1, E2),
	bag_intersect(C, E1, M1, B1, E2, M2, B2).
bag_intersect(>, E1, M1, B1, _, _, bag(E2,M2,B2)) :-
	compare(C, E1, E2),
	bag_intersect(C, E1, M1, B1, E2, M2, B2).
bag_intersect(=, _, M1, _, _, M2, _) :-
	M1+M2 >= 2.	% just a little safety check.



%   bag_add_element(+Bag1, +Element, +Multiplicity, ?Bag2)
%   computes Bag2 = Bag1 U {Element:Multiplicity}.
%   Multiplicity must be an integer.

bag_add_element(Bag1, E, M, Bag2) :-
	integer(M),
	(   M > 0 ->
	    bag_add_element_1(Bag1, E, M, Bag2)
	;   M < 0 -> 
	    N is -M,
	    bag_del_element_1(Bag1, E, N, Bag2)
	;/* M = 0 */
	    Bag2 = Bag1
	).


bag_add_element(Bag1, Element, Bag2) :-
	bag_add_element_1(Bag1, Element, 1, Bag2).


bag_add_element_1(bag, E, M, bag(E,M,bag)).
bag_add_element_1(bag(E1,M1,B1), E, M, Bag) :-
	compare(R, E1, E),
	bag_add_element_1(R, E, M, Bag, E1, M1, B1).


bag_add_element_1(<, E, M, bag(E1,M1,Bag2), E1, M1, B1) :-
	bag_add_element(B1, E, M, Bag2).
bag_add_element_1(=, E, M, bag(E,M2,B1), _, M1, B1) :-
	M2 is M1+M.
bag_add_element_1(>, E, M, bag(E,M,bag(E1,M1,B1)), E1, M1, B1).



%   bag_del_element(+Bag1, +Element, +Multiplicity, ?Bag2)
%   computes Bag2 = Bag1 \ {Element:Multiplicity}.
%   Multiplicity must be an integer.  It might be cleaner to have predicates
%   like *del_element/ which would fail if the thing to be deleted did
%   not occur in the collection.

bag_del_element(Bag1, E, M, Bag2) :-
	integer(M),
	(   M > 0 ->
	    bag_del_element_1(Bag1, E, M, Bag2)
	;   M < 0 -> 
	    N is -M,
	    bag_add_element_1(Bag1, E, N, Bag2)
	;/* M = 0 */
	    Bag2 = Bag1
	).


bag_del_element(Bag1, Element, Bag2) :-
	bag_del_element_1(Bag1, Element, 1, Bag2).


bag_del_element_1(bag, _, _, bag).
bag_del_element_1(bag(E1,M1,B1), E, M, Bag) :-
	compare(R, E1, E),
	bag_del_element_1(R, E, M, Bag, E1, M1, B1).


bag_del_element_1(<, E, M, bag(E1,M1,Bag2), E1, M1, B1) :-
	bag_del_element_1(B1, E, M, Bag2).
bag_del_element_1(=, E, M, Bag2, _, M1, B1) :-
	M2 is M1-M,
	(   M2 > 0 -> Bag2 = bag(E,M2,B1)
	;/* M2=< 0 */ Bag2 = B1
	).
bag_del_element_1(>, _, _, bag(E1,M1,B1), E1, M1, B1).



%   bag_subtract(+Bag1, +Bag2, ?Difference)
%   is true when Difference is the multiset difference of Bag1 and Bag2.

bag_subtract(bag, _, bag).
bag_subtract(bag(E1,M1,B1), Bag2, Difference) :-
	bag_subtract_1(Bag2, E1, M1, B1, Difference).

bag_subtract_1(bag, E1, M1, B1, bag(E1,M1,B1)).
bag_subtract_1(bag(E2,M2,B2), E1, M1, B1, Difference) :-
	compare(Order, E1, E2),
	bag_subtract(Order, E1, M1, B1, E2, M2, B2, Difference).

bag_subtract_2(bag, E2, M2, B2, bag(E2,M2,B2)).
bag_subtract_2(bag(E1,M1,B1), E2, M2, B2, Difference) :-
	compare(Order, E1, E2),
	bag_subtract(Order, E1, M1, B1, E2, M2, B2, Difference).

bag_subtract(<, E1, M1, B1, E2, M2, B2, bag(E1,M1,Difference)) :-
	bag_subtract_2(B1, E2, M2, B2, Difference).
bag_subtract(>, E1, M1, B1, _,  _,  B2, Difference) :-
	bag_subtract_1(B2, E1, M1, B1, Difference).
bag_subtract(=, E,  M1, B1, _,  M2, B2, Difference) :-
	(   M1 =< M2 ->		% do not include in result
	    bag_subtract(B1, B2, Difference)
	;   M is M1-M2,		% include with reduced multplicity
	    Difference = bag(E,M,B),
	    bag_subtract(B1, B2, B)
	).

