/*  SCCS   : @(#)indexing.pl	1.5 01/19/94
    File   : indexing.pl
    Authors: Peter Schachte
    Purpose: Examples to help you understand indexing and determinacy
    Origin : 10 May 90

    Copyright (C) 1990, Quintus Corporation.  All rights reserved.
*/

%  Indexing Tutorial
%
%  This tutorial uses the Quintus Source-Linked Debugger to illustrate
%  how clause indexing works in Quintus Prolog.  To use the tutorial,
%  just read the comments near where the debugger arrow points, and
%  then hit the 'Creep' button in the debugger when you're ready to
%  proceed.  You don't really need to understand all the features of
%  the debugger to use this tutorial.

indexing_tutorial :-		% hit 'creep' now
	example1,		% hit 'creep' now
	example2,		% hit 'creep' now
	example3,		% hit 'creep' now
	example4,		% hit 'creep' now
	example5.		% hit 'creep' now
	



example1 :-		% simple indexing
	%  First, let's see what simple indexing will do.
	%  Note in the following call that the head port
	%  arrow points right to the second clause of index1/1.
	%  This is because indexing tells Prolog that the first
	%  clause cannot match.  Now hit the 'creep' button.

	index1(b, _).		% hit 'creep' now

index1(a, 1).	% never even try this clause
index1(b, 2).	% come right to this clause


% ================================================================

example2 :-		% indexing only on first arg
	%  Quintus Prolog indexes only on the first argument of
	%  a predicate, so if we rearrange the order of the
	%  arguments of the last example, we don't get indexing.
	
	index2(_, b),		% hit 'creep' now

	%  This is an important point:  it's always a good idea
	%  to put an argument that will usually be bound in a call
	%  as the first argument, if that argument will let you
	%  choose between clauses.  Note that in this case, if
	%  we instead called

	index2(2, _).		% hit 'creep' now

	% we would get indexing, because the first argument is
	% bound.


index2(1, a).	% with first argument unbound, come here first
index2(2, b).	% but that clause is wrong, so we come here


% ================================================================

example3 :-		% no indexing on subterms
	%  Quintus Prolog also does not index on subterms of a
	%  term, but only on its principal functor.  Note that
	%  in this example, we DON'T go right to the right
	%  clause.

	index3(a(2)),		% hit 'creep' now

	%  However, Quintus Prolog does destinguish between
	%  terms based on arity.  In this test, we do skip over
	%  the clause for b(1), as well as the clauses for a,
	%  and go right to the clause for b(1,1).

	index3(b(1,1)).		% hit 'creep' now

index3(a(1)).	% come here first, but this clause doesn't match
index3(a(2)).	% then come here
index3(b(1)).	% indexing can tell b/1
index3(b(1,1)).	% from b/2


% ================================================================

example4 :-		% multiple index matches
	%  Sometimes, multiple clauses will match, with nonmatching
	%  clauses between.  In this case, Quintus Prolog will
	%  skip over the intervening nonmatching clauses without
	%  trying them.  You can tell this by looking for the
	%  secondary clause arrow, which is smaller than the 
	%  usual head port arrow; this arrow points to the next
	%  clause to be tried.  Here the primary arrow points to
	%  the second clause, and the secondary points to the fifth.

	index4(b, _),		% 'creep' now

	%  to see that Prolog does go there next, hit creep again,
	%  and we'll backtrack, showing that we do indeed go right
	%  to the fifth clause, and then creep to the next example

	fail;
	true.


index4(a, 1).	% indexing rules out this clause
index4(b, 2).	% but this one matches
index4(c, 3).	% this one doesn't match
index4(d, 4).	% this one doesn't match
index4(b, 5).	% this one matches, too.


% ================================================================

example5 :-			% determinate and nondeterminate exit
	%  You may have noticed earlier that sometimes, the arrow
	%  shown when a goal completes has a forked tail, and sometimes
	%  a solid tail.  This shows whether the goal exited
	%  determinately or not:  a forked tail means the goal was
	%  nondeterminate.  If you don't expect your code to
	%  backtrack into a goal, you will usually want it to exit
	%  determinately.  If it doesn't, that may mean an error
	%  in your code, or at least an unnecessary performance
	%  penalty.  In this example, we actually get an unexpected
	%  result.  The idea here is that if we pass in true or
	%  false, we want to get back a 1 or 0, if we pass in anything
	%  else, we want to get the atom 'bad'.

	index5(true, X),	% hit 'creep' now
	
	%  Looks good so far; X is bound to 1.  But notice that the
	%  exit arrow has a forked tail.  We would have expected
	%  a solid tail, because there should only be one result.
	%  When we backtrack into this goal, we get a wrong answer:
	%  X gets bound to 'bad'.

	fail;
	
	%  But by putting a cut in each clause but the last we avoid
	%  this problem.  The cut says to ignore any other clauses
	%  for the predicate, so the last clause no longer applies.

	index5a(true, X).	% hit 'creep' now
	
	%  This goal exits with a solid arrow, indicating that there
	%  was only the one correct solution.



index5(true, 1).
index5(false, 0).
index5(_, bad).
	
index5a(true, 1) :- !.
index5a(false, 0) :- !.
index5a(_, bad).




:- initialization
	nl,
	write('To run this tutorial, type "indexing." at the Prolog prompt.'),
	nl,
	write('When the debugger window appears, hit the ''Creep'' button'),
	nl,
	write('and then follow the directions in the debugger window'),
	nl.

indexing :-
	trace,
	indexing_tutorial,
	notrace.
