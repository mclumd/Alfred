%   Package: stchk
%   Author : Richard A. O'Keefe
%   Updated: 17 May 1988
%   Purpose: Allow LOCAL style-check modifications in a file.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(stchk, [
	push_style/0,
	set_style/2,
	pop_style/0
   ]).

sccs_id('"@(#)88/05/17 stchk.pl	26.1"').


/*  This module provides an alternative interface to the
    style check flags.  The idea is that a file which uses it
    will look like
	<usual heading>

	:- push_style.
	:- set_style(StyleFlag, Value).
	...

	<clauses>

	:- pop_style.

    Some combination of this with the existing style check
    interface will be safe:  no matter what style check
    changes are made, the original values will be restored.
    However, style check changes made *outside* will
    confuse us:  only the changes we have made will be
    remembered, so :- push_style, pop_style may not be a
    no-op!

    As a hack, because I don't want to have lots of dynamic
    predicates kicking around, I represent the style check
    state by a collection of 3 bits, which is rather naughty

    The initial state (assumed) is that all checks are ON.
*/


:- dynamic
	old_style_check_state/1,
	current_style_check_state/1.


%   There are no clauses for old_style_check_state/1
%   initially.

%   The initial style check state is all flags on.

current_style_check_state(2'111).


%   style_check_bit(Name, BitMask)
%   maps between names and bits.

style_check_bit(single_var,	2'001).
style_check_bit(discontiguous,	2'010).
style_check_bit(multiple,	2'100).

set_style_from_bits(Bits) :-
	set_style_from_bit(single_var,    Bits),
	set_style_from_bit(discontiguous, Bits),
	set_style_from_bit(multiple,      Bits).

set_style_from_bit(Name, Bits) :-
	style_check_bit(Name, BitMask),
	(   Bits /\ BitMask =:= 0 ->
	    no_style_check(Name)
	;   style_check(Name)
	).


%   set_style(StyleName, OnOrOff)
%   sets the given style name to either on or off.
%   Both arguments must be atoms.

set_style(StyleName, OnOrOff) :-
	nonvar(StyleName),
	nonvar(OnOrOff),
	style_check_bit(StyleName, BitMask),
	on_or_off(OnOrOff, BitMask, OrInThis),
	!,
	clause(current_style_check_state(OldBits), true, Ref),
	NewBits is (OldBits /\ \(BitMask)) \/ OrInThis,
	set_style_from_bit(StyleName, NewBits),
	asserta(current_style_check_state(NewBits)),
	erase(Ref).
set_style(StyleName, OnOrOff) :-
	format(user_error,
	    '~N! Invalid arguments to set_style/2~n! Goal: ~q~n',
	    [set_style(StyleName,OnOrOff)]),
	fail.


on_or_off(on,  X, X).
on_or_off(off, _, 0).


%   push_style
%   saves the current style bits on a stack and doesn't change
%   them.  Note that if style_check/2 or no_style_check/2 has
%   been used rather than set_style, the current state may not
%   correspond to what we stack, so just in case, we reset the
%   actual state from the current bits.

push_style :-
	current_style_check_state(Bits),
	asserta(old_style_check_state(Bits)),
	set_style_from_bits(Bits).


%   pop_style
%   restores the current style bits from the stack.
%   If the stack is already empty, it reports an error.

pop_style :-
	clause(old_style_check_state(Bits), true, Ref1),
	clause(current_style_check_state(_), true, Ref2),
	!,
	asserta(current_style_check_state(Bits)),
	erase(Ref2),
	erase(Ref1),
	set_style_from_bits(Bits).
pop_style :-
	format(user_error,
	    '~N! The style stack is already empty~n! Goal: ~q~n',
	    [pop_style]),
	fail.


