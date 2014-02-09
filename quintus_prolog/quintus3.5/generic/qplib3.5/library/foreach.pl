%   Package: foreach
%   Author : Richard A. O'Keefe
%   Updated: 10 Apr 1989
%   Defines: A version of Peter Schachte's "foreach/2" control structure.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(foreach, [
	forall/2,
	foreach/2
   ]).
:- meta_predicate
	forall(0, 0),
	foreach(0, 0).
:- use_module(library(freevars), [
	free_variables/4
   ]),
   use_module(library(sofstk), [
	save_instances/3,
	conj_instances/2
   ]).

sccs_id('"@(#)89/04/10 foreach.pl	31.1"').



/*  forall(Generator, Goal)
    succeeds when Goal is provable for each true instance of Generator.
    Note that there is a sort of double negation going on in here (it
    is in effect a nested pair of failure-driven loops), so it will
    never bind any of the variables which occur in it.
*/
forall(Generator, Goal) :-
	call(( Generator, ( Goal -> fail ; true ) -> fail ; true )).


/*  foreach(Generator, Goal)
    
    for each proof of Generator in turn, we make a copy of Goal with
    the appropriate substitution, then we execute these copies in
    sequence.  For example, foreach(between(1,3,I), p(I)) is
    equivalent to p(1), p(2), p(3).

    Note that this is not the same as forall/2.  For example,
    forall(between(1,3,I), p(I)) is equivalent to
    \+ \+ p(1), \+ \+ p(2), \+ \+ p(3).

    The trick in foreach is to ensure that the variables of Goal which
    do not occur in Generator are restored properly.  (If there are no
    such variables, you might as well use forall/2.)

    Like forall/2, this predicate does a failure-driven loop over the
    Generator.  Unlike forall/2, the Goals are executed as an ordinary
    conjunction, and may succeed in more than one way.
*/
foreach(Generator, Goal) :-
	free_variables(Goal, Generator, [], FreeVariables),	
	save_instances(FreeVariables, Goal, Generator),
	conj_instances(FreeVariables, Conjunction),
	call(user:Conjunction).


