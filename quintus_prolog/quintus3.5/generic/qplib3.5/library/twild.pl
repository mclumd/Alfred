%   Package: twild.pl
%   Author : Richard A. O'Keefe
%   Updated: 25 Oct 1990
%   Purpose: Trivial WILD-card matching.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(twild, [
	twild/2,
	twild/3
   ]).
:- use_module(library(types), [
	chars/1,
	should_be/4
   ]).

/*  A trivial wild-card pattern is a non-empty sequence of characters
    containing
	'?'	- matches any single character
	'*'	- matches 0 or more adjacent characters
	other	- other characters match only themselves.

    A Text matches a trivial wild-card pattern if and only if it is a
    non-empty sequence of characters which can be matched up with the
    characters in the pattern so that
	'?' in the pattern matches any character C in the text
	    - to this will correspond an element [C] in Hits
	'*' in the pattern matches any sequence C1...Cn in the text
	    - to this will correspond an element [C1,...,Cn] in Hits
	any other character in the pattern must match the same character
	in the text, and there will be no corresponding element in Hits.

    The pattern and text may be atoms, strings (in Xerox Quintus Prolog),
    or lists of character codes.  For historical reasons we needn't go
    into here, the optional list of Hits will come back as a list of
    atoms.
               
    These operations will never be part of the Quintus Prolog system and
    will not be part of the supported library because they are so trivial
    and so system-specific.  They were written to simplify conversion from
    another dialect, not because they are useful in themselves.  For
    example, the UNIX features
	[..character set...]
	~user
	{alt1,...,altn}
    are not supported.  VMS users would presumably want
    case-independence, and some of the other wild-carding features of
    VMS (such as wild ancestors).  And of course it doesn't make much
    sense in MVS.  This file should be regarded as an example of how to
    go about implementing this kind of operation.
*/

sccs_id('"@(#)90/10/25 twild.pl	58.1"').


twild(Pattern, Text) :-
	non_empty_chars(Pattern, P),
	non_empty_chars(Text, T),
	!,
	twild_1(P, T, _).
twild(Pattern, Text) :-
	Goal = twild(Pattern, Text),
	should_be(text, Pattern, 1, Goal),
	should_be(text, Text,    2, Goal),
	fail.


twild(Pattern, Text, Hits) :-
	non_empty_chars(Pattern, P),
	non_empty_chars(Text, T),
	!,
	twild_1(P, T, H),
	chars_to_atoms(H, Hits).
twild(Pattern, Text, Hits) :-
	Goal = twild(Pattern, Text, Hits),
	should_be(text, Pattern, 1, Goal),
	should_be(text, Text,    2, Goal),
	fail.


non_empty_chars(Source, Chars) :-
	(   atom(Source) ->
	    atom_chars(Source, Chars)
    %	;   string(Source) ->
    %	    string_chars(Source, Chars)
	;   chars(Source) ->
	    Chars = Source
	),
	Chars \== [].
	


chars_to_atoms([], []).
chars_to_atoms([Text|Texts], [Atom|Atoms]) :-
	atom_chars(Atom, Text),
	chars_to_atoms(Texts, Atoms).


twild_1([], [], []).
twild_1([Char|Chars], Text, Hits) :-
	twild_1(Char, Text, Text1, Hits, Hits1),
	twild_1(Chars, Text1, Hits1).

twild_1(0'?, [Hit|Text1], Text1, [[Hit]|Hits1], Hits1) :- !.
twild_1(0'*, Text, Text1, [Hit|Hits1], Hits1) :- !,
	append(Hit, Text1, Text).
twild_1(Chr, [Chr|Text1], Text1, Hits1, Hits1).


