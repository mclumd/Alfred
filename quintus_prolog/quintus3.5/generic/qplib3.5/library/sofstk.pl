%   Package: sofstk
%   Author : Richard A. O'Keefe
%   Updated: 01 Jun 1989
%   Purpose: Support code for library(findall), library(setof) &c.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This module manages the set-of-stack for the benefit of
	library(findall),
	library(foreach),
	library(setof),
    and perhaps other future packages.  Those packages do not
    re-export the operations of this package, which is not meant
    for general use.
*/
:- module(sofstk, [
	save_instances/2,	% Template x Generator ->
	save_instances/3,	% Key x Template x Generator ->
	list_instances/1,	% -> List
	list_instances/2,	% Accumulator -> List
	list_instances/3,	% Key x Length -> List
	conj_instances/2,	% Key -> Goal
	make_key/3		% Vars -> Length x Key
   ]).
:- meta_predicate
	save_instances(+, 0),
	save_instances(+, +, 0).

:- mode
	list_instances(+, -),
	list_instances(+, +, -).

:- dynamic
	setof_stack/2.

sccs_id('"@(#)89/06/01 sofstk.pl	32.1"').


/*  In the first draft of this file, the intention was to use
	setof_stack(Term)
    where Term is [] or found(Instance) or Key-Instance.
    However, this involves indexing on the functor, which is rather
    pointless here.  So the current version uses
	setof_stack(_, Term)
    to avoid indexing.  The low-level operation which supports the
    built-in operations setof/3 and bagof/3 is more than 3 times
    faster than the version of findall/3 in this library.
*/

%   save_instances(+Template, +Generator)
%   enumerates all provable instances of the Generator and stores the
%   associated Template instances.  Neither argument ends up changed.

save_instances(Template, Generator) :-
	asserta(setof_stack(_, [])),
	call(Generator),
	asserta(setof_stack(_, found(Template))),
	fail.
save_instances(_, _).



%   list_instances(?List)
%   pulls all the Template instances out of the data base until it
%   hits the marker, and unifies List with the result.

list_instances(List) :-
	list_instances([], List).


%   list_instances(+SoFar, ?Total)
%   pulls all the Template instances out of the data base until it
%   hits the marker, and puts them on the front of the accumulator
%   SoFar.  This routine is used by findall/3-4 and by bag_of when
%   the Generator has no free variables.

list_instances(SoFar, Total) :-
	retract(setof_stack(_, Term)),
	!,				%   must not backtrack
	'list instances'(Term, SoFar, Total).


'list instances'([], Total, Total).
'list instances'(found(Template), SoFar, Total) :-
	list_instances([Template|SoFar], Total).



/*  save_instances/3 and list_instances/3 are used by bag_of/3 and
    set_of/3 when there are free variables (which are collected as
    the Key).  They are not used by either version of findall.
    They are in this module so that they can see the setof_stack/1
    predicate.  Using such a predicate was a new feature in the
    2.3 release, which has the effect that the 'recorded' data base
    is now entirely free to customers.
*/

%   save_instances(+Key, +Template, +Generator)
%   enumerates all provable instances of the Generator and stores
%   the associated Key-Template instances.  None of the arguments
%   ends up changed.

save_instances(Key, Template, Generator) :-
	asserta(setof_stack(_, [])),
	call(Generator),
	asserta(setof_stack(_, -(Key,Template))),
	fail.
save_instances(_, _, _).



%   make_key(+Vars, -Length, -Key)
%   is given a list of variables Vars, and constructs a term which
%   holds all those variables.  If there are up to 250 variables,
%   the result is a one-level term.  If there are between 250 and
%   250*250=62500 variables, the result is a two-level term.  The
%   outer functor, if any, is * /N, and the inner functor is . /M.
%   If there are more than 250*250 variables, this predicate fails.
%   It is up to the caller to report the error.

make_key(Vars, Length, Key) :-
	length(Vars, Length),
	(   Length =<     3 -> make_key_1(Length, Vars, Key)
	;   Length =<   250 -> make_one_level_key(Length, Vars, Key, [])
	;   Length =< 62500 -> make_two_level_key(Length, Vars, Key)
	).

make_key_1(1, [X1],	.(X1)).
make_key_1(2, [X1,X2],	.(X1,X2)).
make_key_1(3, [X1,X2,X3],	.(X1,X2,X3)).

make_one_level_key(Length, Vars, Key, Vars1) :-
	functor(Key, ., Length),
	make_one_level_key(Length, Vars, 1, Key, Vars1).

make_one_level_key(Length, [Var|Vars], N, Key, Vars1) :-
	(   Length > 1 ->
	    arg(N, Key, Var),
	    Length1 is Length-1,
	    N1 is N+1,
	    make_one_level_key(Length1, Vars, N1, Key, Vars1)
	;   arg(N, Key, Var),
	    Vars1 = Vars
	).

make_two_level_key(Length, Vars, Key) :-
	Arity is (Length+249) // 250,
	functor(Key, *, Arity),
	make_two_level_key(Length, Vars, 1, Key).

make_two_level_key(Length, Vars, N, Key) :-
	(   Length > 250 ->
	    make_one_level_key(250, Vars, Arg, Vars1),
	    arg(N, Key, Arg),
	    Length1 is Length-250,
	    N1 is N+1,
	    make_two_level_key(Length1, Vars1, N1, Key)
	;   make_one_level_key(Length, Vars, Arg, []),
	    arg(N, Key, Arg)
	).



%   list_instances(+Key, +Length, -List)
%   pulls all the Key-Template instances out of the data base until
%   it hits the marker, and unifies the result with List.
%   Note that asserting something into the data base and pulling it out
%   again renames all the variables; to counteract this we use replace_
%   key_variables to put the old variables back.  Fortunately if we
%   bind X=Y, the newer variable will be bound to the older, and the
%   original key variables are guaranteed to be older than the new ones.
%   This replacement must be done @i<before> the keysort.

%   The make_variable_global({List}) hack gives us a way to tell
%   whether a variable in a Key-Template instance is new or has
%   already been bound to one of the variables in the original
%   Key.  (This fixes a bug where binding two variables in an
%   instance could force them to be bound in all instances!)  The
%   Length is passed in so that we know whether we have a one-level
%   or a two-level key.

list_instances(Key, Length, List) :-
	make_variable_global({List}),
	(   Length =< 250 ->
	    list_instances_one(Key, Length, [], List)
	;   Arity is (Length+249) // 250,
	    list_instances_two(Key, Arity, [], List)
	).


make_variable_global(_).



%   list_instances_one(+Key, +N, +OldBag, -NewBag)
%   is used when the number of variables in Key is N and is at most 250.
%   That is, when we have a one-level key.  We build the list up in
%   reverse order.  We rely on NewBag being a global unbound variable,
%   and use it as a magic marker to decide which variables to replace.

list_instances_one(Key, N, OldBag, NewBag) :-
	retract(setof_stack(_, Term)),
	!,				%  must not backtrack!
	list_instances_one(Term, Key, N, OldBag, NewBag).

list_instances_one([], _, _, AnsBag, AnsBag).
list_instances_one(NewKey-Term, Key, N, OldBag, NewBag) :-
	replace_key_variables_one(N, Key, NewBag, NewKey),
	list_instances_one(Key, N, [NewKey-Term|OldBag], NewBag).

replace_key_variables_one(N, OldKey, MagicMarker, NewKey) :-
	(   N =:= 0 -> true
	;   M is N-1,
	    arg(N, NewKey, Arg),
	    (   var(Arg), Arg @> MagicMarker ->
		arg(N, OldKey, Arg)
	    ;	true
	    ),
	    replace_key_variables_one(M, OldKey, MagicMarker, NewKey)
	).


%   list_instances_two(+Key, +N, +OldBag, -NewBag)
%   is like list_instances_one/4 except that N is the arity of the
%   Key, and the Key is a two-level key.  This should almost never
%   be used.  Note that NewBag plays two roles!

list_instances_two(Key, N, OldBag, NewBag) :-
	retract(setof_stack(_, Term)),
	!,				%  must not backtrack!
	list_instances_two(Term, Key, N, OldBag, NewBag).

list_instances_two([], _, _, AnsBag, AnsBag).
list_instances_two(NewKey-Term, Key, N, OldBag, NewBag) :-
	replace_key_variables_two(N, Key, NewBag, NewKey),
	list_instances_two(Key, N, [NewKey-Term|OldBag], NewBag).

replace_key_variables_two(N, OldKey, MagicMarker, NewKey) :-
	arg(N, OldKey, OldArg),
	arg(N, NewKey, NewArg),
	functor(NewArg, ., Arity),
	replace_key_variables_one(Arity, OldArg, MagicMarker, NewArg),
	(   N =:= 1 -> true
	;   M is N-1,
	    replace_key_variables_two(M, OldKey, MagicMarker, NewKey)
	).



%   conj_instances(+Key, -Goals)
%   picks up the items stored in the data base and returns them
%   as a conjunction (G1, ..., Gn, true).
%   Note that the free variables are mapped back to themselves.

conj_instances(Key, Goals) :-
	conj_instances(Key, true, Goals).

conj_instances(Key, Goals0, Goals) :-
	retract(setof_stack(_, Term)),
	!,
	conj_instances(Term, Key, Goals0, Goals).

conj_instances([], _, Goals, Goals).
conj_instances(Key-Goal, Key, Goals0, Goals) :-
	conj_instances(Key, (Goal,Goals0), Goals).


