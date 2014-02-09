%   Package: aggregate
%   Author : Richard A. O'Keefe
%   Updated: 28 Nov 1989
%   Defines: an aggregation operator for data-base-style queries

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(aggregate, [
	aggregate/3,
	aggregate/4,
	aggregate_all/3,
	aggregate_all/4
   ]).
:- meta_predicate
	aggregate(+, 0, ?),
	aggregate(+, +, 0, ?),
	aggregate_all(+, 0, ?),
	aggregate_all(+, +, 0, ?).

/*----------------------------------------------------------------------
    Data base query languages usually provide so-called "aggregation"
    operations.  Given a relation, aggregation specifies
	(a) a column of the relation
	(b) an operation, one of {sum,max,min,ave,var} or more
    One might, for example, ask

	PRINT DEPT,SUM(AREA) WHERE OFFICE(_ID,DEPT,AREA,_OCCUPANT)

    and get a table of <Department,TotalArea> pairs.  The Prolog
    equivalent of this might be

	dept_office_area(Dept, TotalArea) :-
		aggregate(sum(Area),
		    I^O^office(I,Dept,Area,O), TotalArea).

    where Area is the column and sum(_) is the aggregation operator.
    We can also ask who has the smallest office in each department:

	smallest_office(Dept, Occupant) :-
		aggregate(min(Area),
			I^O^office(I,Dept,Area,O), MinArea),
		office(_, Dept, MinArea, Occupant).

    This module provides an aggregation operator in Prolog:

	    aggregate(Template, Generator, Results)

    where Template is

	    <operator>(<expression>)

    or	<constructor>(<arg>,...,<arg>)
    where	each <arg> is <operator>(<expression>)

    and	<operator> is sum | min | max 		{for now}
    and	<expression> is an arithmetic expression

    Results is unified with a form of the same structure as Template.


    Things like mean and standard deviation can be calculated from
    sums, e.g. to find the average population of countries (defined
    as "if you sampled people at random, what would be the mean
    size of their answers to the question 'what is the population
    of your country?'?") we could do

    ?-	aggregate(x(sum(Pop),sum(Pop*Pop)),
		  Country^population(Country,Pop),
		  x(People,PeopleTimesPops)),
	AveragePop is PeopleTimesPops/People.

    Note that according to this definition, aggregate/3 FAILS if
    there are no solutions.  For max(_), min(_), and many other
    operations (such as mean(_)) this is the only sensible
    definition (which is why bagof/3 works that way).  Even if
    bagof/3 yielded an empty list, aggregate/3 would still fail.

    Concerning the minimum and maximum, it is convenient at times to
    know Which term had the minimum or maximum value.  So we write

	min(Expression, Term)
	max(Expression, Term)

    and in the constructed term we will have

	min(MinimumValue, TermForThatValue)
	max(MaximumValue, TermForThatValue)

    So another way of asking who has the smallest office is

	smallest_office(Dept, Occupant) :-
		aggregate(min(Area,O),
			I^office(I,Dept,Area,O), min(_,Occupant)).

    Consider queries like
	aggregate(sum(Pay), Person^pay(Person,Pay), TotalPay)
    where for some reason pay/2 might have multiple solutions.
    (For example, someone might be listed in two departments.)
    We need a way of saying "treat identical instances of the
    Template as a single instance, UNLESS they correspond to
    different instances of a Discriminator."  That is what

	aggregate(Template, Discriminator, Generator, Results)

    does.  Thus

	NU Prolog		Quintus Prolog
	count(D, Goal, C)	aggregate(count, D, Goal, C)
	max(X, Goal, M)		aggregate(max(X), Goal, M)
	min(X, Goal, M)		aggregate(min(X), Goal, M)
	sum(X, D, Goal, S)	aggregate(sum(X), D, Goal, S)

    Operations available:
	count			sum(1)
	sum(E)			sum of values of E
	min(E)			minimum of values of E
	min(E, X)		min(E) with corresponding instance of X
	max(E)			maximum of values of E
	max(E, X)		max(E) with corresponding instance of X
	set(X)			ordered set of instances of X
	bag(X)			list of instances of X in generated order.

    bagof(X, G, B) :- aggregate(bag(X),    G, L).
    setof(X, G, B) :- aggregate(set(X), X, G, L).

    In 1989, two new operations were added:
	aggregate_all(Template, Generator, Results),
	aggregate_all(Template, Discriminator, Generator, Results).
    They are hybrids between the aggregate/[3,4] operations and the
    {set,bag}_of_all/3 operations found in library(setof).  They insist
    that all the variables in Generator should be captured by the
    Template, the Discriminator, or existential quantifiers.  This means
    that it makes sense for them to return zero counts, zero sums, empty
    sets, and empty bags.
----------------------------------------------------------------------*/


sccs_id('"@(#)89/11/28 aggregate.pl	36.1"').


%   aggregate(+Template, +Discriminator, +Generator, ?Result)
%   is a generalisation of setof/3 which lets you compute sums,
%   minima, maxima, and so on.  library(aggregate) explains.

aggregate(Template, Discriminator, Generator, Result) :-
	parse_template(Template, Pattern),
	setof(Discriminator-Pattern, Generator, Set),
	strip_discriminator(Set, List),
	process_results(List, Pattern, Result).

strip_discriminator([], []).
strip_discriminator([_-T|S], [T|R]) :-
	strip_discriminator(S, R).


%   aggregate(+Template, +Generator, ?Result)
%   is a generalisation of findall/3 which lets you compute sums,
%   minima, maxima, and so on.  library(aggregate) explains.

aggregate(Template, Generator, Result) :-
	parse_template(Template, Pattern),
	bagof(Pattern, Generator, List),
	process_results(List, Pattern, Result).


:- use_module(library(freevars), [
	free_variables/4
   ]),
   use_module(library(break), [
	error_break/2
   ]).

/*  A general note:
    The simplest way of coding these predicates would be to copy the
    definitions of aggregate/[3,4] replacing setof/3 by set_of_all/3
    and bagof/3 by bag_of_all/3.  I have chosen not to do that for
    two reasons:
    (a) calling free_variables/4 here means that I can report the
	actual call in any error message, not the internal *_of_all/3.
    (b) at the moment I call setof/3 and bagof/3 because they are quite
	a bit faster than the library *_of_all/3 predicates.  That is
	going to change:  in the 2.5 final release findall/3 will be
	available to users, which means that set_of_all/3 and bag_of_all/3
	can be about as fast as setof/3 and bagof/3.
    Reason (a) will still hold, so in the 2.5 final release, make the
    changes suggested by the comments.
*/

%   aggregate_all(Template, Discriminator, Generator, Result)
%   is like aggregate/4 except that it will find at most one solution,
%   and does not bind free variables in the Generator.  It is a hybrid
%   between aggregate/4 and set_of_all/3.

aggregate_all(Template, Discriminator, Generator, Result) :-
        free_variables(Generator, Discriminator-Template, [], Vars),
        Vars \== [],            % Note that there is no cut here!
        error_break('~N! free variables ~p~n! in goal ~p~n',
            [Vars,aggregate_all(Template,Discriminator,Generator,Result)]),
        fail.                   % the user may say to proceed anyway.
aggregate_all(Template, Discriminator, Generator, Result) :-
	parse_template(Template, Pattern),
/*  PRE 2.5 final release:  /*
	(   setof(Discriminator-Pattern, Generator, Set) -> true
	;   Set = []
	),
/*  2.5 final release and later:  */
	findall(Discriminator-Pattern, Generator, Bag),
	sort(Bag, Set),
/*  END code which depends on whether findall/3 is built in or not.  */
	strip_discriminator(Set, List),
	process_results(List, Pattern, Result).


%   aggregate_all(Template, Generator, Result)
%   is like aggregate/3 except that it will find at most one solution,
%   and dois not bind free variables in the Generator.  It is a hybrid
%   between aggregate/3 and bag_of_all/3.

aggregate_all(Template, Generator, Result) :-
        free_variables(Generator, Template, [], Vars),
        Vars \== [],            % Note that there is no cut here!
        error_break('~N! free variables ~p~n! in goal ~p~n',
            [Vars,aggregate_all(Template,Generator,Result)]),
        fail.                   % the user may say to proceed anyway.
aggregate_all(Template, Generator, Result) :-
	parse_template(Template, Pattern),
/*  PRE 2.5 final release:  /*
	(   bagof(Pattern, Generator, List) -> true
	;   List = []
	),
/*  2.5 final release and later:  */
	findall(Pattern, Generator, List),
/*  END code which depends on whether findall/3 is built in or not.  */
	process_results(List, Pattern, Result).


%   parse_template(+Template, -Pattern)
%   takes a template as written by the programmer and turns it into
%   a Pattern which has a disinct constructor function for each case.
%   The cases for Pattern are

%	any(V)		was a source variable.  This should be reported
%			as an error, but isn't for the moment.
%	set(Term)	was set(Term).  The final result will be a list
%			in standard order with no duplicates.  It will
%			NOT have set(_) wrapped around it.
%	bag(Term)	was bag(Term).  The final result will be a list
%			in the order generated, with duplicates if they
%			were generated.  It will NOT have bag(_) around it.
%	sum(Expr)	was sum(Expr).  The final result will be
%			the sum of the values of the Exprs.  It will NOT
%			have sum(_) wrapped around it.
%	count		was count.  We could use sum(1), but this is
%			more compact.
%	min(Expr)	was min(Expr).  The final result will be the
%			minimum of the values of the Exprs.  It will NOT
%			have min(_) wrapped around it.
%	max(Expr)	was max(Expr).  The final result will be the
%			maximum of the values of the Exprs.  It will NOT
%			have max(_) wrapped around it.
%	min(Expr,Term)	was min(Expr,Term).  The final result will be the
%			pair min(N,T) where N is the minimum of the values
%			of the Exprs and T is the corresponding Term.  This
%			DOES have the min(_,_) wrapper.
%	max(Expr,Term)	was max(Expr,Term).  The final result will be the
%			pair max(N,T) where N is the maximum of the values
%			of the Exprs and T is the corresponding Term.  This
%			DOES have the max(_,_) wrapper.
%	pat(F,List)	F is an atom and List is a list of patterns.  The
%			final result is F(List') where List' is the sequence
%			of values of elements of List.  For example,
%			sum(X)/count in the Template would be represented
%			as pat(/,[sum(X),sum(1)]) in the Pattern, and the
%			final result might be 273/9.
%	[H|T]		an optimisation of pat(.,[H,T]).
%	con(Term)	An optimisation of pat/2 where the Term is ground.

parse_template(Var,      any(Var)) :- var(Var), !.
parse_template(set(X),   set(X))   :- !.
parse_template(bag(X),   bag(X))   :- !.
parse_template(count,    count)    :- !.
parse_template(sum(E),   sum(E))   :- !.
parse_template(min(E),   min(E))   :- !.
parse_template(max(E),   max(E))   :- !.
parse_template(min(E,T), min(E,T)) :- !.
parse_template(max(E,T), max(E,T)) :- !.
parse_template([],       [])       :- !.
parse_template(Term,     con(Term)):-
	numbervars(Term, 0, 0),
	!.
parse_template([E|Es],	 [X|Xs])   :- !,
	parse_template(E, X),
	parse_template(Es, Xs).
parse_template(Template, pat(F,L)) :-
	functor(Template, F, N),
	parse_template(N, Template, [], L).

parse_template(N, Template, L0, L) :-
    (	N =:= 0 -> L = L0
    ;	M is N-1,
	arg(N, Template, Arg),
	parse_template(Arg, Pat),
	parse_template(M, Template, [Pat|L0], L)
    ).


%   process_results(+ListInstances, +Pattern, ?Result)
%   takes a list of instances of the Pattern as calculated by
%   bagof/3 or setof/3, combines the results according to the
%   pattern, and unifies Result with the combination.

%   If ListOfPatternInstances is empty, the Result is defaulted from
%   the Pattern.  For aggregate_all/[3,4] this makes sense, but for
%   aggregate/[3,4] it doesn't, as those two are supposed to succeed
%   only when the List is nonempty.  However, bagof/3 and setof/3 do
%   not yield an empty list, so we've nothing to worry about.

process_results([], Pattern, Result) :-
	process_default(Pattern, Result).
process_results([First|Rest], Pattern, Result) :-
	process_first(First, X0),
	process_rest(Rest, X0, X1),
	process_result(Pattern, X1, Result).

/*  When there are no solutions,
	any(_), min(_), min(_,_), max(_), and max(_,_)
    can be assigned no meaning, so process_default/2 fails.
*/
process_default(con(X),  X).
process_default(set(_), []).
process_default(bag(_), []).
process_default(count,   0).
process_default(sum(_),  0).
process_default([],     []).
process_default([E|Es], [X|Xs]) :-
	process_default(E, X),
	process_default(Es, Xs).
process_default(pat(F,Es), T) :-
	process_default(Es, Xs),
	T =.. [F|Xs].

process_first(any(X), X).
process_first(con(X), X).
process_first(set(X), [X]).
process_first(bag(X), [X]).
process_first(count,  1).
process_first(sum(E), X) :- eval(E, X).
process_first(min(E), X) :- eval(E, X).
process_first(max(E), X) :- eval(E, X).
process_first(min(E,T), min(X,T)) :- eval(E, X).
process_first(max(E,T), max(X,T)) :- eval(E, X).
process_first([],     []).
process_first([E|Es], [X|Xs]) :-
	process_first(E, X),
	process_first(Es, Xs).
process_first(pat(_,Es), Xs) :-
	process_first(Es, Xs).


process_rest([], X, X).
process_rest([E|Es], X0, X) :-
	process_next(E, X0, X1),
	process_rest(Es, X1, X).

process_next(any(_), V, V).
process_next(con(_), V, V).
process_next(set(X), V, [X|V]).
process_next(bag(X), V, [X|V]).
process_next(count,  V, V1) :-
	V1 is V+1.
process_next(sum(E), V, V1) :-
	eval(E, X),
	V1 is V+X.
process_next(min(E), V, V1) :-
	eval(E, X),
	( X < V -> V1 = X ; V1 = V ).
process_next(max(E), V, V1) :-
	eval(E, X),
	( X > V -> V1 = X ; V1 = V ).
process_next(min(E,T), min(V,C), min(V1,C1)) :-
	eval(E, X),
	( X < V -> V1 = X, C1 = T ; V1 = V, C1 = C ).
process_next(max(E,T), max(V,C), max(V1,C1)) :-
	eval(E, X),
	( X > V -> V1 = X, C1 = T ; V1 = V, C1 = C ).
process_next([], [], []).
process_next([E|Es], [V|Vs], [W|Ws]) :-
	process_next(E, V, W),
	process_next(Es, Vs, Ws).
process_next(pat(_,L), V, V1) :-
	process_next(L, V, V1).



process_result(any(_), X, X).
process_result(con(_), X, X).
process_result(set(_), V, X) :-
	sort(V, X).
process_result(bag(_), V, X) :-
	rev(V, [], X).
process_result(count,  X, X).
process_result(sum(_), X, X).
process_result(min(_), X, X).
process_result(max(_), X, X).
process_result(min(_,_), X, X).
process_result(max(_,_), X, X).
process_result([], [], []).
process_result([E|Es], [V|Vs], [X|Xs]) :-
	process_result(E, V, X),
	process_result(Es, Vs, Xs).
process_result(pat(F,L), V, X) :-
	length(L, N),
	functor(X, F, N),
	process_result_s(L, V, X, 0).

process_result_s([], [], _, _).
process_result_s([E|Es], [X|Xs], T, M) :-
	N is M+1,
	arg(N, T, V),
	process_result(E, X, V),
	process_result_s(Es, Xs, T, N).


rev([], L, L).
rev([H|T], L, R) :-
	rev(T, [H|L], R).


/*  Note: call(Ans is Expr) is used to evaluate expressions;
    this avoids the problem that compiled Dec-10 Prolog and
    all modes of Quintus Prolog demand that source variables
    must be bound to numbers in "is" calls not so protected.
*/
eval(Expr, Ans) :-
	call(Ans is Expr).

