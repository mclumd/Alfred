%   Package: ctr
%   Author : Richard A. O'Keefe
%   Updated: 30 Sep 1992
%   Purpose: "counter" operations.

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(ctr, [
	ctr_set/2,	% ctr_set(Ctr, N) <=> ctr[Ctr] := N
	ctr_set/3,	% ctr_set(Ctr, N, Old); Old is old value
	ctr_inc/1,	% ctr_inc(Ctr)    <=> ctr[Ctr] += 1
	ctr_inc/2,	% ctr_inc(Ctr, N) <=> ctr[Ctr] += N
	ctr_inc/3,	% ctr_inc(Ctr, N, Old); Old is old value
	ctr_dec/1,	% ctr_dec(Ctr)    <=> ctr[Ctr] -= 1
	ctr_dec/2,	% ctr_dec(Ctr, N) <=> ctr[Ctr] -= N
	ctr_dec/3,	% ctr_dec(Ctr, N, Old); Old is old value
	ctr_is/2	% ctr_is( Ctr, N) <=> N is ctr[Ctr]
   ]).

sccs_id('"@(#)92/09/30 ctr.pl	66.1"').

/*  The Arity/Prolog manual does not state what the effect of
    the ctr_xxx predicates is when the Ctr argument is not in
    the range 0..31.  For my convenience, I have ruled that the
    argument is always taken modulo 32, so that any pair of
    integers will always be acceptable as arguments, and have
    left it to the foreign function interface to reject non-
    integral arguments.

    The predicates ctr_{set,inc,dec}/3 do not exist in Arity Prolog,
    but they are quite useful.  After performing their side effect,
    they unify their third argument with the OLD value of the counter.
*/

%   ctr_is(+Counter:0..31, ?OldValue)
%   is true when OldValue is the current value of count[Counter]

ctr_is(Counter, OldValue) :-
	ctr_val(Counter, OldValue).



%   ctr_set(+Counter:0..31, +NewValue:integer)
%   does count[Counter] := NewValue.

ctr_set(Counter, NewValue) :-
	ctr_op2(Counter, NewValue, 2).


%   ctr_set(+Counter:0..31, +NewValue:integer, ?OldValue:integer)
%   does OldValue is count[Counter], count[Counter] := NewValue

ctr_set(Counter, NewValue, OldValue) :-
	ctr_op3(Counter, NewValue, OldValue, 2).



%   ctr_inc(+Counter:0..31)
%   does count[Counter] +:= 1

ctr_inc(Counter) :-
	ctr_op2(Counter, 1, 0).


%   ctr_inc(+Counter:0..31, +Increment:integer)
%   does count[Counter] +:= Increment

ctr_inc(Counter, Increment) :-
	ctr_op2(Counter, Increment, 0).


%   ctr_inc(+Counter:0..31, +Increment:integer, ?OldValue:integer)
%   does OldValue is count[Counter], count[Counter] +:= Increment

ctr_inc(Counter, Increment, OldValue) :-
	ctr_op3(Counter, Increment, OldValue, 0).



%   ctr_dec(+Counter:0..31)
%   does count[Counter] +:= 1

ctr_dec(Counter) :-
	ctr_op2(Counter, 1, 1).


%   ctr_dec(+Counter:0..31, +Decrement:integer)
%   does count[Counter] +:= Decrement

ctr_dec(Counter, Decrement) :-
	ctr_op2(Counter, Decrement, 1).


%   ctr_dec(+Counter:0..31, +Decrement:integer, ?OldValue:integer)
%   does OldValue is count[Counter], count[Counter] +:= Decrement

ctr_dec(Counter, Decrement, OldValue) :-
	ctr_op3(Counter, Decrement, OldValue, 1).



foreign_file(library(system(libpl)), [ctr_op2,ctr_op3,ctr_val]).

foreign(ctr_op2, ctr_op2(+integer,+integer,+integer)).
foreign(ctr_op3, ctr_op3(+integer,+integer,[-integer],+integer)).
foreign(ctr_val, ctr_val(+integer,[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

