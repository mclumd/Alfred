%   Package: unix.pl
%   Author : Richard A. O'Keefe
%   Updated: 11/12/89
%   Purpose: provide unix-like commands having atom/chars arguments.
%   SeeAlso: library(files), unix.c, errno.pl

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(unix, [
	(cd)/0,
	(cd)/1,		% accepts $FOO
	(csh)/0,
	(csh)/1,
	(ls)/0,
	mktemp/2,	% Template -> FileName
	mktemp/3,	% Template -> FileName x Stream
	(more)/1,	% accepts $FOO
	(sh)/0,
	(sh)/1,
	(shell)/0,
	(shell)/1
   ]).

:- use_module(library(environ), [
	environ/2
   ]),
   use_module(library(errno), [
	errno/2,
	fileerrno/2
   ]),
   use_module(library(strings), [
      % atom_chars/2,   	% This is now in the system
	string_char/3,
	substring/5
   ]),
   use_module(library(types), [
	must_be_symbol/3
   ]).

sccs_id('"@(#)94/02/24 unix.pl  71.1"').

:- op(100, fy, [
	cd, csh, more, sh, shell
   ]).



%   chars_or_symbol(Argument, Command, Rectified)
%   is used by unary Commands (cd, shell, sh, csh, more) to let them
%   accept either an atom(symbol) or a list of character codes (chars)
%   as Argument.  It returns an atom as the Rectified argument, or else
%   produces a type failure error message and fails.

chars_or_symbol(Symbol, _, Symbol) :-
	atom(Symbol),
	!.
chars_or_symbol([Char|Chars], _, Symbol) :-
	integer(Char),
	atom_chars(Symbol, [Char|Chars]),
	!.
chars_or_symbol(Bad, Command, _) :-
	Goal =.. [Command,Bad],
	must_be_symbol(Bad, 1, Goal).


name_or_env_var(Symbol, Command, Value) :-
	string_char(1, Symbol, 0'$),
	!,
	substring(Symbol, EnvVarName, 1, _, 0),
	(   environ(EnvVarName, EnvVarValue) ->
	    Value = EnvVarValue
	;   Goal =.. [Command,Symbol],
	    errno(999, Goal)		% EUNKVAR
	).
name_or_env_var(Symbol, _, Symbol).



cd :-
	cd('$HOME').


cd(Directory) :-
	chars_or_symbol(Directory, cd, Dir),
	name_or_env_var(Dir, cd, DirName),
	unix(cd(DirName)).



shell(Command) :-
	chars_or_symbol(Command, shell, Cmd),
	'Qshell'('', Cmd, 2, 0).

shell :-
	'Qshell'('', ., 0, 0).


sh(Command) :-
	chars_or_symbol(Command, sh, Cmd),
	'Qshell'('/bin/sh', Cmd, 2, 0).

sh :-
	'Qshell'('/bin/sh', ., 0, 0).


csh(Command) :-
	chars_or_symbol(Command, csh, Cmd),
	'Qshell'('/bin/csh', Cmd, 2, 0).

csh :-
	'Qshell'('/bin/csh', ., 0, 0).


ls :-
	'Qshell'('/bin/ls', ., 0, 0).



more(File) :-
	chars_or_symbol(File, more, F),
	name_or_env_var(F, more, FileName),
	(   environ('PAGER', Pager) -> true
	;   Pager = '/usr/ucb/more'
	),
	'Qshell'(Pager, FileName, 1, 0).



%   mktemp(+Template, -FileName)
%   is like the BSD Unix function mktemp(3):  it takes a Template which must
%   contain six consecutive Xs somewhere in it and tries to fill the Xs in
%   with a letter and the current process Id so as to make a FileName which
%   is not currently in use.  If it succeeds it returns that FileName, but
%   there is still no such file.

mktemp(Template, FileName) :-
	'QPtemp'(Template, Name, 1, Status),
	(   Status =:= 0 -> FileName = Name
	;   fileerrno(Status, mktemp(Template,FileName))
	).


%   mktemp(+Template, -FileName, -Stream)
%   is like the BSD Unix function mkstemp(3):  it uses the Template to make
%   up a FileName suitable for a temporary file and returns both the
%   FileName and a Stream open for output to that (new) file.  A common
%   pattern is
%	mktemp(Template, FileName, Stream),	% defined here
%	generate_output_to(Stream),		% you write this
%	close(Stream),				% built in
%	open(FileName, read, NewStream),	% built in
%	read_input_back_from(NewStream),	% you write this
%	close(NewStream),			% built in
%	delete_file(FileName)			% from library(files)

mktemp(Template, FileName, Stream) :-
	'QPtemp'(Template, Name, 0, Status),
	(   Status =:= 0 ->
	    open(Name, write, Stream),
	    FileName = Name
	;   fileerrno(Status, mktemp(Template,FileName))
	).


foreign_file(library(system(libpl)),
    [
	'Qshell',
	'QPtemp'
    ]).

foreign('Qshell',  'Qshell'(+string,+string,+integer,[-integer])).
foreign('QPtemp',  'QPtemp'(+string,-atom,+integer,[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

