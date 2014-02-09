%   Package: avl
%   Author : Richard A. O'Keefe
%   Updated: 18 Jan 1994
%   Purpose: AVL trees in Prolog

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(avl, [
	avl_to_list/2,			% AVL -> List
	is_avl/1,			% AVL ->
	avl_change/5,			% Key -> (AVL x Val <-> AVL x Val)
	avl_domain/2,			% AVL -> OrdSet
	avl_fetch/2,			% Key x AVL ->
	avl_fetch/3,			% Key x AVL -> Val
	avl_height/2,			% AVL -> Height
	avl_incr/4,			% Key x AVL x Inc -> AVL
	avl_max/2,			% AVL -> Key
	avl_max/3,			% AVL -> Key x Val
	avl_member/2,			% Key x AVL
	avl_member/3,			% Key x AVL x Val
	avl_min/2,			% AVL -> Key
	avl_min/3,			% AVL -> Key x Val
	avl_next/3,			% Key x AVL -> Key
	avl_next/4,			% Key x AVL -> Key x Val
	avl_prev/3,			% Key x AVL -> Key
	avl_prev/4,			% Key x AVL -> Key x Val
	avl_range/2,			% AVL -> OrdSet
	avl_size/2,			% AVL -> Size
	avl_store/4,			% Key x AVL x Val -> Val
	empty_avl/1,			% -> AVL
	list_to_avl/2,			% List -> AVL
	ord_list_to_avl/2,		% List -> AVL
	portray_avl/1			% AVL ->
   ]).

sccs_id('"@(#)94/01/18 avl.pl	71.1"').

:- mode
	avl_to_list(+, ?),
	    avl_to_list(+, ?, ?),
	is_avl(+),
	    is_avl(+, +, -, -),
	avl_change(+, ?, ?, ?, ?),
	    avl_change(+, +, ?, ?, ?, ?, ?, ?, ?, ?),
	avl_domain(+, ?),
	    avl_domain(+, ?, +),
	avl_fetch(+, +),
	    avl_fetch_1(+, +, +, +),
	avl_fetch(+, +, ?),
	    avl_fetch_1(+, +, ?, +, +, +),
	avl_height(+, ?),
	    avl_height(+, +, ?),
	avl_member(?, +),
	avl_member(?, +, ?),
	avl_max(+, ?),
	    avl_max_1(+, ?, +),
	avl_max(+, ?, ?),
	    avl_max_1(+, ?, ?, +, +),
	avl_min(+, ?),
	    avl_min_1(+, ?, +),
	avl_min(+, ?, ?),
	    avl_min_1(+, ?, ?, +, +),
	avl_next(+, +, ?),
	avl_next(+, +, ?, ?),
	avl_prev(+, +, ?),
	avl_prev(+, +, ?, ?),
	avl_range(+, ?),
	    avl_range(+, ?, +),
	avl_size(+, ?),
	avl_store(+, +, +, ?),
	    avl_store(+, +, +, ?, -),
		avl_store(+, +, +, ?, -, +, +, +, +, +),
	empty_avl(?),
	list_to_avl(+, ?),
	    list_to_avl(+, +, ?),
	ord_list_to_avl(+, ?),
	    ord_list_to_avl(+, +, +, ?),
	portray_avl(+),
	    portray_avl(+, +, -),
	    portray_avl(+, +, +, +).



%   empty_avl(?AVL)
%   is true when AVL is an empty AVL tree.

empty_avl(empty).



%   avl_to_list(+AVL, ?List)
%   assumes that AVL is a proper AVL tree, and is true when
%   List is a list of Key-Value pairs in ascending order with no
%   duplicate keys specifying the same finite function as AVL.
%   Use this to convert an AVL to a(n ordered) list.

avl_to_list(AVL, List) :-
	avl_to_list(AVL, List, []).


avl_to_list(empty) --> [].
avl_to_list(node(K,V,_,L,R)) -->
	avl_to_list(L),
	[K-V],
	avl_to_list(R).



%   is_avl(+AVL)
%   is true when AVL is a (proper) AVL tree.  It checks both the order
%   condition (that the keys are in ascending order as you go from left
%   to right) and the height balance condition.  This code relies on
%   variables (to be precise, the first anonymous variable in is_avl/1)
%   being @< than any non-variable.  in strict point of fact you _can_
%   construct an AVL tree with variables as keys, but is_avl/1 doesn't
%   believe it, and it is not good taste to do so.

is_avl(AVL) :-
	is_avl(AVL, _, _, _).

is_avl(*, _, _, _) :- !, fail.
is_avl(empty, Min, Min, 0).
is_avl(node(Key,_,B,L,R), Min, Max, H) :-
	is_avl(L, Min, Mid, HL),
	Mid @< Key,
	is_avl(R, Key, Max, HR),
	B is HR-HL,
	( HL < HR -> H is HR+1 ; H is HL+1 ).



%   avl_domain(+AVL, ?Domain)
%   unifies Domain with the ordered set representation of the domain
%   of the AVL tree (the keys of it).  As the keys are in ascending
%   order with no duplicates, we just read them off like avl_to_list/2.

avl_domain(AVL, Domain) :-
	avl_domain(AVL, Domain, []).

avl_domain(empty, Domain, Domain).
avl_domain(node(Key,_,_,L,R), Domain0, Domain) :-
	avl_domain(L, Domain0, [Key|Domain1]),
	avl_domain(R, Domain1, Domain).



%   avl_range(+AVL, ?Range)
%   unifies Range with the ordered set representation of the range of the
%   AVL (the values associated with its keys, not the keys themselves).
%   Note that the cardinality (length) of the domain and the range are
%   seldom equal, except of course for trees representing intertible maps.

avl_range(AVL, Range) :-
	avl_range(AVL, Values, []),
	sort(Values, Range).


avl_range(empty, Values, Values).
avl_range(node(_,Val,_,L,R), Values0, Values) :-
	avl_range(L, Values0, [Val|Values1]),
	avl_range(R, Values1, Values).



%   avl_min(+AVL, ?Key)
%   is true when Key is the smallest key in AVL.

avl_min(node(K,_,_,L,_), MinKey) :-
	avl_min_1(L, MinKey, K).

avl_min_1(empty, K, K).
avl_min_1(node(K,_,_,L,_), MinKey, _) :-
	avl_min_1(L, MinKey, K).


%   avl_min(+AVL, ?Key, ?Val)
%   is true when Key is the smallest key in AVL and Val is its value.

avl_min(node(K,V,_,L,_), MinKey, MinVal) :-
	avl_min_1(L, MinKey, MinVal, K, V).

avl_min_1(empty, K, V, K, V).
avl_min_1(node(K,V,_,L,_), MinKey, MinVal, _, _) :-
	avl_min_1(L, MinKey, MinVal, K, V).



%   avl_max(+AVL, ?Key)
%   is true when Key is the greatest key in AVL.

avl_max(node(K,_,_,_,R), MaxKey) :-
	avl_max_1(R, MaxKey, K).

avl_max_1(empty, K, K).
avl_max_1(node(K,_,_,_,R), MaxKey, _) :-
	avl_max_1(R, MaxKey, K).


%   avl_max(+AVL, ?Key, ?Val)
%   is true when Key is the greatest key in AVL and Val is its value.

avl_max(node(K,V,_,_,R), MaxKey, MaxVal) :-
	avl_max_1(R, MaxKey, MaxVal, K, V).

avl_max_1(empty, K, V, K, V).
avl_max_1(node(K,V,_,R,_), MaxKey, MaxVal, _, _) :-
	avl_max_1(R, MaxKey, MaxVal, K, V).



%   avl_height(+AVL, ?Height)
%   is true when Height is the height of the given AVL tree, that is,
%   the longest path in the tree has Height 'node's on it.

avl_height(AVL, Height) :-
	avl_height(AVL, 0, Height).

avl_height(empty, H, H).
avl_height(node(_,_,B,L,R), H0, H) :-
	H1 is H0+1,
	(   B >= 0 -> avl_height(R, H1, H)
	;	      avl_height(L, H1, H)
	).



%   avl_size(+AVL, ?Size)
%   is true when Size is the size of the AVL tree, the number of 'node's in it.

avl_size(empty, 0).
avl_size(node(_,_,_,L,R), Size) :-
	avl_size(L, A),
	avl_size(R, B),
	Size is A+B+1.



%   portray_avl(+AVL)
%   writes an AVL tree to the current output stream in a pretty form so
%   that you can easily see what it is.  Note that an AVL tree written
%   out this way can NOT be read back in; for that use writeq/1.  The
%   point of this predicate is that you can add a directive
%	:- add_portray(portray_avl).
%   to get AVL trees displayed nicely by print/1.


portray_avl(empty) :-
	write('AVL{'),
	put("}").
portray_avl(node(K,V,B,L,R)) :-
	write('AVL{'),
	portray_avl(L, 0, X0),
	portray_avl(K, V, B, X0),
	portray_avl(R, 1, _),
	put("}").


portray_avl(empty, X, X).
portray_avl(node(K,V,B,L,R), X0, X) :-
	portray_avl(L, X0, X1),
	portray_avl(K, V, B, X1),
	portray_avl(R, 1, X).


portray_avl(K, V, B, X0) :-
	( X0 =:= 0 -> true ; put(0',) ),
	print(K),
	(   B < 0 -> write('*->')
	;   B > 0 -> write('->*')
	;            write('->')
	),
	print(V).



%   avl_member(?Key, +AVL)
%   is true when Key is one of the keys in the given AVL.  This
%   predicate should be used to enumerate the keys, not to look for
%   a particular key (use avl_fetch/2 or avl_fetch/3 for that).
%   The Keys are enumerated in ascending order.

avl_member(Key, node(K,_,_,L,R)) :-
	(   avl_member(Key, L)
	;   Key = K
	;   avl_member(Key, R)
	).


%   avl_member(?Key, +AVL, ?Val)
%   is true when Key is one of the keys in the given AVL and Val is
%   the value the AVL associates with that Key.  This predicate should
%   be used to enumerate the keys and their values, not to look up the
%   value of a known key (use avl_fetch/3) for that.
%   The Keys are enumerated in ascending order.

avl_member(Key, node(K,V,_,L,R), Val) :-
	(   avl_member(Key, L, Val)
	;   Key = K, Val = V
	;   avl_member(Key, R, Val)
	).



%   avl_fetch(+Key, +AVL)
%   is true when the (given) Key is one of the keys in the (given) AVL.
%   Use this to test whether a known Key occurs in AVL and you don't
%   want to know the value associated with it.

avl_fetch(Key, node(K,_,_,L,R)) :-
	compare(O, Key, K),
	avl_fetch_1(O, Key, L, R).


avl_fetch_1(=, _,   _, _).
avl_fetch_1(<, Key, node(K,_,_,L,R), _) :-
	compare(O, Key, K),
	avl_fetch_1(O, Key, L, R).
avl_fetch_1(>, Key, _, node(K,_,_,L,R)) :-
	compare(O, Key, K),
	avl_fetch_1(O, Key, L, R).

%   avl_fetch(+Key, +AVL, ?Val)
%   is true when the (given) Key is one of the keys in the (given) AVL
%   and the value associated with it therein is Val.  It should be
%   used to look up _known_ keys, not to enumerate keys (use either
%   avl_member/2 or avl_member/3 for that).

avl_fetch(Key, node(K,V,_,L,R), Val) :-
	compare(O, Key, K),
	avl_fetch_1(O, Key, Val, V, L, R).


avl_fetch_1(=, _,   Val, Val, _, _).
avl_fetch_1(<, Key, Val, _, node(K,V,_,L,R), _) :-
	compare(O, Key, K),
	avl_fetch_1(O, Key, Val, V, L, R).
avl_fetch_1(>, Key, Val, _, _, node(K,V,_,L,R)) :-
	compare(O, Key, K),
	avl_fetch_1(O, Key, Val, V, L, R).


%   avl_next(+Key, +AVL, ?Knext)
%   is true when Knext is the next key after Key in AVL;
%   that is, Knext is the smallest key in AVL such that Knext @> Key.

avl_next(Key, node(K,_,_,L,R), Knext) :-
	(   K @=< Key ->
	    avl_next(Key, R, Knext)
	;   avl_next(Key, L, K1) ->
	    Knext = K1
	;   Knext = K
	).


%   avl_next(+Key, +AVL, ?Knext, ?Vnext)
%   is true when Knext is the next key after Key in AVL and Vnext is the
%   value associated with Knext in AVL.  That is, Knext is the smallest
%   key in AVL such that Knext @> Key, and avl_fetch(Knext, Val, Vnext).

avl_next(Key, node(K,V,_,L,R), Knext, Vnext) :-
	(   K @=< Key ->
	    avl_next(Key, R, Knext, Vnext)
	;   avl_next(Key, L, K1, V1) ->
	    Knext = K1, Vnext = V1
	;   Knext = K,  Vnext = V
	).


%   avl_prev(+Key, +AVL, ?Kprev)
%   is true when Kprev is the key previous to Key in AVL;
%   that is, Kprev is the greatest key in AVL such that Kprev @< Key.

avl_prev(Key, node(K,_,_,L,R), Kprev) :-
	(   K @>= Key ->
	    avl_prev(Key, L, Kprev)
	;   avl_prev(Key, R, K1) ->
	    Kprev = K1
	;   Kprev = K
	).


%   avl_prev(+Key, +AVL, ?Kprev, ?Vprev)
%   is true when Kprev is the key previous to Key in AVL and Vprevext is the
%   value associated with Kprev in AVL.  That is, Kprev is the greatest key
%   in AVL such that Kprev @< Key, and avl_fetch(Kprev, AVL, Vprev).

avl_prev(Key, node(K,V,_,L,R), Kprev, Vprev) :-
	(   K @>= Key ->
	    avl_prev(Key, L, Kprev, Vprev)
	;   avl_prev(Key, R, K1, V1) ->
	    Kprev = K1, Vprev = V1
	;   Kprev = K,  Vprev = V
	).


%   avl_change(+Key, ?AVL1, ?Val1, ?AVL2, ?Val2)
%   is true when AVL1 and AVL2 are avl trees of exactly the same shape,
%   Key is a key of both of them, Val1 is the value associated with Key
%   in AVL1 and Val2 is the value associated with it in AVL2, and when
%   AVL1 and AVL2 are identical except perhaps for the value they assign
%   to Key.  Use this to change the value associated with a Key which is
%   already present, not to insert a new Key (it won't).

avl_change(Key, node(K,V1,B,L1,R1), Val1, node(K,V2,B,L2,R2), Val2) :-
	compare(O, Key, K),
	avl_change(O, Key, Val1, Val2, V1, V2, L1, R1, L2, R2).

avl_change(=, _,   Val1, Val2, Val1, Val2, L, R, L, R).
avl_change(<, Key, Val1, Val2, V, V,
		node(K,V1,B,L1,R1), R, node(K,V2,B,L2,R2), R) :-
	compare(O, Key, K),
	avl_change(O, Key, Val1, Val2, V1, V2, L1, R1, L2, R2).
avl_change(>, Key, Val1, Val2, V, V,
		L, node(K,V1,B,L1,R1), L, node(K,V2,B,L2,R2)) :-
	compare(O, Key, K),
	avl_change(O, Key, Val1, Val2, V1, V2, L1, R1, L2, R2).



%   ord_list_to_avl(+List, ?AVL)
%   is given a list of Key-Val pairs where the Keys are already in
%   standard order with no duplicates (this is not checked) and
%   returns an AVL representing the same associations.  This takes
%   O(N) time, unlike list_to_avl/2 which takes O(N.lg N).

ord_list_to_avl(List, AVL) :-
	length(List, N),
	ord_list_to_avl(N, List, [], _, AVL).

ord_list_to_avl(0, List, List, 0, empty) :- !.
ord_list_to_avl(N, List0, List, H, node(Key,Val,Bal,L,R)) :-
	A is (N-1) >> 1,
	Z is (N-1) - A,
	ord_list_to_avl(A, List0, [Key-Val|List1], HL, L),
	ord_list_to_avl(Z, List1, List, HR, R),
	Bal is HR - HL,
	( HR > HL -> H is HR + 1 ; H is HL + 1).


%   list_to_avl(+Pairs, ?AVL)
%   is given a list of Key-Val pairs where the Keys are in no particular
%   order (but are sufficiently instantiated to be told apart) and
%   returns an AVL representing the same associations.  This works by
%   starting with an empty tree and inserting the elements of the list
%   into it.  This takes O(N.lg N) time.  Since it is possible to read
%   off a sorted list in O(N) time from the result, N.lgN is as good as
%   can possibly be done.  If the same Key appears more than once in the
%   input, the last value associated with it will be used.

list_to_avl(Pairs, AVL) :-
	list_to_avl(Pairs, empty, AVL).


list_to_avl([], AVL, AVL).
list_to_avl([K-V|Pairs], AVL0, AVL) :-
	avl_store(K, AVL0, V, AVL1),
	list_to_avl(Pairs, AVL1, AVL).



%   avl_store(+Key, +OldAVL, +Val, +NewAVL)
%   is true when OldAVL and NewAVL define the same finite function
%   except that NewAVL associates Val with Key.  OldAVL need not have
%   associated any value at all with Key.  When it didn't, you can
%   read this as "insert (Key->Val) into OldAVL giving NewAVL".

avl_store(Key, AVL0, Val, AVL1) :-
	avl_store(AVL0, Key, Val, AVL1, _).


avl_store(empty,           Key, Val, node(Key,Val,0,empty,empty), 1).
avl_store(node(K,V,B,L,R), Key, Val, Result, Delta) :-
	compare(O, Key, K),
	avl_store(O, Key, Val, Result, Delta, K, V, B, L, R).


avl_store(=, Key, Val, node(Key,Val,B,L,R), 0, _, _, B, L, R).
avl_store(<, Key, Val, Result,          Delta, K, V, B, L, R) :-
	avl_store(L, Key, Val, Lavl, Ldel),
	Delta is \(B) /\ Ldel,	% this grew iff left grew and was balanced
	B1 is B-Ldel,
	(   B1 =:= -2 ->	% rotation needed
	    Lavl = node(Y,VY,OY,A,CD),	    
	    (   OY =< 0 ->
		NY is OY+1, NK is -NY,
		Result = node(Y,VY,NY,A,node(K,V,NK,CD,R))
	    ;/* OY = 1, double rotation needed */
		CD = node(X,VX,OX,C,D),
		NY is 0-((1+OX) >> 1),
		NK is (1-OX) >> 1,
		Result = node(X,VX,0,node(Y,VY,NY,A,C),node(K,V,NK,D,R))
	    )
	;   Result = node(K,V,B1,Lavl,R)
	).
avl_store(>, Key, Val, Result,          Delta, K, V, B, L, R) :-
	avl_store(R, Key, Val, Ravl, Rdel),
	Delta is \(B) /\ Rdel,	% this grew iff right grew and was balanced
	B1 is B+Rdel,
	(   B1 =:= 2 ->		% rotation needed
	    Ravl = node(Y,VY,OY,AC,D),
	    (   OY >= 0 ->
		NY is OY-1, NK is -NY,
		Result = node(Y,VY,NY,node(K,V,NK,L,AC),D)
	    ;/* OY = -1, double rotation needed */
		AC = node(X,VX,OX,A,C),
		NY is (1-OX) >> 1,
		NK is 0-((1+OX) >> 1),
		Result = node(X,VX,0,node(K,V,NK,L,A),node(Y,VY,NY,C,D))
	    )
	;   Result = node(K,V,B1,L,Ravl)
	).



%   avl_incr(+Key, +OldAVL, +Inc, +NewAVL)
%   if Key is not present in OldAVL, adds Key->Incr.
%   if Key->N is present in OldAvl, changes it to Key->N+Incr


avl_incr(Key, AVL0, Inc, AVL1) :-
	avl_incr(AVL0, Key, Inc, AVL1, _).


avl_incr(empty,           Key, Inc, node(Key,Inc,0,empty,empty), 1).
avl_incr(node(K,V,B,L,R), Key, Inc, Result, Delta) :-
	compare(O, Key, K),
	avl_incr(O, Key, Inc, Result, Delta, K, V, B, L, R).


avl_incr(=, Key, Inc, node(Key,Val,B,L,R), 0, _, V, B, L, R) :-
	Val is V+Inc.
avl_incr(<, Key, Inc, Result,          Delta, K, V, B, L, R) :-
	avl_incr(L, Key, Inc, Lavl, Ldel),
	Delta is \(B) /\ Ldel,	% this grew iff left grew and was balanced
	B1 is B-Ldel,
	(   B1 =:= -2 ->	% rotation needed
	    Lavl = node(Y,VY,OY,A,CD),	    
	    (   OY =< 0 ->
		NY is OY+1, NK is -NY,
		Result = node(Y,VY,NY,A,node(K,V,NK,CD,R))
	    ;/* OY = 1, double rotation needed */
		CD = node(X,VX,OX,C,D),
		NY is 0-((1+OX) >> 1),
		NK is (1-OX) >> 1,
		Result = node(X,VX,0,node(Y,VY,NY,A,C),node(K,V,NK,D,R))
	    )
	;   Result = node(K,V,B1,Lavl,R)
	).
avl_incr(>, Key, Inc, Result,          Delta, K, V, B, L, R) :-
	avl_incr(R, Key, Inc, Ravl, Rdel),
	Delta is \(B) /\ Rdel,	% this grew iff right grew and was balanced
	B1 is B+Rdel,
	(   B1 =:= 2 ->		% rotation needed
	    Ravl = node(Y,VY,OY,AC,D),
	    (   OY >= 0 ->
		NY is OY-1, NK is -NY,
		Result = node(Y,VY,NY,node(K,V,NK,L,AC),D)
	    ;/* OY = -1, double rotation needed */
		AC = node(X,VX,OX,A,C),
		NY is (1-OX) >> 1,
		NK is 0-((1+OX) >> 1),
		Result = node(X,VX,0,node(K,V,NK,L,A),node(Y,VY,NY,C,D))
	    )
	;   Result = node(K,V,B1,L,Ravl)
	).





end_of_file.

:- use_module(library(addportray), [add_portray/1]).

:- add_portray(portray_avl).

test :-
	list_to_avl([f-1,r-2,e-3,d-4,i-5,c-6,k-7,t-8,h-9,
		     g-10,a-11,o-12,u-13,s-14], empty, Result),
	print(* = Result), nl,
	avl_height(Result, Height),
	avl_size(Result, Size),
	write((size(*)=Size, height(*)=Height)), nl.

test2 :-
	list_to_avl([g-1,a-2,r-3,f-4,i-5,e-6,l-7,d-8], T),
	avl_min(T, K0),
	avl_next(K0, T, K1),
	avl_next(K1, T, K2),
	avl_next(K2, T, K3),
	avl_next(K3, T, K4),
	avl_next(K4, T, K5),
	avl_next(K5, T, K6),
	write([K0,K1,K2,K3,K4,K5,K6]).


test(N) :-
	insert_integers(N, empty, AVL),
	avl_size(AVL, Size),
	avl_height(AVL, Height),
	write(('N',size,height)=(N,Size,Height)), nl.

time(N) :-
	statistics(runtime, _),
	insert_integers(N, empty, _),
	statistics(runtime, [_,T1]),
	insert_integers(0, N, empty, _),
	statistics(runtime, [_,T2]),
	write((T1,T2)).

extremes(N) :-
	insert_integers(N, empty, X1),
	insert_integers(0, N, empty, X2),
	avl_min(X1, Min1), avl_max(X1, Max1),
	avl_min(X2, Min2), avl_max(X2, Max2),
	write((N,Min1,Max1,Min2,Max2)).

insert_integers(0, A, A) :- !.
insert_integers(N, A0, A) :-
	avl_store(N, A0, N, A1),
	M is N-1,
	insert_integers(M, A1, A).

insert_integers(N, N, A, A) :- !.
insert_integers(I, N, A0, A) :- 
	J is I+1,
	avl_store(J, A0, N, A1),
	insert_integers(J, N, A1, A).


del_min(node(K,V,B,L,R), AVL, Del, Key, Val) :-
	(   atom(L) -> Key = K, Val = V, AVL = R, Del = 1
	;   del_min(L, L1, D1, Key, Val),
	    <repair>(K,V,B,L1,R, D1, AVL, Del)
	).

del_max(node(K,V,B,L,R), AVL, Del, Key, Val) :-
	(   atom(R) -> Key = K, Val = V, AVL = L, Del = 1
	;   del_max(R, R1, D1, Key, Val).
	    <repair>(K,V,B,L,R1, D1, AVL, Del)
	).


delete(Key, AVL0, AVL)


delete(Key, AVL0, AVL) :-
	delete_1(AVL0, Key, AVL, _).

delete_1(empty, _, empty, 0).
delete_1(node(K,V,B,L,R), Key, AVL, Del) :-
	compare(R, Key, K),
	delete_1(R, Key, AVL, Del, K, V, B, L, R).

delete_1(=, _, AVL, Del, _, _, B, L, R) :-
	(   B =:= 0, atom(L) ->
	    AVL = empty, Del = 1
	;   B >= 0 ->
	    del_min(R, K, V, R1, D1),
	    B1 is B-D1,
	    AVL = node(K, V, B1, L, R1),
	    Del = 0
	;   B < 0 ->
	    del_max(L, K, V, L1, D1),
	    B1 is B+D1,
	    AVL = node(K, V, B1, L1, R)
	).
delete_1(<, Key, AVL, Del, K, V, B, L, R) :-
	delete_1(L, Key, L1, D1),
	B1 is B+D1,
	(   B1 < 2 ->
	    AVL = node(K,V,B1,L1,R),
	    Del = 0
	;/* B1 = 2, rotation needed */
	).
delete_1(>, Key, AVL, Del, K, V, B, L, R) :-
	delete_1(R, Key, R1, D1),
	B1 is B-D1,
	(   B1 > -2 ->
	    AVL = node(K,V,B1,L,R1),
	    Del = 0
	;/* B1 = -2, rotation needed */
	).
