%   Package: newqueues
%   Author : Richard A. O'Keefe
%   Updated: 23 Aug 1990
%   Defines: queue operations (using Mark Johnson's method)
%   SeeAlso: library(mapqueue), library(listparts).

%   NOTE: This library package is new in release 3.0.  The old
%	  queues package remains available as library(queues).

%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

:- module(queues, [
	append_queue/3,		% List x Queue -> Queue
	empty_queue/1,		% -> Queue
	is_queue/1,		% Queue ->
	list_queue/2,		% List <-> Queue
	portray_queue/1,	% Queue ->
	queue_append/3,		% Queue x List -> Queue
	queue_cons/3,		% Item x Queue -> Queue
	queue_head/2,		% Queue -> Item
	queue_last/2,		% Queue -> Queue
	queue_last/3,		% Queue x Item -> Queue
	queue_length/2,		% Queue <-> Integer
	queue_list/2,		% Queue <-> List
	queue_member/2,		% Item x Queue
	queue_memberchk/2	% Item x Queue ->
   ]).

/*  This module provides an implementation of queues, where you can
	-- create an empty queue
	-- add an element at either end of a queue
	-- add a list of elements at either end of a queue
	-- remove an element from the front of a queue
	-- remove a list of elements from the front of a queue
	-- determine the length of a queue
	-- enumerate the elements of a queue
	-- recognise a queue
	-- print a queue nicely
    The representation was invented by Mark Johnson of the Center for
    the Study of Language and Information.  All operations are fast.
    The names of the predicates in this file are based on the names
    for parts of sequences defined in library(listparts).
*/

:- mode
	empty_queue(?),
	is_queue(+),	
	    is_queue(+, +, +),
	list_queue(+, ?),
	    list_queue(+, ?, ?, ?),
	queue_list(+, ?),
	    queue_list(+, ?, ?, +),
	queue_head(+, ?),
	queue_tail(?, ?),
	queue_cons(?, ?, ?),
	queue_last(?, ?),
	    queue_last_1(?, ?, ?, ?),
	queue_last(+, ?, ?),
	queue_append(+, ?, ?),
	    queue_append(+, ?, ?, ?, ?),
	append_queue(+, ?, ?),
	    append_queue(+, ?, ?, ?, ?),
	queue_length(?, ?),
	    queue_length_1(?, ?, ?, +, -),
	    queue_length_2(+, ?, ?, ?),
	queue_member(?, +),
	    queue_member(+, +, ?),
	queue_memberchk(+, +),
	    queue_memberchk(+, +, +),
	portray_queue(+),
	    portray_queue(+, +, +).


/* type unary --> z | s(unary).
:- type queue(T) --> queue(unary,list(T),list(T)).
:- pred
	empty_queue(queue(T)),
	is_queue(queue(T)),
	    is_queue(unary, list(T), list(T)),
	list_queue(list(T), queue(T)),
	    list_queue(list(T), unary, list(T), list(T)),
	queue_list(queue(T), list(T)),
	    queue_list(unary, list(T), list(T), list(T)),
	queue_head(queue(T), T),
	queue_tail(queue(T), queue(T)),
	queue_cons(T, queue(T), queue(T)),
	queue_last(T, queue(T)),
	    queue_last_1(unary, list(T), list(T), T),
	queue_last(queue(T), T, queue(T)),
	queue_append(queue(T), list(T), queue(T)),
	    queue_append(list(T), list(T), list(T), unary, unary),
	append_queue(list(T), queue(T), queue(T)),
	    append_queue(list(T), list(T), list(T), unary, unary),
	queue_length(queue(T), integer),
	    queue_length_1(unary, list(T), list(T), integer, integer),
	    queue_length_2(integer, unary, list(T), list(T)),
	queue_member(T, queue(T)),
	    queue_member(unary, list(T), T),
	queue_memberchk(T, queue(T)),
	    queue_memberchk(unary, list(T), T),
	portray_queue(queue(T)),
	    portray_queue(unary, list(T), atom).
*/

sccs_id('@(#)newqueues.pl	1.1@(#) newqueues.pl 23 Aug 1990').


/*  In this module, a queue is represented as a triple
	queue(Size, Front, Back)
    where                       n    1 0
	Size is a unary number, s(...s(z)...)
	Front is a list [X1,...,Xn|Back]
	Back is a suffix of Front, and is normally a variable.
    The elements of the queue are the list difference Front\Back, that
    is all the elements starting at Front and stopping at Back.  There
    are Size of them.  Examples:

	queue(s(s(s(s(s(z))))), [a,b,c,d,e|Z], Z)    has elements a,b,c,d,e
	queue(s(s(s(z))),       [a,b,c,d,e], [d,e])  has elements a,b,c
	queue(z, Z, Z)                               has no elements
	queue(z, [1,2,3], [1,2,3])                   has no elements
*/

%   empty_queue(?Queue)
%   is true when Queue represents an empty queue.  It can be used to
%   test whether an existing queue is empty or to make a new empty queue.

empty_queue(queue(z,L,L)).



%   portray_queue(+Queue)
%   writes a queue out in a pretty form, as Queue[elements].  This form
%   cannot be read back in, it is just supposed to be readable.  While it
%   is meant to be called only when is_queue(Queue) has been established,
%   as by portray(Q) :- is_queue(Q), !, portray_queue(Q).
%   it is also meant to work however it is called.

portray_queue(queue(Size,Front,_)) :-
	write('Queue['),
	portray_queue(Size, Front, '').

portray_queue(z, _, _) :-
	put("]").
portray_queue(s(N), [X|Front], Sep) :-
	write(Sep), print(X),
	portray_queue(N, Front, ',').


%   is_queue(+Queue)
%   is true when Queue is a queue.  The elements of Queue do not have
%   to be instantiated, and the Back of the Queue may or may not be.
%   It can only be used to recognise queues, not to generate them.
%   To generate queues, use queue_length(Queue, _).

is_queue(queue(Size,Front,Back)) :-
	is_queue(Size, Front, Back).

is_queue(*, _, _) :- !, fail.		% catch and reject variables
is_queue(z, Front, Back) :-
	Front == Back.
is_queue(s(N), [_|Front], Back) :-
	is_queue(N, Front, Back).



/*  The following five operations correspond precisely to the similarly
    named operations on lists.  See library(listparts).
*/

%   queue_head(+Queue, ?Head)
%   is true when Head is the first element of the given Queue.  It does
%   not remove Head from Queue; Head is still there afterwards.  It can
%   only be used to find Head, it cannot be used to make a Queue.

queue_head(queue(s(_),[Head|_],_), Head).



%   queue_tail(?Queue, ?Tail)
%   is true when Queue and Tail are both queues and Tail contains all the
%   elements of Queue except the first.  Note that Queue and Tail share
%   structure, so that you can add elements at the back of only one of them.
%   It can solve for either argument given the other.

queue_tail(queue(s(N),[_|Front],Back), queue(N,Front,Back)).



%   queue_cons(?Head, ?Tail, ?Queue)
%   is true when Head is the head of Queue and Tail is the tail of Queue,
%   that is, when Tail and Queue are both queues, and the elements of the
%   Queue are Head followed by the elements of Tail in order.  It can be
%   used in either direction, so
%	queue_cons(+Head, +Q0, -Q)	adds Head to Q0 giving Q
%	queue_cons(-Head, -Q, +Q0)	removes Head from Q0 giving Q

queue_cons(Head, queue(N,Front,Back), queue(s(N),[Head|Front],Back)).



%   queue_last(?Last, ?Queue)
%   is true when Last is the last element currently in Queue.  It does
%   not remove Last from Queue; it is still there.  This can be used to
%   generate a non-empty Queue.  The cost is O(|Queue|).

queue_last(Last, queue(s(N),Front,Back)) :-
	queue_last_1(N, Front, Back, Last).

queue_last_1(z, [Last|Back], Back, Last).
queue_last_1(s(N), [_|Front], Back, Last) :-
	queue_last_1(N, Front, Back, Last).



%   queue_last(+Fore, ?Last, ?Queue)
%   is true when Fore and Queue are both lists and the elements of Queue
%   are the elements of Fore in order followed by Last.  This is the
%   operation which adds an element at the end of Fore giving Queue;  it
%   is not reversible, unlike queue_cons/3, and it side-effects Fore,
%   again unlike queue_cons/3.  The normal use is
%	queue_last(+Q0, +Last, -Q)	add Last to Q0 giving Q

queue_last(queue(N,Front,[Last|Back]), Last, queue(s(N),Front,Back)).



%   append_queue(?List, ?Queue0, ?Queue)
%   is true when Queue is obtained by appending the elements of List
%   in order at the front of Queue0, e.g.
%   append_queue([a,b,c], Queue[d,e], Queue[a,b,c,d,e]).  Use
%	append_queue([+X1,...,+Xn], +Q0, -Q) to add X1,...,Xn to Q0 giving Q
%	append_queue([-X1,...,-Xn], -Q, +Q0) to take X1...Xn from Q0 giving Q
%   The cost is O(n) and the operation is pure.

append_queue(List, queue(N0,F0,B), queue(N1,F1,B)) :-
	append_queue(List, F0, F1, N0, N1).

append_queue([], F, F, N, N).
append_queue([H|T], F, [H|R], N0, s(N1)) :-
	append_queue(T, F, R, N0, N1).



%   queue_append(+Queue0, +List, ?Queue)
%   is true when Queue is obtained by appending the elements of List
%   in order at the rear end of Queue0, e.g.
%   append_queue(Queue[a,b,c], [d,e], Queue[a,b,c,d,e]).
%   This is like queue_last/3; it side-effects Queue0.

queue_append(queue(N0,F,B0), List, queue(N1,F,B1)) :-
	queue_append(List, B1, B0, N0, N1).

queue_append([], B, B, N, N).
queue_append([H|T], B, [H|R], N0, s(N1)) :-
	queue_append(T, B, R, N0, N1).



%   list_queue(?List, ?Queue)
%   is true when Queue is a queue and List is a list and both have
%   the same elements in the same order.  list_queue/2 and queue_list/2
%   are the same except for argument order.

list_queue(List, queue(Size,Front,Back)) :-
    (	var(List) ->
	queue_list(Size, List, Back, Front)
    ;	list_queue(List, Size, Back, Front)
    ).

list_queue([], z, Back, Back).
list_queue([Head|Tail], s(N), Back, [Head|Front]) :-
	list_queue(Tail, N, Back, Front).



%   queue_list(?Queue, ?List)
%   is true when Queue is a queue and List is a list and both have
%   the same elements in the same order.  queue_list/2 and list_queue/2
%   are the same except for argument order.

queue_list(queue(Size,Front,Back), List) :-
    (	var(Size) ->
	list_queue(List, Size, Back, Front)
    ;	queue_list(Size, List, Back, Front)
    ).

queue_list(z, [], Back, Back).
queue_list(s(N), [Head|Tail], Back, [Head|Front]) :-
	queue_list(N, Tail, Back, Front).



%   queue_length(?Queue, ?Length)
%   is true when Queue is a queue having Length elements.  It may be used
%   to determine the Length of a Queue or to make a Queue of given Length.

queue_length(queue(N,F,B), Length) :-
    (	var(Length) ->
	queue_length_1(N, F, B, 0, Length)
    ;	integer(Length) ->
	Length >= 0,
	queue_length_2(Length, N, F, B)
 %  ;	should_be(integer, Length, 2, queue_length(queue(N,F,B),Length))
    ).

queue_length_1(z, B, B, Length, Length).
queue_length_1(s(N), [_|F], B, Length0, Length) :-
	Length1 is Length0+1,
	queue_length_1(N, F, B, Length1, Length).

queue_length_2(0, z, B, B) :- !.
queue_length_2(L0, s(N), [_|F], B) :-
	L0 > 0,
	L1 is L0-1,
	queue_length_2(L1, N, F, B).



%   queue_member(?Element, +Queue)
%   is true when Element is an element of Queue.  It could be made to
%   generate queues, but that would be rather inefficient.  It bears
%   the name queue_member/2 because it is prepared to enumerate Elements.

queue_member(Element, queue(s(N),Front,_)) :-
	queue_member(N, Front, Element).

queue_member(z,    [Element|_], Element).
queue_member(s(_), [Element|_], Element).
queue_member(s(N), [_|Front],   Element) :-
	queue_member(N, Front, Element).



%   queue_memberchk(+Element, +Queue)
%   is true when the given Element is an element of Queue.  Once it finds
%   a member of Queue which unifies with Element, it commits to it.  Use
%   it to check a ground Element.

queue_memberchk(Element, queue(s(N),Front,_)) :-
	queue_memberchk(N, Front, Element).

queue_memberchk(z,    [Element|_], Element).
queue_memberchk(s(_), [Element|_], Element) :- !.
queue_memberchk(s(N), [_|Front],   Element) :-
	queue_memberchk(N, Front, Element).




