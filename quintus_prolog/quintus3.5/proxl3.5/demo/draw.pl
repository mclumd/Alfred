% File    : draw.pl
% Author  : Luis Jenkins
% Updated : Fri Jun  2 01:03:53 PDT 1989
% Purpose : A very basic Draw program in ProXL
%
% Copyright (C) 1990, Quintus Computer Systems, Inc. All rights reserved
%

:- module(draw, [
        draw/0
    ]).


:- use_module(library(proxl)).


sccs_id('"@(#)94/06/08 draw.pl    20.1"').	

:- dynamic
	selected_region/4,
	draw_mode/2,
	drawn_figure/3,
        drawing_window/8.


user:runtime_entry(start) :-
	draw.

draw :-
    initialize_state,
    window_data(title, Label),
    window_data(vertical_space, VerticalSpace),
    window_data(horizontal_space, HorizontalSpace),
    window_data(width, DrawWidth),
    window_data(height, DrawHeight),
    window_data(boundary_height, BoundaryHeight),
    window_data(menu_option_size, MenuBoxSize),
    find_font(titlefont, TitleFont),
    find_font(menufont, MenuFont),
    get_font_attributes(TitleFont, [height(FontHeight)]),
    create_rubberband_gc(RubberBandGC, MenuFont),
    create_drawing_gcs(DrawingGC, InvertingGC, FgPixel, BgPixel, MenuFont),
    text_extents(TitleFont, Label, _, _, LabelWidth, Ascent, _),
    MinTitleWidth is LabelWidth + 200,
    MenuWidth is 4*HorizontalSpace + 2*MenuBoxSize,
    MinWidth is DrawWidth + MenuWidth,
    max(MinTitleWidth, MinWidth, Width),
    WindowWidth is Width + HorizontalSpace // 2,
    TitleHeight is 2*VerticalSpace + FontHeight,
    RootHeight is DrawHeight + BoundaryHeight + TitleHeight,
    create_root_window(RootWindow, WindowWidth, RootHeight, RootCursor),
    create_title_window(TitleWindow, WindowWidth, TitleHeight, LabelWidth,
			Ascent, RootWindow, TitleFont),
    create_exit_box(AdiosBox, TitleWindow, WindowWidth, TitleHeight,
	            RootWindow),
    create_drawing_window(DrawWindow, DrawWidth, DrawHeight, TitleHeight,
		       RootWindow, RubberBandGC, DrawingGC),
    create_menu_window(MenuWindow, MenuWidth, DrawHeight,
	               DrawWidth, TitleHeight, RootWindow, RootCursor,
		       DrawWindow, DrawingGC, InvertingGC, FgPixel, BgPixel),
    put_window_attributes(RootWindow, [mapped(true)]),
    assert(drawing_window(RootWindow,WindowWidth,RootHeight,DrawWindow,DrawWidth,
			DrawHeight,MenuWindow,TitleWindow,AdiosBox)),
    handle_events(drawing_window(bye)).


/**********************************************************************
 *                       Create the Windows                           *
 **********************************************************************/

create_root_window(RootWindow, RootWidth, RootHeight, RootCursor) :-
    window_data(root_cursor, RootCursorName),
    create_cursor(RootCursorName, RootCursor),
    create_window(RootWindow, [size(RootWidth, RootHeight),
	                       position(200, 200),
			       property('WM_NAME', 'Draw'),
			       cursor(RootCursor),
			       border_width(2),
			       callback(configure_notify, [size(W,H)],
					new_root_size(RootWindow,W,H))]).



create_title_window(TitleWindow, TitleWidth, TitleHeight, LabelWidth, Ascent,
	            RootWindow, Font) :-
    create_window(TitleWindow, [position(0, 0),
	                        size(TitleWidth, TitleHeight),
				border_width(1),
				parent(RootWindow),
				mapped(true),
				callback(expose, [count(0)],
				         title(TitleWindow, LabelWidth,
					       Ascent))],
			       [font(Font)]).


create_drawing_window(DrawWindow, WindowWidth, WindowHeight, TitleHeight,
    	           RootWindow, RubberBandGC, DrawingGC) :-
    window_data(boundary_height, BoundaryHeight),
    window_data(draw_cursor, CursorName),
    DrawWinY is TitleHeight + BoundaryHeight,
    create_cursor(CursorName, DrawCursor),
    create_window(DrawWindow, [size(WindowWidth, WindowHeight),
	                         position(0, DrawWinY),
	                         border_width(0),
				 parent(RootWindow),
				 cursor(DrawCursor),
				 gc(DrawingGC),
				 mapped(true),
				 callback(expose, [count(0)],
				          refresh(DrawWindow, DrawingGC)),
                                 callback(button_press([1]),
				          [position(X, Y)],
					  start_point(X, Y)),
                                 callback(button_release([1]),
				          [position(X, Y)],
					  end_point(DrawWindow, RubberBandGC,
					            DrawingGC, X, Y)),
                                 callback(motion_notify([1]),
				          [position(X, Y)],
					  new_point(DrawWindow, RubberBandGC,
					            X, Y)),
				 callback(configure_notify, [size(W,H)],
					new_draw_size(DrawWindow, W, H))]).


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
			     callback(button_press, [], drawing_window(bye),
			              adios(RootWindow))]).



create_menu_window(MenuWindow, MenuWidth, MenuHeight, X, Y,
	           RootWindow, RootCursor, DrawWindow, DrawingGC, InvertingGC,
		   FgPixel, BgPixel) :-
    window_data(boundary_height, BoundaryHeight),
    window_data(horizontal_space, HorizontalSpace),
    window_data(vertical_space, VerticalSpace),
    window_data(menu_option_size, MenuOptionSize),
    MenuY is Y + BoundaryHeight,
    create_window(MenuWindow, [size(MenuWidth, MenuHeight),
	                       position(X, MenuY),
			       parent(RootWindow),
			       cursor(RootCursor),
			       border_width(1),
			       background(BgPixel),
			       mapped(true)]),
    FirstColumnX is HorizontalSpace,
    SecondColumnX is FirstColumnX + MenuOptionSize + 2*HorizontalSpace,
    FirstRowY is 2*VerticalSpace,
    RowInc is 2*VerticalSpace + MenuOptionSize,
    create_menu_options([[circle, ellipse],
	                 [square, rectangle],
			 [line, clear]],
%%			 [line_width(1), line_width(2)],
%%			 [line_width(3), line_width(4)],
%%			 [erase, move],
%%                       [],
%%			 [clear]],
			MenuWindow,
			[FirstColumnX, SecondColumnX], FirstRowY, RowInc,
			MenuOptionSize, DrawWindow, DrawingGC, InvertingGC,
			FgPixel, BgPixel).



create_menu_options([], _, _, _, _, _, _, _, _, _, _).
create_menu_options([RowOptions|Options], MenuWindow, Columns, Row, RowInc,
	            Size, DrawWindow, DrawingGC, InvertingGC,
		    FgPixel, BgPixel) :-
    create_menu_row(RowOptions, MenuWindow, Columns, Row, Size, DrawWindow,
	            DrawingGC, InvertingGC, FgPixel, BgPixel),
    NextRow is Row + RowInc,
    create_menu_options(Options, MenuWindow, Columns, NextRow, RowInc, Size,
	                DrawWindow, DrawingGC, InvertingGC, FgPixel, BgPixel).


create_menu_row([], _, _, _, _, _, _, _, _, _).
create_menu_row([Option|RowOptions], MenuWindow, [Column|Columns], Row, Size,
	        DrawWindow, DrawingGC, InvertingGC, FgPixel, BgPixel) :-
    Highlight = highlight(Option, Window, Size, Size, InvertingGC, FgPixel),
    Select    = select(Option, Window, Size, Size, X, Y, DrawWindow,
	               DrawingGC, BgPixel),
%%    Ignore    = unhighlight(Option, Window, Size, Size, DrawingGC, BgPixel),
    Redraw    = redraw(Option, Window, Size, Size),
%%    Button1   = buttons(down, _, _, _, _),
    create_window(Window, [size(Size, Size),
	                   position(Column, Row),
			   parent(MenuWindow),
			   border_width(1),
			   gc(DrawingGC),
			   background(BgPixel),
			   callback(button_press([1]), [], Highlight),
			   callback(button_release([1]), [position(X, Y)],
			            Select),
%%%%%		           callback(leave_notify, [state(Button1, _)], Ignore),
			   callback(expose, [count(0)], Redraw),
			   mapped(true)]),
    default_setup(Option, Window, InvertingGC, FgPixel),
    create_menu_row(RowOptions, MenuWindow, Columns, Row, Size, DrawWindow,
			DrawingGC, InvertingGC, FgPixel, BgPixel).



/***************************************************************************
 *                           Main Callbacks                                *
 ***************************************************************************/

adios(Window) :-
    destroy_window(Window).

start_point(X, Y) :-
    asserta(selected_region(X, Y, X, Y)).

end_point(DrawWindow, RubberBandGC, DrawingGC, X, Y) :-
    selected_region(SX, SY, LX, LY),
    draw_mode(Mode, _),
    draw_rubberband(Mode, DrawWindow, RubberBandGC, SX, SY, LX, LY),
    draw_figure(Mode, DrawWindow, DrawingGC, SX, SY, X, Y),
    retractall(selected_region(_, _, _, _)),
    get_window_attributes(DrawWindow, [size(DrawWidth,DrawHeight)]),
    RSX is SX/DrawWidth, RX is X/DrawWidth,
    RSY is SY/DrawHeight, RY is Y/DrawHeight,
    assertz(drawn_figure(Mode, info(SX,SY,X,Y), info(RSX,RSY,RX,RY))).

new_point(DrawWindow, RubberBandGC, X, Y) :-
    clause(selected_region(SX,SY,LX,LY), _, Ref),
    draw_mode(Mode, _),
    draw_rubberband(Mode, DrawWindow, RubberBandGC, SX, SY, LX, LY),
    draw_rubberband(Mode, DrawWindow, RubberBandGC, SX, SY, X, Y),
    flush,
    erase(Ref),
    asserta(selected_region(SX, SY, X, Y)).
    
title(TitleWindow, LabelWidth, Ascent) :-
    window_data(vertical_space, VerticalSpace),
    window_data(title, Label),
    get_window_attributes(TitleWindow, [width(TitleWidth)]),
    TitleX is (TitleWidth - LabelWidth) // 2,
    TitleY is VerticalSpace + Ascent,
    draw_string(TitleWindow, TitleX, TitleY, Label).

refresh(DrawWindow, DrawingGC) :-
    clear_window(DrawWindow),
    drawn_figure(Figure, info(X1,Y1,X2,Y2), _),
    draw_figure(Figure, DrawWindow, DrawingGC, X1, Y1, X2, Y2),
    fail.
refresh(_, _).

new_root_size(Root, NewWidth, NewHeight) :-
    drawing_window(Root, OldWidth, OldHeight, DrawWindow, OldDrawWidth,
	    OldDrawHeight, MenuWindow, TitleWindow, AdiosBox),
    (   NewWidth =:= OldWidth, NewHeight =:= OldHeight -> true	% do nothing
    ;   put_window_attributes(TitleWindow, [width(NewWidth)]),
	window_data(box_size, BoxSize),
	BoxX is NewWidth - 2*BoxSize,
	put_window_attributes(AdiosBox, [x(BoxX)]),
	DeltaW is NewWidth-OldWidth,
	DeltaH is NewHeight-OldHeight,
	DrawWidth is OldDrawWidth+DeltaW,
	DrawHeight is OldDrawHeight+DeltaH,
	put_window_attributes(DrawWindow, [size(DrawWidth,DrawHeight)]),
	put_window_attributes(MenuWindow, [x(DrawWidth),height(DrawHeight)])
    ).

new_draw_size(DrawWindow, NewWidth, NewHeight) :-
    drawing_window(_, _, _, DrawWindow, OldWidth, OldHeight, _, _, _),
    (   NewWidth =:= OldWidth, NewHeight =:= OldHeight -> true	% do nothing
    ;   scale_drawing(NewWidth, NewHeight)
    ).

scale_drawing(NewWidth, NewHeight) :-
    (   retract(drawn_figure(Mode,_,info(RX1,RY1,RX2,RY2))),
	X1 is integer(RX1*NewWidth), X2 is integer(RX2*NewWidth),
	Y1 is integer(RY1*NewHeight), Y2 is integer(RY2*NewHeight),
	assert(drawn_figure(Mode,info(X1,Y1,X2,Y2),info(RX1,RY1,RX2,RY2))),
	fail
    ;   true
    ).

/**************************************************************************
 *                          Menu Callbacks                                *
 **************************************************************************/

highlight(Option, Window, Width, Height, InvertingGC, FgPixel) :-
    not_selected(Option, _, _, _, _), 
    put_window_attributes(Window, [background(FgPixel), gc(InvertingGC)]),
    clear_window(Window),
    redraw(Option, Window, Width, Height).

select(clear, Window, Width, Height, X, Y, DrawWindow, DrawingGC, BgPixel) :-
    !,
    unhighlight(clear, Window, Width, Height, DrawingGC, BgPixel),
    (
      X =< Width, Y =< Height ->   
	clear_window(DrawWindow),
	retractall(drawn_figure(_, _, _))
    ;
	true
    ).
select(Option, Window, Width, Height, X, Y, _, DrawingGC, BgPixel) :-
    (
      X =< Width, Y =< Height ->
	not_selected(Option, Mode, ModeWindow, MSize, Ref),
        unhighlight(Mode, ModeWindow, MSize, MSize, DrawingGC, BgPixel),
	erase(Ref),
	asserta(draw_mode(Option, Window))
    ;
	unhighlight(Option, Window, Width, Height, DrawingGC, BgPixel)
    ).

redraw(circle, Window, Width, Height) :-
    LRX is Width - 5,
    LRY is Height - 5,
    draw_figure(circle, Window, 5, 5, LRX, LRY).
redraw(ellipse, Window, Width, Height) :-
    LRX is Width - 5,
    FigHeight is (Height-10)//2,
    Y is (Height-FigHeight)//2,
    LRY is Height-Y,
    draw_figure(ellipse, Window, 5, Y, LRX, LRY).
redraw(square, Window, Width, Height) :-
    LRX is Width - 5,
    LRY is Height - 5,
    draw_figure(square, Window, 5, 5, LRX, LRY).
redraw(rectangle, Window, Width, Height) :-
    LRX is Width - 5,
    FigHeight is (Height-10)//2,
    Y is (Height-FigHeight)//2,
    LRY is Height-Y,
    draw_figure(rectangle, Window, 5, Y, LRX, LRY).
redraw(line, Window, Width, Height) :-
    URX is Width - 5,
    LLY is Height - 5,
    draw_figure(line, Window, 5, LLY, URX, 5).
redraw(clear, Window, Width, Height) :-
    text_extents(Window, clear, LBearing, _, TextWidth, Ascent, Descent),
    TextHeight is Ascent + Descent,
    VS is (Height - TextHeight) // 2,
    HS is (Width - TextWidth) // 2,
    X is HS - LBearing,
    Y is VS + Ascent,
    draw_string(Window, X, Y, clear).
    

unhighlight(Option, Window, Width, Height, DrawingGC, BgPixel) :-
    put_window_attributes(Window, [background(BgPixel), gc(DrawingGC)]),
    clear_window(Window),
    redraw(Option, Window, Width, Height).


/**************************************************************************
 *                         Drawing the Figures                            *
 **************************************************************************/

draw_figure(Figure, Window, X1, Y1, X2, Y2) :-
    get_window_attributes(Window, [gc(GC)]),
    draw_figure(Figure, Window, GC, X1, Y1, X2, Y2).

draw_figure(rectangle, DrawWindow, GC, X1, Y1, X2, Y2) :-
    position(X1, X2, UX, Width),
    position(Y1, Y2, UY, Height),
    draw_rectangle(DrawWindow, GC, UX, UY, Width, Height).
draw_figure(square, DrawWindow, GC, X1, Y1, X2, Y2) :-
    position(X1, X2, AUX, Width),
    position(Y1, Y2, AUY, Height),
    min(Width, Height, Size),
    square_constraint(AUX, X1, Size, UX),
    square_constraint(AUY, Y1, Size, UY),
    draw_rectangle(DrawWindow, GC, UX, UY, Size, Size).
draw_figure(line, DrawWindow, GC, X1, Y1, X2, Y2) :-
    draw_line(DrawWindow, GC, X1, Y1, X2, Y2).
draw_figure(ellipse, DrawWindow, GC, X1, Y1, X2, Y2) :-
    position(X1, X2, UX, Width),
    position(Y1, Y2, UY, Height),
    draw_ellipse(DrawWindow, GC, UX, UY, Width, Height).
draw_figure(circle, DrawWindow, GC, X1, Y1, X2, Y2) :-
    position(X1, X2, AUX, Width),
    position(Y1, Y2, AUY, Height),
    min(Width, Height, Size),
    square_constraint(AUX, X1, Size, UX),
    square_constraint(AUY, Y1, Size, UY),
    draw_ellipse(DrawWindow, GC, UX, UY, Size, Size).


/*************************************************************************
 *                        Rubberbanding the Figures                      *
 *************************************************************************/

draw_rubberband(rectangle, DrawWindow, GC, X1, Y1, X2, Y2) :-
    position(X1, X2, UX, Width),
    position(Y1, Y2, UY, Height),
    draw_rectangle(DrawWindow, GC, UX, UY, Width, Height).
draw_rubberband(square, DrawWindow, GC, X1, Y1, X2, Y2) :-
    position(X1, X2, AUX, Width),
    position(Y1, Y2, AUY, Height),
    min(Width, Height, Size),
    square_constraint(AUX, X1, Size, UX),
    square_constraint(AUY, Y1, Size, UY),
    draw_rectangle(DrawWindow, GC, UX, UY, Size, Size).
draw_rubberband(line, DrawWindow, GC, X1, Y1, X2, Y2) :-
    draw_line(DrawWindow, GC, X1, Y1, X2, Y2).
draw_rubberband(ellipse, DrawWindow, GC, X1, Y1, X2, Y2) :-
    position(X1, X2, UX, Width),
    position(Y1, Y2, UY, Height),
    draw_rectangle(DrawWindow, GC, UX, UY, Width, Height).
draw_rubberband(circle, DrawWindow, GC, X1, Y1, X2, Y2) :-
    position(X1, X2, AUX, Width),
    position(Y1, Y2, AUY, Height),
    min(Width, Height, Size),
    square_constraint(AUX, X1, Size, UX),
    square_constraint(AUY, Y1, Size, UY),
    draw_rectangle(DrawWindow, GC, UX, UY, Size, Size).


/*************************************************************************
 *                      Creating GCs, loading Fonts, etc                 *
 *************************************************************************/

create_rubberband_gc(GC, Font) :-
    get_screen_attributes([black_pixel(FgPixel), white_pixel(BgPixel)]),
    xor(FgPixel, BgPixel, XorPixel),
    create_gc(GC, [foreground(XorPixel),
                   background(BgPixel),
		   function(xor),
		   %%                     plane_mask(Mask),
                   font(Font),
                   line_width(0)]).

create_drawing_gcs(NormalGC, InvertingGC, FgPixel, BgPixel, Font) :-
    get_screen_attributes([black_pixel(FgPixel), white_pixel(BgPixel)]),
    create_gc(NormalGC, [foreground(FgPixel),
	                 background(BgPixel),
			 function(copy),
			 %%		   plane_mask(Mask),
			 font(Font),
			 line_width(2)]),
    create_gc(InvertingGC, [foreground(BgPixel),
                            background(FgPixel),
			    function(copy),
			    %%		   plane_mask(Mask),
			    font(Font),
			    line_width(2)]).

/**************************************************************************
 *                  Random routines to maintain the state                 *
 **************************************************************************/

initialize_state :-   
    retractall(draw_state(_, _, _)).

default_setup(Option, Window, InvertingGC, FgPixel) :-
    window_data(default_mode, Option),
    !,
    put_window_attributes(Window, [background(FgPixel), gc(InvertingGC)]),
    asserta(draw_mode(Option, Window)).
default_setup(_, _, _, _).



/*************************************************************************
 *                            Utilities                                  *
 *************************************************************************/

find_font(FontDatum, Font) :-
    (
        window_data(FontDatum, FontSpec),
	current_font(FontSpec, FontName) ->
	    load_font(FontName, Font)
    ;
	otherwise ->
	    format('[ ~p: Cannot find requested fonts ]~n', draw),
	    fail
    ).

xor(A, B, C) :-
    C is (\(A) /\ B) \/ (A /\ \(B)).

max(A, B, Max) :-
    ( A >= B -> Max = A ; Max = B ).

min(A, B, Min) :-
    ( A < B -> Min = A ; Min = B).

position(A, B, Min, Delta) :-
    ( A >= B -> Min is B, Delta is A - B ; Min is A, Delta is B - A ).

square_constraint(Apparent, Start, Size, Real) :-
    ( Apparent < Start -> Real is Start - Size ; Real is Start ).

abs(Num, Absolute, Sign) :-
    ( Num < 0 -> Absolute is -Num, Sign = -1 ; Absolute = Num, Sign = 1 ).

not_selected(Option, Mode, Window, Size, Ref) :-
    clause(draw_mode(Mode, Window), _, Ref),
    window_data(menu_option_size, Size),
    Mode \== Option.



/***********************************************************************
 *                         Window Data                                 *
 ***********************************************************************/

window_data(titlefont, '*-helvetica-bold-r-*-140-*').
window_data(menufont, fixed).			 % font for menu text
window_data(width, 350).
window_data(height, 350).
window_data(title, 'ProXL Draw Demo').
window_data(horizontal_space, 5).
window_data(vertical_space, 5).
window_data(boundary_height, 3).
window_data(root_cursor, left_ptr).
window_data(box_size, 10).
window_data(draw_cursor, crosshair).
window_data(menu_option_size, 40).
window_data(default_mode, rectangle).
window_data(default_line, 2).

