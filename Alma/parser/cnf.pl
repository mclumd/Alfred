/*
File: parser/cnf.pl
By: kpurang
What: conversion to normal form for res.pl

*/

%  ************************************************************
%  for now, we ignore quote(X) and cases of bs(X) where X is compound.
%  ************************************************************

%
% mar 23 00: kp modified the distribution of and over ors.
%

%
% do not convert bs(X) formulas to X formulas at this stage. do it
% at run time so that the variables are bound. Convert them when they 
% are seen leftmost. also, we dont want to end up with whole lots of
% loose bc's right from the beginning.
%
% for calls, smae goes. convert at run time
% maybe we will need 2 types of call: for those in antecedent and those
% in consequent. but maybe not
%
% for quotes, do as planned.
%

% sep 30 97
% now we have another type of if: 'iif'
% this will only be used in formulas of the form
% forall x1..xn iif(AND(p1...pn), call(c))
% c must contain all of x1...xn
% so before we do the cnfization, we look for fomulas with iif
% or maybe do that in the elim-if
% make a list of the antecedents, convert call to icall and add the list
% of antecedents as a new argument, change iif to fif
% in the processing, when we see an icall, verify that the negation of
% the things in the list are present in the datanase before doing the call.
%
% another possibility would be to do that after cnfization

% convert_form(+Form, - list of forms)
% given a formula, convert it into cnf
%
% mar 7 99: convert list of clauses to an ordered set.
%

:- use_module(library(ordsets)).

convert_form(FF, CNF, Typ):-
    clean_bs(FF, F),
    con_que(F, FFF),
    elim_if(FFF, F1, Typ),
    move_not(F1, F2),
    stand_var(F2, F3),
    move_quant(F3, F4),
    skolemize(F4, F6),
    dist_and_or(F6, F7),
    flatten1(F7, CNFa),
    each_list_to_ord_set(CNFa, CNF).

% clean_bs(+F, -G)
% meant to take care of case where we allow bs(X), compound X
clean_bs(X, X):- !.

% con_que(+In, -Out)
% replace yon(X) by and(bs(X), bs(not(X)))
% what is that for?
% do we still need it?
con_que(forall(X, Y), forall(X, Z)):- !,
    con_que(Y, Z).
con_que(exists(X, Y), exists(X, Z)):- !,
    con_que(Y, Z).
con_que(not(X), not(Y)):- !,
    con_que(X, Y).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% code from traum, oct 29 1998

con_que(and2([X,Y]), and(XX, YY)):- !,
    con_que(X, XX),
    con_que(Y, YY).
con_que(and2([X,Y|Z]), and(XX, YY)):- !,
    con_que(X, XX),
    con_que(and2([Y|Z]), YY).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
con_que(and(X, Y), and(XX, YY)):- !,
    con_que(X, XX),
    con_que(Y, YY).
con_que(or(X, Y), or(XX, YY)):- !,
    con_que(X, XX),
    con_que(Y, YY).
con_que(if(X, Y), if(XX, YY)):- !,
    con_que(X, XX),
    con_que(Y, YY).
con_que(fif(X, Y), fif(XX, YY)):- !,
    con_que(X, XX),
    con_que(Y, YY).
con_que(bif(X, Y), bif(XX, YY)):- !,
    con_que(X, XX),
    con_que(Y, YY).
con_que(yon(X), and(bs(X), bs(not(X)))):- !.
con_que(X, X).



% elim_if(+F, -G)
% given formula F, convert all ifs and return G
% there are 3 types of 'if'. the type is used to annotate the caluses.
% only the outermost if is used to determine the type. rest are ignored.
elim_if(forall(X, Y), forall(X, Z), T):- !,
    elim_if(Y, Z, T).
elim_if(exists(X, Y), exists(X, Z), T):- !,
    elim_if(Y, Z, T).
elim_if(not(X), not(Y), _):- !,
    elim_if(X, Y, _).
elim_if(and(X, Y), and(XX, YY), _):- !,
    elim_if(X, XX, _),
    elim_if(Y, YY, _).
elim_if(or(X, Y), or(XX, YY), _):- !,
    elim_if(X, XX, _),
    elim_if(Y, YY, _).
elim_if(iif(X, call(Y)), XX, YY):- !,
    list_conjuncts(X, LX),
    elim_if(fif(X, xicall(Y, LX)), XX, YY).
elim_if(if(X, Y), or(not(XX), YY), if):- !,
    elim_if(X, XX, _),
    elim_if(Y, YY, _).
elim_if(fif(X, Y), or(not(XX), YY), fif):- !,
    elim_if(X, XX, _),
    elim_if(Y, YY, _).
elim_if(bif(X, Y), or(not(XX), YY), bif):- !,
    elim_if(X, XX, _),
    elim_if(Y, YY, _).
elim_if(X, X, _).

% move_not(+F, -G)
% move negations inwards in F to return G.
% cases: 
% not(literal) -> not(literal)
% not(not(literal)) -> literal
% not(forall(X, P)) -> exists(X, move_not(not(P)))
% not(exists(X, P)) -> forall(X, move_not(not(P)))
% not(and(P, Q)) -> or(move_not(not(P)), move_not(not(Q)))
% and so on
move_not(not(not(P)), Q) :- !, move_not(P, Q).
move_not(forall(X, P), forall(X, Q)) :- !, move_not(P, Q).
move_not(not(forall(X, P)), exists(X, Q)) :- !, move_not(not(P), Q).
move_not(exists(X, P), exists(X, Q)) :- !, move_not(P, Q).
move_not(not(exists(X, P)), forall(X, Q)) :- !, move_not(not(P), Q).
move_not(and(P, Q), and(R, S)):- !,
    move_not(P, R),
    move_not(Q, S).
move_not(not(and(P, Q)), or(R, S)):- !,
    move_not(not(P), R),
    move_not(not(Q), S).
move_not(or(P, Q), or(R, S)):- !,
    move_not(P, R),
    move_not(Q, S).
move_not(not(or(P, Q)), and(R, S)):- !,
    move_not(not(P), R),
    move_not(not(Q), S).
move_not(P, P).

% stand_var(+F, -G)
% make all variables different.
stand_var(not(P), not(Q)):- !, stand_var(P, Q).
stand_var(and(P, Q), and(R, S)):- !, stand_var(P, R), stand_var(Q, S).
stand_var(or(P, Q), or(R, S)):- !, stand_var(P, R), stand_var(Q, S).
stand_var(forall(X, P), forall(Y, Qa)):- !,
    stand_var(P, Q),
    copy_term(forall(X, Q), forall(Y, Qa)).
stand_var(exists(X, P), exists(Y, Qa)):- !,
    stand_var(P, Q),
    copy_term(exists(X, Q), exists(Y, Qa)).
stand_var(Q, Q).

% move_quant(+F, -G)
% all quantifiers in F are moved to the left
move_quant(F, G):- !,
    get_quant(F, [], Q, FF),
    requantify(Q, FF, G).

% get_quant(+F, +IQ, -Q, -FF)
% F is a formula perhaps with quantiifers
% IQ is an initial list of quantifiers
% Q is a final list of quantifiers in F in the order in which they appear
% FF is F without quantifiers.
get_quant(not(P), I, F, not(Q)):- !,
    get_quant(P, I, F, Q).
get_quant(and(P, Q), I, F, and(R, S)):- !,
    get_quant(P, I, II, R),
    get_quant(Q, II, F, S).
get_quant(or(P, Q), I, F, or(R, S)):- !,
    get_quant(P, I, II, R),
    get_quant(Q, II, F, S).
get_quant(forall(X, P), I, [[forall, X]|II], Q):- !,
    get_quant(P, I, II, Q).
get_quant(exists(X, P), I, [[exists, X]|II], Q):- !,
    get_quant(P, I, II, Q).
get_quant(Y, X, X, Y).

% requantify(+Q, +F, -FF)
% Q: a list of [quantifier, variable] lists,
% F: a qunatifier free formula
% FF: the qunatifiers in Q applied to F
requantify([], F, F):- !.
requantify([[forall, Var]|Rest], F, forall(Var, D)):- !,
    requantify(Rest, F, D).
requantify([[exists, Var]|Rest], F, exists(Var, D)):- !,
    requantify(Rest, F, D).
    
% skolemize(+F, -G)
% skolemizes and drops all quantifiers in F to get G
skolemize(F, G):- !, sko(F, [], G).
sko(forall(X, P), I, Q):- !,
    sko(P, [X|I], Q).
sko(exists(X, P), I, Q):- !,
    new_sko(I, X),
    sko(P, I, Q).
sko(X, _, X).

% new_sko(+Q, +S)
% Q: a list of variables
% S: a new skolem constatn or function with the right arguments
new_sko([], S):- !,
    new_sko_name(S).
new_sko(I, S):- !,
    new_sko_name(SS),
    S=..[SS|I].

% new_sko_name(-N)
% return a new name
new_sko_name(N):- !,
    retract(skolem_count(C)),
    D is C + 1,
    assert(skolem_count(D)),
    name(C, Xn),
    name(N, [115,107,111|Xn]).

% dist_and_or(+F, -G)
% distribute and over ors in F to get G
dist_and_or(and(P, Q), and(R, S)):- !,
    dist_and_or(P, R),
    dist_and_or(Q, S).
dist_and_or(or(P, Q), Z):- !,
    dist_and_or(P, R),
    dist_and_or(Q, S),
    ((R = and(R1, R2),  S = and(S1, S2)) ->
	  ( dist_and_or(or(R1, S1), V1),
	    dist_and_or(or(R1, S2), V2),
	    dist_and_or(or(R2, S1), V3),
	    dist_and_or(or(R2, S2), V4),
	  Z = and(V1, and(V2, and(V3, V4))));
      (R = and(R1, R2)) -> 
	   ( dist_and_or(or(R1, S), V5),
	     dist_and_or(or(R2, S), V6),
	     Z = and(V5, V6));
         (S = and(S1, S2)) -> 
	      ( dist_and_or(or(R, S1), V7),
		dist_and_or(or(R, S2), V8),
		Z = and(V7, V8));
            Z = or(R, S)).
dist_and_or(X, X).

% my_flatten(+F, -G)
% F: a formula in cnf
% G: list of clauses (clause: list of disjuncts)
flatten1(and(P, Q), R):- !,
    my_flatten(and(P, Q), R).
flatten1(P, [R]):- !,
    my_flatten(P, R).
my_flatten(or(P, Q), R):- !,
    flatten_or(P, PP),
    flatten_or(Q, QQ),
    append(PP, QQ, R).
my_flatten(and(P, Q), R):- !,
    flatten_and(P, PP),
    flatten_and(Q, QQ),
    append(PP, QQ, R).
my_flatten(P, [P]):- !.

flatten_or(or(P, Q), R):- !,
    my_flatten(or(P, Q), R).
flatten_or(P, [P]):- !.

flatten_and(and(P, Q), R):- !,
    my_flatten(and(P, Q), R).
flatten_and(or(P, Q), [R]):- !,
    my_flatten(or(P, Q), R).
flatten_and(P, [[P]]):-!.


% unquote(+Form, -Form)
% given Form, replace all foo(x, quote(and(bar, goo))) by and(bar(foo(x), 
% goo(foo(x))))
% that is, make a term out of the predicate that contains the quote with
% that predicate as functor and the non-quote arguments as terms.
% then add this term as argument to the predicates inside the quote.
% what if: multiple quotes in 1 predicate, nested quotes?



% list_conjuncts(+X, -LX)
% X is a bunch of conjunctions, LX is a list of the conjuncts.
list_conjuncts(X, Y):- !,
    list_conj(X, [], Y).
list_conj(and(X, Y), L1, L2):- !,
    list_conj(X, L1, L1_5),
    list_conj(Y, L1_5, L2).
list_conj(X, Y, [X|Y]):- !.


each_list_to_ord_set(LoL, LoO):- !,
    eltos(LoL, [], LoO).
    
eltos([], X, X):- !.
eltos([X|Y], A, F):- !,
    list_to_ord_set(X, XX),
    eltos(Y, [XX|A], F).


% ************************************************************
% end of cnfization
% ************************************************************

