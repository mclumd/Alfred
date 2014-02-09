%   Package: queues
%   Author : Richard A. O'Keefe
%   Updated: 4/3/90
%   Defines: queue operations (using difference lists)

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

%   NOTE: This library package is obsolete in release 3.0.  library(newqueues)
%	  should be used instead.

:- module(queues, [
	make_queue/1,		%   create empty queue
	join_queue/3,		%   add element to end of queue
	list_join_queue/3,	%   add many elements to end of queue
	jump_queue/3,		%   add element to front of queue
	list_jump_queue/3,	%   add many elements to front of queue
	head_queue/2,		%   look at first element of queue
	serve_queue/3,		%   remove first element of queue
	length_queue/2,		%   count elements of queue
	empty_queue/1,		%   test whether queue is empty
	is_queue/1,		%   recognise queues
	portray_queue/1,	%   print a queue
	list_to_queue/2,	%   convert list to queue
	queue_to_list/2		%   convert queue to list
   ]).

:- mode
	make_queue(-),
	join_queue(+, +, -),
	list_join_queue(+, +, -),
	jump_queue(+, +, -),
	list_jump_queue(+, +, -),
	head_queue(+, ?),
	serve_queue(+, ?, -),
	length_queue(+, ?),
	length_queue(+, +, +, -),
	empty_queue(+),
	is_queue(+),
	is_queue(+, +),
	portray_queue(+),
	portray_queue(+, +, +),
	list_to_queue(+, -),
	queue_to_list(+, -),
	queue_to_list(+, +, -).

sccs_id('@(#)queues.pl	58.1@(#) queues.pl 25 Oct 1990').


/*  In this package, a queue is represented as a term Front-Back,  where
    Front  is  a list and Back is a tail of that list, and is normally a
    variable.  join_queue will only work when the Back  is  a  variable,
    the  other routines will accept any tail.  The elements of the queue
    are the list difference, that is, all the elements starting at Front
    and stopping at Back.  Examples:

	[a,b,c,d,e|Z]-Z	    has elements a,b,c,d,e
	[a,b,c,d,e]-[d,e]   has elements a,b,c
	Z-Z		    has no elements
	[1,2,3]-[1,2,3]	    has no elements
*/

%   make_queue(Queue)
%   creates a new empty queue.  It will also match empty queues, but
%   because Prolog doesn't do the occurs check, it will also match
%   other queues, creating circular lists.  So this should ONLY be
%   used to make new queues.

make_queue(X-X).



%   join_queue(Element, OldQueue, NewQueue)
%   adds the new element at the end of the queue.  The old queue is
%   side-effected, so you *can't* do
%	join_queue(1, OldQ, NewQ1),
%	join_queue(2, OldQ, NewQ2).
%   There isn't any easy way of doing that, sensible though it might
%   be.  You *can* do
%	join_queue(1, OldQ, MidQ),
%	join_queue(2, MidQ, NewQ).
%   See list_join_queue.

join_queue(Element, Front-[Element|Back], Front-Back).



%   list_join_queue(List, OldQueue, NewQueue)
%   adds the new elements at the end of the queue.  The elements are
%   added in the same order that they appear in the list, e.g.
%   list_join_queue([y,z], [a,b,c|M]-M, [a,b,c,y,z|N]-N).

list_join_queue(List, Front-OldBack, Front-NewBack) :-
	append(List, NewBack, OldBack).



%   jump_queue(Element, OldQueue, NewQueue)
%   adds the new element at the front of the list.  Unlike join_queue,
%	jump_queue(1, OldQ, NewQ1),
%	jump_queue(2, OldQ, NewQ2)
%   *does* work, though if you add things at the end of NewQ1 they
%   will also show up in NewQ2.  Note that
%	jump_queue(1, OldQ, MidQ),
%	jump_queue(2, MidQ, NewQ)
%   makes NewQ start 2, 1, ...

jump_queue(Element, Front-Back, [Element|Front]-Back).



%   list_jump_queue(List, OldQueue, NewQueue)
%   adds all the elements of List at the front of the queue.  There  are
%   two  ways  we might do this.  We could add all the elements one at a
%   time, so that they would appear at the beginning of the queue in the
%   opposite order to the order they had in the list, or  we  could  add
%   them in one lump, so that they have the same order in the  queue  as
%   in  the  list.   As you can easily add the elements one at a time if
%   that is what you want, I have chosen the latter.

list_jump_queue(List, OldFront-Back, NewFront-Back) :-
	append(List, OldFront, NewFront).
%	reverse(List, OldFront, NewFront).	% for the other definition



%   head_queue(Queue, Head)
%   unifies Head with the first element of the queue.  The tricky part
%   is that we might be at the end of a queue: Back-Back, with Back a
%   variable, and in that case this predicate should not succeed, as we
%   don't know what that element is or whether it exists yet.

head_queue(Front-Back, Head) :-
	Front \== Back,		%  the queue is not empty
	Front = [Head|_].



%   serve_queue(OldQueue, Head, NewQueue)
%   removes the first element of the queue for service.

serve_queue(OldFront-Back, Head, NewFront-Back) :-
	OldFront \== Back,
	OldFront = [Head|NewFront].



%   empty_queue(Queue)
%   tests whether the queue is empty.  If the back of a queue were
%   guaranteed to be a variable, we could have
%	empty_queue(Front-Back) :- var(Front).
%   but I don't see why you shouldn't be able to treat difference
%   lists as queues if you want to.

empty_queue(Front-Back) :-
	Front == Back.



%   length_queue(Queue, Length)
%   counts the number of elements currently in the queue.  Note that
%   we have to be careful in checking for the end of the list, we
%   can't test for [] the way length(List) does.

length_queue(Front-Back, Length) :-
	length_queue(Front, Back, 0, N),
	Length = N.

length_queue(Front, Back, N, N) :-
	Front == Back, !.
length_queue([_|Front], Back, K, N) :-
	L is K+1,
	length_queue(Front, Back, L, N).



%   list_to_queue(List, Queue)
%   creates a new queue with the same elements as List.

list_to_queue(List, Front-Back) :-
	append(List, Back, Front).



%   queue_to_list(Queue, List)
%   creates a new list with the same elements as Queue.

queue_to_list(Front-Back, List) :-
	queue_to_list(Front, Back, List).

queue_to_list(Front, Back, Ans) :-
	Front == Back, !, Ans = [].
queue_to_list([Head|Front], Back, [Head|Tail]) :-
	queue_to_list(Front, Back, Tail).



%   is_queue(Queue)
%   is true when Queue is a queue.  It can only be used to recognise
%   queues, don't even think of using it to generate them.  The obvious
%   definition of is_queue/2 would have
%	is_queue([_|Tail], Back) :- is_queue(Tail, Back).
%   as its second clause.  Most of the time that would work fine.  But
%   if is_queue/2 were ever called with a first argument which was not
%   identical to Back but was a variable, that version would loop for-
%   ever.  This version, though clumsier, is guaranteed to terminate.

is_queue(Front-Back) :-
	is_queue(Front, Back).

is_queue(Front, Back) :-
	Front == Back,
	!.
is_queue(Front, Back) :-
	nonvar(Front),
	Front = [_|Tail],
	is_queue(Tail, Back).


%   portray_queue(Queue)
%   writes a queue out in a pretty form, as queue[elements].  This form
%   cannot be read back in, it is just supposed to be readable.  While it
%   is meant to be called only when is_queue(Queue) has been established,
%   as by portray(Q) :- is_queue(Q), !, portray_queue(Q).
%   it is also meant to work however it is called.

portray_queue(Front-Back) :-
	write('Queue['),
	portray_queue(Front, Back, '').

portray_queue(Front, Back, _) :-
	Front == Back,
	!,
	write(']').
portray_queue(Front, Back, Prefix) :-
	nonvar(Front),
	Front = [Head|Tail],
	!,
	write(Prefix), print(Head), 
	portray_queue(Tail, Back, ',').
portray_queue(Front, Back, _) :-
	write('|('), print(Front),
	write(')-'), print(Back),
	write(']').


