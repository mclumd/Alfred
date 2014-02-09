%   Package: big_text
%   Author : Richard A. O'Keefe
%   Updated: 30 Sep 1992
%   Purpose: handle much more text than Prolog can hold

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(big_text, [
	is_big_text/1,		% BigText ->
	copy_texts/3,		% list(Text) x FileName -> list(BigText)
	edit_text/3,		% Text x FileName -> BigText
	edit_text/4,		% Text x FileName x BufferName -> BigText
	have_emacs_edit/1,	% FileName ->
	have_emacs_edit/2,	% FileName x BufferName ->
	make_big_text/2,	% FileName -> BigText
	make_big_text/3,	% FileName x Length -> BigText
	make_big_text/4,	% FileName x Offset x Length -> BigText
	pipe_to_text/3,		% UnixCommand x FileName -> BigText
	send_editor/2,		% Format x Args ->
	show_text/1,		% list(Text) ->
	text_to_file/2,		% list(Text) x FileName ->
	text_to_pipe/2		% list(Text) x UnixCommand ->
   ]).
:- use_module(library(directory), [
	file_property/2,	% FileName x Property ->
	file_property/3		% FileName x Property -> Value
   ]),
   use_module(library(critical), [
	begin_critical/0,	% enter critical region (for send_to_emacs)
	end_critical/0		% leave critical region
   ]),
   use_module(library(strings), [
	system/1		% list(Text) ->
   ]).

sccs_id('"@(#)92/09/30 big_text.pl	66.1"').


%   is_big_text(+BigText)
%   recognises big_text objects.

is_big_text(big_text(FileName,Offset,Length)) :-
	atom(FileName),
	integer(Offset), Offset >= 0,
	integer(Length), Length >= 0.



%   make_big_text(+FileName, +Offset, +Length, ?BigText)
%   unifies BigText with a term representing the section of text
%   starting at byte Offset in file FileName and extending for
%   Length bytes.  This is the simple way of making a big_text
%   object from a known section of an already existing file.
%   The section must actually exist in the file.
%   Actually, you can use this to unpack a BigText, but it will
%   still check that the file exists and the section is valid.

make_big_text(FileName, Offset, Length, big_text(FileName,Offset,Length)) :-
	integer(Offset), Offset >= 0,
	integer(Length), Length >= 0,
	file_property(FileName, readable),
	file_property(FileName, size_in_bytes, Size),
	Offset+Length =< Size.


%   make_big_text(+FileName, +Length, ?BigText)
%   unifies BigText with a term representing the first Length bytes
%   of text in file FileName.  The file must exist and be at least
%   this long.

make_big_text(FileName, Length, BigText) :-
	make_big_text(FileName, 0, Length, BigText).


%   make_big_text(+FileName, ?BigText)
%   unifies BigText with a term representing all of the text in
%   file FileName, which must exist.  You can also use this to
%   test whether BigText represents all of its file.

make_big_text(FileName, big_text(FileName,0,Size)) :-
	file_property(FileName, readable),
	file_property(FileName, size_in_bytes, Size).



%   text_to_file(+Text, +FileName)
%   writes a whole pile of text to FileName.  The text can be a
%   constant, an atom, a list of character codes, one of the
%   special terms big_term(FileName[[,Offset],Length]) which
%   represent all or part of a file, or a list of these.  For
%   Example, text_to_file([big_text(a),"**",big_text(b)], astarb)
%   is the equivalent of the UNIX command
%	(cat a; echo -n "**"; cat b) >astarb
%   and has the same caveat:  don't use FileName in the Text!

text_to_file(Text, FileName) :-		% To see how this works,
	atom(FileName),			% read the C code.
	(   'QBopen'(_),		% open a scratch file
	    write_text(Text),		% write to the scratch file
	    'QBrename'(FileName)	% close scratch, rename to this
	;   'QBclose',			% close scratch file
	    'QBdelete'			% and delete it
	), !.


write_text([Char|Chars]) :-		% list of character codes
	integer(Char),
	!,
	'QBchar'(Char),			% write one byte
	write_text_chars(Chars).
write_text([Text|Texts]) :-		% list of texts
	nonvar(Text),
	!,
	write_text(Text),
	write_texts(Texts).
write_text(big_text(FileName)) :- !,	% all of file
	file_property(FileName, readable),
	file_property(FileName, size_in_bytes, Size),
	'QBfile'(FileName, 0, Size, 0).
write_text(big_text(FileName, Length)) :- !,
	integer(Length), Length >= 0,
	file_property(FileName, readable),
	file_property(FileName, size_in_bytes, Size),
	Length =< Size,
	'QBfile'(FileName, 0, Length, 0).
write_text(big_text(FileName,Offset,Length)) :- !,
	integer(Offset), Offset >= 0,
	integer(Length), Length >= 0,
	file_property(FileName, readable),
	file_property(FileName, size_in_bytes, Size),
	Length =< Size,
	'QBfile'(FileName, Offset, Length, 0).
write_text(Atom) :-
	atom(Atom),
	'QBatom'(Atom).


write_text_chars([]).
write_text_chars([Char|Chars]) :-
	'QBchar'(Char),
	write_text_chars(Chars).


write_texts([]).
write_texts([Text|Texts]) :-
	write_text(Text),
	write_texts(Texts).



%   show_text(+Text)
%   was originally intended as a debugging aid for this package.
%   It concatenates the text just like text_to_file/2 and sends
%   the result to the user's terminal.
%   Output is routed through a new UNIX stream, not through the
%   existing Prolog output stream 'user_output', so the latter's
%   counts will NOT be affected by this!

show_text(Text) :-
	(   'QBshow',			% open /dev/tty
	    write_text(Text),
	    'QBclose'
	;   'QBclose', fail
	), !.


%   text_to_pipe(+Text, +UnixCommand)
%   execute UnixCommand with Text as its standard input.
%   We could do this by opening UnixCommand as a pipe, hence the
%   name, but in order to get this stuff done in a couple of hours
%   I had to cut corners, and so we write to a file, run the Unix
%   Command with standard input from that file, then delete the
%   file.  We could use library(popen), but this is probably
%   faster, as it uses UNIX I/O directly.

text_to_pipe(Text, UnixCommand) :-
	(   'QBopen'(TempFile),	% open a scratch file	
	    write_text(Text),	% write to the scratch file
	    'QBclose',		% close the scratch file
	    system([UnixCommand,' <',TempFile]),
	    'QBdelete'		% delete the scratch file
	;   'QBclose',		% error occurred, so
	    'QBdelete'		% close and delete
	), !.


%   copy_texts(+[Text1,...,Textn], +FileName, ?[BigText1,...,BigTextn])
%   writes to a new file, which is later renamed to FileName.
%   Each Text<i> has a corresponding element BigText<i> in the result,
%   which represents the section of FileName which contains a copy of
%   the text in Text<i>.

copy_texts(ListOfTexts, FileName, ListOfNewBigTexts) :-
	atom(FileName),
	(   'QBopen'(_),		% open a scratch file
	    copy_texts(ListOfTexts, FileName, 0, ListOfNewBigTexts),
	    'QBrename'(FileName)	% close scratch, rename to FileName
	;   'QBclose',			% close and delete it
	    'QBdelete'
	), !.

copy_texts([], _, _, []).
copy_texts([Text|Texts], FileName, Offset,
		[big_text(FileName,Offset,Length)|BigTexts]) :-
	write_text(Text),
	'QBtell'(Position),
	Length is Position-Offset,
	copy_texts(Texts, FileName, Position, BigTexts).


%   pipe_to_text(+UnixCommand, +FileName, ?BigText)
%   appends the output of UnixCommand to FileName, and
%   binds BigText to a big_text containing that output.

pipe_to_text(UnixCommand, FileName, big_text(FileName,Offset,Length)) :-
	(   file_property(FileName, size_in_bytes, Offset) -> true
	;   Offset = 0			% assume file does not exist yet
	),
	system([UnixCommand,' >>',FileName]),
	file_property(FileName, size_in_bytes, Size),
	Length is Size-Offset.




%   send_editor(+Format, +Args)
%   is adapted from Vince Pecora's send_editor/1 in library(menu).
%   The only difference between the two is that his command takes
%   a list of atoms and concatenates them, while mine takes a
%   format and a list of arguments which may be rather clearer.

send_editor(Format, Args) :-
	begin_critical,
	put(user_output, 30),		% start of editor command
	format(user_output, Format, Args),
	put(user_output, 29),		% end of editor command
	flush_output(user_output),
	end_critical.


%   have_emacs_edit(+FileName, +BufferName)
%   commands Emacs to select the window immediately above the
%   Prolog window, to view buffer BufferName there, and to
%   replace the previous contents of BufferName (if any) by
%   the file FileName.  When you save the edits, FileName will
%   be updated.  While this code is running, Emacs *cannot*
%   send to Prolog.

have_emacs_edit(FileName, BufferName) :-
	atom(FileName),
	atom(BufferName),
	send_editor(
'(pop-to-buffer "qprolog")(previous-window)(switch-to-buffer "~w")(erase-buffer)
 (error-occurred (insert-file "~w"))(change-current-filename "~w")',
		[BufferName, FileName, FileName]).


%   have_emacs_edit(+FileName)
%   commands Emacs to select the window immediately above the
%   Prolog window, and to edit the file FileName there in a buffer
%   whose name is the last component of FileName.
%   See have_emacs_edit/2 for some restrictions.

have_emacs_edit(FileName) :-
	file_name_to_buffer_name(FileName, BufferName),
	have_emacs_edit(FileName, BufferName).


file_name_to_buffer_name(FileName, BufferName) :-
	atom_chars(FileName, FileChars),
	after_slash(FileChars, BufferChars),
	\+ after_slash(BufferChars, _),
	!,
	name(BufferName, BufferChars).
file_name_to_buffer_name(FileName, FileName).


%%  after_slash(FullName, AfterSlash)
%   is true when FullName = <something> ++ "/" ++ AfterSlash

after_slash([47 /* / */|AfterSlash], AfterSlash).
after_slash([_|Rest], AfterSlash) :-
	after_slash(Rest, AfterSlash).


%   edit_text(+Text, +FileName, ?BigText)
%   writes the text to a temporary file, has emacs edit it in a
%   buffer whose name is the last component of FileName), and then
%   and then appends the modified version of the temporary file to
%   FileName, constructing a new BigText.

edit_text(Text, FileName, BigText) :-
	file_name_to_buffer_name(FileName, BufferName),
	edit_text(Text, FileName, BufferName, BigText).


%   edit_text(+Text, +FileName, +BufferName, ?BigText)
%   writes the text to a temporary file, has emacs edit it in the
%   buffer with name BufferName, and then appends the modified version
%   of the temporary file to FileName, constructing a new BigText.

edit_text(Text, FileName, BufferName, big_text(FileName,Offset,Length)) :-
	atom(FileName),
	atom(BufferName),
	(   'QBopen'(TempFile),
	    write_text(Text),
	    'QBclose'
	;   'QBclose', 'QBdelete', fail
	),
	!,
	have_emacs_edit(TempFile, BufferName),
	(   file_property(FileName, readable) ->
	    file_property(FileName, size_in_bytes, Offset)
	;   Offset = 0		% assume it didn't exist
	),
	(   system(['cat ',TempFile,' >>',FileName]) ->
	    file_property(FileName, size_in_bytes, Size),
	    Length is Size-Offset,
	    'QBdelete'
	;   'QBdelete', fail
	).



foreign_file(library(system(libpl)), [
	'QBrename', 'QBclose', 'QBchar', 'QBatom',
	'QBdelete', 'QBopen',  'QBfile', 'QBtell', 'QBshow'
    ]).

foreign('QBopen',	'QBopen'([-string])).
foreign('QBshow',	'QBshow').
foreign('QBrename',	'QBrename'(+string)).
foreign('QBclose',	'QBclose').
foreign('QBdelete',	'QBdelete').
foreign('QBchar',	'QBchar'(+integer)).
foreign('QBatom',	'QBatom'(+string)).
foreign('QBfile',	'QBfile'(+string,+integer,+integer,[-integer])).
foreign('QBtell',	'QBtell'([-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

