
/* @(#)best_first.pl	1.1 02/11/91 */

%   Author : R.A.O'Keefe
%   Updated: 10 May 1985
%   Purpose: define a schema for "best" first search

:- ensure_loaded([ eight_puzzle, library(basics), 
		   library(findall), library(heaps) ]).

%   This schema has five parameters:
%	starting_position(Start)
%		binds Start to the first position to try
%	solution(Position)
%		tests whether a Position is a solution or not
%	operator_applies(Operator, OldPosition, NewPosition)
%		enumerates all the operators which apply to the
%		OldPosition, and also gives the NewPosition which
%		results from that operator application.
%	equivalent(Pos1, Pos2)
%		tests whether the two positions are essentially
%		the same.  The idea is that we will only look at
%		a position once.
%	distance(Position, Distance)
%		returns an estimate of how far the Position is
%		from a solution.  This is only used to rank the
%		descendants of a node, so the actual values of
%		the estimate don't matter too much.  See BEST
%		for a method where the values *do* matter.

%   best_first_search(Position, OperatorList)
%	returns the first solution it can find, and the list of
%	Operators which produced it: [On,...,O2,O1] means that
%	applying O1 to the start position, then O2, then ... and
%	finally On produces Position.


%   in best_first_search(+Heap, +Seen, -Position, -History),
%   Position and History are the results to be returned, Seen is a list
%   of positions which have been explored, and Heap is a heap (see heaps.pl)
%   of state(Position,Depth,History) triples ranked by the estimated cost
%   of a solution (depth + distance of position).  We don't actually bother
%   to eliminate duplicate positions from the heap.  We really ought to
%   do this, and to be prepared to update estimates if we find a smaller
%   estimate for the same position.

best_first_search(Position, History) :-
	starting_position(Start),
	distance(Start, Distance),
	list_to_heap([Distance-state(Start,0,[])], Heap),
	best_first_search(Heap, [Start], Position, History).

best_first_search(Heap, Seen, Position, History) :-
	get_from_heap(Heap, _Estimate, state(Pos,Depth,Hist), RestHeap),
	best_first_search(Pos,Depth,Hist, RestHeap, Seen, Position, History).

best_first_search(Position, _, History, _, _, Position, History) :-
	solution(Position),
	!.	%  assuming you want only one
best_first_search(Pos, Depth, Hist, Heap, Seen, Position, History) :-
	findall(Operator, new_position(Operator,Pos,Seen), Ops),
	NewDepth is Depth+1,
	fill_out(Ops, Pos, NewDepth, Hist, Heap, Seen,
		NewHeap, NewSeen),
	best_first_search(NewHeap, NewSeen, Position, History).


fill_out([], _, _, _, Heap, Seen, Heap, Seen).
fill_out([Op|Ops], Pos, Depth, Hist, Heap0, Seen0, Heap, Seen) :-
	operator_applies(Op, Pos, NewPos),
	distance(NewPos, Dist),
	Estimate is Dist+Depth,
	add_to_heap(Heap0, Estimate, state(NewPos,Depth,[Op|Hist]), Heap1),
	fill_out(Ops, Pos, Depth, Hist, Heap1, [Pos|Seen0], Heap, Seen).


new_position(Operator, Position, Seen) :-
	operator_applies(Operator, Position, NewPos),
	\+ (
	    member(OldPos, Seen),
	    equivalent(OldPos, NewPos)
	).


