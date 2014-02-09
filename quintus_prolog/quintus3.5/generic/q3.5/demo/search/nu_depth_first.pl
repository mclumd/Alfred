
/* @(#)nu_depth_first.pl	1.1 02/11/91 */

%   Author : R.A.O'Keefe + Peter Ross
%   Updated: 19 December 1983
%   Purpose: define a schema for depth first search

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

%   depth_first_search(DepthLimit, Position, OperatorList)
%	returns the first solution it can find, and the list of
%	Operators which produced it: [O1,...,On] means that
%	applying O1 to the start position, then O2, then ... and
%	finally On produces Position. The DepthLimit should be
%	a positive integer, specifying that the search should go
%	no deeper than that.

%   depth_first(Position, OperatorList)
%       behaves like depth_first/3 with a very large DepthLimit.

% When used with the example defined in eight_puzzle, you should find that
% if you set the depth limit to
%	5    it is pretty fast (better than breadth_first: 4 to 1)
%      10    not too bad (rather worse than breadth_first: 1 to 5)
%      30    truly glacial (time for a trip to the cinema: 1 to HUGE)
% You may need to use a big local stack for deep searches: invoke prolog
% with -L512 if, for example, you want 512Kb of local stack rather than 128Kb

depth_first_search(FinalPos, Ans) :-
	depth_first_search(8'377777, FinalPos, Ans).

depth_first_search(Limit, FinalPos, Ans) :-
	starting_position(Start),
	depth_first_search(Limit, [Start], FinalPos, Ans).

depth_first_search(_Limit, [FinalPos|_], FinalPos, []) :-
	solution(FinalPos),
	!.			% assuming you want only one
depth_first_search(Limit, [CurrentPos|OthersSeen], FinalPos, [Op|DeeperOps]) :-
	NewLimit is Limit-1, NewLimit >= 0,
	operator_applies(Op, CurrentPos, NewPos),
	\+ (
	     member(SeenPos, [CurrentPos|OthersSeen]),
	     equivalent(SeenPos, NewPos)
	   ),
	depth_first_search(NewLimit, [NewPos,CurrentPos|OthersSeen],
		FinalPos, DeeperOps).
