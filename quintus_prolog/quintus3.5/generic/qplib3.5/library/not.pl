%   Module : negation
%   Author : Richard A. O'Keefe
%   Updated: 31 Jan 1994
%   Purpose: "suspicious" negation, and inequality.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This file defines a version of 'not' which checks that there are
    no free variables in the goal it is given to "disprove".  Bound
    variables introduced by the existential quantifier ^ or set/bag
    dummy variables are accepted.  If any free variables are found, 
    a message is printed on the terminal and a break level entered.

    not/1 is intended purely as a debugging aid, and is substantially
    slower than using \+ /1.

    Two versions of inequality are defined here.

	X \= Y		is identical in effect to \+(X=Y)
	X ~= Y		is "suspicious"

    If you care about your programs bearing some relation to logic,
    you would be better to use ~=, which succeeds if the two terms can
    never become equal, fails if they can never become unequal, and in
    case of doubt *warns* you.  The name of this predicate is copied
    from MU Prolog, in which it will delay if it can neither succeed
    nor fail just yet.  Since Dec-10, C, and Quintus Prolog do not
    have the ability to delay, they produce a warning message.
*/

:- module(negation, [
	(\=)/2,			%   unsound inequality
	(~=)/2,
	(once)/1,
	(not)/1			%   new checking denial
   ]).
:- meta_predicate
	once(0),
	not(0).
:- use_module(library(freevars), [
	free_variables/4
   ]).

sccs_id('"@(#)94/01/31 not.pl    71.1"').

:- op(900,  fy, [not,once]).	%  same priority and type as \+
:- op(700, xfx, [\=,~=]).	%  same priority and type as = or ==


/*  Note that X \= Y is not quite the same as true inequality:  if X\=Y
    succeeds, then some difference was found, so X and Y are genuinely
    different, but if X\=Y fails that only means they can be unified
    NOW, it doesn't mean that a further instantiation can't make them
    different.  For example, if X and Y are new variables, the query
	\+(X \= Y), X = a, Y = b
    will succeed!  MU Prolog has a sound version of this called ~=; the
    idea is that if X and Y can be unified but that instantiates some
    variables, X ~= Y will be delayed until some more variables are
    bound.  X ~= Y will only fail when X and Y are identical (and in
    that it is like \==). Unfortunately, this is not MU Prolog, so you
    have to put up with \='s little quirks.

    X ~= Y is as close to MU Prolog's predicate as you can get without
    coroutining; if there isn't enough information to tell yet whether
    X = Y or not, you get an instantiation error.  This is more powerful 
    than not(X = Y).  Consider
	X = f(a,_,1), Y = f(a,_,2)
    Then X ~= Y will succeed, but not(X = Y) would report an error.
*/

%   X \= Y (X does not unify with Y)
%   is true when no substitution can be found to make X and Y the same.

X \= X :- !,			%   This clause might be too eager,
	fail.			%   a later binding might have changed things.
_ \= _.



%   X ~= Y (X is definitely not equal to Y)
%   is true when X is not identical to Y now and never will be.

X ~= Y :-
	(   X == Y -> fail	%   identical, can't ever be different
	;   X \= Y -> true	%   can't be made the same
	;   otherwise ->
	        raise_exception(instantiation_error(X~=Y,0))
	).



%   not(Goal)
%   is a sound version of negation as failure; if there are free variables
%   in Goal it reports an error.  You may have existential variables.

not(Goal) :-
	free_variables(Goal, [], [], Vars),
	Vars = [_|_],
	!,
	raise_exception(instantiation_error(not(Goal),1)).
not(Goal) :-
	\+ call(Goal).



%   once(Goal)
%   makes Goal determinate.  You can obtain the same effect as this
%   directly by writing (Goal->true;fail), which can be abbreviated
%   to (Goal->true).

once(Goal) :-
	call(Goal),
	!.

