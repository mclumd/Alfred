
/* @(#)knight.pl	28.1 02/11/91 */

/* ----------------------------------------------------------------------
   knight.pl			David Bowen, Quintus Computer Systems, Inc.

   The travelling knight puzzle: to find all paths of knight-moves on a
   chessboard of size N, starting at (1,1) and finishing at (1,N), and
   visiting each square on the board no more than once.
   
   Invoke the program by

    ?- tour(N).		% for an arbitrary NxN board, or

    ?- tour.		% in the case where N=5 (73,946 solutions) 

    ?- tour_slowly.	% is like tour/0 except that it uses a list to
			% represent the path of squares visited so far.

    Timings for tour/0:

	QP 1.6 on a Sun 3/160			22 min 34 sec
	QP 2.0 on a Sun 3/160			20 min 40 sec
	QP 3.1 on a Sun Sparcstation 1		 6 min 15 sec

    Timing for tour_slowly/0:

	QP 2.0 on a Sun 3/160			62 min 44 sec


    NOTE: If you are comparing Quintus Prolog with a LISP system you should
    consider space requirements as well as raw speed.  These programs run
    comfortably in 1 Meg of data space under Quintus Prolog (I did

	limit datasize 1M

    before starting up Prolog).
   ---------------------------------------------------------------------- */


tour(N) :-
	init_count,
	statistics(runtime,_),
	(   start(N),
	    incr_count,
	    fail
	|   true
	),
	statistics(runtime,[_,T]), Time is T//1000,
	Minutes is Time//60, Remainder is T - Minutes*60000,
	count(Count),
	format('~N[~D solutions in ~d minutes and ~3d seconds]~n', 
		[Count, Minutes, Remainder]).


/* ----------------------------------------------------------------------
   I have to admit that Prolog is not good when what you really want is
   a global variable.  Using assert/retract is clumsy and inefficient, so
   I have commented out the following and am using instead the library 
   package, ctr, which maintains global variables in C for use as counters.
   This may be regarded as "cheating" in a benchmark, but I would argue that
   the benchmark is the solving of the problem, not the counting of the
   solutions.  In any case, library(ctr) is part of the standard Quintus 
   Prolog distribution.

   :- dynamic count/1.
   init_count :- abolish(count,1), assert(count(0)).
   incr_count :- retract(count(M)), !, N is M+1, assert(count(N)).
   ---------------------------------------------------------------------- */

:- ensure_loaded(library(ctr)). 
init_count :- ctr_set(1,0).	% set counter number 1 to zero
incr_count :- ctr_inc(1,1).	% increment counter number 1 by 1
count(N) :- ctr_is(1,N).	% unify N with current value of counter 1



% The knights journey is represented by an array called 'visited' with N^2
% elements corresponding to the N^2 squares on the board.  These elements
% are initially unbound variables; each element gets bound to a value K when
% it is visited on the Kth step of the knight's tour.

start(N) :-
	Nsq is N*N,
	functor(Visited,visited,Nsq),
	go(1, 1, N, 1, Visited).


% go(A,B, N, K, Visited) is called when attempting to visit (A,B) as
% the Kth step in the knight's journey.  If this square has already been 
% visited, the Ith element of Visited will already be bound to some value
% less than K, so the call to arg fails.  If it is possible to visit this
% square, the knight's journey is over if A =:= 1 and B =:= N, that is, if
% I =:= N.  Otherwise, a move is non-deterministically generated and the 
% knight moves on.

go(A,B, N, K, Visited) :-
	I is (A-1)*N+B,
	arg(I, Visited, K),
	( I =:= N ->
	    % output(0, N, Visited),
	    true
	| otherwise ->
	    NewK is K + 1,
	    knight_move(Dx,Dy),
	    C is A + Dx,
	    1 =< C, C =< N,
	    D is B + Dy,
	    1 =< D, D =< N,
	    go(C,D, N, NewK, Visited)
	).


knight_move( 2, 1).
knight_move( 2,-1).
knight_move(-2, 1).
knight_move(-2,-1).
knight_move( 1, 2).
knight_move(-1, 2).
knight_move( 1,-2).
knight_move(-1,-2).


output(I, N, Visited) :-
	( I mod N =:= 0 -> 
	    nl,
	    I < N*N
	| true 
	),
	!,
	J is I+1,
	arg(J, Visited, Next),
	( var(Next) -> 
	    Next = '_' 
	| true 
	),
	format('~|~t~w~3+', [Next]),
	output(J, N, Visited).
output(_, _, _).



/* ----------------------------------------------------------------------
   These are special cases of the above routines for the case where N=5.
   This goes a little bit faster than tour(5) because one less argument
   is passed around.
   ---------------------------------------------------------------------- */

tour :-
	init_count,
	statistics(runtime,_),
	(   start,
	    incr_count,
	    fail
	|   true
	),
	statistics(runtime,[_,T]), Time is T//1000,
	Minutes is Time//60, Remainder is T - Minutes*60000,
	count(Count),
	format('~N[~D solutions in ~d minutes and ~3d seconds]~n', 
		[Count, Minutes, Remainder]).


start :-
	functor(Visited,visited,25),
	go(1, 1, 1, Visited).


go(A,B, K, Visited) :-
	I is (A-1)*5+B,
	arg(I, Visited, K),
	( I =:= 5 ->
	    % output(0, 5, Visited),
	    true
	| otherwise ->
	    NewK is K + 1,
	    knight_move(Dx,Dy),
	    C is A + Dx,
	    1 =< C, C =< 5,
	    D is B + Dy,
	    1 =< D, D =< 5,
	    go(C,D, NewK, Visited)
	).


/* ----------------------------------------------------------------------
   This is a version of tour using a list to remember the squares which 
   have been visited.  I think that the previous version is more "natural"
   for Prolog at least, and more efficient in any language.  Prolog
   probably compares badly with LISP in this version of the program because
   Prolog implementations do not generally provide much special low-level
   support for operations on lists.
   ---------------------------------------------------------------------- */

tour_slowly :-
	init_count,
	statistics(runtime,_),
	(   start_slowly,
	    incr_count,
	    fail
	|   true
	),
	statistics(runtime,[_,T]), Time is T//1000,
	Minutes is Time//60, Remainder is T - Minutes*60000,
	count(Count),
	format('~N[~D solutions in ~d minutes and ~3d seconds]~n', 
		[Count, Minutes, Remainder]).


start_slowly :-
	go_slowly(1, 1, []).


:- ensure_loaded(library(basics)).	% for nonmember/1

go_slowly(A,B, Visited) :-
	I is (A-1)*5+B,
	nonmember(I, Visited),
	( I =:= 5 ->
	    true
	| otherwise ->
	    knight_move(Dx,Dy),
	    C is A + Dx,
	    1 =< C, C =< 5,
	    D is B + Dy,
	    1 =< D, D =< 5,
	    go_slowly(C,D, [I|Visited])
	).


