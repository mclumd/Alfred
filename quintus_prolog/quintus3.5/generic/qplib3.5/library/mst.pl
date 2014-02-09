%   Package: mst
%   Author : Richard A. O'Keefe
%   Updated: 02 Nov 1988
%   Purpose: Find minimum spanning trees.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  mst(+Nodes:list(T), +Cost:void(T,T,number), -Root:T, -MST:list(pair(T,T)))

    is given a list of nodes (any ground term may serve as a node label)
    and a cost function: Cost(X,Y,C) -> the cost of the arc X->Y is C
    which is assumed to be non-negative and returns in MST a list of
    arcs From-To which constitute a minimum spanning tree for the graph.
    These arcs run from children to parents, so for every Node except the
    Root there is precisely one Node-Parent arc in MST and there is no
    Root-_ arc in MST.

    Note that no explicit representation of the graph is used: every
    node is notionally linked to every other node, and the cost of
    arcs that aren't really there is just infinity.  As a hack, I rely
    on the fact that N @< infinity for any number N, and allow the
    cost function to fail when infinity is meant.

    This file will be included in library(graphs) when it has been more
    thoroughly tested.  Then there will also be a version which takes a
    list of cost triples rather than a predicate.  This is a preliminary
    version (which is why it is not in a module).

    Important note: mst/4 has been carefully written so that it will find
    all the minimal spanning trees of a graph.  There can be rather a lot
    of them, especially as it is blind to redundant representations of
    isomorphic trees.  If you will be satisfied with any MST at all, use
    first_mst/4 instead.  Basically, first_mst will try to keep the arcs
    in the same order as the nodes if at all possible.
*/

:- module(mst, [
	first_mst/4,
	mst/4
   ]).

:- meta_predicate
	first_mst(+, 3, -, -),
	mst(+, 3, -, -),
	    initial_costs(+, +, 3, +, -),
		cost(3, +, +, -),
	    rest_mst(+, 3, -),
		update_costs(+, +, 3, -).

:- use_module(library(basics), [
	member/2
   ]),
   use_module(library(call), [
	call/4
   ]),
   use_module(library(sets), [
	select/3
   ]).


sccs_id('"@(#)88/11/02 mst.pl	27.4"').


%   first_mst(+Nodes, +Cost, -Root, -MST)
%   is given a set of Nodes and a Cost function (to find the cost C of
%   the edge from X to Y we call(Cost,X,Y,C) -- if this fails the cost
%   is infinity) and returns a minimum cost spanning tree and its Root.
%   It finds just one MST.

first_mst(Nodes, Cost, Root, MST) :-
	mst(Nodes, Cost, R, M),
	!,
	Root = R, MST = M.

%   mst(+Nodes, +Cost, -Root, -MST)
%   is given a set of Nodes and a Cost function (to find the cost C of
%   the edge from X to Y we call(Cost,X,Y,C) -- if this fails the cost
%   is infinity) and returns a minimum cost spanning tree and its Root.
%   It enumerates all the MSTs of the graph.

mst(Nodes, Cost, Root, MST) :-
	select(Root, Nodes, Rest),
	initial_costs(Rest, Root, Cost, [], Triples),
	rest_mst(Triples, Cost, MST).

rest_mst([], _, []).
rest_mst([Triple|Triples], Cost, [From-To|MST]) :-
	minimal_triples(Triples, Triple, [Triple], Minima),
	member(@(From,To,_), Minima),
	update_costs([Triple|Triples], From, Cost, UpdatedTriples),
	rest_mst(UpdatedTriples, Cost, MST).


%.  initial_costs(+Nodes, +Root, +Cost, +Acc, -Triples)
%   builds a list of @(Node,Root,Dist) triples in Triples.  This is
%   in the opposite order to Nodes, so that minimal_triples will come
%   out in the same order as Nodes.

initial_costs([], _, _, Triples, Triples).
initial_costs([Node|Nodes], Root, Cost, Acc, Triples) :-
	cost(Cost, Node, Root, Dist),
	initial_costs(Nodes, Root, Cost, [@(Node,Root,Dist)|Acc], Triples).


%.  cost(+Cost, +From, +To, -Dist)
%   applies the cost function Dist=Cost(From,To).  It is made symmetric,
%   so the user-supplied cost function needn't bother to calculate the
%   cost in both directions nor of self-links.  If Cost() fails both
%   ways around, it is assumed that this means no link (infinite cost).

cost(_, Node, Node, 0) :- !.
cost(Cost, From, To, Dist) :-
	call(Cost, From, To, Dist),
	!.
cost(Cost, From, To, Dist) :-
	call(Cost, To, From, Dist),
	!.
cost(_, _, _, infinity).


%.  minimal_triples(+Triples, -Minima)
%   is given a list of @(From,To,Dist) triples, and returns in Minima
%   a set of triples having a common Dist value, which value is the
%   least Dist in Triples.  Triples and Minima are in reverse order,
%   and we want to search Minima in the same order that we search the
%   Node list initially, so we build the initial costs in the opposite
%   order to the Node list.  We don't actually call this procedure
%   directly in rest_mst.

minimal_triples([Triple|Triples], Minima) :-
	minimal_triples(Triples, Triple, [Triple], Minima).

minimal_triples([], _, Minima, Minima).
minimal_triples([Triple|Triples], Elt, Set, Minima) :-
	compare_triples(R, Triple, Elt),
	minimal_triples(R, Elt, Set, Minima, Triple, Triples).

compare_triples(R, @(_,_,X), @(_,_,Y)) :-
	compare(R, X, Y).

minimal_triples(>, Elt, Set, Minima, _, Triples) :-
	minimal_triples(Triples, Elt, Set, Minima).
minimal_triples(<, _, _, Minima, Triple, Triples) :-
	minimal_triples(Triples, Triple, [Triple], Minima).
minimal_triples(=, Elt, Set, Minima, Triple, Triples) :-
	minimal_triples(Triples, Elt, [Triple|Set], Minima).

%.  update_costs(+Triples, +From, +Cost, -Updated)
%   maps each @(F,T,D) triple in Triples to
%	@(F,T,D) if D =< cost(F->From)
%	@(F,From,D) if D > cost(F->From)
%	nothing if F=From

update_costs([], _, _, []).
update_costs([@(From,_,_)|Triples], From, Cost, Updated) :- !,
	update_costs(Triples, From, Cost, Updated).
update_costs([@(Node,_,Old)|Triples], From, Cost, [@(Node,From,New)|Updated]) :-
	cost(Cost, Node, From, New),
	New @< Old,
	!,
	update_costs(Triples, From, Cost, Updated).
update_costs([Triple|Triples], From, Cost, [Triple|Updated]) :-
	update_costs(Triples, From, Cost, Updated).


end_of_file.

%   TEST CODE

test(L) :-
	expand(L, 1, [H|T]),
	minimal_triples(T, H, [H], M),
	write(M), nl.

expand([], _, []).
expand([H|T], M, [@(M,M,H)|X]) :-
	N is M+1,
	expand(T, N, X).

cost(a, b, 1).
cost(b, c, 1).
cost(b, d, 1).
cost(c, d, 1).

call(_, X, Y, D) :-
	cost(X, Y, D).

test :-
	mst([a,b,c,d], cost, Root, MST),
	write(Root/MST), nl.

