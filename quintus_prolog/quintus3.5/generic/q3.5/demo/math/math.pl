
/* @(#)math.pl	28.2 09/05/90 */

/*
	+--------------------------------------------------------+
	| 							 |
        |    Math Library Interface (a C-interface example)      |
        |							 |
        |							 |
	|  Copyright (C) 1985,  Quintus Computer Systems, Inc.   |
	|  All rights reserved.					 |
	|							 |
	+--------------------------------------------------------+

*/


:- use_module(library(math)).

distance(X,Y) :-
	scale_val(X,Y,Scale),
	X_1 is Scale * X, X1 is integer(X_1),
	Y_1 is Scale * Y, Y1 is integer(Y_1),
	draw_to_scale(X,Y,X1,Y1).

scale_val(X,Y,Scale) :-
	( X >= Y -> Scale is 20.0/X
	| Scale is 20.0/Y
	).

draw_to_scale(X,Y,X1,Y1) :-
	nl, nl,  write(' Y = '), write(Y), nl,
	draw_y_axis(Y1),
	draw_x_axis(X1),
	write('  0'), tab(2*X1 - 2), write('X = '), write(X),nl,nl,
	write('The distance between X and Y is '),
	cabs(complex(X,Y),Distance), write(Distance),nl.

draw_y_axis(0) :- !.
draw_y_axis(1) :- !, write('0|').
draw_y_axis(Y) :- Y > 0, write(' |'), nl, Y1 is Y - 1, draw_y_axis(Y1).

draw_x_axis(0) :- !, nl.
draw_x_axis(X) :- X > 0, write('__'), X1 is X - 1, draw_x_axis(X1).

run :-	see('math.q'),
	write('hit <return> to step through this demo'), nl,nl, 
	repeat,
	read(Term),
	(Term \== end_of_file ->
	 read(Call), 
	 write(Term), ttyget0(_),write('	-> '), call(Call), 
	 write(Call),nl,nl,fail
	| seen).

user_help :-
	write('

Commands:

	run.		Run a demo of the math functions.
	distance(X,Y).	Graphically display distance between 2 points.
			X and Y must be positive, e.g.
			| ?- distance(4,5).
	help.		Print this message.
	halt.		Exit from prolog.

	Commands appearing in the first demo can be typed individually, e.g. 
	| ?- sqrt(100,X).

').

