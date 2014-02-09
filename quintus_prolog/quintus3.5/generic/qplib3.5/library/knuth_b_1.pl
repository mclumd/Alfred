%   Package: knuth_b_1
%   Typist : Richard A. O'Keefe
%   Author : the rules of arithmetic, via Donald Knuth
%   Updated: 30 Apr 1990
%   Purpose: table of constants.

/*  This is table 1 of appendix B of "The Art of Computer Programming"
    volume 1, by Donald E. Knuth.  That table gives 40 decimal places.
    As most of the Prolog systems known to me have trouble with 6
    places, I have rounded to 7 decimal places.  Anyone wanting more
    should consult the original reference.  Note that most of these
    names are compound terms, e.g. sqrt(2), 3^(1/3), cos(1).  This
    was done for clarity.

    This table may be extended with other constants taken from
    Abramowitz & Stegun, "Handbook of Mathematical Functions",
    chapter 1.  Note that they give numbers to 21 or 26 places.
    Which constants would be most useful to you?
*/

:- module(knuth_b_1, [
	constant/2
   ]).

sccs_id('"@(#)90/04/30 knuth_b_1.pl	41.1"').


constant(sqrt(2),	1.41421356237309504880).
constant(sqrt(3),	1.73205080756887729353).
constant(sqrt(5),	2.23606797749978969641).
constant(sqrt(10),	3.16227766016837933200).

constant(2^(1/3),	1.25992104989487316477).
constant(3^(1/3),	1.44224957030740838232).
constant(2^(1/4),	1.18920711500272106672).

constant(ln(2),		0.69314718055994530942).
constant(ln(3),		1.09861228866810969140).
constant(ln(10),	2.30258509299404568402).
constant(1/ln(2),	1.44269504088896340736).
constant(1/ln(10),	0.43429448190325182765).
constant(ln(ln(2)),    -0.36651292058166432701).

constant(pi,		3.14159265358979323846).
constant(pi/180,	0.01745329251994329577).
constant(1/pi,		0.31830988618379067154).
constant(pi^2,		9.86960440108935861883).
constant(sqrt(pi),	1.77245385090551602730).
constant(ln(pi),	1.14472988584940017414).

constant(gamma(1/2),	1.77245385090551602730).
constant(gamma(1/3),	2.67893853470774763366).
constant(gamma(2/3),	1.35411793942640041695).

constant(e,		2.71828182845904523536).
constant(1/e,		0.36787944117144232160).
constant(e^2,		7.38905609893065022723).
constant(e^(pi/4),	2.19328005073801545656).

constant(gamma,		0.57721566490153286061).
constant(e^gamma,	1.78107241799019798524).

constant(phi,		1.61803398874989484820).
constant(ln(phi),	0.48121182505960344750).
constant(1/ln(phi),	2.07808692123502753760).

constant(sin(1),	0.84147098480789650665).
constant(cos(1),	0.54030230586813971740).

constant(zeta(3),	1.20205690315959428540).

