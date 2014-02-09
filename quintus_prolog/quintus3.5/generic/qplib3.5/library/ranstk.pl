%   Package: ranstk
%   Author : Richard A. O'Keefe
%   Updated: 01 Nov 1988
%   Defines: Random-access stacks

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(ranstk, [
	cons_rs/3,
	empty_rs/1,
	index_rs/3,
	length_rs/2,
	top_rs/2,
	portray_rs/1
   ]).

sccs_id('"@(#)88/11/01 ranstk.pl	27.2"').

/*  This is a Prolog implementation of the algorithms in

	"An Applicative Random-Access Stack"
	Eugene W. Myers
	TR 83-9, Dept of CS, University of Arizona.


    The operations provided are

	empty_rs(?EmptyStack)				O(1)
	cons_rs(?Datum, ?ShortStack, ?FullStack)	O(1)
	top_rs(+Stack, ?Datum)				O(1)
	length_rs(+Stack, ?Length)			O(1)
	index_rs(+N, +Stack, ?Datum)			O(lg length)
	portray_rs(+Stack)				O(length)

    We could do all these operations with lists, but then index_rs/3
    would be O(L) rather than O(lg L).  We could do them with binary
    trees, but then push_rs/3 and pop_rs/3 would be O(lg L) too.

    A random access stack is represented by
	empty_rs
    |	push_rs(Length,Datum,Next,Jump)
*/



%   empty_rs(?Stack)
%   is true when Stack represents an empty stack

empty_rs(empty_rs).



%   length_rs(?Stack, ?Length)
%   is true when the Stack has length Length.  The elements are numbered
%   1..Length, with the first to be pushed being #1, and the last being
%   #Length.  The original version was just length_rs_1/2,
%   but that requires the Stack to be instantiated.  This version can be
%   used to make a Stack of a given Length, or to enumerate Stacks and
%   Lengths in ascending order.

length_rs(Stack, Length) :-
	(   nonvar(Stack) ->
	    length_rs_1(Stack, Length)
	;   var(Length) ->
	    length_rs_1(0, Length, empty_rs, Stack)
	;   integer(Length) ->
	    Length >= 0,
	    length_rs_1(Length, empty_rs, Stack)
	).


%.  length_rs_1(+Stack, ?Length)
%   return the length of a known stack

length_rs_1(empty_rs, 0).
length_rs_1(push_rs(Length,_,_,_), Length).


%.  length_rs_1(+N0, -N, +Stack0, -Stack)
%   enumerate Stacks of length N >= N0 where length_rs(Stack0, N0).

length_rs_1(N, N, Stack, Stack).
length_rs_1(N0, N, Stack0, Stack) :-
	N1 is N0+1,
	cons_rs(_, Stack0, Stack1),
	length_rs_1(N1, N, Stack1, Stack).


%.  length_rs_1(+N, +Stack0, -Stack)
%   make Stack a stack having N more elements than Stack0 (N >= 0).

length_rs_1(N, Stack0, Stack) :-
	(   N =:= 0 ->
	    Stack = Stack0
	;   M is N-1,
	    cons_rs(_, Stack0, Stack1),
	    length_rs_1(M, Stack1, Stack)
	).



%   top_rs(+Stack, ?Datum)
%   is true when Datum is the top element of Stack, which should be
%   instantiated.  DO NOT USE THIS TO MAKE A STACK!

top_rs(push_rs(_,Datum,_,_), Datum).



%   cons_rs(?Datum, +Rest, -Stack)
%   cons_rs(?Datum, -Rest, +Stack)
%   is the equivalent of [Datum|Rest] = Stack; it can be used to push
%   Datum onto Rest giving Stack or to (non-destructively) pop Datum
%   from Stack giving Rest.

cons_rs(Datum, Next, push_rs(Length,Datum,Next,Jump)) :-
	(   nonvar(Length) -> true	% already built
	;   nonvar(Next)   -> cons_rs_1(Next, Length, Jump, Next)
	;   abort			% instantiation fault
	).


cons_rs_1(empty_rs, 1, empty_rs, _).
cons_rs_1(push_rs(L,_,_,T), L1, Jump, S) :-
	L1 is L+1,
	length_and_jump(T, LenT, J, LenJ),
	(   L-LenT =:= LenT-LenJ -> Jump = J
	;			    Jump = S
	).


length_and_jump(empty_rs, 0, empty_rs, 0).
length_and_jump(push_rs(LenT,_,_,J), LenT, J, LenJ) :-
	length_rs_1(J, LenJ).



%   index_rs(+Index, +Stack, ?Datum)
%   is true when Datum is the Indexth element of Stack, where the first
%   element to be pushed on the stack is element 1 and the last is
%   element length_rs(Stack).

index_rs(N, RS, Datum) :-
	N >= 1,
	index_rs_1(N, RS, Datum).

index_rs_1(K, push_rs(L,D,N,J), Datum) :-
    (   L > K ->
	length_rs(J, X),
	(   X < K ->	index_rs_1(K, N, Datum)
	;		index_rs_1(K, J, Datum)
	)
    ;	L =:= K -> Datum = D
    ).



%   portray_rs(+Stack)
%   prints out a random-access stack in a readable form.

portray_rs(empty_rs) :-
	write('RanStk{}').
portray_rs(push_rs(_,D,N,_)) :-
	write('RanStk{'),
	print(D),
	portray_rs_1(N).

portray_rs_1(empty_rs) :-
	put("}").
portray_rs_1(push_rs(_,D,N,_)) :-
	put(","), print(D),
	portray_rs_1(N).


end_of_file.

%   Test code.

portray(X) :-
	portray_rs(X).

show_rs(empty_rs) :-
	write(empty), nl.
show_rs(push_rs(Length,Datum,Next,Jump)) :-
	length_rs(Next, N),
	length_rs(Jump, J),
	write((Length->Datum,N,J)), nl,
	show_rs(Next).

test :-
	empty_rs(RS0),
	push_rs(a1, RS0, RS1),
	push_rs(b2, RS1, RS2),
	push_rs(a3, RS2, RS3),
	push_rs(c4, RS3, RS4),
	push_rs(c5, RS4, RS5),
	push_rs(b6, RS5, RS6),
	push_rs(c7, RS6, RS7),
	show_rs(RS7),
	index_rs(1, RS7, X1),
	index_rs(2, RS7, X2),
	index_rs(3, RS7, X3),
	index_rs(4, RS7, X4),
	index_rs(5, RS7, X5),
	index_rs(6, RS7, X6),
	index_rs(7, RS7, X7),
	write([X1,X2,X3,X4,X5,X6,X7]), nl.

/*  In the timing test, list_to_rs takes about 7.8 times as long as
    list_to_list.
*/

list_to_rs(L, R) :-
	list_to_rs(L, empty_rs, R).

list_to_rs([], R, R).
list_to_rs([X|Xs], R0, R) :-
	cons_rs(X, R0, R1),
	list_to_rs(Xs, R1, R).

list_to_list(L, R) :-
	list_to_list(L, [], R).

list_to_list([], R, R).
list_to_list([X|Xs], R0, R) :-
	R1 = [X|R0],
	list_to_list(Xs, R1, R).

