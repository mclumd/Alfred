%   Package: exit
%   Author : Richard A. O'Keefe
%   Updated: 30 Sep 1992
%   Defines: An alternative to halt/0

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(exit, [
	exit/0,
	exit/1
   ]).

sccs_id('"@(#)92/09/30 exit.pl	66.1"').

/*	exit
    and	exit(ExitCode)

    are alternatives to the built-in predicate 'halt'.  My original
    reason for wanting them was to have a way of exiting Prolog
    without getting the closing "Prolog execution halted"banner.
    It then occurred to me that while some UNIX systems provide an
    "onexit" function, some don't, and it would be a good idea to
    have a portable way of doing that.  The best thing would be to
    move this into the supported system, so that QP streams could
    be properly closed by a call to QP_run_exit_forms(x) from user
    C code.  Note that we do NOT redefine the standard C function
    exit(2), though we could.
*/

exit :-
	exit(0).


exit(ExitCode) :-
	integer(ExitCode),
	!,
	(   current_stream(_, _, Stream),
	    close(Stream),
	    fail
	;   flush_output(user_output),
	    flush_output(user_error),
	    'QP_run_exit_forms'(ExitCode)
	;   halt % just in case...
	).
exit(ExitCode) :-
	format(user_error, '~N! Type failure in argument ~w of ~w/~w~n',
	    [1, exit, 1]),
	format(user_error, '! ~w expected, but found ~q~n! Goal: ~q~n',
	    [integer, ExitCode, exit(ExitCode)]),
	exit(1).



foreign_file(library(system(libpl)), ['QP_run_exit_forms']).
foreign('QP_run_exit_forms', 'QP_run_exit_forms'(+integer)).

:- load_foreign_executable(library(system(libpl))).
