%   Package: break
%   Author : Richard A. O'Keefe
%   Updated: 01 Nov 1988
%   Purpose: Print an error message and enter a break level (if possible).

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(break, [
	error_break/2
   ]).


sccs_id('"@(#)88/11/01 break.pl	27.2"').

%   error_break(+Format, +List)
%   writes an error message to the error output stream, then enters a
%   break level (an interactive loop) so that the programmer can examine
%   the data base, set spy-points &c.  If the programmer wants to let
%   the program proceed with its default action, s/he should exit the
%   break level by typing "end_of_file." or the <EOF> character.  If
%   not, s/he should type "abort." or "halt.", whichever is appropriate.
%   In a program compiled using "qpc", the error message is written and
%   then error_break/2 returns to its caller as if the programmer had
%   exited the break level normally.

error_break(Format, List) :-
	format(user_error, Format, List),
	(   call(break) ->	% This must be a "development" system
	    true		% return to caller after interaction
	;			% This must be a "runtime" system
	    true		% return to caller, not having interacted
	).

end_of_file.

/*  Originally, each library package which wanted to do this just said
	format(user_error, '~~some format~~', [Some,List]),
	break,
	<default action>	% usually "fail"
    However, the "qpc" compiler is meant for generating ordinary UNIX-
    style programs where the programmer is not present to interact with
    the program (a customer may be using the program, but this customer
    is not the programmer), and it complains if you call break/0 directly.
    However, call(break) is accepted, and just fails quietly.  So if you
    do call(break), there are three cases:
	- it fails	=> this must be a "runtime" system
	- it succeeds	=> this must be a "development" system, and
			   the programmer exited the break level by typing
			   end_of_file or the <EOF> character.
	- no return	=> the programmer did something else, such as
			   abort, halt, or killing the Prolog process.
    The if->then;else is there because we want to continue, because the
    success or failure of call(break) only tells us what kind of program
    we're in.
*/

