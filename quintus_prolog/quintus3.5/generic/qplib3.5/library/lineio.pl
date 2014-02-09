%   Module : lineio
%   Author : Richard A. O'Keefe
%   Updated: 31 May 1990
%   Purpose: read and write lines as lists of character codes

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, 1988, 1989,
%	Quintus Computer Systems, Inc.  All rights reserved.

:- module(lineio, [
	get_line/1,		fget_line/2,
	get_line/2,		fget_line/3,
	put_chars/1,
	put_line/1
%	skip_line/0		See comments at skip_line/0 in this file
   ]).
:- mode
	get_line(?),
	get_line(?, ?),
	get_line_1(-, ?),
	put_chars(+),
	put_line(+).

sccs_id('"@(#)90/05/31 lineio.pl    49.1"').


/*  The 1987 version of this file used is_end{file,line}/1 from
    library(ctypes).  In this version, I have reverted to using the
    appropriate codes in-line, so that with the future Quintus 
    Prolog new I/O implementation it should all go fast.
*/

%   get_line(?Chars)
%   reads a line from the current input stream, and returns the characters in
%   the list Chars.  It does NOT return the line terminating character, so it
%   is useful for portable programming.  If the terminator was the end of the
%   file, it simply fails and later calls will abort.

get_line(Chars) :-
	get_line_1(Line, Terminator),
	Terminator >= 0,		% not end-of-file
	Chars = Line.



%   get_line(?Chars, ?Terminator)
%   reads a line from the current input stream, and returns the characters in
%   the list Chars, and the line terminating character in Terminator.  If the
%   terminator was end of file, it just returns it like always.  When you use
%   this routine, the last line will often be ignored if not properly ended.

get_line(Chars, Terminator) :-
	get_line_1(Line, Terminator),
	Chars = Line.



get_line_1(Line, Terminator) :-		% 9 is the ASCII TAB character.
	get0(Char),			% 5 is the EBCDIC TAB character.
	(   Char < " ", Char =\= 9, Char =\= 5 ->
	    Line = [], Terminator = Char
	;   Line = [Char|Chars],
	    get_line_1(Chars, Terminator)
	).



%   fget_line(+Stream, ?Chars)
%   reads a line from the given input Stream, and returns the characters in
%   the list Chars.  It does NOT return the line terminating character, so it
%   is useful for portable programming.  If the terminator was the end of the
%   file, it simply fails and later calls will abort.

fget_line(Stream, Chars) :-
	fget_line(Stream, Line, Terminator),
	Terminator >= 0,		% not end-of-file
	Chars = Line.



%   fget_line(+Stream, ?Chars, ?Terminator)
%   reads a line from the given input Stream, and returns the characters in
%   the list Chars, and the line terminating character in Terminator.  If the
%   terminator was end of file, it just returns it like always.  When you use
%   this routine, the last line will often be ignored if not properly ended.

fget_line(Stream, Chars, Term) :-
	current_input(OldInput),
	see(Stream),			% could be a DEC-10 file name
	  get_line_1(Line, Terminator),
	set_input(OldInput),
	Chars = Line, Term = Terminator.



%   put_line(+Chars)
%   writes a list of character codes, followed by a new-line.

put_line([]) :-
      nl.
put_line([Ch|Line]) :-
      put(Ch),
      put_line(Line).



%   put_chars(+Chars)
%   writes a list of character codes, with no following new-line.

put_chars([]).
put_chars([Char|Chars]) :-
	put(Char),
	put_chars(Chars).



%   skip_line
%   skips to the end of the current line.  It is happy with 26 as the end of
%   the line, which get_line(_) would not be, but get_line(_,_) would.
%   Use of skip_line/0 here is subsumed by the new builtin skip_line/0.

% skip_line :-
%	repeat,
%	    get0(Char),
%	    Char < " ", Char =\= 9, Char =\= 5,
%	!.

