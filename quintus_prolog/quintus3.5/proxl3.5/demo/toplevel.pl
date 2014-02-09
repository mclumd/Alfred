%
% File    : top_level.pl
% Author  : Luis Jenkins
% Updated : Mon May 29 22:59:15 PDT 1989
% Purpose : A simple interactive Prolog Top Level window in ProXL
%
% Copyright (C) 1989, Quintus Computer Systems, Inc. All rights reserved.
%

:- module(top_level, [
        top_level/0
    ]).


:- use_module(library(proxl)).
:- use_module(library(charsio), [
        with_output_to_chars/2,
	with_input_from_chars/2
    ]).
:- use_module(library(ctypes), [
        is_upper/1,
	is_quote/1
    ]).

sccs_id('"@(#)91/01/30 toplevel.pl    4.4"').

:- dynamic
    window_data/2,
    char_stack/3.



user:runtime_entry(start) :-
	top_level.


top_level :-
    window_data(prompt_label, PromptLabel),
    window_data(vertical_space, VerticalSpace),
    window_data(horizontal_space, HorizontalSpace),
    window_data(boundary_height, BoundaryHeight),
    graphics_data(GC, FontHeight, FontWidth, Font),
    text_extents(Font, PromptLabel, _, _, LabelWidth, Ascent, _),
    WindowHeight is 4*VerticalSpace + 2*FontHeight,
    WindowWidth is LabelWidth + 80*FontWidth + 3*HorizontalSpace,
    TitleHeight is 2*VerticalSpace + FontHeight,
    TitleWidth is WindowWidth,
    RootHeight is WindowHeight + BoundaryHeight + TitleHeight,
    RootWidth is WindowWidth,
    create_root_window(RootWindow, RootWidth, RootHeight, RootCursor),
    create_title_window(TitleWindow, TitleWidth, TitleHeight,
	                LabelWidth, Ascent,
	                RootWindow, RootCursor, GC),
    create_exit_box(_AdiosBox, TitleWindow, TitleWidth, TitleHeight,
	            RootWindow),
    create_prolog_window(_PrologWindow, WindowWidth, WindowHeight,
	                 LabelWidth, Ascent, TitleHeight,
			 FontWidth, FontHeight,
			 RootWindow, GC),
    initialize_state,
    put_window_attributes(RootWindow, [mapped(true)]),
    handle_events(bye, input).


/***************************************************************************
 *                             Create the Windows
 ***************************************************************************/


create_root_window(RootWindow, RootWidth, RootHeight, RootCursor) :-
    create_cursor(left_ptr, RootCursor),
    create_window(RootWindow, [size(RootWidth, RootHeight),
	                       position(200, 200),
			       property('WM_NAME', 'Prolog Top Level'),
			       cursor(RootCursor),
			       border_width(2)]).



create_title_window(TitleWindow, TitleWidth, TitleHeight, LabelWidth, Ascent,
	            RootWindow, RootCursor, GC) :-
    create_window(TitleWindow, [position(0, 0),
	                        size(TitleWidth, TitleHeight),
				border_width(1),
				parent(RootWindow),
				cursor(RootCursor),
				gc(GC),
				mapped(true),
				callback(expose, [count(0)],
				         title(TitleWindow, LabelWidth,
					       Ascent))]).

create_prolog_window(PrologWindow, WindowWidth, WindowHeight,
                     LabelWidth, Ascent, TitleHeight, FontWidth, FontHeight,
    	             RootWindow, GC) :-
    window_data(boundary_height, BoundaryHeight),
    PrologWinY is TitleHeight + BoundaryHeight,
    create_cursor(xterm, Cursor),
    create_window(PrologWindow, [size(WindowWidth, WindowHeight),
	                         position(0, PrologWinY),
	                         border_width(0),
				 parent(RootWindow),
				 cursor(Cursor),
				 gc(GC),
				 mapped(true),
				 callback(key_press,
				          [key(K), length(L), chars(S)],
                                          More,
					  Mode,
				          input(Mode, More, PrologWindow,
					        LabelWidth, Ascent, 
					        FontWidth, FontHeight,
						K, L, S)),
				 callback(expose,
				          [count(0)],
				          expose(PrologWindow,
					         LabelWidth, Ascent,
					         FontWidth, FontHeight))]).




create_exit_box(AdiosBox, TitleWindow, TitleWidth, TitleHeight, RootWindow) :-
    window_data(box_size, BoxSize),
    BoxX is TitleWidth - 2*BoxSize,
    BoxY is (TitleHeight - BoxSize) // 2,  
    create_window(AdiosBox, [position(BoxX, BoxY),
	                     size(BoxSize, BoxSize),
			     border_width(1),
			     parent(TitleWindow),
			     win_gravity(north_east),
			     mapped(true),
			     callback(button_press, [], bye,
			              adios(RootWindow))]).


/****************************************************************************
 *                                  Callbacks                               *
 ****************************************************************************/

adios(Window) :-
    destroy_window(Window).


title(TitleWindow, LabelWidth, Ascent) :-
    window_data(vertical_space, VerticalSpace),
    window_data(title, Label),
    get_window_attributes(TitleWindow, [width(TitleWidth)]),
    TitleX is (TitleWidth - LabelWidth) // 2,
    TitleY is VerticalSpace + Ascent,
    draw_string(TitleWindow, TitleX, TitleY, Label).


input(input, _, PrologWindow, LabelWidth, Ascent, FontWidth, FontHeight,
      K, L, S) :-
    !,     %%% input mode has to be first and cut 
    L =\= 0,
    current_index(Index),
    window_data(horizontal_space, HorizontalSpace),
    window_data(vertical_space, VerticalSpace),
    GoalX is 2*HorizontalSpace + LabelWidth,
    GoalY is VerticalSpace + Ascent,
    update_input(K, S, Index, PrologWindow, FontWidth, FontHeight,
	         GoalX, GoalY, EOL),
    (
      EOL == true ->
        goal_assemble(Chars, Goal),
        execute_goal_from_chars(Chars, NVars, Answer),
        AnswerX is GoalX,
        AnswerY is GoalY + VerticalSpace + FontHeight,        
        AreaWidth is 80*FontWidth,
        AreaHeight is FontHeight,
        AreaX is AnswerX,
        AreaY is 2*VerticalSpace + FontHeight,
        clear_area(PrologWindow, AreaX, AreaY, AreaWidth, AreaHeight, false),
	draw_string(PrologWindow, AnswerX, AnswerY, Answer),
        ( NVars == 0 -> true ;
	  Answer == 'no' -> true ;
          text_width(PrologWindow, Answer, AnswerWidth),
	  MoreX is AnswerX + AnswerWidth + 2*FontWidth,
          clear_area(PrologWindow, AreaX, AreaY, AreaWidth, AreaHeight, false),
	  draw_string(PrologWindow, AnswerX, AnswerY, Answer),
	  draw_string(PrologWindow, MoreX, AnswerY, 'More ?'),
	  handle_events(More, no_input),
          repaint_goal(Goal, PrologWindow, LabelWidth, Ascent),
          More == done,
          MoreWidth is 6*FontWidth,
	  clear_area(PrologWindow, MoreX, AreaY, MoreWidth, AreaHeight, false)
        )
    ;
      otherwise ->
	true
    ).
input(no_input, More, _, _, _, _, _, K, L, _) :-
    L =\= 0, % reject modifiers and such
    ( K == ';' -> More = more ; More = done ).


expose(PrologWindow, LabelWidth, Ascent, _FontWidth, _FontHeight) :-
    clear_window(PrologWindow),
    goal_assemble(_, Goal),
    repaint_goal(Goal, PrologWindow, LabelWidth, Ascent).
%   repaint_status

repaint_goal(Goal, PrologWindow, LabelWidth, Ascent) :-
    window_data(prompt_label, Prompt),
    window_data(vertical_space, VerticalSpace),
    window_data(horizontal_space, HorizontalSpace),
    PromptX is HorizontalSpace,
    PromptY is VerticalSpace + Ascent,
    GoalX is 2*HorizontalSpace + LabelWidth,
    GoalY is VerticalSpace + Ascent,
    draw_string(PrologWindow, PromptX, PromptY, Prompt),
    draw_string(PrologWindow, GoalX, GoalY, Goal).
%    ( 
%      current_goal(result, Answer) ->
%	draw_string(PrologWindow, AnswerX, AnswerY, Answer)
%    ;
%      otherwise ->
%	true
%    ).
    


/*************************************************************************
 *                        Handle user input                              *
 *************************************************************************/

update_input('Return', _, _, _, _, _, _, _, true) :-
    !.
update_input('Linefeed', _, _, _, _, _, _, _, true) :-
    !.
update_input('Delete', _, Index, PrologWindow, FW, FH, GX, GY, _) :-
    !,
    erase(Index, _, PrologWindow, FW, FH, GX, GY).
update_input('Backspace', _, Index, PrologWindow, FW, FH, GX, GY, _) :-
    !,
    erase(Index, _, PrologWindow, FW, FH, GX, GY).
update_input('u', [21], Index, PrologWindow, FW, FH, GX, GY, _) :-  % ^U
    !,
    erase_line(Index, PrologWindow, FW, FH, GX, GY).
update_input(_, [C], Index, PrologWindow, FW, FH, GX, GY, _) :-
    !,
    new_char(C, Index, _, PrologWindow, FW, FH, GX, GY).
update_input(_, S, Index, PrologWindow, FW, FH, GX, GY, _) :-
    new_input(S, Index, PrologWindow, FW, FH, GX, GY).


new_input([], _, _, _, _, _, _).
new_input([C|Chars], Index, W, FW, FH, GX, GY) :-
    new_char(C, Index, NewIndex, W, FW, FH, GX, GY),
    new_input(Chars, NewIndex, W, FW, FH, GX, GY).


erase_line(Index, PrologWindow, FW, FH, GX, _GY) :-
    !,
    initialize_state,
    window_data(vertical_space, VS),
    AreaX is GX,
    AreaY is VS,
    AreaHeight is FH,
    AreaWidth is Index*FW,
    clear_area(PrologWindow, AreaX, AreaY, AreaWidth, AreaHeight, false),
    AnswerAreaY is AreaY + FH + VS,
    AnswerAreaWidth is 80*FW,
    clear_area(PrologWindow, AreaX, AnswerAreaY, AnswerAreaWidth, AreaHeight,
	       false).

new_char(Char, Index, Next, PrologWindow, FW, _FH, GX, GY) :-
    push(Char, Index, 0),
    X is GX + Index*FW,
    Y is GY,
    draw_string(PrologWindow, X, Y, [Char]),
    Next is Index + 1.


erase(Index, Prev, PrologWindow, FontWidth, FontHeight, GoalX, _) :-
    (
      Index == 0 ->
	Prev = 0
    ;
      otherwise ->
        Prev is Index - 1,
        pop(_, Prev, _State),
        window_data(vertical_space, VerticalSpace),
	X is GoalX + Prev*FontWidth,
	Y is VerticalSpace,
	clear_area(PrologWindow, X, Y, FontWidth, FontHeight, false)
    ).



current_index(Index) :-
    ( clause(char_stack(Prev, _, _), _, _) -> Index is Prev + 1 ; Index = 0 ).


push(Char, Index, State) :-
    asserta(char_stack(Index, Char, State)).

pop(Char, Index, State) :-
    clause(char_stack(Index, Char, State), _, Ref),
    !,
    erase(Ref).


/***************************************************************************
 *                           Random utilities                              *
 ***************************************************************************/

initialize_state :-
    retractall(char_stack(_, _, _)).


graphics_data(GC, FontHeight, FontWidth, Font) :-
    find_font(Font),
    get_font_attributes(Font, [height(FontHeight), max_width(FontWidth)]),
    get_screen_attributes([black_pixel(FgPixel), white_pixel(BgPixel)]),
    create_gc(GC, [foreground(FgPixel),
                   background(BgPixel),
		   font(Font),
                   line_width(0)]).

find_font(Font) :-
    (
        window_data(font, FontSpec),
	current_font(FontSpec, FontName) ->
	    load_font(FontName, Font)
    ;
	otherwise ->
	    format('[ ~p: Can not find requested fonts ]~n', top_level),
	    fail
    ).


/**************************************************************************
 *                      From chars to terms and such                      *
 **************************************************************************/

goal_assemble(Chars, Goal) :-
    goal_characters(0, Chars),
    atom_chars(Goal, Chars).


goal_characters(I, Chars) :-
    (
      char_stack(I, C, _) ->
	Chars = [C|Cs],
	J is I + 1,
	goal_characters(J, Cs)
    ;
      otherwise ->
	Chars = []
    ).


term_to_atom(Term, Atom) :-
    numbervars(Term, 0, _),
    with_output_to_chars(write(Term), Chars),
    atom_chars(Atom, Chars).


execute_goal_from_chars(Chars, NVars, Atom) :-
    goal_analyse(Chars, NVars, ProperChars),
    with_input_from_chars(read(Goal), ProperChars),
    (
      Goal == end_of_file ->
	fail
    ;
      call(Goal),
      ( NVars == 0 -> Atom = 'yes', ! ; term_to_atom(Goal, Atom) )
    ;
      Atom = 'no'
    ).




goal_analyse(Chars, NVars, ProperChars) :-
    goal_analyse(Chars, 0, 0, NVars, ProperChars).


%
% goal_analyse(+Chars, +InQuote, +N, -NVars, -ProperChars)
%   Find out if the Chars require a final ". " for proper
%   reading and count the number of variables inside.
%   InQuote is the type of quotes we are inside of, 0 means none
%
goal_analyse(". ", _, N, N, ". ") :-
    !.
goal_analyse(".", _, N, N, ".") :-
    !.
goal_analyse([X], _, N, N, [X, 0'., 0' ]) :-
    !.
goal_analyse([S|Ss], InQuote, N0, N, [S|DSs]) :-
    (
      is_upper(S) ->
	( InQuote == 0 -> N1 is N0 + 1 ; N1 is N0 ),
	OutQuote = InQuote
    ;
      is_quote(S) ->
	( InQuote == 0 -> OutQuote = S ;
	  InQuote == S -> OutQuote = 0 ;
	  OutQuote = InQuote ),
	N1 is N0
    ;
      otherwise ->
	OutQuote = InQuote,
	N1 is N0
    ),
    goal_analyse(Ss, OutQuote, N1, N, DSs).


/*****************************************************************************
 *                             Window data                                   *
 *****************************************************************************/
					  
window_data(font, 'fixed').
window_data(prompt_label, '| ?- ').
window_data(vertical_space, 5).
window_data(horizontal_space, 5).
window_data(boundary_height, 3).
window_data(box_size, 10).
window_data(title, 'Prolog Top Level').

