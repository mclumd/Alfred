/*  File   : math.c
    Authors: Evan Tick + Richard A. O'Keefe
    Updated: 04/15/99
    Defines: Interface to Unix Math library

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    The math library is supplied with your Unix system.  It contains a
    number of common mathmetical (mostly transcendental) functions.
    We have added qp_pow(x, n) for calculating x**n when n is integral.
    This saves an integer->float coercion and a fair chunk of
    fiddling around while pow(3m) works out that its second argument
    used to be an integer.  This saving is worth having on workstations
    without floating point hardware, and never does any harm.  For some
    strange reason, the UNIX C library includes trig and arc-trig
    functions, and hyperbolic trig functions, but no arc-hyperbolic trig
    functions.  This is a pity, as it is tricky to get them right.  The
    code here is neither certified nor supported.

    ---------------------------------------------------------------------- */
   
#ifndef	lint
static	char SCCSid[] = "@(#)99/04/15 math.c	76.3";
#endif/*lint*/

#ifdef WIN32
#define __STDC__ 1      /* for broken "math.h" */
#endif

/* [PM] 3.5 Do not do this for HPUX. HPUX has drem()/remainder() (and
   the static round conflicts with C9X round()) */
#if SVR4 || ( HPUX && 0 )
#define NODREM		1
#endif

#include "quintus.h"		/* get integer limits */
#include <math.h>		/* include math library definitions */
#include <float.h>             /* [PM] 3.5 STDC DBL_MAX */
#include <errno.h>

#if SUNOS4

/*  These are the routines in libm.a referenced directly from Prolog.
    We include them in a stub here in order to construct a shared object
    file which includes all the necessary object files from libm.a. This
    is needed only because there is no libm.so.* file to load dynamically.
*/
extern	double	exp(), fabs(), log10(), pow(), gamma(), hypot(),
		j0(), j1(), jn(), y0(), y1(), yn(), sin(), tan(), cos(),
		asin(), acos(), atan(), atan2(), sinh(), cosh(), tanh();

static double	(*(stub[]))() = {
	exp, fabs, log10, pow, gamma, hypot, j0, j1, jn, y0, y1, yn,
	sin, cos, tan, asin, acos, atan, atan2, sinh, cosh, tanh,
};
 
#elif WIN32

  double j0(double x) { return _j0(x); }
  double j1(double x) { return _j1(x); }
  double jn(int n, double x) { return _jn(n,x); }
  double y0(double x) { return _y0(x); }
  double y1(double x) { return _y1(x); }
  double yn(int n, double x) { return _yn(n,x); }
  double hypot(double x, double y) { return _hypot(x,y); }

#endif


/*  From here on is the work of Richard A. O'Keefe.
    Note that Quintus are not a supplier of mathematical software:
    the routines provided here are not supported, and while they
    have been tested, Quintus make no claim that they are any good
    for anything at all.  There are some magic numbers, which have
    been chosen to suit a purported implementation of IEEE-754
    double-precision arithmetic.  The greatest source of error in
    this package is thought to be the truncation which takes place
    when floating-point numbers are represented as Prolog terms,
    but we repeat that you should really get routines like this
    from your C or Fortran vendor, or from a library such as NAG
    or IMSL or FUNPACK.  The only precautions which have been
    taken are precautions against overflow and underflow, and even
    that isn't guaranteed either.  This is not supported code!
*/

double qp_pow(x, n)		/* Calculates x**n efficiently for integer */
    double x;			/* values of n.  The C library function is */
    int n;			/* smart enough to do this, but it takes a */
    {				/* while to discover that this is what to do */
	double a;		/* invariant: a*x**n = x0**n0.   R.A.O'Keefe */

	if (n < 0) x = 1.0/x, n = -n;
	if (n == 0) return 1.0;
	while (!(n&1)) x *= x, n >>= 1;
	for (a = x; --n > 0; a *= x)
	    while (!(n&1)) x *= x, n >>= 1;
	return a;
    }


/*  M_LN2 is supposed to be defined in <math.h> as the natural
    logarithm of 2 to machine precision; the alternative definition
    here was taken from Abramowitz & Stegun, page 2.
*/
#ifndef	M_LN2
#define M_LN2 0.6931471805599453094172321
#endif/*M_LN2*/

/*  It is often possible to compute log(1+x) more accurately as log1p(x)
    (for small values of x, adding 1+x loses a lot of the information in
    x, which log1p(x) can preserve).  However, log1p() is not universally
    available.  If you have it, put
	-DLOG1P=log1p
    in the CFLAGS of the makefile in this directory.  If you haven't,
    don't worry, we'll just use log().
*/

#ifdef	LOG1P
extern	double	LOG1P(/* double */);
#else
#define	LOG1P(x) log((x)+1.0)
#endif

#ifdef WIN32
/* [PM] 3.5 FIXME: Should we use DBL_MAX as below? */
#define HUGE HUGE_VAL
#endif

#ifndef HUGE
/* [PM] 3.5 HPUX 11.00 does not have HUGE. May as well make this
   general synonym.

   FIXME: What is the right value?
   
   The RH 9 (glibc) math.h define HUGE as the same value as FLT_MAX
   wherease HUGE_VAL is +Infinity (as to the Solaris matherr(3M) man
   page in the section SVID3 standard conformance, so it is probably
   correct). I do not know what it used to be in HPUX, running HPUX QP
   3.4 and calling atanh(2.0, X) gives X close to DBL_MAX (which makes
   more sense than FLT_MAX since it is used in double float contexts).

*/
#define HUGE DBL_MAX
#endif

/*  The formula being used here is
	arc sinh (z) = log (z+sqrt (1+z*z))
    The reason for the four cases is to avoid overflow
    and underflow.  I assume that at most 18 decimal
    digits are available in a double.

    Note that sinh (x) -> z has (-oo,+oo) as range, so
    arc sinh (z) -> x accepts any x.
*/

double asinh(z)
    double z;
    {
	int neg = 0;

	if (z < 0) neg++, z = -z;
	if (z >= 1.0) {
	    if (z >= 1.0e9) {
		z = log(z)+M_LN2;
	    } else {
		z = LOG1P(sqrt(1.0/(z*z)+1.0)) + log(z);
	    }
	} else {
	    if (z < 1.0e-5) {
		double t = z*z;
		z *= 1.0 - t*((1.0)/(6.0) - 0.075*t);
	    } else {
		z = log(sqrt(z*z+1.0)+z);
	    }
	}
	return neg ? -z : z;
    }


/*  The formula being used here is
	arc cosh (z) = log (z + sqrt (z*z-1))
    Since cosh (x) -> z has [1.0,+oo) as its range, we need
    only accept such numbers as inputs.  Strictly, arc cosh (z)
    and -arc cosh (z) would both do, but it is conventional to
    return the positive value only.  So a negative result is
    used to signal a bad argument.

    The trick is to observe that z**2 - 1 = (z-1)(z+1) so that
    if a = sqrt(z-1), b = sqrt(z+1), then sqrt(z**2 - 1) = ab,
    then we could eliminate z in favour of a or b by doing
	z = (z-1)+1 = a**2 + 1, acosh = log(a.b + a.a + 1)
    or	z = (z+1)-1 = b**2 - 1, acosh = log(a.b + b.b - 1)
    But we note that it may be possible to compute log(x+1) more
    precisely as log1p(x) -- if you have log1p -- so we pick the
    first alternative.  I tried a special formula for small values
    of a: sqrt(2*(z-1)) is then a good approximation, but it did
    not produce any improvement, so I kept this version.
*/
double acosh(z)
    double z;
    {
	if (z < 1.0) return -1.0;
	if (z >= 1.0e9) {
	    return log(z)+M_LN2;
	} else {
	    double a = sqrt(z-1.0);
	    return LOG1P((sqrt(z+1.0)+a)*a);
	}
    }


/*  The formula being used here is
	arc tanh (z) = -0.5*log (1-z)/(1+z)
    Since tanh (x) -> z has (-1.0,1.0) as its range, we need only
    accept such numbers as inputs.  However, tanh(x) is indistinguishable
    from 1.0 for x >= 20 (say), we can report bad inputs by returning
    x = +/-HUGE as the result.  The magic numbers here were determined
    by experiment on something which claimed to be an implementation of
    the IEEE-754 floating-point standard.  The parameters were determined
    with reference to C "double" arithmetic, NOT with respect to Prolog
    floating point.  This code has been compared with a commercial
    implementation and seems to be usable.  Remember, it's free!
*/
double atanh(z)
    double z;
    {
	int neg = 0;

	if (z < 0) neg++, z = -z;
	if (z <= 5.0e-3) {
	    if (z > 1.0e-8) {
		double t = z*z;
		z *= ((t*0.2 + 1.0/3.0)*t + 1.0);
	    } else {
		/* the multiplier is not distinguishable from 1 */
	    }
	} else
	if (z >= 1.0) {          
	    z = HUGE;  
	} else {
	    z = (1.0-z)/(1.0+z);
	    z = z == 0.0 ? HUGE : log(z)*(-0.5);
	}
	return neg ? -z : z;
    }


/*  Portability note.
    We use the following Unix-provided functions:
	floor(x)		|_ x _|
	ceil(x)			-floor(-x)
	drem(x, y)		x - y*round(x/y)
	modf(x, &i)		i = trunc(x), x-i
    floor() and ceil() are generally available.  modf() is required in
    Unix System V, and present in 4.2BSD, except that the 4.2BSD manual
    has a different description for it.  There is some reason to believe
    that some 4.2BSD-related versions of Unix may follow the 4.2 manual
    rather than the code, so modf() needs to be checked carefully.
    drem() is an IEEE-754 function which we want to use if we possibly can.
    If you do not have drem(), compile this with -DNODREM

    We could have implemented ffloor/2 as a direct call to floor() and
    fceiling/2 as a direct call to ceiling(); this was not done so that
    all the system dependencies could be concentrated in this file.

    Note that overflow and underflow are not possible in these operations.
    The results are not defined if X is an infinity or NaN.
    The one IEEE exception which might be reported is 'InExact', in the
    function QFjoin.  In that case we ought to return 0, but if the
    exception is ignored we'll return 0 anyway.
*/

#ifdef	vax
/* VAX D-format is used for 'double' */
#define	SignBit  0x00008000
#define	SignWord 0
#define	ExptMask 0x00007F80
#else
#ifdef	u370
/* IBM System/370 "long" format is used for 'double' */
#define	SignBit	 0x80000000
#define	SignWord 0
#define ExptMask 0x7F000000
#else
/* All other machines are close enough to IEEE 754 "double" format */
#define	SignBit  0x80000000
#define SignWord 0
#define	ExptMask 0x7FF00000
#endif
#endif

union pun { double d; int L[2]; };

/*  IEEE 754 defines (x REM y) thus:
    "	When y =\= 0, the remainder r = x REM y is defined regardless of
	the rounding mode by the mathematical relation r = x - y.n,
	where n is the integer nearest the exact value x/y; whenever
	|n - x/y| = 1/2, then n is even.  Thus, the remainder is always
	exact.  If r = 0, its sign shall be that of x.  Precision control
	(section 4.3) shall not apply to the remainder operation.  "

    (x REM y) is supposed to report (by setting a status flag) an
    "Invalid Operation" (section 7.1) if x is infinite or y is zero.
    Note that reporting "Division by Zero" (section 7.2) instead would
    be WRONG.

    Since |x REM y| is bounded above by |y| and below by min(|x|,|y|),
    and since the definition is exact, the Overflow, Underflow, and inexact
    exceptions cannot occur.  So "Invalid Operation" is the only possible
    exception.  This is true even on non-IEEE systems.

    IEEE 854 defines (x REM y) in exactly the same words.

    Draft 0.91 of the proposed standard for primitive functions in Ada
    specifies (x rem y) compatibly with IEEE 754.

    4.3BSD provides an interface to the (REM) operation through the
    function double drem(double x, double y), defined in <math.h>.
    SunOS provides this function too, but in recent versions of SunOS
    double remainder(double x, double y) is provided and <math.h> warns
    that "drem will disappear in a future release".

    System V provided a slightly different function:
	double fmod(double x, double y)
	    { return x - y*n where n:int && fabs(x-y*n) < fabs(y); }
    This means that |fmod(x,y)| < |y| and the absolute difference between
    fmod(x,y) and (x REM y) will be either 0 or |y|.  This function is in
    the draft ANSI standard for C.  Given that we can synthesise REM.

    On the other hand, there is at least one recent UNIX system for which
    the manuals we have mention neither drem() nor fmod().

    So we have the following cases to consider:
    NODREM is defined:
    (a) fmod() _is_ available.  In that case, just include "-DNODREM" in
	the command line, and it will be defined as 1.  We assume that
	NODREM==1 means that fmod() is there.
    (b) Nothing is provided.  In that case, use "-DNODREM=0" in the
	command line.  We provide an *INACCURATE* implementation in that
	case.  That's the price of using non-standard C!
    NODREM is not defined:
    (c) This is a recent SunOS and it is called "remainder".
	We assume this if FLOATPARAMETERVALUE is defined at all.
    (d) This is a 4.3BSD and it is called "drem".
	We assume this if FLOATPARAMETERVALUE is not defined.
    There is another possibility, which is that the operation is available
    in a highly system-specific way (e.g. the IBM RT PC).  In that case we
    check for it explicitly and you don't have to worry.
*/

#ifdef NODREM

/*  round(X) returns X rounded to the nearest integer (to even in the
    case of a tie) as a float.  The test for X in (-0.5,1.5) is there
    to prevent underflow.  What we really want to do is
	return ceil(d) - (if d is an even integer, then 0 else 1)
*/
static double round(X)
    double X;
    {
	double t, d;

	d = X + 0.5;		/* this cannot overflow! */
	t = ceil(d);		/* neither can this */
	if ((X > -0.5 && X < 1.5) || modf(d*0.5, &d) != 0.0) t -= 1.0;
	return t;
    }


/*  Prolog's sign/2 is the IEEE copysign() function.  As far as I know,
    you should have copysign() iff you have drem().  Here is a version
    of copysign() that Prolog can use if it is missing.
    Note that the VAX is special: -0.0 is illegal there.  On the /370,
    -0.0 is legal, but not otherwise differentiated from +0.0.  In IEEE
    arithmetic, -0.0 and +0.0 are both legal and clearly different.
*/

double copysign(X, Y)
    double X, Y;
    {
	union pun ux, uy;

	ux.d = X, uy.d = Y;
#ifdef	vax
	if ((ux.L[SignWord] & ExptMask) == 0) return X;
#endif
	ux.L[SignWord] &=~ SignBit;
	ux.L[SignWord] |= (uy.L[SignWord] & SignBit);
	return ux.d;
    }


#if NODREM
/*  In this case:
    -	REM is not directly available
    -	fmod() is present and compatible with the C standard.
*/
double QFrmdr(x, y)
    double x, y;
    {
	double r;

	r = fmod(x, y);		/* should check operands */
#ifndef	vax
	if (r == 0.0) return copysign(r, x);
#endif
	x = fabs(r), y = fabs(y);
	if (y > 1.0 ? y*0.5 < x : x*2.0 > y) {
	    if (r >= 0.0) r -= y; else r += y;
	}
	return r;
    }

#else
/*  In this case:
    -	REM is not directly available
    -	fmod is not present or is not compatible with the C standard.
    -	the answers are not as accurate as they should be.
*/
double QFrmdr(x, y)
    double x, y;
    {
	double r = x - round(x/y)*y;
	return r == 0.0 ? copysign(r, x) : r;
    }

#endif
#else
#ifdef	FLOATPARAMETERVALUE
#define	drem	remainder
#endif

/*  In this case:
    -	REM is available
    -	We can use the name drem() for it now.
*/
double QFrmdr(x, y)
    double x, y;
    {
	return drem(x, y);
    }

#endif


/*  QFconv(Method, X)
    Method = -1 => Result = ffloor(X)
    Method =  0 => Result = ftruncate(X)
    Method =  1 => Result = fceiling(X)
    Method =  2 => Result = fround(X)
*/    
double QFconv(Method, X)
    int Method;
    double X;
    {
	switch (Method) {
	    case -1:	return floor(X);
	    case  1:	return ceil(X);
	    case  0:	(void) modf(X, &X); return X;
        default:                /* [PM] 3.5 avoid compiler warning about missing return */
#ifdef	NODREM
	    case  2:	return round(X);
#else
	    case  2:	return X-drem(X, 1.0);
#endif
	}
	/*NOTREACHED*/
    }


/*  QFpart(Method, X, &I, &F)
    Method = -1 => *I = ffloor(X),	*F = X-*I
    Method =  0 => *I = ftruncate(X),	*F = X-*I
    Method =  1 => *I = fceiling(X),	*F = X-*I
    Method =  2 => *I = fround(X),	*F = X-*I
*/
void QFpart(Method, X, I, F)
    int Method;
    double X;
    double *I, *F;
    {
	double ip, fp;

	switch (Method) {
	    case -1:	fp = X - (ip = floor(X));	break;
	    case  1:	fp = X - (ip = ceil(X));	break;
	    case  0:	fp = modf(X, &ip);		break;
        default:                /* [PM] 3.5 avoid compiler warning about uninited fp */

#ifdef	NODREM
	    case  2:	fp = X - (ip = round(X));	break;
#else
	    case  2:	ip = X - (fp = drem(X, 1.0));	break;
#endif
	}
	*F = fp, *I = ip;
    }


/*  QFjoin(Method, &X, I, F)
    if I represents an integer and |F| < 1.0, and decomposing
    I+F according to Method would yield I and F again, *X is set
    to I+F and 1 is returned.  Otherwise, *X is undefined and 0
    is returned.  QFpart() and QFjoin() are inverses.
    Note that once we have checked that I is integral and F is
    in range, we know that I+F cannot overflow.
*/
int QFjoin(Method, X, I, F)
    int Method;
    double *X;
    double I, F;
    {
	double sm;

	if (modf(I, &sm) != 0.0) return 0;	/* I is not integral */
	switch (Method) {
	    case -1:	if (F < 0.0 || F >= 1.0) return 0;
			*X = I+F;
			return 1;
	    case  1:	if (F > 0.0 || F <= -1.0) return 0;
			*X = I+F;
			return 1;
	    case  0:	if (F <= -1.0 || F >= 1.0) return 0;
			sm = I+F;
			if (modf(sm, &I) != F) return 0;
			*X = sm;
			return 1;
        default:                /* [PM] 3.5 avoid compiler warning about missing return */
	    case  2:	if (F < -0.5 || F > 0.5) return 0;
			sm = I+F;
#ifdef	NODREM
			if (round(sm) != I) return 0;
#else
			if (drem(sm, 1.0) != F) return 0;
#endif
			*X = sm;
			return 1;
	}
	/*NOTREACHED*/
    }


static double QFImin = (long)QP_INT_MIN;
static double QFImax = QP_INT_MAX;

/*  QIconv(Method, X, &I)
    Method = -1 => *I = floor(X)
    Method =  0 => *I = truncate(X)
    Method =  1 => *I = ceiling(X)
    Method =  2 => *I = round(X)
    If the result can be represented as a Prolog integer, *I will be set
    as shown and 1 will be returned.  Otherwise, 0 will be returned.
    The caller will have to report the representation fault.
*/    
int QIconv(Method, X, I)
    int Method;
    double X;
    long *I;
    {
	double ip;

	switch (Method) {
	    case -1:	ip = floor(X);		break;
	    case  1:	ip = ceil(X);		break;
	    case  0:	(void) modf(X, &ip);	break;
#ifdef	NODREM
	    case  2:	ip = round(X);		break;
#else
	    case  2:	ip = X-drem(X, 1.0);	break;
#endif
	}
	if (ip < QFImin || ip > QFImax) return 0;
	*I = (long)ip;
	return 1;
    }


/*  QIpart(Method, X, &I, &F)
    Method = -1 => *I = floor(X),	*F = X-*I
    Method =  0 => *I = truncate(X),	*F = X-*I
    Method =  1 => *I = ceiling(X),	*F = X-*I
    Method =  2 => *I = round(X),	*F = X-*I
    If the result can be represented as a Prolog integer, *I will be set
    as shown and 1 will be returned.  Otherwise, 0 will be returned.
*/
int QIpart(Method, X, I, F)
    int Method;
    double X;
    long *I;
    double *F;
    {
	double ip, fp;

	switch (Method) {
	    case -1:	fp = X - (ip = floor(X));	break;
	    case  1:	fp = X - (ip = ceil(X));	break;
	    case  0:	fp = modf(X, &ip);		break;
        default:                /* [PM] 3.5 avoid compiler warning about uninited fp */
#ifdef	NODREM
	    case  2:	fp = X - (ip = round(X));	break;
#else
	    case  2:	ip = X - (fp = drem(X, 1.0));	break;
#endif
	}
	if (ip < QFImin || ip > QFImax) return 0;
	*F = fp, *I = (long)ip;
	return 1;
    }



/*  QFdecd(+X, -S, -F, -E)
    takes a double X and breaks it into three pieces S, F, and E
    such that
	S = 1 or S = -1
	F = 0.0 or 0.5 <= F < 1.0
	X = S.F.2**E (E is an integer)
    We have to be careful about this in order to get the result
    right for IEEE -0.0.
*/
void QFdecd(X, S, F, E)
    double X;
    long *S;
    double *F;
    long *E;
    {
	union pun ux;
	int evalue;

	ux.d = X;
	*S = ux.L[SignWord]&SignBit ? -1 : 1;
	ux.L[SignWord] &=~ SignBit;
	*F = frexp(ux.d, &evalue);
	*E = evalue;
    }


int QFencd(X, S, F, E)
    double *X;
    int S;
    double F;
    int E;
    {
	if (S != 1 && S != -1) return 0;
	if (F >= 1.0 || (F < 0.5 && (F != 0.0 || E != 0))) return 0;
	errno = 0;
	F = ldexp(F, E);
	if (errno) return 2;
	*X = S < 0 ? -F : F;
	return 1;
    }


/*  Various pieces of test code.
*/
#ifdef	M_TEST

main()
    {
	int i;
	double x, c, s, t;

	for (i = 1000; i <= 2000; i += 10) {
	    x = i*0.01;
	    t = tanh(x);
	    s = atanh(t);
	    printf("atanh(tanh(%7.2f) = %.17e) = %18.15f\n", x, t, s);
	}
	exit(0);
	for (i = -100; i <= 100; i++) {
	    x = i*0.1;
	    c = cosh(x);
	    s = sinh(x);
	    t = tanh(x);
	    printf("x = %.2f;\n\tasinh(% .10e) = % .8f;\n", x, s, asinh(s));
	    printf("\tacosh(% .10e) = % .8f;\n", c, acosh(c));
	    printf("\tatanh(% .10e) = % .8f\n\n", t, atanh(t));
	}
    }	

#endif/*M_TEST*/

