%   Package: random
%   Author : Richard A. O'Keefe
%   Updated: 04/20/99
%   Purpose: Provide a portable random number generator.

/*  This package uses algorithm AS 183 from the journal Applied Statistics
    as the basic random number generator.  random.c contains a "C"
    version of the code.  Lisp and Prolog versions exist too.  Exactly the
    same underlying sequence will be produced in all versions of Quintus
    Prolog; the actual results may not be identical because of differences
    in floating-point arithmetic.

    The operations are
	getrand(OldState)
	setrand(NewState)
	    -- allow saving and restoring the generator state
	maybe
	    -- succeed/fail with equal probability (variant of maybe/1)
	maybe(P) {Peter Schachte's brain-child}
	    -- succeed with probability P, fail with probability 1-P
	maybe(P, N)
	    -- succeed with probability P/N (variant of maybe/1)
	random(X)
	    -- bind X to a random float in [0.0,1.0)
	random(L, U, X)
	    -- bind X to a random element of [L,U)
	    -- if L, U are integers, X will be an integer.
	random_member(Elem, List)
	    -- unifies Elem with a random element of List.
	    -- Reports an error if List is not a proper list.
	random_perm2(A, B, X, Y)
	    -- does X=A,Y=B or X=B,Y=A with equal probability.
	    -- random_perm2 : perm2 :: random_permutation : permutation
	random_select(Elem, List, Rest)
	    -- is like select(Elem, List, Rest), but picks a random
	    -- element of the list.  You can use it to insert Elem in
	    -- a random place in Rest, yielding List, or to delete a
	    -- random Elem of List, yielding Rest.
	    -- Either List or Rest should be proper.
	    -- This used to be called rand_elem/3.
	random_subseq(List, Sbsq, Cmpl)
	    -- is like subseq(List, Sbsq, Cmpl), but picks a random
	    -- subsequence of List rather than enumerating all of them.
	    -- Either List, or both Sbsq and Cmpl, should be proper.
	random_permutation(L1, L2)
	    -- unify L2 with a random permutation of L1.
	    -- like permutation(L1, L2), either of the arguments may
	    -- be proper and the other will be solved for.
	    -- This used to be rand_perm/2.
*/

:- module(random, [
	getrand/1,			% save the state
	setrand/1,			% reset the state
	maybe/0,			% random success/failure
	maybe/1,			% random success/failure
	maybe/2,			% random success/failure
	random/1,			% uniform [0,1)
	random/3,			% uniform [L,U)
	random_graph/3,			% Prob x Size -> Graph
	random_numlist/4,		% Prob x Low x High -> Set
	random_member/2,		% Elem <- List
	random_select/3,		% Elem <- List -> Rest
	random_subseq/3,		% List -> Sbsq x Cmpl
	random_permutation/2,		% List -> Perm
	random_perm2/4			% Item x Item -> Item x Item
   ]).

:- mode
	setrand(+),
	maybe,
	maybe(+),
	maybe(+, +),
	random(?),
	random(+, -, -),
	random_member(?, +),
	    random_member(+, +, ?),
	    'proper length'(+, +, -),
	random_select(?, ?, ?),
	    random_select(+, +, ?, +),
	    'one longer'(?, ?, -),
	    'common length'(?, ?, +, -),
	random_subseq(?, ?, ?),
	random_permutation(?, ?),
	    random_permutation(+, +, -, +),
		random_partition(+, +, +, -, -),
	random_perm2(?, ?, ?, ?).

sccs_id('"@(#)99/04/20 random.pl	76.1"').


foreign_file(library(system(libpl)), [
    'QPRget',		% read random-state variables
    'QPRput',		% write random-state variables
    'QPRnxt',		% return the next random number
    'QPRmyb',		% return 0/1 for maybe/2
    'QPRbit'		% return 0/1 for maybe/0
]).
foreign('QPRget', 'QPRget'(-integer,-integer,-integer,-integer)).
foreign('QPRput', 'QPRput'(+integer,+integer,+integer,+integer,[-integer])).
foreign('QPRnxt', 'QPRnxt'([-double])).
foreign('QPRbit', 'QPRbit'([-integer])).
foreign('QPRmyb', 'QPRmyb'(+integer,+integer,[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).



%   getrand(?RandomState)
%   returns the random number generator's current state

getrand(random(X,Y,Z,B)) :-
	'QPRget'(X, Y, Z, B).


%   setrand(+RandomState)
%   sets the random number generator's state to RandomState.
%   If RandomState is not a valid random state, it reports
%   an error, and then fails.

setrand(random(X,Y,Z,B)) :-
	integer(X), integer(Y),
	integer(Z), integer(B),
	'QPRput'(X, Y, Z, B, 1),
	!.
setrand(RandomState) :-
	format(user_error, '~N! Bad random state: ~q~n! Goal: ~q~n',
	    [RandomState, setrand(RandomState)]),
	fail.


%   maybe
%   succeeds determinately with probability 1/2,
%   fails with probability 1/2.  We use a separate "random bit"
%   generator for this test to avoid doing much arithmetic.

maybe :-
	'QPRbit'(1).


%   maybe(+Probability)
%   succeeds determinately with probability Probability,
%   fails with probability 1-Probability.
%   Arguments =< 0 always fail, >= 1 always succeed.

maybe(P) :-
	random(X),
	X < P.


%   maybe(+P, +N)
%   succeeds determinately with probability P/N,
%   where 0 =< P =< N and P and N are integers.
%   If this condition is not met, it fails.
%   It is equivalent to random(0, N, X), X < P, but is somewhat faster.

maybe(P, N) :-
	'QPRmyb'(P, N, 1).

%   Sun-3/50, floating point in software:	0.83 -vs- 1.06 msec
%   Sun-3/160, floating point mc68881 chip:	0.21 -vs- 0.38 msec
%   These are the times for a single "maybe"    this -vs- random<P.



%   random(?Uniform)
%   unifies Uniform with a new random number in [0.0,1.0)

random(Uniform) :-
	'QPRnxt'(Uniform).



%   random(+L, +U, ?R)
%   unifies R with a random integer in [L,U)
%   when L and U are integers (note that U will NEVER be generated),
%   or to a random floating number in [L,U) otherwise.
%   If either L or U is not a number, it quietly fails.

random(L, U, R) :- integer(L), integer(U), !,
	'QPRnxt'(X),
	R is integer((U-L)*X) + L.
random(L, U, R) :- number(L), number(U), !,
	'QPRnxt'(X),
	R is (U-L)*X + L.



/*----------------------------------------------------------------------+
|		    Randomised list-processing				|
+----------------------------------------------------------------------*/


%   random_member(?Elem, +List)
%   unifies Elem with a random element of List, which must be proper.
%   Takes O(N) time (average and best case).

random_member(Elem, List) :-
	'proper length'(List, 0, N),
	!,
	random(0, N, I),
	random_member(I, List, Elem).
random_member(Elem, List) :-
	format(user_error,
	    '~N! Improper argument to ~q~n! Goal: ~q~n',
	    [random_member/2, random_member(Elem,List)]),
	fail.


%%  random_member/3 has the same arguments and meaning as nth0/3
%   in library(lists), but only works one way around.  (Not exported.)

random_member(0, [Elem|_], Elem) :- !.
random_member(N, [_|List], Elem) :-
	M is N-1,
	random_member(M, List, Elem).


%%  'proper length'(List, N0, N)
%   is true when List is a proper list and N-N0 is its length.

'proper length'(*,           _,  _) :- !, fail.
'proper length'([_,_,_,_|L], N0, N) :- !, N1 is N0+4, 'proper length'(L, N1, N).
'proper length'([_,_,_],     N0, N) :- !, N is N0+3.
'proper length'([_,_],       N0, N) :- !, N is N0+2.
'proper length'([_],         N0, N) :- !, N is N0+1.
'proper length'([],          N,  N).



%   random_select(?Elem, ?List, ?Rest)
%   unifies Elem with a random element of List and Rest with all the
%   other elements of List (in order).  Either List or Rest should
%   be proper, and List should/will have one more element than Rest.
%   Takes O(N) time (average and best case).

random_select(Elem, List, Rest) :-
	'one longer'(List, Rest, N),
	random(0, N, I),
	random_select(I, List, Elem, Rest).


%   random_select/4 has the same arguments and meaning as nth0/4
%   in library(lists), but only works one way around.  (Not exported.)

random_select(0, List, Elem, Rest) :- !,
	List = [Elem|Rest].
random_select(N, [Head|Tail], Elem, [Head|Rest]) :-
	M is N-1,
	random_select(M, Tail, Elem, Rest).


%  'one longer'(+List, +Rest, -N) is true when List and Rest are lists,
%   List has N elements, and Rest has N-1 elements.  It is assumed
%   that either List or Rest is proper.

'one longer'([_|List], Rest, N) :-
	'common length'(List, Rest, 1, N).


%   'common length'(L1, L2, N0, N) is true when L1 and L2 are
%   lists of the same length, and N-N0 is that common length.
%   same_length/3 in library(lists) was derived from this.

'common length'([], [], N, N).
'common length'([_|X], [_|Y], K, N) :-
	L is K+1,
	'common length'(X, Y, L, N).



%   random_subseq(+List, ?Sbsq, ?Cmpl)
%   unifies Sbsq with a random sub-sequence of List, and Cmpl with its
%   complement.  After this, subseq(List, Sbsq, Cmpl) will be true.
%   Each of the 2**length(List) solutions is equally likely.  Like its
%   name-sake subseq/3, if you supply Sbsq and Cmpl it will interleave
%   them to find List.  Takes O(N) time.  List should be proper.

random_subseq([], [], []).
random_subseq([Elem|List], Sbsq, Cmpl) :-
	'QPRbit'(B),
	(   B =:= 0 ->		% B = 0 with probability 1/2
	    Sbsq = [Elem|Sbs1],
	    random_subseq(List, Sbs1, Cmpl)
	;   			% B = 1 with probability 1/2
	    Cmpl = [Elem|Cmp1],
	    random_subseq(List, Sbsq, Cmp1)
	).



%   random_permutation(?List, ?Perm)
%   unifies Perm with a random permutation of List.  Either List or Perm
%   should be proper, and they should/will have the same length. Each of
%   the N! permutations is equally likely, where length(List, N).
%   The old rand_perm/2 predicate took O(N**2) time and only worked one
%   way around; this takes O(N.lgN) time and is bidirectional.

random_permutation(List, Perm) :-
	'common length'(List, Perm, 0, N),
	random_permutation(N, List, Ans, []),
	Perm = Ans.

random_permutation(0, _, X, X) :- !.
random_permutation(1, [X], [X|L], L) :- !.
random_permutation(2, [X,Y], [U,V|L], L) :- !,
	'QPRbit'(B),
	( B =:= 0 -> U = X, V = Y ; U = Y, V = X ).
random_permutation(N, List, Front, Back) :-
	Z is N>>1,
	A is N-Z,
	random_partition(List, A, N, Alist, Zlist),
	random_permutation(Z, Zlist, Middle, Back),
	random_permutation(A, Alist, Front, Middle).


random_partition(L, 0, _, [], L) :- !.
random_partition([], _, _, [], []).
random_partition([X|Xs], P0, N0, A0, B0) :-
	'QPRmyb'(P0, N0, D),
	P1 is P0-D,
	N1 is N0-1,
	(   D =:= 1 -> A0 = [X|A1], random_partition(Xs, P1, N1, A1, B0)
	;   D =:= 0 -> B0 = [X|B1], random_partition(Xs, P1, N1, A0, B1)
	).


%   random_perm2(A,B, X,Y)
%   unifies X,Y = A,B or X,Y = B,A, making the choice at random,
%   each choice being equally likely.  It is equivalent to
%   random_permutation([A,B], [X,Y]).

random_perm2(U, V, X, Y) :-
	'QPRbit'(B),
	( B =:= 0 -> X = U, Y = V ; X = V, Y = U  ).


%   random_numlist(+P, +L, +U, -List)
%   where P is a probability (0..1) and L=<U are integers
%   unifies List with a random subsequence of the integers L..U,
%   each integer being included with probability P.

random_numlist(P, L, U, List) :-
	float(P), P >= 0.0, P =< 1.0,
	integer(L), integer(U),
	!,
	random_numlist_1(L, U, P, List).
random_numlist(P, L, U, List) :-
	format(user_error,
	    '~N! Improper argument to ~q~n! Goal: ~q~n',
	    [random_numlist/4, random_numlist(P,L,U,List)]),
	fail.
  
random_numlist_1(L, U, P, List) :-
	(   L > U -> List = []
	;   M is L+1,
	    random(X),
	    (   X > P -> random_numlist_1(M, U, P, List)
	    ;   List = [L|Rest],  random_numlist_1(M, U, P, Rest)
	    )
	).

%   random_graph(+P, +N, -Graph)
%   where P is a probability and N is the number of nodes,
%   unifies Graph with a random subgraph of {1..N}x{1..N},
%   each arc being included with probability P.
%   S-representation (see library(graphs)) is used.

random_graph(P, N, Graph) :-
	float(P), P >= 0.0, P =< 1.0,
	integer(N), N >= 0,
	!,
	random_graph_1(0, N, P, Graph).
random_graph(P, N, Graph) :-
	format(user_error,
	    '~N! Improper argument to ~q~n! Goal: ~q~n',
	    [random_graph/3, random_graph(P,N,Graph)]),
	fail.

random_graph_1(N, N, _, Graph) :- !, Graph = [].
random_graph_1(I, N, P, [J-List|Graph]) :-
	J is I+1,
	random_numlist_1(1, N, P, List),
	random_graph_1(J, N, P, Graph).

