%   Module : ask
%   Author : Richard A. O'Keefe
%   Updated: 25 Oct 1990
%   Purpose: ask questions that have a one-character answer.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(ask, [
	ask/2,
	ask/3,
	ask_between/4,
	ask_between/5,
	ask_chars/4,
	ask_default_character/2,
	ask_file/2,
	ask_file/3,
	ask_number/2,
	ask_number/3,
	ask_number/4,
	ask_number/5,
	ask_oneof/3,
	ask_oneof/4,
	yesno/1,
	yesno/2
   ]).
:- use_module(library(ctypes), [
	is_endline/1,
	is_graph/1,
	to_lower/2
   ]),
   use_module(library(prompt), [
	prompt/1,
	prompted_char/2,
	prompted_line/2
   ]),
   use_module(library(files), [
	can_open_file/3
   ]).

:- mode
	ask(+, ?),
	ask(+, +, ?),
	ask_between(+, +, +, ?),
	ask_between(+, +, +, +, ?),
	ask_chars(+, +, +, ?),
	ask_default_character(+, -),
	ask_file(+, -),
	ask_file(+, +, -),
	ask_number(+, ?),
	ask_number(+, +, ?),
	ask_number(+, +, +, ?),
	ask_number(+, +, +, +, ?),
	ask_oneof(+, +, ?),
	ask_oneof(+, +, +, ?),
	prefix_of_unique(+, +, ?),
	prefix_of_unique(+, +, ?, ?),
	yesno(+),
	yesno(+, +).

sccs_id('"@(#)90/10/25 ask.pl	58.1"').


/*  The predicates in this file are described in the Quintus Prolog
    Library manual.  They always write a prompt to the terminal (or
    rather, to user_output) and read a one-line response from the
    terminal (or rather, from user_input).  If you want the user of
    your program to enter one-character responses, you should use
    these routines rather than calling get0/1 or get/1 directly.
    Typically, the routines have an optional Default parameter so
    that the user can hit ENTER or RETURN and get that default but
    if you do not supply a Default the user must enter something.
    If the response is not acceptable, the user will be told what
    sort of response is expected, and re-prompted.  "?" is usually
    an invalid response.
*/

%   ask_default_character(+Spec, ?Char)
%   lets the programmer specify the default character in whatever way
%   s/he finds convenient, either as an integer, as a string, or as a
%   Prolog atom.  The case of the character is preserved.  We export
%   it so your program can use the same convention elsewhere.

ask_default_character(Spec, Char) :-
	(   integer(Spec) -> Char = Spec
	;   atomic(Spec)  -> name(Spec, [Char|_])
	;   Spec = [Head|_], nonvar(Head),
	    ask_default_character(Head, Char)
	).

%   ask(+Question, ?Answer)
%   displays the Question on the  terminal  and  reads  a  one-character
%   answer  from the terminal.  But because you normally have to type "X
%   <CR>" to get the computer to attend to you, it skips to the  end  of
%   the line.   The character returned will have ASCII code in the range
%   33..126 (that is, it won't be a space or a control character).

ask(Question, Answer) :-
	repeat,
	    prompted_char([Question,'? '], Char),
	    is_graph(Char),
	!,
	Answer = Char.



%   ask(+Question, +Default, ?Answer)
%   is like ask(Question, Answer) except that if the user types a newline
%   the Default will be taken as the Answer.

ask(Question, Default, Answer) :-
	ask_default_character(Default, DefChar),
	repeat,
	    prompted_char([Question,' [',{DefChar},']? '], Char),
	    (   is_endline(Char), !, Answer = DefChar
	    ;   is_graph(Char), !, Answer = Char
	    ).



%   yesno(+Question)
%   asks the question, and succeeds if the answer is y or Y, fails if
%   the answer is n or N, and repeats the question if it is anything else.

yesno(Question) :-
	repeat,
	    prompted_char([Question,'? '], Char),
	    to_lower(Char, Answer),
	    (   Answer =:= "y" -> !, true
	    ;   Answer =:= "n" -> !, fail
	    ;	prompt('Please answer Yes or No followed by RETURN'), ttynl,
		fail
	    ).


%   yesno(+Question, +Default)
%   is like yesno(Question), except that if the user types a newline
%   without a Y or N the default will be used.  It should of course
%   be y or n itself.

yesno(Question, Default) :-
	ask_default_character(Default, DefChar),
	repeat,
	    prompted_char([Question,' [',{DefChar},']? '], Char),
	    to_lower(Char, Answer),
	    (   is_endline(Char), !,	% use the default
		    to_lower(DefChar, 0'y)
	    ;   Answer =:= "y" -> !, true
	    ;   Answer =:= "n" -> !, fail
	    ;   prompt('Please answer Yes or No followed by RETURN'), ttynl,
		fail
	    ).



%   ask_file(+Prompt, -FileName)
%   prompts for a file name and returns it as an atom.  This is done using
%   prompted_line/2.  There are two more points:
%   (1) if the file name is empty (user hit carriage return), ask_file/2
%   just quietly FAILS.  This can be used to control loops.
%   (2) this is meant for reading the names of INPUT files, so it calls
%   file_must_exist/2 to check that the file exists and can be read.  If
%   the file does not exist or can't be read, it prompts again.
%   This should ONLY be called with Prompt BOUND and FileName UNBOUND.

ask_file(Prompt, FileName) :-
	ask_file(Prompt, read, FileName).


%   ask_file(+Prompt, +Mode, -FileName)
%   prompts for a FileName which you have permission to open in the
%   given Mode (see can_open_file/3 in library(files)).  Two points:
%   (1) if the file name is empty (user hit carriage return), ask_file/3
%   just quietly FAILS.  This is typically used for specifying that the
%   user does not want a particular file written or otherwise processed.
%   (2) File names beginning with "?" cannot be entered, as that is
%   taken to mean that the user wants help.

ask_file(Prompt, Mode, FileName) :-
	repeat,
	    prompted_line(Prompt, Chars),
	    (   Chars = "" -> true, !, fail
	    ;   Chars = [0'?|_] ->
		format(user_output,
'~NPlease enter the name of a file which can be opened in
~a mode, followed by a RETURN.  To terminate this operation,
just type a RETURN with no file name.~n', [Mode]), fail
	    ;   name(FileName, Chars),
		can_open_file(FileName, Mode, warn)
	    ),
	!.



%   ask_number(+Prompt, ?Answer)
%   asks a question where the answer should be some sort of number,
%   either integer or float.  The answer is left as whatever type
%   the user supplied:  integers are not converted to floats.  As
%   a convenience, layout, "+", and "_" are ignored.

ask_number(Prompt, Answer) :-
	repeat,
	    prompted_numeric_line([Prompt,': '], Chars),
	    (   number_chars(X, Chars)
	    ;   format(user_output,
		       '~NPlease enter a number followed by RETURN~n',
		       []), fail
	    ),
	!,
	Answer = X.

%   ask_number(+Prompt, +Default, ?Answer)
%   asks a question where the answer should be some sort of number,
%   either integer or float.  The answer is left as whatever type
%   the user supplied:  integers are not converted to floats.  If
%   the user supplies an empty line, the Default (which need not
%   be a number) is returned.  Layout, "+", and "_" are ignored.

ask_number(Prompt, Default, Answer) :-
	repeat,
	    prompted_numeric_line([Prompt,' [',Default,']: '], Chars),
	    (   Chars = "", X = Default
	    ;   number_chars(X, Chars)
	    ;   format(user_output,
		    '~NPlease enter a number followed by RETURN~n',
		    []),
		fail
	    ),
	!,
	Answer = X.


%   ask_number(+Prompt, +Lower, +Upper, ?Answer)
%   asks a question where the answer should be a number in the range
%   Lower..Upper.  This is like ask_number/2 except for checking the
%   range.  Ass also ask_between/4 which insists on an integer.

ask_number(Prompt, Lower, Upper, Answer) :-
	repeat,
	    prompted_numeric_line([Prompt,': '], Chars),
	    (   number_chars(X, Chars), X >= Lower, X =< Upper
	    ;	format(user_output,
		    '~NPlease enter a number between ~w and ~w followed by RETURN~n',
		    [Lower,Upper]),
		fail
	    ),
	!,
	Answer = X.

%   ask_number(+Prompt, +Lower, +Upper, +Default, ?Answer)
%   asks a question where the answer should be a number in the range
%   Lower..Upper.  If the user enters an empty line, the Default
%   (which need not be in range, or even a number) is returned.
%    A typical use might be ask_number('Percentage', 0, 100, 50, Percentage).

ask_number(Prompt, Lower, Upper, Default, Answer) :-
	repeat,
	    prompted_numeric_line([Prompt,' [',Default,']: '], Chars),
	    (   Chars = "", X = Default
	    ;   number_chars(X, Chars), X >= Lower, X =< Upper
	    ;	format(user_output,
		   '~NPlease enter a number between ~w and ~w followed by RETURN~n',
		   [Lower,Upper]),
		fail
	    ),
	!,
	Answer = X.



%%  prompted_numeric_line(+Prompt, ?Chars)
%   is a version of prompted_line/2 which strips away layout characters,
%   underscores, and leading "+" signs from its result.  It also strips
%   any "."s which are not followed by a digit, so that it does no harm
%   to enter "123." as if you were typing to read/1.

prompted_numeric_line(Prompt, Neat) :-
	prompted_line(Prompt, Chars),
	filter_numeric(Chars, 0, Neat).

filter_numeric([], _, []).
filter_numeric([Char|Raw], State, Neat) :-
	(   Char =< " " -> true
	;   Char =:= "_" -> true
	;   Char =:= "+" -> State =:= 0
	;   Char =:= "." -> not_before_a_digit(Raw)
	;   fail
	),
	!,
	filter_numeric(Raw, State, Neat).
filter_numeric([Char|Raw], _, [Char|Neat]) :-
	filter_numeric(Raw, 1, Neat).

not_before_a_digit([]).
not_before_a_digit([X|_]) :- ( X < "0" -> true ; X > "9" -> true ).




%   ask_oneof(+Prompt, +Constants, ?Selected)
%   expects an answer to be (a prefix of) one of the constants in the
%   given list of Constants.  INPUT CASE IS SIGNIFICANT.

ask_oneof(Prompt, Constants, Selected) :-
	repeat,
	    prompted_line([Prompt,': '], Chars),
	    (   prefix_of_unique(Constants, Chars, X)
	    ;   format(user_output,
'~NPlease enter one of these constants:~n	~p
followed by a RETURN.  Do not add a full stop.~n', [Constants]),
		fail
	    ),
	!,
	Selected = X.


%   ask_oneof(+Prompt, +Constants, +Default, ?Selected)
%   expects an answer to be (a prefix of) one of the constants in the
%   given list of constants.  If the user enters an empty line, the
%   Default (which need not be among the Constants) is returned.
%   INPUT CASE IS SIGNIFICANT.

ask_oneof(Prompt, Constants, Default, Selected) :-
	repeat,
	    prompted_line([Prompt,' [',Default,']: '], Chars),
	    (   Chars = "", X = Default
	    ;   prefix_of_unique(Constants, Chars, X)
	    ;   format(user_output,
'~NPlease enter one of these constants~n	~p
followed by a RETURN.  If you just type RETURN,~n	~p
will be taken as your answer.  Do not add a full stop.~n',
		    [Constants,Default]),
		fail
	    ),
	!,
	Selected = X.


%%  prefix_of_unique(Constants, Chars, Selected)
%   is true when (1) Chars is the name/2 of Selected which is a member of
%   the list of constants Constants, or (2) Chars is a prefix of that
%   name, and there is only 1 such element.

prefix_of_unique(_, [0'?|_], _) :- !,
	fail.
prefix_of_unique(Constants, Chars, Selected) :-
	prefix_of_unique(Constants, Chars, _, Selected).


prefix_of_unique([], _, Flag, Selected) :- !,
	nonvar(Flag),
	Selected = Flag.
prefix_of_unique([Constant|_], Chars, _, Selected) :-
	name(Constant, Chars),
	!,					% exact match
	Selected = Constant.
prefix_of_unique([Constant|Constants], Chars, Flag, Selected) :-
	\+ (name(Constant,L), \+ append(Chars,_,L)),
	!,					% prefix
	Flag = Constant,
	prefix_of_unique(Constants, Chars, Flag, Selected).
prefix_of_unique([_|Constants], Chars, Flag, Selected) :-
	prefix_of_unique(Constants, Chars, Flag, Selected).




%   ask_between(+Prompt, +Lower, +Upper, ?Answer)
%   asks a question where the answer should be an integer in the range
%   Lower..Upper.  This predicate does not check that Lower and Upper
%   make sense.  Here is an example:
%   ask_between('Delete item', 1, N, Index).

ask_between(Prompt, Lower, Upper, Answer) :-
	repeat,
	    prompted_numeric_line([Prompt,': '], Chars),
	    (   number_chars(X, Chars), integer(X), X >= Lower, X =< Upper
	    ;	format(user_output,
'~NPlease enter an integer between ~d and ~d followed by RETURN.~n',
		    [Lower,Upper]), fail
	    ),
	!,
	Answer = X.

%   ask_between(+Prompt, +Lower, +Upper, +Default, ?Answer)
%   asks a question where the answer should be an integer in the range
%   Lower..Upper.  If the user enters an empty line, the Default (which
%   need not be in range, or even an integer) is returned instead.
%   A typical use might be ask_between('Item number', 1, N, 0, Index).

ask_between(Prompt, Lower, Upper, Default, Answer) :-
	repeat,
	    prompted_numeric_line([Prompt,' [',Default,']: '], Chars),
	    (   Chars = "", X = Default
	    ;   number_chars(X, Chars), integer(X), X >= Lower, X =< Upper
	    ;	format(user_output,
'~NPlease enter an integer between ~d and ~d followed by RETURN.~n',
		    [Lower,Upper]), fail
	    ),
	!,
	Answer = X.



%   ask_chars(+Prompt, +MinLength, +MaxLength, ?Answer)
%   expects an answer which is a sequence of between MinLength and MaxLength
%   characters, not beginning with a question mark.

ask_chars(Prompt, MinLength, MaxLength, Answer) :-
	repeat,
	    prompted_line([Prompt,': '], Chars),
	    length(Chars, Length),
	    (   Length >= MinLength, Length =< MaxLength,
		\+ (Chars = [0'?|_])
	    ;   format(user_output,
'~NPlease enter between ~d and ~d characters followed by RETURN.
Do not add a full stop unless it is part of the answer.~n',
		    [MinLength,MaxLength]), fail
	    ),
	!,
	Answer = Chars.

