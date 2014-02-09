%  SCCS   : @(#)word_obj.pl	20.5 11/17/94
%  File   : word_obj.pl
%  Authors: Bruce Smith
%  Purpose: class definitions for use in WORDS searches
%  Origin : 15 Sep 94
%
%   Copyright (C) 1994, Quintus Computer Systems, Inc.  All rights reserved.
%
% This file defines the classes used in searching the graph built from
% the WORDS database.  Only the 'obj_bfs' search actually uses the graph
% to search, but the find_path/3 predicate uses component labeling of the
% graph to avoid searching in cases where there is no path.

% This file uses the Quintus Objects package:

:- load_files(library(obj_decl), [when(compile_time), if(changed)]).
:- use_module(library(objects)).

% Class: node
%
% The node class is adequate for building a graph of atom-labeled nodes,
% where each node has an adjacency list of neighboring nodes.

:- class node = [
		  public name: atom,
		  public nbrs: term = []
		].

Self <- create(Word) :-		% any node must be given its name
	Self << name(Word).	% at creation time

:- end_class node.

% Class: bfs
%
% This is a mixin class for use with node.  It adds a "visited" slot and
% a back pointer slot (which can be any descendant of node).

:- class bfs = [
		public vstd: integer = 0,
		public back: node
		].

Self <- reset_vstd :-		% mark the node as unvisited, again
	Self << vstd(0).

Self <- visited :-		% has the node been visited?
	Self >> vstd(1).

Self <- visit(Back) :-		% mark the node as visited and give
	Self << vstd(1),	% it a back pointer to another node
	Self << back(Back).

Self <- trace_back(Name, Back) :-	% follow back pointer path,
	Self >> name(Name),		% getting names of nodes on
	Self >> back(Back).		% the way

:- end_class bfs.

% Class: word_node
%
% This class combines 'node' and 'bfs', adding an integer valued slot for
% holding graph component label.

:- class word_node = [public comp: integer = 0] + node + bfs.

:- end_class word_node.

% The rest of the file is for initializing the search graph and ensuring
% that needed items are in the Prolog database.

:- ensure_loaded([word_sgb, library(basics)]).

:- dynamic word_obj/2.	% word_obj(Word, ListOfNeighbors).
:- dynamic all_objs/1.	% all_objs(ListOfAllWordObjects).

% graph_setup
%
% Do all the initialization stuff.

graph_setup :-
	format("~nInitializing graph for WORDS searching.~n~n", []),
	build_nodes,
	find_links,
	save_objs,
	label_all_comp.

% build_nodes
%
% Build a node for each word, and assert a word_obj/2 fact to let us find
% it, again.

build_nodes :-
	words(Word, _),
	create(word_node(Word), Wobj),
	assert(word_obj(Word, Wobj)),
	fail.
build_nodes.

% find_links
%
% For each words/2 fact, put a list of neighboring words' objects into
% the word's nbrs slot.

find_links :-
	words(W, Ws),
	word_obj(W, O),
	words_to_objs(Ws, Os),
	O << nbrs(Os),
	fail.
find_links.

% words_to_objs(+Words, -Objs)
%
% Objs is the list of objects associated with Objs for each member of
% Words, according to the word_obj/2 relation.

words_to_objs([], []).
words_to_objs([W|Ws],[O|Os]) :-
	word_obj(W,O),
	words_to_objs(Ws, Os).

% reset_vstd
%
% Fetch the list of all word_node objects and reset the visited slot of
% each.

reset_vstd :-
	all_objs(OL),
	reset_vstd(OL).

reset_vstd([]).
reset_vstd([O|Os]) :-
	O <- reset_vstd,
	reset_vstd(Os).

% save_objs
%
% To avoid doing a bagof or repeat-fail loop to reset visited slots, make
% a list of all word_node objects and store in the Prolog database.

save_objs :-
 	bagof(O, W^word_obj(W, O), OL),
	assert(all_objs(OL)).

% label_all_comp
%
% Label graph components via a very simple depth-first search.

label_all_comp :-
	all_objs(OL),
	label_all_comp(OL, 1).

label_all_comp([], _).
label_all_comp([O|Os], I0) :-
	( O >> comp(0) ->
		O << comp(I0),
		O >> nbrs(OL),
		label_comp(OL, I0),
		I1 is I0 + 1
	; I1 = I0
	),
	label_all_comp(Os, I1).

label_comp([], _).
label_comp([O|Os], I) :-
	( O >> comp(0) ->
		O << comp(I),
		O >> nbrs(OL),
		label_comp(OL, I)
	; true
	),
	label_comp(Os, I).

% end of words_obj.pl
