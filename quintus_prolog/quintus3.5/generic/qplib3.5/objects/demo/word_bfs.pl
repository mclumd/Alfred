%  SCCS   : @(#)word_bfs.pl	20.8 11/17/94
%  File   : word_bfs.pl
%  Authors: Bruce Smith
%  Purpose: comparison of search with and without Objects
%  Origin : 15 Sep 94
%
%   Copyright (C) 1994, Quintus Computer Systems, Inc.  All rights reserved.
%
% The programs in this file compare searching in a graph with and without
% the Quintus Objects package.  Sample data in the file word_sgb.pl is
% derived from the Stanford GraphBase, but none of these files is part of
% the Stanford GraphBase.
% 
% Three techniques are contrasted:
% 
% 	dfs	standard Prolog depth-first search
% 	std_bfs	standard Prolog breadth-first search
% 	obj_bfs	Prolog breadth-first search using Quintus Objects
% 
% All three searches find "word ladders".  You specify a pair of 5-letter
% words, in the database.  The solution is an sequence of 5-letter words,
% where consecutive words differ by one letter.  Both bfs searches find a
% path that is as short as possible.
% 
% Sample goals are
% 
% 	?- find_path(dfs, flour, bread).
% 	?- find_path(std_bfs, flour, bread).
% 	?- find_path(obj_bfs, flour, bread).
% 	?- find_path(flour, bread)	%% equiv to asking for obj_bfs
% 
% Other pairs to experiment with:
% 
% 	amigo, signs	-- the greatest distance in the graph
% 	grain, flour
% 	chaos, order
%	loves, hates
%
% For a review of search techniques in Prolog, see chapter 2 of either
% of the following:
%
%    Artificial Intelligence Techniques in Prolog,
%    Yohav Shoham, Morgan Kaufman Publishers, Inc.
%    1994.
%
%    The Craft of Prolog,
%    Richard O'Keefe, The MIT Press, 1990.
%
% The standard bfs program is loosely based on the breadth-first search
% program on p. 28 of Shoham's book.
%
% None of these search programs is the best nor fastest possible.  They
% were written to contrast programming techniques with and without the
% Quintus Objects package.

% This file uses the Quintus Objects package:

:- load_files(library(obj_decl), [when(compile_time), if(changed)]).
:- use_module(library(objects)).

% It also uses the following:

:- ensure_loaded([
		word_sgb,		% WORDS database derived from SGB
		word_obj,		% class def and initialization
		library(basics),	% for member/2
		library(lists)		% for reverse/2
		]).

% Set up the WORDS graph and label components.

:- initialization(graph_setup).		% defined in word_obj.pl

% find_path(+FromWord, +ToWord)
% find_path(+Method, +FromWord, +ToWord)
%
% Find a path from FromWord to ToWord, in the WORDS database.  Perform
% the search by the indicated Method, if specified.  If there's no path,
% print a rather minimal error message.

find_path(FromWord, ToWord) :-
	find_path(obj_bfs, FromWord, ToWord).

find_path(Method, FromWord, ToWord) :-
	( words_okay(FromWord, ToWord) ->
		find_path(Method, FromWord, ToWord, Path),
		show_path(Path)
	; no_solution(FromWord, ToWord) 
	).

find_path(dfs,	FromWord, ToWord, Path) :-
	dfs(FromWord, ToWord, Path).
find_path(std_bfs, FromWord, ToWord, Path) :-
	std_bfs(FromWord, ToWord, Path).
find_path(obj_bfs, FromWord, ToWord, Path) :-
	obj_bfs(FromWord, ToWord, Path).

% words_okay(+Word1, +Word2)
%
% Are the words okay?  That is, both atoms in the WORDS database and in
% the same component.

words_okay(Word1, Word2) :-
	atom(Word1),
	atom(Word2),
	word_obj(Word1, Obj1),
	word_obj(Word2, Obj2),
	Obj1 >> comp(C),
	Obj2 >> comp(C).

% no_solution(+Word1, +Word2)
%
% If there is no solution because of a problem in Word1 or Word2, print a
% rather minimal error message.

no_solution(Word1, Word2) :-
	\+ (atom(Word1), atom(Word2)),
	!,
	format("No solution: both words must be atoms~n", []).
no_solution(Word1, _) :-
	\+ word_obj(Word1, _),
	!,
	format("No solution: ~w not in WORDS database~n", [Word1]).
no_solution(_, Word2) :-
	\+ word_obj(Word2, _),
	!,
	format("No solution: ~w not in WORDS database~n", [Word2]).
no_solution(Word1, Word2) :-
	format("No solution: ~w and ~w in different components~n",
		[Word1, Word2]).
	
% show_path(+ListOfWords)
%
%
% Print a numbered listing of ListOfWords, one per line, starting with
% number 0.

show_path(Ws) :-
	show_path(Ws, 0).

show_path([], _) :- nl.
show_path([W|Ws], I0) :-
	format("~n~t~d~5|: ~a", [I0, W]),
	I1 is I0 + 1,
	show_path(Ws, I1).

%
% dfs -- Depth-First Search, not using Objects
%

% dfs(+Start, +Goal, -Solution)
%
% Just here for comparison of dfs vs. bfs.  For this problem, dfs tends
% to find a very bad solution fairly quickly.  However, in some cases
% this is also very slow.

dfs(Start, Goal, Solution) :-
	dfs(Start, Goal, [Start], Path),
	reverse(Path, Solution).

dfs(Goal, Goal, Path, Path).
dfs(Word0, Goal, Path0, Path) :-
	words(Word0, Nbrs),
	member(Word1, Nbrs),
	\+ member(Word1, Path0),
	dfs(Word1, Goal, [Word1|Path0], Path).

%
% std_bfs -- Breadth-First Search, not using Objects
%

% std_bfs(+Start, +Goal, -Solution)
%
% Find a shortest Solution path from Start, to Goal.

std_bfs(Start, Goal, Solution) :-
	std_bfs([[Start]|Tail], Tail, [], Goal, Solution).

% std_bfs(+OPEN, +Tail, +CLOSED, +Goal, -Solution)
%
% This is a fairly standard bfs, written in Prolog.  The OPEN list
% consists of paths, not nodes.  Expanding a path means finding all paths
% that go one step further.  The OPEN list is a difference list, the
% CLOSED list is a proper list.

std_bfs(OPEN, Tail, _, _, _) :-
	OPEN == Tail,
	!,
	fail.
std_bfs([[Goal|Path]|_], _, _, Goal, Solution) :-
	reverse([Goal|Path], Solution).
std_bfs([[Node|Path]|MoreOPEN], Tail0, CLOSED, Goal, Solution) :-
	words(Node, Nbrs),
	new_open(Nbrs, CLOSED, [[Node|Path]|MoreOPEN], Tail0, Tail1),
	std_bfs(MoreOPEN, Tail1, [Node|CLOSED], Goal, Solution).

% new_open(+Nbrs, CLOSED, +OPEN, +Tail0, -Tail)
%
% Given a set of nodes (the neighbors of the node at the end of a path in
% the OPEN list) add those which appear in neither OPEN nor CLOSED lists
% to the end of the OPEN list.

new_open([], _, _, Tail, Tail).
new_open([Next|Nbrs], CLOSED, [[Node|Path]|MoreOPEN], Tail0, Tail) :-
	\+ dlmember([Next|_], MoreOPEN, Tail0),
	\+ member(Next, CLOSED),
	!,
	Tail0 = [[Next, Node|Path]|Tail1],
	new_open(Nbrs, CLOSED, [[Node|Path]|MoreOPEN], Tail1, Tail).
new_open([_|Nbrs], CLOSED, OPEN, Tail0, Tail) :-
	new_open(Nbrs, CLOSED, OPEN, Tail0, Tail).

% dlmember(Element, Head, Tail)
%
% Is Element a member of the difference list Head\Tail.  Fairly standard
% difference list program.

dlmember(_, Head, Tail) :-
	Head == Tail,
	!,
	fail.
dlmember(X, [X|_], _).
dlmember(X, [_|Y], Tail) :-
	dlmember(X, Y, Tail).

%
% obj_bfs -- Breadth-First Search, using Objects
%

% obj_bfs(+FromWord, +ToWord, -Solution)
%
% Perform a breadth first search to find a shortest path from FromWord to
% ToWord, using the node objects.  Find the objects for each word, mark
% the FromObj as visited, use obj_bfs_1/3 to search, build the solution
% shortest path using collect_path/3.

obj_bfs(FromWord, ToWord, Solution) :-
	reset_vstd,
	word_obj(FromWord, FromObj),
	word_obj(ToWord, ToObj),
	FromObj <- visit(FromObj),
	obj_bfs_1([FromObj|Tail], Tail, ToObj),
	collect_path(ToObj, FromObj, Solution).

% obj_bfs_1(+OPEN, +Tail, +Goal)
%
% Perform a breadth-first search to the node Goal, starting with the open
% list, given as the difference list OPEN/Tail.  Rather than keeping a
% CLOSED list, mark nodes as visited.  Rather than building paths during
% the search, assign each node a "back pointer" as it is visited.

obj_bfs_1(OPEN, Tail, _) :-
	OPEN == Tail,
	!,
	fail.
obj_bfs_1([Node|MoreOPEN], Tail0, Goal) :-
	( Node = Goal ->
		true
	; Node >> nbrs(Nbrs),
	  new_open(Nbrs, Node, Tail0, Tail1),
	  obj_bfs_1(MoreOPEN, Tail1, Goal)
	).

% new_open(+Nodes, +OPEN, +Tail0, -Tail)
%
% Given a list NODES and an open list, as the difference list OPEN\Tail0,
% add the "new" nodes-- those which have not been visited-- in the list
% to the end of the open list.

new_open([], _, Tail, Tail).
new_open([Next|Nbrs], Node, Tail0, Tail) :-
	( Next <- visited ->
		new_open(Nbrs, Node, Tail0, Tail)
	; Next <- visit(Node),
	  Tail0 = [Next|Tail1],
	  new_open(Nbrs, Node, Tail1, Tail)
	).

% collect_path(+Goal, +Start, -Path)
%
% After a obj_bfs search is completed, follow backpointers from the Goal
% node to the Start node, collecting the names of the nodes on the path
% into Path.

collect_path(Goal, Start, Path) :-
	collect_path(Goal, Start, [], Path).

collect_path(Start, Start, Path, [StartWord|Path]) :-
	!,
	Start >> name(StartWord).
collect_path(Node0, Start, Path0, Path) :-
	Node0 <- trace_back(Word0, Node1),
	collect_path(Node1, Start, [Word0|Path0], Path).

% end of word_bfs.pl
