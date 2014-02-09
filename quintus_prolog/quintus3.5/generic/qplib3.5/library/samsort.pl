%   Package: samsort
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Purpose: a sorting routine which exploits existing order

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(samsort, [
	keymerge/3,
	merge/3,
	merge/4,
	samkeysort/2,
	samsort/2,
	samsort/3
   ]).

:- meta_predicate
	merge(2, +, +, ?),
	    sam_merge(+, +, 2, ?),
	samsort(2, +, ?),
	    sam_sort(+, 2, +, +, ?),
		sam_run(+, +, +, 2, -, -),
		    sam_rest(+, +, +, +, 2, -, -),
		sam_fuse(+, 2, ?),
		sam_fuse(+, +, 2, +, ?).

:- use_module(library(call), [
	call/3
   ]).

/*  This package defines three sorting routines:

	samkeysort(+Raw:list(pair(K,T)), ?Ordered:list(pair(K,T)))
	    Raw should be a list of Key-Value pairs.  This list is
	    sorted into non-decreasing order of Keys (pairs with
	    the same Key are left in the order they originally had)
	    and the result is unified with Ordered.  This is just
	    the same as keysort/2 but is done differently.

	samsort(+Raw:list(T), ?Ordered:list(T))
	    Raw is a list of arbitrary terms.  This list is sorted
	    into non-decreasing (standard) order, and the result is
	    unified with Ordered.  This is like sort/2, except that
	    sort/2 discards duplicate terms, and samsort/2 keeps them.

	samsort(+Order:void(T,T), +Raw:list(T), ?Ordered:list(T))
	    Raw is a list of terms.  This list is sorted into
	    non-descreasing order as defined by the Order predicate,
	    and the result is unified with Ordered.  This is like
	    samsort/2, except that you can define your own ordering.

    In samsort/3, Order is to act like (@=<)/2.  In particular, if
    you call samsort(@=<, X, Y), you'll get exactly the same result
    that you'd have got from samsort(X, Y) only slower.  An earlier
    version of this package wanted a predicate like (@<)/2, but as
    the other library files (library(ordered), library(ordprefix))
    want something like (@=<)/2, this file was changed to conform.

    The name "samsort" comes from "Smooth Applicative Merge sort".
    The algorithm is of my own invention.  It is a variant of the
    natural merge, and can exploit descending order in the Raw
    list as well as asscending order.

    The sorting routines use merging routines which may be useful:

	merge(+X:list(T), +Y:list(T), ?Merged:list(T))
	merge(+Order:void(T,T), +X:list(T), +Y:list(T), ?Merged:list(T))
	keymerge(+X:list(pair(K,T)), +Y:list(pair(K,T)),
		 ?Merged:list(pair(K,T))

    merge/3 is based on the built-in predicate (@=<)/2, while
    merge/4 lets you specify as Order your own ordering predicate.
    keymerge/3 is like merge/3 but only compares the Keys of two
    pairs.
*/

sccs_id('"@(#)89/08/29 samsort.pl	33.1"').


%   samsort(+RawList, ?Sorted)
%   is given a proper list RawList and unifies Sorted with a list
%   having exactly the same elements as RawList but in ascending
%   order according to the standard order on terms.  That is,
%   append(_, [X,Y|_], Sorted) -> \+(Y@<X).

samsort(List, Sorted) :-
	sam_sort(List, [], 0, Sorted).

sam_sort([], Stack, _, Sorted) :-
	sam_fuse(Stack, Sorted).
sam_sort([Head|Tail], Stack, R, Sorted) :-
	sam_run(Tail, [Head|Queue], [Head|Queue], Run, Rest),
	S is R+1,
	sam_fuse(Stack, Run, S, NewStack),
	sam_sort(Rest, NewStack, S, Sorted).


sam_fuse([], []).
sam_fuse([Run|Stack], Sorted) :-
	sam_fuse(Stack, Run, 0, [Sorted]).

sam_fuse([B|Rest], A, K, Ans) :-
	0 is K /\ 1,
	!,
	J is K >> 1,
	sam_merge(B, A, C),
	sam_fuse(Rest, C, J, Ans).
sam_fuse(Stack, Run, _, [Run|Stack]).


sam_run([], Run, [_], Run, []).
sam_run([Head|Tail], QH, QT, Run, Rest) :-
	sam_rest(QH, QT, Head, Tail, Run, Rest).


%   For true stability, less_equal_head/2 in the second clause of
%   sam_rest/6 should be less_than_head/2 (@< rather than @=<),
%   but as we are sorting entire terms this is safe and faster.

sam_rest(Qh, [Last|Qt], Head, Tail, Run, Rest) :-
	Last @=< Head,
	!,
	Qt = [Head|_],
	sam_run(Tail, Qh, Qt, Run, Rest).
sam_rest(Qh, Qt, Head, Tail, Run, Rest) :-
	less_equal_head(Head, Qh),
	!,
	sam_run(Tail, [Head|Qh], Qt, Run, Rest).
sam_rest(Run, [_], Head, Tail, Run, [Head|Tail]).


less_equal_head(X, [H|_]) :-
	X @=< H.


%   merge(+List1, +List2, -Merged)
%   is true when Merged is the stable merge of the two given lists.
%   If the two lists are not ordered, the merge doesn't mean a great
%   deal.  Merging is perfectly well defined when the inputs contain
%   duplicates, and all copies of an element are preserved in the
%   output, e.g. merge("122357", "34568", "12233455678").

merge(List1, List2, Merged) :-
	sam_merge(List1, List2, Steadfast),
	Merged = Steadfast.


sam_merge(L1, [X|L2], [X|M1]) :-
	less_than_head(X, L1),
	!,
	sam_merge(L1, L2, M1).
sam_merge([X|L1], L2, [X|M1]) :-
	sam_merge(L1, L2, M1).
sam_merge([], L2, L2).


less_than_head(X, [H|_]) :-
	X @< H.



%   samsort(+Order, +RawList, ?SortedList)
%   is given a proper list RawList and a binary predicate Order
%   (note that it may be an N-ary predicate with the first N-2
%   arguments already filled in) and unifies SortedList with a
%   sorted version of RawList, in that append(_, [X,Y|_], Sorted)
%   -> \+Order(Y,X).  This is only supposed to work when Order
%   is transitive.

samsort(Order, List, Sorted) :-
	sam_sort(List, Order, [], 0, Sorted).

sam_sort([], Order, Stack, _, Sorted) :-
	sam_fuse(Stack, Order, Sorted).
sam_sort([Head|Tail], Order, Stack, R, Sorted) :-
	sam_run(Tail, [Head|Queue], [Head|Queue], Order, Run, Rest),
	S is R+1,
	sam_fuse(Stack, Run, Order, S, NewStack),
	sam_sort(Rest, Order, NewStack, S, Sorted).


sam_fuse([], _, []).
sam_fuse([Run|Stack], Order, Sorted) :-
	sam_fuse(Stack, Run, Order, 0, [Sorted]).

sam_fuse([B|Rest], A, Order, K, Ans) :-
	0 is K /\ 1,
	!,
	J is K >> 1,
	sam_merge(B, A, Order, C),
	sam_fuse(Rest, C, Order, J, Ans).
sam_fuse(Stack, Run, _, _, [Run|Stack]).


sam_run([], Run, [_], _, Run, []).
sam_run([Head|Tail], QH, QT, Order, Run, Rest) :-
	sam_rest(QH, QT, Head, Tail, Order, Run, Rest).


sam_rest(Qh, [Last|Qt], Head, Tail, Order, Run, Rest) :-
	call(Order, Last, Head),
	!,
	Qt = [Head|_],
	sam_run(Tail, Qh, Qt, Order, Run, Rest).
sam_rest(Run, [_], Head, Tail, Order, Run, [Head|Tail]) :-
	head_less_equal(Order, Run, Head),
	!.
sam_rest(Qh, Qt, Head, Tail, Order, Run, Rest) :-
	sam_run(Tail, [Head|Qh], Qt, Order, Run, Rest).


head_less_equal(Order, [H|_], X) :-
	call(Order, H, X).



%   merge(+Order, +List1, +List2, -Merged)
%   is like merge/3 except that it takes an Order predicate as its
%   first arguments, like all the generalised ordering routines.
%   For efficiency, it calls sam_merge/4.

merge(Order, List1, List2, Merged) :-
	sam_merge(List1, List2, Order, Steadfast),
	Merged = Steadfast.


sam_merge(List1, [], _, List1) :- !.
sam_merge([], List2, _, List2) :- !.
sam_merge([Head1|Tail1], [Head2|Tail2], Order, [Head1|Merged]) :-
	call(Order, Head1, Head2),
	!,
	sam_merge(Tail1, [Head2|Tail2], Order, Merged).
sam_merge(List1, [Head2|Tail2], Order, [Head2|Merged]) :-
	sam_merge(List1, Tail2, Order, Merged).



%   samkeysort(+RawList, ?Sorted)
%   is given a proper list RawList of Key-Value pairs, and unifies
%   Sorted with a list having exactly the same elements as RawList
%   but in ascending order according to the standard order on the
%   keys.  That is, append(_, [X-_,Y-_|_], Sorted) -> \+(Y@<X).

samkeysort(List, Sorted) :-
	sam_key_sort(List, [], 0, Sorted).

sam_key_sort([], Stack, _, Sorted) :-
	sam_key_fuse(Stack, Sorted).
sam_key_sort([Head|Tail], Stack, R, Sorted) :-
	sam_key_run(Tail, [Head|Queue], [Head|Queue], Run, Rest),
	S is R+1,
	sam_key_fuse(Stack, Run, S, NewStack),
	sam_key_sort(Rest, NewStack, S, Sorted).


sam_key_fuse([], []).
sam_key_fuse([Run|Stack], Sorted) :-
	sam_fuse(Stack, Run, 0, [Sorted]).

sam_key_fuse([B|Rest], A, K, Ans) :-
	0 is K /\ 1,
	!,
	J is K >> 1,
	keymerge(B, A, C),
	sam_key_fuse(Rest, C, J, Ans).
sam_key_fuse(Stack, Run, _, [Run|Stack]).


sam_key_run([], Run, [_], Run, []).
sam_key_run([Head|Tail], QH, QT, Run, Rest) :-
	sam_key_rest(QH, QT, Head, Tail, Run, Rest).


sam_key_rest(Qh, [Last|Qt], Head, Tail, Run, Rest) :-
	key_less_equal(Last, Head),
	!,
	Qt = [Head|_],
	sam_key_run(Tail, Qh, Qt, Run, Rest).
sam_key_rest(Qh, Qt, Head, Tail, Run, Rest) :-
	key_less_head(Head, Qh),
	!,
	sam_key_run(Tail, [Head|Qh], Qt, Run, Rest).
sam_key_rest(Run, [_], Head, Tail, Run, [Head|Tail]).


key_less_equal(K1-_, K2-_) :-
	K1 @=< K2.

key_less_head(K1-_, [K2-_|_]) :-
	K1 @< K2.



%   keymerge(+List1, +List2, -Merged)
%   is like merge/3 except that it compares only the keys of its input
%   lists.  Note that it will not work properly when Merged is already
%   instantiated.

keymerge(List1, List2, Merged) :-
	sam_key_merge(List1, List2, Steadfast),
	Merged = Steadfast.


sam_key_merge(L1, [X|L2], [X|M1]) :-
	key_less_head(X, L1),
	!,
	sam_key_merge(L1, L2, M1).
sam_key_merge([X|L1], L2, [X|M1]) :-
	sam_key_merge(L1, L2, M1).
sam_key_merge([], L2, L2).


