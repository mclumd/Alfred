%   SCCS   : @(#)qqmaster.pl	24.2 4/14/88
%   Author : David S. Warren
%   Purpose: Demo of Prolog calling Prolog through IPC.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

go :-
	go('').		% uses pipes.

go(HostName) :-
	write('Starting up the Prolog servant (routing its output to you)...'),
	nl,
	create_servant(HostName, qqservant, user),
	help.


user_help :-
	write('This is the n-queens demo of the Prolog IPC facility.'), nl,
	write('It uses a servant process to help solve the n-queens problem.'), nl,
	write('To solve the 4-queens problem, enter the goal:'), nl,
	tab(5), write('queens(4, Ans).'), nl,
	write('and the system will produce the ways to place 4 queens on a'), nl,
	write('4 by 4 chess board. (Enter ; to step through the answers.)'), nl,
	nl,
	write('You may turn tracing on (off) by using the goal tracing_on (tracing_off).'), nl,
	write('With message tracing on, all messages cause a trace to be printed.'), nl,
	write('(The tracing messages are produced (and buffered) by separate processes'), nl,
	write('and so the order they appear on your screen may look unusual.)'), nl,
	write('To terminate gracefully, enter:'), nl,
	tab(5), write('shutdown_servant.'), nl,
	write('before halting Prolog.'), nl,
	nl,
	write('Go to it.'), nl.

tracing_on :-
	msg_trace(_, on),
	call_servant(msg_trace(_,on)),
	write('Message tracing turned on'), nl.

tracing_off :-
	msg_trace(_, off),
	call_servant(msg_trace(_,off)),
	write('Message tracing turned off'), nl.

/*  This demo involves running the N-queens problem
    partly in one process and partly in another.  So IN THIS EXAMPLE,
    the master and the servant have a lot of code in common.
*/
:- ensure_loaded(qqservant).

