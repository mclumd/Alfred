%   Package: pushbutton
%   Author : Peter Schachte & Luis Jenkins
%   Updated: Thu Sep 28 14:16:11 PDT 1989 by lej
%   Purpose: push button window, a cut-rate push button widget

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(pushbutton, [
	create_pushbutton/4,
	create_pushbutton/5,
	create_pushbutton/6,
	create_pushbutton/7
   ]).

:- meta_predicate
	create_pushbutton(-, +, 0, :),
	create_pushbutton(-, +, 0, :, +),
	create_pushbutton(-, +, 0, 0, 0, :),
	create_pushbutton(-, +, 0, 0, 0, :, +).

:- use_module(library(proxl)).
:- use_module(library(label)).
:- use_module(library(basics)).

sccs_id('"@(#)96/10/10 pushbutton.pl    21.1"').


%  create_pushbutton(-Window, +Label, +Action, +Attribs)
%  create_pushbutton(-Window, +Label, +Action, +Attribs, +Graphics_attribs)
%  create_pushbutton(-Window, +Label, +Action, +Hilite, +Lolite, +Attribs)
%  create_pushbutton(-Window, +Label, +Action, +Hilite, +Lolite, +Attribs,
%	+Graphics_attribs)
%  Window is a newly created push button window displaying Label.  Label should
%  be either an atom or a pixmap.  Attribs and Graphics_attribs specify
%  attributes for Window.  Action is the goal to execute when the push button
%  is released.  Hilite and Lolite, if specified, are the goals to execute
%  to show when the push button is pressed and released, respectively.  The
%  default is to exchange the foreground and background colors.

create_pushbutton(Window, Label, Action, Attribs) :-
	create_pushbutton(Window, Label, Action, invert(Window),
		invert(Window), Attribs, []).

create_pushbutton(Window, Label, Action, Attribs, Graphics_attribs) :-
	create_pushbutton(Window, Label, Action, pushbutton:invert(Window),
		pushbutton:invert(Window), Attribs, Graphics_attribs).

create_pushbutton(Window, Label, Action, Hilite, Lolite, Attribs) :-
	create_pushbutton(Window, Label, Action, Hilite, Lolite, Attribs, []).

create_pushbutton(Window, Label, Action, Hilite, Lolite, Attribs,
		Graphics_attribs) :-
	split_meta_variable(Action, M, Act),
	split_meta_variable(Attribs, Mod, Attrs),
	pushbutton_callback(Act, M, Label, Window, Lolite, ButtonRelease),
	create_label(Window, Label, Mod:[
		callback(button_press, [],
		         button(Label, press), Hilite),
		ButtonRelease,
		callback(enter_notify, [state(B, _)],
		         button(Label, enter), 
                         ( buttons_mask(B, 0) -> true ; Lolite )),
		callback(leave_notify, [state(B, _)],
                         button(Label, leave),
			 ( buttons_mask(B,0) -> true ; Lolite ))
		| Attrs], Graphics_attribs).


%  invert(+Window)
%  Swap the foreground and background colors in Window.

invert(Window) :-
	get_graphics_attributes(Window, [foreground(F),background(B),
		function(Fn)]),
	X is ((F /\ \(B)) \/ (\(F) /\ B)),
	put_graphics_attributes(Window, [foreground(X),function(xor)]),
	fill_rectangle(Window, 0, 0, 32767, 32767),
	put_graphics_attributes(Window, [foreground(F),function(Fn)]).



%
% pushbutton_callback(+Action, +Mod, +Label, +Lolite, -ButtonReleaseCallback)
% Figure out a proper callback
%
pushbutton_callback(action(Attr, Exit, Context, Goal), Mod, _Label, Win,
	            Lolite,
	            callback(button_release, NewAttr, Exit, Context, 
		             ( pushbutton:check_button_release(Win, X, Y) ->
				 Lolite, Mod:Goal
			     ; true ))) :-
        !,
	add_position(Attr, X, Y, NewAttr).
pushbutton_callback(action(Attr, Exit, Goal), Mod, _Label, Win, Lolite,
	            callback(button_release, NewAttr, Exit,
		             ( pushbutton:check_button_release(Win, X, Y) ->
				 Lolite, Mod:Goal
			     ; true ))) :-
	!,
	add_position(Attr, X, Y, NewAttr).
pushbutton_callback(action(Attr, Mod:Goal), Mod, Label, Win, Lolite,
	            callback(button_release, NewAttr, button(Label, release),
		             ( pushbutton:check_button_release(Win, X, Y) ->
				 Lolite, Mod:Goal
			     ; true ))) :-
	!,
        add_position(Attr, X, Y, NewAttr).
pushbutton_callback(Goal, Mod, Label, Win, Lolite,
	            callback(button_release, [position(X, Y)],
		             button(Label, release),
		             ( pushbutton:check_button_release(Win, X, Y) ->
				 Lolite, Mod:Goal
			     ; true ))).


%
% check_button_release(+Window, +X, +Y)
% Make sure that the button was released in the Window and not outside
%
check_button_release(Window, X, Y) :-
    get_window_attributes(Window, [size(W, H)]),
    X >= 0, X =< W,
    Y >= 0, Y =< H.


%
% add_position(Attr, X, Y, NewAttr)
% Make sure we ask for the position
%
add_position([], X, Y, [position(X, Y)]) :-
	!.
add_position([x(X)|Rest], X, Y, New) :-
	!,
        add_position(Rest, X, Y, New).
add_position([y(Y)|Rest], X, Y, New) :-
	!,
	add_position(Rest, X, Y, New).
add_position([position(X, Y)|Rest], X, Y, New) :-
	!,
	add_position(Rest, X, Y, New).
add_position([R|Rest], X, Y, [R|New]) :-
	add_position(Rest, X, Y, New).

