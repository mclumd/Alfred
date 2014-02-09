%   Package: aritystrings
%   Authors: Richard A. O'Keefe, Tom Howland
%   Updated: 30 Dec 1993
%   Purpose: Support for Arity's string operations.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(apstring, [
	string_search/3,
	string_search/4,
	arity_substring/4,
	nth_char/3,
	concat/3,
	concat/2,
	string_term/2,
	atom_string/2,
	int_text/2,
	float_text/3,
	list_text/2,
	read_string/2,
	read_string/3,
	read_line/1,
	read_line/2
   ]).
:- use_module(library(strings), [
	nth_char/3,
	substring/4,
	concat/3,
	concat_atom/2
   ]).

:- use_module(library(charsio), [
	term_to_chars/2,
	chars_to_term/2,
	with_output_to_chars/2
   ]).

:- use_module(library(ctypes), [is_ascii/1]).

sccs_id('"@(#)93/12/30 aritystrings.pl  71.1"').

/*

Arity:	 atom limit 255, string limit 64K
Quintus: atom limit 32K, strings not provided.

Porting an Arity program to Quintus Prolog will thus run into two kinds
of problems:

(1) Unexpected success.  Attempts to create long atoms will succeed in
    Quintus Prolog, where they would have failed in Arity.  That means
    that the programs may not port back.

(2) Unexpected error.  Valid Arity code working with strings within
    Arity's string length bound may run into the 32k limit on Quintus
    atoms.

On the other hand, if you are trying to manipulate strings with that
many characters your program is _extremely_ likely to benefit from
restructuring.  (Consider a list of atoms, for example, or perhaps a
tree).  Strings are in general a very costly way of handling text,
compared with ordinary Prolog data structures.

Our conversion package includes arity_read/1, which reads $...$ forms
as atoms.  string(X) succeeds when X is an atom.
*/

%   string_search(SubString, String, Offset)
%   is true when String = A // SubString // Z and string_length(A,Z)
%   It is already in library(strings).  See our library manual.
string_search(SubString, String, Location) :-
	is_ascii(SubString) ->
	     strings:string_search([SubString], String, Location);
	     strings:string_search(SubString, String, Location).

%   string_search(CaseFlag, SubString, String, Offset)
%   is the same as string_search/3 when CaseFlag is 0, is like it but
%   ignores alphabetic case when CaseFlag is 1.  There is something
%   very important for you to realise if you want to make your code
%   portable between Arity/Prolog on a PC and Quintus Prolog on a
%   workstation:  IBM have their own private extension of ASCII,
%   while Quintus Prolog assumes the ISO 8859/1 character set, also
%   an extension of ASCII.  The upper halves of the two are very
%   unlike.  The code here to convert to lower case is specific to
%   the ISO 8859/1 character set.  Your data may have to be recoded.
%   That isn't always possible, because IBM's private character set
%   contains a lot of masks for drawing boxes, which have no
%   equivalent in ISO 8859/1.  Conversely, ISO 8859/1 has a lot of
%   important letters which have no equivalent in IBM's set.

string_search(0, SubString, String, Location) :-
	is_ascii(SubString) ->
	     strings:string_search([SubString], String, Location);
	     strings:string_search(SubString, String, Location).
string_search(1, SubString, String, Location) :-
	name(String, StringChars),
	(is_ascii(SubString) ->
	     SubStringChars = [SubString];
	     name(SubString, SubStringChars)),
	lower_chars(StringChars, StringLower),
	lower_chars(SubStringChars, SubStringLower),
	locate(SubStringLower, StringLower, 0, Location).

lower_chars([], []).
lower_chars([C|Cs], [L|Ls]) :-
	( C =< 122, C >= 97 -> L is C-32
	; C >= 224, C =< 254, C =\= 247 -> L is C-32
	; L is C
	),
	lower_chars(Cs, Ls).

locate(M, S, L, L) :-
	prefix(M, S).
locate(M, [_|S], L0, L) :-
	L1 is L0+1,
	locate(M, S, L1, L).

prefix([], _).
prefix([C|Xs], [C|Ys]) :-
	prefix(Xs, Ys).



%   arity_substring(String, Offset, Length, SubString)
%   is true when String = A // SubString // Z, |A| = Offset,
%   and |SubString| = Length.  It is the same as substring/4
%   from our library, except for the argument order.  The argument
%   order in our library ie very far from being arbitrary!

arity_substring(String, Offset, Length, SubString) :-
	substring(String, SubString, Offset, Length).


%   nth_char(Offset, String, Char)
%   is already in our library.  It is like string_char/3, except that
%   it counts from 0 rather than 1 (strange).


%   string_length(String, Length)
%   is already in our library


%   concat(A, Z, AZ)
%   is already in our library.  There is one subtle difference:
%   if A is an atom, this will make AZ an atom, while Arity's version
%   will make a string.  But this only shows up when strings are not
%   implemented as atoms.

%   concat(Texts, String)
%   In our library, we have several versions of this, depending on what
%   they are supposed to produce.  It should be concat_string/2, but in
%   the absence of strings...

concat(Texts, String) :-
	concat_atom(Texts, String).


%   string_term(String, Term)
%   is thoroughly wierd.  A name like this should only be used when the
%   predicate is bidirectional.  But this one ISN'T.  I do not follow
%   the examples in the Arity manual (S9.2.1 P118), they say that
%	string_term($put(7)$, X) ==> X = put(7)
%   but they also say that
%	string_term(S, 99) ==> S = $j$
%   I would have expected S = $99$, and that's what you'll get here.

string_term(String, Term) :-
    (   var(String)
    ->  term_to_chars(Term, Chars),
        atom_chars(String, Chars)
    ;   atomic(String)
    ->  name(String, Chars1),
        remove_ending_period(Chars1, Chars),
        chars_to_term(Chars, Term)
    ;   format(user_error,
	       '~N! Argument ~w of ~q is invalid.~n! Goal: ~q~n',
	       [1, string_term/2, string_term(String,Term)])
    ).

%  in converting an atom to a term, remove the ending period (if any) so
%  chars_to_term doesn't choke.

remove_ending_period(Chars1, Chars) :- append(Chars, ".", Chars1), !.
remove_ending_period(Chars, Chars).

%   atom_string(Atom, String)
%   is a bijection betwen atoms and strings.  The cases are
%	Atom	String	Action
%	var	var	instantiation fault
%	var	string	make Atom
%	atom	var	make String
%	atom	string	check equivalence
%	other	-	type failure (atom expected)
%	-	other	type failure (string expected)
%   However, when strings are implemented as atoms, we just have

atom_string(X, X).

/*
atom_string(Atom, String) :-
	(   atom(Atom) ->
	    atom_chars(Atom, Chars),
	    string_chars(String, Chars)
	;   var(Atom) ->
	    string_chars(String, Chars),
	    atom_chars(Atom, Chars)
	;   must_be_atom(Atom, 1, atom_string(Atom,String))
	).
*/

%   int_text(Integer, Text)
%   is pretty weird too.  It is supposed to convert integers to strings,
%   but any sort of named thing to an integer.

int_text(Integer, Text) :-
	(   var(Text) ->
	    integer(Integer),
	    number_chars(Integer, Chars),
	    atom_chars(Text, Chars)
	;   name(Text, Chars),
	    number_chars(Integer, Chars),
	    integer(Integer)
	).

%   There is a version of string_chars/2 in library(strings) which
%   reports a representation fault.  If/when we support strings on
%   ordinary workstations, this definition should be deleted and
%   the correct one used.

string_chars(String, Chars) :-
	atom_chars(String, Chars).


%   list_text(Chars, Text)
%   is similar to string_chars/2 but does not have its simplicity.
%   This has been reconstructed as well as I can from the description
%   in the Arity manual.

list_text(Chars, Text) :-
	(   var(Text) ->
	    atom_chars(Text, Chars)
	;   name(Text, Chars)
	).


%   float_text(Float, Text, Style)
%   is really strange.  It cannot be given a logical reading.

float_text(Float, Text, Style) :-
	(   atomic(Text) ->
	    name(Text, Chars),
	    number_chars(X, Chars),
	    Float is float(X)
	;   var(Text), number(Float) ->
	    X is float(Float),
	    float_text_1(Style, X, Chars),
	    atom_chars(Text, Chars)
	).

float_text_1(general, X, Chars) :-
	number_chars(X, Chars).
float_text_1(fixed(N), X, Chars) :-
	with_output_to_chars(format('~*f', [N,X]), Chars).
float_text_1(scientific(N), X, Chars) :-
	with_output_to_chars(format('~*e', [N,X]), Chars).


%   read_string([Stream, ] MaxLength, String)
%   reads from the current input stream [from Stream] until MaxLength
%   characters have been read or the end of the stream is reached,
%   whichever happens sooner, and returns a String containing all
%   those characters.  Note that the end-of-file border may be consumed;
%   if String=$$ afterwards and MaxLength>0, the end of the file was
%   reached.


read_string(MaxLength, String) :-
	integer(MaxLength),
	read_chars(MaxLength, Chars),
	atom_chars(String, Chars).

read_string(Stream, MaxLength, String) :-
	integer(MaxLength),
	current_input(OldInput),
	see(Stream),
	read_chars(MaxLength, Chars),
	set_input(OldInput),
	atom_chars(String, Chars).


read_chars(N, [C|Cs]) :-
	N > 0,
	get0(C),
	C >= 0,
	!,
	M is N-1,
	read_chars(M, Cs).
read_chars(_, []).


%   read_line([Stream, ]String)
%   reads characters from the current input stream [from Stream] until
%   either a new-line character or the end of file border has been
%   consumed.  Whichever of the two characters terminates the read,
%   the terminator is not included in the String.  See get_line/1
%   in our library.

read_line(String) :-
    read_line(user_input, String).

read_line(Stream, String) :-
    current_input(Old),
    set_input(Stream),
    (   read_line_chars(Chars)
    ->  set_input(Old)
    ;   set_input(Old), fail
    ),
    atom_chars(String, Chars).

read_line_chars(L) :-
    on_exception(existence_error(get0(_),_,_,_,errno(1001)),
		 get0(First),
		 (!,fail)
		),
    First =\= -1,
    (   First =:= 10
    ->  L = []
    ;   L = [First|Chars], read_line_chars2(Chars)
    ).

read_line_chars2([C|Cs]) :-
  on_exception(existence_error(get0(_),_,_,_,errno(1001)), get0(C), (!,fail)),
  C >= 0, C =\= 10,
  !,
  read_line_chars2(Cs).
read_line_chars2([]).


