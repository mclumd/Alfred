%   Module : ctypes
%   Author : Richard A. O'Keefe
%   Updated: 27 Feb 1992
%   Purpose: Character classification

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

/*  The predicates to_lower, to_upper, is_alnum, is_alpha, is_cntrl,
    is_digit, is_graph, is_lower, is_upper, is_print, is_punct, and
    is_space are taken directly from the April 84 draft of the C
    standard.  The remaining ones are of my own invention, but are
    reasonably useful.  If you want to make your programs portable
    between different operating systems, use is_endline and is_endfile
    instead of the literal constants 31 and 26 or 10 and -1.

    Release 2.0 of Quintus Prolog handles 8-bit characters in the
    base system, classifying them according to the new international
    standard ISO 8859/1.  (VAX/VMS users note: the main difference
    between this and DEC's Multinational Character Set is that the
    latter has OE and oe ligatures, which ISO 8859/1 uses for a
    multiplication and division sign.  The VMS version of Quintus
    Prolog uses the VMS interpretation of those codes.)  In July 88
    library(ctypes) was upgraded to ISO 8859/1 as well.  As part of
    this, the is_ascii(C) predicate has been retained with the
    meaning "C is an ASCII character"; it is false of the others.
    A new is_char(C) predicate has been introduced, meaning "C is the
    code of a character in the supported character set".

    There is a problem:  in the ASCII character set, every letter is
    either an upper case letter having a unique corresponding lower
    case letter, or a lower case letter having a unique corresponding
    upper case letter.  This is not true in ISO 8859/1.  There is a
    lower case y with an umlaut, but no upper case Y with an umlaut.
    The German "sz" ligature has SS as its upper case equivalent, but
    that's two characters.  To cope with this problem, I have chosen
    to classify these characters as Extra letters, neither Lower nor
    Upper.  The predicate is_alpha/1 recognises them.

    Another question concerns the non-breaking space (code 160).
    Currently, is_cntrl(160), is_space(160), but \+ is_white(160).
    That may not be exactly right.  Suggestions?
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
	is_digit/2,
	is_digit/3,
	is_endfile/1,
	is_endline/1,
	is_graph/1,
	is_layout/1,
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
	is_white/1,
	to_lower/2,
	to_upper/2,
	ctypes_bits/2
   ]).

sccs_id('"@(#)92/02/27 ctypes.pl	66.1"').


/*  Character classification is now done with the aid of a table.
    Each entry in this table has the form
	bits(Ch, 2'ELUDSCVVVVVV)
    where
	Extra (8'4000) is on if Ch is a letter, but not upper or lower case.
	Lower (8'2000) is on if Ch is a lower case letter
	Upper (8'1000) is on if Ch is an upper case letter
	Digit (8'0400) is on if Ch is a decimal digit
	Space (8'0200) is on if is_space(Ch)
	Cntrl (8'0100) is on if is_cntrl(Ch)
	Value (8'0077) is the value of Ch as a digit, 63 for non-digits.
*/

%   is_alnum(?Char)
%   is true when Char is the character code of a letter or digit.

is_alnum(C) :-
	bits(C, M), M /\ 8'7400 =\= 0.


%   is_alpha(?Char)
%   is true when Char is the character code of a letter, in either
%   case or none.  (It is NOT the union of is_lower/1 and is_upper/1.)

is_alpha(C) :-
	bits(C, M), M /\ 8'7000 =\= 0.


%   is_ascii(?Char)
%   is true when Char is a character code in the ASCII range.

is_ascii(C) :-
	range(C, 0, 127).


%   is_char(?Char)
%   is true when Char is a character code in whatever the supported
%   range happens to be.  (In this version:  ISO 8859/1.)

is_char(C) :-
	range(C, 0, 255).


%   is_cntrl(?Char)
%   is true when Char is the character code of a control character.
%   The ASCII control characters are 0..31; ISO 8859/1 adds 128..160.

is_cntrl(C) :-
	bits(C, M), M /\ 8'0100 =\= 0.


%   is_csym(?Char)
%   is true when Char is the code of a character which could occur in
%   the body of an identifier (it is a letter, digit, or underscore).

is_csym(C) :-
	bits(C, M), M /\ 8'17400 =\= 0.


%   is_csymf(?Char)
%   is true when Char is the code of a character which could occur as
%   the first character of an identfier (it is a letter or underscore).

is_csymf(C) :-
	bits(C, M), M /\ 8'17000 =\= 0.


%   is_digit(?Char)
%   is true when Char is the character code of a decimal digit.

is_digit(C) :-
	bits(C, M), M /\ 8'0400 =\= 0.


%   is_digit(?Char, ?Weight)
%   is true when Char is the character code of a decimal digit,
%   and Weight is its decimal value.

is_digit(Char, Weight) :-
	(   integer(Char)   -> Char >= "0", Char =< "9", Weight is Char-"0"
	;   integer(Weight) -> Weight >= 0, Weight =< 9, Char is Weight+"0"
	;   var(Char), var(Weight) ->
	    range(Weight, 0, 9), Char is Weight+"0"
	).



%   is_digit(?Char, ?Base, ?Weight)
%   is true when Base is an integer between 2 and 36,
%   Weight is an non-negative integer less than Base,
%   and Char is the character code of a digit in that base
%   whose numerical value is Weight.  "Digits" greater than
%   9 may be in either case.

is_digit(Char, Base, Weight) :-
	range(Base, 2, 36),
	bits(Char, Mask),
	Weight is Mask /\ 8'77,
	Weight < Base.


%   is_endfile(?Char)
%   is true when Char is the end of file code (note that this may
%   or may not be the code of some character; it isn't in Quintus
%   Prolog, but it was the code of ^Z in DEC-10 Prolog and two others).

is_endfile(-1).			% was 26 in Dec-10 and C Prolog


%   is_endline(+Char)
%   succeeds when Char is the code of some character which terminates
%   a line.  Char must already be instantiated.

is_endline(C) :-		% line terminator, NOT just newline
	C < 32,			% covers EOF, ^G, ^J, ^K, ^L, ^M, ^Z, ESC, ^_
	C =\= 9 /* ^I */.	% not ^I (TAB) though.


%   is_graph(?Char)
%   is true if Char is the character code of some character which
%   should make a visible mark when printed.

is_graph(C) :-
	bits(C, M), M /\ 8'0300 =:= 0.


%   is_layout(?Char)
%   is true when Char is a character code which does NOT correspond to
%   a visible mark; it is the opposite of is_graph/1.

is_layout(C) :-
	bits(C, M), M /\ 8'0300 =\= 0.


%   is_lower(?Char)
%   is true when Char is the character code of a lower case letter.

is_lower(C) :-
	bits(C, M), M /\ 8'2000 =\= 0.


%   is_newline(?Char)
%   is true when Char is the character code of the normal new-line
%   character.  This is 10 on UNIX, 13 in systems where CR is the
%   line terminator, and is 31 in systems where CR+LF is the terminator.

is_newline(10 /* ^J */).


%   is_newpage(?Char)
%   is true when Char is the character code of the control character
%   which starts a new page.  There need not be any such character.

is_newpage(12 /* ^L */).	% may fail (O/S-dependent)


%   is_paren(?Left, ?Right)
%   is true when Left and Right are character codes corresponding to
%   "()", "[]", "{}", or "<< >>".

is_paren(0'(, 0')).
is_paren(0'[, 0']).
is_paren(0'{, 0'}).
is_paren(171, 187).	% Left << and Right >> quote characters.


%   is_period(?Char)
%   is true when Char is the character code of any of the three stops
%   which may terminate a period (also known as a sentence):  the full
%   stop, the question mark, or the exclamation mark.

is_period(0'.).		% Full stop
is_period(0'?).		% Question mark
is_period(0'!).		% Exclamation mark


%   is_print(?Char)
%   is true when Char is a character code other than the code of a
%   control character.  That is, a graphic character, or a blank.

is_print(C) :-
	bits(C, M), M /\ 8'0100 =:= 0.


%   is_punct(?Char)
%   is true when Char is the character code of some graphic character
%   other than a letter or digit.

is_punct(C) :-
	bits(C, M), M /\ 8'3700 =:= 0.


%   is_quote(?Char)
%   is true when Char is the character code of a quotation mark.
%   ', ", and ` are accepted as quotation marks.  This doesn't handle
%   << and >> because it fails to draw the left/right distinction.
%   (Instead of squandering code space on trash like 1/4,1/2,3/4 and
%   so on, why didn't ISO give us ENGLISH 6--9 66--99 quotation marks?)

is_quote(0'').
is_quote(0'").
is_quote(0'`).


%   is_space(?Char)
%   is true when Char is the character code of a "format effector",
%   space, tab, line-feed, carriage return, form feed, vertical tab.
%   For reasons of backwards compatibility this includes DEC-10 Prolog's
%   line terminator (31).

is_space(C) :-
	bits(C, M), M /\ 8'0200 =\= 0.


%   is_upper(?Char)
%   is true when Char is the character code of an upper case letter.

is_upper(C) :-
	bits(C, M), M /\ 8'1000 =\= 0.


%   is_white(?Char)
%   is true when Char is the character code of a space or tab.
%   The ISO 8859/1 non-breaking space (160) is _not_ currently
%   accepted, but that may change.

is_white(32).			% space
is_white( 9).			% tab


%   to_lower(?UpperCase, ?LowerCase)
%   converts upper case letters to lower case, and leaves other
%   characters alone.

to_lower(U, L) :-
	bits(U, M),
	L is U + (M /\ 8'1000) >> 4.


%   to_upper(?LowerCase, ?UpperCase)
%   converts lower case letters to upper case, and leaves other
%   characters (including "sz" and y-umlaut) alone.

to_upper(L, U) :-
	bits(L, M),
	U is L - (M /\ 8'2000) >> 5.


%.  range(?X, +L, +U)
%   is a specialised version of between(L, U, X) where it is known that
%   L and U are integers with L < U, and we don't want an error message
%   if X is neither a variable nor an integer.  In fact L, U, and X are
%   all supposed to be character codes.

range(X, L, U) :-
	(   integer(X) -> L =< X, X =< U
	;   var(X) ->     range1(L, U, X)
	).

range1(X, _, X).
range1(L, U, X) :-
	M is L+1,
	M =< U,
	range1(M, U, X).


/*  The ASCII part of the table below was bootstrapped from an earlier
    version of library(ctypes) using the following code:

	tell(bits),
	is_ascii(C),
	(   is_digit(C) -> M is C - 0'0 +      8'0400
	;   is_upper(C) -> M is C - 0'A + 10 + 8'1000
	;   is_lower(C) -> M is C - 0'a + 10 + 8'2000
	;   is_csymf(C) -> M is 8'4077
	;   C =:= " "   -> M is 8'0277
	;   is_space(C) -> M is 8'0377
	;   is_cntrl(C) -> M is 8'0177
	;		   M is 8'0077
	),
	format('bits(~|~t~d~3+, 2''~|~`0t~2r~12+).~n', [C,M]),
	fail
    ;	told.
*/

bits(  0, 2'000001111111).
bits(  1, 2'000001111111).
bits(  2, 2'000001111111).
bits(  3, 2'000001111111).
bits(  4, 2'000001111111).
bits(  5, 2'000001111111).
bits(  6, 2'000001111111).
bits(  7, 2'000001111111).
bits(  8, 2'000001111111).
bits(  9, 2'000011111111).
bits( 10, 2'000011111111).
bits( 11, 2'000011111111).
bits( 12, 2'000011111111).
bits( 13, 2'000011111111).
bits( 14, 2'000001111111).
bits( 15, 2'000001111111).
bits( 16, 2'000001111111).
bits( 17, 2'000001111111).
bits( 18, 2'000001111111).
bits( 19, 2'000001111111).
bits( 20, 2'000001111111).
bits( 21, 2'000001111111).
bits( 22, 2'000001111111).
bits( 23, 2'000001111111).
bits( 24, 2'000001111111).
bits( 25, 2'000001111111).
bits( 26, 2'000001111111).
bits( 27, 2'000001111111).
bits( 28, 2'000001111111).
bits( 29, 2'000001111111).
bits( 30, 2'000001111111).
bits( 31, 2'000011111111).
bits( 32, 2'000010111111).
bits( 33, 2'000000111111).
bits( 34, 2'000000111111).
bits( 35, 2'000000111111).
bits( 36, 2'000000111111).
bits( 37, 2'000000111111).
bits( 38, 2'000000111111).
bits( 39, 2'000000111111).
bits( 40, 2'000000111111).
bits( 41, 2'000000111111).
bits( 42, 2'000000111111).
bits( 43, 2'000000111111).
bits( 44, 2'000000111111).
bits( 45, 2'000000111111).
bits( 46, 2'000000111111).
bits( 47, 2'000000111111).
bits( 48, 2'000100000000).
bits( 49, 2'000100000001).
bits( 50, 2'000100000010).
bits( 51, 2'000100000011).
bits( 52, 2'000100000100).
bits( 53, 2'000100000101).
bits( 54, 2'000100000110).
bits( 55, 2'000100000111).
bits( 56, 2'000100001000).
bits( 57, 2'000100001001).
bits( 58, 2'000000111111).
bits( 59, 2'000000111111).
bits( 60, 2'000000111111).
bits( 61, 2'000000111111).
bits( 62, 2'000000111111).
bits( 63, 2'000000111111).
bits( 64, 2'000000111111).
bits( 65, 2'001000001010).
bits( 66, 2'001000001011).
bits( 67, 2'001000001100).
bits( 68, 2'001000001101).
bits( 69, 2'001000001110).
bits( 70, 2'001000001111).
bits( 71, 2'001000010000).
bits( 72, 2'001000010001).
bits( 73, 2'001000010010).
bits( 74, 2'001000010011).
bits( 75, 2'001000010100).
bits( 76, 2'001000010101).
bits( 77, 2'001000010110).
bits( 78, 2'001000010111).
bits( 79, 2'001000011000).
bits( 80, 2'001000011001).
bits( 81, 2'001000011010).
bits( 82, 2'001000011011).
bits( 83, 2'001000011100).
bits( 84, 2'001000011101).
bits( 85, 2'001000011110).
bits( 86, 2'001000011111).
bits( 87, 2'001000100000).
bits( 88, 2'001000100001).
bits( 89, 2'001000100010).
bits( 90, 2'001000100011).
bits( 91, 2'000000111111).
bits( 92, 2'000000111111).
bits( 93, 2'000000111111).
bits( 94, 2'000000111111).
bits( 95,2'1000000111111).
bits( 96, 2'000000111111).
bits( 97, 2'010000001010).
bits( 98, 2'010000001011).
bits( 99, 2'010000001100).
bits(100, 2'010000001101).
bits(101, 2'010000001110).
bits(102, 2'010000001111).
bits(103, 2'010000010000).
bits(104, 2'010000010001).
bits(105, 2'010000010010).
bits(106, 2'010000010011).
bits(107, 2'010000010100).
bits(108, 2'010000010101).
bits(109, 2'010000010110).
bits(110, 2'010000010111).
bits(111, 2'010000011000).
bits(112, 2'010000011001).
bits(113, 2'010000011010).
bits(114, 2'010000011011).
bits(115, 2'010000011100).
bits(116, 2'010000011101).
bits(117, 2'010000011110).
bits(118, 2'010000011111).
bits(119, 2'010000100000).
bits(120, 2'010000100001).
bits(121, 2'010000100010).
bits(122, 2'010000100011).
bits(123, 2'000000111111).
bits(124, 2'000000111111).
bits(125, 2'000000111111).
bits(126, 2'000000111111).
bits(127, 2'000001111111).
bits(128, 2'000001111111).
bits(129, 2'000001111111).
bits(130, 2'000001111111).
bits(131, 2'000001111111).
bits(132, 2'000001111111).
bits(133, 2'000001111111).
bits(134, 2'000001111111).
bits(135, 2'000001111111).
bits(136, 2'000001111111).
bits(137, 2'000001111111).
bits(138, 2'000001111111).
bits(139, 2'000001111111).
bits(140, 2'000001111111).
bits(141, 2'000001111111).
bits(142, 2'000001111111).
bits(143, 2'000001111111).
bits(144, 2'000001111111).
bits(145, 2'000001111111).
bits(146, 2'000001111111).
bits(147, 2'000001111111).
bits(148, 2'000001111111).
bits(149, 2'000001111111).
bits(150, 2'000001111111).
bits(151, 2'000001111111).
bits(152, 2'000001111111).
bits(153, 2'000001111111).
bits(154, 2'000001111111).
bits(155, 2'000001111111).
bits(156, 2'000001111111).
bits(157, 2'000001111111).
bits(158, 2'000001111111).
bits(159, 2'000001111111).
bits(160, 2'000001111111).
bits(161, 2'000000111111).
bits(162, 2'000000111111).
bits(163, 2'000000111111).
bits(164, 2'000000111111).
bits(165, 2'000000111111).
bits(166, 2'000000111111).
bits(167, 2'000000111111).
bits(168, 2'000000111111).
bits(169, 2'000000111111).
bits(170, 2'000000111111).
bits(171, 2'000000111111).
bits(172, 2'000000111111).
bits(173, 2'000000111111).
bits(174, 2'000000111111).
bits(175, 2'000000111111).
bits(176, 2'000000111111).
bits(177, 2'000000111111).
bits(178, 2'000000111111).
bits(179, 2'000000111111).
bits(180, 2'000000111111).
bits(181, 2'000000111111).
bits(182, 2'000000111111).
bits(183, 2'000000111111).
bits(184, 2'000000111111).
bits(185, 2'000000111111).
bits(186, 2'000000111111).
bits(187, 2'000000111111).
bits(188, 2'000000111111).
bits(189, 2'000000111111).
bits(190, 2'000000111111).
bits(191, 2'000000111111).
bits(192, 2'001000111111).
bits(193, 2'001000111111).
bits(194, 2'001000111111).
bits(195, 2'001000111111).
bits(196, 2'001000111111).
bits(197, 2'001000111111).
bits(198, 2'001000111111).
bits(199, 2'001000111111).
bits(200, 2'001000111111).
bits(201, 2'001000111111).
bits(202, 2'001000111111).
bits(203, 2'001000111111).
bits(204, 2'001000111111).
bits(205, 2'001000111111).
bits(206, 2'001000111111).
bits(207, 2'001000111111).
bits(208, 2'001000111111).
bits(209, 2'001000111111).
bits(210, 2'001000111111).
bits(211, 2'001000111111).
bits(212, 2'001000111111).
bits(213, 2'001000111111).
bits(214, 2'001000111111).
bits(215, 2'001000111111).
bits(216, 2'001000111111).
bits(217, 2'001000111111).
bits(218, 2'001000111111).
bits(219, 2'001000111111).
bits(220, 2'001000111111).
bits(221, 2'001000111111).
bits(222, 2'001000111111).
bits(223, 2'100000111111).
bits(224, 2'010000111111).
bits(225, 2'010000111111).
bits(226, 2'010000111111).
bits(227, 2'010000111111).
bits(228, 2'010000111111).
bits(229, 2'010000111111).
bits(230, 2'010000111111).
bits(231, 2'010000111111).
bits(232, 2'010000111111).
bits(233, 2'010000111111).
bits(234, 2'010000111111).
bits(235, 2'010000111111).
bits(236, 2'010000111111).
bits(237, 2'010000111111).
bits(238, 2'010000111111).
bits(239, 2'010000111111).
bits(240, 2'010000111111).
bits(241, 2'010000111111).
bits(242, 2'010000111111).
bits(243, 2'010000111111).
bits(244, 2'010000111111).
bits(245, 2'010000111111).
bits(246, 2'010000111111).
bits(247, 2'010000111111).
bits(248, 2'010000111111).
bits(249, 2'010000111111).
bits(250, 2'010000111111).
bits(251, 2'010000111111).
bits(252, 2'010000111111).
bits(253, 2'010000111111).
bits(254, 2'010000111111).
bits(255, 2'100000111111).

ctypes_bits(C, B) :- bits(C, B).
