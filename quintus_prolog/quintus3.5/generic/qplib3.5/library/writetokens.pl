%   Package: writetokens.pl
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Purpose: Convert a term to a list of tokens.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(write_tokens, [
	term_to_tokens/2,
	term_to_tokens/4
   ]).

sccs_id('"@(#)89/08/29 writetokens.pl	33.1"').

/*  This is essentially the same as the public-domain write.pl, except
    the instead of writing characters to the current ouput stream, it
    returns a list of tokens.  There are three kinds of tokens:
    (1) punctuation marks, which are represented by atoms.
	'('	','	')'
	'['	'|'	']'
	'{'		'}'
    (2) constants, wrapped around to say what they are
	atom(Atom)
	integer(Integer)
	float(Float)
	var(Var)
    (3) atoms used other ways have other wrappers
	functor(Functor)	% THE ( IS IMPLICIT IN THIS TOKEN!!!
	prefix(Operator)
	infix(Operator)
	postfix(Operator)
    Note that ',' and ';', when used as operators, will be reported
    as infix(_) tokens.

    There is nothing to indicate spacing; the point of this package is
    to let the caller do such formatting.
*/

%   term_to_tokens(+Term, ?Tokens)
%   unifies Tokens with a list of tokens which represent the Term.
%   Extra parentheses are added just as write/1 would add them.
%   This predicate is steadfast in Tokens.

term_to_tokens(Term, Tokens) :-
	term_to_tokens(Term, 1200, Tokens, []).

term_to_tokens(Term, Priority) --> 
	(   {var(Term)} ->	[var(Term)]
	;   {integer(Term)} ->	[integer(Term)]
	;   {float(Term)} ->	[float(Term)]
	;   {atom(Term)} ->
	    (	{prefix(Term, P, _), P > Priority} ->
		['(',atom(Term),')']
	    ;	/* not prefix operator, or in priority range */
		[atom(Term)]
	    )
	;   {functor(Term, F, N)},
	    (	{N =:= 1} ->
	        unary_to_tokens(F, Term, Priority)
	    ;	{N =:= 2} ->
		binary_to_tokens(F, Term, Priority)
	    ;   /* there is no special syntax for terms with >2 arguments */
		[functor(F)],	% THE ( IS IMPLICIT IN THIS TOKEN!!!
		arguments_to_tokens(1, N, Term)
	    )
	).


%.  arguments_to_tokens(+I, +N, +Term)(S0,S)
%   converts the Ith to Nth arguments of Term to tokens, adding
%   appropriate punctuation.

arguments_to_tokens(I, N, Term) --> !,
	{arg(I, Term, Arg)},
	term_to_tokens(Arg, 999), 
	(   {I < N} ->	[','],
	    {J is I+1},
	    arguments_to_tokens(J, N, Term)
	;   /* finished */ [')']
	).


%.  unary_to_tokens(+Functor, +Term, +Priority)(S0,S)
%   converts a unary term to a sequence of tokens.  In addition to
%   handling user-defined operators and the {_} form, it watches out
%   for a nasty little special case:  we do NOT want -(4) to be written
%   out as -4; that's quite a different term!

unary_to_tokens(-, -(N), _) --> {number(N)}, !,
	[functor(-)], term_to_tokens(N, 999), [')'].
unary_to_tokens({}, {Term}, _) --> !,
	['{'], term_to_tokens(Term, 1200), ['}'].
unary_to_tokens(F, Term, Priority) -->
	{arg(1, Term, Arg)},
	(   {prefix(F, O, Q)} ->
	    (   {O > Priority} ->
		['(',prefix(F)], term_to_tokens(Arg, Q), [')']
	    ;       [prefix(F)], term_to_tokens(Arg, Q)
	    )
	;   {postfix(F, P, O)} ->
	    (   {O > Priority} ->
		['('], term_to_tokens(Arg, P), [postfix(F),')']
	    ;	       term_to_tokens(Arg, P), [postfix(F)]
	    )
	;   [functor(F)], term_to_tokens(Arg, 999), [')']
	).


%.  binary_to_tokens(+Functor, +Term, +Priority)(S0,S)
%   converts a binary term to a sequence of tokens.  In addition to
%   handling user-defined operators, it handles the bracket notation
%   for lists.  The public-domain version of write/1 also has a case
%   here to catch (A,B) so that the comma here is written as a plain
%   ",", not as a quoted atom "','" as using infix(',') might do.
%   I chose to omit that case here.  [Code available on request.]
%   Sorry about the layout in the second clause, but I wanted to make
%   the relation between the with-parens and the without-parens cases clear.

binary_to_tokens('.', [Head|Tail], _) --> !,
	['['],
	term_to_tokens(Head, 999),
	tail_to_tokens(Tail).
binary_to_tokens(F, Term, Priority) -->
	{infix(F, P, O, Q)},
	!,
	{arg(1, Term, A)},
	{arg(2, Term, B)},
	(   {O > Priority} ->
	    ['('],term_to_tokens(A, P),[infix(F)],term_to_tokens(B, Q),[')']
	;         term_to_tokens(A, P),[infix(F)],term_to_tokens(B, Q)
	).
binary_to_tokens(F, Term, _) -->
	[functor(F)],
	arguments_to_tokens(1, 2, Term).



%.  tail_to_tokens(Tail)(S0,S)
%   converts the tail of a list to a sequence of tokens.  This Tail
%   was preceded by a Head, which has been converted.

tail_to_tokens(Var) --> {var(Var)}, !,
	['|',var(Var),']'].
tail_to_tokens([]) --> !,
	[']'].
tail_to_tokens([Head|Tail]) --> !,
	[','],
	term_to_tokens(Head, 999),
	tail_to_tokens(Tail).
tail_to_tokens(Term) -->
	['|'],
	term_to_tokens(Term, 999).


%.  The original public-domain code was written to go with a similarly
%   public-domain version of op/3 and current_op/3 where the following
%   three tables were the primary reality.  Whether they are or aren't,
%   only current_op/3 is (currently) directly available to customers.

prefix(F, O, Q) :-
	(   current_op(O, fx, F) -> Q is O-1
	;   current_op(O, fy, F) -> Q is O
	).

postfix(F, P, O) :-
	(   current_op(O, xf, F) -> P is O-1
	;   current_op(O, yf, F) -> P is O
	).

infix(F, P, O, Q) :-
	(   current_op(O, xfy, F) -> P is O-1, Q is O
	;   current_op(O, xfx, F) -> P is O-1, Q is P
	;   current_op(O, yfx, F) -> Q is O-1, P is O
	).

end_of_file.


%   test_write/1, write_tokens/1, and write_token/1 are a test harness to
%   ensure that this file is working properly.
%   This provides a very rough and inefficient first approximation to an
%   output routine which takes line length into account.  The things it
%   doesn't do include reducing unnecessary spaces between operators and
%   operands when no confusion would result, getting the length right in
%   the presence of quoting, atoms which are too big to fit no matter
%   what you do (the answer is quote, use escapes, and insert \<newline>).
%   Basically, what we want is a "write_token" primitive down at the C
%   level somewhere.

test_write(Term) :-
	term_to_tokens(Term, Tokens),
	current_output(Stream),
	line_position(Stream, Column),
	write_tokens(Tokens, Column).


write_tokens([], _).
write_tokens([Token|Tokens], C0) :-
	write_token(Token, C0, C1),
	write_tokens(Tokens, C1).

write_token(Token, C0, C1) :-
	token_length(Token, Length),
	(   C0+Length > 75 ->
	    C1 is Length,
	    nl,
	    write_token(Token)
	;   C1 is C0+Length,
	    write_token(Token)
	).

token_length('(', 1).
token_length(',', 1).
token_length(')', 1).
token_length('[', 1).
token_length('|', 1).
token_length(']', 1).
token_length('{', 1).
token_length('}', 1).
token_length(var(_), 8).	% sometimes an over-estimate
token_length(integer(X), L)	:- constant_length(X, 0, L).
token_length(float(X), L)	:- constant_length(X, 0, L).
token_length(atom(X), L)	:- constant_length(X, 0, L).
token_length(prefix(X), L)	:- constant_length(X, 1, L).
token_length(infix(X), L)	:- constant_length(X, 2, L).
token_length(postfix(X), L)	:- constant_length(X, 1, L).
token_length(functor(X), L)	:- constant_length(X, 1, L).

constant_length(Constant, L0, L1) :-
	name(Constant, Chars),
	length(Chars, L),
	L1 is L0+L.

write_token('(')		:- put("(").
write_token(',')		:- put(",").
write_token(')')		:- put(")").
write_token('[')		:- put("[").
write_token('|')		:- put("|").
write_token(']')		:- put("]").
write_token('{')		:- put("{").
write_token('}')		:- put("}").
write_token(var(X))		:- write(X).
write_token(integer(X))		:- write(X).
write_token(float(X))		:- write(X).
write_token(atom(X))		:- write(X).
write_token(prefix(X))		:-           write(X), put(" ").
write_token(infix(X))		:- put(" "), write(X), put(" ").
write_token(postfix(X))		:- put(" "), write(X).
write_token(functor(X))		:- write(X), put("(").

