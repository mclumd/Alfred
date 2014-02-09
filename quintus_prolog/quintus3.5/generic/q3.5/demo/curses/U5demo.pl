/* @(#)U5demo.pl	26.1 11/16/88 */

/*
	+--------------------------------------------------------+
	| 							 |
        |     Curses Package Demos (a C-interface example)       |
        |							 |
        |							 |
	|  Copyright (C) 1988,  Quintus Computer Systems, Inc.   |
	|  All rights reserved.					 |
	|							 |
	+--------------------------------------------------------+ */


/* ----------------------------------------------------------------------
   This file contains a few examples of programs that make calls to the
   curses package.
   ---------------------------------------------------------------------- */

user_help :-
	write('

Commands:
	go.			run the curses demo
	write_diag(Y,X,String)  write a string diagonally at (X,Y).
	write_down(Y,X,String)  write a string vertically at (X,Y).
	help.			print this message.
        halt.			Exit from Prolog.

').

/* ----------------------------------------------------------------------
        This demo prints "Quintus Prolog" in a pleasing manner

        To run, type:

        | ?- go.
   ---------------------------------------------------------------------- */

:- dynamic init/0.

init :- initscr.
end  :- endwin.

go :-
	init,
	num_cols(C),
	C1 is C - 7,
	End is C1 // 2 + 1,
	num_lines(L),
	Mid is L // 2,
	Hi is Mid - 2,
	splash(Hi, Mid, 0, C1, End, ' QUINTUS', 'PROLOG '),
	endwin.

splash(_Y1, _Y2, X1, _X2, X1, _, _).


splash(Y1, Y2, X1, X2, EndCol, Str1, Str2) :-
	mvaddstr(Y1, X1, Str1),
	X3 is X1 + 1,
	mvaddstr(Y2, X2, Str2),
	X4 is X2 - 1,
	refresh,
	splash(Y1, Y2, X3, X4, EndCol, Str1, Str2).


/* ----------------------------------------------------------------------
   The following example takes a string and prints it vertically on the
   screen beginning in a designated Y,X location.  To see the results, the
   screen must be initialized using initscr and refreshed subsequently.
   A call to it might look like:

   | ?- initscr, write_down(10,20,'Quintus Prolog'), refresh.

   ----------------------------------------------------------------------  */

write_down(Y,X,Str) :-
	init,
	integer(Y), integer(X),
	name(Str, Characters),
	write_vertical(Y,X,Characters),
	refresh,
	endwin.

write_down(_,_,_) :-
	write('The arguments to write_down must be instantiated, e.g.
write_down(2,2,''Hi there folks'').').

write_vertical(_Y,_X,[]).

write_vertical(Y,X,[C|Rest]) :-
	mvaddch(Y,X,C),
	Y1 is Y + 1,
	write_vertical(Y1,X,Rest).



/* ----------------------------------------------------------------------
   write_diag works like write_down except that the text is printed on a
   diagonal rather than vertically.  A call to this routine might look
   like:

   | ?- initscr, write_diag(10,20,'Quintus Prolog'), refresh.
   ---------------------------------------------------------------------- */

write_diag(Y,X,Str) :-
	integer(Y), integer(X),
	init,
	write_diagonal(Y,X,Str),
	refresh, endwin.

write_diag(_,_,_) :-
	write('The arguments to write_diag must be instantiated, e.g.
write_diag(2,2,''Hi there folks'').').

write_diagonal(_Y,_X,[]).

write_diagonal(Y,X,[C|Rest]) :-
	mvaddch(Y,X,C),
	Y1 is Y + 1,
	X1 is X + 1,
	write_diagonal(Y1,X1,Rest).

write_diagonal(Y,X,Str) :-
	name(Str, Characters),
	write_diagonal(Y,X,Characters).

