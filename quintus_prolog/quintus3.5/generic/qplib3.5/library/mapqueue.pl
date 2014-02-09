%   Package: mapqueue
%   Author : Richard A. O'Keefe
%   Updated: 03 Apr 1990
%   Defines: mapping operations over queues (see library(queues,maplist))

%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

:- module(mapqueue, [
	map_queue/2,		% Pred x Queue ->
	map_queue/3,		% Pred x Queue x Queue
	map_queue_list/3,	% Pred x Queue x List
	map_list_queue/3,	% Pred x List x Queue
	some_queue/2,		% Pred x Queue
	some_queue/3,		% Pred x Queue x Queue
	somechk_queue/2,	% Pred x Queue ->
	somechk_queue/3		% Pred x Queue x Queue ->
   ]).
/*  This module is based on library(maplist).  Analogues of all the
    predicates in that file could be defined; I have chosen not to do
    that in this edition of library(mapqueue) but merely to show how
    such analogues are constructed.

    The three families of mapping predicates represente here are

	map_queue(P, Queue[X11,...,X1n], ..., Queue[Xm1,...,Xmn]) :-
	    P(X11, ..., Xm1),
	    ...
	    P(Xm1, ..., Xmn).

	some_queue(P, Queue[X11,...,X1n], Queue[Xm1,...,Xmn]) :-
	    P(X11, ..., Xm1)
	  ; ...
	  ; P(Xm1, ..., Xmn).

	somechk_queue(P, Queue[X11,...,X1n], Queue[Xm1,...,Xmn]) :-
	    P(X11, ..., Xm1) -> true
	  ; ...
	  ; P(Xm1, ..., Xmn) -> true.

    Ideally these predicates would exist for all N >= 2.

    There are also two "mixed" predicates
	map_queue_list(P, Queue[X11,...,X1n], [X21,...,X2n])
	map_list_queue(P, [X11,...,X1n], Queue[X21,...,X2n])
    to show how such mixed predicates might be coded.
*/

:- meta_predicate
	map_queue(1, ?),
	map_queue(2, ?, ?),
	map_queue_list(2, ?, ?),
	map_list_queue(2, ?, ?),
	some_queue(1, ?),
	some_queue(2, ?, ?),
	somechk_queue(1, ?),
	somechk_queue(2, ?, ?).


:- use_module(library(call), [
	call/2,
	call/3
   ]).

:- mode
	map_queue(+, ?),
	    mapqueue(?, ?, ?, +),
	map_queue(+, ?, ?),
	    mapqueue(?, ?, ?, ?, ?, +),
	some_queue(+, +),
	    somequeue(+, +, +),
	some_queue(+, +, +),
	    somequeue(+, +, +, +),
	somechk_queue(+, +),
	    somechkqueue(+, +, +),
	somechk_queue(+, +, +),
	    somechkqueue(+, +, +, +).


/* type unary --> z | s(unary).
:- type queue(T) --> queue(unary,list(T),list(T)).
:- pred
	map_queue(void(T), queue(T)),
	    mapqueue(unary, list(T), list(T), void(T)),
	map_queue(void(S,T), queue(S), queue(T)),
	    mapqueue(unary, list(S), list(S), list(T), list(T), void(S,T)),
	map_queue_list(void(S,T), queue(S), list(T)),
	    mapqueue(unary, list(S), list(S), list(T), list(T), void(S,T)),
	map_list_queue(void(S,T), list(S), queue(T)),
	    mapqueue(unary, list(S), list(S), list(T), list(T), void(S,T)),
	some_queue(void(T), queue(T)),
	    somequeue(unary, list(T), void(T)),
	some_queue(void(S,T), queue(S), queue(T)),
	    somequeue(unary, list(S), list(T), void(S,T)),
	somechk_queue(void(T), queue(T)),
	    somechkqueue(unary, list(T), void(T)),
	somechk_queue(void(S,T), queue(S), queue(T)),
	    somechkqueue(unary, list(S), list(T), void(S,T)).
*/

sccs_id('@(#)mapqueue.pl	39.1@(#) mapqueue.pl 03 Apr 1990').



%   map_queue(Pred, Queue[X1,...,Xn])
%   succeeds when Pred(Xi) succeeds for each element Xi of the Queue.

map_queue(Pred, queue(Size,F1,B1)) :-
	mapqueue(Size, F1, B1, Pred).

mapqueue(z, B1, B1, _).
mapqueue(s(N), [X1|F1], B1, Pred) :-
	call(Pred, X1),
	mapqueue(N, F1, B1, Pred).


%   map_queue(Pred, Queue[X1,...,Xn], Queue[Y1,...,Yn])
%   succeeds when Pred(Xi,Yi) succeeds for each corresponding pair
%   of elements Xi, Yi of the two Queues.

map_queue(Pred, queue(Size,F1,B1), queue(Size,F2,B2)) :-
	mapqueue(Size, F1, B1, F2, B2, Pred).

mapqueue(z, B1, B1, B2, B2, _).
mapqueue(s(N), [X1|F1], B1, [X2|F2], B2, Pred) :-
	call(Pred, X1, X2),
	mapqueue(N, F1, B1, F2, B2, Pred).



%   map_queue_list(Pred, Queue[X1,...,Xn], [Y1,...,Yn])
%   succeeds when Pred(Xi, Yi) is true for each corresponding pair Xi,Yi
%   of elements of the Queue and the List.  It may be used to generate
%   either of the sequences from the other.

map_queue_list(Pred, queue(N,F,B), L) :-
    (	var(N) ->
	map_list_queue_2(L, N, F, B, Pred)
    ;	map_queue_list_1(N, F, B, L, Pred)
    ).

map_queue_list_1(z, B, B, [], _).
map_queue_list_1(s(N), [X1|F], B, [X2|L], Pred) :-
	call(Pred, X1, X2),
	map_queue_list_1(N, F, B, L, Pred).

map_queue_list_2(z, B, B, [], _).
map_queue_list_2(s(N), [X2|F], B, [X1|L], Pred) :-
	call(Pred, X1, X2),	% note arguments swapped
	map_queue_list_2(N, F, B, L, Pred).


%   map_list_queue(Pred, [X1,...,Xn], Queue[Y1,...,Yn])
%   succeeds when Pred(Xi, Yi) is true for each corresponding pair Xi,Yi
%   of elements of the List and the Queue.  It may be used to generate
%   either of the sequences from the other.

map_list_queue(Pred, L, queue(N,F,B)) :-
    (	var(N) ->
	map_list_queue_1(L, N, F, B, Pred)
    ;	map_queue_list_2(N, F, B, L, Pred)
    ).

map_list_queue_1([], z, B, B, _).
map_list_queue_1([X1|L], s(N), [X2|F], B, Pred) :-
	call(Pred, X1, X2),
	map_list_queue_1(L, N, F, B, Pred).

map_list_queue_2([], z, B, B, _).
map_list_queue_2([X2|L], s(N), [X1|F], B, Pred) :-
	call(Pred, X1, X2),	% note arguments swapped.
	map_list_queue_2(L, N, F, B, Pred).



%   some_queue(Pred, Queue[X1,...,Xn])
%   succeeds when Pred(Xi) succeeds for some Xi in the Queue.  It will
%   try all ways of proving Pred(Xi) for each Xi, and will try each Xi
%   in the Queue.  somechk_queue/2 is to some_queue/2 as memberchk/2
%   is to member/2; you are more likely to want somechk_queue.
%   This acts on backtracking like member/2; Queue should be proper.

some_queue(Pred, queue(Size,F1,_)) :-
	somequeue(Size, F1, Pred).

somequeue(s(_), [X1|_], Pred) :-
	call(Pred, X1).
somequeue(s(N), [_|F1], Pred) :-
	somequeue(N, F1, Pred).


%   some_queue(Pred, Queue[X1,...,Xn], Queue[Y1,...,Yn])
%   is true when Pred(Xi, Yi) is true for some i.

some_queue(Pred, queue(Size,F1,_), queue(Size,F2,_)) :-
	somequeue(Size, F1, F2, Pred).

somequeue(s(_), [X1|_], [X2|_], Pred) :-
	call(Pred, X1, X2).
somequeue(s(N), [_|F1], [_|F2], Pred) :-
	somequeue(N, F1, F2, Pred).



%   somechk_queue(Pred, Queue[X1,...,Xn])
%   is true when Pred(Xi) is true for some i, and it commits to
%   the first solution it finds (like memberchk/2).

somechk_queue(Pred, queue(Size,F1,_)) :-
	somechkqueue(Size, F1, Pred).

somechkqueue(s(_), [X1|_], Pred) :-
	call(Pred, X1),
	!.
somechkqueue(s(N), [_|F1], Pred) :-
	somechkqueue(N, F1, Pred).


%   somechk_queue(Pred, Queue[X1,...,Xn], Queue[Y1,...,Yn])
%   is true when Pred(Xi, Yi) is true for some i, and it commits to
%   the first solution it finds (like memberchk/2).

somechk_queue(Pred, queue(Size,F1,_), queue(Size,F2,_)) :-
	somechkqueue(Size, F1, F2, Pred).

somechkqueue(s(_), [X1|_], [X2|_], Pred) :-
	call(Pred, X1, X2),
	!.
somechkqueue(s(N), [_|F1], [_|F2], Pred) :-
	somechkqueue(N, F1, F2, Pred).


