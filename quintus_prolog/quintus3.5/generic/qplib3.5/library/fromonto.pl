%   Package: fromonto
%   Author : Richard A. O'Keefe
%   Updated: 13 Jul 1989
%   Purpose: input/output redirection.
%   SeeAlso: library(charsio).

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  The Quintus Prolog I/O predicates come in two groups:

	the <standard> group, which use either the current input
	stream or the current output stream, as appropriate, and
	are compatible with Dec-10 Prolog.

	the <stream> group which take an extra first argument
	which is the stream to use.  These routines are not
	compatible with Dec-10 Prolog.

    As a general rule, it is much easier to write routines which
    use the current streams than to write ones which pass streams
    all around the place.  Routines which use the current streams
    are also more efficient.  But if you want to apply your I/O
    routines to other streams, you have to redirect them, and
    this can be tricky.

    The point of this file is to provide six infix commands:

	Goal from_stream Stream
	Goal onto_stream Stream
	Goal from_file FileName
	Goal onto_file FileName
	Goal from_chars CharLis
	Goal onto_chars CharLis

    All of these operations assume that the Goal is determinate,
    which is much the most sensible assumption for I/O Goals.  In
    fact, they force it to be determinate even if it wasn't.

    The ...._file operations open a new stream to the file and
    close it when they are finished.  They will not interfere with
    any Dec-10-style I/O to the same FileName.

    The ...._stream operations divert to an existing stream, which
    they do @i<not> close.  It would be easy to make them take a
    FileName as well, in which case they would act like see/tell
    and open the file if it was not already open, but would leave
    it open.  This hasn't been done yet.

    The ...._chars operations read from or generate a list of ASCII
    codes.  Note that there is no requirement that from_chars's Goal
    should consume ALL the characters in the list of ASCII codes,
    and that there is as yet no way of finding out how much it DID
    consume.  Note also that if you want to read a term from a list
    of character codes, you will have to ensure that it ends with
    ". " just like any other source of input.  That is,
	read(Term) from_chars "fred"	IS IN ERROR, you must say
	read(Term) from_chars "fred. ".
    But see chars_to_term/2 in library(charsio), which does add ".".
    Just like ordinary output, writing to Chars will not add
    punctuation, so
	write(fred) onto_chars L % binds L = "fred"
	(write(fred),write('. ')) onto_chars L % binds L = "fred. ".
    You will probably find that the most useful output routine to
    call is format/2, as you can then write one idea as one call:
	format('~w. ', [fred]) onto_chars L.
    To use ...._chars, you'll have to ensure_loaded(library(charsio)).

    Note that you can redirect both streams by writing e.g.
	process_commands from_stream user onto_file 'CMD.LOG'

    writeln/1 is copied from another Prolog.  It is trivial, but if
    you haven't got format/[2-3] it is handy.  This isn't exactly
    the right place for it, but it is apposite.
*/

:- module(fromonto, [
	from_chars/2,
	onto_chars/2,
	from_file/2,
	onto_file/2,
	from_stream/2,
	onto_stream/2,
	copy_bytes/0,
	writeln/1
   ]).

:- meta_predicate
	from_chars(0, +),
	onto_chars(0, ?),
	from_file(0, +),
	onto_file(0, +),
	from_stream(0, +),
	onto_stream(0, +).

:- use_module(library(charsio), [
	with_input_from_chars/2,
	with_output_to_chars/2
   ]).

:- op(800, yfx, [
	from_chars,
	onto_chars,
	from_file,
	onto_file,
	from_stream,
	onto_stream,
	with_input_from_chars,
	with_output_to_chars
   ]).

sccs_id('"@(#)89/07/13 fromonto.pl	32.1"').


%   from_file(+Goal, +FileName)
%   executes Goal with current input coming from a new stream connected
%   to FileName, then closes that stream.  This is an infix operator.

from_file(Goal, FileName) :-
	current_input(OldStream),
	open(FileName, read, NewStream),
	set_input(NewStream),
	(   call(Goal) -> Flag = 1 ; Flag = 0   ),
	set_input(OldStream),
	close(NewStream),
	Flag > 0.


%   onto_file(+Goal, +FileName)
%   executes Goal with current output going to a new stream connected
%   to FileName, then closes that stream.  This is an infix operator.

onto_file(Goal, FileName) :-
	current_output(OldStream),
	open(FileName, write, NewStream),
	set_output(NewStream),
	(   call(Goal) -> Flag = 1 ; Flag = 0   ),
	set_output(OldStream),
	close(NewStream),
	Flag > 0.


%   from_stream(+Goal, +Stream)
%   executes Goal with current input coming from Stream, which must be
%   open, and will not be closed.  This is an infix operator.

from_stream(Goal, NewStream) :-
	current_input(OldStream),
	set_input(NewStream),
	(   call(Goal) -> Flag = 1 ; Flag = 0   ),
	set_input(OldStream),
	Flag > 0.


%   onto_stream(+Goal, +Stream)
%   executes Goal with current output going to Stream, which must be
%   open, and will not be closed.  This is an infix operator.

onto_stream(Goal, NewStream) :-
	current_output(OldStream),
	set_output(NewStream),
	(   call(Goal) -> Flag = 1 ; Flag = 0   ),
	set_output(OldStream),
	Flag > 0.


%   from_chars(+Goal, +Chars)
%   executes Goal with current input coming from a new stream whose
%   contents are copied from Chars, which must be a proper list of
%   character codes.  Then the new stream is closed.  This can be
%   used as an infix operator.

from_chars(Goal, Chars) :-
	with_input_from_chars(Goal, Chars).


%   onto_chars(+Goal, ?Chars)
%   executes Goal with current output going to a new stream.  After
%   Goal has finished, the new stream is closed, and Chars is
%   unified with a list of the characters which were written to
%   that stream.  This can be used as an infix operator.

onto_chars(Goal, Chars) :-
	with_output_to_chars(Goal, Chars).



%   copy_bytes
%   copies characters from the current input stream to the current
%   output stream.  It is best used with the I/O redirection operators
%   defined in this file, e.g.
%	copy_bytes from_file 'fred.pl' onto_stream Output

copy_bytes :-
	repeat,
	    get0(C),
	    (   C >= 0 -> put(C), fail
	    ;   true
	    ),
	!.



%   writeln(+ListOfTerms)
%   writes each of the Terms in ListOfTerms using write/1, then
%   writes a newline.  You probably want format/2 instead.

writeln([]) :-
	nl.
writeln([Head|Tail]) :-
	write(Head),
	writeln(Tail).

