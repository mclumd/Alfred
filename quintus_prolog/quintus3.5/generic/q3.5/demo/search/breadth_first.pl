
/* @(#)breadth_first.pl	1.1 02/11/91 */

%   Author : R.A.O'Keefe
%   Updated: 21 December 1983
%   Purpose: define a schema for breadth first search

:- ensure_loaded([ eight_puzzle, library(basics), library(findall) ]).

%   This schema has four parameters:
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

%   breadth_first_search(Position, OperatorList)
%	returns the first solution it can find, and the list of
%	Operators which produced it: [On,...,O2,O1] means that
%	applying O1 to the start position, then O2, then ... and
%	finally On produces Position.


breadth_first_search(Position, History) :-
	starting_position(Start),
	breadth_first_search([Start-[]], [Start], Position, History).


breadth_first_search([Position-OpList|_], _, Position, OpList) :-
	solution(Position),
	!.	%  assuming you want only one
breadth_first_search([Position-OpList|Rest], Seen, Answer, History) :-
	findall(Operator, new_position(Operator, Position, Seen), Ops),
	fill_out(Ops, Position, OpList, Seen, NewSeen, Descendants),
	append(Rest, Descendants, NewRest), !,
	breadth_first_search(NewRest, NewSeen, Answer, History).


new_position(Operator, Position, Seen) :-
	operator_applies(Operator, Position, NewPos),
	\+ (
	    member(OldPos, Seen),
	    equivalent(OldPos, NewPos)
	).


fill_out([], _, _, Seen, Seen, []) :- !.
fill_out([Op|Ops], Position, OpList, Seen, NewSeen, [NewPos-[Op|OpList]|New]) :-
	operator_applies(Op, Position, NewPos), !,
	fill_out(Ops, Position, OpList, [NewPos|Seen], NewSeen, New).

