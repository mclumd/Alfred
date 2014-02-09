%   Module : print_chars
%   Author : Richard A. O'Keefe
%   Updated: 10 Sep 1991
%   Purpose: Portray lists of characters as strings.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(print_chars, [
	plausible_chars/1,
	portray_chars/1
   ]).

:- use_module(library(addportray), [
	add_portray/1
   ]),
   use_module(library(ctypes), [ctypes_bits/2]).

sccs_id('"@(#)91/09/10 printchars.pl	65.1"').


%   plausible_chars(Chars)
%   is true when Chars is a list of "plausible" characters, possibly
%   ending with a variable.  To be plausible, either is_graph(Char) or
%   is_space(Char) must be true for each element Char of Chars.  As
%   well as allowing Chars to end with a variable, it may end with
%   a $VAR(_) term bound by numbervars/3.

plausible_chars(Var) :-
	var(Var), !.
plausible_chars('$VAR'(_)).
plausible_chars([]).
plausible_chars([Char|Chars]) :-
	integer(Char),
	ctypes_bits(Char, Mask),
	Mask /\ 8'0300 =\= 8'0100,	% is_graph or is_space
	plausible_chars(Chars).


%   portray_chars(Chars)
%   checks whether Chars is a non-empty plausible list of character codes.
%   If it is, it prints the characters out between double quotes.
%   THIS IS A DEBUGGING AID.  Control characters are written out in ^X
%   form, rather than using \x.  If the list ends with a variable or
%   $VAR(_), that is written out as |_X, which will not, of course, be
%   read back.  That's ok, it's just for looking at.

portray_chars(Chars) :-
	Chars = [_|_],			% a non-empty list
	plausible_chars(Chars),		% of plausible characters
	put(0'"), 'portray chars'(Chars), put(0'").


'portray chars'(Var) :-
	var(Var),
	!,
	put(0'|), write(Var).
'portray chars'([]).
'portray chars'('$VAR'(N)) :-
	put(0'|), write('$VAR'(N)).
'portray chars'([Char|Chars]) :-
	(   Char < " " ->		% we should have to_cntrl/2
	    Caps is Char+64,		% in library(ctypes); as yet
	    put(0'^), put(Caps)		% we don't, so not EBCDICy.
	;   Char =:= 0'" ->		% " is written doubled
	    put(0'"), put(0'")
	;   put(Char)
	),
	'portray chars'(Chars).

/*  When you ensure_loaded(library(print_chars)), portray_chars/1
    is automagically hooked into portray/1.  If you don't want that,
    do del_portray(print_chars:portray_chars).
*/
:- initialization add_portray(portray_chars).


