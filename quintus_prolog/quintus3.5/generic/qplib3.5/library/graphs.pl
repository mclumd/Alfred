%   Package: graphs.pl
%   Author : Richard A. O'Keefe
%   Updated: 06/17/02
%   Defines: Graph-processing utilities.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This package is a collection of utilities for performing operations
    on (mathematical) graphs.  The collection is rather haphazard: I've
    added routines as I needed them.  Please tell us which operations
    you would have a use for.

    The P-representation of a graph is a list of (from-to) vertex
    pairs, where the pairs can be in any old order.  This form is
    convenient for input/output.

    The S-representation of a graph is a list of (vertex-neighbours)
    pairs, where the pairs are in standard order (as produced by
    keysort) and the neighbours of each vertex are also in standard
    order (as produced by sort).  This form is convenient for many
    calculations.

    p_to_s_graph(Pform, Sform) converts a P- to an S- representation.
    s_to_p_graph(Sform, Pform) converts an S- to a P- representation.

    warshall(Graph, Closure) takes the transitive closure of a graph
    in S-form.  (NB: this is not the reflexive transitive closure).

    s_to_p_trans(Sform, Pform) converts Sform to Pform, transposed.

    p_transpose transposes a graph in P-form, cost O(|E|).
    s_transpose transposes a graph in S-form, cost O(|V|^2).

    p_length(+G, -E) and
    s_length(+S, -E) return the number of edges, cost O(E).

    In 1988, the code for forests was added.

    reachable(Node, SGraph, ReachableFromNodeInGraph)
    unifies ReachableFromNodeInGraph with the (ord)set of nodes in
    SGraph which are reachable from Node.  SGraph is in Sform.
    There is no Pform version: the cheapest method would involve
    converting to Sform.
*/

:- module(graphs, [
	f_to_p_graph/2,			% new in 1988
	f_to_s_graph/2,			% new in 1988
	p_to_f_graph/2,			% new in 1988
	p_to_s_graph/2,
	s_to_f_graph/2,			% new in 1988
	s_to_p_graph/2,
	s_to_p_trans/2,
	p_length/2,			% new in 1988
	s_length/2,			% new in 1988
	p_member/3,
	s_member/3,
	p_transpose/2,
	s_transpose/2,
	compose/3,
	reachable/3,			% new in 1988
	top_sort/2,
	p_vertices/2,
	s_vertices/2,
	warshall/2
   ]).
:- use_module(library(ordsets), [
	ord_subtract/3,			% for reachable/3
	ord_union/3
   ]),
   use_module(library(basics), [
	member/2,
	memberchk/2
   ]).

:- mode
	s_vertices(+, ?),
	p_vertices(+, -),
	p_to_s_graph(+, -),
	    p_to_s_vertices(+, -),
	    p_to_s_group(+, +, -),
		p_to_s_group(+, +, -, -),
	s_to_p_graph(+, -),
	    s_to_p_graph(+, +, -, -),
	s_to_p_trans(+, -),
	    s_to_p_trans(+, +, -, -),
	p_member(?, ?, +),
	s_member(?, ?, +),
	p_transpose(+, -),
	s_transpose(+, -),
	    s_transpose(+, -, ?, -),
		transpose_s(+, +, +, -),
	compose(+, +, -),
	    compose(+, +, +, -),
		compose1(+, +, +, -),
		    compose1(+, +, +, +, +, +, +, -),
	top_sort(+, -),
	    vertices_and_zeros(+, -, ?),
	    count_edges(+, +, +, -),
		incr_list(+, +, +, -),
	    select_zeros(+, +, -),
	    top_sort(+, -, +, +, +),
		decr_list(+, +, +, -, +, -),
	warshall(+, -),
	    warshall(+, +, -),
		warshall(+, +, +, -).

sccs_id('"@(#)02/06/17 graphs.pl	76.1"').

/*  A common pattern in this file involves two lists of vertex names:
    Neibs is the list of neighbours of some node,
    Vertices is the complete list of all vertex names for a graph.

	p(Neibs, Vertices, ...)

    p([], _, ...).
    p([V|Ns], [V|Vs], ...) :- !,
	{case when V is an element of Neibs}
	p(Ns, Vs, ...).
    p(Ns, [V|Vs], ...) :-
	{case when V is not an element of Neibs}
	p(Ns, Vs, ...).

    This works because Neibs and Vertices are in standard order, with Neibs
    being a subset of Vertices.  So the last clause corresponds to the case
    Ns = [N|_], N @> V.
*/

%   s_vertices(+S_Graph,  ?Vertices)
%   strips off the neighbours lists of an S-representation to produce
%   a list of the vertices of the graph.  (It is a characteristic of
%   S-representations that *every* vertex appears, even if it has no
%   neighbours.)

s_vertices([], []).
s_vertices([Vertex-_Neighbours|Graph], [Vertex|Vertices]) :-
	s_vertices(Graph, Vertices).



%   p_vertices(+P_Graph, ?Vertices)
%   unifies Vertices with the set of non-isolated vertices of P_Graph
%   represented as a list in standard order.  It is a characteristic
%   of P-representation that a vertex only appears if it is attached
%   to some edge.

p_vertices(P_Graph, Vertices) :-
	p_vertices_1(P_Graph, Bag),
	sort(Bag, Vertices).

p_vertices_1([], []).
p_vertices_1([From-To|Edges], [From,To|Vertices]) :-
	p_vertices_1(Edges, Vertices).



%   p_to_s_graph(+P_Graph, ?S_Graph)
%   converts a graph from P-representation to S-representation.
%   If the graph has N nodes and E edges, the cost is O(ElgE).

p_to_s_graph(P_Graph, S_Graph) :-
	sort(P_Graph, EdgeSet),
	p_vertices(EdgeSet, VertexSet),
	p_to_s_group(VertexSet, EdgeSet, S_Graph).


p_to_s_group([], _, []).
p_to_s_group([Vertex|Vertices], EdgeSet, G0) :-
	p_to_s_group(EdgeSet, Vertex, G0, G1, RestEdges),
	p_to_s_group(Vertices, RestEdges, G1).

p_to_s_group([V-X|Edges], V, [V-[X|Neibs]|G], G, RestEdges) :- !,
	p_to_s_group(Edges, V, Neibs, RestEdges).
p_to_s_group(Edges, V, [V-[]|G], G, Edges).

p_to_s_group([V-X|Edges], V, [X|Neibs], RestEdges) :- !,
	p_to_s_group(Edges, V, Neibs, RestEdges).
p_to_s_group(Edges, _, [], Edges).



%   s_to_p_graph(+S_Graph, ?P_Graph)
%   converts a graph from S-representation to P-representation.
%   A unique choice is made: edges appear in standard order.
%   If the graph has N nodes and E edges, the cost is O(E).

s_to_p_graph([], []).
s_to_p_graph([Vertex-Neibs|G], P_Graph) :-
	s_to_p_graph(Neibs, Vertex, P_Graph, Rest_P_Graph),
	s_to_p_graph(G, Rest_P_Graph).


s_to_p_graph([], _, P_Graph, P_Graph).
s_to_p_graph([Neib|Neibs], Vertex, [Vertex-Neib|P], Rest_P) :-
	s_to_p_graph(Neibs, Vertex, P, Rest_P).



%   s_to_p_trans(+S_Graph, ?P_Graph)
%   converts the TRANSPOSE of a graph in S-representation to
%   P-representation, without actually building the transpose.
%   If the graph hasN nodes and E edges, the cost is O(E).
%   A unique representation is returned, but it has no useful
%   properties other than having no duplicates (it is not ordered).

s_to_p_trans([], []).
s_to_p_trans([Vertex-Neibs|G], P_Graph) :-
	s_to_p_trans(Neibs, Vertex, P_Graph, Rest_P_Graph),
	s_to_p_trans(G, Rest_P_Graph).


s_to_p_trans([], _, P_Graph, P_Graph).
s_to_p_trans([Neib|Neibs], Vertex, [Neib-Vertex|P], Rest_P) :-
	s_to_p_trans(Neibs, Vertex, P, Rest_P).



%   warshall(+Graph, ?Closure) computes Closure from graph in
%   O(N**3) time.  To obtain the transitive closure of a
%   graph in P-representation, convert it to S-representation.
%   The closure will be the dominant cost.  Note that there
%   can be a lot of graphs with a given closure, so it wouldn't
%   make much sense to call this with a variable as first
%   argument.

warshall(Graph, Closure) :-
	warshall(Graph, Graph, Closure).


warshall([], Closure, Closure).
warshall([V-_|G], E, Closure) :-
	memberchk(V-Y, E),	%  Y := E(v)
	warshall(E, V, Y, NewE),
	warshall(G, NewE, Closure).


warshall([], _, _, []).
warshall([X-Neibs|G], V, Y, [X-NewNeibs|NewG]) :-
	memberchk(V, Neibs),
	!,
	ord_union(Neibs, Y, NewNeibs),
	warshall(G, V, Y, NewG).
warshall([X-Neibs|G], V, Y, [X-Neibs|NewG]) :-
	warshall(G, V, Y, NewG).



%   p_transpose(?P_Graph, ?P_Trans)
%   computes the transpose of a graph in P-representation.
%   It can solve for either argument.  The cost is O(E).

p_transpose([], []).
p_transpose([From-To|Edges], [To-From|Transpose]) :-
	p_transpose(Edges, Transpose).



%   s_transpose(+S_Graph, ?S_Trans)
%   computes the transpose of a graph in S-representation.
%   It can only be used one way around.  The cost is O(N**2).

s_transpose(S_Graph, Transpose) :-
	s_transpose(S_Graph, Base, Base, Transpose).

s_transpose([], [], Base, Base).
s_transpose([Vertex-Neibs|Graph], [Vertex-[]|RestBase], Base, Transpose) :-
	s_transpose(Graph, RestBase, Base, SoFar),
	transpose_s(SoFar, Neibs, Vertex, Transpose).

transpose_s([], [], _, []).
transpose_s([Neib-Trans|SoFar], [Neib|Neibs], Vertex,
		[Neib-[Vertex|Trans]|Transpose]) :- !,
	transpose_s(SoFar, Neibs, Vertex, Transpose).
transpose_s([Head|SoFar], Neibs, Vertex, [Head|Transpose]) :-
	transpose_s(SoFar, Neibs, Vertex, Transpose).



%   p_length(+P_Graph, ?E)
%   is true when P_Graph is a graph in P form (which means that it must be
%   a proper list of _-_ pairs) and E is the number of edges in it.  This
%   costs O(E) time.

p_length(P_Graph, N) :-
	p_length(P_Graph, 0, N).

p_length(*, _, _) :- !, fail.		% catch & reject variables
p_length([], N, N).
p_length([_-_|P_Graph], N0, N) :-
	N1 is N0+1,
	p_length(P_Graph, N1, N).


%   s_length(+S_Graph, ?E)
%   is true when S_Graph is a graph in S form (which means that it must
%   be a proper list of F-T pairs, where each T must be a proper list),
%   and E is the number of edges in it.  This costs O(E) time.

s_length(S_Graph, N) :-
	s_length(S_Graph, 0, N).

s_length(*, _, _) :- !, fail.		% catch & reject variables
s_length([], N, N).
s_length([_-L|S_Graph], N0, N) :-
	sslength(L, N0, N1),
	s_length(S_Graph, N1, N).

sslength(*, _, _) :- !, fail.		% catch & reject variables
sslength([], N, N).
sslength([_|L], N0, N) :-
	N1 is N0+1,
	sslength(L, N1, N).



%   p_member(?X, ?Y, +P_Graph)
%   tests whether the edge (X,Y) occurs in the graph.  This always
%   costs O(|E|) time.  Here, as in all the operations in this file,
%   vertex labels are assumed to be ground terms, or at least to be
%   sufficiently instantiated that no two of them have a common instance.

p_member(X, Y, P_Graph) :-
	(   nonvar(X), nonvar(Y) ->
	    memberchk(X-Y, P_Graph)
	;   /* var X or var Y */
	    member(X-Y, P_Graph)
	).


%   s_member(?X, ?Y, +S_Graph)
%   tests whether the edge (X,Y) occurs in the graph.  If either
%   X or Y is instantiated, the check is order |V| rather than
%   order |E|.  The if-then-else tries to reduce nondeterminacy.

s_member(X, Y, S_Graph) :-
	(   nonvar(X) -> memberchk(X-Neibs, S_Graph)
	;   /* var(X) */ member(X-Neibs, S_Graph)
	),
	(   nonvar(Y) -> memberchk(Y, Neibs)
	;   /* var(Y) */ member(Y, Neibs)
	).



%   compose(+G1, +G2, ?Composition)
%   calculates the composition of two S-form graphs, which need not
%   have the same set of vertices.

compose(G1, G2, Composition) :-
	s_vertices(G1, V1),
	s_vertices(G2, V2),
	ord_union(V1, V2, V),
	compose(V, G1, G2, Composition).


compose([], _, _, []).
compose([Vertex|Vertices], [Vertex-Neibs|G1], G2,
	[Vertex-Comp|Composition]) :- !,
	compose1(Neibs, G2, [], Comp),
	compose(Vertices, G1, G2, Composition).
compose([Vertex|Vertices], G1, G2,
	[Vertex-[]|Composition]) :-
	compose(Vertices, G1, G2, Composition).


compose1([V1|Vs1], [V2-N2|G2], Comp0, Comp) :- !,
	compare(Rel, V1, V2),
	compose1(Rel, V1, Vs1, V2, N2, G2, Comp0, Comp).
compose1(_, _, Comp, Comp).


compose1(<, _, Vs1, V2, N2, G2, Comp0, Comp) :-
	compose1(Vs1, [V2-N2|G2], Comp0, Comp).
compose1(>, V1, Vs1, _, _, G2, Comp0, Comp) :-
	compose1([V1|Vs1], G2, Comp0, Comp).
compose1(=, V1, Vs1, V1, N2, G2, Comp0, Comp) :-
	ord_union(N2, Comp0, Comp1),
	compose1(Vs1, G2, Comp1, Comp).


%   top_sort(+Graph, ?Sorted)
%   finds a topological ordering of a Graph in S-representation
%   and returns the ordering as a list of Sorted vertices.  It
%   takes O(N**2) time [even just count_edges/4 takes that].  We
%   really ought to look for something better.

top_sort(Graph, Sorted) :-
	vertices_and_zeros(Graph, Vertices, Counts0),		% O(N)
	count_edges(Graph, Vertices, Counts0, Counts1),		% O(N**2)
	select_zeros(Counts1, Vertices, Zeros),			% O(N)
	top_sort(Zeros, Sorted, Graph, Vertices, Counts1).	% O(N**2)


vertices_and_zeros([], [], []).
vertices_and_zeros([Vertex-_Neibs|Graph], [Vertex|Vertices], [0|Zeros]) :-
	vertices_and_zeros(Graph, Vertices, Zeros).


%.  count_edges(+Graph, +Vertices, +Counts0, -Counts)
%   is given a list of Vertex-ListOfNeighbours pairs (Graph),
%   a list of all the Vertices in the graph,
%   and a table of Counts running parallel to Vertices (Counts0).
%   If   Vertices = [..., V, ...]
%   and  Counts0  = [..., M, ...]
%   and  Counts   = [..., N, ...]
%   then N-M is the number of edges Vertex->V in Graph.  The cost of this
%   is proportional to |Vertices|**2; if we had updatable arrays we could
%   reduce it to ||Graph||, but the two are usually comparable.

count_edges([], _, Counts, Counts).
count_edges([_Vertex-Neibs|Graph], Vertices, Counts0, Counts2) :-
	incr_list(Neibs, Vertices, Counts0, Counts1),
	count_edges(Graph, Vertices, Counts1, Counts2).


incr_list([], _, Counts, Counts) :- !.
incr_list([V|Neibs], [V|Vertices], [M|Counts0], [N|Counts1]) :- !,
	N is M+1,
	incr_list(Neibs, Vertices, Counts0, Counts1).
incr_list(Neibs, [_|Vertices], [N|Counts0], [N|Counts1]) :-
	incr_list(Neibs, Vertices, Counts0, Counts1).


%.  select_zeros(+Counts, +Vertices, -Zeros)
%   where Vertices and Counts are parallel lists of vertex names and counts,
%   returns a list of the vertext names corresponding to zero counts.

select_zeros([], [], []).
select_zeros([0|Counts], [Vertex|Vertices], [Vertex|Zeros]) :- !,
	select_zeros(Counts, Vertices, Zeros).
select_zeros([_|Counts], [_|Vertices], Zeros) :-
	select_zeros(Counts, Vertices, Zeros).



top_sort([], [], Graph, _, Counts) :-
	vertices_and_zeros(Graph, _, Counts).
top_sort([Zero|Zeros], [Zero|Sorted], Graph, Vertices, Counts1) :-
	memberchk(Zero-Neibs, Graph),
	decr_list(Neibs, Vertices, Counts1, Counts2, Zeros, NewZeros),
	top_sort(NewZeros, Sorted, Graph, Vertices, Counts2).


decr_list([], _, Counts, Counts, Zeros, Zeros) :- !.
decr_list([V|Neibs], [V|Vertices], [1|Counts1], [0|Counts2], Zi, Zo) :- !,
	decr_list(Neibs, Vertices, Counts1, Counts2, [V|Zi], Zo).
decr_list([V|Neibs], [V|Vertices], [N|Counts1], [M|Counts2], Zi, Zo) :- !,
	M is N-1,
	decr_list(Neibs, Vertices, Counts1, Counts2, Zi, Zo).
decr_list(Neibs, [_|Vertices], [N|Counts1], [N|Counts2], Zi, Zo) :-
	decr_list(Neibs, Vertices, Counts1, Counts2, Zi, Zo).


/*  The material concerning a representation of forests is
    Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.
    and is _not_ based on shared code written by this author.

    A forest is a graph which is a collection of trees (that is, no vertex
    in the graph has more than one parent, and there may be any number of
    vertices having no parent).

    The F-representation of a forest is a list of Root/Sons pairs with
    the roots in standard order, the Sons of each root being a forest.

    Example:
				a
				|
		+---------------+---------------+
		|				|						
		b				c
		|				|
	+-------+-------+		+-------+-------+
	|	|	|		|	|	|
	d       e	f		g	h	i
		|	|				|
		j	k				l

    P-representation:
	[a-b,a-c,b-d,b-e,b-f,c-g,c-h,c-i,e-j,f-k,i-l]
    S-representation:
	[a-[b,c],b-[d,e,f],c-[g,h,i],e-[j],f-[k],i-[l]]
    F-representation:
	[a/[b/[d/[],e/[j/[]],f/[k/[]]],c/[g/[],h/[],i/[l/[]]]]]

    The only operations on F-representation defined here are
    f_to_{p,s}_graph/2 and {p,s}_to_f_graph/2,
    but see library(pptree) for some routines to print them (particularly
    pp_term/1) and library(level) for extracting cross-sections.

    {p,s}_to_f_graph/2 check that their first argument represents a
    forest, so you can test
	\+ s_to_f_graph(S, _)		-- not a forest
	\+ s_to_f_graph(S, [_])		-- not a tree
    just as you can test
	\+ top_sort(S, _)		-- not acyclic
    Would it be useful to make these tests directly available?
*/


%   f_to_p_graph(+Forest, -P_graph)
%   converts a given Forest (or perhaps a single tree) to P-representation.
%   It takes O(N) time and space.

f_to_p_graph(Forest, Edges) :-
	f_to_p_graph(Forest, Edges, []).


%   f_to_p_graph/3 walks along the very top level of a forest, handling
%   only the nodes which have no parents.  _/_ is a single tree.

f_to_p_graph([], Edges, Edges).
f_to_p_graph(Node/Sons, Edges0, Edges) :-
	f_to_p_graph(Sons, Node, Edges0, Edges).
f_to_p_graph([Node/Sons|Fratres], Edges0, Edges) :-
	f_to_p_graph(Sons, Node, Edges0, Edges1),
	f_to_p_graph(Fratres, Edges1, Edges).


%   f_to_p_graph/4 walks over all of a tree except the root, collecting
%   edges.  Note that the special case for a tree does _not_ occur!

f_to_p_graph([], _, Edges, Edges).
f_to_p_graph([Node/Sons|Fratres], Parent, [Parent-Node|Edges1], Edges) :-
	f_to_p_graph(Sons, Node, Edges1, Edges2),
	f_to_p_graph(Fratres, Parent, Edges2, Edges).



%   f_to_s_graph(+Forest, -S_graph)
%   converts a given Forest (or perhaps a single tree) to S-representation.
%   It takes O(N.lgN) time and turns over that much space.
%   There are two things to watch out for:  the S-representation is sorted,
%   and it is not supposed to contain Node-[] pairs.

f_to_s_graph(Forest, Edges) :-
	f_to_s_graph(Forest, RawEdges, []),
	keysort(RawEdges, Edges).


%   f_to_s_graph/3 walks along the very top level of a forest, handling
%   only the nodes which have no parents.  _/_ is a single tree.

f_to_s_graph([], Edges, Edges).
f_to_s_graph(Node/Sons, [Node-Labels|Edges1], Edges) :-
	f_to_s_graph(Sons, Labels, Edges1, Edges).
f_to_s_graph([Node/Sons|Fratres], Edges0, Edges) :-
	f_to_s_graph(Sons, Node, Edges0, Edges1),
	f_to_s_graph(Fratres, Edges1, Edges).


%   f_to_s_graph/4 suppresses Node-[] pairs.

f_to_s_graph([], _, Edges, Edges).
f_to_s_graph([Son|Sons], Node, [Node-Labels|Edges1], Edges) :-
	f_to_s_graph_1([Son|Sons], Labels, Edges1, Edges).


%   f_to_s_graph_1/4 walks over all of a tree except the root, collecting
%   node labels for its parent and accumulating its own edges.

f_to_s_graph_1([], [], Edges, Edges).
f_to_s_graph_1([Node/Sons|Fratres], [Node|Nodes], Edges0, Edges) :-
	f_to_s_graph(Sons, Node, Edges0, Edges1),
	f_to_s_graph_1(Fratres, Nodes, Edges1, Edges).



/*  The tricky thing is converting a graph _to_ F-representation.
    It is most convenient to do this starting from S-representation,
    which is half-way there.

    What we do is build a map from "From" nodes to (From/Sons,Flag)
    triples, where Flag will be instantiated if From is a son of some
    node.  We read the top of the forest off this.
*/

%   s_to_f_graph(+S_graph, ?Forest)
%   converts a forest in S-representation to F-representation.
%   It fails if the first argument does not represent a forest.
%   This is enforced by 1.s_f_son/7 which won't let a child have
%   more than one parent.

s_to_f_graph(S_graph, Forest) :-
	s_to_map(S_graph, Map),
	s_f_fill(S_graph, Map),
	s_roots(Map, Forest, []).


%   s_roots(+Map, -L0, -L) reads off the Tree slots of the elements of Map
%   whose Flag slots can be unified with 'r' (root).  All the elements
%   which represent children have had their Flag set to 'c' (child).

s_roots(tip) --> [].
s_roots(map(_,Flag,Tree,Lmap,Rmap)) -->
	s_roots(Lmap),
	s_roots(Flag, Tree),
	s_roots(Rmap).

s_roots(r, Tree) --> !, [Tree].
s_roots(c, _)    --> [].


s_to_map(S_graph, Map) :-
	length(S_graph, N),
	s_to_map(N, Map, S_graph, []).

s_to_map(0, tip) --> !, [].
s_to_map(N, map(From,_,From/_,Lmap,Rmap)) -->
	{ A is (N-1)>>1, Z is N-1-A },
	s_to_map(A, Lmap),
	[From-_],
	s_to_map(Z, Rmap).


s_f_fill([], _).
s_f_fill([From-Neibs|Graph], Map) :-
	s_f_find(Map, From, Sons),
	s_f_sons(Neibs, Map, Sons),
	s_f_fill(Graph, Map).


s_f_find(map(Node,_,Tree,Lmap,Rmap), From, Sons) :-
	compare(R, From, Node),
	s_f_find(R, Tree, Lmap, Rmap, From, Sons).

s_f_find(=, From/Sons, _, _, From, Sons).
s_f_find(<, _,      Lmap, _, From, Sons) :-
	s_f_find(Lmap, From, Sons).
s_f_find(>, _,      _, Rmap, From, Sons) :-
	s_f_find(Rmap, From, Sons).


/*  s_f_sons(+Neibs, +Map, -Sons) looks up a whole batch of nodes
    in the Map, returning their trees.
    A node which is not found in the tree is returned as node/[].
    Nodes which are found are flagged as being children.
    In a graph which is a tree, there are no more Neibs all told
    than there are nodes in the graph, so this is an O(N.lgN) operation.
*/
s_f_sons([], _, []).
s_f_sons([Neib|Neibs], Map, [Son|Sons]) :-
	s_f_son(Map, Neib, Son),
	s_f_sons(Neibs, Map, Sons).

s_f_son(tip, Neib, Neib/[]).	% This son has no children
s_f_son(map(Node,Flag,Data,L,R), Neib, Son) :-
	compare(C, Neib, Node),
	s_f_son(C, Neib, Son, Flag, Data, L, R).

s_f_son(=, _, Son, Flag, Son, _, _) :-
	var(Flag),	%  A child can have at most one parent in a forest
	Flag = c.	%  Note that this is a child, not a root.
s_f_son(<, Neib, Son, _, _, L, _) :-
	s_f_son(L, Neib, Son).
s_f_son(>, Neib, Son, _, _, _, R) :-
	s_f_son(R, Neib, Son).



%   p_to_f_graph(+P_graph, ?Forest)
%   converts a forest from P-representation to F-representation.
%   It fails if P_graph does not represent a forest.
%   Currently, it goes through S-representation first.

p_to_f_graph(P_graph, Forest) :-
	p_to_s_graph(P_graph, S_graph),
	s_to_f_graph(S_graph, Forest).


/*  We are given a graph G in S-representation, and a node I.
    The task is to compute the set of nodes in G which are reachable from I.
    That is, {X | I G* X}.  In a conventional language, using integers to
    represent nodes, this can be done in O(N**2) time, N being the number
    of nodes.  At the time of writing this note, I am not sure what the
    cost will be for Prolog.

    Here is the algorithm.
	Set := []
	Frontier := [I]
	do Frontier =\= [] =>
	    Set := Set U Frontier
	    Frontier := U {neighbours(X)\Set | X in Frontier}
	od

    Now neighbours(X)\Set costs O(N) time,
    so the second assignment to Frontier will cost at most O(N**2) time,
    and the updates to Set should take at most O(N**2) time, so the
    total should be O(N**2), which is better than I hoped for.

    Note added half an hour later: the code worked first time, and takes
    0.2 N**2 milliseconds (when labels are integers) on a Sun-3/50.
*/
:- use_module(library(ordsets), [
	ord_union/3,
	ord_subtract/3
   ]).

%   reachable(+Vertex, +Graph, -Reachable)
%   is given a Graph (in S-representation) and a Vertex of that Graph,
%   and returns the set of nodes which are Reachable from that Vertex.

reachable(Initial, Graph, Reachable) :-
	reachable([Initial], Graph, [], Reachable).

%.  reachable(+Frontier, +Graph, +Set0, +Set)

reachable([], _, Set, Set).
reachable([Node|Nodes], Graph, Set0, Set) :-
	Frontier0 = [Node|Nodes],
	ord_union(Frontier0, Set0, Set1),
	new_frontier(Graph, Frontier0, Set1, [], Frontier1),
	reachable(Frontier1, Graph, Set1, Set).

new_frontier([], [], _, Frontier, Frontier).
new_frontier([From-Neibs|Pairs], [From|Froms], Set, Frontier0, Frontier) :- !,
	ord_subtract(Neibs, Set, NewNeibs),
	ord_union(Frontier0, NewNeibs, Frontier1),
	new_frontier(Pairs, Froms, Set, Frontier1, Frontier).
new_frontier([_|Pairs], Froms, Set, Frontier0, Frontier) :-
	new_frontier(Pairs, Froms, Set, Frontier0, Frontier).


end_of_file.


s_write([]) :- nl.
s_write([From-Neibs|Sgraph]) :-
	write((From->Neibs)), nl,
	s_write(Sgraph).

test(f, [a/[b/[d/[],e/[j/[]],f/[k/[]]],c/[g/[],h/[],i/[l/[]]]]]).
test(s, [a-[b,c],b-[d,e,f],c-[g,h,i],e-[j],f-[k],i-[l]]).
test(p, [a-b,a-c,b-d,b-e,b-f,c-g,c-h,c-i,e-j,f-k,i-l]).

:- use_module(library(random), [
	random_graph/3
   ]).

reach_test(N) :-
	reach_test(0.1, N).

reach_test(P, N) :-
	random_graph(P, N, G),
	s_write(G), nl,
	member(I-_, G),
	reachable(I, G, R),
	s_write([I-R]), nl,
	fail
    ;   nl.

reach_time(N) :-
	reach_time(0.1, N).

reach_time(P, N) :-
	random_graph(P, N, G),
	statistics(runtime, _),
	member(I-_, G),
	reachable(I, G, _),
	fail
    ;   statistics(runtime, [_,T]),
	S is T/N*1000/N/N,
	write(N^3*S=T), nl.

