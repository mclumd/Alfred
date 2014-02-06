/*
file: parser/taparse.pl
By: kpurang
What: a more friendly alma language

Toso: to delete since not used.

*/


% need to make this recurse into afs and calls.
% alternative: include this in alma.

:- op(1200, xfx, [ '=>' ]).       % forward if
:- op(1200, xfx, [ '|-' ]).       % Prod rule
:- op(1200, xfx, [ '<=' ]).       % bif
:- op(1000, yfx, [ '&' ]).        % And
:- op(1100, yfx, [ '#' ]).        % Or

translate(forall(V, X), forall(V, XX)):-
    var(V), !,
    translate(X, XX).
translate(forall([], X), XX):- !,
    translate(X, XX).
translate(forall([X|Y], Z), forall(X, ZZ)):- !,
    translate(forall(Y, Z), ZZ).
translate(exists(V, X), exists(V, XX)):-
    var(V), !,
    translate(X, XX).
translate(exists([], X), XX):- !,
    translate(X, XX).
translate(exists([X|Y], Z), exists(X, ZZ)):- !,
    translate(exists(Y, Z), ZZ).
translate((X => Y), if(XX, YY)):- !,
    translate(X, XX),
    translate(Y, YY).
translate((X <= Y), bif(YY, XX)):- !, 
    translate(X, XX),
    translate(Y, YY).
translate((X |- Y), fif(XX, conclusion(YY))):- !,
%    translate(X, XX),
    conjlist(X, XX),
    translate(Y, YY).
translate((X & Y), and(XX, YY)):- !,
    translate(X, XX),
    translate(Y, YY).
translate((X # Y), or(XX, YY)):- !,
    translate(X, XX),
    translate(Y, YY).
translate(X, X):-
    functor(X, call, 2), !.
translate(X, X):-
    functor(X, call, _), !, nl(user_error), 
    print(user_error, 'Error '), print(user_error, X), nl(user_error), !, fail.
translate(X, X):-
    functor(X, gensym, 3), !.
translate(X, X):-
    functor(X, gensym, _), !, nl,
    print(user_error, 'Error '), print(user_error, X), nl(user_error), !, fail.
translate(X, X).


runtime_entry(start):-
    repeat,
    read(T),
    (\+ T = end_of_file ->
	 (translate(T, TT), print(TT), print('.'), nl); true),
    T = end_of_file, !, 
    halt.


conjlist([X, Y], and(X, Y)):- !.
conjlist([X|R], and(X, Z)):- !,
    conjlist(R, Z).
