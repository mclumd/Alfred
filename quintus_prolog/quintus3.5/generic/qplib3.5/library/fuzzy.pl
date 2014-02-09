%   Package: fuzzy
%   Author : Richard A. O'Keefe
%   Updated: 04/20/99
%   Defines: Knuth-style fuzzy comparison predicates in Quintus Prolog.

%   This code is Copyright (C) 1989, Quintus Computer Systems, Inc.,
%   but it may be used freely provided the copyight notice is preserved and
%   Quintus is acknowledged.

:- module(fuzzy, [
	'fuzzy <'/2,		% Def (21) p 218 sec 4.2.2 
	'fuzzy ~'/2,		% Def (22) p 218 sec 4.2.2 
	'fuzzy >'/2,		% Def (23) p 218 sec 4.2.2 
	'fuzzy ='/2,		% Def (24) p 218 sec 4.2.2 
	set_fuzz/1
   ]).

sccs_id('"@(#)99/04/20 fuzzy.pl	76.1"').

/*  For a fixed epsilon, the fuzzy comparison predicates are defined
    in section 4.2.2 (Accuracy of floating point arithmetic) of
    Knuth, The Art of Computer Programming, vol 2, Seminumerical Algorithms
    (2nd edition) on page 218.

    (21)  'fuzzy <'(U, V) <->  V-U  >  epsilon.b^max(e_u, e_v)
    (22)  'fuzzy ~'(U, V) <-> |V-U| =< epsilon.b^max(e_u, e_v)
    (23)  'fuzzy >'(U, V) <->  U-V  >  epsilon.b^max(e_u, e_v)
    (24)  'fuzzy ='(U, V) <-> |V-U| =< epsilon.b^min(e_u, e_v)

    where U = F.b^e_u and |F| < 1
      and V = G.b^e_v and |G| < 1

    This is a very crude first implementation.
*/

'fuzzy <'(U, V) :-
	'QPFUZZCMP'(U, V, 2).

'fuzzy ~'(U, V) :-
	'QPFUZZCMP'(U, V, C),
	C < 2.

'fuzzy >'(U, V) :-
	'QPFUZZCMP'(U, V, 3).

'fuzzy ='(U, V) :-
	'QPFUZZCMP'(U, V, 1).

set_fuzz(Epsilon) :-
	number(Epsilon),
	Epsilon > 0,
	'QPSETFUZZ'(Epsilon).

foreign_file(library(system(libpl)), [ 'QPFUZZCMP', 'QPSETFUZZ' ]).

foreign('QPFUZZCMP', 'QPFUZZCMP'(+double,+double,[-integer])).
foreign('QPSETFUZZ', 'QPSETFUZZ'(+double)).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

