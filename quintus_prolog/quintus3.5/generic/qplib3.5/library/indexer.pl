%   Package: indexer
%   Author : Richard A. O'Keefe
%   Updated: 25 Oct 1990
%   Purpose: Provide multi-argument indexing.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  CAVEAT LECTOR:
    This was written on the fly during the Advanced Prolog Course.
    You must not reload this module, and if you are using term_expansion
    you will have to use add_linking_clause too (see the last line of
    this file and imitate it).
    There is a design probem which means that multi-index predicates
    can currently only be in user:, I intend to fix this later.
    THIS IS NOT A SUPPORTED PRODUCT.
*/

:- module(indexer, [
	add_fact/1,
	del_all/1,
	del_fact/1
   ]).
:- meta_predicate
	add_fact(0),
	del_fact(0),
	del_all(0).

:- use_module(library(addportray), [
	add_linking_clause/3
   ]).


sccs_id('"@(#)90/10/25 indexer.pl	58.1"').

/*  The basic idea is that we want people to be able to write in their
    programs

	:- index(<pred>(<argspecs>)).

    where

	<argspecs> --> <argspec> ( [','] -> <argspecs> | [])

	<argspec> --> ['?'] | [X], {between(1,arity(pred),X}

    In fact, to keep it simple, I think we'll let the numbers
    be anything, and sort into increasing order.

    The :- index(<pred>(<argspecs>))
    fact turns into
	<pred>(<args>) :-
		(   nonvar(<key>) --> true	% first indexed arg
		;   nonvar(<arg>) --> <index>(<arg>,<key>)	% 2nd
		;...
		;   nonvar(<arg>) --> <index>(<arg>,<key>)	% last
		;   true
		),
		<real pred>(<permuted args>).

    The <index> predicates are inverted indices.  The names are
    made by sticking the argument number (relative to the original
    predicate) in front of the predicate name.  E.g. '1 fred'.
    The <real pred>'s name is made by sticking 0 in front.

    The permuted arguments of the <real pred> are the numbered
    arguments of the original predicate in ascending order of
    number, followed by the '?' arguments, in original order.

    For example, if the declaration were

	:- index(fred(1, ?, ?, 2, 3, ?)).

    the linkage clause would be

	fred(A1, X2, X3, B4, C5, X6) :-
		(   nonvar(A1) -> true
		;   nonvar(B4) -> '4 fred'(B4, A1)
		;   nonvar(C5) -> '5 fred'(C5, A1)
		;   true
		),
		'0 fred'(A1, B4, C5, X2, X3, X6).

    The '# fred' predicates are abolished, then made dynamic.

    Such a predicate is updated using two new predicates exported
    by this module:

	add_fact(<pred>(<args>))
	del_fact(<pred>(<args>))

    For a change, del_fact/1 is NOT going to backtrack.  In fact both of
    these predicates are going to insist that the relevant arguments
    should already be ground.  We can easily code

	del_all(X) :- X, del_fact(X), fail ; true.

    What happens when there are several items in the original table
    with a particular value of key K and an indexed argument I?  We
    have to have #pred(I,K) in the table, but what do we do about
    multiple copies of this pattern?  The ideal thing would be to
    maintain a reference count, so that del_fact would decrement the
    reference count and only delete the index item when the count
    reaches zero.  A later version of this package will do that.
    But this version makes the world safe for del_fact by storing
    an index pair for each tuple, even redundant ones.  Yes, this
    will make for some redundancy.

    In order to do an add fact or del_fact, we need
    to accept a fact,
	to return the permuted fact
	and all the indices.
    The change is valid if this is possible and the indices are all
    ground.  We compute this mapping at "compile" time.

    The table
	indexed(PredPattern, Module,
		PermPattern, Indices)
    takes care of this (the permuted fact and the indices live in the
    module that the :- index declaration was seen in).
*/

:- dynamic
	indexed/4.

%   add_fact(+Module:Fact)
%   adds a unit clause to an indexed predicate.
%   The indexed arguments of the fact should be ground.

add_fact(RawFact) :-
	unpack_fact(RawFact, user, RealFact, Module, Indices),
	ground(Indices),
	!,
	Module:assert(RealFact),
	assert_each(Indices, Module).
add_fact(RawFact) :-
	unpack_fact(RawFact, user, _, _, _),
	!,		% we have diagnosed the error
	format(user_error,
	    '~N! An indexed argument is not ground~n! Goal: ~q~n',
	    [add_fact(RawFact)]),
	fail.
add_fact(RawFact) :-
	format(user_error,
	    '~N! The predicate is not indexed~n! Goal: ~q~n',
	    [add_fact(RawFact)]),
	fail.

assert_each([], _).
assert_each([Head|Tail], Module) :-
	Module:assert(Head),
	assert_each(Tail, Module).



%   del_fact(+Module:Fact)
%   deletes a unit clause from an indexed predicate.
%   The indexed arguments of the fact should be ground.

del_fact(RawFact) :-
	unpack_fact(RawFact, user, RealFact, Module, Indices),
	ground(Indices),
	!,			% blocks error message; query sensible
	Module:retract(RealFact),
	!,			% commits to first "solution"
	delete_each(Indices, Module).
del_fact(RawFact) :-
	unpack_fact(RawFact, user, _, _, _),
	!,			% we have diagnosed the error
	format(user_error,
	    '~N! An indexed argument is not ground~n! Goal: ~q~n',
	    [del_fact(RawFact)]),
	fail.
del_fact(RawFact) :-
	format(user_error,
	    '~N! The predicate is not indexed~n! Goal: ~q~n',
	    [del_fact(RawFact)]),
	fail.

delete_each([], _).
delete_each([Head|Tail], Module) :-
	Module:retract(Head),
	delete_each(Tail, Module).



%   del_all(+:Module:Pattern)
%   deletes from an indexed predicate all facts matching the given
%   pattern.  The indexed arguments do not need to be ground.
%   Note that we cannot build on retractall/1, because we need to
%   know about the retracted clauses so that we can remove the
%   appropriate index entries.

del_all(RawFact) :-
	unpack_fact(RawFact, user, RealFact, Module, Indices),
	!,			% blocks error message; query sensible
	(   Module:retract(RealFact),
	    delete_each(Indices, Module),
	    fail
	;   true
	).
del_all(RawFact) :-
	format(user_error,
	    '~N! The predicate is not indexed~n! Goal: ~q~n',
	    [del_fact(RawFact)]),
	fail.





%   unpack_fact(+RawFact, +RawMod, -RealFact, -RealMod, -Indices)
%   does two things:  it strips module prefixes from RawFact, and
%   it looks the result up in the indexed/4 table.  If the input
%   is ill formed or not in the table, it fails.

unpack_fact(-, _, _, _, _) :- !, fail.	% reject variable goals
unpack_fact(Module:Goal, _, RealFact, RealMod, Indices) :- !,
	unpack_fact(Goal, Module, RealFact, RealMod, Indices).
unpack_fact(Goal, Module, RealFact, Module, Indices) :-
	atom(Module),
	/* nonvar(Goal), or clause 1 would have matched */
	/* Goal is not _:_, or clause 2 would have matched */
	indexed(Goal, Module, RealFact, Indices).



%   ground(X)
%   succeeds when X is already a ground term.
%   This is actually defined in library(types), but I'm not using
%   anything else from it yet.
%   Now ground/1 is a builtin
% ground(X) :-
%	numbervars(X, 0, 0).
%


%   expand_indexed_rule(+Clause, -Expansion)
%   checks for Head :- Body and Head where Head is an
%   indexed predicate.  If any indexed arguments are not
%   ground, the rule is rewritten to an error message.

expand_indexed_rule((RawHead :- Body), Translation) :- !,
	unpack_fact(RawHead, user, RealHead, Module, Indices),
	(   ground(Indices) ->
	    Translation = (RealHead :- Body),
	    assert_each(Indices, Module)
	;   Translation = :-((format(user_error,
		'~N! An indexed argument is not ground~n! Clause: ~q~n',
		[(RawHead:-Body)]), fail))
	).
expand_indexed_rule(:-(_), _) :- !,
	fail.
expand_indexed_rule(?-(_), _) :- !,
	fail.
expand_indexed_rule(RawHead, Translation) :-
	unpack_fact(RawHead, user, RealHead, Module, Indices),
	(   ground(Indices) ->
	    Translation = RealHead,
	    assert_each(Indices, Module)
	;   Translation = :-((format(user_error,
		'~N! An indexed argument is not ground~n! Clause: ~q~n',
		[RawHead]), fail))
	).




%   make_auxiliary_name(+Name, +Prefix, -Result)
%   is true when concat_atom([Prefix," ",Name], Result),
%   but done without loading library(strings).

make_auxiliary_name(Name, Prefix, Result) :-
	name(Prefix, PrefixChars),
	name(Name, NameChars),
	append(PrefixChars, [0' |NameChars], ResultChars),
	atom_chars(Result, ResultChars).


/*  Given a predicate specification like
	fred(1, ?, ?, 2, 3, ?)
    and a head template like    
	fred(A, B, C, D, E, F)
    we start by forming the list
	[1-(A,1), ? - (B,2), ? - (C,3), 2-(D,4), 3-(E,5), ? -(F,6)]
    {checking as we go that the flags are integers or '?'}.
    Then we sort this list, producing
	[1-(A,1), 2-(D,4), 3-(E,5), ? - (B,2), ? - (C,3), ? - (F,6)]
    We then make the "real goal"
	'0 fred'(A, D, E, B, C, F)
    and the indices
	['2 fred'(D,A), '3 fred'(E,A)].
    Note that a '1 fred' is never generated.
*/

parse_index_specification(PredSpec, RealHead, Indices,
		PredHead, (Disjunction,RealHead)) :-
	nonvar(PredSpec),
	functor(PredSpec, PredName, Arity),
	atom(PredName),
	functor(PredHead, PredName, Arity),
	make_auxiliary_name(PredName, 0, RealName),
	functor(RealHead, RealName, Arity),
	collect_specification(Arity, PredSpec, PredHead, RawList, []),
	keysort(RawList, OrdList),
	flesh_out(OrdList, RealHead, 1),
	collect_indices(OrdList, PredName, Indices, Disjunction).


%   collect_specifications(+ArgsLeft, +PredSpec, +PredHead, RawList, RawList0) 
%   collects the specifications in Spec-(Var,Num) form.

collect_specification(0, _, _, RawList, RawList) :- !.
collect_specification(N, PredSpec, PredHead, RawList, RawList0) :-
	arg(N, PredSpec, Spec),
	(   integer(Spec) -> true ; Spec == ?   ),
	arg(N, PredHead, Var),
	M is N-1,
	collect_specification(M, PredSpec, PredHead,
		RawList, [Spec - (Var,N)|RawList0]).

flesh_out([], _, _).
flesh_out([_-(Var,_)|OrdList], RealHead, M) :-
	arg(M, RealHead, Var),
	N is M+1,
	flesh_out(OrdList, RealHead, N).


%   collect_indices(+OrdList, +PredName, -Indices, -Disjunction)

collect_indices([X-(Var,_)|Rest], PredName, Indices,
	(   nonvar(Var) -> true ; Disjunction   )) :-
	integer(X),
	collect_indices(Rest, Var, PredName, Indices, Disjunction).

collect_indices([X-(Var,N)|Rest], Key, PredName, [Index|Indices],
	(   nonvar(Var) -> Index ; Disjunction   )) :-
	integer(X),
	!,
	make_auxiliary_name(PredName, N, IndexName),
	Index =.. [IndexName,Var,Key],
	collect_indices(Rest, Key, PredName, Indices, Disjunction).
collect_indices(_, _, _, [], true).


%   We handle :-index declarations by means of term expansion.
%   Note that valid index declarations are rewritten to ordinary
%   clauses for the predicates in question, but invalid index
%   declarations are not reported here, instead they are
%   rewritten to commands to print the error message.

index_expansion(:-(index(PredSpec)),
		:-(PredHead,PredBody)) :-
	parse_index_specification(PredSpec,
		RealGoal, Indices, PredHead, PredBody),
	!,
	Module = user,		% this is NOT right yet.
	assert(indexed(PredHead, Module, RealGoal, Indices)).
index_expansion(:-(index(PredSpec)),
		:-(format(user_error,
			'~N! Invalid index specification~n! Goal: ~q~n',
			[index(PredSpec)]))).


:- initialization add_linking_clause(index_expansion, term_expansion, 2).
:- initialization add_linking_clause(expand_indexed_rule, term_expansion, 2).


