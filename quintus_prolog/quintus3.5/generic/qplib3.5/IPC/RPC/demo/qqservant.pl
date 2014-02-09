%   SCCS   : @(#)qqservant.pl	24.3 4/14/88
%   Author : David S. Warren
%   Purpose: demonstrate Prolog being called by Prolog through IPC.

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.


/*  This file contains Prolog code to demo the Prolog IPC facilities.
    Be sure the IPC remote Prolog routines are loaded into your
    runtime environment (ensure_loaded(library(qpcallqp))).  Make a
    Prolog saved state containing the server code.  See qqservant.sh
    for details.

    To run it REMOTELY,
	create_servant(TheRemoteMachine, TheSavedState, TheOutputFile).
    To run it LOCALLY,
	create_servant('', TheSavedState, TheOutputFile).

    You could create a generic Prolog server just containing
    library(qpcallqp).  You would then have to call (in the master)
	call_servant(compile(TheFilesToBeLoaded))
    which tells the servant what files to load.  But it is more common
    to create a saved state containing everything you need and start
    that up.

    Then the goal :-queens(4,A) will generate answers to how to set up 4
    queens on a 4x4 chess board so that no two are in opposition.  An
    answer is represented as a list of Row-Col positions for the queens.
    There are two answers to the 4 queens problem.

    You may provide any number to determine the size of the chess board.
    (The 8-queens problem has 92-some solutions, and may take a while!)

    The way that the work is divided up between the two processes means
    that N must be even: N=4 and N=8 are ok, but N=5 will produce some
    meaningless answers.

    To see what is being sent to the remote machine, you can turn
    message tracing on in the master with
	msg_trace(_, on)
    and also in the servant with
	call_server(msg_trace(_, on)).
    This will show what is being sent to the servant process
    and what is coming back from it.
*/

:- ensure_loaded(library(qpcallqp)).
:- ensure_loaded(library(basics)).


%   queens(+N, ?Sol)
%   is true when Sol is a solution to the N-queens problem.
%   Sol is represented as a list of Row-Column pairs.

queens(N, Solution) :-
	numlist(1, N, Rows),
        pairlist(Rows, Cols, Solution),
	/* unwind one level to parallelize */
        /* permute(Cols, Rows), */
	Cols = [H|T],
	select(H1, Rows, Rest1),
%	select2(H1, H2, Rows, Rest1, Rest2),
	bag_of_all_servant(p(H,Solution),
		( H1 = H, permute(T, Rest1), safe(Solution)
%		; H2 = H, permute(T, Rest2), safe(Solution)
		), ANS),
	member(p(H,Solution), ANS).
	/* permute(T,Rest),   safe(Solution). */


%   select2(?E1, ?E2, +List, ?Rlist1, ?Rlist2)
%   is true when E1 and E2 are consecutive elements of List (E1 in an
%   odd position), Rlist1 is the result of deleting E1 from List and E2
%   is the result of deleting E2 from List.
%   This is used nondeterministically.

select2(H1, 0, [H1], [], []).
select2(H1, H2, [H1,H2|Rest], [H2|Rest], [H1|Rest]).
select2(H1, H2, [X,Y|Rest], [X,Y|Rest1], [X,Y|Rest2]) :-
	select2(H1, H2, Rest, Rest1, Rest2).


%   numlist(+Low, +High, ?List)
%   is true when List is the list of integers from Low to High

numlist(Lower, Upper, [Lower|NumList]) :-
	Lower =< Upper,
	!,
	Next is Lower+1,
	numlist(Next, Upper, NumList).
numlist(Lower, Upper, []) :-
	Lower > Upper.


%   pairlist(+List1, +List2, ?Pairs)
%   is true when Pairs is the list whose ith element is the
%   pair of the ith elements of List1 and List2.

pairlist([], [], []).
pairlist([R|Rs], [C|Cs], [R-C|RCs]) :-
	pairlist(Rs, Cs, RCs).


%   permute(?L1, +L2)
%   is true when L2 is a permutation of L1.

permute([], []).
permute([H|T], Perm) :-
	select(H, Perm, Rest),
	permute(T, Rest).


%   select(?X, +L, -R)
%   is true when X is an element of L and R is the result of
%   extracting X from L.

select(X, [X|R], R).
select(X, [H|T], [H|R]) :-
	select(X, T, R).


%   safe(+PairList)
%   is true when PairList is a list of Row-Column pairs and no two
%   queens on these squares are in opposition.

safe([]).
safe([R-C|Qs]) :-
	S is R+C,
	D is R-C,
	safe(Qs, S, D),
	safe(Qs).


%   safe(+PairList, +Sum, +Dif)
%   PairList is a list of Row-Column pairs.
%   Let R-C be another board position.
%   Then Sum is R+C and Dif is R-C.
%   safe/3 is true if placing a queen on R-C does not oppose
%   any queen on any square in PairList.

safe([], _, _).
safe([R-C|Qs], S, D) :-
	S =\= R+C,
	D =\= R-C,
	safe(Qs, S, D).

