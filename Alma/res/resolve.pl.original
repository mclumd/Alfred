/*
File: res/resolve.pl
By: kpurang
What: does the resolution

Todo: there has to be a more efficient way
      add strucutre to the clauses to make more efficient      

*/

:- ensure_loaded(library(sets)).
:- ensure_loaded(library(ordsets)).


% new version mar 01
% kp

/*
  make sure we take care of cases like:
  p(X) -> q(X) and p(a) | p(b)
  Need to resolve multiple times.
  
  how about if the vars and constants are on both sides? :(

  ALSO: what do we expect to return? a _list_ of result clauses i think.
  is a list of [R, T] where R is the cluase, T is the target and is used
  only in bcres. Now, how that target gets in there, i am not sure. ah!
  the target is the third arg. Oh! it has to be inthe resiult cos if i
  have several results, i need several targets! OK. we fix that now.
  BUT not the several results thing for now.
  

  detect tautologies and return 'true'


  TODO:
  1. find multiple resolutions
  2. retrun them in the right way (with the target)
  3. detect tautologies.

*/

resolve(C1, C2, Tar, Res):- !,
    copy_term([C1, C2, Tar], [CC1, CC2, CTar]),
    separate_lits(CC1, [[],[]], CS1),
    separate_lits(CC2, [[],[]], CS2),
    resolve2(CS1, CS2, Tar, Res).

separate_lits([], [X, Y], [OX, OY]):- !,
    list_to_ord_set(X, OX),
    list_to_ord_set(Y, OY).
separate_lits([not(X)|Y], [XX, YY], Z):- !,
    separate_lits(Y, [XX, [X|YY]], Z).
separate_lits([X|Y], [XX, YY], Z):- !,
    separate_lits(Y, [[X|XX], YY], Z).

%resolve2([+1, -1], [+2, -2], Tar, Res)
% for each element in +1, see if htere is anything in -2 that unifies.
% same for -1 and +2
% once that happens, merge the clauses

resolve2([P1, N1], [P2, N2], T, R):- 
    (try_each1([], P1, [], N2, P2, N1, T, R); 
    try_each1([], P2, [], N1, P1, N2, T, R)).

try_each1(X, [], Y, [], _, _, _, _):- !, fail.
try_each1(X, [Y|Z], Q, [], Xs, Qs, T, R):- !,
    try_each1([Y|X], Z, [], Xs, Qs, Q, T, R).
try_each1(X, [Y|Z], Q, [W|V], Xs, Qs, T, R):- 
    (Y = W -> merge(X, Z, Q, V, Xs, Qs, T, R); 
    try_each1(X, [Y|Z], [W|Q], V, Xs, Qs, T, R)).

/*
  Note that this will have to be changed later when we do the 
  multiple resolutions.
*/
merge(X, Z, Q, V, Xs, Qs, T, [[R, T]]):- !,
    append(X, Z, XZ), append(XZ, Xs, Plus),
    append(Q, V, QV), append(QV, Qs, Negs),
    list_to_ord_set(Plus, Oplus),
    list_to_ord_set(Negs, ONegs),
    clean_up_res(Oplus, ONegs, R).

%
% do not detect tautologies for now!!
%
clean_up_res(X, [], X):- !.
clean_up_res(X, [Y|Z], R):- !,
    clean_up_res([not(Y)|X], Z, R).




