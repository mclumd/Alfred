%   Package: true
%   Author : Richard A. O'Keefe
%   Updated: 02 Nov 1988
%   Purpose: Define true/N, fail/N, false/N for several N.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(true, [
	true/1,		fail/1,		false/1,
	true/2,		fail/2,		false/2,
	true/3,		fail/3,		false/3,
	true/4,		fail/4,		false/4,
	true/5,		fail/5,		false/5,
	true/6,		fail/6,		false/6
   ]).

/*  The purpose of this file is to define some logical constants
    which are useful to pass as dummy values to meta-predicates.
    Some day [true,fail,false]/N might be built in for all N.
    In this release, the range of N was copied from library(call):
	call(true)			-> true
	call(true, X)			-> true(X)
	call(true, X, Y)		-> true(X, Y)
	call(true, X, Y, Z)		-> true(X, Y, Z)
	call(true, X, Y, Z, U)		-> true(X, Y, Z, U)
	call(true, X, Y, Z, U, V)	-> true(X, Y, Z, U, V)
	call(true, X, Y, Z, U, V, W)	-> true(X, Y, Z, U, V, W)
    all succeed.  As an example,
	maplist:maplist(true, X, Y)
    succeeds when
	lists:same_length(X, Y)
    succeeds.

	true/0		fail/0		false/0
    are already built-in.
*/

sccs_id('"@(#)88/11/02 true.pl	27.1"').


true(_).
fail(_) :- fail.
false(_) :- fail.

true(_, _).
fail(_, _) :- fail.
false(_, _) :- fail.

true(_, _, _).
fail(_, _, _) :- fail.
false(_, _, _) :- fail.

true(_, _, _, _).
fail(_, _, _, _) :- fail.
false(_, _, _, _) :- fail.

true(_, _, _, _, _).
fail(_, _, _, _, _) :- fail.
false(_, _, _, _, _) :- fail.

true(_, _, _, _, _, _).
fail(_, _, _, _, _, _) :- fail.
false(_, _, _, _, _, _) :- fail.

