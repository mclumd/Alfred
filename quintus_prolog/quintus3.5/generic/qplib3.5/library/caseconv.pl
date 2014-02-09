%   Package: caseconv
%   Author : Richard A. O'Keefe
%   Updated: 02 Apr 1994
%   Defines: upper-casing and lower-casing.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(caseconv, [
	lower/1,
	lower/2,
	mixed/1,
	mixed/2,
	upper/1,
	upper/2,
	lower_upper/2
   ]).
:- use_module(library(ctypes), [
	is_alpha/1,
	is_lower/1,
	is_upper/1,
	to_lower/2,
	to_upper/2
   ]),
   use_module(library(strings), [
	string_char/3
   ]).

sccs_id('"@(#)94/04/02 caseconv.pl	72.1"').


/*  This file is intended as an example of how trivially easy it
    is to crunch characters in Prolog, without needing a special
    string data type.  As Xerox Quintus Prolog has strings forced
    on it by Lisp, this package will work nicely with strings if
    it has to (hence the use of library(strings)).  The first
    argument of all of these predicates must be a text object.
    That is, a string (in Xerox Quintus Prolog) or an atom.

    lower(X, Y) converts X to a constant of the same type with
	all upper case letters forced to lower case, binds Y to it.
    upper(X, Y) converts X to a constant of the same type with
	all lower case letters forced to upper case, binds Y to it.
    mixed(X, Y) converts X to a constant of the same type with
	the first letter of each group of letters in upper case,
	subsequent letters of each group in lower case, binds Y to it.

    lower(X) is true when the name of X has no upper case letters.
    upper(X) is true when the name of X has no lower case letters.
    mixed(X) is true when the name of X has letters of both cases.

    As an extra-special fun-type not-to-be-imitated hack,
    {lower,upper,mixed}/2 will convert a **NON-EMPTY** list
    of character codes to the appropriate case pattern, and
    {lower,upper,mixed}/1 will accept a **NON-EMPTY** list
    of character codes of the appropriate case pattern.

    Note the emphasis on **NON-EMPTY**:  an empty list is an atom.
    In most versions of Quintus Prolog, that atom is spelled "[]".
    But in Xerox Quintus Prolog, for compatibility with Lisp, the
    empty list is spelled "NIL" which is three upper-case letters.

    The behaviour of these operations on non-ground arguments or
    arguments which are lists but whose elements are not all
    character codes is NOT DEFINED.  In this release, none of
    these predicates issues error messages in its own name.
    This package is NOT SUPPORTED.
*/


%   lower_upper(?Lower, ?Upper)
%   is true when Lower and Upper are constants of the same type (both
%   atoms or both strings), Lower contains no upper case letters,
%   Upper contains no lower case letters, and wherever one of them
%   contains a letter the other contains the same letter in the
%   opposite case.  This predicate does _not_ work well with languages
%   like German where there are lower case letters which _cannot_ be
%   converted to upper case.

lower_upper(Lower, Upper) :-
	(   atom(Lower) ->
	    atom_chars(Lower, LowerChars),
	    lower_upper_chars(LowerChars, UpperChars),
	    atom_chars(Upper, UpperChars)
	;   nonvar(Lower) ->
	    fail			% type failure
	;   atom(Upper) ->
	    atom_chars(Upper, UpperChars),
	    upper_lower_chars(LowerChars, UpperChars),
	    atom_chars(Lower, LowerChars)
	;   nonvar(Upper) ->
	    fail			% type failure
	;   
	    fail			% instantiation fault
	).


lower_upper_chars([], []).
lower_upper_chars([L|Ls], [U|Us]) :-
	(   is_upper(L) -> fail
	;   to_upper(L, U)
	),
	lower_upper_chars(Ls, Us).


upper_lower_chars([], []).
upper_lower_chars([U|Us], [L|Ls]) :-
	(   is_lower(L) -> fail
	;   to_lower(U, L)
	),
	upper_lower_chars(Us, Ls).



%   lower(+Text, ?Lower)
%   converts an atom, [XQP] string, or non-empty list of character codes
%   Text to lower case.  Lower and Text are the same type of term.

lower(Text, Lower) :-
	(   atom(Text) ->
		atom_chars(Text, TextChars),
		lower_chars(TextChars, LowerChars),
		atom_chars(Lower, LowerChars)
	;   /* maybe a list of character codes */
		lower_chars(Text, Lower)
	).

lower_chars(-, _) :- !, fail.
lower_chars([], []).
lower_chars([T|Ts], [U|Us]) :-
	to_lower(T, U),
	lower_chars(Ts, Us).



%   upper(+Text, ?Upper)
%   converts an atom, [XQP] string, or non-empty list of character codes
%   Text to upper case.  Upper and Text are the same type of term.

upper(Text, Upper) :-
	(   atom(Text) ->
		atom_chars(Text, TextChars),
		upper_chars(TextChars, UpperChars),
		atom_chars(Upper, UpperChars)
	;   /* maybe a list of character codes */
		upper_chars(Text, Upper)
	).

upper_chars(-, _) :- !, fail.
upper_chars([], []).
upper_chars([T|Ts], [U|Us]) :-
	to_upper(T, U),
	upper_chars(Ts, Us).



%   mixed(+Text, ?Mixed)
%   converts an atom, [XQP] string, or non-empty list of character codes
%   Text to mixed case, where the first letter in each block of letters
%   is in upper case and the remaining letters are in lower case.
%   Text and Mixed are the same type of term.

mixed(Text, Mixed) :-
	(   atom(Text) ->
		atom_chars(Text, TextChars),
		mixed_chars(TextChars, MixedChars, 0),
		atom_chars(Mixed, MixedChars)
	;   /* maybe a list of character codes */
		mixed_chars(Text, Mixed, 0)
	).

mixed_chars(-, _, _) :- !, fail.
mixed_chars([], [], _).
mixed_chars([T|Ts], [M|Ms], Flag) :-
	is_alpha(T),
	!,
	(   Flag =:= 0 -> to_upper(T, M)
	;   /* not 1st */ to_lower(T, M)
	),
	mixed_chars(Ts, Ms, 1).
mixed_chars([T|Ts], [T|Ms], _) :-
	mixed_chars(Ts, Ms, 0).



%   lower(+Text)
%   is true when Text is an atom, [XQP] string, or list of character
%   codes containing no upper case letters.

lower(Text) :-
	atomic(Text),
	!,
	\+ ( string_char(_, Text, Upper), is_upper(Upper) ).
lower(Text) :-
	\+ ( chars_char(Text, Upper), is_upper(Upper) ).



%   upper(+Text)
%   is true when Text is an atom, [XQP] string, or list of character
%   codes containing no lower case letters.

upper(Text) :-
	atomic(Text),
	!,
	\+ ( string_char(_, Text, Lower), is_lower(Lower) ).
upper(Text) :-
	\+ ( chars_char(Text, Lower), is_lower(Lower) ).



%   mixed(+Text)
%   is true when Text is an atom, [XQP] string, or list of character
%   codes containing at least one lower case and at least one upper
%   case letter.

mixed(Text) :-
	atomic(Text),
	!,
	string_char(_, Text, Lower), is_lower(Lower),
	!,		% commit to first lower case letter.
	string_char(_, Text, Upper), is_upper(Upper),
	!.		% commit to first upper case letter.
mixed(Text) :-
	chars_char(Text, Lower), is_lower(Lower),
	!,		% commit to first lower case letter.
	chars_char(Text, Upper), is_upper(Upper),
	!.		% commit to first upper case letter.



%%   chars_char(+Chars, -Char)
%    enumerates elements Char of the list of character codes Chars.
%    if Chars is not proper, it will eventually fail.

chars_char([], _) :- !, fail.
chars_char([Char|_], Char).
chars_char([_|Chars], Char) :-
	chars_char(Chars, Char).




