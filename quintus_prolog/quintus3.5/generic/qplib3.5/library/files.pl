%   Module : files
%   Author : Richard A. O'Keefe
%   Updated: 31 Jan 1994
%   Purpose: file-handling commands and predicates.
%   SeeAlso: files.c, library(directory)

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(files, [
	can_open_file/2,
	can_open_file/3,
	close_all_streams/0,
	current_dec10_stream/2,
	delete_file/1,
	directory_exists/1,
	directory_exists/2,
	file_exists/1,
	file_exists/2,
	file_must_exist/1,
	file_must_exist/2,
	open_file/3,
	dec10_rename/2,		% 1.6 library compatibility
	rename/2,		% Dec-10 compatibility
	rename_file/2
    %	stream_position/2	% became a built-in in 2.0
   ]).

:- use_module(library(types), [
	must_be_oneof/4,
	must_be_symbol/3
   ]).
:- use_module(library(errno), [
        file_error/3
   ]).

sccs_id('"@(#)94/01/31 files.pl	71.1"').


%   rename_file(+OldName, +NewName)
%   OldName and NewName must be text objects which are well formed
%   file names.  OldName must identify an existing file, which will
%   be renamed to NewName.  The details of just when this can be
%   done are operating-system dependent.  Either the operation
%   succeeds, or it prints an error message and fails.  If the
%   file is associated with a stream, the effect is system-dependent;
%   under UNIX you can still use the stream.

rename_file(OldName, NewName) :-
	Goal = rename_file(OldName, NewName),
	must_be_symbol(OldName, 1, Goal),
	must_be_symbol(NewName, 2, Goal),
	'Qrename'(OldName, NewName, ErrorCode),
	rename_file_error(ErrorCode, OldName, NewName, Goal).


%   delete_file(+OldName)
%   OldName must be a text object which is a well formed file name,
%   and it must identify an existing file, which will be deleted.
%   Either the operation succeeds, or it prints an error message
%   and fails.  Some day we'll accept path records too.  If the
%   file is associated with a stream, the effect is system-dependent;
%   under UNIX you can still use the stream.

delete_file(OldName) :-
	Goal = delete_file(OldName),
	must_be_symbol(OldName, 1, Goal),
	'Qdelete'(OldName, ErrorCode),
	(   ErrorCode =:= 0 ->
		true
	;   otherwise ->
		file_must_exist(OldName, exists, Goal),
		raise_exception(
	            permission_error(Goal,delete,file,OldName,errno(ErrorCode)))
	).


%   The following two commands are identical.  The name dec10_rename/2
%   was used in the 1.6 library, but it was always intended to be the
%   operation known as rename/2 in Dec-10 Prolog and C Prolog.  In
%   Dec-10 Prolog, you had to open a file before you could rename it,
%   and renaming closed the file.  C Prolog closed the file, but did not
%   demand that it be open.  Similarly, the Quintus version will close
%   any DEC-10 compatible stream connected to the file (but it wil NOT
%   close any streams opened by open/3; they continue to see the file).
%   If the file doesn't exist or can't be renamed, an error message will
%   be printed and execution will be aborted if file errors are enabled;
%   you'll get a quiet failure if file errors are disabled.  Note that
%   close(OldName) doesn't mind a bit if OldName isn't open!  These
%   operations are only provided to help convert old code; new programs
%   should use rename_file/2 or delete_file/1.

dec10_rename(OldName, NewName) :-
	Goal = dec10_rename(OldName, NewName),
	must_be_symbol(OldName, 1, Goal),
	must_be_symbol(NewName, 2, Goal),
	(   current_dec10_stream(OldName, _) -> close(OldName)
	;   true % for C Prolog compatibility, do not insist on
	),       % the file being open beforehand.
	(   NewName = [] -> 'Qdelete'(OldName, ErrorCode)
	;   'Qrename'(OldName, NewName, ErrorCode)
	),
	old_rename_file_error(ErrorCode, OldName, NewName, Goal).


rename(OldName, NewName) :-
	Goal = rename(OldName, NewName),
	must_be_symbol(OldName, 1, Goal),
	must_be_symbol(NewName, 2, Goal),
	(   current_dec10_stream(OldName, _) -> close(OldName)
	;   true % for C Prolog compatibility, do not insist on
	),       % the file being open beforehand.
	(   NewName = [] -> 'Qdelete'(OldName, ErrorCode)
	;   'Qrename'(OldName, NewName, ErrorCode)
	),
	old_rename_file_error(ErrorCode, OldName, NewName, Goal).


%   Error handling for rename predicates

rename_file_error(ErrorCode, OldName, NewName, Goal) :-
	(   ErrorCode =:= 0 ->
		true
	;   otherwise ->
		file_must_exist(OldName, exists, Goal),
		file_must_exist(NewName, write, Goal),
						  % shouldn't get here
		raise_exception(
		    permission_error(Goal,rename,file,OldName,errno(ErrorCode)))
	).

old_rename_file_error(ErrorCode, Old, New, Goal) :-
	(   ErrorCode =:= 0 ->
		true
	;   prolog_flag(fileerrors, off) ->
		fail
	;   otherwise ->
		rename_file_error(ErrorCode, Old, New, Goal)
	).



%   current_dec10_stream(?FileName, ?See_or_Tell)
%   is true when See_or_Tell is 'see' and FileName is a file which
%   was opened by see(FileName) and has not yet been closed, or
%   when See_or_Tell is 'tell' and FileName is a file which was
%   opened by tell(FileName) and has not yet been closed.  It is
%   a version of current_stream/3 which just tells you about the
%   Dec-10-compatible streams.  It relies on two facts:
%   (1) *all* the streams you opened are in the current_stream/3 table.
%   (2) seeing/1 (telling/1) return an atom if and only if the
%   current input (output) stream was opened by see/1 (tell/1), and
%   the atom it returns is that which was given to see/1 (tell/1).

current_dec10_stream(FileName, see) :-
	current_stream(_, read, Stream),
	current_input(OldStream),
	set_input(Stream),
	seeing(Thingy),
	set_input(OldStream),
	atom(Thingy),
	FileName = Thingy.
current_dec10_stream(FileName, tell) :-
	current_stream(_, write, Stream),
	current_output(OldStream),
	set_output(Stream),
	telling(Thingy),
	set_output(OldStream),
	atom(Thingy),
	FileName = Thingy.



%   directory_exists(+Directory, [+Mode])
%   is true when Directory is a well formed directory name which
%   can be accessed to Mode. Mode is an atom, an integer,
%   or a list of atoms and/or integers. See access(2) in the
%   UNIX manual or in the VAX-11 C reference manual for details.

directory_exists(Directory) :-
    (	atom(Directory) ->
	'Qdaccess'(Directory, 0, 0)
    ;	must_be_symbol(Directory, 1, directory_exists(Directory))
    ).

directory_exists(Directory, Mode) :-
	atom(Directory),
	'mode bits'(Mode, 0, Bits),
	!,
	'Qdaccess'(Directory, Bits, 0).
directory_exists(Directory, Mode) :-
	Goal = directory_exists(Directory, Mode),
	must_be_symbol(Directory, 1, Goal),
	raise_exception(
	    domain_error(Goal,0,'access mode',Mode,0)).

%   file_exists(+File[, +Mode])
%   is true when File is a well formed file name which can be
%   accessed according to Mode.  Mode is an atom, an integer,
%   or a list of atoms and/or integers.  See access(2) in the
%   UNIX manual or in the VAX-11 C reference manual for details.

file_exists(File) :-
    (	atom(File) ->
	'Qaccess'(File, 0, 0)
    ;	must_be_symbol(File, 1, file_exists(File))
    ).

file_exists(File, Mode) :-
	atom(File),
	'mode bits'(Mode, 0, Bits),
	!,
	'Qaccess'(File, Bits, 0).
file_exists(File, Mode) :-
	Goal = file_exists(File,Mode),
	must_be_symbol(File, 1, Goal),
	raise_exception(
	    domain_error(Goal,0,'access mode',Mode,0)).


'mode bits'(-, _, _) :- !, fail.	% catches variables
'mode bits'([], Bits, Bits) :- !.
'mode bits'([Head|Tail], Bits0, Bits) :- !,
	'mode bits'(Head, Bits0, Bits1),
	'mode bits'(Tail, Bits1, Bits).
'mode bits'(read,   Bits0, Bits) :- !, Bits is Bits0 \/ 4.
'mode bits'(write,  Bits0, Bits) :- !, Bits is Bits0 \/ 2.
'mode bits'(execute,Bits0, Bits) :- !, Bits is Bits0 \/ 1.
'mode bits'(append, Bits0, Bits) :- !, Bits is Bits0 \/10.
'mode bits'(exists, Bits,  Bits) :- !.
'mode bits'(Integer, Bits0, Bits) :-
	integer(Integer),
	Bits is (Integer/\7)\/Bits0.


%   file_must_exist(+File[, +Mode])
%   is like file_exists(File[, Mode]) except that if the file is NOT
%   accessible it reports an error.


file_must_exist(File) :-
	atom(File),
	'Qaccess'(File, 0, 0),
	!.
file_must_exist(File) :-
	Goal = file_must_exist(File),
	must_be_symbol(File, 1, Goal),
	'Qaccess'(File, 0, ErrorCode),
	file_error(ErrorCode, File, Goal).


file_must_exist(File, Mode) :-
	file_must_exist(File, Mode, file_must_exist(File,Mode)).

file_must_exist(File, Mode, _) :-
	atom(File),
	'mode bits'(Mode, 0, Bits),
	'Qaccess'(File, Bits, 0),
	!.
file_must_exist(File, Mode, Goal) :-
	must_be_symbol(File, 1, Goal),
	(   'mode bits'(Mode, 0, Bits) ->
	    'Qaccess'(File, Bits, ErrorCode),
	    file_error(ErrorCode, File, Goal)
	;   raise_exception(
		domain_error(Goal,0,'access mode',Mode,0))
	).

/*  can_open_file(FileName, Mode, Quiet)
    checks whether it is possible to open the file called FileName in Mode.
    Mode is one of
	read	- FileName must exist and be readable
	write	- FileName must exist and be writable or else
		  be non-existent in a writable directory
	append	- same as write
    The possible values for Quiet are
	fail	- just quietly fail if the file is not openable
	warn	- print an error message if the file won't open.
    All things considered, the simplest way to do this is to just try to
    open the file.  This has a defect: it might indeed be possible to open
    the file, but if too many files are open already it won't work.  But
    the error message for that is intelligible, and if we really want to
    open the file that is something we'd like to know about.

    open_file(File, Mode, Stream) does the same checks, and goes ahead
    and does open the file.  This does better error reporting than the
    existing open/3 (which it uses).

    The "standard" modes are
	read	- input
	write	- output, creates a new file
	append	- output, extends an existing file or creates a new one
    These two predicates understand a fourth mode
	backup	- output, any existing file F is renamed to F.BAK
    There is no way of overwriting an existing file.
*/
can_open_file(FileName, Mode) :-
	can_open_file(FileName, Mode, fail).


can_open_file(FileName, Mode, Quiet) :-
	Goal = can_open_file(FileName,Mode,Quiet),
	must_be_symbol(FileName, 1, Goal),
	'file mode'(Mode, Goal, Bits, _),
	must_be_oneof(Quiet, [fail,warn], 3, Goal),
	'Qcanopen'(FileName, Bits, ErrorCode),
	(   ErrorCode = 0, !		% all went well
	;   Quiet = fail, !, fail	% fail quietly
	;   file_error(ErrorCode, FileName, Goal)
	).


'file mode'(read,	_, 0, read) :- !.
'file mode'(write,	_, 1, write) :- !.
'file mode'(append,	_, 1, append) :- !.
'file mode'(backup,	_, 1, write) :- !.
'file mode'(Mode, Goal, _) :-		% fails
	must_be_oneof(Mode, [read,write,append,backup], 2, Goal).



open_file(FileName, Mode, Stream) :-
	Goal = open_file(FileName,Mode,Stream),
	must_be_symbol(FileName, 1, Goal),
	'file mode'(Mode, Goal, Bits, NewMode),
	'Qcanopen'(FileName, Bits, ErrorCode),
	file_error(ErrorCode, FileName, Goal),
	'back file'(Mode, FileName),
	open(FileName, NewMode, Stream).


'back file'(backup, FileName) :- !,
	name(FileName, Chars),
	append(Chars, ".BAK", BackChars),
	name(BackName, BackChars),
	'Qrename'(FileName, BackName, _).
'back file'(_, _).



/*  close_all_streams closes all the streams (other than the standard input
    and output) which are currently open.  The time to call this is after
    an abort/0.  Note that current_stream does not notice the standard
    input or output.
*/
close_all_streams :-
	current_stream(_, _, Stream),
	close(Stream),
	fail
    ;	true.


/*  --------------------------------------------------------------------
    Quintus Prolog provides a command
	stream_position(+Stream, ?OldPosition, +NewPosition)
    which is analogous to lseek(3) in C.
    But that predicate only works for streams whose positions
    can be changed, and neither the 'user' streams nor streams
    made by QP_make_stream() can be, so you can't even use
	stream_position(Stream, Position, Position)
    to read their position.

    This file used to define
	stream_position(?Stream, ?OldPosition)
    which just returns the current position without trying to
    change it.  It is a true predicate; it can be used to find
    the position of a given stream, or to enumerate all the
    streams.  stream_position/2 became a built-in in release 2.0.

    current_stream(?Stream)
    is true when Stream is a standard stream or one of the
    streams visible in current_stream/3.  It may be used to
    check whether something is a current stream, or to enumerate
    all the streams.


current_stream(X) :-
	(   atom(X) ->
	    standard_stream(X)
	;   nonvar(X) ->
	    X = '$stream'(_,_),
	    current_stream(_, _, X)
	;   standard_stream(X)
	;   current_stream(_, _, X)
	).

standard_stream(user).
standard_stream(user_input).
standard_stream(user_output).
standard_stream(user_error).


stream_position(Stream, '$stream_position'(CharCount,LineCount,LinePos)) :-
	current_stream(Stream),
	character_count(Stream, CharCount),
	line_count(Stream, LineCount),
	line_position(Stream, LinePos).
--------------------------------------------------------------------  */


/* Extensions to QU_messages to enable proper printing of error messages */

:- multifile 'QU_messages':operation/3.
:- multifile 'QU_messages':typename/3.

'QU_messages':operation(delete) --> [delete-[]].
'QU_messages':operation(rename) --> [rename-[]].
'QU_messages':operation(access) --> [access-[]].

'QU_messages':typename('access mode') --> ['access mode'-[]].



foreign_file(library(system(libpl)), [
	'Qrename',		% old name x new name -> error code
	'Qdelete',		% old name -> error code
	'Qaccess',		% file name x access bits -> error code
	'Qdaccess',		% directory name x access bits -> error code
	'Qcanopen'		% file name x mode -> error code
    ]).

foreign('Qrename', 'Qrename'(+string,+string,[-integer])).
foreign('Qdelete', 'Qdelete'(+string,[-integer])).
foreign('Qaccess', 'Qaccess'(+string,+integer,[-integer])).
foreign('Qdaccess','Qdaccess'(+string,+integer,[-integer])).
foreign('Qcanopen','Qcanopen'(+string,+integer,[-integer])).


:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

