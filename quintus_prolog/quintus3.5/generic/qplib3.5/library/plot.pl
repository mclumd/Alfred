%   Package: plot
%   Author : Richard A. O'Keefe
%   Updated: 09 Sep 1988
%   Purpose: Generate UNIX plot(5)files

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(plot, [
	set_plot/1,
	close_plot/0,
	flush_plot/0,	erase_plot/0,	
	move/1,		move/2,
	cont/1,		cont/2,
	point/1,	point/2,
	line/2,		line/4,
	space/2,	space/4,
	circle/2,	circle/3,
	arc/3,		arc/6,
	label/1,
	linemod/1,
	polygon/1,	polygon/2,
	polyline/1,	polyline/2
   ]).

sccs_id('"@(#)88/09/09 plot.pl	27.1"').

:- dynamic
	plot_output/1.

set_plot(Plot) :-
	nonvar(Plot),
	current_stream(_, write, Plot),
	!,
	retractall(plot_output(_)),
	assert(plot_output(Plot)).
set_plot(Plot) :-
	format(user_output,
	    '~N! Output stream expected, but ~q found~n! Goal: ~q~n',
	    [Plot, set_plot(Plot)]),
	fail.

close_plot :-
	retract(plot_output(Plot)),
	close(Plot).


flush_plot :-
	plot_output(Plot),
	flush_output(Plot).

erase_plot :-
	plot_output(Plot),
	put(Plot, 0'e),
	flush_output(Plot).

move(Point) :-
	arg(1, Point, X),
	arg(2, Point, Y),
	plot_point(X, Y, 0'm).

cont(Point) :-
	arg(1, Point, X),
	arg(2, Point, Y),
	plot_point(X, Y, 0'n).

point(Point) :-
	arg(1, Point, X),
	arg(2, Point, Y),
	plot_point(X, Y, 0'p).

line(From, To) :-
	arg(1, From, X1),
	arg(2, From, Y1),
	arg(1,  To,  X2),
	arg(2,  To,  Y2),
	plot_pair(X1, Y1, X2, Y2, 0'l).

space(BotLeft, TopRight) :-
	arg(1, BotLeft,  X1),
	arg(2, BotLeft,  Y1),
	arg(1, TopRight, X2),
	arg(2, TopRight, Y2),
	plot_pair(X1, Y1, X2, Y2, 0's).

circle(Centre, Radius) :-
	arg(1, Centre, X),
	arg(2, Centre, Y),
	plot_circle(X, Y, Radius, 0'c).

arc(Centre, From, To) :-
	arg(1, Centre, XC),
	arg(2, Centre, YC),
	arg(1,  From,  XB),
	arg(2,  From,  YB),
	arg(1,   To,   XS),
	arg(2,   To,   YS),
	plot_triple(XC, YC, XB, YB, XS, YS, 0'a).

move(X, Y) :-
	plot_point(X, Y, 0'm).

cont(X, Y) :-
	plot_point(X, Y, 0'n).

point(X, Y) :-
	plot_point(X, Y, 0'p).

line(X1, Y1, X2, Y2) :-
	plot_pair(X1, Y1, X2, Y2, 0'l).

space(X1, Y1, X2, Y2) :-
	plot_pair(X1, Y1, X2, Y2, 0's).

circle(X, Y, R) :-
	plot_circle(X, Y, R, 0'c).

arc(XC, YC, XB, YB, XE, YE) :-
	plot_triple(XC, YC, XB, YB, XE, YE, 0'a).

label(Label) :-
	plot_string(Label, 0't).

linemod(Style) :-
	plot_string(Style, 0'f).


plot_string(Atom, Tag) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	put(Tag), write(Atom), nl,
	set_output(Normal).

plot_point(X, Y, Tag) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	put(Tag),
	put(X), put(X >> 8),
	put(Y), put(Y >> 8),
	set_output(Normal).

plot_circle(X, Y, R, Tag) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	put(Tag),
	put(X), put(X >> 8),
	put(Y), put(Y >> 8),
	put(R), put(R >> 8),
	set_output(Normal).

plot_pair(X1, Y1, X2, Y2, Tag) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	put(Tag),
	put(X1), put(X1 >> 8),
	put(Y1), put(Y1 >> 8),
	put(X2), put(X2 >> 8),
	put(Y2), put(Y2 >> 8),
	set_output(Normal).
	
plot_triple(X1, Y1, X2, Y2, X3, Y3, Tag) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	put(Tag),
	put(X1), put(X1 >> 8),
	put(Y1), put(Y1 >> 8),
	put(X2), put(X2 >> 8),
	put(Y2), put(Y2 >> 8),
	put(X3), put(X3 >> 8),
	put(Y3), put(Y3 >> 8),
	set_output(Normal).
	
polygon([Point|Points]) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	plot_pt(Point, 0'm),
	plot_pts(Points),
	plot_pt(Point, 0'n),
	set_output(Normal).

polyline([Point|Points]) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	plot_pt(Point, 0'm),
	plot_pts(Points),
	set_output(Normal).


plot_pt(Point, Tag) :-
	put(Tag),
	arg(1, Point, X), put(X), put(X >> 8),
	arg(2, Point, Y), put(Y), put(Y >> 8).

plot_pts([]).
plot_pts([Point|Points]) :-
	put(0'n),
	arg(1, Point, X), put(X), put(X >> 8),
	arg(2, Point, Y), put(Y), put(Y >> 8),
	plot_pts(Points).

polygon([X|Xs], [Y|Ys]) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	plot_pt(X, Y, 0'm),
	plot_pts(Xs, Ys),
	plot_pt(X, Y, 0'n),
	set_output(Normal).

polyline([X|Xs], [Y|Ys]) :-
	current_output(Normal),
	plot_output(Plot),
	set_output(Plot),
	plot_pt(X, Y, 0'm),
	plot_pts(Xs, Ys),
	set_output(Normal).

plot_pt(X, Y, Tag) :-
	put(Tag),
	put(X), put(X >> 8),
	put(Y), put(Y >> 8).

plot_pts([], []).
plot_pts([X|Xs], [Y|Ys]) :-
	put(0'n),
	put(X), put(X >> 8),
	put(Y), put(Y >> 8),
	plot_pts(Xs, Ys).

