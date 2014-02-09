%   Package: getfile
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Purpose: Read a whole file as a list of lines

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(get_file, [
	get_file/2
   ]).

sccs_id('"@(#)89/08/29 getfile.pl	33.1"').

/*  get_file(+File, ?Lines)
    opens File for input, and returns the entire contents of the File as
    a list of Lines, where each Line is a list of character codes.  The
    new-line characters terminating the lines are NOT included in the
    result.  The last line of the file need not be terminated by a new-line.
    For example, if the file contains "ab\n\ncd\ne", the Lines returned
    will be ["ab","","cd","e"]; there is no way of telling that the last
    line had no new-line at the end of it.

    The space cost is one cons cell (8 bytes) for every character of the
    File.  That is, file_property(File, size_in_bytes, N) =>
    Lines will require exactly 8*N bytes.
    The longest file in this library fits in less than 0.5Mbyte.
*/

get_file(File, Lines) :-
	current_input(OldStream),
	open(File, read, NewStream),
	set_input(NewStream),
	    get_file(Ls),
	set_input(OldStream),
	close(NewStream),
	Lines = Ls.

get_file(Lines) :-
	get0(Char),
	(   Char  <   0 -> Lines = []
	;   Char =:= 10 -> Lines = [[]|Rest], get_file(Rest)
	;                  Lines = [Line|Rest], get_file(Char, Line, Rest)
	).

get_file(Char, [Char|Line], Lines) :-
	get0(Next),
	(   Next  >  10 -> get_file(Next, Line, Lines)
	;   Next =:= 10 -> Line = [], get_file(Lines)
	;   Next  <   0 -> Line = [], Lines = []
	;                  get_file(Next, Line, Lines)
	).

