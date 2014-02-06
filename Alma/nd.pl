/*
File: nd.pl
By: kpurang
What: natural deduction specific stuff
      
Todo: actually implement it!!

*/
ir_init:- true.

% get_predicates(+Node, -[Predicate, Pol] list)
% given a node, return a list of [predicate, polarity] for predicates in
% the formula. In this case polarity is always plus.
get_predicates(N, P):- !,
    get_form(N, NF),
    gp(NF, [], P).
gp(forall(X, Y), I, F):- !,
    gp(Y, I, F).
gp(exists(X, Y), I, F):- !,
    gp(Y, I, F).
gp(not(X), I, F):- !,
    gp(X, I, F).
gp(quote(X), I, I):- !.
gp(and(X, Y), I, F):- !,
    gp(X, I, II),
    gp(Y, II, F).
gp(or(X, Y), I, F):- !,
    gp(X, I, II),
    gp(Y, II, F).
gp(if(X, Y), I, F):- !,
    gp(X, I, II),
    gp(Y, II, F).
gp(X, I, [[Xp, plus]|I]):- !,
    functor(X, Xp, _).
    

% convert_form(+Form, - list of forms)
% given a formula, return it in a list
convert_form(Form, [Form]).
