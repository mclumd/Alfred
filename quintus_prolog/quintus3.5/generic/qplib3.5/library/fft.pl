%   Package: fft
%   Author : Richard A. O'Keefe
%   Updated: 04/15/99
%   Defines: Fast Fourier Transform in Prolog.

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(fft, [
	fwd_fft/2,
	inv_fft/2
   ]).

:- use_module(library(math), [
	sin/2,
	cos/2
   ]).

sccs_id('"@(#)99/04/15 fft.pl	76.1"').

/*	F[k] = sum[j=0..N-1] exp(2.pi.i.j.k/N) f[j]

	     = sum[j=0..N/2-1] exp(2.pi.i.k.(2j)/N f[2j]
	     + sum[j=0..N/2-1] exp(2.pi.i.k.(2j+1)/N f[2j+1]

	     = sum[j=0..N/2-1] exp(2.pi.i.j.k/(N/2)) f[2j]
	     + W^k
	     * sum[j=0..N/2-1] exp(2.pi.i.j.k/(N/2)) f[2j+1]

	F(k;L) = f(k;E) + exp(2.pi.i.k/length(L))f(k;O)
		where evens_and_odds(L, E, O).

    fwd_fft(Data, FFT) and inv_fft(FFT, Data)
    do a forward and inverse Fast Fourier Transform respectively.
    The input is a list of complex numbers.
    A complex number may be represented as (Real,Imag), complex(Real,Imag),
    or as a single floating-point number Real (Imag=0).  The only form
    used in the output is (Real,Imag).
    If the length of the input is not a power of two, or if any element
    cannot be construed as a number, these operations will fail.

    This file was written to demonstrate that a FFT could be written in
    Prolog with the same O(N*log(N)) _asymptotic_ cost as in Fortran.
    There are several easy things that could be done to make it faster,
    but you would be better off for numerical calculations like this
    using library(vectors) to call a Fortran subroutine.
*/

%   fwd_fft(+Numbers, -FFT)
%   does a forward FFT on a list of complex numbers, each of which is
%   represented as a pair (Real,Imag).  (Real,0) may be abbreviated as
%   a single floating-point number Real in the input; this will not be
%   done in the output.

fwd_fft(Raw, FFT) :-
	complex_numbers(Raw, Normalised, 0, N),
	fft(N, Normalised, FFT, fwd).


%   inv_fft(+FFT, -Numbers)
%   does an inverse FFT on a list of complex numbers, using the same
%   representation as fwd_fft.

inv_fft(FFT, Raw) :-
	complex_numbers(FFT, Normalised, 0, N),
	fft(N, Normalised, Mid, inv),
	scale(Mid, N, Raw).


fft(1, [X], [X], _) :- !.
fft(N, Raw, FFT, Dir) :-
	n_cos_sin(N, Cos, Sin),
	pack_w(Dir, Cos, Sin, W),
	M is N>>1,
	evens_and_odds(Raw, E, O),
	fft(M, E, Ef, Dir),
	fft(M, O, Of, Dir),
	fft(Ef, Of, W, (1.0,0.0), Z, FFT, FF2),
	fft(Ef, Of, W, Z, _, FF2, []).

pack_w(fwd, C, S, (C,S)).
pack_w(inv, C, S, (C,Z)) :- Z is -S.

fft([], [], _, Z, Z, F, F).
fft([E|Es], [O|Os], W, Z0, Z, [F|Fs], Fl) :-
	complex_mul(Z0, O, Zt),
	complex_add(Zt, E, F),
	complex_mul(Z0, W, Z1),
	fft(Es, Os, W, Z1, Z, Fs, Fl).

evens_and_odds([], [], []).
evens_and_odds([E,O|EOs], [E|Es], [O|Os]) :-
	evens_and_odds(EOs, Es, Os).


scale([], _, []).
scale([(Ra,Ia)|Xs], Scale, [(Rs,Is)|Ys]) :-
	Rs is Ra/Scale,
	Is is Ia/Scale,
	scale(Xs, Scale, Ys).


complex_numbers(-, _, _, _) :- !, fail.
complex_numbers([], [], N, N) :-
	(N-1) \/ N =:= N-1 + N.		% N is a power of 2
complex_numbers([Number|Numbers], [(Real,Imag)|Complexes], N0, N) :-
	N1 is N0+1,
	complex_number(Number, Real, Imag),
	complex_numbers(Numbers, Complexes, N1, N).

complex_number((Ra,Ia), Rs, Is) :- !,
	Rs is float(Ra),
	Is is float(Ia).	
complex_number(complex(Ra,Ia), Rs, Is) :- !,
	Rs is float(Ra),
	Is is float(Ia).
complex_number(Ra, Rs, 0.0) :-
	Rs is float(Ra).


complex_add((Ra,Ia), (Rb,Ib), (Rs,Is)) :-
	Rs is Ra+Rb,
	Is is Ia+Ib.

complex_mul((Ra,Ia), (Rb,Ib), (Rs,Is)) :-
	Rs is Ra*Rb-Ia*Ib,
	Is is Ra*Ib+Rb*Ia.

complex_exp(Ang, (Rs,Is)) :-
	cos(Ang, Rs),
	sin(Ang, Is).


%   n_cos_sin(N, C, S) is true when N is 2^K for K=1..23,
%   C is cos(2.pi/N), and S is sin(2.pi/N).

n_cos_sin(        2, -1.00000000e+00,  0.00000000e+00).
n_cos_sin(        4,  0.00000000e+00,  1.00000000e+00).
n_cos_sin(        8,  7.07106781e-01,  7.07106781e-01).
n_cos_sin(       16,  9.23879533e-01,  3.82683432e-01).
n_cos_sin(       32,  9.80785280e-01,  1.95090322e-01).
n_cos_sin(       64,  9.95184727e-01,  9.80171403e-02).
n_cos_sin(      128,  9.98795456e-01,  4.90676743e-02).
n_cos_sin(      256,  9.99698819e-01,  2.45412285e-02).
n_cos_sin(      512,  9.99924702e-01,  1.22715383e-02).
n_cos_sin(     1024,  9.99981175e-01,  6.13588465e-03).
n_cos_sin(     2048,  9.99995294e-01,  3.06795676e-03).
n_cos_sin(     4096,  9.99998823e-01,  1.53398019e-03).
n_cos_sin(     8192,  9.99999706e-01,  7.66990319e-04).
n_cos_sin(    16384,  9.99999926e-01,  3.83495188e-04).
n_cos_sin(    32768,  9.99999982e-01,  1.91747597e-04).
n_cos_sin(    65536,  9.99999995e-01,  9.58737991e-05).
n_cos_sin(   131072,  9.99999999e-01,  4.79368996e-05).
n_cos_sin(   262144,  1.00000000e+00,  2.39684498e-05).
n_cos_sin(   524288,  1.00000000e+00,  1.19842249e-05).
n_cos_sin(  1048576,  1.00000000e+00,  5.99211245e-06).
n_cos_sin(  2097152,  1.00000000e+00,  2.99605623e-06).
n_cos_sin(  4194304,  1.00000000e+00,  1.49802811e-06).
n_cos_sin(  8388608,  1.00000000e+00,  7.49014057e-07).

end_of_file.

%   TEST CODE

:- use_module(library(between)).

data(0, [0,0,0,0]).
data(1, [1,0,0,0]).
data(2, [0,1,0,0]).
data(8, [1,2,3,4,3,2,1,0]).
data(9, [1,2,1,2,1,2,1,2]).

test(N) :-
	data(N, Raw),
	fwd_fft(Raw, FFT),
	inv_fft(FFT, Inv),
	write('Raw = '), write(Raw), nl,
	write('FFT = '), write(FFT), nl,
	write('Inv = '), write(Inv), nl.

time(K) :-
	N is 1<<K,
	numlist(1, N, Raw),
	statistics(runtime, _),
	fwd_fft(Raw, _),
	statistics(runtime, [_,T]),
	S is (T/N)/K,
	write(T=S*N*K), nl.

