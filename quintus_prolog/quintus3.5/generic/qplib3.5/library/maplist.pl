%   Package: maplist
%   Author : Lawrence Byrd + Richard A. O'Keefe
%   Updated: 02 Nov 1988
%   Purpose: Various "function" application routines based on library(call).

%   Adapted from shared code written by the same authors; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(maplist, [
	checklist/2,			% obsolete: use maplist/2
	cumlist/4,
	cumlist/5,
	cumlist/6,
	maplist/2,
	maplist/3,
	maplist/4,
	map_product/4,
	scanlist/4,
	scanlist/5,
	scanlist/6,
	some/2,
	some/3,
	some/4,
	somechk/2,
	somechk/3,
	somechk/4
   ]).
/*  There are five general families:
	maplist(P, [X11,...,X1n], ..., [Xm1,...,Xmn]) :-
	    P(X11, ..., Xm1),
	    ...
	    P(Xm1, ..., Xmn).

	scanlist(P, [X11,...,X1n], ..., [Xm1,...,Xmn], V0, Vn) :-
	    P(X11, ..., Xm1, V0, V1),
	    ...
	    P(Xm1, ..., Xmn, V', Vn).

	cumlist(P, [X11,...,X1n], ..., [Xm1,...,Xmn], V1, [V1,...,Vn]) :-
	    P(X11, ..., Xmn, V0, V1),
	    ...
	    P(Xm1, ..., Xmn, V', Vn).


	some(P, [X11,...,X1n], ..., [Xm1,...,Xmn]) :-
	    P(X11, ..., Xm1)
	  ; ...
	  ; P(Xm1, ..., Xmn).

	somechk(P, [X11,...,X1n], ..., [Xm1,...,Xmn]) :-
	    P(X11, ..., Xm1) -> true
	  ; ...
	  ; P(Xm1, ..., Xmn) -> true.

    Ideally, {maplist,some,somechk}/N would exist for all N >= 2
    and {cumlist,scanlist}/N would exist for all N >= 4.
    At the moment, only the ones I have had occasion to use exist.
    The names may be changed before the package becomes supported.
    Note that the argument order of the predicate argument to the
    scanlist/4 predicate was changed in May 1988.  This was so that

    A general characteristic of these families is that the order of
    arguments passed to Pred is the same as the order of the
    arguments following Pred.  This close correspondence helps you
    keep track of which argument goes where.

    Several other predicates (convlist/3, exclude/3, include/3, and
    partition/5) have moved into a new file library(moremaps) where
    some additional new predicates will be found.
*/

:- meta_predicate
	checklist(1, +),
	cumlist(3, +, ?, ?),
	    cum_list(+, ?, ?, 3),
	cumlist(4, ?, ?, ?, ?),
	    cum_list(?, ?, ?, ?, 4),
	cumlist(5, ?, ?, ?, ?, ?),
	    cum_list(?, ?, ?, ?, ?, 5),
	maplist(1, ?),
	    map_list(?, 1),
	maplist(2, ?, ?),
	    map_list(?, ?, 2),
	maplist(3, ?, ?, ?),
	    map_list(?, ?, ?, 3),
	map_product(3, +, +, ?),
	    map_product_1(+, +, ?, ?, 3),
		map_product_2(+, +, ?, ?, 3),
	scanlist(3, +, ?, ?),
	    scan_list(+, ?, ?, 3),
	scanlist(4, ?, ?, ?, ?),
	    scan_list(?, ?, ?, ?, 4),
	scanlist(5, ?, ?, ?, ?, ?),
	    scan_list(?, ?, ?, ?, ?, 5),
	some(1, ?),
	some(2, ?, ?),
	some(3, ?, ?, ?),
	somechk(1, +),
	somechk(2, +, +),
	somechk(3, +, +, +).
:- use_module(library(call), [
	call/2,
	call/3,
	call/4,
	call/5,		% for {cum,scan}list/5
	call/6		% for {cum,scan}list/6
   ]).

sccs_id('"@(#)88/11/02 maplist.pl	27.2"').

/* pred
	checklist(void(T), list(T)),
	cumlist(void(T,U,U), list(T), U, list(U)),
	    cum_list(list(T), U, list(U), void(T,U,U)),
	cumlist(void(S,T,U,U), list(S), list(T), U, list(U)),
	    cum_list(list(S), list(T), U, list(U), void(S,T,U,U)),
	cumlist(void(R,S,T,U,U), list(R), list(S), list(T), U, list(U)),
	    cum_list(list(R), list(S), list(T), U, list(U), void(R,S,T,U,U)),
	maplist(void(T), list(T)),
	    map_list(list(T), void(T)),
	maplist(void(T,U), list(T), list(U)),
	    map_list(list(T), list(U), void(T,U)),
	maplist(void(T,U,V), list(T), list(U), list(V)),
	    map_list(list(T), list(U), list(V), void(T,U,V)),
	map_product(void(U,V,T), list(U), list(V), list(T)),
	    map_product_1(list(U), list(V), list(T), list(T), void(U,V,T)),
		map_product_2(list(V), U, list(T), list(T), void(U,V,T)),
	scanlist(void(T,U,U), list(T), U, U),
	    scan_list(list(T), U, U, void(T,U,U)),
	scanlist(void(S,T,U,U), list(S), list(T), U, U),
	    scan_list(list(S), list(T), U, U, void(S,T,U,U)),
	scanlist(void(R,S,T,U,U), list(R), list(S), list(T), U, U),
	    scan_list(list(R), list(S), list(T), U, U, void(R,S,T,U,U)),
	some(void(T), list(T)),
	some(void(T,U), list(T), list(U)),
	some(void(T,U,V), list(T), list(U), list(V)),
	somechk(void(T), list(T)),
	somechk(void(T,U), list(T), list(U)),
	somechk(void(T,U,V), list(T), list(U), list(V)).


    The <foo>list predicates are retained for backwards compatibility with
    the Dec-10 Prolog library.  They all take a void(...) argument as their
    first argument.  The <foo>_list predicates take the void(...)
    argument *last* so as to exploit indexing on the first argument.
    Putting the Pred argument first is still considered to be the better
    style as far as human reading and comprehension is concerned, and
    putting it last is not recommended for exported predicates.

    BEWARE: the scanlist/4 predicate changed subtly in May 1988 when it
    was generalised to the scanlist/N family.  If you were passing
    commutative functions to it, you won't notice any change, but the
    new version is simpler than the old.
*/


%   checklist(Pred, List)
%   suceeds when Pred(Elem) succeeds for each Elem in the List.
%   In InterLisp, this is EVERY.  It is also MAPC.
%   List should be a proper list.

checklist(Pred, List) :-
	map_list(List, Pred).



%   cumlist(Pred, [X1,...,Xn], V0, [V1,...,Vn])
%   maps a ternary predicate Pred down the list [X1,...,Xn] just as
%   scanlist/4 does, and returns a list of the results.  It terminates
%   when either list runs out.  If Pred is bidirectional, it may be
%   used to derive [X1...Xn] from V0 and [V1...Vn], e.g.
%   cumlist(plus, [1,2,3,4], 0, /* -> */ [1,3,6,10]) and
%   cumlist(plus, [1,1,1,1], /* <- */ 0, [1,2,3,4]).

cumlist(Pred, List, V0, Cum) :-
	cum_list(List, V0, Cum, Pred).

cum_list([], _, [], _).
cum_list([X|Xs], V0, [V1|Vs], Pred) :-
	call(Pred, X, V0, V1),
	cum_list(Xs, V1, Vs, Pred).


cumlist(Pred, Xs, Ys, V0, Cum) :-
	cum_list(Xs, Ys, V0, Cum, Pred).

cum_list([], [], _, [], _).
cum_list([X|Xs], [Y|Ys], V0, [V1|Vs], Pred) :-
	call(Pred, X, Y, V0, V1),
	cum_list(Xs, Ys, V1, Vs, Pred).


cumlist(Pred, Xs, Ys, Zs, V0, Cum) :-
	cum_list(Xs, Ys, Zs, V0, Cum, Pred).

cum_list([], [], [], _, [], _).
cum_list([X|Xs], [Y|Ys], [Z|Zs], V0, [V1|Vs], Pred) :-
	call(Pred, X, Y, Z, V0, V1),
	cum_list(Xs, Ys, Zs, V1, Vs, Pred).



%   maplist(Pred, List)
%   succeeds when Pred(X) succeeds for each element X of List.
%   This is identical to the (now obsolete) predicate checklist/2.

maplist(Pred, List) :-
	map_list(List, Pred).

map_list([], _).
map_list([X|Xs], Pred) :-
	call(Pred, X),
	map_list(Xs, Pred).



%   maplist(Pred, OldList, NewList)
%   succeeds when Pred(Old,New) succeeds for each corresponding
%   Old in OldList, New in NewList.  In InterLisp, this is MAPCAR. 
%   It is also MAP2C.  Isn't bidirectionality wonderful?
%   Either OldList or NewList should be a proper list.

maplist(Pred, Olds, News) :-
	map_list(Olds, News, Pred).

map_list([], [], _).
map_list([Old|Olds], [New|News], Pred) :-
	call(Pred, Old, New),
	map_list(Olds, News, Pred).



%   maplist(Pred, Xs, Ys, Zs)
%   is true when Xs, Ys, and Zs are lists of equal length, and
%   Pred(X, Y, Z) is true for corresponding elements X of Xs,
%   Y of Ys, and Z of Zs.
%   At least one of Xs, Ys, and Zs should be a proper list.

maplist(Pred, Xs, Ys, Zs) :-
	map_list(Xs, Ys, Zs, Pred).

map_list([], [], [], _).
map_list([X|Xs], [Y|Ys], [Z|Zs], Pred) :-
	call(Pred, X, Y, Z),
	map_list(Xs, Ys, Zs, Pred).



%   map_product(Pred, Xs, Ys, PredOfProduct)
%   Just as maplist(P, Xs, L) is the analogue of Miranda's
%	let L = [ P x | x <- Xs ]
%   so map_product(P, Xs, Ys, L) is the analogue of Miranda's
%	let L = [ P x y | x <- Xs; y <- Ys ]
%   That is, if Xs = [X1,...,Xm], Ys = [Y1,...,Yn], and P(Xi,Yj,Zij),
%   L = [Z11,...,Z1n,Z21,...,Z2n,...,Zm1,...,Zmn]
%   It is as if we formed the cartesian product of Xs and Ys and
%   applied P to the (Xi,Yj) pairs.

map_product(Pred, Xs, Ys, Answer) :-
	map_product_1(Xs, Ys, Answer, [], Pred).

map_product_1([], _, A, A, _).
map_product_1([X|Xs], Ys, A0, A, Pred) :-
	map_product_2(Ys, X,  A0, A1, Pred),
	map_product_1(Xs, Ys, A1, A,  Pred).

map_product_2([], _, A, A, _).
map_product_2([Y|Ys], X, [Z|A1], A, Pred) :-
	call(Pred, X, Y, Z),
	map_product_2(Ys, X, A1, A, Pred).



%   scanlist(Pred, List, V1, V)
%   maps a ternary relation Pred down a list.  If the list is
%   [X1,X2,...,Xn], the computation is
%   Pred(X1,V1,V2), Pred(X2,V2,V3), ..., Pred(Xn,Vn,V)
%   So if Pred is plus/3, scanlist(plus, List, 0, V) puts the
%   sum of the list elements in V.
%   List should be a proper list.
%   Note that the order of the arguments passed to Pred is the same
%   as the order of the arguments following Pred.  This also holds
%   for scanlist/5 and scanlist/6, e.g.
%   scanlist(Pred, Xs, Ys, Zs, V1, V) calls Pred(X3,Y3,Z3,V3,V4).

scanlist(Pred, List, V0, V) :-
	scan_list(List, V0, V, Pred).

scan_list([], V, V, _).
scan_list([X|Xs], V0, V, Pred) :-
	call(Pred, X, V0, V1),
	scan_list(Xs, V1, V, Pred).


scanlist(Pred, Xs, Ys, V0, V) :-
	scan_list(Xs, Ys, V0, V, Pred).

scan_list([], [], V, V, _).
scan_list([X|Xs], [Y|Ys], V0, V, Pred) :-
	call(Pred, X, Y, V0, V1),
	scan_list(Xs, Ys, V1, V, Pred).


scanlist(Pred, Xs, Ys, Zs, V0, V) :-
	scan_list(Xs, Ys, Zs, V0, V, Pred).

scan_list([], [], [], V, V, _).
scan_list([X|Xs], [Y|Ys], [Z|Zs], V0, V, Pred) :-
	call(Pred, X, Y, Z, V0, V1),
	scan_list(Xs, Ys, Zs, V1, V, Pred).



%   some(Pred, List)
%   succeeds when Pred(Elem) succeeds for some Elem in List.  It will
%   try all ways of proving Pred for each Elem, and will try each Elem
%   in the List.  somechk/2 is to some/2 as memberchk/2 is to member/2;
%   you are more likely to want somechk with its single solution.
%	member(X,L)	<-> some(=(X), L).
%	memberchk(X, L)	<-> somechk(=(X), L).
%	some(Pred,L)    <-> member(X, L), call(Pred,X).
%   In InterLisp this is SOME.
%   This acts on backtracking like member/2; List should be a proper list.

some(Pred, [X|_]) :-
	call(Pred, X).
some(Pred, [_|Xs]) :-
	some(Pred, Xs).


%   some(Pred, [X1,...,Xn], [Y1,...,Yn])
%   is true when Pred(Xi, Yi) is true for some i.

some(Pred, [X|_], [Y|_]) :-
	call(Pred, X, Y).
some(Pred, [_|Xs], [_|Ys]) :-
	some(Pred, Xs, Ys).



%   some(Pred, [X1,...,Xn], [Y1,...,Yn], [Z1,...,Zn])
%   is true when Pred(Xi, Yi, Zi) is true for some i.

some(Pred, [X|_], [Y|_], [Z|_]) :-
	call(Pred, X, Y, Z).
some(Pred, [_|Xs], [_|Ys], [_|Zs]) :-
	some(Pred, Xs, Ys, Zs).



%   somechk(Pred, [X1,...,Xn])
%   is true when Pred(Xi) is true for some i, and it commits to
%   the first solution it finds (like memberchk/2).

somechk(Pred, [X|_]) :-
	call(Pred, X),
	!.
somechk(Pred, [_|Xs]) :-
	somechk(Pred, Xs).


%   somechk(Pred, [X1,...,Xn], [Y1,...,Yn])
%   is true when Pred(Xi, Yi) is true for some i, and it commits to
%   the first solution it finds (like memberchk/2).

somechk(Pred, [X|_], [Y|_]) :-
	call(Pred, X, Y),
	!.
somechk(Pred, [_|Xs], [_|Ys]) :-
	somechk(Pred, Xs, Ys).


%   somechk(Pred, [X1,...,Xn], [Y1,...,Yn], [Z1,...,Zn])
%   is true when Pred(Xi, Yi, Zn) is true for some i, and it commits to
%   the first solution it finds (like memberchk/2).

somechk(Pred, [X|_], [Y|_], [Z|_]) :-
	call(Pred, X, Y, Z),
	!.
somechk(Pred, [_|Xs], [_|Ys], [_|Zs]) :-
	somechk(Pred, Xs, Ys, Zs).



%   There used to be a predicate sublist(Pred, List, SubList) 
%   which was identical to include(Pred, List, SubList) in all but name.
%   The name sublist/3 was needed in library(length), so the redundant
%   sublist/3 has been withdrawn from this file.


/*  Example:
	maplist(include(atom), [[a,1,2,b],[3,c],[4,5,6],[d,e]], L)
  binds L = [[a,b],[c],[],[d,e]].
	maplist(exclude(atom), [[a,1,2,b],[3,c],[4,5,6],[d,e]], L)
  binds L = [[1,2],[3],[4,5,6],[]].
*/

