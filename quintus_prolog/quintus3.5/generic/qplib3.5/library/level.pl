%   Package: level
%   Author : Richard A. O'Keefe
%   Updated: 02 Nov 1988
%   Purpose: Take horizontal slices through a tree

%   Copyright (C) 1988 Quintus Computer Systems, Inc.  All rights reserved.

:- module(level, [
	tree_level/3,
	tree_level_labels/3,
	term_level/3,
	term_level_labels/3
   ]).


sccs_id('"@(#)88/11/02 level.pl	27.2"').


/*  tree_level(+Level, +Tree, ?List)
    is given a level number (a non-negative number) and a tree
    (which is a pair Label/[Son1,...,SonN], the sons being trees)
    and returns all the sub-trees at a particular level.

    library(pptree) uses a similar but defaulty data structure, which
    Edward P.  Stabler defined for a parser.  What makes it defaulty
    is that he represented terminals by themselves, rather than the
    word(X)/[] trees which appear below.  To get this defaulty version,
    restore the second (commented out) clause of level//2.
*/

tree_level(Level, Tree, List) :-
	integer(Level),
	tree_level(Level, Tree, List, []).

tree_level(0, SubTree) --> !, [SubTree].
tree_level(N, _/Sons) -->
	{ M is N-1, M >= 0 },
	tree_level1(Sons, M).

tree_level1([], _) --> [].
tree_level1([Tree|Trees], M) -->
	tree_level(M, Tree),
	tree_level1(Trees, M).



/*  tree_level_labels(+Level, +Tree, ?List)
    is given a level number (a non-negative number) and a tree
    (which is a pair Label/[Son1,...,SonN], the sons being trees)
    and returns all the labels of the subtrees at a particular level.
*/

tree_level_labels(Level, Tree, List) :-
	integer(Level),
	tree_level_labels(Level, Tree, List, []).

tree_level_labels(0, Label/_) --> !, [Label].
/* tree_level_labels(0, Label) --> !, [Label].	% For Ed Stabler */
tree_level_labels(N, _/Sons) -->
	{ M is N-1, M >= 0 },
	tree_level_labels1(Sons, M).

tree_level_labels1([], _) --> [].
tree_level_labels1([Tree|Trees], M) -->
	tree_level_labels(M, Tree),
	tree_level_labels1(Trees, M).



/*  term_level(+Level, +Term, ?List)
    is like tree_level/3 except that instead of a tree made out of
    Label/[Son1,...,SonN] nodes it is given a tree made out of
    Label(Son1,...,SonN) nodes.  This means that complex labels are
    not possible, only atomic ones.

    Note that this thing doesn't test for variables.  In some Prolog
    systems, functor/3 will fail if given too many variables, while in
    others it will report an error.  When you are using this correctly,
    the Term should be ground, so you shouldn't care which functor/3
    does.  But you SHOULD be entitled to rely on functor(2,2,0) being
    true so that numbers can appear in the tree without special treatment.
*/

term_level(Level, Term, List) :-
	integer(Level),
	term_level(Level, Term, List, []).

term_level(0, SubTree) --> !, [SubTree].
term_level(N, Term) -->
	{ M is N-1, M >= 0 },
	{ functor(Term, _, Arity) },
	term_level1(0, Arity, M, Term).

term_level1(N, N, _, _) --> !, [].
term_level1(I, N, M, Term) -->
	{ J is I+1 },
	{ arg(J, Term, Son) },
	term_level(M, Son),
	term_level1(J, N, M, Term).



/*  term_level_labels(+Level, +Term, ?List)
    is like tree_level_labels/3 except that instead of a tree made out of
    Label/[Son1,...,SonN] nodes it is given a tree made out of
    Label(Son1,...,SonN) nodes.  This means that complex labels are
    not possible, only atomic ones.
*/

term_level_labels(Level, Term, List) :-
	integer(Level),
	term_level_labels(Level, Term, List, []).

term_level_labels(0, Term) --> !,
	{ functor(Term, Label, _) }, [Label].
term_level_labels(N, Term) -->
	{ M is N-1, M >= 0 },
	{ functor(Term, _, Arity) },
	term_level_labels1(0, Arity, M, Term).

term_level_labels1(N, N, _, _) --> !, [].
term_level_labels1(I, N, M, Term) -->
	{ J is I+1 },
	{ arg(J, Term, Son) },
	term_level_labels(M, Son),
	term_level_labels1(J, N, M, Term).

end_of_file.

tree_test(Level, List) :-
	Tree =
	s/[
	    np/[
		det/[
		    word(a)/[]],
		n(singular)/[
		    word(man)/[]],
		sbar/[
		    comp/[
			np(A)/[
			    n(singular)/[
				word(who)/[]]]],
		    s/[
			np/[
			    det/[
				word(a)/[]],
			    n(singular)/[
				word(woman)/[]],
			    sbar([])/[]],
			vp/[
			    v(singular)/[
				word(like)/[]],
			    np/[
				np_trace(A)/[]]],
			adjunct/[]]]],
	    vp/[
		v(singular)/[
		    word(read)/[]],
		np/[
		    det/[
			word(a)/[]],
		    n(singular)/[
			word(book)/[]],
		    sbar([])/[]]],
	    adjunct/[]],
	tree_level_labels(Level, Tree, List).

term_test(Level, List) :-
	Term =
	s(
	    np(
		det(
		    word(a)),
		n(singular,
		    word(man)),
		sbar(
		    comp(
			np('*1',
			    n(singular,
				word(who)))),
		    s(
			np(
			    det(
				word(a)),
			    n(singular,
				word(woman)),
			    sbar),
			vp(
			    v(singular,
				word(like)),
			    np(
				np_trace('*1'))),
			adjunct))),
	    vp(
		v(singular,
		    word(read)),
		np(
		    det(
			word(a)),
		    n(singular,
			word(book)),
		    sbar)),
	    adjunct),
	term_level_labels(Level, Term, List).

/* tree_test/2 has solutions

    tree_test(0, [s]).
    tree_test(1, [np,vp,adjunct]).
    tree_test(2, [det,n(singular),sbar,v(singular),np]).
    tree_test(3, [word(a),word(man),comp,s,word(read),det,n(singular),sbar([])]).
    tree_test(4, [np(A),np,vp,adjunct,word(a),word(book)]).
    tree_test(5, [n(singular),det,n(singular),sbar([]),v(singular),np]).
    tree_test(6, [word(who),word(a),word(woman),word(like),np_trace(A)]).

    tree_test(N, []) for any integer N > 6;
    tree_test(N, L) fails for any other N.

   term_test/2 has solutions

    term_test(0, [s]).
    term_test(1, [np,vp,adjunct]).
    term_test(2, [det,n,sbar,v,np]).
    term_test(3, [word,singular,word,comp,s,singular,word,det,n,sbar]).
    term_test(4, [a,man,np,np,vp,adjunct,read,word,singular,word]).
    term_test(5, ['*1',n,det,n,sbar,v,np,a,book]).
    term_test(6, [singular,word,word,singular,word,singular,word,np_trace]).
    term_test(7, [who,a,woman,like,'*1']).

    term_test(N, []) for any integer N > 7;
    term_test(N, L) fails for any other N.
*/
