%   Package: more_maps
%   Author : Richard A. O'Keefe
%   Updated: 13 Jul 1989
%   Purpose: More predicates for mapping down lists.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(more_maps, [
	convlist/3,
	exclude/3,
	exclude/4,
	exclude/5,
	include/3,
	include/4,
	include/5,
	partition/5,
	group/3,
	group/4,
	group/5
   ]).

:- meta_predicate
	convlist(2, +, ?),
	    conv_list(+, ?, 2),
	exclude(1, +, ?),
	    exclude_list(+, ?, 1),
	exclude(2, +, +, ?),
	    exclude_list(+, +, ?, 2),
	exclude(3, +, +, +, ?),
	    exclude_list(+, +, +, ?, 3),
	include(1, +, ?),
	    include_list(+, ?, 1),
	include(2, +, +, ?),
	    include_list(+, +, ?, 2),
	include(3, +, +, +, ?),
	    include_list(+, +, +, ?, 3),
	partition(2, +, ?, ?, ?),
	    partition_1(+, 2, ?, ?, ?),
	        partition_1(+, +, ?, ?, ?, +, 2),
	group(2, +, ?),
	    group1(+, ?, 2),
	group(1, +, ?, ?),
	group(2, +, +, ?, ?).

:- use_module(library(call), [
	call/2,
	call/3,
	call/4
   ]).

/* pred
	convlist(void(T,U), list(T), list(U)),
	    conv_list(list(T), list(U), void(T,U)),
	exclude(void(T), list(T), list(T)),
	    exclude_list(list(T), list(T), void(T)),
	include(void(T), list(T), list(T)),
	    include_list(list(T), list(T), void(T)),
	partition(void(T,order), list(T), list(T), list(T), list(T)),
	    partition_1(list(T), void(T,order), list(T), list(T), list(T)),
		partition_1(order, T, list(T), list(T), list(T),
			    void(T,order), list(T)),
	group(void(T,T), list(T), list(list(T))),
	    group1(list(T), list(list(T)), void(T,T)),
	group(void(T,T), list(T), list(T), list(T)),
	group(void(T,T), T, list(T), list(T), list(T)).
*/

sccs_id('"@(#)89/07/13 moremaps.pl	32.1"').



%   convlist(+Rewrite, +OldList, ?NewList)
%   is a sort of hybrid of maplist/3 and include/3.
%   Each element of NewList is the image under Rewrite of some
%   element of OldList, and order is preserved, but elements of
%   OldList on which Rewrite is undefined (fails) are not represented.
%   Thus if foo(K,X,Y) :- integer(X), Y is X+K.
%   then convlist(foo(1), [1,a,0,joe(99),101], [2,1,102]).
%   OldList should be a proper list.

convlist(Pred, Olds, News) :-
	conv_list(Olds, News, Pred).


conv_list([], [], _).
conv_list([Old|Olds], NewList, Pred) :-
	call(Pred, Old, New),
	!,
	NewList = [New|News],
	conv_list(Olds, News, Pred).
conv_list([_|Olds], News, Pred) :-
	conv_list(Olds, News, Pred).



%   exclude(+Pred, +List, ?SubList)
%   succeeds when SubList is the SubList of List containing all the
%   elements for which Pred(Elem) is *false*.  That is, it removes
%   all the elements satisfying Pred.  List should be a proper list.

exclude(Pred, List, SubList) :-
	exclude_list(List, SubList, Pred).


exclude_list([], [], _).
exclude_list([Head|Tail], SubList, Pred) :-
	call(Pred, Head),
	!,
	exclude_list(Tail, SubList, Pred).
exclude_list([Head|Tail], [Head|SubTail], Pred) :-
	exclude_list(Tail, SubTail, Pred).



%   exclude(+Pred, +Xs, +Ys, +Es)
%   is true when Es is the sublist of Xs containing all the elements Xi
%   for which Pred(Xi, Yi) is *false*.  Xs should be a proper list, and
%   Ys should be at least as long as Xs (it may be longer).

exclude(Pred, Xs, Ys, Rs) :-
	exclude_list(Xs, Ys, Rs, Pred).


exclude_list([], _, [], _).
exclude_list([X|Xs], [Y|Ys], Rs, Pred) :-
	call(Pred, X, Y),
	!,
	exclude_list(Xs, Ys, Rs, Pred).
exclude_list([X|Xs], [_|Ys], [X|Rs], Pred) :-
	exclude_list(Xs, Ys, Rs, Pred).



%   exclude(+Pred, +Xs, +Ys, +Zs, +Es)
%   is true when Es is the sublist of Xs containing all the elements Xi
%   for which Pred(Xi, Yi, Zi) is *false*.  Xs should be a proper list,
%   and Ys and Zs should be at least as long as Xs (they may be longer).

exclude(Pred, Xs, Ys, Zs, Rs) :-
	exclude_list(Xs, Ys, Zs, Rs, Pred).


exclude_list([], _, _, [], _).
exclude_list([X|Xs], [Y|Ys], [Z|Zs], Rs, Pred) :-
	call(Pred, X, Y, Z),
	!,
	exclude_list(Xs, Ys, Zs, Rs, Pred).
exclude_list([X|Xs], [_|Ys], [_|Zs], [X|Rs], Pred) :-
	exclude_list(Xs, Ys, Zs, Rs, Pred).



%   include(+Pred, +List, ?SubList)
%   succeeds when SubList is the SubList of List containing all the
%   elements for which Pred(Elem) is *true*.  That is, it retains
%   all the elements satisfying Pred.  List should be a proper list.

include(Pred, List, SubList) :-
	include_list(List, SubList, Pred).


include_list([], [], _).
include_list([Head|Tail], SubList, Pred) :-
	call(Pred, Head),
	!,
	SubList = [Head|SubTail],
	include_list(Tail, SubTail, Pred).
include_list([_|Tail], SubList, Pred) :-
	include_list(Tail, SubList, Pred).



%   include(+Pred, +Xs, +Ys, +Es)
%   is true when Es is the sublist of Xs containing all the elements Xi
%   for which Pred(Xi, Yi) is *true*.   Xs should be a proper list, and
%   Ys should be at least as long as Xs (it may be longer).

include(Pred, Xs, Ys, Rs) :-
	include_list(Xs, Ys, Rs, Pred).


include_list([], _, [], _).
include_list([X|Xs], [Y|Ys], Rs, Pred) :-
	call(Pred, X, Y),
	!,
	Rs = [X|Rs1],
	include_list(Xs, Ys, Rs1, Pred).
include_list([_|Xs], [_|Ys], Rs, Pred) :-
	include_list(Xs, Ys, Rs, Pred).



%   include(+Pred, +Xs, +Ys, +Zs, +Es)
%   is true when Es is the sublist of Xs containing all the elements Xi
%   for which Pred(Xi, Yi, Zi) is *false*.  Xs should be a proper list,
%   and Ys and Zs should be at least as long as Xs (they may be longer).

include(Pred, Xs, Ys, Zs, Rs) :-
	include_list(Xs, Ys, Zs, Rs, Pred).


include_list([], _, _, [], _).
include_list([X|Xs], [Y|Ys], [Z|Zs], Rs, Pred) :-
	call(Pred, X, Y, Z),
	!,
	Rs = [X|Rs1],
	include_list(Xs, Ys, Zs, Rs1, Pred).
include_list([_|Xs], [_|Ys], [_|Zs], Rs, Pred) :-
	include_list(Xs, Ys, Zs, Rs, Pred).



%   partition(+Pred, +List, ?Less, ?Equal, ?Greater)
%   is a relative of include/3 and exclude/3 which has some pretensions
%   to being logical.  For each X in List, we call Pred(X,R), and route
%   X to Less, Equal, or Greater according as R is <, =, or > .
%   Note that the argument order of the built-in predicate compare/3 is
%   not what we want here, so you will typically have to write your own
%   interface predicate (see library(order) for some examples).

partition(Pred, List, Less, Equal, Greater) :-
	partition_1(List, Pred, Less, Equal, Greater).

partition_1([], _, [], [], []).
partition_1([X|Xs], Pred, L, E, G) :-
	call(Pred, X, R),
	partition_1(R, X, L, E, G, Xs, Pred).

partition_1(<, X, [X|L], E, G, Xs, Pred) :-
	partition_1(Xs, Pred, L, E, G).
partition_1(=, X, L, [X|E], G, Xs, Pred) :-
	partition_1(Xs, Pred, L, E, G).
partition_1(>, X, L, E, [X|G], Xs, Pred) :-
	partition_1(Xs, Pred, L, E, G).



%   group(+Pred, +List, ?Front, ?Back)
%   is true when append(Front, Back, List), maplist(Pred, Front),
%   and Front is as long as possible.

group(Pred, [Head|Tail], Front, Back) :-
	call(Pred, Head),
	!,
	Front = [Head|Rest],
	group(Pred, Tail, Rest, Back).
group(_, Back, [], Back).


%   group(+Pred, +Key, +List, ?Front, ?Back)
%   is true when append(Front, Back, List), maplist(call(Pred,Key), Front),
%   and Front is as long as possible.  Strictly speaking we don't need it;
%   group(call(Pred,Key), List, Front, Back) would do just as well.

group(Pred, Key, [Head|Tail], Front, Back) :-
	call(Pred, Key, Head),
	!,
	Front = [Head|Rest],
	group(Pred, Key, Tail, Rest, Back).
group(_, _, Back, [], Back).


%   group(+Pred, +List, ?ListOfLists)
%   is true when append(ListOfLists, List), each element of ListOfLists
%   has the form [Head|Tail] such that group(Pred, Head, Tail, Tail, []),
%   and each element of ListOfLists is as long as possible.  For example,
%   if you have a keysorted list, and define same_key(K-_, K-_), then
%   group(same_key, List, Buckets) will divide List up into Buckets of
%   pairs having the same key.

group(Pred, List, ListOfLists) :-
	group1(List, ListOfLists, Pred).

group1([], [], _).
group1([Head|Tail], [[Head|Front]|ListOfLists], Pred) :-
	group(Pred, Head, Tail, Front, Back),
	group1(Back, ListOfLists, Pred).

