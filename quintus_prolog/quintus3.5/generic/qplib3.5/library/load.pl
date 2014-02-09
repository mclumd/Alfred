%   Package: load
%   Author : Richard A. O'Keefe
%   Updated: 11/19/89
%   Purpose: Load a dynamic relation from a formatted file.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(load, [
	integer_chars/2,
	load/3,
	load_record/1
   ]).
:- meta_predicate
	load(+, 0, +).

sccs_id('"@(#)89/12/04 load.pl  36.1"').


/*  load(FileName, Clause, Fields)
    FileName is anything which is acceptable to open/3 as a file name.
    Clause is anything which is acceptable to assert/1 as a clause.
    Fields is a list of field specifications.  In this preliminary
    version of load/3, a field specification is

	nl				-- skip to and consume a new-line
	skip(N)				-- skip over N characters
	field(N, Type, Var)		-- take exactly N characters
	repeat(K, N, Type, Var)		-- list of field()s

    There is no implicit 'nl' in a list of Fields, so it is possible to
    read files made of fixed-length records with no new-lines.  There
    may be any number of 'nl's in a list of Fields, so it is possible to
    read "records" that consist of several lines.

    repeat(K, N, Type, Var) binds Var to [X1,...,Xk] as if there had
    been field(N,Type,X1),...,field(N,Type,Xk).  For example, if there
    are 51 single-digit fields in a particular record,
	repeat(51, 1, integer, Digits)
    will bind Digits to a list of 51 integers.

    Type is one of

	atom				-- Var is an atom
	chars				-- Var is a list of characters
	integer				-- Var is an integer
	float				-- Var is a float
	number				-- Var is a number of any sort
	name				-- give Chars to name/2
	code([Cs=V,...,Cs=V|V])		-- one of a set of codes.

    This package is definitely NOT in its final form.  It is likely to be
    improved beyond recognition.
*/
load(FileName, Clause, Fields) :-
	open(FileName, read, Stream),
	current_input(OldInput),
	set_input(Stream),
	repeat,
	    \+ (load_record(Fields), assert(Clause)),
	!,
	set_input(OldInput),
	close(Stream).


/*  load_record(Fields)
    reads a single record (which may span part of a line, a whole line, or
    several lines) according to the list of Fields.  The field list holds
    the variables whose values are to be filled in.
*/
load_record([]).
load_record([Field|Fields]) :-
	load_field(Field),
	load_record(Fields).


load_field(nl) :-
	skip(10).
load_field(skip(N)) :-
	skip1(N).
load_field(field(N, T, V)) :-
	field1(N, Chars),
	field2(T, Chars, V).
load_field(repeat(K, N, T, V)) :-
	load_list(K, N, T, V).	


load_list(0, _, _, []) :- !.
load_list(K, N, T, [V|Vs]) :-
	K > 0, J is K-1,
	field1(N, Chars),
	field2(T, Chars, V),
	load_list(J, N, T, Vs).


skip1(N) :-
	( N > 0 -> M is N-1, get0(D), D >= 0, skip1(M) ; true ).


field1(N, Chars) :-
	get0(C),
	C >= 0,
	field1(N, C, Chars).

field1(N, C, [C|Cs]) :-
	( N > 1 -> M is N-1, get0(D), D >= 0, field1(M, D, Cs) ; Cs = [] ).


field2(atom, Chars, Atom) :-
	atom_chars(Atom, Chars).
field2(integer, Chars, Integer) :-
	trim(Chars, Cs),
	integer_chars(Integer, Cs).
field2(float, Chars, Float) :-
	trim(Chars, Cs),
	number_chars(X, Cs),
	Float is float(X).
field2(number, Chars, Number) :-
	trim(Chars, Cs),
	number_chars(Number, Cs).
field2(name, Chars, Atomic) :-
	trim(Chars, Cs),
	name(Atomic, Cs).
field2(chars, Chars, Chars).
field2(trim,  Chars, Cs) :-
	trim(Chars, Cs).
field2(code(L), Chars, Value) :-
	field_code(L, Chars, Value).


field_code([Chars=Value|_], Chars, Value) :- !.
field_code([_=_|L], Chars, Value) :- !,
	field_code(L, Chars, Value).
field_code(Default, _, Default).


/*  trim(+Chars, -Trimmed)
    is lifted from library(readsent).  The point is that if a field
    contains a number we want to discard leading/trailing layout; it
    was easiest for me to pick up this routine which compresses any
    internal layout sequences to single blanks, which isn't likely
    to hurt.
*/
trim([], []).
trim([Char|Chars], Cleaned) :- Char =< " ", !,
	trim(Chars, Cleaned).
trim([Char|Chars], [Char|Cleaned]) :-
	trim1(Chars, Cleaned).

trim1([], []).
trim1([Char|Chars], Cleaned) :- Char =< " ", !,
	trim2(Chars, Cleaned).
trim1([Char|Chars], [Char|Cleaned]) :-
	trim1(Chars, Cleaned).


trim2([], []).
trim2([Char|Chars], Cleaned) :- Char =< " ", !,
	trim2(Chars, Cleaned).
trim2([Char|Chars], [0' ,Char|Cleaned]) :-
	trim1(Chars, Cleaned).


%   integer_chars(?Integer, ?Chars)
%   is true when Integer is a Prolog-representable integer and Chars is
%   a list of character codes depicting an integer, and the value
%   depicted by Chars is the same as Integer.  If this were NU Prolog,
%   we would describe its intended use thus:
%	?- integer_chars(I, C) when I or ground(C).
%   This code checks for overflow, by watching out for intermediate
%   results with the wrong sign.  To keep the code simple, it just fails
%   when overflow is detected.  Ideally it should signal a representation
%   fail.  To be consistent, other errors also result in quiet failure.
%   The code works with *negative* integers so that the most negative
%   integer can be correctly converted in either direction without overflow.

integer_chars(Integer, Chars) :-
	(   var(Integer) ->
	    'chars to int'(Integer, Chars)
	;   integer(Integer) ->
	    'int to chars'(Integer, Chars)
    %	;   should_be(integer, Integer, 1, integer_chars(Integer,Chars))
	).

'chars to int'(Integer, [0'-|Chars]) :- !,
	Chars = [_|_],
	'chars to neg'(Chars, 0, Integer).
'chars to int'(Integer, Chars) :-
	Chars = [_|_],
	'chars to neg'(Chars, 0, Neg),
	Integer is -Neg,
	Integer >= 0.			% THIS IS AN OVERFLOW CHECK

'chars to neg'([], Neg, Neg).
'chars to neg'([Digit|Digits], Neg0, Neg) :-
	integer(Digit), Digit >= "0", Digit =< "9",
	Neg1 is Neg0*10 + "0" - Digit,
	Neg1 =< 0,			% THIS IS AN OVERFLOW CHECK
	'chars to neg'(Digits, Neg1, Neg).


'int to chars'(Integer, [0'-|Chars]) :-
	Integer < 0,
	!,
	'neg to chars'(Integer, [], Chars).
'int to chars'(Integer, Chars) :-
	Neg is -Integer,
	'neg to chars'(Neg, [], Chars).

'neg to chars'(Neg, Chars0, Chars) :-
	Digit is "0" - Neg mod 10, Neg1 is Neg // 10,
	(   Neg1 =:= 0 -> Chars = [Digit|Chars0]
	;   'neg to chars'(Neg1, [Digit|Chars0], Chars)
	).


end_of_file.

test :-
	write('|: ATOM..INT.S'), nl,
	load('/dev/tty', p(X,Y,Z), [
	    field(4, atom, X),
	    skip(2),
	    field(3, integer, Y),
	    skip(1),
	    field(1, code(["1"=male,"2"=female]), Z),
	    nl
	]),
	listing(p/3).





