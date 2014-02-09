%   Module : read_sent
%   Author : Richard A. O'Keefe
%   Updated: 30 Aug 1990
%   Purpose: to provide a flexible input facility

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

/*  The main predicates provided exported by this file are
	read_until(+Delimiters, -Answer)
	read_line(-String)
	trim_blanks(+RawString, -Trimmed)
	read_sentence(-ListOfTokens).
*/

:- module(read_sent, [
	case_shift/2,
	chars_to_words/2,
	read_line/1,
	read_sent/1,
	read_until/2,
	trim_blanks/2
   ]).
:- use_module(library(basics), [
	memberchk/2
   ]),
   use_module(library(ctypes), [
	is_alpha/1,		% A-Z, a-z
	is_digit/2,		% 0-9
	is_endfile/1,		% -1
	is_layout/1,		% doesn't make a mark on the paper
	is_newline/1,		% \n
	is_quote/1,		% '"`
	to_lower/2		% A-Z => a-z ; no other change
   ]).

:- mode
	case_shift(+, -),
	chars_to_atom(-, ?, ?),
	chars_to_integer(+, -, ?, ?),
	chars_to_string(+, -, ?, ?),
	chars_to_words(+, -),
	chars_to_words(-, ?, ?),
	chars_to_word(-, ?, ?),
	read_line(-),
	read_sent(-),
	read_until(+, -),
	read_until(+, +, -),
	trim_blanks(+, -),
	trim_blanks_rest_word(+, -),
	trim_blanks_next_word(+, -).

sccs_id('"@(#)90/08/30 readsent.pl    56.1"').



/*  read_until(?Delimiters, -Answer)
    reads characters from the current input until  a  character  in  the
    Delimiters  string  is  read.  The characters are accumulated in the
    Answer string, and include the closing  delimiter.  The end of file
    character always acts as a delimiter, even if it is not in the list
    of characters you supply.
*/
read_until(Delimiters, [Char|Rest]) :-
	get0(Char),
	read_until(Char, Delimiters, Rest).


read_until(Char, _, []) :-
	is_endfile(Char),
	!.
read_until(Char, Delimiters, []) :-
	memberchk(Char, Delimiters),
	!.
read_until(_, Delimiters, [Char|Rest]) :-
	get0(Char),
	read_until(Char, Delimiters, Rest).



/*  trim_blanks(+RawInput, ?Cleaned)
    removes leading and trailing layout characters  from  RawInput,  and
    replaces  internal  groups  of  layout  characters by single spaces.
    Thus trim_blanks(<|TAB TAB a SP ^M ^E b ^Z|>, "a b") would be true.
    The 2.5 release of this predicate is steadfast.
*/
trim_blanks([], []).
trim_blanks([Char|Chars], Cleaned) :-
	is_layout(Char),
	!,
	trim_blanks(Chars, Cleaned).
trim_blanks([Char|Chars], [Char|Cleaned]) :-
	trim_blanks_rest_word(Chars, Cleaned).


trim_blanks_rest_word([], []).
trim_blanks_rest_word([Char|Chars], Cleaned) :-
	is_layout(Char),
	!,
	trim_blanks_next_word(Chars, Cleaned).
trim_blanks_rest_word([Char|Chars], [Char|Cleaned]) :-
	trim_blanks_rest_word(Chars, Cleaned).


trim_blanks_next_word([], []).
trim_blanks_next_word([Char|Chars], Cleaned) :-
	is_layout(Char),
	!,
	trim_blanks_next_word(Chars, Cleaned).
trim_blanks_next_word([Char|Chars], [0' ,Char|Cleaned]) :-
	trim_blanks_rest_word(Chars, Cleaned).



/*  chars_to_words(+Chars, ?Words)
    parses a list of characters (read by read_until) into a list of
    tokens, where a token is
	'X'	    for X a full stop[*] or other punctuation mark, e.g. ';'
	atom(X)	    for X a sequence of letters, e.g. atom(the)
	integer(X)  for X a sequence of digits, e.g. integer(12)
	apost	    for '
	aposts	    for 's
	string(X) for X "..sequence of any.."
    Thus the string "the "Z-80" is on card 12." would be parsed as
	[atom(the),string('Z-80'),atom(is),atom(on),atom(card),
	 integer(12),'.'].
    It is up to the sentence parser to decide what to do with these.
    Note that the final full stop[*], if any, is retained, as the
    parser may need it.

    Linguistic note:  the word "period" means a sentence.  One character
    which ends a period is called a full stop, "stop" being the name for
    a punctuation mark which represents a pause.  A full stop is normally
    followed by layout, but the layout is not part of the full stop.  Two
    other characters can end sentences: the exclamation point and the
    question mark.  They are stops too.
*/
chars_to_words(Chars, Words) :-
	chars_to_words(Words, Chars, []).


chars_to_words([]) --> [].
chars_to_words([Word|Words]) -->
	chars_to_word(Word),
	chars_to_words(Words).


chars_to_word(Word) -->
	[Char],
	(   {is_alpha(Char)} ->		% either case letter
	    chars_to_atom(Chars),
	    {case_shift([Char|Chars], Name)},
	    {atom_chars(Atom, Name)},
	    {Word = atom(Atom)}
	;   {is_digit(Char, N0)} ->	% <decimal> digit
	    chars_to_integer(N0, N),
	    {Word = integer(N)}
	;   {Char =:= "'"} ->		% apostrophe
	    (   "s" -> {Word = aposts}	% 's
	    ;   "S" -> {Word = aposts}	% 'S
	    ;          {Word = apost }	% '
	    )
	;   {is_quote(Char)} ->		% " or `
	    chars_to_string(Char, Name),
	    {atom_chars(Atom, Name)},
	    {Word = string(Atom)}
	;   {is_layout(Char)} ->	% space or control character
	    chars_to_word(Word)
	;				% any other printing character
	    {atom_chars(Word, [Char])}
	).


/*- chars_to_atom(Tail)
    reads the remaining characters of a word.  Case conversion  is  left
    to  another  routine.   In this application, a word may only contain
    letters but they may be in either case.  If you want to parse French
    there is no problem as long as you are using ISO 8859/1 -- ctypes.pl
    takes care of that.  If you want to hack embedded accents in ISO646,
    you will need to change this code.
*/
chars_to_atom([Char|Chars]) -->
	[Char], {is_alpha(Char)},
	!,
	chars_to_atom(Chars).
chars_to_atom([]) --> [].


/*  case_shift(+Mixed, ?Lower)
    converts all the upper case letters in Mixed to lower  case.   Other
    characters (not necessarily letters!) are left alone.  If you decide
    to accept other characters in words only chars_to_atom has to alter.
    See also lower/2 in library(caseconv).
*/
case_shift([], []).
case_shift([Char|Chars], [Letter|Letters]) :-
	to_lower(Char, Letter),
	case_shift(Chars, Letters).


/*- chars_to_integer(N0, N)
    reads the remaining characters of an integer which starts as N0.
    NB:  this parser does not know about negative numbers or radices
    other than 10, as it was written for PDP-11 Prolog.
*/
chars_to_integer(N0, N) -->
	[Char], {is_digit(Char, Digit)},
	!,
	{N1 is N0*10+Digit},
	chars_to_integer(N1, N).
chars_to_integer(N, N) --> [].


/*- chars_to_string(Quote, String)
    reads the rest of a string which was opened by  a  Quote  character.
    The  string is expected to end with a Quote as well.  If there isn't
    a matching Quote, the attempt to parse the  string  will  FAIL,  and
    thus the whole parse will FAIL.  I would prefer to give some sort of
    error  message and try to recover but that is application dependent.
    Two adjacent Quotes are taken as one, as they are in Prolog itself.
*/
chars_to_string(Quote, [Quote|String]) -->
	[Quote,Quote], !,
	chars_to_string(Quote, String).
chars_to_string(Quote, []) -->
	[Quote], !.
chars_to_string(Quote, [Char|String]) -->
	[Char],
	chars_to_string(Quote, String).


/*  read_line(-Chars)
    reads characters up to the next newline or the end of the file, and
    returns them in a list, including the newline or end of file.  When
    you want multiple spaces crushed out, and the newline dropped, that
    is most of the time, call trim_blanks on the result.  For a routine
    which does not include the newline character in the result, see the
    predicate get_line/1 in library(lineio).
*/
read_line(Chars) :-
	is_newline(NL),
	read_until([NL], Chars).


/*  read_sent(?Words)
    reads characters up to the next period, which may be  several  lines
    distant from the start, skips to the end of that line, and turns the
    result  into  a  list of tokens.  It can happen that the sentence is
    not well formed, if say there is an unmatched double quote.  In that
    case all the characters will still be read, but chars_to_words  will
    fail  and  so  read_sent  will fail.  read_sent will NOT try to read
    another sentence.

    If the end of the current input stream was encountered before a
    closing stop was found, the last element of Chars will be the
    end of file code (-1).  In that case, we must not skip to the
    end of the current line, because any such attempt will signal
    an error.  Also, we should return something distinctive, so any
    caller can tell that end of file was reached.  I have chosen to
    make read_sent/1 return the empty list in this case.  There are
    thus three possible outcomes:
	read_chars(Chars) => Chars = []		end of file hit
	read_chars(Chars) => Chars = [_|_]	well formed words read ok
	read_chars(Chars) => fail		ill formed input
*/
read_sent(Words) :-
	read_until("!?.", Chars),
	(   memberchk(-1, Chars) ->	% end of file was hit
	    Words = []
	;/* nonmember(-1, Chars) */	% terminating stop found
	    is_newline(NL),
	    read_until([NL], _),	% skip to end of line
	    chars_to_words(Chars, Words)
	).
