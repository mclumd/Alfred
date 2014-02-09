%   Package: setof
%   Author : Richard A. O'Keefe
%   Updated: 01 Nov 1988
%   Defines: improved versions of setof and bagof

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This file defines two predicates which act like setof/3 and bagof/3.
    I have seen the code for these routines in Dec-10 and in C-Prolog,
    but I no longer recall it, and this code was independently derived
    in 1982 by me and me alone.

    Most of the complication comes from trying to cope with free variables
    in the Filter; these definitions actually enumerate all the solutions,
    then group together those with the same bindings for the free variables.
    There must be a better way of doing this.  I do not claim any virtue for
    this code other than the virtue of working.  In fact there is a subtle
    bug: if setof/bagof occurs as a data structure in the Generator it will
    be mistaken for a call, and free variables treated wrongly.  Given the
    current nature of Prolog, there is no way of telling a call from a data
    structure, and since nested calls are FAR more likely than use as a
    data structure, we just put up with the latter being wrong.  The same
    applies to negation.

    Two new predicates were introduced in April 1986.  They are
	set_of_all(Template, Goal, Set)
	bag_of_all(Template, Goal, Bag)
    The names are meant to suggest that these routines are a cross
    between set_of/bag_of and findall.  What this means is that they
    are happy to return an empty list of solutions (as findall is),
    but that they have the same interpretation of free variables as
    set_of/3 and bag_of/3.  How are these two statements resolved?
    By *checking* that there are NO free variables in Goal, which
    is the only time that findall/3 ever really makes sense.  (Yes,
    I do know what I'm talking about.)  The cost of this check is
    typically slight.  

    Two new predicates were introduced in August 1987.  They are
	grouped_set_of(GroupVars, Template, Goal, Set)
	grouped_bag_of(GroupVars, Template, Goal, Bag)
    These routines resemble setof/3 and bagof/3 except that they
    use a different convention for identifying which variables are
    the "free" variables to be enumerated by the routine and which
    variables are the "existentially quantified" variables which
    are in effect to be ignored.  setof/3 and and bagof/3 (and the
    other routines in this file) mark the existentially quantified
    variables specially.  These two predicates mark the free
    variables specially.  In particular, if GroupVars contains no
    variables, grouped_bag_of/4 is identical in its effect to
    findall/3.  grouped_set_of/4 is analogous to
	SELECT Template FROM Goal GROUP BY GroupVars
    in a data-base query language.

    In October 1987, a customer reported a bug.  The bug turned out
    to be that if the Generator had too many free variables, the
    goal	Key =.. [.|Vars]
    which we used to build the key just failed quietly, because it
    could not make a term with more than 255 arguments.  So now we
    have a make_key/3 predicate which constructs one-level keys as
    before for |Vars| =< 250, two-level keys for |Vars| =< 62,500,
    or fails (and this failure is reported) for |Vars| > 62,500.
    In the process of fixing this bug, another bug was noticed.  As
    the terms which come back in the list are copies of the terms
    which were recorded, they are guaranteed to have all new vars.
    replace_key_variables tries to put the old variables back.  But
    it was too eager.  If the original free variables had been X,Y
    and one instance had bound X=Y but left them variables, we'd
    try to bind X=Y in all instances (where both were variables).
    This seems wrong.  So now we only bind a variable to its old
    equivalent if it is a *new* variable.  Thank you, @> .
*/

:- module(setof, [
	bag_of/3,		%   Like bagof (Dec-10 manual p52)
	bag_of_all/3,		%   bag_of/findall hybrid.
	grouped_bag_of/4,	%   bag_of, but opposite marking
	set_of/3,		%   Like setof (Dec-10 manual p51)
	set_of_all/3,		%   set_of/findall hybrid.
	grouped_set_of/4	%   set_of, but opposite marking
   ]).

:- meta_predicate
	bag_of(+, 0, ?),
	bag_of_all(+, 0, ?),
	grouped_bag_of(+, +, 0, ?),
	set_of(+, 0, ?),
	set_of_all(+, 0, ?),
	grouped_set_of(+, +, 0, ?),
	bag_of(+, +, 0, ?).	%   The kernel.

:- use_module(library(freevars), [
	free_variables/4,	%   find unquantified variables
	term_variables/3	%   find all variables
   ]),
   use_module(library(break), [
	error_break/2		%   report bad {set,bag}_of_all/3 calls
   ]),
   use_module(library(sofstk),	[
	save_instances/2,	%   use for 0 free variables
	save_instances/3,	%   use for >= 1 free variables
	list_instances/1,	%   use for 0 free variables
	list_instances/3,	%   use for >= 1 free variables
	make_key/3		%   converts list of vars to key
   ]).



sccs_id('"@(#)88/11/01 setof.pl	27.1"').



%   set_of(+Template, +Generator, ?Set)
%   finds the Set of instances of the Template satisfying the Generator.
%   The set is in ascending order (see compare/3 for a definition of
%   this order) without duplicates, and is non-empty.  If there are
%   no solutions, set_of fails.  set_of may succeed more than one way,
%   binding free variables in the Generator to different values.  This
%   predicate is defined on p51 of the Dec-10 Prolog manual.

set_of(Template, Filter, Set) :-
	bag_of(Template, Filter, Bag),
	sort(Bag, Set).



%   set_of_all(+Template, +Generator, ?Set)
%   is like set_of, but (like not/1), checks that there are no free
%   variables.  We could have called bag_of_all/3 the way that set_of
%   calls bag_of/2, but this way we get a more precise error message.

set_of_all(Template, Generator, Set) :-
	free_variables(Generator, Template, [], Vars),
	Vars \== [],		% Note that there is no cut here!
	error_break('~N! free variables ~p~n! in goal ~p~n',
	    [Vars,set_of_all(Template,Generator,Set)]),
	fail.			% if user okays it, act like findall+sort
set_of_all(Template, Generator, Set) :-
	save_instances(Template, Generator),
	list_instances(Bag),
	sort(Bag, Set).



%   grouped_set_of(+GroupVars, +Template, +Generator, ?Set)
%   is like set_of/3, but instead of marking existential variables
%   with the ^ existential quantifier and having the grouping
%   variables be everything else, this version marks the free
%   variables by listing them in the GroupVars argument, and every
%   variable of the Generator which doesn't appear in GroupVars or
%   Template is implicitly taken to be existential.  A consequence
%   of the way this is done is that a variable can appear in BOTH
%   GroupVars and Template, and GroupVars "wins".

grouped_set_of(GroupVars, Template, Generator, Solutions) :-
	grouped_bag_of(GroupVars, Template, Generator, Instances),
	sort(Instances, Solutions).



%   bag_of(+Template, +Generator, ?Bag)
%   finds all the instances of the Template produced by the Generator,
%   and returns them in the Bag in they order in which they were found.
%   If the Generator contains free variables which are not bound in the
%   Template, it assumes that this is like any other Prolog question
%   and that you want bindings for those variables.  (You can tell it
%   not to bother by using existential quantifiers.)

bag_of(Template, Generator, Bag) :-
	free_variables(Generator, Template, [], Vars),
	bag_of(Vars, Template, Generator, Bag).


bag_of([], Template, Generator, Bag) :- !,
	save_instances(Template, Generator),
	list_instances(Bag),
	Bag \== [].
bag_of(Vars, Template, Generator, Bag) :-
	make_key(Vars, Length, Key),
	!,
	save_instances(Key, Template, Generator),
	list_instances(Key, Length, OmniumGatherum),
	keysort(OmniumGatherum, Gamut),
	concordant_subset(Gamut, Key, Answer),
	Bag = Answer.
bag_of(Vars, _, Generator, _) :-
	numbervars(Vars, 0, Length),
	format(user_error,
	    '~N! set_of/bag_of free variable limit is 62,500.~n', []),
	format(user_error,
	    '! but generator has ~d free variables.~n! Culprit: ~q~n',
	    [Length, Generator]),
	fail.


%   bag_of_all(+Template, +Generator, ?Bag)
%   is like bag_of, but (like not/1), checks that there are no free
%   variables.  It is then equivalent to findall/3, but meaningful.

bag_of_all(Template, Generator, Bag) :-
	free_variables(Generator, Template, [], Vars),
	Vars \== [],		% Note that there is no cut here!
	error_break('~N! free variables ~p~n! in goal ~p~n',
	    [Vars,bag_of_all(Template,Generator,Bag)]),
	fail.			% if user okays it, act like findall.
bag_of_all(Template, Generator, Bag) :-
	save_instances(Template, Generator),
	list_instances(Bag).



%   grouped_bag_of(+GroupVars, +Template, +Generator, ?Bag)
%   is like bag_of/3, but instead of marking existential variables
%   with the ^ existential quantifier and having the grouping
%   variables be everything else, this version marks the free
%   variables by listing them in the GroupVars argument, and every
%   variable of the Generator which doesn't appear in GroupVars or
%   Template is implicitly taken to be existential.  A consequence
%   of the way this is done is that a variable can appear in BOTH
%   GroupVars and Template, and GroupVars "wins".  If there are no
%   variables in GroupVars, this is identical to findall/3 except
%   for refusing to generate the empty bag.

grouped_bag_of(GroupVars, Template, Generator, Bag) :-
	term_variables(GroupVars, [], Vars),
	bag_of(Vars, Template, Generator, Bag).



%%  concordant_subset([Key-Val list], Key, [Val list]).
%   takes a list of Key-Val pairs which has been keysorted to bring
%   all the identical keys together, and enumerates each different
%   Key and the corresponding lists of values.

concordant_subset([Key-Val|Rest], Clavis, Answer) :-
	concordant_subset(Rest, Key, List, More),
	concordant_subset(More, Key, [Val|List], Clavis, Answer).


%%  concordant_subset(Rest, Key, List, More)
%   strips off all the Key-Val pairs from the from of Rest,
%   putting the Val elements into List, and returning the
%   left-over pairs, if any, as More.

concordant_subset([Key-Val|Rest], Clavis, [Val|List], More) :-
	Key == Clavis,
	!,
	concordant_subset(Rest, Clavis, List, More).
concordant_subset(More, _, [], More).


%%  concordant_subset/5 tries the current subset, and if that
%   doesn't work if backs up and tries the next subset.  The
%   first clause is there to save a choice point when this is
%   the last possible subset.

concordant_subset([],   Key, Subset, Key, Subset) :- !.
concordant_subset(_,    Key, Subset, Key, Subset).
concordant_subset(More, _,   _,   Clavis, Answer) :-
	concordant_subset(More, Clavis, Answer).


