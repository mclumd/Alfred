%   Package: browser
%   Author : Peter Schachte
%   Updated: 06/08/94
%   Purpose: visual browser for ProXL objects

%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

:- module(browser, [
        browser/0,
	browse/1
   ]).

:- use_module(library(proxl)).
:- use_module(library(basics)).
:- use_module(library(pushbutton)).

sccs_id('"@(#)94/06/08 browser.pl    20.1"').


:- dynamic
	browser_font_names/2,		% not volatile
	browser_font_cache/2,
	browser_cursor_cache/2,
	browser_window/9,
	browser_highlighted/5.
:- volatile
	browser_font_cache/2,
	browser_cursor_cache/2,
	browser_window/9,
	browser_highlighted/5.

browser_font_names('*-helvetica-medium-r-*-12-*','*-helvetica-bold-r-*-12-*').



user:runtime_entry(start) :-
	browser.


%  browser
%  pop up a push button window that allows you to select another window,
%  and then pops a browser on that window

browser :-
	create_pushbutton(_, 'Select window to browse', select_window,
		[mapped(true), property('WM_HINTS',
			wm_hints(false,normal,none,none,none,none,none))]),
	handle_events.



%  select_window(Root)
%  allows user to click a window, and then pops up a browser on that
%  window.

select_window :-
	event_list_mask([button_press], Events),
	get_screen_attributes([root(Root)]),
	cursor_cache_lookup(crosshair, Cursor),
	grab_pointer(Root, false, Events, sync, async, none, Cursor,
		current_time, success),
	allow_events(sync_pointer),
	window_event(Root, Events, _, _),
	ungrab_pointer,
	get_pointer_attributes([deepest(W,_,_)]),
	browse_object(W).
	


%  browse(+Obj)
%  Obj is a ProXL object that has properties (ie, a window, gc, font, pixmap,
%  display or screen).  A window is brought up that display Obj's current
%  attributes.  browse/1 terminates as soon as the last browser window
%  is destroyed.
%  
%  In the browser window display, browsable ProXL objects are shown in boldface.
%  If one of these is selected with the left mouse button, a browser will
%  be brought up showing this object.  Any browser window may be refreshed,
%  that is, forced to reread the object's attributes, by pressing the 'r'
%  key on the keyboard; a browser window is destroyed by pressing 'q'.

browse(Obj) :-
	browse_object(Obj),
	handle_events(browser_finished).


%  browse_object(+Obj)
%  Does the bulk of the work of browse/1, but it doesn't wait around, it
%  returns immediately.  Used for recursive browses.

browse_object(Obj) :-
	(   valid_gc(Obj) -> Obj = gc(Id)		% gross HACK!!!!
	;   valid_screen(Obj) -> Obj = screen(Id)	% gross HACK!!!!
	;   valid_display(Obj) -> Obj = display(Id)	% gross HACK!!!!
	;   proxl_xlib(Obj, Type, Id)
	),
	(   browser_window(Id, Window, _, _, _, _, _, _, _) ->
		put_window_attributes(Window, [mapped(true)]),
		restack_window(Window, top)
	;   object_type(Obj, Type),
	    proxl_object_term_string(Obj, Type, Chars),
	    atom_chars(Icontitle, Chars),
	    append("Browser: ", Chars, Titlechars),
	    atom_chars(Title, Titlechars),
	    browser_fonts(Font1, Font2),
	    bagof(A, get_attribute_term(Type, Obj, Font1, Font2, A), L),
	    get_font_attributes(Font1, [height(Fontheight), ascent(Ascent)]),
	    length(L, Lines),
	    Height is (Fontheight+1)*Lines,
	    browser_width(L, 0, Width0),
	    (   Width0 > 500 -> Width = 500	% arbitrary maximum width
	    ;   Width = Width0
	    ),
	    create_window(Window, [
		    size(Width,Height), border_width(2), mapped(true),
		    bit_gravity(north_west), property('WM_NAME', Title),
		    property('WM_ICON_NAME', Icontitle),
		    callback(expose, [count(0)], browser_expose(Window,Id)),
		    callback(button_press([1]), [position(X,Y)],
				    browser_button(Window,Id,X,Y,down)),
		    callback(button_release([1]), [position(X,Y)],
				    browser_button(Window,Id,X,Y,up)),
		    callback(motion_notify_hint([1]), [],
				    browser_button(Window,Id,0,0,hint)),
		    callback(key_press, [key(K)], Exit,
				    browser_key(K,Window,Id,Exit))
	    ], [font(Font1)]),
	    assert(browser_window(Id, Window, Obj, Type, Font1, Font2, L,
		    Ascent, Fontheight))
	).
	


%  object_type(+Obj, -Type)
%  Obj is a browsable ProXL object of type Type.

object_type(Obj, Type) :-
	(   valid_window(Obj)	-> Type = window
	;   valid_gc(Obj)	-> Type = gc
	;   valid_font(Obj)	-> Type = font
	;   valid_pixmap(Obj)	-> Type = pixmap
	;   valid_display(Obj)	-> Type = display
	;   valid_screen(Obj)	-> Type = screen
	).


%  browser_fonts(-F1, -F2)
%  F1 is the font to use for the bulk of a browser window; F2 is the font
%  to use for showing browsable objects.

browser_fonts(F1, F2) :-
    (
        browser_font_names(Roman, Bold),
	font_cache_lookup(Roman, F1),
	font_cache_lookup(Bold, F2) ->
	  true
    ;
	otherwise ->
	    format('[ Can not find requested fonts ]~n', []),
	    fail
    ).
	
%  font_cache_lookup(+Spec, -Font)
%  Font is a font that matches Spec.  Uses a cache to avoid reloading fonts.

font_cache_lookup(Spec, Font) :-
	(   browser_font_cache(Spec, Font) -> 
		true
	;   current_font(Spec, Name) ->
		load_font(Name, Font),
		assert(browser_font_cache(Spec,Font))
	).


%  cursor_cache_lookup(+Spec, -Cursor)
%  Lookup a cursor.  Uses a cache to avoid reloading the cursor.

cursor_cache_lookup(Spec, Cursor) :-
	(   browser_cursor_cache(Spec, Cursor) -> true
	;   create_cursor(Spec, Cursor),
	    assert(browser_cursor_cache(Spec, Cursor))
	).

%  get_attribute_term(+Type, +Obj, +Font1, +Font2, -Attrib)
%  Obj is a object of Type, and Font1 and Font2 are the fonts to be used
%  to display Obj.  Attrib is an attrib(Texts, Browsables, Width) term
%  describing a single attribute of Obj, where Texts is a list of textitem
%  terms to be displayed to show the attribute, Browsables is a list of
%  range(Term,Atom,Left,Right) terms, and Width is the pixel width of this
%  attribute.  The range/4 terms specify a selectable part of the attribute.
%  Term is an actual browsable part of an attribute, Atom is the printed
%  form of it as shown in the display, and Left and Right are the horizontal
%  bounds of the browsable part.

get_attribute_term(Type, Obj, Font1, Font2, attrib(Texts,Browsables,Width)) :-
	get_individual_attribute(Type, Obj, Attrib),
	attribute_detail(Attrib, Font1, Font2, Texts, Browsables, Width).


%  get_individual_attribute(+Type, +Obj, -Attrib)
%  Attrib is an attribute of Obj, which is a browsable object of Type.

get_individual_attribute(window, Window, Attrib) :-
	window_attribute(Attrib),
	get_window_attributes(Window, [Attrib]),
	(   Attrib=callback(E,_,_,_,_) -> nonvar(E)
	;   true
	).
get_individual_attribute(gc, Gc, Attrib) :-
	get_graphics_attributes(Gc, [Attrib]).
get_individual_attribute(font, Font, Attrib) :-
	font_attribute(Attrib),
	get_font_attributes(Font, [Attrib]).
get_individual_attribute(pixmap, Pixmap, Attrib) :-
	get_pixmap_attributes(Pixmap, [Attrib]).
get_individual_attribute(display, Display, Attrib) :-
	get_display_attributes(Display, [Attrib]).
get_individual_attribute(screen, Screen, Attrib) :-
	get_screen_attributes(Screen, [Attrib]).

window_attribute(parent(_)).
window_attribute(position(_,_)).
window_attribute(size(_,_)).
window_attribute(depth(_)).
window_attribute(border_width(_)).
window_attribute(class(_)).
window_attribute(visual(_)).
window_attribute(bit_gravity(_)).
window_attribute(win_gravity(_)).
window_attribute(backing_store(_)).
window_attribute(backing_planes(_)).
window_attribute(backing_pixel(_)).
window_attribute(save_under(_)).
window_attribute(event_mask(_)).
window_attribute(do_not_propagate_mask(_)).
window_attribute(override_redirect(_)).
window_attribute(colormap(_)).
window_attribute(mapped(_)).
window_attribute(gc(_)).
window_attribute(callback(_,_,_,_,_)).


font_attribute(direction(_)).
font_attribute(min_char(_)).
font_attribute(max_char(_)).
font_attribute(min_charset(_)).
font_attribute(max_charset(_)).
font_attribute(all_chars_exist(_)).
font_attribute(default_char(_)).
font_attribute(ascent(_)).
font_attribute(descent(_)).
font_attribute(height(_)).
font_attribute(max_lbearing(_)).
font_attribute(max_rbearing(_)).
font_attribute(max_width(_)).
font_attribute(max_ascent(_)).
font_attribute(max_descent(_)).
font_attribute(max_attribute_bits(_)).
font_attribute(min_lbearing(_)).
font_attribute(min_rbearing(_)).
font_attribute(min_width(_)).
font_attribute(min_ascent(_)).
font_attribute(min_descent(_)).
font_attribute(min_attribute_bits(_)).
font_attribute(property(_,_)).


%  attribute_detail(+Term, +Font1, +Font2, -Texts, -Objs, -Width)
%  Term is an attribute term to be displayed in Font1 and Font2.
%  Texts is the list of textitem terms used to display it, Objs is
%  the list of range/4 terms describing browsable subterms, and Width
%  is the pixel width of this term.

attribute_detail(Term, Font1, Font2, Texts, Objs, Width) :-
	numbervars(Term, 0, _),
	term_textitems(Term, Font1, Font2, [], Texts0, [], Objs),
	squeeze_textitems(Texts0, Texts1),
	atomize_textitems(Texts1, Texts),
	find_object_positions(Texts, 2, Width, Objs).

%  proxl_object_term_string(+Term, +Type, -Chars)
%  Chars is a chars (list of character codes) spelling the representation
%  of Term, which is a browsable ProXL object object of type.

proxl_object_term_string(Term, Type, Chars) :-
		atom_chars(Type, Chars1),
		arg(1, Term, Number),
		number_chars(Number, Chars2),
		append(Chars2, ")", Chars3),
		append(Chars1, [0'(|Chars3], Chars).


%  term_textitems(+Term, +F1, +F2, +L0, -L, +Objs0, -Objs)
%  L is a list of textitem terms describing Term, followed by L0.  Obj is
%  the list of range/4 terms for Term, followed by Objs0.  F1 and F2 are
%  the fonts to use.  The proc makes no effort to construct a minimal
%  list of textitem terms, that is done as a separate pass.  In fact,
%  each of these textitem terms contains a chars rather than an atom, since
%  it'll be easier to append to its neighbors later.

term_textitems(Term, F1, F2, L0, L, Objs0, Objs) :-
	(   Term = '$VAR'(N) ->
		Objs = Objs0,
		Ch is N+0'A,
		L = [textitem([Ch],0,F1)|L0]
	;   object_type(Term, Name) ->
		L = [textitem(Chars,0,F2)|L0],
		Objs = [range(Term,Atom,_,_)|Objs0],
		proxl_object_term_string(Term, Name, Chars),
		atom_chars(Atom, Chars)
	;   number(Term) ->
		L = [textitem(Chars,0,F1)|L0],
		Objs = Objs0,
		number_chars(Term, Chars)
	;   atom(Term) ->
		L = [textitem(Chars,0,F1)|L0],
		Objs = Objs0,
		atom_chars(Term, Chars)
	;   Term = [H|T] ->
		L = [textitem("[",0,F1)|L1],
		term_textitems(H, F1, F2, L2, L1, Objs0, Objs1),
		list_tail_textitems(T, F1, F2, L0, L2,
			Objs1, Objs)
	;   functor(Term, Name, Arity),
	    atom_chars(Name, Chars1),
	    append(Chars1, [0'(], Chars),
	    L = [textitem(Chars,0,F1)|L1],
	    term_textitems_args(Arity, Term, F1, F2,
		    [textitem(")",0,F1)|L0], L1, Objs0, Objs)
	).

%  term_textitems_args(+N, +Term, +F1, +F2, +L0, -L, +Objs0, -Objs)
%  L and Objs are the lists of textitem and range terms describing
%  the arguments of Term from 1 to N, followed by L0 and Objs0,
%  respectively.  F1 and F2 are the fonts.

term_textitems_args(N, Term, F1, F2, L0, L, Objs0, Objs) :-
	(   N =:= 0 ->
		L0 = L,
		Objs = Objs0
	;   arg(N, Term, Subterm),
	    term_textitems(Subterm, F1, F2, L0, L1, Objs0, Objs1),
	    (   N =:= 1 -> L2 = L1
	    ;   L2 = [textitem(", ",0,F1)|L1]
	    ),
	    N1 is N-1,
	    term_textitems_args(N1, Term, F1, F2, L2, L, Objs1, Objs)
	).


%  list_tail_textitems(+Tail, +F1, +F2, +L0, -L, +Objs0, -Objs)
%  L and Objs are the lists of textitem and range terms describing
%  the list tail Tail, followed by L0 and Objs0,
%  respectively.  F1 and F2 are the fonts.

list_tail_textitems(Tail, F1, F2, L0, L, Objs0, Objs) :-
	(   Tail == [] ->
		L = [textitem("]",0,F1)|L0],
		Objs = Objs0
	;   Tail = [Next|Tail1] ->
		L = [textitem(",",0,F1)|L1],
		term_textitems(Next, F1, F2, L2, L1, Objs0, Objs1),
		list_tail_textitems(Tail1, F1, F2, L0, L2, Objs1, Objs)
	;   L = [textitem("|",0,F1)|L1],
	    term_textitems(Tail, F1, F2, [textitem("]",0,F1)|L0], L1,
		    Objs0, Objs1)
	).


%  squeeze_textitems(+L0, -L)
%  L is a compressed version of L0, which is a list of textitem/3 terms.
%  We put together adjacent textitems using the same font, where the
%  offset between them is 0.  We also assume that all the textitems
%  string args are chars, not atoms.
%  
%  This proc is not general, but could be made general with a bit of work.
%  
%  This proc is not tail recursive, even though it could be, since it is
%  more efficient to append the chars starting from the end of the list.

squeeze_textitems([], []).
squeeze_textitems([Textitem|L0], L) :-
	squeeze_textitems(L0, L1),
	squeeze_single(Textitem, L1, L).


%  squeeze_single(+Textitem, +List0, -List)
%  List is Textitem squozen onto the front of List0.  If possible List
%  will be the same length as List0, else one element longer.

squeeze_single(textitem(Str1,Offset,Font),[textitem(Str2,0,Font)|L],
		[textitem(Str,Offset,Font)|L]) :-
	!,
	append(Str1, Str2, Str).
squeeze_single(Textitem, List, [Textitem|List]).


%  atomize_textitems(List0, List)
%  List0 is a list of textitem/3 terms.  List is the same, except that
%  all the string arguments (the first arg) are atoms.  This could be
%  made general if it handled textitem/2 terms, but this prog doesn't
%  need them.

atomize_textitems([], []).
atomize_textitems([textitem(A,O,F)|L0], [textitem(A,O,F)|L]) :-
	atom(A),
	!,
	atomize_textitems(L0, L).
atomize_textitems([textitem(S,O,F)|L0], [textitem(A,O,F)|L]) :-
	name(A,S),
	atomize_textitems(L0, L).


%  find_object_positions(-Texts, +X0, -X, +Objs)
%  X is X0 plus the pixel width of the textitems in Texts.  Objs is a
%  list of range/4 terms which has is Left and Right args unbound.
%  As a side effect of this proc, these args will be bound.  Yeah, I
%  know, but it works.

find_object_positions([], X, X, _).
find_object_positions([textitem(S,Offset,F)|Texts], X0, X, Objs) :-
	(   memberchk(range(_,S,X0,X1), Objs) -> true
	;   true
	),
	text_width(F, S, Width),
	X1 is X0+Offset+Width,
	find_object_positions(Texts, X1, X, Objs).


%  browser_width(+Attribs, +Width0, -Width)
%  Width is the larger of Width0 and the width of the widest attrib on
%  Attribs.

browser_width([], Width, Width).
browser_width([attrib(_,_,Width1)|List], Width0, Width) :-
	max(Width0, Width1, Width2),
	browser_width(List, Width2, Width).


%  max(+X, +Y, -Z)
%  Z is the greater of X and Y.
max(X, Y, Z) :-
	(   X < Y -> Z = Y
	;   Z = X
	).

%  nth(+N, +L, -E)
%  E is the Nth element of L.

nth(0, [E|_], E) :- !.
nth(N, [_|L], E) :-
	N1 is N-1,
	nth(N1, L, E).


% ----------------------------------------------------------------
% 			Callback handling
% ----------------------------------------------------------------

%  browser_expose(+Window, +Id)
%  repaint Window, which is the browser window with id Id.

browser_expose(Window, Id) :-
	browser_window(Id, _, _, _, _, _, Items, Ascent, Lineheight),
	browser_body(Items, Window, Ascent, Lineheight, Lineheight),
	(   browser_highlighted(Win, L, T, W, H) ->
		invert_region(Win, L, T, W, H)
	;   true
	).

%  browser_body(+Attribs, +Window, +Baseline, +Under, +Lineheight)
%  Display in Window the attributes listed in Attribs with the first line's
%  baseline at Baseline (pixels from top of Window), and with a line under
%  it at Under pixels.  Each line is Lineheight pixels high, plus 1 for the
%  underline.

browser_body([], _, _, _, _).
browser_body([attrib(Textitems,_,_)|L], Window, Baseline, Under, Lineheight) :-
	draw_line(Window, 0, Under, 10000, Under),
	draw_text(Window, 2, Baseline, Textitems),
	Under2 is Under+Lineheight+1,
	Baseline2 is Baseline+Lineheight+1,
	browser_body(L, Window, Baseline2, Under2, Lineheight).


%  browser_button(+Window, +Id, +X0, +Y0, +Transition)
%  Handle all mouse interaction with a browser window.  Either a mouse
%  button went down, or up, or the mouse moved with a button down, as
%  specified by Transition (either up, down, or hint).  Window and Id
%  reflect the browser, and X0 and Y0 are the position at which the
%  mouse event happened, unless Transition == hint, in which case we
%  must query the server to find out where the mouse is.

browser_button(Window, Id, X0, Y0, Transition) :-
        browser_window(Id, _, _, _, _, _, Items, _, Lineheight),
        (   Transition == hint ->
        	get_pointer_attributes([window(Window,X,Y)])
	;   X = X0,
	    Y = Y0
	),
	Line is Y//(Lineheight+1),
	nth(Line, Items, attrib(_,Browsables,_)),
	Top is Line*(Lineheight+1),
	(   member(range(Obj, _, Left, Right), Browsables),
	    X >= Left,
	    X =< Right ->
		Width is Right-Left,
		browser_highlight(Window, Left, Top, Width, Lineheight),
		(   Transition == up ->
			browser_lowlight,
			browse_object(Obj)
		;   true
		)
	;   browser_lowlight
	).


%  browser_highlight(+Window, +Left, +Top, +Width, +Height)
%  Highlight the region of Window specified by Left, Top, Width, and Height,
%  keeping track of what part of Window is highlighted.  We also lowlight
%  any previously highlighted region.

browser_highlight(Window, Left, Top, Width, Height) :-
	(   clause(browser_highlighted(Win, L, T, W, H), true, Ref) ->
		(   Win == Window,
		    L =:= Left,
		    T =:= Top,
		    W =:= Width,
		    H =:= Height -> true
		;   invert_region(Win, L, T, W, H),
		    erase(Ref),
		    invert_region(Window, Left, Top, Width, Height),
		    assert(browser_highlighted(Win, Left, Top,
			    Width, Height))
		)
	;   invert_region(Window, Left, Top, Width, Height),
	    assert(browser_highlighted(Window, Left, Top, Width, Height))
	).


%  browser_lowlight
%  Lowlight any currently highlighted browser region.

browser_lowlight :-
	(   retract(browser_highlighted(Win, L, T, W, H)) ->
		invert_region(Win, L, T, W, H)
	;   true
	).
	

%  invert_region(+Window, +Left, +Top, +Width, +Height)
%  Invert (reverse video, swapping black and white) the region of Window
%  specified by Left, Top, Width, and Height.  This is a generally
%  useful procedure.  Notice that the complication of taking the
%  xor of black and white, and xoring with that, is done in order to
%  work on color screens.

invert_region(Window, Left, Top, Width, Height) :-
	get_screen_attributes(Window, [black_pixel(B), white_pixel(W)]),
	Fg is (B /\ \(W)) \/ (\(B) /\ W),	% Fg is B xor F
	put_graphics_attributes(Window, [foreground(Fg), function(xor)]),
	fill_rectangle(Window, Left, Top, Width, Height),
	put_graphics_attributes(Window, [foreground(B), function(copy)]).

%  browser_key(+Key, +Window, +Id, -Exit)
%  Key has been pressed in Window, a browser window with Id number.
%  Exit is browser_finished or browser_still_going on completion,
%  depending on whether this keypress killed the last browser window.
%  Windows are killed by pressing q in them, and are refreshed by pressing
%  r.

browser_key(q, Window, Id, Exit) :-
	destroy_window(Window),
	retractall(browser_window(Id, _, _, _, _, _, _, _, _)),
	retractall(browser_highlighted(Window, _, _, _, _)),
	(   browser_window(_, _, _, _, _, _, _, _, _) ->
		Exit = browser_still_going
	;   Exit = browser_finished
	).
browser_key(r, Window, Id, browser_still_going) :-
	cursor_cache_lookup(watch, Cursor),
	put_window_attributes(Window, [cursor(Cursor)]),
	flush,
	retractall(browser_highlighted(Window, _, _, _, _)),
	retract(browser_window(Id, Win, X, Type, Font1, Font2, _,
			Ascent, Fontheight)),
	bagof(A, get_attribute_term(Type, X, Font1, Font2, A), L),
	assert(browser_window(Id, Win, X, Type, Font1, Font2, L,
			Ascent, Fontheight)),
	clear_window(Window),
	browser_expose(Window, Id),
	put_window_attributes(Window, [cursor(none)]).


