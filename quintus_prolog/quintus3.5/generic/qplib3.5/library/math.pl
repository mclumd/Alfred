%   Module : math
%   Authors: Evan Tick + Richard A. O'Keefe
%   Updated: 04/15/99
%   Purpose: Interface to Unix Math library

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(math, [
	exp/2,
	log/2,
	log10/2,
	pow/3,
	sqrt/2,
	hypot/3,
	abs/2,		fabs/2,
	j0/2,		j1/2,		jn/3,
	y0/2,		y1/2,		yn/3,
	sin/2,		asin/2,		sinh/2,		asinh/2,
	cos/2,		acos/2,		cosh/2,		acosh/2,
	tan/2,		atan/2,		tanh/2,		atanh/2,
	atan2/3,
	max/3,			%  This is defined here.
	min/3,			%  This is defined here.
	sign/2,		sign/3,		scale/3,	decode_float/4,
	floor/2,	floor/3,	ffloor/2,	ffloor/3,
	truncate/2,	truncate/3,	ftruncate/2,	ftruncate/3,
	ceiling/2,	ceiling/3,	fceiling/2,	fceiling/3,
	round/2,	round/3,	fround/2,	fround/3,
	fremainder/3,

	ceil/2,			% BACKWARDS COMPATIBILITY ONLY
	cabs/2			% BACKWARDS COMPATIBILITY ONLY
   ]).


/*  library(math) started as a tiny little demo, showing how you could
    pull in the Unix math(3m) library.  Then we ported the system to
    the Xerox Lisp machines, added a couple of functions, wrote some
    missing inverses, moved the new stuff back to the Sun, and it sort
    of grew from there.  The nasty thing is that when you do
	:- compile(library(math)).
    it uses about 81k of memory in SunOS 3.5.  Sorry about that, but it
    really isn't our fault:  math.o takes about 3.6k, and math.pl is
    about the same size.  It turns out that a program which has no
    code of its own but pulls in all of the functions that we pull in
    from the Unix math library is also about 80k.  That's how big the
    SunOS 3.5 math library is.
*/

sccs_id('"@(#)99/04/15 math.pl    76.1"').


max(X, Y, Max) :-
	(   X < Y -> Max is Y ; Max is X   ).

min(X, Y, Min) :-
	(   Y < X -> Min is Y ; Min is X   ).


%   sign(+Y, ?Sign)
%   is true when Y and Sign are numbers of the same type,
%   and either Sign = |Y| = 0 or Sign = Y/|Y| (+ or - 1).

sign(X, Sign) :-
	(   X > 0 -> ( integer(X) -> Sign =  1 ; Sign =  1.0 )
	;   X < 0 -> ( integer(X) -> Sign = -1 ; Sign = -1.0 )
	;/* X = 0 */                 Sign =  X
	).

%   sign(+X, +Y, X_with_sign_of_Y)
%   is true when X and X_with_sign_of_Y are numbers of the same type,
%   |X| = |X_with&c|, and X_with&c has the same sign as Y.  We have
%   to be careful to handle -0.0 correctly.

sign(X, Y, AbsX_SignY) :-
	(   float(X) -> copysign(X, Y, AbsX_SignY)
	;   integer(X) -> copysign(1.0, Y, Sign),
	    (   X*Sign >= 0 -> AbsX_SignY is X ; AbsX_SignY is -X   )
	;   should_be(number, sign(X,Y,AbsX_SignY))
	).


abs(Number, Absolute) :-	%  like fabs/2, but integer->integer
	(   Number >= 0 -> Absolute is  Number
	; 		   Absolute is -Number
	).

pow(Base, Power, Result) :-
	(   integer(Power) -> qp_pow(Base, Power, Result)
	;   float(Power)   -> cl_pow(Base, Power, Result)
	).


/*  scale(+X, +N, ?Y)
    is true when X and Y are floating-point numbers of the same type.
    N is an integer, and Y = X*2^N.  It can only be used to solve
    for Y.  I originally wanted it to solve for any of its arguments, but
    in IEEE 754 arithmetic it is not necessarily an exact operation.
    (If X and N are such that X is not subnormal but Y is, some information
    will have been lost.)  What happens on overflow or underflow?  For the
    moment we let C's ldexp() determine that.  On a Sun-3,
	if X =:= 0, or X is an infinity or NaN, Y = X.
	on overflow, Y = sign(infinity, X).
	on underflow, Y = sign(0.0, X).
    We use ldexp() even when scalb() is provided, because the only difference
    then is that ldexp() sets errno and scalb() doesn't.
*/

/*  [f]floor(X, I[, F])

    The floor of a number X, |_X_|, is the largest integer not greater
    than X.  In these four predicates, X is the number whose floor is
    to be taken, I is the integer part, and F, if present, is the fraction
    part.  X = I+F and I = floor(X).

    [f]floor(+X, ?I) will find I given X.  It cannot solve for X.
    [f]floor(?X, ?I, ?F) will find I and F given X, or X given I and F.
    Unlike most floating-point operations, this one is exact.

    The floor/[2,3] predicates return I as an integer.  This is not always
    possible, and when it isn't, they report a representation fault.
    The ffloor/[2,3] predicates return I as a float.  This *IS* always
    possible.
*/

%   floor(+X, ?I)
%   is true when X is a number, I is an integer, and I = floor(X).

floor(X, I) :-
    (	'QIconv'(-1, X, I, 1) -> true
    ;	number(X), var(I) ->
	representation_fault(2, floor(X,I), ffloor(X,I))
    ).


%   floor(X, I, F)
%   is true when X and F are the same kind of number, I is an integer,
%   X = I+F, and I = floor(X).

floor(X, I, F) :-
	(   float(X) ->
	    (   'QIpart'(-1, X, I, F, 1) -> true
	    ;   var(I), var(F) ->
		representation_fault(2, floor(X,I,F), ffloor(X,I,F))
	    )
	;   integer(X) ->
	    I = X, F = 0
	;   var(X) ->
	    integer(I),
	    'QFjoin'(-1, X, I, F, 1)
	;   should_be(number, floor(X,I,F))
	).


%   ffloor(+X, ?I)
%   is true when X and I are both floats and I represents floor(X).

ffloor(X, I) :-
	'QFconv'(-1, X, I).


%   ffloor(X, I, F)
%   is true when X, I, and F are all floating-point numbers, X = I+F,
%   and I represents the integer floor(X).

ffloor(X, I, F) :-
	(   float(X) ->
	    'QFpart'(-1, X, I, F)
	;   var(X) ->
	    'QFjoin'(-1, X, I, F, 1)
	;   should_be(float, ffloor(X,I,F))
	).



/*  [f]truncate(X, I[, F])

    The truncation of a number X is an integer with the same sign as X
    such that |I| <= |X| whose absolute value is as large as possible.
    If X >= 0, it is the same as the floor.
    If X =< 0, it is the same as the ceiling.
    In these four predicates, X is the number which is to be truncated,
    I is the integer part, and F, if present, is the fraction part.
    X = I+F and I = truncate(X).

    [f]truncate(+X, ?I) will find I given X.  It cannot solve for X.
    [f]truncate(?X, ?I, ?F) will find I and F given X, or X given I and F.
    Unlike most floating-point operations, this one is exact.

    The truncate/[2,3] predicates return I as an integer.  This is not always
    possible, and when it isn't, they report a representation fault.
    The ftruncate/[2,3] predicates return I as a float.  This *IS* always
    possible.
*/

%   truncate(+X, ?I)
%   is true when X is a number, I is an integer, and I = truncate(X).

truncate(X, I) :-
    (	'QIconv'(0, X, I, 1) -> true
    ;	number(X), var(I) ->
	representation_fault(2, truncate(X,I), ftruncate(X,I))
    ).


%   truncate(X, I, F)
%   is true when X and F are the same kind of number, I is an integer,
%   X = I+F, and I = truncate(X).

truncate(X, I, F) :-
	(   float(X) ->
	    (   'QIpart'(0, X, I, F, 1) -> true
	    ;   var(I), var(F) ->
		representation_fault(2, truncate(X,I,F), ftruncate(X,I,F))
	    )
	;   integer(X) ->
	    I = X, F = 0
	;   var(X) ->
	    integer(I),
	    'QFjoin'(0, X, I, F, 1)
	;   should_be(number, truncate(X,I,F))
	).


%   ftruncate(+X, ?I)
%   is true when X and I are both floats and I represents truncate(X).

ftruncate(X, I) :-
	'QFconv'(0, X, I).


%   ftruncate(X, I, F)
%   is true when X, I, and F are all floating-point numbers, X = I+F,
%   and I represents the integer truncate(X).

ftruncate(X, I, F) :-
	(   float(X) ->
	    'QFpart'(0, X, I, F)
	;   var(X) ->
	    'QFjoin'(0, X, I, F, 1)
	;   should_be(float, ftruncate(X,I,F))
	).



/*  [f]ceiling(X, I[, F])
				_ _
    The ceiling of a number X, | X |, is the smallest integer not less
    than X.  In these four predicates, X is the number whose ceiling is
    to be taken, I is the integer part, and F, if present, is the fraction
    part.  X = I+F and I = ceiling(X).

    [f]ceiling(+X, ?I) will find I given X.  It cannot solve for X.
    [f]ceiling(?X, ?I, ?F) will find I and F given X, or X given I and F.
    Unlike most floating-point operations, this one is exact.

    The ceiling/[2,3] predicates return I as an integer.  This is not always
    possible, and when it isn't, they report a representation fault.
    The fceiling/[2,3] predicates return I as a float.  This *IS* always
    possible.
*/

%   ceiling(+X, ?I)
%   is true when X is a number, I is an integer, and I = ceiling(X).

ceiling(X, I) :-
    (	'QIconv'(1, X, I, 1) -> true
    ;	number(X), var(I) ->
	representation_fault(2, ceiling(X,I), fceiling(X,I))
    ).


%   ceiling(X, I, F)
%   is true when X and F are the same kind of number, I is an integer,
%   X = I+F, and I = ceiling(X).

ceiling(X, I, F) :-
	(   float(X) ->
	    (   'QIpart'(1, X, I, F, 1) -> true
	    ;   var(I), var(F) ->
		representation_fault(2, ceiling(X,I,F), fceiling(X,I,F))
	    )
	;   integer(X) ->
	    I = X, F = 0
	;   var(X) ->
	    integer(I),
	    'QFjoin'(1, X, I, F, 1)
	;   should_be(number, ceiling(X,I,F))
	).


%   fceiling(+X, ?I)
%   is true when X and I are both floats and I represents ceiling(X).

fceiling(X, I) :-
	'QFconv'(1, X, I).


%   fceiling(X, I, F)
%   is true when X, I, and F are all floating-point numbers, X = I+F,
%   and I represents the integer ceiling(X).

fceiling(X, I, F) :-
	(   float(X) ->
	    'QFpart'(1, X, I, F)
	;   var(X) ->
	    'QFjoin'(1, X, I, F, 1)
	;   should_be(float, fceiling(X,I,F))
	).



/*  [f]round(X, I[, F])

    To round a number X, one finds an integer I minimising |X-I|.
    That is, no integer is closer to X than I.  This definition pins
    I down except when X is <some integer> + (1/2).  The rule then is
    that I should be *even*, thus round(0.5) = 0, round(1.5) = 2.
    round(X) = ceiling(X+0.5) - (if (2X+1)/4 is an integer than 0 else 1).
    
    The truncation of a number X is an integer with the same sign as X
    such that |I| <= |X| whose absolute value is as large as possible.
    If X >= 0, it is the same as the floor.
    If X =< 0, it is the same as the ceiling.
    In these four predicates, X is the number which is to be rounded,
    I is the integer part, and F, if present, is the fraction part.
    X = I+F and I = round(X).

    [f]round(+X, ?I) will find I given X.  It cannot solve for X.
    [f]round(?X, ?I, ?F) will find I and F given X, or X given I and F.
    Unlike most floating-point operations, this one is exact.

    The round/[2,3] predicates return I as an integer.  This is not always
    possible, and when it isn't, they report a representation fault.
    The fround/[2,3] predicates return I as a float.  This *IS* always
    possible.
*/

%   round(+X, ?I)
%   is true when X is a number, I is an integer, and I = round(X).

round(X, I) :-
    (	'QIconv'(2, X, I, 1) -> true
    ;	number(X), var(I) ->
	representation_fault(2, round(X,I), fround(X,I))
    ).


%   round(X, I, F)
%   is true when X and F are the same kind of number, I is an integer,
%   X = I+F, and I = round(X).

round(X, I, F) :-
	(   float(X) ->
	    (   'QIpart'(2, X, I, F, 1) -> true
	    ;   var(I), var(F) ->
		representation_fault(2, round(X,I,F), fround(X,I,F))
	    )
	;   integer(X) ->
	    I = X, F = 0
	;   var(X) ->
	    integer(I),
	    'QFjoin'(2, X, I, F, 1)
	;   should_be(number, round(X,I,F))
	).


%   fround(+X, ?I)
%   is true when X and I are both floats and I represents round(X).

fround(X, I) :-
	'QFconv'(2, X, I).



%   fround(X, I, F)
%   is true when X, I, and F are all floating-point numbers, X = I+F,
%   and I represents the integer round(X).

fround(X, I, F) :-
	(   float(X) ->
	    'QFpart'(2, X, I, F)
	;   var(X) ->
	    'QFjoin'(2, X, I, F, 1)
	;   should_be(float, fround(X,I,F))
	).


%   decode_float(?Number, ?Sign, ?Significand, ?Exponent)
%   is true when Number and Significand are the same kind of float,
%   Sign and Exponent are integers, Sign = +1 or Sign = -1, and
%   abs(Number) = Significand = 0.0 and Exponent = 0 or
%   abs(Number) = Sign x Significand x 2.0**Exponent.

decode_float(Number, Sign, Significand, Exponent) :-
	(   float(Number) ->
	    'QFdecd'(Number, Sign, Significand, Exponent)
	;   var(Number) ->
	    'QFencd'(X, Sign, Significand, Exponent, Status),
	    (	Status =:= 1 -> Number = X
	    ;	Status =:= 2 ->
		representation_fault(1,
		    decode_float(Number,Sign,Significand,Exponent), 0)
	    )
	;   should_be(float, decode_float(Number,Sign,Significand,Exponent))
	).



%.  representation_fault(ArgNo, Goal, Alternative)
%   reports that Goal has a solution which the system is unable to
%   construct, and suggests an Alternative goal.

representation_fault(ArgNo, Goal, Alternative) :-
	functor(Goal, Symbol, Arity),
	format(user_error,
	    '~N! Argument ~w of ~w/~w cannot be constructed.~n',
	    [ArgNo, Symbol, Arity]),
	format(user_error, '! Goal: ~q~n', [Goal]),
	(   integer(Alternative) -> true
	;   format(user_error, '! Try instead: ~q~n', [Alternative])
	),
	fail.


%.  should_be(Type, Goal)
%   reports that the first argument of Goal is not of the right type.

should_be(Type, Goal) :-
	functor(Goal, Symbol, Arity),
	arg(1, Goal, X),
        format(user_error,
	    '~N! Type ~w in argument ~w of ~w/~w~n',
	    [failure, 1, Symbol, Arity]),
	format(user_error,
	    '! ~w expected, but found ~q~n! Goal: ~q~n',
	    [Type, X, Goal]),
	fail.


/*  This package is moving towards full support.
    An earlier release exported the C functions floor() and ceil() under
    those names; in this release floor/2 returns an integer, not a float,
    and ceil/2 was to have been dropped.  For the benefit of old code that
    used to use ceil/2, it is retained as an alias for fceiling/2.
    Similarly, cabs() was always bogus.  It has been dropped from the ANSI C
    standard, and was to have been dropped from this release of library(math).
    However, it is retained for the benefit of old code.
    In the next major release of Quintus Prolog, we intend to split this
    package into several smaller modules, most of which will be fully
    supported.  library(math) will remain as an unsupported "wrapper" which
    includes and re-exports all the smaller modules.  There will be no
    changes to the interface of library(math) in that release.
    To repeat:  ceil/2 and cabs/2 are not and will not be supported, but
    they're still here.
*/
ceil(X, Y) :-
	fceiling(X, Y).

cabs(complex(X,Y), Z) :-
	hypot(X, Y, Z).

foreign_file(library(system(libplm)),
    [
	exp,
	log,
	log10,
	pow,
	sqrt,
	fabs,
	hypot,
	j0,
	j1,
	jn,
	y0,
	y1,
	yn,
	sin,
	cos,
	tan,
	asin,
	acos,
	atan,
	atan2,
	sinh,
	cosh,
	tanh,
	asinh,
	acosh,
	atanh,
	qp_pow,
	ldexp,
	copysign,
	'QIconv',	% QIconv(+Method, +X, -I) -> Status
	'QIpart',	% QIpart(+Method, +X, -I, -F) -> Status
	'QFconv',	% QFconv(+Method, +X) -> I
	'QFpart',	% QFpart(+Method, +X, -I, -F)
	'QFjoin',	% QFjoin(+Method, -X, +I, +F) -> Status
	'QFdecd',	% QFdecd(+Num, -Sign, -Frac, -Expt)
	'QFencd',	% QFencd(-Num, +Sign, +Frac, +Expt) -> Status
	'QFrmdr'	% QFrmdr(+X, +Y, -X_REM_Y)
    ]).


/* ----------------------------------------------------------------------
     Declare Prolog predicate names and arguments for each C function
   ---------------------------------------------------------------------- */

foreign(exp,		exp(	 +double,[-double])).	
foreign(log,		log(	 +double,[-double])).
foreign(log10,		log10(	 +double,[-double])).
foreign(pow,		cl_pow(	 +double,+double,[-double])).
foreign(qp_pow, 	qp_pow(	 +double,+integer,[-double])).
foreign(sqrt,		sqrt(	 +double,[-double])).
foreign(fabs,		fabs(	 +double,[-double])).
foreign(hypot,		hypot(	 +double,+double,[-double])).
foreign(j0,		j0(	 +double,[-double])).
foreign(j1,		j1(	 +double,[-double])).
foreign(jn,		jn(	 +integer,+double,[-double])).
foreign(y0,		y0(	 +double,[-double])).
foreign(y1,		y1(	 +double,[-double])).
foreign(yn,		yn(	 +integer,+double,[-double])).
foreign(sin,		sin(	 +double,[-double])).
foreign(tan,		tan(	 +double,[-double])).
foreign(cos,		cos(	 +double,[-double])).
foreign(asin,		asin(	 +double,[-double])).
foreign(acos,		acos(	 +double,[-double])).
foreign(atan,		atan(	 +double,[-double])).
foreign(atan2,		atan2(	 +double,+double,[-double])).
foreign(sinh,		sinh(	 +double,[-double])).
foreign(cosh,		cosh(	 +double,[-double])).
foreign(tanh,		tanh(	 +double,[-double])).
foreign(asinh,		asinh(	 +double,[-double])).
foreign(acosh,		acosh(	 +double,[-double])).
foreign(atanh,		atanh(	 +double,[-double])).
foreign(ldexp,		scale(	 +double,+integer,[-double])).
foreign(copysign,	copysign(+double,+double,[-double])).
foreign('QFrmdr',	fremainder(+double,+double,[-double])).
foreign('QIconv',	'QIconv'(+integer,+double,-integer,[-integer])).
foreign('QIpart',	'QIpart'(+integer,+double,-integer,-double,[-integer])).
foreign('QFconv',	'QFconv'(+integer,+double,[-double])).
foreign('QFpart',	'QFpart'(+integer,+double,-double,-double)).
foreign('QFjoin',	'QFjoin'(+integer,-double,+double,+double,[-integer])).
foreign('QFdecd',	'QFdecd'(+double,-integer,-double,-integer)).
foreign('QFencd',	'QFencd'(-double,+integer,+double,+integer,[-integer])).

:- load_foreign_executable(library(system(libplm))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).


