%   File   : Puzzle Solver
%   Author : Luis E. Jenkins
%   Updated: Fri Aug 18 13:06:37 PDT 1989
%   Purpose: Solve a 15-like puzzle
%   SCCS   : @(#)plan.pl	18.1 08/31/92
%
% This code is based on the code written by Don Bennet, HP Labs
% and distributed with the X11R3 demos.
%
% Don't even look at this code. It needs to be cleaned up!



:- use_module(library(basics), [member/2]).
:- use_module(library(lists), [rev/2, delete/3]).
:- use_module(library(findall)).
:- use_module(library(heaps)).

:- dynamic
      debug_state/1.



apply(Dir, WinInfo) :-
	puzzle_tile(XRow, XCol, 0), !,
	WinInfo = puzzle(Win, Pix, Facts, Size, TW, TH),
	move_blank(Dir, XRow, XCol, _, _, Win, Pix, Facts, Size, TW, TH),
%%	sync,
	debug_print(text, 'Move space ~p~n', [Dir]),
	debug_print(state, '~n', _).



operator_ok(u, OldXLoc, NewXLoc) :- OldXLoc > 4, NewXLoc is OldXLoc-4.
operator_ok(d, OldXLoc, NewXLoc) :- OldXLoc < 13, NewXLoc is OldXLoc+4.
operator_ok(l, OldXLoc, NewXLoc) :- OldXLoc mod 4 =\= 1, NewXLoc is OldXLoc-1.
operator_ok(r, OldXLoc, NewXLoc) :- OldXLoc mod 4 =\= 0, NewXLoc is OldXLoc+1.


solve_layer0(WinInfo, Locked) :-
	ul(0, UL0),
	find_piece(UL0, WinInfo, Loc),
	move_piece(Loc, UL0, WinInfo, Locked),
	lr(0, LR0),
	move_space_to(LR0, WinInfo, Locked).

do_last_two_on_edge(NtLast, Last, Tmp, Emg, WinInfo, Locked0, Locked) :-
	( Last == 15 -> LastPiece = 11 ; LastPiece = Last ),
	find_piece(NtLast, WinInfo, NtLastLoc0),
	move_piece(NtLastLoc0, Last, WinInfo, Locked0),
	add_lock(Last, Locked0, Locked1),
    (
      find_piece(0, WinInfo, NtLast) ->
	debug_print(text, 'Space moved to avoid landlock~n', []),
	move_space_to(Tmp, WinInfo, Locked1)
    ;
      otherwise ->
	true
    ),
	Locked2 = Locked1,
    (
      find_piece(LastPiece, WinInfo, NtLast) ->    % Rescue
	debug_print(text, 'Rescue Begins~n', []),
	find_piece(NtLast, WinInfo, NtLastLoc2),
	move_piece(NtLastLoc2, NtLast, WinInfo, Locked0),
	add_lock(NtLast, Locked0, Locked3),
	find_piece(LastPiece, WinInfo, LastLoc3),
	move_piece(LastLoc3, Emg, WinInfo, Locked3),
	add_lock(Emg, Locked0, Locked4),
	find_piece(NtLast, WinInfo, NtLastLoc4),
	move_piece(NtLastLoc4, Last, WinInfo, Locked4),
	Locked5 = Locked2,
	debug_print(text, 'Rescue Ends~n', [])
    ;
      otherwise ->
	true
    ),
	Locked5 = Locked2,
	find_piece(LastPiece, WinInfo, LastLoc5),
	move_piece(LastLoc5, Tmp, WinInfo, Locked5),
	add_lock(Tmp, Locked5, Locked6),
	move_space_to(NtLast, WinInfo, Locked6),
	move_space_to(Last, WinInfo, Locked0),
	move_space_to(Tmp, WinInfo, Locked0),
	add_lock(NtLast, Locked5, Locked).


solve_puzzle(Win, Pix, Facts, Size, TW, TH) :-
	Layers is Size // 2,
	OuterLayer is Layers - 1,
	WinInfo = puzzle(Win, Pix, Facts, Size, TW, TH),
	solve_layers(OuterLayer, Layers, WinInfo, [], _).


solve_layers(0, Layers, WinInfo, Locked, Locked) :-
	!,
	solve_layer0(WinInfo, Locked),
	L0 is Layers - 1,
	finish(L0, WinInfo).
solve_layers(N, Layers, WinInfo, Locked0, Locked) :-
	N > 0,
	ul(N, UL),
	place_piece(UL, WinInfo, Locked0, Locked1), % UL Corner
	ur(N, UR),
	place_piece(UR, WinInfo, Locked1, Locked2), % UR Corner
	ll(N, LL),
	place_piece(LL, WinInfo, Locked2, Locked3), % LL Corner
	lr(N, LR),
	place_piece(LR, WinInfo, Locked3, Locked4), % LR Corner
	layer_edge(top, N, UL, UR, WinInfo, Locked4, Locked5),
	layer_edge(bottom, N, LL, LR, WinInfo, Locked5, Locked6),
	layer_edge(left, N, UL, LL, WinInfo, Locked6, Locked7),
	layer_edge(right, N, UR, LR, WinInfo, Locked7, Locked8),
	M is N - 1,
	solve_layers(M, Layers, WinInfo, Locked8, Locked).

layer_edge(Side, Layer, EdgeFirst, EdgeLast, WinInfo, Locked0, Locked) :-
	edge_auxiliary(Side, Layer, WinInfo, Inc, Tmp, Emg),
	Start is EdgeFirst + Inc,
	Stop is EdgeLast - 2*Inc,
	place(Start, Stop, Inc, WinInfo, Locked0, Locked1),
	NtLast is Stop,
	Last is NtLast + Inc,
	do_last_two_on_edge(NtLast, Last, Tmp, Emg, WinInfo, Locked1, Locked).


place(Start, Stop, Inc, WinInfo, Locked0, Locked) :-
    ( Start < Stop ->
	place_piece(Start, WinInfo, Locked0, Locked1),
	Next is Start + Inc,
	place(Next, Stop, Inc, WinInfo, Locked1, Locked)
    ; otherwise ->
	Locked = Locked0
    ).

place_piece(Loc, WinInfo, Locked0, Locked) :-
	find_piece(Loc, WinInfo, From),
	move_piece(From, Loc, WinInfo, Locked0),
	add_lock(Loc, Locked0, Locked).

finish(0, _) :-
	!.
finish(N, WinInfo) :-
	N > 0,
	apply(d, WinInfo),
	apply(r, WinInfo),
	M is N - 1,
	finish(M, WinInfo).


move_space_to(NewXLoc, WinInfo, Locked) :- 
        find_piece(0, WinInfo, OldXLoc),
	plan_move(OldXLoc, NewXLoc, Locked, Plan),
	execute_plan(Plan, WinInfo).

execute_plan([], _).
execute_plan([Op|Ops], WinInfo) :-
	apply(Op, WinInfo),
	execute_plan(Ops, WinInfo).

move_piece(From, To, WinInfo, Locked) :-
	plan_move(From, To, Locked, Plan),
	execute_move(Plan, From, WinInfo, Locked).

execute_move([], _, _, _).
execute_move([Op|Ops], Where, WinInfo, Locked) :-
	operator_ok(Op, Where, Next),
	add_lock(Where, Locked, TempLocked),
	move_space_to(Next, WinInfo, TempLocked),
	move_space_to(Where, WinInfo, Locked),
	execute_move(Ops, Next, WinInfo, Locked).



plan_move(From, To, Locked, Plan) :-
	simple_path(From, To, Locked, Plan),
	!.
plan_move(From, To, Locked, Plan) :-
	d(From, To, D),
	list_to_heap([D-state(From, 0, [])], Heap),
	flood_search(Heap, [From|Locked], To, Plan),
	!.
plan_move(From, To, Locked, _Plan) :-
	format('Cant move ~p to ~p with locked: ~p~n', [From, To, Locked]),
	print_board,
	sync,
	fail.


simple_path(From, To, Locked, Plan) :-
	row(From, R1),
	row(To, R2),
	V is R1 - R2,    % Up is positive
	col(From, C1),
	col(To, C2),
	H is C2 - C1,    % Right is positive
	path_clear(path(V, H), From, Locked, Plan).


path_clear(path(V, H), From, Locked, Plan) :-
	path_clear(V, v, From, Locked, Mid, Plan, Tail),
	path_clear(H, h, Mid, Locked, _To, Tail, []),
	!.
path_clear(path(V, H), From, Locked, Plan) :-
	path_clear(H, h, From, Locked, Mid, Plan, Tail),
	path_clear(V, v, Mid, Locked, _To, Tail, []).


path_clear(0, _, Loc, _, Loc, Plan, Plan) :-
	!.
path_clear(D, Dir, From, Locked, To, [Op|Plan], Tail) :-
	D \== 0,
	advance(Dir, D, Op, D0),
	operator_ok(Op, From, Mid),
	\+ member(Mid, Locked),
	path_clear(D0, Dir, Mid, Locked, To, Plan, Tail).


advance(h, D, Op, D0) :-
	( D > 0 -> Op = r, D0 is D - 1 ; D < 0 -> Op = l, D0 is D + 1 ).
advance(v, D, Op, D0) :-
	( D > 0 -> Op = u, D0 is D - 1 ; D < 0 -> Op = d, D0 is D + 1 ).


flood_search(Heap, Seen, Position, History) :-
	get_from_heap(Heap, _Estimate, state(Loc,Depth,Hist), RestHeap),
	flood_search(Loc,Depth,Hist, RestHeap, Seen, Position, History).

flood_search(Position, _, RevHistory, _, _, Position, History) :-
	!,	%  assuming you want only one
	rev(RevHistory, History).
flood_search(Loc, Depth, Hist, Heap, Seen, Position, History) :-
	findall(Child, new_position(Child,Loc,Seen), Children),
	NewDepth is Depth+1,
	fill_out(Children, NewDepth, Hist, Heap, Seen, Position,
		NewHeap, NewSeen),
	flood_search(NewHeap, NewSeen, Position, History).


fill_out([], _, _, Heap, Seen, _, Heap, Seen).
fill_out([pos(NewLoc, Op)|Cs], Depth, Hist, Heap0, Seen0, To, Heap, Seen) :-
	d(NewLoc, To, Dist),
	add_to_heap(Heap0, Dist, state(NewLoc,Depth,[Op|Hist]), Heap1),
	fill_out(Cs, Depth, Hist, Heap1, [NewLoc|Seen0], To, Heap, Seen).


new_position(pos(NewLoc, Operator), Loc, Seen) :-
	operator_ok(Operator, Loc, NewLoc),
	\+ member(NewLoc, Seen).
	

find_piece(16, WinInfo, Loc) :-
%%	format('Why do you ask for 16 anyway?~n', []),
	puzzle_tile(Row, Col, 15), !,
        WinInfo = puzzle(_Win, _Pix, _Facts, Size, _TW, _TH),
	Loc is Row*Size + Col + 1.
find_piece(P, WinInfo, Loc) :-
	puzzle_tile(Row, Col, P), !,
        WinInfo = puzzle(_Win, _Pix, _Facts, Size, _TW, _TH),
	Loc is Row*Size + Col + 1.


d(N1, N2, D) :-
	row(N1, Row1),
	row(N2, Row2),
	col(N1, Col1),
	col(N2, Col2),
	R is Row1 - Row2,
	C is Col1 - Col2,
	abs(R, RowDiff),
	abs(C, ColDiff),
	D is RowDiff + ColDiff.


row(Loc, Row) :-
	Row is (Loc - 1 ) // 4.

col(Loc, Col) :-
	Col is (Loc - 1) mod 4.


layer_depth(L, D) :-
	N = 2, %%%%% HARD CODED LAYERS
	D is N - 1 - L.


layer_width(L, W) :-
	S = 4,  %%%%%% HARD CODED SIZE
	layer_depth(L, D),
	W is S - 2*D.

ul(L, UL) :-
	layer_depth(L, D),
	S = 4,  %%%%%% HARD CODED SIZE
	UL is D * (S + 1) + 1.

ur(L, UR) :-
	ul(L, UL),
	layer_width(L, W),
	UR is UL + W - 1.

ll(L, LL) :-
	ul(L, UL),
	S = 4, %%%%% HARD CODED SIZE
	layer_width(L, W),
	LL is UL + (W - 1)*S.

lr(L, LR) :-
	ul(L, UL),
	S = 4, %%%%% HARD CODED SIZE
	layer_width(L, W),
	LR is UL + (W - 1)*(S + 1).



edge_auxiliary(top, Layer, _WinInfo, 1, TemporaryLoc, EmergencyLoc):-
	L0 is Layer - 1,
	ur(L0, TemporaryLoc),
	operator_ok(d, TemporaryLoc, EmergencyLoc).
edge_auxiliary(bottom, Layer, _WinInfo, 1, TemporaryLoc, EmergencyLoc):-
	L0 is Layer - 1,
	lr(L0, TemporaryLoc),
	operator_ok(u, TemporaryLoc, EmergencyLoc).
edge_auxiliary(left, Layer, WinInfo, Size, TemporaryLoc, EmergencyLoc):-
	L0 is Layer - 1,
	ll(L0, TemporaryLoc),
	operator_ok(r, TemporaryLoc, EmergencyLoc),
	WinInfo = puzzle(_Win, _Pix, _Facts, Size, _TW, _TH).
edge_auxiliary(right, Layer, WinInfo, Size, TemporaryLoc, EmergencyLoc):-
	L0 is Layer - 1,
	lr(L0, TemporaryLoc),
	operator_ok(l, TemporaryLoc, EmergencyLoc),
	WinInfo = puzzle(_Win, _Pix, _Facts, Size, _TW, _TH).


add_lock(N, Locked, [N|Locked]).

remove_lock(N, OldLocked, NewLocked) :-
	delete(OldLocked, N, NewLocked).


debug_print(text, Format, List) :-
	( debug_state(yes) -> format(Format, List) ; true ).
debug_print(state, Format, _) :-
	( debug_state(yes) -> format(Format, []), print_board ; true ).

verbose :-
	asserta(debug_state(yes)).
quiet :-
	retractall(debug_state(_)).


	
print_board :-
	Size = 4,  %%%%%% HARD CODED SIZE
	Len is Size*Size,
	print_board(0, Len, Size).

print_board(Index, Len, Size) :-
	Index < Len,
	!,
	tab_pos(Index, Size),
	I is Index // Size,
	J is Index mod Size,
	puzzle_tile(I, J, P), !,
	print_arg(P),
	NextIndex is Index + 1,
	print_board(NextIndex, Len, Size).
print_board(_, _, _) :-
	nl,
	nl.

tab_pos(Index, Size) :-
	( (Index mod Size) =:= 0 -> nl, tab(8) ; true ).

print_arg(0) :- 
	!,
	write(' x ').
print_arg(N) :-
	( N > 9 -> format('~d ', [N]) ; format(' ~d ', [N]) ).





