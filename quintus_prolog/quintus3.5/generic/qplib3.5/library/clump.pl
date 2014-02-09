%   Package: clump
%   Author : Richard A. O'Keefe
%   Updated: 28 Aug 1989
%   Purpose: Group adjacent related elements of lists

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(clump, [
	clumped/2,
	clumps/2,
	keyclumped/2,
	keyclumps/2
   ]).

sccs_id('"@(#)89/08/28 clump.pl	33.1"').


%   clumps(+Items, ?Clumps)
%   is true when Clumps is a list of lists such that
%   (a) append(Clumps, Items)
%   (b) for each Clump in Clumps, all the elements of Clump are identical (==)
%   Items must be a proper list of terms for which sorting would have been
%   sound.  In fact, it usually is the result of sorting.
    
clumps([], []).
clumps([Item|Items], [Clump|Clumps]) :-
	clumps(Items, Item, Clump, Clumps).


clumps([], Key, [Key], []).
clumps([Item|Items], Key, [Key|Clump], Clumps) :-
	compare(O, Key, Item),
	clumps(O, Item, Clump, Clumps, Items).


clumps(=, Item, Clump, Clumps, Items) :-
	clumps(Items, Item, Clump, Clumps).
clumps(<, Item, [], [Clump|Clumps], Items) :-
	clumps(Items, Item, Clump, Clumps).
clumps(>, Item, [], [Clump|Clumps], Items) :-
	clumps(Items, Item, Clump, Clumps).



%   keyclumps(+Pairs, ?Clumps)
%   is true when Pairs is a list of pairs and Clumps a list of lists such that
%   (a) append(Clumps, Pairs)
%   (b) for each Clump in Clumps, all of the Key-Value pairs in Clump have
%   identical (==) Keys.
%   Pairs must be a proper list of pairs for which keysorting would have
%   been sound.  In fact, it usually is the result of keysorting.

keyclumps([], []).
keyclumps([Pair|Pairs], [Clump|Clumps]) :-
	keyclumps(Pairs, Pair, Clump, Clumps).


keyclumps([], Prev, [Prev], []).
keyclumps([Pair|Pairs], Prev, [Prev|Clump], Clumps) :-
	keycompare(O, Prev, Pair),
	keyclumps(O, Pair, Clump, Clumps, Pairs).


keyclumps(=, Pair, Clump, Clumps, Pairs) :-
	keyclumps(Pairs, Pair, Clump, Clumps).
keyclumps(<, Pair, [], [Clump|Clumps], Pairs) :-
	keyclumps(Pairs, Pair, Clump, Clumps).
keyclumps(>, Pair, [], [Clump|Clumps], Pairs) :-
	keyclumps(Pairs, Pair, Clump, Clumps).


keycompare(O, K1-_, K2-_) :-
	compare(O, K1, K2).



%   clumped(+Items, ?Counts)
%   is true when Counts is a list of Item-Count pairs such that
%   if clumps(Items, Clumps), then each Item-Count pair in Counts corresponds
%   to an element [Item/*1*/,...,Item/*Count*/] of Clumps.
%   Items must be a proper list of terms for which sorting would have been
%   sound.  In fact, it usually is the result of sorting.

clumped([], []).
clumped([Item|Items], Clumps) :-
	clumped(Items, Item, 1, Clumps).


clumped([], Key, Count, [Key-Count]).
clumped([Item|Items], Key, Count0, Counts) :-
	compare(O, Key, Item),
	clumped(O, Item, Count0, Counts, Items, Key).


clumped(=, Item, Count0, Counts, Items, _) :-
	Count1 is Count0+1,
	clumped(Items, Item, Count1, Counts).
clumped(<, Item, Count, [Key-Count|Counts], Items, Key) :-
	clumped(Items, Item, 1, Counts).
clumped(>, Item, Count, [Key-Count|Counts], Items, Key) :-
	clumped(Items, Item, 1, Counts).



%   keyclumped(+Pairs, ?Groups)
%   is true when Pairs is a list of Key-Item pairs and
%   Groups is a list of Key-Items pairs such that
%   if keyclumps(Pairs, Clumps), then for each K-[I1,...,In] pair in Groups
%   there is a [K-I1,...,K-In] clump in Clumps.
%   Pairs must be a proper list of pairs for which keysorting would have
%   been sound.  In fact, it usually is the result of keysorting.

keyclumped([], []).
keyclumped([Key-Item|Pairs], [Key-[Item|Items]|Groups]) :-
	keyclumped(Pairs, Key, Items, Groups).


keyclumped([], _, [], []).
keyclumped([Next-Item|Pairs], Key, Items, Groups) :-
	compare(O, Key, Next),
	keyclumped(O, Key, Items, Groups, Next, Item, Pairs).


keyclumped(=, Key, [Item|Items], Groups, _, Item, Pairs) :-
	keyclumped(Pairs, Key, Items, Groups).
keyclumped(<, _, [], [Key-[Item|Items]|Groups], Key, Item, Pairs) :-
	keyclumped(Pairs, Key, Items, Groups).
keyclumped(>, _, [], [Key-[Item|Items]|Groups], Key, Item, Pairs) :-
	keyclumped(Pairs, Key, Items, Groups).



end_of_file.

/*  TEST CODE */

t1 :-
	clumps([m,i,s,s,i,s,s,i,p,p,i], X),
	write(mississippi=X).

t2 :-
	clumped([m,i,s,s,i,s,s,i,p,p,i], X),
	write(mississippi=X).

t3 :-
	keyclumps([m-1,i-2,s-3,s-4,i-5,s-6,s-7,i-8,p-9,p-a,i-b], X),
	write(mississippi=X).

t4 :-
	keyclumped([m-1,i-2,s-3,s-4,i-5,s-6,s-7,i-8,p-9,p-a,i-b], X),
	write(mississippi=X).

