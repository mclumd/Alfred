%   Package: label
%   Author : Peter Schachte
%   Updated: Thu Sep 28 14:16:11 PDT 1989 by lej
%   Purpose: label window, a cut-rate label widget

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(label, [
	create_label/3,
	create_label/4,
	change_label/2,
	change_label_and_size/2
   ]).

:- meta_predicate
	create_label(-, +, :),
	create_label(-, +, :, +).

:- use_module(library(proxl)).
:- use_module(library(basics)).

sccs_id('"@(#)96/10/10 label.pl    21.1"').


%  create_label(-Window, +Label, +Attribs)
%  create_label(-Window, +Label, +Attribs, +Graphics_attribs)
%  Window is a newly created label window displaying Label.  Label should
%  be either an atom or a pixmap.  Attribs and Graphics_attribs specify
%  attributes for Window.

create_label(Window, Label, Attribs) :-
	create_label(Window, Label, Attribs, []).

create_label(Window, Label, Attributes, Graphics_attribs) :-
	split_meta_variable(Attributes, Mod, Attribs),
	(   memberchk(font(Font), Graphics_attribs) -> true
	;   (   memberchk(parent(Parent), Attribs) ->
		valid_screenable(Parent, Screen)
	    ;   default_screen(Screen, Screen)
	    ),
	    get_screen_attributes(Screen, [root(Root)]),
	    get_graphics_attributes(Root, [font(Font)])
	),
	label_callback_size(Label, Window, Font, Callback, Size),
	create_window(Window, Mod:[Callback,Size|Attribs], Graphics_attribs).


%  change_label(+Window, +New_label)
%  change_label_and_size(+Window, +New_label)
%  Window is a label window which is to have its label changed to New_label.
%  change_label_and_size/2 will also resize window to neatly fit New_label.

change_label(Window, New_label) :-
	get_graphics_attributes(Window, [font(Font)]),
	label_callback_size(New_label, Window, Font, Callback, _),
	put_window_attributes(Window, [Callback]).

change_label_and_size(Window, New_label) :-
	get_graphics_attributes(Window, [font(Font)]),
	label_callback_size(New_label, Window, Font, Callback, Size),
	put_window_attributes(Window, [Callback,Size]).


%  label_callback_size(+Label, +Window, +Font, -Callback, -Size)
%  Callback is the expose callback attribute to refresh Window, which
%  contains Label, and Size is appropriate size for the label, given
%  that it is displayed in Font.  Font is ignored if Label is a pixmap.

label_callback_size(Label, Window, Font,
	            callback(expose, [count(0)], label(Label, expose), Goal),
		    size(W,H)) :-
	(   atom(Label) ->
		get_font_attributes(Font, [ascent(A), height(H1)]),
		text_width(Font, Label, W1),
		Goal = label:center_text(Window, Label, W1, H1, A),
		W is W1 + 4,
		H is H1 + 4
	;   valid_pixmap(Label) ->
		get_pixmap_attributes(Label, [size(W,H)]),
		Goal = label:center_pixmap(Window, Label, W, H)
	;   format('[Label:  invalid label ~q]~n', [Label]),
	    fail
	).

%  center_text(+Window, +Label, +Lwidth, +Lheight, +Ascent)
%  Center Label, an atom, in Window.  Label's width and height are Lwidth
%  and Lheight, and its ascent is Ascent.

center_text(Window, Label, Lwidth, Lheight, Ascent) :-
	get_window_attributes(Window, [size(W,H)]),
	X is (W-Lwidth)//2,
	Y is (H-Lheight)//2 + Ascent,
	clear_window(Window),
	draw_string(Window, X, Y, Label).


%  center_pixmap(+Window, +Pixmap, +Pwidth, +Pheight)
%  Center Pixmap in Window.  Pixmap's width and height are Pwidth and Pheight.

center_pixmap(Window, Pixmap, Pwidth, Pheight) :-
	get_window_attributes(Window, [size(W,H)]),
	X is (W-Pwidth)//2,
	Y is (H-Pheight)//2,
	clear_window(Window),
	copy_area(Window, X, Y, Pixmap, 0, 0, Pwidth, Pheight).
