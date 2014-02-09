%   Package: pipe
%   Author : Richard A. O'Keefe
%   Updated: 11/16/89
%   Purpose: Show how Quintus streams may be connected to pipes.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This module exports a single predicate:
	popen(+Command, +Mode, -Stream)

    It is overwhelming simpler, more portable, and more reliable to use
    the UNIX library function popen(3S) [see popen(BA_OS) in volume 1 of
    the System V Interface Definition] rather than to use pipe(2), exec(2),
    and fork(2) directly.  We pay two prices for this:
	(1) we will find out *if* something goes wrong, but the effect of
	    popen(3S) on errno is not defined, so we cannot find out *what*
	    went wrong.
	(2) there is no equivalent of popen(3S) which allows you to connect
	    a pipe to BOTH ends of a command, nor to the standard error
	    stream of a command, so we can only provide 'read' and 'write'
	    modes.

    The Mode may be either
	read	: Stream will be bound to a new input stream, connected
		  to the standard output of the Command.  The standard
		  input stream of the Command is left the same as the
		  standard input stream of Prolog.  So we have
			user_input -> Command -> Stream

	write	: Stream will be bound to a new output stream, connected
		  to the standard input of the Command.  The standard
		  output stream of the Command is left the same as the
		  standard input stream of Prolog.  So we have
			Stream -> Command -> user_output

    The behaviour of popen/3 is defined by the UNIX popen(3S) function;
    see the appropriate manual page.  There is no special pclose/1
    command: the existing close/1 will call pclose(3S).  Commands are
    executed by the Bourne shell.

    There is one minor problem: if Prolog runs out of streams before C
    does (which is quite possible) the Command would be started, making
    a C stream, and then when it was found that Prolog had run out, the
    popen(3S) would wait for the Command to come to an orderly halt.
    As a precaution against this, we open a null stream and close it
    again before calling QUpopen, to ensure that there is at least one
    slot in the Prolog stream table left.  But *of course* QUpopen still
    checks!
*/

:- module(pipe, [
	popen/3
   ]).

:- use_module(library(types)).

:- mode
	popen(+, +, -),
	popen_mode(+, -).

sccs_id('"@(#)98/12/10 pipe.pl  76.1"').


%   popen(+Command:atom, +Mode:atom, -Stream)
%   executes Command using the Bourne shell.  If Mode=read, Prolog can read
%   the standard output of the command through Stream.  If Mode=write, Prolog
%   can write the standard input of the command through Stream.  This is uses
%   the UNIX popen(3S) function.

popen(Command, Mode, Stream) :-
	atom(Command),
	atom(Mode),
	popen_mode(Mode, Direction),
	var(Stream),
	!,
	open_null_stream(Precaution),	% ensure that there is at least one
	close(Precaution),		% slot in the Prolog stream table.
	'QUpopen'(Command, Direction, StreamCode, 0),
	stream_code(Stream, StreamCode).
popen(Command, Mode, Stream) :-
	Goal = popen(Command,Mode,Stream),
	must_be_symbol(Command, 1, Goal),
	must_be_oneof(Mode, [read,write], 2, Goal),
	must_be_var(Stream, 3, Goal).

popen_mode(read,	0).
popen_mode(write,	1).

foreign_file(library(system(libpl)), ['QUpopen']).
foreign('QUpopen', 'QUpopen'(+string,+integer,-address('QP_stream'),[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

end_of_file.

/*  This is an example of using library(pipe).
*/

:- use_module([
	library(pipe),
	library(lineio),
	library(fromonto)	
   ]).


%.  cwd(?DirectoryName)
%   unifies DirectoryName with the name of the current directory
%   (represented as an atom).  It uses the UNIX pwd(1) command.

cwd(X) :-
	popen(pwd, read, S),
	get_line(Line) from_stream S,
	close(S),
	atom_chars(X, Line).


%.  cwd_chars(?DirectoryName)
%   unifies DirectoryName with the name of the current directory
%   (represented as character list).  It uses the UNIX pwd(1) command.

cwd_chars(X) :-
	popen(pwd, read, S),
	get_line(Line) from_stream S,
	close(S),
	X = Line.





