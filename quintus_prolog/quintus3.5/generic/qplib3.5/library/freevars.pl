%   Package: free_variables
%   Author : Richard A. O'Keefe
%   Updated: 03 May 1989
%   Purpose: SUPPORT for not.pl,setof.pl,foreach.pl

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  In earlier releases of the Dec-10 Prolog, C Prolog, and Quintus
    Prolog libraries, the predicate free_variables/4 was defined
    elsewhere (typically not.pl), and used freely by any library
    file which included that one.  However, I don't really want to
    make free_variables/4 a public predicate of library(not), so
    this predicate has been split out into its own file.

    This is support for not.pl, setof.pl, and foreach.pl.  It is
    not meant for general use.

    In August 1987, term_variables/3 was added to support the new
    grouped_{bag,set}_of/4 predicates.

    In April 1989, all of the code for free_variables/4 was scrapped.
    It had always been our intention to have free_variables/4 check
    for quantifiers ONLY in "code" rather than "data".  Note that it
    should really look inside the meta-arguments of meta_predicates.
    The built-in setof/3 and bagof/3 use a version of free_variables/4
    which does this.
*/
:- module(free_variables, [
	free_variables/4,
	term_variables/3
   ]).

:- mode
	free_variables(+, +, +, -),
	    free_variables_1(+, +, +, -),
	    data_variables(+, +, +, -),
		data_variables(+, +, +, +, -),
	list_is_free_of(+, +),
	term_is_free_of(+, +),
	    term_is_free_of(+, +, +),
	term_variables(+, +, -),
	    term_variables(+, +, +, -).


sccs_id('"@(#)89/05/03 freevars.pl	31.3"').


%   free_variables(+Goal, +Bound, +Vars0, -Vars)
%   binds Vars to the union of Vars0 with the set of *FREE* variables
%   in Goal, that is the set of variables which are captured neither
%   by Bound nor by any internal quantifiers or templates in Goal.
%   We have to watch out for setof/3 and bagof/3 themselves, for the
%   explicit existential quantifier Vars^Goal, and for things like
%   \+(_) which might look as though they bind variables but can't.

free_variables(Term, Bound, Vars0, Vars) :-
	(   nonvar(Term) ->
	    free_variables_1(Term, Bound, Vars0, Vars)
	;   term_is_free_of(Bound, Term),
	    list_is_free_of(Vars0, Term)
	->  Vars = [Term|Vars0]
	;   Vars = Vars0
	).

free_variables_1(:(_Module,Goal), Bound) --> !,
	free_variables_1(Goal, Bound).
free_variables_1((Conjunct,Conjuncts), Bound) --> !,
	free_variables(Conjunct,  Bound),
	free_variables(Conjuncts, Bound).
free_variables_1((Disjunct ; Disjuncts), Bound) --> !,
	free_variables(Disjunct,  Bound),
	free_variables(Disjuncts, Bound).
free_variables_1((If -> Then), Bound) --> !,
	free_variables(If,   Bound),
	free_variables(Then, Bound).
free_variables_1(call(Goal), Bound) --> !,
	free_variables(Goal, Bound).
free_variables_1(\+(_), _) --> !.
free_variables_1(Vars^Goal, Bound) --> !,
	free_variables(Goal, Vars^Bound).
free_variables_1(setof(Template,Generator,Set), Bound) --> !,
	free_variables(Generator, Template^Bound),
	data_variables(Set, Bound).
free_variables_1(bagof(Template,Generator,Bag), Bound) --> !,
	free_variables(Generator, Template^Bound),
	data_variables(Bag, Bound).

/*  The following two clauses are included because you will have to
    use set_of/3 and bag_of/3 throughout your program instead of
    setof/3 and bagof/3 to work around the bug.
*/
free_variables_1(set_of(Template,Generator,Set), Bound) --> !,
	free_variables(Generator, Template^Bound),
	data_variables(Set, Bound).
free_variables_1(bag_of(Template,Generator,Bag), Bound) --> !,
	free_variables(Generator, Template^Bound),
	data_variables(Bag, Bound).

/*  If you intend to use any of the library predicates
	set_of/3, bag_of/3, set_of_all/3, bag_of_all/3,
	findall/3, aggregate/3, grouped_bag_of/3,
	grouped_set_of/3, grouped_aggregate/3, forall/2
    then move the corresponding clauses above this comment.
    This version of library(freevars) was prepared for the
    Philips laboratory in Brussels.  The next line is not a mistake!
/*
free_variables_1(set_of_all(Template,Generator,Set), Bound) --> !,
	free_variables(Generator, Template^Bound),
	data_variables(Set, Bound).
free_variables_1(bag_of_all(Template,Generator,Bag), Bound) --> !,
	free_variables(Generator, Template^Bound),
	data_variables(Bag, Bound).
free_variables_1(findall(_,_,List), Bound) --> !,
	% The Generator is ignored, just like \+(Generator)
	data_variables(List, Bound).
free_variables_1(aggregate(Template,Generator,Aggregate), Bound) --> !,
	free_variables(Generator, Template^Bound),
	data_variables(Aggregate, Bound).
free_variables_1(grouped_set_of(GroupVars,_,_,Set), Bound) --> !,
	data_variables(GroupVars, Bound),
	data_variables(Set, Bound).
free_variables_1(grouped_bag_of(GroupVars,_,_,Bag), Bound) --> !,
	data_variables(GroupVars, Bound),
	data_variables(Bag, Bound).
free_variables_1(grouped_aggregate(GroupVars,_,_,Aggregate), Bound) --> !,
	data_variables(GroupVars, Bound),
	data_variables(Aggregate, Bound).
free_variables_1(forall(_,_), _) --> !.

/*  End of "optional" clauses.
*/
free_variables_1(NormalGoal, Bound) -->
	data_variables(NormalGoal, Bound).

%   data_variables(+Term, +Bound, +Vars0, -Vars)
%   binds Vars to the union of Vars0 with the set of variables in Term
%   which do not occur in (are not "captured by") Bound.  When the Bound
%   contains no variables, it delivers the same results as
%   term_variables(Term, Vars0, Vars).

data_variables(Term, Bound, Vars0, Vars) :-
	(   nonvar(Term) ->
	    functor(Term, _, N),
	    data_variables(N, Term, Bound, Vars0, Vars)
	;   term_is_free_of(Bound, Term),
	    list_is_free_of(Vars0, Term)
	->  Vars = [Term|Vars0]
	;   Vars = Vars0
	).

data_variables(N, Term, Bound) -->
    (	{ N =:= 0 } -> []
    ;	{ arg(N, Term, Arg), M is N-1 },
	data_variables(Arg, Bound),
	data_variables(M, Term, Bound)
    ).



%   term_is_free_of(+Term, +Var)
%   is a meta-logical predicate which is true when the variable Var
%   does not occur anywhere in the term Term.  It is used when the
%   Term is a tree built from all the existential quantifiers and
%   Templates dominating (the goal containing) this variable.

term_is_free_of(Term, Var) :-
	(   var(Term) ->
	    Term \== Var
	;   functor(Term, _, N),
	    term_is_free_of(N, Term, Var)
	).

term_is_free_of(N, Term, Var) :-
	(   N =:= 0 -> true
	;   arg(N, Term, Arg),
	    term_is_free_of(Arg, Var),
	    M is N-1,
	    term_is_free_of(M, Term, Var)
	).


%   list_is_free_of(+Vars0, +Var)
%   is a meta-logical predicate which is true when the variable Var
%   is not an element of Vars0, which is known to be a list of variables.
%   It is used when Vars0 is the set of free variables which have been
%   built up so far, and we are considering whether Var should be
%   added to this set.

list_is_free_of([], _).
list_is_free_of([Head|Tail], Var) :-
	Head \== Var,
	list_is_free_of(Tail, Var).


%   term_variables(+Term, +Vars0, ?Var)
%   binds Var to a union of Vars0 and the variables which occur in Term.
%   This doesn't take quantifiers into account at all.

term_variables(Term, Vars0, Vars) :-
	nonvar(Term),
	!,
	functor(Term, _, N),
	term_variables(N, Term, Vars0, Vars).
term_variables(Term, Vars0, [Term|Vars0]) :-
	list_is_free_of(Vars0, Term),
	!.
term_variables(_, Vars, Vars).


term_variables(N, Term) -->
    (	{ N =:= 0 } -> []
    ;	{ arg(N, Term, Arg), M is N-1 },
	term_variables(Arg),
	term_variables(M, Term)
    ).


