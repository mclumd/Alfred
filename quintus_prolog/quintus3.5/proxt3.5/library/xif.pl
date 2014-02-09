/*  SCCS   : @(#)xif.pl	18.1 08/31/92
    File   : xif.pl
    Authors: Luis Jenkins and Dimitar Bojantchev
    Purpose: Compatibility Library for using ProXT and ProXL together
    Origin : 27 Aug 90

	+--------------------------------------------------------+
	|							 |
	|  Copyright (C) 1990					 |
	|  Quintus Computer Systems Inc.  All rights reserved.	 |
	|							 |
	+--------------------------------------------------------+
*/


:- module(xif, [
        xif_main_loop/0,
        xif_main_loop/1,
        xif_main_loop/2,
        xif_main_loop/3,
	xif_initialize/3,
	widget_to_screen/2,
	widget_to_display/2,
	widget_window/2
    ]).


:- use_module(library(proxt), [
        xtNextEvent/1,
        xtDispatchEvent/1,
	xtInitialize/3,
	xtDisplay/2,
	xtScreen/2,
	xtWindow/2,
	xtWindowToWidget/3
    ]).
:- use_module(library(proxl), [
        default_display/1,
	default_screen/2,
        dispatch_event/1,
        dispatch_event/2,
        dispatch_event/3,
	valid_window/1,
	ensure_valid_displayable/3,
	flush/1,
	display_xdisplay/2,
	screen_xscreen/2,
	proxl_xlib/4,
	current_window/2
    ]).


/*
 * xif_main_loop/[0, 1, 2, 3]
 *
 * These predicates provide functionality similar to ProXL's
 * handle_events/[0, 1, 2, 3] predicates, but handle both Xt 
 * and raw X11 events.
 *
 * These predicates should be used whenever ProXT and ProXL
 * are used together, to guarantee that events will be dispatched
 * properly to both Widgets and Windows.
 *
 * These predicates are provided both as a convenience and as an
 * example of what the main loop in a combined ProXT and ProXL
 * application needs to do.
 */
xif_main_loop :-
    Goal = xif_main_loop,
    default_display(Display),
    do_handle_xif_events(Display, never_exit, _, Goal).

xif_main_loop(ExitCond) :-
    Goal = xif_main_loop(ExitCond),
    default_display(Display),
    do_handle_xif_events(Display, ExitCond, _, Goal).

xif_main_loop(ExitCond, Context) :-
    Goal = xif_main_loop(ExitCond, Context),
    default_display(Display),
    do_handle_xif_events(Display, ExitCond, Context, Goal).

xif_main_loop(Displayable, ExitCond, Context) :-
    Goal = xif_main_loop(Displayable, ExitCond, Context),
    do_handle_xif_events(Displayable, ExitCond, Context, Goal).


/*
 * do_handle_xif_events/4 implements the event handling loop
 *
 * xtNextEvent/1 will give back the next X11 event.
 * xtDispatchEvent/1 handles the event if a ProXT Widget wants it.
 * dispatch_event/3 handles the event if a ProXL Window wants it, and
 * succeeds when the ExitCond is satisfied (see handle_events/4).
 */
do_handle_xif_events(Displayable, ExitCond, Context, Goal) :-
    ensure_valid_displayable(Displayable, Display, Goal),
    repeat,
	xtNextEvent(XtEvent),                       % X11 Event
	xtDispatchEvent(XtEvent),                   % A ProXT Event?
	XtEvent = xtevent(Addr),
	XEvent = xevent(Addr),
	% NB:  dispatch_event/3 fails unless this is an exit condition
	dispatch_event(XEvent, ExitCond, Context), % A ProXL Event?
    !,
    flush(Display).


/*
 * xif_initialize(+Name, +Class, -Shell)
 *    Name: String
 *    Class: String
 *
 * xif_initialize/3 should be called when ProXT and ProXL are used together,
 * instead of xtInitilize/3.
 *
 * This predicate provides similar functionality to xtInitialize/3, but
 * also sets ProXL's default screen, which is _essential_ to ensure that
 * both ProXL and ProXT use the same display and screen.
 */
xif_initialize(Name, Class, Shell) :-
    xtInitialize(Name, Class, Shell),
    widget_to_screen(Shell, Screen),
    default_screen(_, Screen).


/*
 * widget_to_screen(+Widget, -Screen)
 *
 * Given a ProXT Widget, return the associated ProXL Screen
 */
widget_to_screen(Widget, Screen) :-
    xtScreen(Widget, XScreen),
    screen_xscreen(Screen, XScreen).


/*
 * widget_to_display(+Widget, -Display)
 *
 * Given a ProXT Widget, return the associated ProXL Display
 */
widget_to_display(Widget, Display) :-
    xtDisplay(Widget, XtDisplay),
    XtDisplay = xtdisplay(XDisplay),
    display_xdisplay(Display, XDisplay).


/*
 * widget_window(?Widget, ?Window)
 *
 * Convert between Widgets and ProXL Windows.
 * If handed a ProXT Widget, find the associated ProXL Window.
 * If handed a ProXL Window, find the associated ProXT Widget,
 * fail if it doesn't exist.
 */
widget_window(Widget, Window) :-
    (Widget = widget(W),
     integer(W) ->
	xtWindow(Widget, XWindow),
	widget_to_display(Widget, Display),
	proxl_xlib(Window, window, XWindow, Display)
    ;
     valid_window(Window) ->
	current_window(Window, Display),
	proxl_xlib(Window, window, XWindow, Display),
	display_xdisplay(Display, XDisplay),
	XtDisplay = xdisplay(XDisplay),
	xtWindowToWidget(XtDisplay, XWindow, Widget),
	Widget \== widget(0)
    ).



:- initialization
       user:use_module(xif, _, all).
