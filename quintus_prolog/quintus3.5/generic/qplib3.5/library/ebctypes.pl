%   Package: ctypes
%   Author : Richard A. O'Keefe
%   Updated: 02 Nov 1988
%   Purpose: Character classification

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  The predicates to_lower, to_upper, is_alnum, is_alpha, is_cntrl,
    is_digit, is_graph, is_lower, is_upper, is_print, is_punct, and
    is_space are taken directly from the April 84 draft of the C
    standard.  The remaining ones are of my own invention, but are
    reasonably useful.  If you want to make your programs portable
    between different operating systems, use is_endline and is_endfile
    instead of the literal constants 31 and 26 or 10 and -1.

    This file is the EBCDIC version of library(ctypes).
    The information as to which character corresponds to what number
    was taken from the table in "System/370 Reference Summary, IBM
    Technical Publication GX20-1850-4, Fifth Edition (October 1981);
    specifically on the column labelled "EBCDIC" on pp12-15.  This
    corresponds well to the translation done by the UNIX utility dd(1)
    with the option conv=ibm.
*/
:- module(ctypes, [
	is_alnum/1,
	is_alpha/1,
	is_ascii/1,
	is_char/1,
	is_cntrl/1,
	is_csym/1,
	is_csymf/1,
	is_digit/1,
	is_digit/3,
	is_ebcdic/1,
	is_endfile/1,
	is_endline/1,
	is_graph/1,
	is_lower/1,
	is_newline/1,
	is_newpage/1,
	is_paren/2,
	is_period/1,
	is_print/1,
	is_punct/1,
	is_quote/1,
	is_space/1,
	is_upper/1,
	to_lower/2,
	to_upper/2
   ]).

sccs_id('"@(#)88/11/02 ebctypes.pl	27.1"').


%   'in range'(L, U, X)
%   is a poor man's version of between/3 from library(between),
%   put in here to make this file self-contained.  It omits all the
%   checks that library(between) has, because we know that all calls
%   have integer(L) < integer(U).  It is NOT for general use.

'in range'(L, U, X) :-
	(   integer(X) ->
	    L =< X, X =< U
	;   var(X) ->
	    'in range 1'(L, U, X)
	).

'in range 1'(L, U, X) :-
	(   L =:= U -> X = L
	;   X = L
	;   M is L+1,
	    'in range 1'(M, U, X)
	).



is_ascii(_) :-			% It is not clear what this should
	fail.			% do when the character set is EBCDIC.



is_alnum(C) :-			% Letter or Digit
	'in range'(0'a, 0'9, C),
	'char type'(C, T, _),
	T < 36.



is_alpha(C) :-			% Upper or Lower case letter
	'in range'(0'a, 0'Z, C),
	'char type'(C, T, _),
	T >= 10, T < 36.



is_char(C) :-
	'in range'(0, 255, C).


is_ebcdic(C) :-			% Any EBCDIC character code.
	'char type'(C, _, _).



is_cntrl(C) :-			% EBCDIC control character
	'char type'(C, 39, 0).



is_csym(C) :-			% Letter, Digit, or Underscore
	'in range'(0'_, 0'9, C),
	'char type'(C, T, _),
	T < 37.



is_csymf(C) :-			% Letter or Underscore
	'in range'(0'_, 0'Z, C),
	'char type'(C, T, _),
	T >= 10, T < 37.



is_digit(C) :-			% (plain) Decimal digit
	'in range'(0'0, 0'9, C).



is_digit(C, Base, Weight) :-
	'in range'(2, 36, Base),
	'in range'(0'a, 0'9, C),
	'char type'(C, Weight, _),
	Weight < Base.



is_endfile(-1).			% was 26 in Dec-10 and C Prolog



is_endline(C) :-		% line terminator, NOT just newline
	is_cntrl(C),		% covers EOF, BEL, LF, VT, FF, CR, ESC, EOT
	C =\= 5.		% not TAB though.


is_graph(C) :-			% makes a mark when you print it
	'in range'(16'4a, 0'9, C),
	'char type'(C, T, _),
	T < 38.


is_lower(C) :-			% Lower case letter
	'in range'(0'a, 0'z, C),
	'char type'(C, _, 1).


is_newline(16'15).		% is "NL", not "LF".



is_newpage(_) :- fail.		% no character has this effect in CMS or MVS



is_paren(0'(, 0')).
is_paren(0'[, 0']).
is_paren(0'{, 0'}).



is_period(0'.).			% a period is anything that ends a sentence
is_period(0'?).			% (also known as a period).  . is a full stop.
is_period(0'!).			% "stop" another word for "punctuation mark".



is_print(C) :-			% ` ` or is_graph
	'in range'(16'40, 0'9, C),
	'char type'(C, T, _),
	T < 39.



is_punct(C) :-			% is_graph(C), \+ is_alnum(C).
	'in range'(16'4a, 16'e0, C),
	'char type'(C, 37, 0).



is_quote(0'').
is_quote(0'").
is_quote(0'`).



is_space(16'40).		% ` `
is_space(16'15).		% `\n` (new-line)
is_space(16'05).		% `\t`
is_space(16'25).		% line-feed (not identical to \n in EBCDIC)
is_space(16'0b).		% `\v`
is_space(16'0c).		% `\f`
is_space(16'0d).		% `\r`



is_upper(C) :-
	'in range'(0'A, 0'Z, C),
	'char type'(C, T, 0),
	T >= 10, T < 36.



is_white(16'40).		% space
is_white(16'05).		% tab



%   to_lower(UpperCase, LowerCase) and
%   to_upper(LowerCase, UpperCase)
%   convert letters from one case to another.  Other characters
%   they are supposed to leave alone.

to_lower(U, L) :-
	'char type'(U, T, X),
	(   X =:= 0, T < 36, T >= 10 -> L is U-64 ; L is U   ).


to_upper(L, U) :-
	'char type'(L, _, X),
	(   X =:= 1 -> U is L+64 ; U is L   ).




'char type'(  0, 39, 0).
'char type'(  1, 39, 0).
'char type'(  2, 39, 0).
'char type'(  3, 39, 0).
'char type'(  4, 39, 0).
'char type'(  5, 39, 0).
'char type'(  6, 39, 0).
'char type'(  7, 39, 0).
'char type'(  8, 39, 0).
'char type'(  9, 39, 0).
'char type'( 10, 39, 0).
'char type'( 11, 39, 0).
'char type'( 12, 39, 0).
'char type'( 13, 39, 0).
'char type'( 14, 39, 0).
'char type'( 15, 39, 0).
'char type'( 16, 39, 0).
'char type'( 17, 39, 0).
'char type'( 18, 39, 0).
'char type'( 19, 39, 0).
'char type'( 20, 39, 0).
'char type'( 21, 39, 0).
'char type'( 22, 39, 0).
'char type'( 23, 39, 0).
'char type'( 24, 39, 0).
'char type'( 25, 39, 0).
'char type'( 26, 39, 0).
'char type'( 27, 39, 0).
'char type'( 28, 39, 0).
'char type'( 29, 39, 0).
'char type'( 30, 39, 0).
'char type'( 31, 39, 0).
'char type'( 32, 39, 0).
'char type'( 33, 39, 0).
'char type'( 34, 39, 0).
'char type'( 35, 39, 0).
'char type'( 36, 39, 0).
'char type'( 37, 39, 0).
'char type'( 38, 39, 0).
'char type'( 39, 39, 0).
'char type'( 40, 39, 0).
'char type'( 41, 39, 0).
'char type'( 42, 39, 0).
'char type'( 43, 39, 0).
'char type'( 44, 39, 0).
'char type'( 45, 39, 0).
'char type'( 46, 39, 0).
'char type'( 47, 39, 0).
'char type'( 48, 39, 0).
'char type'( 49, 39, 0).
'char type'( 50, 39, 0).
'char type'( 51, 39, 0).
'char type'( 52, 39, 0).
'char type'( 53, 39, 0).
'char type'( 54, 39, 0).
'char type'( 55, 39, 0).
'char type'( 56, 39, 0).
'char type'( 57, 39, 0).
'char type'( 58, 39, 0).
'char type'( 59, 39, 0).
'char type'( 60, 39, 0).
'char type'( 61, 39, 0).
'char type'( 62, 39, 0).
'char type'( 63, 39, 0).
'char type'( 64, 38, 0).
'char type'( 65, 40, 0).
'char type'( 66, 40, 0).
'char type'( 67, 40, 0).
'char type'( 68, 40, 0).
'char type'( 69, 40, 0).
'char type'( 70, 40, 0).
'char type'( 71, 40, 0).
'char type'( 72, 40, 0).
'char type'( 73, 40, 0).
'char type'( 74, 37, 0).
'char type'( 75, 37, 0).
'char type'( 76, 37, 0).
'char type'( 77, 37, 0).
'char type'( 78, 37, 0).
'char type'( 79, 37, 0).
'char type'( 80, 37, 0).
'char type'( 81, 40, 0).
'char type'( 82, 40, 0).
'char type'( 83, 40, 0).
'char type'( 84, 40, 0).
'char type'( 85, 40, 0).
'char type'( 86, 40, 0).
'char type'( 87, 40, 0).
'char type'( 88, 40, 0).
'char type'( 89, 40, 0).
'char type'( 90, 37, 0).
'char type'( 91, 37, 0).
'char type'( 92, 37, 0).
'char type'( 93, 37, 0).
'char type'( 94, 37, 0).
'char type'( 95, 37, 0).
'char type'( 96, 37, 0).
'char type'( 97, 37, 0).
'char type'( 98, 40, 0).
'char type'( 99, 40, 0).
'char type'(100, 40, 0).
'char type'(101, 40, 0).
'char type'(102, 40, 0).
'char type'(103, 40, 0).
'char type'(104, 40, 0).
'char type'(105, 40, 0).
'char type'(106, 37, 0).
'char type'(107, 37, 0).
'char type'(108, 37, 0).
'char type'(109, 36, 0).
'char type'(110, 37, 0).
'char type'(111, 37, 0).
'char type'(112, 40, 0).
'char type'(113, 40, 0).
'char type'(114, 40, 0).
'char type'(115, 40, 0).
'char type'(116, 40, 0).
'char type'(117, 40, 0).
'char type'(118, 40, 0).
'char type'(119, 40, 0).
'char type'(120, 40, 0).
'char type'(121, 37, 0).
'char type'(122, 37, 0).
'char type'(123, 37, 0).
'char type'(124, 37, 0).
'char type'(125, 37, 0).
'char type'(126, 37, 0).
'char type'(127, 37, 0).
'char type'(128, 40, 0).
'char type'(129, 10, 1).
'char type'(130, 11, 1).
'char type'(131, 12, 1).
'char type'(132, 13, 1).
'char type'(133, 14, 1).
'char type'(134, 15, 1).
'char type'(135, 16, 1).
'char type'(136, 17, 1).
'char type'(137, 18, 1).
'char type'(138, 40, 0).
'char type'(139, 37, 0).
'char type'(140, 40, 0).
'char type'(141, 40, 0).
'char type'(142, 40, 0).
'char type'(143, 40, 0).
'char type'(144, 40, 0).
'char type'(145, 19, 1).
'char type'(146, 20, 1).
'char type'(147, 21, 1).
'char type'(148, 22, 1).
'char type'(149, 23, 1).
'char type'(150, 24, 1).
'char type'(151, 25, 1).
'char type'(152, 26, 1).
'char type'(153, 27, 1).
'char type'(154, 40, 0).
'char type'(155, 37, 0).
'char type'(156, 40, 0).
'char type'(157, 40, 0).
'char type'(158, 40, 0).
'char type'(159, 40, 0).
'char type'(160, 40, 0).
'char type'(161, 37, 0).
'char type'(162, 28, 1).
'char type'(163, 28, 1).
'char type'(164, 30, 1).
'char type'(165, 31, 1).
'char type'(166, 32, 1).
'char type'(167, 33, 1).
'char type'(168, 34, 1).
'char type'(169, 35, 1).
'char type'(170, 40, 0).
'char type'(171, 40, 0).
'char type'(172, 40, 0).
'char type'(173, 37, 0).
'char type'(174, 40, 0).
'char type'(175, 40, 0).
'char type'(176,  0, 0).
'char type'(177,  1, 0).
'char type'(178,  2, 0).
'char type'(179,  3, 0).
'char type'(180,  4, 0).
'char type'(181,  5, 0).
'char type'(182,  6, 0).
'char type'(183,  7, 0).
'char type'(184,  8, 0).
'char type'(185,  9, 0).
'char type'(186, 40, 0).
'char type'(187, 40, 0).
'char type'(188, 40, 0).
'char type'(189, 37, 0).
'char type'(190, 40, 0).
'char type'(191, 40, 0).
'char type'(192, 37, 0).
'char type'(193, 10, 0).
'char type'(194, 11, 0).
'char type'(195, 12, 0).
'char type'(196, 13, 0).
'char type'(197, 14, 0).
'char type'(198, 15, 0).
'char type'(199, 16, 0).
'char type'(200, 17, 0).
'char type'(201, 18, 0).
'char type'(202, 40, 0).
'char type'(203, 40, 0).
'char type'(204, 40, 0).
'char type'(205, 40, 0).
'char type'(206, 40, 0).
'char type'(207, 40, 0).
'char type'(208, 37, 0).
'char type'(209, 19, 0).
'char type'(210, 20, 0).
'char type'(211, 21, 0).
'char type'(212, 22, 0).
'char type'(213, 23, 0).
'char type'(214, 24, 0).
'char type'(215, 25, 0).
'char type'(216, 26, 0).
'char type'(217, 27, 0).
'char type'(218, 40, 0).
'char type'(219, 40, 0).
'char type'(220, 40, 0).
'char type'(221, 40, 0).
'char type'(222, 40, 0).
'char type'(223, 40, 0).
'char type'(224, 37, 0).
'char type'(225, 40, 0).
'char type'(226, 28, 0).
'char type'(227, 29, 0).
'char type'(228, 30, 0).
'char type'(229, 31, 0).
'char type'(230, 32, 0).
'char type'(231, 33, 0).
'char type'(232, 34, 0).
'char type'(233, 35, 0).
'char type'(234, 40, 0).
'char type'(235, 40, 0).
'char type'(236, 40, 0).
'char type'(237, 40, 0).
'char type'(238, 40, 0).
'char type'(239, 40, 0).
'char type'(240,  0, 0).
'char type'(241,  1, 0).
'char type'(242,  2, 0).
'char type'(243,  3, 0).
'char type'(244,  4, 0).
'char type'(245,  5, 0).
'char type'(246,  6, 0).
'char type'(247,  7, 0).
'char type'(248,  8, 0).
'char type'(249,  9, 0).
'char type'(250, 40, 0).
'char type'(251, 40, 0).
'char type'(252, 40, 0).
'char type'(253, 40, 0).
'char type'(254, 40, 0).
'char type'(255, 40, 0).

