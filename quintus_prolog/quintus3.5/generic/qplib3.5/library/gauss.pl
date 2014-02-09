%   Package: gauss
%   Author : Richard A. O'Keefe
%   Updated: 25 Oct 1990
%   Purpose: Solve linear equations by Gaussian elimination.

%   This code was written by R.A.O'K for an introductory Prolog class,
%   and is in the public domain.  It is intended that other matrix and
%   vector operations will be provided in future versions of this
%   file; such additional code may be copyright.

:- module(gauss, [
	gauss/3
   ]).

sccs_id('"@(#)90/10/25 gauss.pl	58.1"').

/*  gauss(+A, +B, -X)
    solves the system of linear equations A.X = B
    where A is an N-by-N matrix, B is an N-by-1 column vector,
    and X is an N-by-1 column vector.  B and X are represented
    by lists, and A is represented by a list of lists (each
    row of A is represented by a list of its elements).
    For example,
	| a11 a12 a13 |   | x1 |   | b1 |
	| a21 a22 a23 | x | x2 | = | b2 |
	| a31 a32 a33 |   | x3 |   | b3 |
    would be represented by
	gauss([[A11,A12,A13]
	      ,[A21,A22,A23]
	      ,[A31,A32,A33]], [B1,B2,B3], [X1,X2,X3])
*/

gauss(A, B, X) :-
	group_ab(A, B, AB),
	forward_eliminate(AB, AB1),
	back_substitute(AB1, X).

group_ab([], [], []).
group_ab([Row|Rows], [B|Bs], [RowB|RowBs]) :-
	append(Row, [B], RowB),
	group_ab(Rows, Bs, RowBs).

forward_eliminate([], []).
forward_eliminate([[R|Rs]|Rows], [[M|Ms]|Tri]) :-
	( R >= 0 -> AbsR is R ; AbsR is -R ),
	find_pivot(Rows, AbsR, R, Rs, M, Ms, Rest),
	eliminate(Rest, M, Ms, Reduced),
	forward_eliminate(Reduced, Tri).

find_pivot([], _, M, Ms, M, Ms, []).
find_pivot([Row|Rows], AbsM0, M0, Ms0, M, Ms, [Row1|Rest]) :-
	Row = [R|Rs],
	( R >= 0 -> AbsR is R ; AbsR is -R ),
	( AbsR > AbsM0 ->
	    Row1 = [M0|Ms0],
	    find_pivot(Rows, AbsR, R, Rs, M, Ms, Rest)
	;   Row1 = Row,
	    find_pivot(Rows, AbsM0, M0, Ms0, M, Ms, Rest)
	).

eliminate([], _, _, []).
eliminate([[R|Rs]|Rows], M, Ms, [Mod|Mods]) :-
	Scale is -R/M,
	eliminate_row(Rs, Ms, Scale, Mod),	% "saxpy"
	eliminate(Rows, M, Ms, Mods).

eliminate_row([], [], _, []).
eliminate_row([R|Rs], [M|Ms], S, [A|As]) :-
	A is M*S+R,
	eliminate_row(Rs, Ms, S, As).

back_substitute([], []).
back_substitute([[Scale|Coeffs]|Eqns], [Var|Vars]) :-
	back_substitute(Eqns, Vars),
	calc_rhs(Vars, Coeffs, 0.0, Rhs),
	Var is Rhs/Scale.

calc_rhs([], [B], S, Rhs) :-
	Rhs is B-S.
calc_rhs([V|Vs], [B|Bs], S0, Rhs) :-
	S1 is V*B+S0,
	calc_rhs(Vs, Bs, S1, Rhs).


end_of_file.

test(N, X, E) :-
	data(N, A, B),
	gauss(A, B, X),
	matvec(A, X, C),
	relerr(B, C, E).

data(1,	[[911,812,713],[721,822,923],[631,632,933]], [1,2,3]).
data(2, [[  1,  0,  0],[  0,  1,  0],[  0,  0,  1]], [7,8,9]).
data(3, [[  0,  1,  0],[  0,  0,  1],[ -1,  0,  0]], [4,5,6]).


/*  In order to test guass/3 properly, we want to compute
	A.X = B
    in the opposite direction, solving for B.  This is easy
    because in A, lists represent ROWS, while the list X
    represents a COLUMN.
*/
matvec([], _, []).
matvec([Row|Rows], Col, [B|Bs]) :-
	dot(Row, Col, 0, B),
	matvec(Rows, Col, Bs).

dot([], [], S, S).
dot([A|As], [X|Xs], S0, S) :-
	S1 is A*X+S0,
	dot(As, Xs, S1, S).

relerr(Bi, Bf, RE) :-
	relerr(Bi, Bf, 0.0, 0.0, RE).

relerr([], [], N, D, RE) :-
	RE is N/D.
relerr([I|Is], [F|Fs], N0, D0, RE) :-
	( I >= 0 -> D1 is D0+I ; D1 is D0-I ),	% D1 is D0+abs(I)
	E is F-I,
	( E >= 0 -> N1 is N0+E ; N1 is N0-E ),	% N1 is N0+abs(F-I)
	relerr(Is, Fs, N1, D1, RE).


