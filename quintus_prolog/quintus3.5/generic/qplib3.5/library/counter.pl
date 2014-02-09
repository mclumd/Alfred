%   Package: counter
%   Author : Richard A. O'Keefe
%   Updated: 24 Dec 1989
%   Defines: Bounded backtrackable counters.

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(counter, [
	make_counter/2,			% Integer -> Counter
	counter_bound/2,		% Counter -> Integer
	counter_value/2,		% Counter -> Integer
	decrement_counter/1,		% Counter ->
	decrement_counter/2,		% Counter -> Integer
	is_counter/1,			% Counter ->
	portray_counter/1		% Counter ->
   ]).

sccs_id('"@(#)89/12/24 counter.pl	1.1"').


/*  In order to implement a form of constraint processing, I want a
    kind of counter object which can be initialised to a value N, which
    will disappear when the creation is backtracked over, which can be
    decremented provided it is non-zero, where the decrementing is
    undone by backtracking, but without leaving extra choice-points
    behind, and which is reasonably compact.

    The chosen method is a hack.  The maximum value of N is already
    bounded by the maximum arity of a term, so I create a term with N
    arguments, all variables.  The current value of the counter is the
    number of variables remaining, which is also the index of the
    highest variable argument.

    To decrement a counter, we locate the highest variable and bind it.
    The picture I used to develop last_var/4 was this
	      0        N		initial values
	-------+ -------+ -------
	    var| unknown| nonvar	known status of arguments
	-------+ -------+ -------
	      A        Z		working values of loop parameters

    Initially, last_var doesn't know the status of any of the arguments.
    loop_var(Counter, A, Z, I) means
	0 <= A < I <= Z <= arity(Counter) and
	for all 1 <= K <= A, the Kth argument of Counter is a variable and
	for all Z < K <= N,  the Kth argument of Counter is not a variable.
    The loop terminates when the unknown region is empty.

    Unifying two counters will fail unless they have the same upper bound;
    the effect when they do have the same upper bound is to set the value
    of both to the MINIMUM of their former values, and to tie the two
    together so that decrementing one will decrement both.

    By duality, if you want bounded counters which start at 0 and increment
    to N, use
	make_counter(N, Counter)		to make & initialise one
	counter_value(Counter, X), I is N-X	to get the current value
	decrement_counter(Counter)		to *increment* one
	X = Y					to set X=Y=*max*(X,Y)
*/

%   make_counter(+N, -Counter)
%   Unify Counter with a new bounded counter which can take values in
%   the range [0..N], initialised to N.

make_counter(N, Counter) :-
    (	integer(N), N >= 0, N =< 255 ->
	functor(Counter, counter, N)
    ;	format(user_error, '~N! ~w expected but ~w found.~n! Goal: ~q~n',
	    [0-255,N,make_counter(N,Counter)]),
	fail
    ).


%   counter_bound(+Counter, ?N)
%   Unify N with the upper bound of the Counter.

counter_bound(Counter, N) :-
	functor(Counter, F, N),		% force error if var(Counter)
	F = counter.			% fail quietly if not a counter.


%   counter_value(+Counter, ?I)
%   Unify I with the current value of the Counter; 0 =< I =< N.

counter_value(Counter, I) :-
	functor(Counter, counter, N),
	last_var(Counter, 0, N, I).


%   decrement_counter(+Counter)
%   decrement the bounded Counter; fail if its value is already 0.
%   This is undone by backtracking.

decrement_counter(Counter) :-
	functor(Counter, counter, N),
	last_var(Counter, 0, N, I),
	arg(I, Counter, I).


%   decrement_counter(+Counter, ?I)
%   decrement the bounded Counter and unify I with its *former* value.
%   This fails if the value is already 0, and is undone by backtracking.

decrement_counter(Counter, I) :-
	functor(Counter, counter, N),
	last_var(Counter, 0, N, I),
	arg(I, Counter, I).


%   is_counter(?Counter)
%   is true when Counter is a bounded counter.

is_counter(Counter) :-
	nonvar(Counter),
	functor(Counter, counter, N),
	is_counter(N, Counter, 0).

is_counter(N, Counter, Flag) :-
	(   N =:= 0 -> true
	;   arg(N, Counter, Arg),
	    M is N-1,
	    (   var(Arg) ->
		is_counter(M, Counter, 1)
	    ;	Flag =:= 0,
		is_counter(M, Counter, Flag)
	    )
	).


%   portray_counter(+Counter)
%   write a bounded Counter whose value is I as Counter{I}.

portray_counter(Counter) :-
	counter_value(Counter, I),
	write('Counter'), write({I}).


last_var(Counter, A, Z, I) :-
	(   A < Z ->
	    M is (A+Z+1) >> 1,
	    arg(M, Counter, Arg),
	    (   var(Arg) ->
		last_var(Counter, M, Z, I)
	    ;	L is M-1,
		last_var(Counter, A, L, I)
	    )
	;   A =:= Z ->
	    I is A
	).

end_of_file.

/* TESTING CODE */

test(N) :-
	make_counter(N, Counter),
	portray_counter(Counter), nl,
	test(N, Counter).

test(N, Counter) :-
	(   N =:= 0 -> true
	;   decrement_counter(Counter, I),
	    (   I =:= N -> write(I=:=N)
	    ;              write(I=\=N)
	    ),
	    put(32),
	    portray_counter(Counter), nl,
	    M is N-1,
	    test(M, Counter)
	).

ceil_log_2(N, L) :-
	N > 0,
	ceil_log_2(N, 0, L).

ceil_log_2(N0, L0, L) :-
    (	N0 =< 1 -> L = L0
    ;	N1 is (N0+1) >> 1,
	L1 is L0+1,
	ceil_log_2(N1, L1, L)
    ).

time(N) :-
	make_counter(N, Counter),
	statistics(runtime, _),
	time(N, Counter),
	statistics(runtime, [_,T]),
	ceil_log_2(N, L),
	R is T/(N*L),
	format('N = ~d, |~~lgN~~| = ~d, T = ~d, T/N|~~lgN~~| = ~w~n',
		[N,L,T,R]).

time(N, Counter) :-
	(   N =:= 0 -> true
	;   decrement_counter(Counter),
	    M is N-1,
	    time(M, Counter)
	).

