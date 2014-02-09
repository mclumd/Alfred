%   Package: cassert
%   Author : Richard A. O'Keefe
%   Updated: 16 Dec 1987
%   Purpose: Add a ground unit clause to the data base if not already there.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(cassert, [
	cassert/1,
	casserta/1,
	cassertz/1
   ]).

:- meta_predicate
	cassert(0),
	casserta(0),
	cassertz(0).

sccs_id('"@(#)87/12/16 cassert.pl	21.1"').



%   cassert(+Fact)
%   adds Fact somewhere in its predicate unlesss it is already known.
%   Fact must be a ground unit clause.
%   The clause order is NOT defined and may change.

cassert(Fact) :-
	unpack(Fact, user, Head, Module),
	!,
	do_cassert(a, Module, Head).
cassert(Fact) :-
	format(user_error,
	    '~N! Argument is not a ground unit clause.~n! Goal: ~q~n',
	    [cassert(Fact)]),
	fail.


%   casserta(+Fact)
%   adds Fact at the front of its predicate unless it is already known.
%   Fact must be a ground unit clause.

casserta(Fact) :-
	unpack(Fact, user, Head, Module),
	!,
	do_cassert(a, Module, Head).
casserta(Fact) :-
	format(user_error,
	    '~N! Argument is not a ground unit clause.~n! Goal: ~q~n',
	    [casserta(Fact)]),
	fail.


%   cassertz(+Fact)
%   adds Fact at the end of its predicate unless it is alreayd known.
%   Fact must be a ground unit clause.

cassertz(Fact) :-
	unpack(Fact, user, Head, Module),
	!,
	do_cassert(z, Module, Head).
cassertz(Fact) :-
	format(user_error,
	    '~N! Argument is not a ground unit clause.~n! Goal: ~q~n',
	    [cassertz(Fact)]),
	fail.



%%  unpack(+Fact0, +Module0, -Fact, -Module)
%   unpacks a Module0:Fact0 form into separate Fact and Module,
%   and checks that Fact is a ground unit clause.

unpack(M:F, _, Fact, Module) :- !,
	atom(M),
	nonvar(F),
	unpack(F, M, Fact, Module).
unpack((_ :- _), _, _, _) :- !, fail.
unpack(Head, Module, Head, Module) :-
	functor(Head, F, _),
	atom(F),
	numbervars(Head, 0, 0).


%%  do_cassert(+End, +Module, +Fact)
%   does nothing if Module:Fact is already provable, otherwise adds
%   it at the given End of its predicate.

do_cassert(_, Module, Fact) :-
	Module:Fact,
	!.
do_cassert(a, Module, Fact) :-
	asserta(Module:Fact).
do_cassert(z, Module, Fact) :-
	assertz(Module:Fact).


