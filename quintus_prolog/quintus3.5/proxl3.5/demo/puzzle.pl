% File    : puzzle.pl
% Author  : Luis Jenkins
% Updated : Fri Aug 18 13:06:37 PDT 1989
% Purpose : The Mandrill puzzle demo in ProXL
%  SCCS   : @(#)puzzle.pl	20.1 06/08/94
% 
% Based on the puzzle program by Don Bennet, HP Labs
%
% Copyright (C) 1989, Quintus Computer Systems, Inc.
%

/* Puzzle - (C) Copyright 1987, 1988 Don Bennett.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose and without fee is hereby granted,
 * provided that the above copyright notice appear in all copies and that
 * both that copyright notice and this permission notice appear in
 * supporting documentation.
 */

:- module(puzzle, [
	puzzle/0,
	puzzle/1,
	puzzle/2,
	puzzle/4
    ]).

:- use_module(library(proxl)).
:- use_module(library(ras2pix)).
:- use_module(library(between), [
	between/3
    ]).
:- use_module(library(random), [
        random/3
    ]).

:- use_module(library(panel)).
:- use_module(library(pushbutton)).
:- ensure_loaded(plan).

sccs_id('"@(#)89/07/21 puzzle.pl    3.1"').

:- dynamic
    puzzle_tile/3,
    puzzle_state/1.



user:runtime_entry(start) :-
	puzzle.


%
% Create the puzzle and start handling events
%
puzzle :-
    puzzle(4).

puzzle(N) :-
    get_screen_attributes([visual(V)]),
    ( V = pseudo_color(_, _, _, _) ->
	File = demo('puzzle.im8')
    ; V = gray(_, 1, _) ->
	File = demo('puzzle.im1')
    ; otherwise ->
	format(user_error, "Cannot display this demo on visual: ~w~n", [V]),
	fail
    ),
    absolute_file_name(File, RasterFile),
    puzzle(RasterFile, N).

puzzle(File, N) :-
    absolute_file_name(demo('ac.cursor'), Cursor),
    absolute_file_name(demo('ac_mask'), Mask),
    puzzle(File, Cursor, Mask, N).


puzzle(PictureFile, CursorFile, MaskFile, Size) :-
    nogc,
    create_picture_pixmap(Pixmap, PictureWidth, PictureHeight, PictureFile),
    TileWidth is PictureWidth // Size,
    TileHeight is PictureHeight // Size,
    graphics_context(GC, FgPixel, BgPixel),
    create_root_window(PuzzleRoot, PuzzleWidth, PuzzleHeight,
	               CursorFile, MaskFile, Size, GC,
	               FgPixel, BgPixel, TileWidth, TileHeight),
    create_facts_window(FactsWindow, Size, GC, FgPixel, BgPixel),
    create_tile_window(TileWindow, _TileWinWidth, _TileWinHeight,
	               PuzzleRoot, PuzzleWidth, PuzzleHeight, Pixmap, 
		       FactsWindow, Size, GC, FgPixel, TileWidth, TileHeight),
    create_panel_window(_PanelWindow, PuzzleRoot, PuzzleWidth, PuzzleHeight,
	                Pixmap, FactsWindow, Size, GC, FgPixel, BgPixel,
			TileWindow, TileWidth, TileHeight),
    initialize_puzzle_state(Size),
    put_window_attributes(PuzzleRoot, [mapped(true)]),
    handle_events(puzzle(bye)).



/***********************************************************************
 *                         Create the Windows                          *
 ***********************************************************************/

%
% Create the pixmap from a rasterfile and return its size
%
create_picture_pixmap(Pixmap, PictureWidth, PictureHeight, File) :-
    create_pixmap_from_rasterfile(File, Pixmap),
    get_pixmap_attributes(Pixmap, [size(PictureWidth, PictureHeight)]).


%
% Create the Root window that will contain everything else.
% This window is the parent of all the others
%
create_root_window(PuzzleRoot, PuzzleWidth, PuzzleHeight,
	           CursorFile, MaskFile, Size, GC, FgPixel, BgPixel,
		   TileWidth, TileHeight) :-
    create_cursor_from_file(Cursor, CursorFile, MaskFile),
    window_data(x, PuzzleRootX),
    window_data(y, PuzzleRootY),
    window_data(panel_window_height, PanelWinHeight),
    window_data(boundary_height, BoundaryHeight),
    window_data(border_width, BorderWidth),
    PuzzleWidth is TileWidth*Size,
    PuzzleHeight is TileHeight*Size + PanelWinHeight + BoundaryHeight,
    %
    % wm_normal_hints doesn't quite work on the DEC Alpha - all the Y
    % coordinates get set to zero. Thus do not set Max Size or Program Size
    SizeHints = wm_size_hints(program_position(PuzzleRootX, PuzzleRootY),
			      none,  % Program size
                              size(PuzzleWidth, PuzzleHeight),  % Min Size
                              none,  % Max Size
                              none,  % Resize Inc
                              none), % Aspect
    create_window(PuzzleRoot, [position(PuzzleRootX, PuzzleRootY),
	                       size(PuzzleWidth, PuzzleHeight),
			       property('WM_NAME', 'Puzzle'),
			       property('WM_NORMAL_HINTS', SizeHints),
			       cursor(Cursor),
			       gc(GC),
			       border_width(BorderWidth),
			       border(FgPixel),
			       background(BgPixel)]).


%
% Create the panel window at the top
%
create_panel_window(PanelWindow, PuzzleRoot, PuzzleWidth, _PuzzleHeight,
	            Pixmap, FactsWindow, Size, GC, FgPixel, BgPixel,
		    TileWindow, TileWidth, TileHeight) :-
    window_data(panel_window_height, PanelWinHeight),
    create_panel(PanelWindow,
	         [button(' Scramble ',
		    action([], Mode,
		           scramble(TileWindow, Pixmap, FactsWindow, Size,
			            TileWidth, TileHeight, Mode))),
		  button(' Solve ',
		    action([], Mode,
                           solve(TileWindow, Pixmap, FactsWindow, Size,
			         TileWidth, TileHeight, Mode))),
		  button(' Auto ',
		    action([], Mode, 
		           auto(TileWindow, Pixmap, FactsWindow, Size,
			        TileWidth, TileHeight, Mode))),
		  button(' Stop ',
		    action([], puzzle(stop), assertz(puzzle_state(stop)))),
		  button(' Show Facts ',
		    action([], puzzle(normal),
		           put_window_attributes(FactsWindow,
			                         [mapped(true)]))),
		  button(' Quit ',
		    action([], puzzle(bye), bye(PuzzleRoot, FactsWindow)))],
		 [parent(PuzzleRoot),
		  gc(GC),
		  border(FgPixel),
		  border_width(1),
		  background(BgPixel),
		  gc(GC),
		  mapped(true)],
		 PuzzleWidth,
		 PanelWinHeight).


%
% Create the tile window that will contain the image tiles
%
create_tile_window(TileWindow, TileWinWidth, TileWinHeight,
                   PuzzleRoot, PuzzleWidth, PuzzleHeight, Pixmap, FactsWindow,
		   Size, GC, TileBgPixel, TileWidth, TileHeight) :-
    window_data(panel_window_height, PanelWinHeight),
    window_data(boundary_height, BoundaryHeight),
    TileWinWidth is PuzzleWidth,
    TileWinHeight is PuzzleHeight - PanelWinHeight,
    TileWinY is PanelWinHeight + BoundaryHeight,
    create_window(TileWindow, [parent(PuzzleRoot),
	                       position(0, TileWinY),
			       size(TileWinWidth, TileWinHeight),
			       gc(GC),
			       border_width(0),
			       background(TileBgPixel),
			       callback(button_press, [position(X, Y)],
			                puzzle(normal),
			                slide(TileWindow, Pixmap, FactsWindow,
					      Size, X, Y,
					      TileWidth, TileHeight)),
			       callback(expose, [count(0)],
			                puzzle(normal),
			                expose(TileWindow, Pixmap, Size,
					       TileWidth, TileHeight)),
			       mapped(true)]).


%
% Create the window that will have the Prolog facts showing the
% state of the puzzle 
%
create_facts_window(FactsWindow, Size, GC, _FgPixel, BgPixel) :-
    window_data(panel_window_height, PanelHeight),
    window_data(boundary_height, BoundaryHeight),
    get_font_attributes(GC, [ascent(Ascent), height(FontHeight)]),
    H1 is PanelHeight + BoundaryHeight + Ascent,	
    H is H1 + Size*Size*FontHeight + 3*BoundaryHeight,
    text_width(GC, ' puzzle_tile( 9, 9, 99).  ', W),
    create_window(FactsWindow, [size(W, H),
	                        gc(GC),
				border_width(2),
				background(BgPixel),
				mapped(false),
				callback(expose, [count(0)],
				         puzzle(normal),
				         show_facts(FactsWindow, Size))]),
    create_pushbutton(_HideFacts,
	              ' Hide Facts ',
		      action([], puzzle(normal),
	                put_window_attributes(FactsWindow, [mapped(false)])),
		      [parent(FactsWindow),
		       position(4, 4),
		       border_width(1),
		       gc(GC),
		       background(BgPixel),
		       mapped(true)]).
					            



/**************************************************************************
 *                           Registered Callbacks                         *
 **************************************************************************/

%
% bye(+PuzzleWindow, +FactsWindow)
%     Called when the Quit button is pressed.
%     Destroy PuzzleWindow  and exit handle_events
%
bye(PuzzleWindow, FactsWindow) :-
    format('Sayonara!~n', []),
    destroy_window(PuzzleWindow),
    destroy_window(FactsWindow).	



%
% slide(+TileWindow, +Pixmap, +FactsWindow, +Size, +X, +Y,
%       +TileWidth, +TileHeight)
%    Called when any mouse button is pressed in the TileWindow
%    If the move is valid, slide the tile at X, Y
%
slide(TileWindow, Pixmap, FactsWindow, Size, X, Y, TileWidth, TileHeight) :-
    \+ puzzle_state(normal),
    retractall(puzzle_state(_)),
    Row is Y // TileHeight,
    Col is X // TileWidth,
    puzzle_tile(BlankRow, BlankCol, 0), !,  % 0 means the blank is here
    admissible_move(Row, Col, BlankRow, BlankCol),
    swap_blank(BlankRow, BlankCol, Row, Col, TileWindow, Pixmap, FactsWindow,
	       Size, TileWidth, TileHeight),
    !.
slide(_, _, _, _, _, _, _, _).


%
% scramble(+TileWindow, +Pixmap, +FactsWindow, +Size,
%          +TileWidth, +TileHeight, -Mode)
%    Called when the Scramble button is pressed.
%    Randomly move the blank around to scramble the puzzle
%
scramble(TileWindow, Pixmap, FactsWindow, Size, TileWidth, TileHeight, Mode) :-
    \+ puzzle_state(normal),
    retractall(puzzle_state(_)),
    asserta(puzzle_state(normal)),
    N is Size*Size*10,
    puzzle_tile(BlankRow, BlankCol, 0),
    scramble(N, BlankRow, BlankCol, TileWindow, Pixmap, FactsWindow, Size,
	     TileWidth, TileHeight),
    !,
    retractall(puzzle_state(_)),
    Mode = puzzle(normal).

scramble(_, _, _, _, _, _, puzzle(Mode)) :-
    puzzle_state(Mode),
    !.


%
% solve(+TileWindow, +Pixmap, FactsWindow, +Size,
%       +TileWidth, +TileHeight, -Mode)
%    Called when the Solve button is pressed.
%
solve(TileWindow, Pixmap, FactsWindow, Size, TileWidth, TileHeight, Mode) :-
    \+ puzzle_state(normal),
    retractall(puzzle_state(_)),
    asserta(puzzle_state(normal)),
    solve_puzzle(TileWindow, Pixmap, FactsWindow, Size, TileWidth,
	             TileHeight),
    !,
    retractall(puzzle_state(_)),
    Mode = puzzle(normal).
solve(_, _, _, _, _, _, puzzle(Mode)) :-
    puzzle_state(Mode),
    !.



%
% auto(+TileWindow, +Pixmap, +FactsWindow, +Size,
%      +TileWidth, +TileHeight, -Mode)
%    Called when the Auto button is pressed.
%    Keep scrambling and solving until stopped.
%
auto(TileWindow, Pixmap, FactsWindow, Size, TileWidth, TileHeight, Mode) :-
    \+ puzzle_state(normal),
    repeat,
      scramble(TileWindow, Pixmap, FactsWindow, Size,
	       TileWidth, TileHeight, Mode0),
      ( Mode0 == puzzle(normal) ->
	  waste_time(99999),
          garbage_collect,
	  solve(TileWindow, Pixmap, FactsWindow, Size,
	        TileWidth, TileHeight, Mode)
      ; otherwise ->
	  Mode = Mode0
      ),
      ( Mode == puzzle(normal) ->
	  waste_time(99999),
          garbage_collect,
	  fail
      ; true
      ),
    !.
auto(_, _, _, _, _, _, Mode) :- 
    puzzle_state(Mode),
    !.

%
% expose(+TileWindow, +Pixmap, +Size, +TileWidth, +TileHeight)
%    Called when the TileWindow gets the last in a series of expose events
%    Recreate the contents of the puzzle
%
expose(TileWindow, Pixmap, Size, TileWidth, TileHeight) :-
    N is Size*Size,
    repaint(0, N, TileWindow, Pixmap, Size, TileWidth, TileHeight).




%
% show_facts(+FactsWindow, +Size)
%    Called to refresh the Facts Window
%  
show_facts(FactsWindow, Size) :-
    get_window_attributes(FactsWindow, [mapped(viewable), width(W), gc(GC)]),
    !,
    N is Size*Size,
    get_font_attributes(GC, [ascent(Ascent), height(FontHeight)]),
    text_width(GC, '99', TW1),
    text_width(GC, '9', TW2),
    Pad is TW1 - TW2,
    window_data(panel_window_height, PanelHeight),
    window_data(boundary_height, BoundaryHeight),
    BarHeight is PanelHeight + BoundaryHeight,
    StartHeight is BarHeight + Ascent,
    clear_window(FactsWindow),
    draw_line(FactsWindow, 0, BarHeight, W, BarHeight),
    show_facts(0, N, FactsWindow, Size, StartHeight, FontHeight, Ascent, Pad),
    !.
show_facts(_, _).



/**************************************************************************
 *                           Moving Tiles Around                          *
 **************************************************************************/

%
% admissible_move(+FromRow, +FromCol, +ToRow, +ToCol)
%    Succeed if moving a tile from (FromRow, FromCol) to (ToRow, ToCol)
%    is a valid move
%
admissible_move(FromRow, FromCol, ToRow, ToCol) :-
    R is FromRow - ToRow,
    C is FromCol - ToCol,
    abs(R, RowDiff),
    abs(C, ColDiff),
    1 =:= RowDiff + ColDiff.


%
% swap_blank(+BlankRow, +BlankCol, +Row, +Col, +TileWindow, +Pixmap,
%            +FactsWindow, +Size, +TileWidth, +TileHeight)
%    Swap the blank at (BlankRow, BlankCol) with the tile at (Row, Col)
%
swap_blank(BlankRow, BlankCol, Row, Col, TileWindow, Pixmap, FactsWindow,
	   Size, TileWidth, TileHeight) :-
    \+ puzzle_state(bye),
    puzzle_tile(Row, Col, Tile), !,
    ul(BlankRow, BlankCol, TileWidth, TileHeight, DX, DY),  % Destination
    repaint_tile(Tile, DX, DY, Size, TileWindow, Pixmap,
	         TileWidth, TileHeight),
    ul(Row, Col, TileWidth, TileHeight, BX, BY),
    clear_area(TileWindow, BX, BY, TileWidth, TileHeight, false),
    update_state(Row, Col, 0, Tile),            % Blank is now at (Row, Col)
    update_state(BlankRow, BlankCol, Tile, _), % Tile is where Blank used to
    update_facts_window(FactsWindow, Size, Row, Col, BlankRow, BlankCol),
    handle_pending_events.



%
% new_position(+Dir, +Size, +BlankRow, +BlankCol, -NewRow, -NewCol)
%    Succeed if the blank at (BlankRow, BlankCol) can be moved one
%    step in direction Dir, and (NewRow, NewCol) is its new position.
%
new_position(u, _, BlankRow, BlankCol, NewRow, BlankCol) :-
    % Up
    BlankRow > 0,
    NewRow is BlankRow - 1.
new_position(d, Size, BlankRow, BlankCol, NewRow, BlankCol) :-
    % Down
    NewRow is BlankRow + 1,
    NewRow < Size.
new_position(l, _, BlankRow, BlankCol, BlankRow, NewCol) :-
    % Left
    BlankCol > 0,
    NewCol is BlankCol - 1.
new_position(r, Size, BlankRow, BlankCol, BlankRow, NewCol) :-
    % Right
    NewCol is BlankCol + 1,
    NewCol < Size.



%
% move_blank(+Dir, +BlankRow, +BlankCol, -NewRow, -NewCol, +TileWindow,
%            +Pixmap, +FactsWindow, +Size, +TileWidth, +TileHeight)
%    If moving the blank at (BlankRow, BlankCol) in direction Dir is valid,
%    do it and return its new position (NewRow, NewCol)
%
move_blank(Dir, BlankRow, BlankCol, NewRow, NewCol, TileWindow, Pixmap,
	   FactsWindow, Size, TileWidth, TileHeight) :-
    \+ puzzle_state(stop),
    (
      new_position(Dir, Size, BlankRow, BlankCol, NewRow, NewCol) ->
	swap_blank(BlankRow, BlankCol, NewRow, NewCol, TileWindow, Pixmap, 
                   FactsWindow, Size, TileWidth, TileHeight)

    ;
      otherwise ->
	NewRow = BlankRow,
	NewCol = BlankCol    % No move
    ).



%
% scramble(+N, +BlankRow, +BlankCol, +TileWindow, +Pixmap, +FactsWindow,
%          +Size, +TileWidth, +TileHeight)
%    Scramble the puzzle state N times, moving the blank at
%    (BlankRow, BlankCol)
%
scramble(0, _, _, _, _, _, _, _, _) :-
    !.
scramble(N, BlankRow, BlankCol, TileWindow, Pixmap, FactsWindow, Size,
	 TileWidth, TileHeight) :-
    random(0, 4, D),
    direction(D, Dir),
    move_blank(Dir, BlankRow, BlankCol, NewRow, NewCol, TileWindow, Pixmap,
	       FactsWindow, Size, TileWidth, TileHeight), 
    M is N - 1,
    scramble(M, NewRow, NewCol, TileWindow, Pixmap, FactsWindow, Size,
	     TileWidth, TileHeight).



/***************************************************************************
 *                         Repaint the Tile Window                         *
 ***************************************************************************/

%
% repaint(+Index, +Total, +TileWindow, +Pixmap, +Size, +TileWidth, +TileHeight)
%
repaint(Index, Total, TileWindow, Pixmap, Size, TileWidth, TileHeight) :-
    (
      Index == Total ->
	flush
    ;
      otherwise ->
	I is Index // Size,
	J is Index mod Size,
	puzzle_tile(I, J, Tile), !,
	ul(I, J, TileWidth, TileHeight, X, Y),
	repaint_tile(Tile, X, Y, Size, TileWindow, Pixmap,
	             TileWidth, TileHeight),
        Next is Index + 1,
	repaint(Next, Total, TileWindow, Pixmap, Size, TileWidth, TileHeight)
    ).


%
% repaint_tile(+Tile, +X, +Y, +Size, +TileWindow, +Pixmap, +TileWidth,
%              +TileHeight)
%
repaint_tile(0, X, Y, _, TileWindow, _, TileWidth, TileHeight) :-
    !,
    clear_area(TileWindow, X, Y, TileWidth, TileHeight, false).
repaint_tile(Tile, X, Y, Size, TileWindow, Pixmap, TileWidth, TileHeight) :-
    Row is (Tile - 1) // Size,
    Col is (Tile - 1) mod Size,
    ul(Row, Col, TileWidth, TileHeight, OrgX, OrgY),
    copy_area(TileWindow, X, Y, Pixmap, OrgX, OrgY, TileWidth, TileHeight).




/*************************************************************************
 *                    Keeping the state of the puzzle                    *
 *************************************************************************/

%
% initialize_puzzle_state(+N)
%    Create the initial state for a puzzle of size N by N
%
initialize_puzzle_state(N) :-
    abolish(puzzle_tile/3),
    M is N - 1,
    (
      Last is N*N,
      between(0, M, I),
      between(0, M, J),
      Index is I*N + J + 1,
      Index =\= Last,
      assertz(puzzle_tile(I, J, Index)),
      fail
    ;
      asserta(puzzle_tile(M, M, 0))
    ).



%
% update_state(+I, +J, +NewTile, -OldTile)
%    Update the puzzle state to reflect that position (I, J) contains
%    the tile NewTile. Return the OldTile that was there before
%
update_state(I, J, NewTile, OldTile) :-
    clause(puzzle_tile(I, J, OldTile), true, Ref), !,
    erase(Ref),
    asserta(puzzle_tile(I, J, NewTile)).




/**********************************************************************
 *         Show the Prolog Facts with the state of the Puzzle         *
 **********************************************************************/
%
% show_facts(+Index, +N, +FactsWindow, +Size, +StartHeight,
%            +FontHeight, +Ascent, +Pad)
%
show_facts(Index, N, FactsWindow, Size, Y, FontHeight, Ascent, Pad) :-
    (
      Index < N ->
	I is Index // Size,
	J is Index mod Size,
	puzzle_tile(I, J, Tile), !,
        show_fact(FactsWindow, 0, Y, Ascent, I, J, Tile, Pad),
        NextIndex is Index + 1,
	NextY is Y + FontHeight,
	show_facts(NextIndex, N, FactsWindow, Size, NextY,
	           FontHeight, Ascent, Pad)
    ;
      otherwise ->
	true
    ).


%
% update_facts_window(+FactsWindow, +Size, +Row1, +Col1, +Row2, +Col2)
%
update_facts_window(FactsWindow, Size, Row1, Col1, Row2, Col2) :-
    get_window_attributes(FactsWindow, [mapped(viewable), gc(GC)]),
    !,
    get_font_attributes(GC, [ascent(Ascent), height(FontHeight)]),
    put_graphics_attributes(GC, [function(xor)]),	
    window_data(panel_window_height, PanelHeight),
    window_data(boundary_height, BoundaryHeight),
    StartHeight is PanelHeight + BoundaryHeight + Ascent,
    Y1 is StartHeight + (Row1*Size + Col1)*FontHeight - 1,
    Y2 is StartHeight + (Row2*Size + Col2)*FontHeight - 1,
    text_width(GC, ' puzzle_tile( 9, 9, ', X),
    text_width(GC, '99', W),
    NX is X - 1,
    copy_area(FactsWindow, NX, Y1, FactsWindow, NX, Y2, W, FontHeight),
    copy_area(FactsWindow, NX, Y2, FactsWindow, NX, Y1, W, FontHeight),
    copy_area(FactsWindow, NX, Y1, FactsWindow, NX, Y2, W, FontHeight),
    put_graphics_attributes(GC, [function(copy)]).
update_facts_window(_, _, _, _, _, _).



show_fact(FactsWindow, X, Y, Ascent, I, J, Tile, Pad) :-
	number_chars(I, L1),
	number_chars(J, L2),
	number_string(Tile, L3, Pad, D3),
        TY is Y + Ascent,
        draw_text(FactsWindow, X, TY, [textitem(' puzzle_tile( ', 0),
	                              textitem(L1, 0),
				      textitem(', ', 0),
				      textitem(L2, 0),
				      textitem(', ', 0),
				      textitem(L3, D3),
				      textitem('). ', 0)]),
        !.   %%%% BUG in ProXL: draw_text leaves choice points

	

/**********************************************************************
 *                 GC, Cursor, Pending Events                         *
 **********************************************************************/

%
% graphics_context(-GC, -FgPixel, -BgPixel)
%
graphics_context(GC, FgPixel, BgPixel) :-
    get_screen_attributes([black_pixel(FgPixel), white_pixel(BgPixel)]),
    find_font(Font),
    create_gc(GC, [foreground(FgPixel),
	           background(BgPixel),
		   graphics_exposures(false),
		   font(Font),
		   line_width(1)]).


%
% create_cursor_from_file(-Cursor, +CursorFile, +MaskFile)
%
create_cursor_from_file(Cursor, CursorFile, MaskFile) :-
    read_bitmap_file(CursorFile, CursorPix, XHot, YHot),
    read_bitmap_file(MaskFile, MaskPix),
    WhiteBackground = color(1.0, 1.0, 1.0),
    BlackForeground = color(0.0, 0.0, 0.0),
    create_cursor(pixmap_cursor(CursorPix, MaskPix, XHot, YHot),
	          Cursor, BlackForeground, WhiteBackground).


%
% handle_pending_events
%
handle_pending_events :-
    (
      pending(0) ->
	true
    ;
      handle_one_event(Mode) ->
        retractall(puzzle_state(_)),
	asserta(puzzle_state(Mode))
    ;
      otherwise ->
	true
    ).


handle_one_event(Mode) :-
    handle_events(Exit), 
    nonvar(Exit),
    Exit = puzzle(Mode),
    Mode \== normal.



/*************************************************************************
 *                               Utilities                               *
 *************************************************************************/

%
% Finding out {upper, lower} {left, right} coordinates of tiles
%
ul(I, J, TileWidth, TileHeight, ULX, ULY) :-
    ULX is J*TileWidth,
    ULY is I*TileHeight.

ll(I, J, TileWidth, TileHeight, LLX, LLY) :-
    LLX is J*TileWidth,
    LLY is (I+1)*TileHeight - 1.

ur(I, J, TileWidth, TileHeight, URX, URY) :-
    URX is (J+1)*TileWidth - 1,
    URY is I*TileHeight.

lr(I, J, TileWidth, TileHeight, LRX, LRY) :-
    LRX is (J+1)*TileWidth - 1,
    LRY is (I+1)*TileHeight - 1.

%
% Direction
%
direction(0, u).
direction(1, d).
direction(2, l).
direction(3, r).

%
% Random other things
%

find_font(Font) :-
    (
        window_data(font, FontSpec),
	current_font(FontSpec, FontName) ->
	    load_font(FontName, Font)
    ;
	otherwise ->
	    format('[ ~p: Can not find requested fonts ]~n', puzzle),
	    fail
    ).

abs(Number, Abs) :-
    ( Number >= 0 -> Abs is Number ; Abs is - Number).


waste_time(N) :-
    ( N =< 0 -> true ; M is N - 1, waste_time(M) ).


number_string(I, S, Pad, D) :-
    number_chars(I, S),
    ( I =< 9 -> D = Pad; D = 0 ).

/*************************************************************************
 *                        Puzzle Configuration Data                      *
 *************************************************************************/

window_data(border_width, 2).
window_data(panel_window_height, 25).
window_data(boundary_height, 3).
window_data(box_width, 10).
window_data(box_height, 10).
window_data(min_tile_height, 30).
window_data(min_tile_width, 30).
window_data(font, '*-helvetica-medium-r-*-120-*'). % First choice, on X11R3
window_data(font, 'fixed').                        % Second choice or on X11R2
window_data(x, 100).
window_data(y, 300).

% NB:  this is done so that the same code will work as a demo loaded
%      into either a prolog or proxl development system, and also
%      as a stand-alone runtime system.  In the latter case, if
%      the usual demo directories are not accessible from the
%      executables, copy the files puzzle.im1, puzzle.im8, ac.cursor,
%      and ac_mask into a directory somewhere and do
%		qsetpath -r <that directory> puzzle
%      to tell the puzzle executable where to find its files.

:- initialization assertz(user:file_search_path(demo, runtime(''))).
