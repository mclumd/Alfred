%   Package: long.pl
%   Author : Richard A. O'Keefe
%   Updated: 19 Jan 1994
%   Purpose: Arbitrary precision rational arithmetic package.

%   Copyright (C) 1981, 1982, 1983, 1984, 1985 - Richard A. O'Keefe.
%   Adapted from shared code written by the same authors; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This package provides arithmetic for arbitrary precision rational
    numbers.  The normal domain of Prolog 'integers' is extended to full
    rational 'numbers'.  This domain includes all Prolog integers.  The
    predicate:
		    rational(N)

    will recognise any number in this extended domain.  (This is the
    predicate I propose in my "Draft Proposed Standard for Prolog
    Buult-in Predicates" for this operation.  The Dec-10 version of
    this package used number/1, but number/1 in C Prolog and Quintus
    Prolog recognises any sort of number.)
    Rational numbers are produced by using the predicates

		    eval(Command)

		    eval(Expression, Answer)

    Expression can involve any form of rational number, whether such
    numbers can be represented by Prolog integer or not.  Any form of
    number produced as output by "eval" is acceptable as input to it.

    For convenience the Answer produced by eval is normalised as follows:

    a) integers which fit in the range of Prolog 32-bit 2-s complement
       integers are represented as Prolog integers; (The negative
       boundary is -(2^31-1) rather than -2^31 since Prolog can not
       read back -2^31 as an integer.)

    b) 1/0, 0/0, -1/0 are represented as infinity, undefined, neginfinity;

    c) All other numbers are represented as full rationals in reduced form
       i.e. numerator and denominator are relatively prime.

    In the current representation, one normalised number will unify with
    another (including an integer) iff the two numbers are equal.  But
    it is better to test for equality between arbitrary numbers using

		    eval(N1=:=N2)

    which also handles infinity & undefined, and is guaranteed to work.
    Once created, representations of rational numbers can be passed
    round your program, used with eval, or printed.  The predicate

		    portray_number(Number)

    will pretty-print arbitrary numbers, and will fail for anything
    else.  In particular, it will not evaluate an expression.  (But
    eval(write(Expr)) combines evaluation and printing if you want.)  If
    this is connected up to your general "portray" mechanism, you will
    never have to see the internal representation of rationals.  It is
    ill-advised to write procedures which assume knowledge of this
    internal representation as it is subject to change (rarely), not to
    mention that such activities are against all the principles of
    abstraction and structured programming.

NB: Note that eval/1 and eval/2 will only evaluate fully numeric
    expressions.  If there is some garbage in the expression (such as an
    atom) then no evaluation at all occurs and the whole input
    expression is returned untouched.  If you want to evaluate mixed
    symbolic and numeric expressions then use tidy/2 (from TIDY.PL)
    which is designed for this purpose.

CHANGES

[3 April 1981]

	Added the functions numer(_), denom(_) and sign(_) to the 
	evaluator (i.e. eva2).

[8 April 1981]

	removed choice-points from comq, and corrected sign(.).
	replaced the log routine completely.

[14 April 1981]

	changed all XXXr routines to XXXn (for Natural or zero)
	changed all XXXs routines to XXXm (for Modified (Natural routines))
	changed all XXXl routines to XXXz (for the ring Z of integers)
	replaced "digits" by "conn" as I've meant to for some time.
	removed experimental 'xwd' code which doesn't work compiled.  Eheu.
	changed estq,chkq,gest to estd,chkd,estg (estimate division digit,
	check digit, estimate Gcd) to avoid confusion; they don't use rationals.
	rewrote norm_number and renamed it to stdq.
	laid the trig routines out in MY style not Lawrence's.
	Increased the radix from 10,000 to 100,000 after fixing addn to use
	unsigned numbers.

[21 April 1981]

	Continued tidying things up.
	made 0^(1/N) = 0; this was an oversight.
	added new xwd(,) code in eva2, and beautified portray_number.

[8 July 1981]

	fixed mode error bug in eva2(abs(_),_).  Foolish oversight.

[9 September 1981]

	fixed negative number bugs in arccos and arcsin.  How long have
	these been around without anyone (except Bernard) noticing?
	Also shunted some cuts around in the same general area.

[13 September 1981]

	corrected typo {da=>Da} in gcdq/4.

[2 December 1981]

	corrected a benign bug in number/5 (100000 had been written
	where R should have been), and some minor cosmetic changes.
	Unified error reporting into long_error[_message].  Added a
	few mode declarations for trig functions.

[9 December 1981]

	when writing eval up for EuroSam, discovered that logs aren't
	handled properly.  Rewrote absq and logq to return 'undefined'
	in more cases, instead of failing.

[27 July 1982]

	changed prnq/3 to portray_number/3 and laid it out properly.
	changed prin/1 to putn/1 (put Natural) to avoid conflict elsewhere.	
	Made this stuff call put/1 where it made sense, and used ASCII
	codes instead of strings.  Don't know if it matters, really.
	Also rewrote arctaneval completely, so that it should succeed in a
	few more cases.  Really, the trig stuff is PITIFUL.  Please, will
	someone do a proper job of it (preferrably someone PAID to do it).

[30 August 1982]

	fixed bug in gcdq/4 so that gcd(1/2,1/4) = 1/4, not 1/2!

[12 July 1983]

	arctaneval used to call addn/4, and there isn't any such
	predicate.  Made it call addn/5.

[23 March 1985]

	Converted to Quintus Prolog.  Changes:
	all occurrences of mod 2 changed to /\ 1; uses of / for integer
	division changed to //, radix changed from 100000 to 10000.

[20 June 1986]

	Decided to include it in the released library.  Changes:
	+ completely re-laid-out so that find-definition would work;
	+ stripped out the "trig" stuff which was only ever for MECHO;
	+ added eval(X//Y, Z) for compatibility with "Z is X//Y";
	+ made stdq/2 yield a Prolog integer if it possibly can.
	- Yet to be done: implement reversible plus/3 and times/3
	- instead of one-way add/3 and multiply/3;
	- add more comments and document?

[21 June 1986]

	Added the non-evaluating comparison predicates {lt,eq,gt,ge,ne,le}/2.
	These operations are copied from C Prolog, where they accept only
	integers, but they would have accepted rationals had such existed.
	NB: *none* of the rational routines will tolerate floats or complexes.
	Fixed rational/1 so it rejects variables.

[28 June 1986]

	Added comQ/[2,4] to make the comparisons more uniform.  This should be
	done at a lower level; as comQ is generally what we want, all of the
	com* predicates should return numbers and comq/4 should be built from
	comQ/4 rather than the other way around.  Tidied up eval(comparison).

	Introduced if->then;else in addn/5, subp/5, estg/4.  This hadn't been
	done before because the Dec-10 compiler didn't understand it.
	Eliminated several cuts.  Lots more should go.

	Added log(X,Y) to eva2.  Don't rely *too* much on it, hnn?

	Fixed a major bug in pown/5.

	Implemented succ/2, plus/3, times/3 (retained old power/3).
	succ/2 and plus/3 are copied from C Prolog, where they proved
	very useful indeed.
	Added whole/1 (mainly so I could describe succ/2 accurately).

[24 March 1987]

	Added proper_number/5 for the division routines.
	Made portray_number/1 check its argument much more strictly.
	Replaced numeric character codes by "x" form in preparation
	for non-ASCII character sets.
	Removed some more cuts.
	Added stdq/3 as an optimisation of stdq/2.
	Added {floor,ceiling,round,truncate}/2.

[26 March 1987]

	Added {floor,ceiling,round,truncate}/3
	Added {floor,ceiling,round,truncate}/4.  Whew!
	stdq/4 was added for this last group, perhaps use it elsewhere?

[6 February 1988]

	Stripped out the radix parameter, and built the radix into
	the bottom-level routines.  Removed more cuts.
	Made power/3 multidirectional (hasn't been tested yet).
	Added comN/3 (faster comn/4, returns -1,0,or +1), started using it.
*/


:- module(long, [
	rational/1,		%  rational(N) <=> N is a rational number
	whole/1,		%  whole(N) <=> N is a (big) integer
	eval/1,			%  eval(E) => E/rational-eval is true
	eval/2,			%  eval(E,A) => (A is E)/rational-eval
	(eq)/2,
	(ge)/2,
	(gt)/2,
	(le)/2,
	(lt)/2,
	(ne)/2,
	portray_number/1,	%  writes rational assumed radix 100000.
%				%  Lawrence's Low Level TIDY interface
	succ/2,			%  succ(M,N) <=> integer(M),M>=0,N=M+1
	plus/3,			%  plus(A,B,C) => (C is A+B)/rational-eval
	times/3,		%  similar for *.  NB A,B must be numbers
	power/3,		%  similar for ^.  NOT general terms.
	floor/2,	floor/3,	floor/4,
	ceiling/2,	ceiling/3,	ceiling/4,
	round/2,	round/3,	round/4,
	truncate/2,	truncate/3,	truncate/4
   ]).

sccs_id('"@(#)94/01/19 long.pl	71.1"').


/* OPERATORS */

:- op(300, xfx, div).		%  integer quotient A div B = fix(A/B).


/* MODES and types */

%   The comments at the right give the argument types for each predicate.
%   The predicates can of course be called with any arguments, but these
%   are the only types they are supposed to work on or deliver.  
%   ? = any Prolog term, possibly including variables.
%   E = an arithmetic Expression, a term.
%   A = a Prolog atom (but not an integer).
%   I = a Prolog integer.  Generally positive, but not always.
%   T = a Truth-value, 'true' or 'false'.
%   S = a Sign, '+' or '-'.  {Sometimes can be 0 or *.}
%   R = a Relational operator, {<, =, >; sometimes =<, >=, =/=}
%   N = a long positive (Natural) number.
%   Q = a rational number.

:- mode

%% Top Level %%

    rational(+),				% Q
    whole(+),					% Q
    eval(+),					% E
    eval(+, -),					% E Q
	eva2(+, -),				% E Q
    portray_number(+),				% Q
	portray_number(+, +, +), 		% S N N
	    putn(+),				% N

%% Conversions %%

    proper_number(+, ?, ?, ?),			% Q S N N
    number(+, ?, ?, ?),				% Q S N N
	binrad(+, -),				% I N
    stdq(+, +, ?),				% N S Q
    stdq(+, +, +, ?),				% N N S Q
    stdq(+, ?),					% Q Q
	stdn(+, ?),				% N I

%% Reversible relational forms %%

    succ(?, ?),					% Q Q
    plus(?, ?, ?),				% Q Q Q
    times(?, ?, ?),				% Q Q Q
    power(?, ?, ?),				% Q Q Q

    floor(+, -),				% Q I
    ceiling(+, -),				% Q I
    round(+, -),				% Q I
    truncate(+, -),				% Q I
    round1(+, +, +, -),				% N N N N

    floor(+, +, -),				% Q Q I
    ceiling(+, +, -),				% Q Q I
    round(+, +, -),				% Q Q I
    truncate(+, +, -),				% Q Q I
    div_parts(+, +, -, -, -, -),		% Q Q S N N N
    remainder(+, +, +, +, -),			% S N N Q Q

    floor(+, +, +, -),				% Q Q I Q
    ceiling(+, +, +, -),			% Q Q I Q
    round(+, +, +, -),				% Q Q I Q
    truncate(+, +, +, -),			% Q Q I Q
    div_patch(?, ?, ?, ?),			% Q Q I Q

	/* from here on, the modes are wrong */
%% Rational Arithmetic %%

    comQ(+, +, +, ?),				% Q Q I I
	comQ(+, ?),				% R     I
    mod2(+, ?),					% Q I
    intq(+,    +, -),				% Q   I Q
    gcdq(+, +, +, -),				% Q Q I Q
/*  invq(+,    +, -),				% Q   I Q  */
    mulq(+, +, +, -),				% Q Q I Q
    divq(+, +, +, -),				% Q Q I Q
    divo(+, +, +, -, -),			% Q Q I Q Q
    powq(+, +, +, -),				% Q Q I Q
    negq(+,    +, -),				% Q   I Q
    addq(+, +, +, -),				% Q Q I Q
    subq(+, +, +, -),				% Q Q I Q
    comq(+, +, ?),				% Q Q R
    comQ(+, +, -),				% Q Q I
    nthq(+, +, +, -),				% I Q I Q
	nthn(+, +, +, -),			% I N I N
	    newton(+, +, +, +, -),		% I N N I N
		newton(+, +, +, +, +, -),	% R I N N I N

  %% Long Arithmetic %%

    addz(+,+, +,+, +, -,-),			% S N S N I S N
	addn(+, +, +, +, -),			% N N I I N
	    add1(+, +, -),			% N I N
    comz(+,+, +,+, ?),				% S N S N R
	comn(+, +, +, ?),			% N N R R
	    com1(+, +, +, -),			% I I R R
    subz(+,+, +,+, +, -,-),			% S N S N I S N
	subn(+, +, +, -,-),			% N N I S N
	    subn(+, +, +, +, -,-),		% R N N I S N
		prune(+, -),			% N N
		subp(+, +, +, +, -),		% N N I I N
		    sub1(+, +, -),		% N I N
    sign(+, +, -),				% S S S
/*  mulz(+,+, +,+, +, -,-),			% S N S N I S N  */
	muln(+, +, +, -),			% N N I N
	    muln(+, +, +, +, -),		% N N N I N
		mul1(+, +, +, -),		% N I I N
		    mul1(+, +, +, +, -),	% N I I I N
    powz(+,+, +, +, -,-),			% S N I I S N
	pown(+, +, +, +, -),			% I N N I N
    divz(+,+, +,+, +, -,-, -,-),		% S N S N I S N S N
	divn(+, +, +, -, -),			% N N I N N
	    conn(?, ?, ?),			% I N N
	%   both +, +, - and -, -, + are used.
	    div1(+, +, +, -, -),		% N I I N N
	    divm(+, +, +, -, -),		% N N I N N
		div2(+, +, +, -, -),		% N N I N N
		    estd(+, +, +, -),		% N N I I
		    chkd(+, +, +, +, +, -, -),	% N N I I I I N
/*  gcdz(+,+, +,+, +, -, -,-, -,-),		% S N S N I N S N S N  */
	gcdn(+, +, +, -, -, -),			% N N I N N N
	    gcdn(+, +, +, -),			% N N I N
		gcdn(+, +, +, +, -),		% R N N I N
		    estg(+, +, +, -),		% N N I I

%% Logarithms %%

    logq(+, +, +, -),				%  Q Q I Q
	logq(+,+, +,+,+,-),			%  R R Q Q I Q
	absq(+, -, -),				%  Q S Q
	    logq(+, -,-),			%  S S N
	    oneq(+, -, -),			%  Q R Q
	    ratlog(+, +, +, -),			%  Q Q I Q
		ratlog(+,+, +,+,+, -),		%  S S Q Q I Q
		    lograt(+,+,+, -,-),		%  Q Q I N N
			loop(+, +, +, -),	%  N N I N
			    loop(+,+,+,+,-),	%  N N N I N
			logn(+,+,+,+,-),	%  Q I Q Q I I 

%% Non-evaluating Comparison %%

    eq(+, +),					%  Q Q
    ge(+, +),					%  Q Q
    gt(+, +),					%  Q Q
    le(+, +),					%  Q Q
    lt(+, +),					%  Q Q
    ne(+, +),					%  Q Q

%% Error handing %%

    long_error(+, ?),				%  A ?
	long_error_message(+, -),		%  A A
    long_error(+, ?, ?),			%  A ? ? 
	div_error(+,+,+,+).			%  Q Q Q Goal

/* Implementation

	The internal representation for rationals is of the form:

		number(Sign, Numerator, Denominator)

		    where
			Sign is in {+,-}
			Numerator is a list of (Prolog) integers
			Denominator is a list of (Prolog) integers

	The lists of Prolog integers represent arbitrary precision unsigned
	long integers

		eg [n0,n1,....,nz]

		    is n0+R*(n1+R*(....R*nz)...)

		    where R is the Radix.

	The Radix used in the current version is 10000. Most of the code
	in this module is completely independent of the radix - it all
	uses the value passed in by the top level procedures. However the
	printing routine currently assumes that the radix is a power of
	10 as this makes things easier. In general the radix must be such
	that both:

			Radix^2 - 1
		   and	Radix*2 + 1

				are representable as Prolog integers (which
	are 18 bit quantities on the DEC10). This is a little restrictive,
	however, and this implementation only assumes that Radix^2 - 1 is
	"obtainable" as an intermediate during Prolog arithmetic. On the
	DEC10 intermediate results can be 36 bit quantities and so 100000
	becomes a suitable radix.  In C Prolog and Quintus Prolog 10000 is
	a better radix.  

	The code actually unpacks the number terms into their separate
	bits for all the low level operations. At this stage the following
	additional number forms are appropriately converted

		<integer>   -	(Prolog integers)
		infinity    -	represented as +1/0
		neginfinity -	represented as -1/0
		undefined   -	represented as  0/0

	The treatment of these strange things is not supposed to be
	mathematically beautiful, but sensible things happen using
	this representation. They are strictly an extension to the
	rationals and could be removed (with eval failing should 0
	denominator numbers ever get produced) if desired.

	Results from eval are normalised before being returned.
	This operation reverses the above transformation: a number
	will be represented as a 32-bit Prolog integer if that is
	at all possible, so that when X is Expr and eval(X is Expr)
	both give a correct answer, they give exactly the same answer.
*/



%% TOP LEVEL PREDICATES %%



			% Number recognition predicate

rational(N)		:- integer(N), !.
rational(number(S,_,_))	:- !, atom(S).	% filters out variables too.
rational(infinity).
rational(neginfinity).
rational(undefined).


			% Integer recognition predicate

whole(N)		:- integer(N), !.
whole(number(S,_,[1]))	:- atom(S).



			% Simple eval interpreter with various features.

eval(Var)      :- var(Var), !, long_error(eval, Var).
eval(B is Y)   :- eval(Y, B).
eval(write(Y)) :- eval(Y, B), portray_number(B).
eval(even(X))  :- eva2(X, A), mod2(A, 0).
eval(odd( X))  :- eva2(X, A), mod2(A, 1).
eval(compare(R,X,Y)) :-
		  eva2(X, A), eva2(Y, B), comq(A, B, S), R = S.
eval(X=:=Y)    :- eva2(X, A), eva2(Y, B), comQ(A, B, D), D =:= 0.
eval(X=\=Y)    :- eva2(X, A), eva2(Y, B), comQ(A, B, D), D =\= 0.
eval(X > Y)    :- eva2(X, A), eva2(Y, B), comQ(A, B, D), D  >  0.
eval(X=< Y)    :- eva2(X, A), eva2(Y, B), comQ(A, B, D), D =<  0.
eval(X < Y)    :- eva2(X, A), eva2(Y, B), comQ(A, B, D), D  <  0.
eval(X >=Y)    :- eva2(X, A), eva2(Y, B), comQ(A, B, D), D  >= 0.


mod2(number(_,_,[]),    _) :- !, fail.
mod2(number(_,[],_),    0) :- !.
mod2(number(_,[L|_],_), M) :- M is L /\ 1.


			% General evaluation of rational expressions

eval(Exp, Ans) :-	%    Hope for the best
	eva2(Exp, N),
	stdq(N, A), !,
	Ans = A.
eval(Exp, Exp).		%    Cannot evaluate so leave alone
%	format(user_error, '~N! error in rational expression: ~q~n', [Exp]).



eva2(Var, _)     :- var(Var), !, long_error(eva2, Var).
eva2(X+Y, C)     :- !, eva2(X, A), eva2(Y, B), addq(A, B, C).
eva2(X-Y, C)     :- !, eva2(X, A), eva2(Y, B), subq(A, B, C).
eva2( -Y, C)     :- !,             eva2(Y, B), negq(   B, C).
eva2(X*Y, C)     :- !, eva2(X, A), eva2(Y, B), mulq(A, B, C).
eva2(X/Y, C)     :- !, eva2(X, A), eva2(Y, B), divq(A, B, C).
eva2(X//Y, C)    :- !, eva2(X, A), eva2(Y, B), divo(A, B, C, _).
eva2(X div Y, C) :- !, eva2(X, A), eva2(Y, B), divo(A, B, C, _).
eva2(X mod Y, C) :- !, eva2(X, A), eva2(Y, B), divo(A, B, _, C).
eva2(X^Y, C)     :- !, eva2(X, A), eva2(Y, B), powq(A, B, C).
eva2(gcd(X,Y),C) :- !, eva2(X, A), eva2(Y, B), gcdq(A, B, C).
eva2(log(X,Y),C) :- !, eva2(X, A), eva2(Y, B), logq(A, B, C).
eva2(fix(X), C)  :- !, eva2(X, A), 	       intq(A, C).
eva2(  \(X), C)  :- !, eva2(X, A), addq(A, 1, B), negq(B, C).
eva2(abs(X),   number(+,N, D )) :- !, eva2(X, A), A = number(_,N,D).
eva2(numer(X), number(+,N,[1])) :- !, eva2(X, A), A = number(_,N,_).
eva2(denom(X), number(+,D,[1])) :- !, eva2(X, A), A = number(_,_,D).
eva2(sign(X),  number(S,B,[1])) :- !, eva2(X, A), A = number(S,N,_),
				      (N=[], B=[] ; B=[1]), !.
eva2(X, C) :- number(X, S, N, D), !, C = number(S, N, D).



			% Pretty-Print a number.
			%  This now always forces parentheses. When a
			%  proper general portray handler is written
			%  this could be made cleverer (as it once was).
			%  The magic numbers are 40 = "(", 41 = ")",
			%  45 = "-", 47 = "/", 48 = "0" {ASCII codes}.

portray_number(number(S,N,D)) :-
	atom(S),
	is_n(N),
	is_n(D),
	portray_number(S, N, D).

			% is_n(L) is true when L is a proper list of
			% Digits 0..9999

is_n(0) :- !, fail.	% catch variables
is_n([]).
is_n([H|T]) :-
	integer(H), H >= 0, H < 10000,
	is_n(T).


portray_number(_,[],  []) :- !,		%  0/0 = undefined
	write(undefined).
portray_number(+, _,  []) :- !,		% +N/0 = +infinity
	write(infinity).
portray_number(-, _,  []) :- !,		% -N/0 = -infinity
	write(neginfinity).
portray_number(+, N, [1]) :- !,		% +N/1 = a +ve integer
	putn(N).
portray_number(-, N, [1]) :- !,		% -N/1 = a -ve integer
	put("-"), putn(N).
portray_number(+, N,  D ) :- !,		% +N/D = a +ve rational
	put("("), putn(N), put("/"), putn(D), put(")").
portray_number(S, N,  D ) :- 		% -N/D = a -ve rational
	put("("), write(S), putn(N), put("/"), putn(D), put(")").

putn([]   ) :- !, put("0").
putn([D]  ) :- !, write(D).
putn([D|T]) :- 
	putn(T),
	D3 is (D//1000)       + "0", put(D3),	% D3*10^3 +
	D2 is (D//100) mod 10 + "0", put(D2),	% D2*10^2 +
	D1 is (D//10) mod 10  + "0", put(D1),	% D1*10^1 +
	D0 is (D) mod 10      + "0", put(D0).	% D0*10^0 = D.


%% INTERFACE CONVERSIONS %%

			% Conversion of a number, of any form, to its
			%  essential bits.

proper_number(variable, _, _, _) :- !, fail.
proper_number(number(S, N, D), S,  N,  D) :- !.
proper_number(N, S, L, [1]) :-
	integer(N),
	(   N >= 0 -> S = +, binrad(N, L)
	;   M is -N,  S = -, binrad(M, L)
	).

number(variable,        _, _ ,  _) :- !, fail.
number(infinity,        +,[1], []) :- !.
number(neginfinity,     -,[1], []) :- !.
number(undefined,	+, [], []) :- !.
number(number(S, N, D), S,  N,  D) :- !.
number(N/D,             S,  L,  K) :- !,
	integer(D), integer(N),
	D >= 0,
	(   N >= 0 -> S = +, binrad(N, L)
	;   M is -N,  S = -, binrad(M, L)
	),
	binrad(D, K).
number(N, S, L, [1]) :-
	integer(N),
	(   N >= 0 -> S = +, binrad(N, L)
        ;   N =:= 1<<31 -> % cannot be negated
		S = -, L=[3648, 4748, 21]
	;   M is -N,  S = -, binrad(M, L)
	).

binrad(0, []) :- !.
binrad(N, [M|T]) :-
	K is N  // 10000,
	M is N mod 10000,
	binrad(K, T).



			% Normalise a number

stdq(Num, S, Ans) :-	% stdq(N, S, A) :- stdq(number(S,N,[1]), A).
	stdn(Num, N),
	!,
	(   S = + -> Ans = N
	;   S = - -> Ans is -N
	).
stdq(Num, S, number(S,Num,[1])).


			% stdq(D,N,S, A) :- stdq(number(S,N,D), A).
stdq([1], Num, S, Ans) :-
	stdn(Num, N),
	!,
	(   S = + -> Ans = N
	;   S = - -> Ans is -N
	).
stdq([], N, S, Ans) :- !,
	(   N =[] -> Ans = undefined
	;   S = + -> Ans = infinity
	;   S = - -> Ans = neginfinity
	).
stdq(D, N, S, number(S,N,D)).


stdq(number(S,Num,[1]), Ans) :-
	stdn(Num, N),
	!,
	(   S = + -> Ans = N
	;   S = - -> Ans is -N
	).
stdq(number(S,N,[]), Ans) :- !,
	(   N =  [] -> Ans = undefined
	;   S = + -> Ans = infinity
	;   S = - -> Ans = neginfinity
	).
stdq(Number, Number).


stdn([], 0) :- !.
stdn([D0], D0) :- !.
stdn([D0,D1], N) :- !,
	N is D1*10000+D0.
stdn([D0,D1,D2], N) :-
	T is D2*10000+D1,
	(   T < 214748 -> true
	;   T =:= 214748, D0 =< 3647 -> true
	),
	N is T*10000+D0.


%% BASIC ARITHMETIC OVER RATIONALS %%


			% Integer part of a rational

intq(A, number(S, Q, [1])) :-
	number(A, S, N, D),
	divn(N, D, Q, _).



			%   The greatest common divisor of two numbers is
			%   defined for all pairs of non-zero rationals.
			%   gcd(X,Y) = Z iff Z > 0 and there are integers
			%   M,N relatively prime for which X=MZ & Y=NZ.

gcdq(A, B, number(+,Nd,Dd)) :-
	number(A, _, Na, Da),
	number(B, _, Nb, Db),
	gcdn(Da, Db, _, Ga, Gb),
	muln(Gb, Na, Ma),
	muln(Ga, Nb, Mb),
	gcdn(Ma, Mb, Nd),
	muln(Gb, Da, Dd).

/*	The above seems to be right, but I'm not sure.  This IS right.
gcdq(A, B, number(+,Nd,Dd)) :-
	number(A, _, Na, Da),		%  |A| = Na/Da
	number(B, _, Nb, Db),		%  |B| = Nb/Db
	muln(Na, Db, N1),		%  N1 = Na.Db
	muln(Nb, Da, N2),		%  N2 = Nb.Da
	gcdn(N1, N2, Nc),		%  Nc = gcd(Na.Db, Nb.Da)
	muln(Da, Db, Dc),		%  Dc = Da.Db
	gcdn(Nc, Dc, _, Nd, Dd).	%  Nd/Dd = Nc/Dc in standard form
*/

			% Take the inverse of a rational

invq(A, number(S, D, N)) :-
	number(A, S, N, D).



			% Multiplication of two rationals

mulq(A, B, number(Sc, Nc, Dc)) :-
	number(A, Sa, Na, Da),
	number(B, Sb, Nb, Db),
	sign(Sa, Sb, Sc),
	gcdn(Na, Db, _, Na1, Db1),
	gcdn(Da, Nb, _, Da1, Nb1),
	muln(Na1, Nb1, Nc),
	muln(Da1, Db1, Dc).



			% Division of two rationals

divq(A, B, number(Sc, Nc, Dc)) :-
	number(A, Sa, Na, Da),
	number(B, Sb, Nb, Db),
	sign(Sa, Sb, Sc),
	gcdn(Na, Nb, _, Na1, Nb1),
	gcdn(Da, Db, _, Da1, Db1),
	muln(Na1, Db1, Nc),
	muln(Da1, Nb1, Dc).



			% Quotient and remainder of two rationals

divo(A, B, number(Sq,Nq,[1]), number(Sx,Nx,Dx)) :-
	number(A, Sa, Na, Da),		%  A = Sa.Na/Da
	number(B, Sb, Nb, Db),		%  B = Sb.Nb/Db
	muln(Na, Db, N1),		%  A/B = (Sa.Na.Db)/(Sb.Nb.Da)
	muln(Nb, Da, D1),		%      = (Sa.N1)/(Sb.D1)
	divz(Sa,N1, Sb,D1, Sq,Nq, Sx,Ny),
	muln(Da, Db, Dy),		%  A/B = Q + (Sx.Ny)/(Sb.Nb.Da)
	gcdn(Ny, Dy, _, Nx, Dx).	%  A = Q.B + (Sx.Ny)/Dy



			% Exponentiation of rationals
			%  This is always defined for (positive or
			%   negative) integer powers, however there
			%   is a current implementation restiction that
			%   the power be between -9999 and +9999 (ie
			%   within the current Radix).
			%  This may be defined for some rational powers
			%   but since there are results from this which are
			%   not representable as rationals it will fail
			%   in such cases.  The code for rational powers
			%   relies on numerator and denominator being
			%   relatively prime, which is standard.

powq(A, B, C) :-
	number(B, S, N, [1]),
	!,
	powq(S, N, A, C).
powq(A, B, C) :-
	number(B, S, N, [D]),
	nthq(D, A, X), !,
	powq(S, N, X, C).

powq(_, [], _, number(+,[1],[1])) :- !.
powq(+,[N], A, number(Sc, Nc, Dc)) :-
	number(A, Sa, Na, Da),
	powz(Sa, Na, N, Sc, Nc),
	pown(N,  Da,[1],    Dc).
powq(-,[N], A, number(Sc, Nc, Dc)) :-
	number(A, Sa, Na, Da),
	powz(Sa, Da, N, Sc, Nc),
	pown(N,  Na,[1],    Dc).



			% Negate a rational

negq(A, number(Sc, Nc, Dc)) :-
	number(A, Sa, Nc, Dc),
	(   Nc = [], Dc = [] -> Sc = +		%  -undefined=undefined
	;   sign(Sa, -, Sc)			%  -0 = -(0) now.
	).



			% Addition of two rationals

addq(A, B, number(Sc, Nc, Dc)) :-
	number(A, Sa, Na, Da),
	number(B, Sb, Nb, Db),
	muln(Na, Db, Xa),
	muln(Nb, Da, Xb),
	addz(Sa,Xa, Sb,Xb, Sc,Xc),
	gcdn(Xc, Da, _, Nx, Ya),
	gcdn(Nx, Db, _, Nc, Yb),
	muln(Ya, Yb, Dc), /*Q'*/ Nc/Dc\==[]/[], !.
addq(A, B, number(Sc, Nc, [])) :- /*Q'*/
	number(A, Sa, Na, _a),
	number(B, Sb, Nb, _b),
	(   Na\==[], Nb\==[], Sa==Sb, Sc=Sa, Nc=[1]
	;   Sc= +, Nc=[]
	),  !.



			% Subtraction of two rationals

subq(A, B, number(Sc, Nc, Dc)) :-
	number(A, Sa, Na, Da),
	number(B, Sb, Nb, Db),
	muln(Na, Db, Xa),
	muln(Nb, Da, Xb),
	subz(Sa,Xa, Sb,Xb, Sc,Xc),
	gcdn(Xc, Da, _, Nx, Ya),
	gcdn(Nx, Db, _, Nc, Yb),
	muln(Ya, Yb, Dc), /*Q'*/ Nc/Dc\==[]/[], !.
subq(A, B, number(Sc, Nc, [])) :- /*Q'*/
	number(A, Sa, Na, _a),
	number(B, Sb, Nb, _b),
	(   Na\==[], Nb\==[], Sa\==Sb, Sc=Sa, Nc=[1]
	;   Sc= +, Nc=[]
	),  !.



			% Comparison of two rationals

comQ(A, B, X) :-	% return a numeric value
	comq(A, B, S),
	comQ(S, X).

comQ(<, -1).		% convert a compare/3-style sign to
comQ(=,  0).		% a number we can test with Prolog
comQ(>,  1).		% built in arithmetic


comq(A, B, S) :-	% return a compare/3-style sign
	number(A, Sa, Na, Da), /*Q'*/ Na/Da \== []/[],
	number(B, Sb, Nb, Db), /*Q'*/ Nb/Db \== []/[],
	muln(Na, Db, Xa),
	muln(Nb, Da, Xb),
	comz(Sa, Xa, Sb, Xb, S).



			% Try to find Nth root
			%  This will fail in cases where the solution is
			%  not representable as a rational

nthq(N, A, number(S,Nr,Dr)) :-
	number(A, S, Na, Da),
	nthk(S, N),	% check that the sign is compatible with N
	nthn(N, Na, Nr),
	nthn(N, Da, Dr).

nthk(+, _).
nthk(-, N) :-
	N /\ 1 =:= 1.	% only odd roots of -ve numbers are allowed

nthn(_,  [],  []) :- !.
nthn(_, [1], [1]) :- !.
nthn(N,   A,   S) :-
	newton(N, A, A, S),
	pown(N, S, [1], B),
	B = A.		% check that S^N=A !

newton(N, A, E, S) :-
	M is N-1,
	pown(M, E, [1], E1),	% E1=E^(N-1)
	mul1(E1, N, D2),	% D2=N.E^(N-1)
	muln(E, E1, E2),	% E2=E^N
	mul1(E2, M, N1),	% N1=(N-1).E^N
	addn(N1, A, 0, N2),	% N2=(N-1).E^N+A
	divn(N2, D2, F, _),	% F = {(N-1).E^N+A}div{N.E^(N-1)}
	comn(F, E, =,  Z),	% F Z E
	newton(Z, N, A, F, S).

newton(=, _, _, F, F).
newton(<, N, A, F, S) :-
	newton(N, A, F, S).



	% Take the logarithm of a rational to a rational base.
	% This can be expected to fail for almost every pair
	% of rational numbers.  To keep the search space within


%   logq(B, X, L) is true iff
%	B, X, and L are rationals such that B^L = X.
%   This does its best for strange mixtures, like log(-3,-27) = 3.

logq(B, X, L) :-
	absq(B, S, C),		%   B S 0 & |B| = C
	absq(X, T, Y),		%   X T 0 & |X| = Y
	logq(S, T, C, Y, L).

%   absq(A, S, B) is true iff
%	A and B are rationals, |A| = B, and
%	S = {-,0,+,*} as A {<,=,>} 0 or is undefined.

absq(number(_,[],[]), *, number(+,[],[]))  :- !.
absq(number(_,[], _), 0, number(+,[],[1])) :- !.
absq(number(S,Na,Da), S, number(+,Na,Da)).

%   logq(S, T, ...) is just a case analysis of logq.

logq(+, +, B, X, L) :- !,
	ratlog(B, X, L).
logq(-, +, B, X, L) :- !,
	ratlog(B, X, L),
	mod2(L, 0).		%  L must be "even"
logq(-, -, B, X, L) :- !,
	ratlog(B, X, L),
	mod2(L, 1).		%  L must be "odd"
logq(+, -, _, _, _, number(+,[],[])) :- !.
logq(*, _, _, _, _, number(+,[],[])) :- !.	% B undefined
logq(_, *, _, _, _, number(+,[],[])) :- !.	% X undefined
logq(0, _, _, _, _, number(+,[],[])) :- !.	% B 0, X defined
logq(_, 0, B, _, _, number(Z, N,[])) :- !,	% X 0, B defined, non-zero
	oneq(B, S, _),
	log0(S, Z,N).

log0(+, -,[1]) :- !.	%  log(B,0) = -inf for 1<B<inf
log0(-, +,[1]) :- !.	%  log(B,0) = +inf for 0<B<1
log0(_, +,[]).		%  log(B,0) = ???? otherwise

%  oneq(A, S, B) is true when A and B are positive
%  defined rationals, |log A| = log B, and S = sign(log A).

oneq(number(_, _,[]), *, number(+,[1],[])) :- !.
oneq(number(_,Na,Da), S, number(+,Na,Da)) :-
	comN(Na, Da, R),
	sigN(R, S).

sigN(-1, -).
sigN( 0, 0).
sigN( 1, +).


%   ratlog(B, X, L) is true iff
%	B, X > 0 and B^L = X.

ratlog(B, X, L) :-
	oneq(B, S, C),	%  B S 1 & |log B| = log C
	oneq(X, T, Y),	%  X T 1 & |log X| = log Y
	ratlog(S, T, C, Y, L).

%  ratlog(S,T, ...) is just a case analysis

ratlog(+, +, B, X, number(+,N,D)) :- !,
	lograt(B, X, N, D).
ratlog(+, -, B, X, number(-,N,D)) :- !,
	lograt(B, X, N, D).
ratlog(-, +, B, X, number(-,N,D)) :- !,
	lograt(B, X, N, D).
ratlog(-, -, B, X, number(+,N,D)) :- !,
	lograt(B, X, N, D).
ratlog(0, _, _, _, _, number(+,[], [])) :- !.
ratlog(_, 0, _, _, _, number(+,[],[1])) :- !.
ratlog(+, *, _, _, _, number(+,[1],[])) :- !.
ratlog(-, *, _, _, _, number(-,[1],[])) :- !.
ratlog(_, *, _, _, _, number(+,[], [])) :- !.
ratlog(*, _, _, _, _, number(+,[], [])) :- !.

%   lograt(B, X, N, D) is true iff
%	B > 1, X > 1 are rationals, B^N = X^D, and gcd(N,D) = 1.

lograt(number(+,Nb,Db), number(+,Nx,Dx), [N], [D] ) :-
	gcdn(Db, Nx, U), !, U = [1],		%  Db co-prime Nx
	gcdn(Nb, Dx, V), !, V = [1],		%  Nb co-prime Dx
	loop(Nb, Nx, G), !,
	logn(G, 1, G, Nb, D), !,		%  D=log(G,Nb)
	logn(G, 1, G, Nx, N), !,		%  N=log(G,Nx)
	pown(N, Db, [1], K1),
	pown(D, Dx, [1], K2), !,
	K1 = K2.				%  Db^N = Dx^D

loop(A, B, G) :-
	comn(A, B, =, S),
	loop(S, A, B, G).

loop(=, A, _, A).
loop(<, A, B, G) :-
	divn(B, A, Q, X), X = [],
	loop(A, Q, G).
loop(>, A, B, G) :-
	divn(A, B, Q, X), X = [],
	loop(Q, B, G).

%   logn(B, N, P, X, L) is true iff
%	X >= B > 1, P = B^N, and X = B^L.

logn(_, N, X, X, N) :- !.
logn(B, N, P, X, L) :-
	comN(P, X, -1),		% P < X
	muln(B, P, Q),
	M is N+1,
	logn(B, M, Q, X, L).


%% BASIC ARITHMETIC OVER LONG INTEGERS %%


			% Addition of two long integers

addz(+,A, +,B, +,C) :- !, addn(A, B, 0, C).
addz(+,A, -,B, S,C) :- !, subn(A, B, S, C).
addz(-,A, +,B, S,C) :- !, subn(B, A, S, C).
addz(-,A, -,B, -,C) :- !, addn(B, A, 0, C).

addn([D1|T1], [D2|T2], Cin, [D3|T3]) :- !,
	Sum is D1+D2+Cin,
	(   Sum < 10000 -> Cout = 0, D3 =  Sum
	;		   Cout = 1, D3 is Sum-10000
	),
	addn(T1, T2, Cout, T3).
addn([], L, 0, L) :- !.
addn([], L, 1, M) :- !, add1(L, M).
addn(L, [], 0, L) :- !.
addn(L, [], 1, M) :- !, add1(L, M).

add1([],    [1]).
add1([M|T], X) :-
	N is M+1,
	(   N < 10000 -> X = [N|T]
	;   X = [0|S], add1(T, S)
	).



			% Comparison of two long integers

comz(_,[],_,[],S) :- !, S = '='.	% -0 = 0 now, alas.
comz(+,A, +,B, S) :- !, comn(A, B, =, S).
comz(+,_, -,_, >) :- !.
comz(-,_, +,_, <) :- !.
comz(-,A, -,B, S) :- !, comn(B, A, =, S).

comn([D1|T1], [D2|T2], D, S) :- !,
	com1(D1, D2, D, N),
	comn(T1, T2, N, S).
comn([],      [],      D, S) :- !, S = D.
comn([],      _,       _, <) :- !.
comn(_,       [],      _, >) :- !.

com1(X, X, D, D) :- !.
com1(X, Y, _, <) :- X < Y, !.
com1(X, Y, _, >) :- X > Y, !.

comN([], N2, S) :-
	comN1(N2, S).
comN([D1|T1], N2, S) :-
	comN2(N2, D1, T1, S).

comN1([], 0).
comN1([_|_], -1).

comN2([], _, _, 1).
comN2([D2|T2], D1, T1, S) :-
	(   D1 < D2 -> S = -1
	;   D1 > D2 -> S =  1
	;   comN(T1, T2, S)
	).

			% Subtraction of two long integers

subz(+,A, +,B, S,C) :- !, subn(A, B, S, C).
subz(+,A, -,B, +,C) :- !, addn(A, B, 0, C).
subz(-,A, +,B, -,C) :- !, addn(B, A, 0, C).
subz(-,A, -,B, S,C) :- !, subn(B, A, S, C).

subn(A, B, S, C) :-
	comn(A, B, =, O),  	%  Oh for Ordering
	subn(O, A, B, S, C).

subn(=, _, _, +,[]).
subn(<, A, B, -, C) :- subp(B, A, 0, D), prune(D, C).
subn(>, A, B, +, C) :- subp(A, B, 0, D), prune(D, C).

subp(A, B, C) :-
	subp(A, B, 0, D),
	prune(D, C).

prune([],    []).
prune([0|L], M ) :- !,
	prune(L, T),
	(T = [] -> M = [] ; M = [0|T]).
prune([D|L], [D|M]) :- !,
	prune(L, M).

subp([D1|T1], [D2|T2], Bin, [D3|T3]) :- !,
	S is D1-D2-Bin,
	(   S >= 0 -> Bout = 0, D3 =  S
	;   S <  0 -> Bout = 1, D3 is S+10000
	),
	subp(T1, T2, Bout, T3).
subp(L, [], 0, L) :- !.
subp(L, [], 1, M) :- !, sub1(L, M).

sub1([0|T], [K|S]) :- !, K is 9999, sub1(T, S).
sub1([N|T], [M|T]) :- M is N-1.



			% Multiplication of Signs

sign(S, S, +) :- !.
sign(_, _, -).



			% Multiplication of two long integers

mulz(S,A, T,B, U,C) :-
	sign(S, T, U),
	muln(A, B, C).

muln([], _, []) :- !.
muln(_, [], []) :- !.
muln(A,  B,  C) :- muln(A, B, [], C).

muln([],       _, Ac, Ac).
muln([D1|T1], N2, Ac, [D3|Pr]) :-
	mul1(N2, D1, P2),
	addn(Ac, P2, 0, Sm),
	conn(D3, An, Sm),
	muln(T1, N2, An, Pr).

mul1(_, 0, []) :- !.
mul1(A, M, Pr) :-
	mul1(A, M, 0, Pr).

mul1([], _, 0, []) :- !.
mul1([], _, C, [C]) :- !.
mul1([D1|T1], M, C, [D2|T2]) :-
	S is D1*M+C,
	D2 is S mod 10000,		% expand S in Dec-10 Prolog
	Co is S  // 10000,		% expand S in Dec-10 Prolog
	mul1(T1, M, Co, T2).



			% Exponentiation of a long integer to a short
			%  (Prolog) integer. Note that this means the
			%  power must be less than 10000 (current radix).
			%  This code should always be called with positive
			%  powers.

powz(S,A, N, T,C) :-
	( N /\ 1 =:= 0 -> T = + ; T = S),
	pown(N, A, [1], C).

pown(0, _, M, M) :- !.
pown(1, A, M, P) :- !,
	muln(A, M, P).
pown(N, A, M, P) :-
	N1 is N >> 1,
	(   N /\ 1 =:= 0 -> M1 = M
	;   muln(A, M, M1)
	),
	muln(A, A, A1),
	pown(N1, A1, M1, P).



			% Division of two long integers

divz(S,A, T,B, U,Q, S,X) :-
	sign(S, T, U),
	divn(A, B, Q, X).

divn(_, [], _, _) :- !, fail.	% division by 0 is undefined
divn(A,[1], A,[]) :- !.	 	% a very common special case
divn(A,[B], Q, X) :- !,	 	% nearly as common a case
	div1(A, B, Q, Y),
	conn(Y, [], X).
divn(A,  B, Q, X) :-
	comn(A, B, =, S),
	(   S = '<', Q =  [], X = A
	;   S = '=', Q = [1], X = []
	), !.
divn(A,  B, Q, X) :-
	divm(A, B, Q, X).

conn(0, [],   []) :- !.
conn(D, T, [D|T]).

div1([], _, [],  0).
div1([D1|T1], B1, Q1, X1) :-
	div1(T1, B1, Q2, X2),
	S is X2*10000+D1,
	D2 is S  // B1,		% expand S in Dec-10 Prolog
	X1 is S mod B1,		% expand S in Dec-10 Prolog
	conn(D2, Q2, Q1).

% divm(A, B, Q, X) is called with A > B > 10000

divm([], _, [], []).
divm([D1|T1], B, Q1, X1) :-
	divm(T1, B, Q2, X2),
	conn(D1, X2, T2),
	div2(T2, B, D2, X1),
	conn(D2, Q2, Q1).

div2(A, B, Q, X) :-
	estd(A, B, E), !,
	chkd(A, B, E, 0, Q, P), !,
	subn(A, P, _, X).   %  _=+
div2(A, B, _, _) :-
	long_error(divq, A/B).

estd([],         _, 0).
estd([_0,A1,A2], [_0,B1], E) :-
	B1 >= 5000, !,		% R >> 1
	E is (A2*10000+A1)//B1.
estd([A0,A1,A2], [B0,B1], E) :- !,
	L is (A2*10000+A1)//(B1+1),
	mul1([B0,B1],    L, P),
	subn([A0,A1,A2], P, _, N), !, %  _=+
	estd(N, [B0,B1], M),    !,
	E is L+M.
estd([A0,A1],    [B0,B1], E) :- !,
	E is (A1*10000+A0+1)//(B1*10000+B0).
estd([_A],       _, 0) :- !.
estd([_A|Ar],    [_B|Br], E) :- !,
	estd(Ar, Br, E).

chkd(A, B, _, 3, _, _) :- !,
	long_error(divq, A/B).
chkd(A, B, E, _, E, P) :-
	mul1(B, E, P),
	comn(P, A, <, <),
	!.
chkd(A, B, E, K, Q, P) :-
	L is K+1, F is E-1,
	chkd(A, B, F, L, Q, P).



			% GCD of two long integers

gcdz(S,A, T,B, D, S,M, T,N) :-
	gcdn(A, B, D, M, N).

gcdn([], [], [1],  [],  []) :- !.
gcdn([],  B,   B,  [], [1]) :- !.
gcdn( A, [],   A, [1],  []) :- !.
gcdn([1], B, [1], [1],   B) :- !.	%  common case
gcdn( A,[1], [1],   A, [1]) :- !.	%  common case
gcdn( A,  B,   D,   M,   N) :-	%  A, B > 1
	gcdn(A, B, D),
	divn(A, D, M, _),
	divn(B, D, N, _).

gcdn(A, B, D) :-		%  A, B >= 1  !!
	comn(A, B, =, S),
	gcdn(S, A, B, D).

gcdn(=, A, _, A).
gcdn(<,[], B, B) :- !.
gcdn(<, A, B, D) :-
	estg(B, A, E),
	muln(E, A, P),
	subn(B, P, _, M),
	gcdn(A, M, D).
gcdn(>, A,[], A) :- !.
gcdn(>, A, B, D) :-
	estg(A, B, E),
	muln(E, B, P),
	subn(A, P, _, M),
	gcdn(M, B, D).

estg(    A,   [B], E) :- !,
	div1(A, B, Q, X),
	(   X+X =< B -> E = Q
	;   add1(Q, E)
	).
estg([_|A], [_|B], E) :- !,
	estg(A, B, E).


%% ERROR HANDLING %%

long_error(Tag, Expression) :-
	long_error_message(Tag, Message),
	format(user_error, '~N! ~w: ~p~n', [Message, Expression]),
	fail.

long_error_message(eval, 'EVAL given a variable').
long_error_message(eva2, 'EVAL given an expression containing a variable').
long_error_message(divq, 'Unexpected rational division problem').



/*  Arithmetic comparison.

    Here we define six predicates:

	X lt Y		X eq Y		X gt Y
	X ge Y		X ne Y		X le Y

    They differ from the six standard predicates [(X < Y) and friends] and
    from the eval versions of them [eval(X < Y) and friends] in that they
    do not evaluate their arguments.  Like eval(X < Y), they work on rationals
    in standard form (including integers), and do not accept floating point
    numbers at all.  They are the fastest way of comparing rationals.  Note
    that the representation of rationals used in this package means that the
    standard term comparison operators [(X @< Y) and friends] do *NOT* yield
    the expected result on rationals: to compare rationals you MUST use eval
    or one of these routines.  If we ever provide rationals as a built in
    feature of Quintus Prolog, compare/3 will work as expected on them, but
    not until then.
*/

:- op(700, xfx, [lt,ge,eq,ne,gt,le]).

lt(X, Y) :-
	(   integer(X), integer(Y) -> X < Y
	;   rational(X), rational(Y) -> comQ(X, Y, D), D < 0
	;   long_error(lt, X, Y)
	).

eq(X, X) :-
	rational(X).

gt(X, Y) :-
	(   integer(X), integer(Y) -> X > Y
	;   rational(X), rational(Y) -> comQ(X, Y, D), D > 0
	;   long_error(eq, X, Y)
	).

ge(X, Y) :-
	(   integer(X), integer(Y) -> X >= Y
	;   rational(X), rational(Y) -> comQ(X, Y, D), D >= 0
	;   long_error(ge, X, Y)
	).

ne(X, Y) :-
	(   integer(X), integer(Y) -> X =\= Y
	;   rational(X), rational(Y) -> comQ(X, Y, D), D =\= 0
	;   long_error(ne, X, Y)
	).

le(X, Y) :-
	(   integer(X), integer(Y) -> X =< Y
	;   rational(X), rational(Y) -> comQ(X, Y, D), D =< 0
	;   long_error(le, X, Y)
	).

long_error(Comparison, X, Y) :-
	(   nonvar(X), \+rational(X) ->
	    format(user_error,
		'~N! type failure in arg ~w of ~w/~w : rational expected~n',
		[1, Comparison, 2])
	;   nonvar(Y), \+rational(Y) ->
	    format(user_error,
		'~N! type failure in arg ~w of ~w/~w : rational expected~n',
		[2, Comparison, 2])
	;   format(user_error, '~N! instantiation fault in ~w/~w~n',
		[Comparison, 2])
	),
	format(user_error, '! Goal: ~p ~w ~p~n', [X,Comparison,Y]),
	fail.


/*  We now define the "reversible" arithmetic predicates

	succ(X, Y) <-> integer(X) & integer(Y) & X >= 0 & Y = X+1

	plus(X, Y, Z)  <-> rational(X) & rational(Y) & rational(Z)
			&  X+Y = Z

	times(X, Y, Z) <-> rational(X) & rational(Y) & rational(Z)
			&  X*Y = Z

	power(X, Y, Z) <-> rational(X) & rational(Y) & rational(Z)
			&  X**Y = Z


    The general idea is that if there is enough information in a goal
    to detect that it must fail (e.g. succ(X,a)) we fail, if there is
    enough information to determine a unique solution, we yield that
    solution, and otherwise (this can generally only happen when too
    few arguments are instantiated) we report an instantiation fault.
    We report a fault even when the non-determinism is bounded, e.g.
    in times(X, X, 4) there are only two possible solutions.  This is
    because these operations are primitives, that would be coded in
    assembler or micro-code, and we don't want to oblige a compiler
    to generate full frames for them.  

    succ/2 has been hacked so as to be reasonably fast when applied to
    integers.  Making the other two fast for integers is tricky in
    Prolog as we can't catch 32-bit overflow.  Instantiation fault is
    always reported, but type failure is not.
*/

%   succ(P, S) <-> integer(P) & integer(S) & P >= 0 & S = P+1
%   given either of P or S we can solve for the other.
%   If either is neither an integer nor a variable the relation
%   must be false.  But succ(P, S) with both arguments unbound
%   has infinitely many solutions.  (You can generate a bounded
%   range of integers using between/3.)

succ(Pred, Succ) :-
	(   integer(Succ) ->
	    Succ > 0,
	    Pred is Succ-1
	;   integer(Pred), Pred < 8'1777777777 ->
	    Pred >= 0,
	    Succ is Pred+1
	;   nonvar(Pred) ->
	    number(Pred, +, R, [1]),
	    add1(R, L),
	    stdq(L, +, Succ)
	;   nonvar(Succ) ->
	    number(Succ, +, L, [1]),
	    sub1(L, R),
	    stdq(R, +, Pred)
	;   format(user_error,
		'~N! instantiation fault in ~w~n! Goal: ~q~n',
		[succ/2, succ(Pred,Succ)]),
	    fail
	).



%   plus(A, B, S) <-> rational(A) & rational(B) & rational(S) & S = A+B.
%   given any two of the arguments, we can solve for the third.
%   If any argument is neither a rational nor a variable, the relation
%   must be false.  If two are variables and the other is variable or
%   integer, there are infinitely many solutions.

plus(A, B, S) :-
	(   nonvar(A), nonvar(B) -> addq(A, B, X), stdq(X, S)
	;   nonvar(B), nonvar(S) -> subq(S, B, X), stdq(X, A)
	;   nonvar(A), nonvar(S) -> subq(S, A, X), stdq(X, B)
	;   format(user_error,
		'~N! instantiation fault in ~w~n! Goal: ~q~n',
		[plus/3, plus(A,B,S)]),
	    fail
	).



%   times(A, B, P) <-> rational(A) & rational(B) & rational(P) & P = A*B.
%   This is pretty much like plus/3, except that if P is given, and we
%   are to solve for one of A, B, and the other is 0, there are problems.

times(A, B, P) :-
	(   nonvar(A), nonvar(B) ->
		mulq(A, B, X), stdq(X, P)
	;   nonvar(A), nonvar(P), A \== 0 ->
		divq(P, A, X), stdq(X, B)
	;   nonvar(B), nonvar(P), B \== 0 ->
		divq(P, B, X), stdq(X, A)
	;   A == 0, nonvar(P), P \== 0 -> fail
	;   B == 0, nonvar(P), P \== 0 -> fail
	;   format(user_error,
		'~N! instantiation fault in ~w~n! Goal: ~q~n',
		[times/3, times(A,B,P)]),
	    fail
	).


/*  There used to be a low level interface for procedures which want
    to operate directly on pairs of numbers.  That interface was only
    ever used by TIDY.PL, so only three routines were provided:
	add(A, B, C) :- plus(A, B, C).		% eval(C is A+B)
	multiply(A, B, C) :- times(A, B, C).	% eval(C is A*B)
	power(A, N, C)				% eval(C is A^N)
    add/3 and multiply/3 have been subsumed by plus/3 and times/3.
    power/3 tries to be multidirectional too, now.
    power(A, N, C) <-> rational(A) & rational(N) & rational(C) & A^N = C
    Cases:
	to find C: C = A^N
	to find N: N = log(A,C)
	to find A: A = C^1/N
*/

power(A, N, C) :-	% eval(C is A^B).
	(   nonvar(A), nonvar(N) ->
		powq(A, N, X),
		stdq(X, C)
	;   nonvar(A), nonvar(C) ->
		number(A, Sa,Na,Da),	
		number(C, Sc,Nc,Dc),
		logq(number(Sa,Na,Da), number(Sc,Nc,Dc), X),
		stdq(X, N)
	;   nonvar(N), nonvar(C) ->
		invq(N, I),		
		powq(C, I, X),
		stdq(X, A)
	;   format(user_error,
		'~N! instantiation fault in ~w~n! Goal: ~q~n',
		[power/3, power(A,N,C)]),
	    fail
	).


/*  There are four "division" predicates, each having three variants.

	floor(A, B, Q, R)	floor(A, B, Q)	    floor(A, Q)
	ceiling(A, B, Q, R)	ceiling(A, B, Q)    ceiling(A, Q)
	round(A, B, Q, R)	round(A, B, Q)	    round(A, Q)
	truncate(A, B, Q, R)	truncate(A, B, Q)   truncate(A, Q)

    For each of the four predicates in the first column, the other
    two variants are defined thus:
	<p>(A, B, Q) :- <p>(A, B, Q, _).
	<p>(A, Q)    :- <p>(A, 1, Q, _).
    The <p>/2 variant must be called with A instantiated.
    The <p>/3 variant must be called with A and B instantiated.
    The <p>/4 variant must be called with
	A and B instantiated (Q and R will be determined)
    or  B and Q and R instantiated (A will be determined)
    or  A and Q and R instantiated (B will be determined).
    Anything else will provoke an error report.

    All of the predicates have this much in common: they are true when

	rational(A) & proper(A) &
	rational(B) & proper(B) & B =\= 0 &
	whole(Q) &
	rational(R) & proper(R) &
	A =:= B*Q+R &
	abs(R) < abs(B)

    where proper(X) is false of infinity, neginfinity, undefined.
    The difference between the predicates is how Q is calculated.

    floor:	R >= 0
		Q = floor(A/B)

    ceiling:	R =< 0
		Q = ceiling(A/B) = -floor(-A/B)

    round:	abs(R)*2 =< abs(B)

    truncate:	Q = sign(A/B)*floor(abs(A/B))
		sign(R) = sign(A)

    The overwhelming concern in these predicates was correctness.
    Efficiency came a very poor second.  These definitions are to
    be regarded as runnable specifications.  Efficient versions
    may be produced if there is enough demand for them.

    Since the <p>/2 variants can only work one way around anyway,
    they have been extended to accept floating point numbers as their
    first argument.  In the context of a rational arithmetic package,
    we really should be able to accept any floating point number at
    all (floating point numbers being disguised rationals), and if
    the number is too big for an ordinary integer, we ought to return
    a bignum.  What is needed here is a machine-dependent C routine
    float_parts(Float -> Sign, Hi, Lo, Expt)
    and then we could call eval((Hi*65535+Lo)*Sign*2^Expt, A1)
    to obtain the rational equivalent A1 of the float A.  This should
    be used only when the host floating-point arithmetic cannot perform
    the operation or the result could not be expressed as a Prolog
    32-bit integer.  It is not possible to express this in a machine-
    independent manner in C, so we currently put up with whatever the
    float->integer conversion does and accept the fact that the result
    will sometimes be wrong.  The results for rational numbers and
    integers are not affected by this problem.

    We rely here on the fact that "improper" rationals are normalised
    to atoms, so when we check for number(S,N,D) we don't need to test
    whether D=[], because it won't be.
*/

floor(A, Q) :-
	(   integer(A) -> Q = A
	;   float(A) ->
	    T is integer(A),
	    ( A < 0.0, T =\= A -> Q is T-1 ; Q is T )
	;   A = number(S,N,D), atom(S) ->
	    divn(N, D, Q0, R0),
	    (   S = -, R0 \== [] ->
		add1(Q0, Q1)
	    ;   Q1 = Q0
	    ),
	    stdq(Q1, S, Q)
	;   div_error(A, 1, Q, floor(A,Q))
	).

ceiling(A, Q) :-
	(   integer(A) -> Q = A
	;   float(A) ->
	    T is integer(A),
	    ( A > 0.0, T =\= A -> Q is T+1 ; Q is T )
	;   A = number(S,N,D), atom(S) ->
	    divn(N, D, Q0, R0),
	    (   S = +, R0 \== [] ->
		add1(Q0, Q1)
	    ;   Q1 = Q0
	    ),
	    stdq(Q1, S, Q)
	;   div_error(A, 1, Q, ceiling(A,Q))
	).

round(A, Q) :-
	(   integer(A) -> Q = A
	;   float(A) ->
	    ( A >= 0.0 -> Q is integer(A+0.5) ; Q is integer(A-0.5) )
	;   A = number(S,N,D), atom(S) ->
	    divn(N, D, Q0, R0),
	    round1(R0, D, Q0, Q1),
	    stdq(Q1, S, Q)
	;   div_error(A, 1, Q, round(A,Q))
	).

truncate(A, Q) :-
	(   integer(A) -> Q = A
	;   float(A) -> Q is integer(A)
	;   A = number(S,N,D), atom(S) ->
	    divn(N, D, Q0, _),
	    stdq(Q0, S, Q)
	;   div_error(A, 1, Q, truncate(A,Q))
	).


round1(X0, D0, Q0, Q1) :-
	addn(X0, X0, 0, X1),
	comn(X1, D0, =, C),
	(   C = > -> add1(Q0, Q1)
	;   C = < -> Q1 = Q0
	;   Q0 = [X|_], X /\ 1 =:= 1 -> add1(Q0, Q1)
	;   Q1 = Q0
	).


div_error(A, B, Q, Goal) :-
	B \== 0,
	functor(Goal, F, N),
	(   nonvar(Q), \+ whole(Q) ->
	    format(user_error,
		'~N! Type failure in last arg of ~q: whole number expected~n',
		[F/N])
	;   var(A) ->
	    format(user_error, '~N! Instantiation fault in ~q~n', [F/N])
	;   var(B) ->
	    format(user_error, '~N! Instantiation fault in ~q~n', [F/N])
	;   format(user_error,
		'~N! Type failure in of ~q: rational expected~n', [F/N])
	),
	format(user_error, '! Goal: ~q~n', [Goal]),
	fail.


floor(A, B, Q) :-
	(   integer(A), integer(B) ->
	    (   B < 0 -> A1 is -A, B1 is -B
	    ;   B > 0 -> A1 is  A, B1 is  B
	    ),
	    X1 is A1 mod B1,
	    (   X1 < 0 -> Q is (A1 // B1) - 1
	    ;   Q is A1 // B1
	    )
	;   div_parts(A, B, S, Q0, X, _) ->
	    (   S = -, X \== [] -> add1(Q0, Q1)
	    ;   Q1 = Q0
	    ),
	    stdq(Q1, S, Q)
	;   div_error(A, B, Q, floor(A,B,Q))
	).

ceiling(A, B, Q) :-
	(   integer(A), integer(B) ->
	    (   B < 0 -> A1 is -A, B1 is -B
	    ;   B > 0 -> A1 is  A, B1 is  B
	    ),
	    X1 is A1 mod B1,
	    (   X1 > 0 -> Q is (A1 // B1) + 1
	    ;   Q is A1 // B1
	    )
	;   div_parts(A, B, S, Q0, X, _) ->
	    (   S = +, X \== [] -> add1(Q0, Q1)
	    ;   Q1 = Q0
	    ),
	    stdq(Q1, S, Q)
	;   div_error(A, B, Q, ceiling(A,B,Q))
	).

round(A, B, Q) :-
	(   integer(A), integer(B) ->
	    (   B < 0 -> A1 is -A, B1 is -B
	    ;   B > 0 -> A1 is  A, B1 is  B
	    ),
	    Q1 is A1//B1,
	    X1 is (A1 mod B1) << 1,
	    (   X1 >= B1   -> Q is Q1+1
	    ;   X1+B1 =< 0 -> Q is Q1-1
	    ; 		      Q is Q1
	    )
	;   div_parts(A, B, S, Q0, R0, D0) ->
	    round1(R0, D0, Q0, Q1),
	    stdq(Q1, S, Q)
	;   div_error(A, B, Q, round(A,B,Q))
	).

truncate(A, B, Q) :-
	(   integer(A), integer(B) ->
	    (   B < 0 -> A1 is -A, B1 is -B
	    ;   B > 0 -> A1 is  A, B1 is  B
	    ),
	    Q is A1//B1
	;   div_parts(A, B, S, Q0, _, _) ->
	    stdq(Q0, S, Q)
	;   div_error(A, B, Q, truncate(A,B,Q))
	).


%   div_parts(A, B, S, Q, X, D)
%   is true when A and B are rational numbers, B is not 0,
%   and A/B = S*(Q+X/D) where 0 =< X < D.

div_parts(A, B, S, Q, X, D) :-
	proper_number(A, Sa, Na, Da),
	proper_number(B, Sb, Nb, Db),
	Nb = [_|_],			% B is not zero.
	sign(Sa, Sb, S),
	gcdn(Na, Nb, _, Na1, Nb1),	% Na/Nb = Na1/Nb1
	gcdn(Da, Db, _, Da1, Db1),	% Da/DB = Da1/Db1
	muln(Na1, Db1, Nc),		% Nc = Na1*Db1 = K*(Na*Db)
	muln(Da1, Nb1, Dc),		% Dc = Da1*Nb1 = K*(Da*Nb)
	divn(Nc, Dc, Q, Xc),		% Nc = Q*Dc+Xc
	gcdn(Xc, Dc, _, X, D).		% Xc/Dc = X/D.

remainder(Sa, Na, Da, B, X) :-	% a version of mulq, DRAT>
	proper_number(B, Sb, Nb, Db),
	sign(Sa, Sb, Sc),
	gcdn(Na, Db, _, Na1, Db1),
	gcdn(Da, Nb, _, Da1, Nb1),
	muln(Na1, Nb1, Nc),
	muln(Da1, Db1, Dc),
	stdq(Dc, Nc, Sc, X).


floor(A, B, Q, X) :-
	(   integer(A), integer(B) ->
	    (   B < 0 -> A1 is -A, B1 is -B
	    ;   B > 0 -> A1 is  A, B1 is  B
	    ),
	    X1 is A1 mod B1,
	    (   X1 < 0 -> Q is (A1//B1)-1 ; Q is A1//B1),
	    X is (-Q)*B+A
	;   div_patch(A, B, Q, X),
	    div_parts(A, B, S, Q0, X0, D) ->
	    (   S = -, X0 \== [] ->
		add1(Q0, Q1),
		subp(D, X0, X1)
	    ;   Q1 = Q0, X1 = X0
	    ),
	    remainder(+, X1, D, B, X),
	    stdq(Q1, S, Q)
	;   div_error(A, B, Q, floor(A,B,Q,X))
	).

ceiling(A, B, Q, X) :-
	(   integer(A), integer(B) ->
	    (   B < 0 -> A1 is -A, B1 is -B
	    ;   B > 0 -> A1 is  A, B1 is  B
	    ),
	    X1 is A1 mod B1,
	    (   X1 > 0 -> Q is (A1//B1)+1 ; Q is A1//B1   ),
	    X is (-Q)*B+A
	;   div_patch(A, B, Q, X),
	    div_parts(A, B, S, Q0, X0, D) ->
	    (   S = +, X0 \== [] ->
		add1(Q0, Q1),
		subp(D, X0, X1)
	    ;   Q1 = Q0, X1 = X0
	    ),
	    remainder(-, X1, D, B, X),
	    stdq(Q1, S, Q)
	;   div_error(A, B, Q, ceiling(A,B,Q,X))
	).

round(A, B, Q, X) :-
	(   integer(A), integer(B) ->
	    (   B < 0 -> A1 is -A, B1 is -B
	    ;   B > 0 -> A1 is  A, B1 is  B
	    ),
	    Q1 is A1//B1,
	    X1 is (A1 mod B1) << 1,
	    (   X1 >= B1   -> Q is Q1+1
	    ;   X1+B1 =< 0 -> Q is Q1-1
	    ; 		      Q is Q1
	    ),
	    X is (-Q)*B+A
	;   div_patch(A, B, Q, X),
	    div_parts(A, B, S, Q0, X0, D0) ->
	    round1(X0, D0, Q0, Q1),
	    (   Q0 = Q1 -> X1 = X0, S1 = S
	    ;   subp(D0, X0, X1),  sign(-, S, S1)
	    ),
	    remainder(S1, X1, D0, B, X),
	    stdq(Q1, S, Q)
	;   div_error(A, B, Q, round(A,B,Q,X))
	).

truncate(A, B, Q, X) :-
	(   integer(A), integer(B) ->
	    B =\= 0,
	    Q is A//B, X is A mod B
	;   div_patch(A, B, Q, X),
	    div_parts(A, B, S, Q0, X0, D) ->
	    remainder(S, X0, D, B, X),
	    stdq(Q0, S, Q)
	;   div_error(A, B, Q, truncate(A,B,Q,X))
	).


%   div_patch(A, B, Q, X)
%   lets us make the division/4 predicates reversible.
%   If A or B is a variable, it is filled in from the other
%   arguments.  On the assumption that the reverse uses are
%   not as important as the forward uses, and to get this
%   thing ready in time for shipment, I'm using eva2/2 to do
%   the arithmetic.

div_patch(A, B, Q, X) :-
	(   var(A) -> eva2(B*Q+X, A)
	;   var(B) -> eva2((A-X)/Q, B)
	;   true
	).

/*----------------------------------------------------------------------
%   Some of the test code for the division/4 routines:

:- ensure_loaded(library(call)).
:- ensure_loaded(library(addportray)).

:- add_portray(portray_number).

t(X) :-
	nl, write('Testing '), write(X), nl,
	ab(A, B),
	call(X, A, B, Q, R),
	print(A=B*Q+R), put(9),
	call(X, U, B, Q, R),
	print(U=B*Q+R), put(9),
	call(X, A, V, Q, R),
	print(A=V*Q+R), nl,
	fail.

s(X) :-
	T =.. [X,A,B],
	ab(A, B),
	call(X, A, B, Q),
	print(T=Q), nl, fail
    ;   nl,
	ab(A, B),
	call(X, A, B, Q, R),
	print(A=B*Q+R), nl,
	fail.
	
ab(A, B) :-
	abs_ab(AA, BB),
	(  eval(AA, A) ; eval(-AA, A) ),
	(  eval(BB, B) ; eval(-BB, B) ).

abs_ab(13, 5).
abs_ab(13/3, 5/3).
abs_ab(21, 4).
abs_ab(21/4, 1).

:- t(floor) ; t(ceiling) ; t(round) ; t(truncate).

----------------------------------------------------------------------*/
