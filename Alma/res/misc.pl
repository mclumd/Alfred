/*
File: res/misc.pl
By: kpurang
What:  miscellaneous code

Todo: see if this duplicates code elsewhere

*/

% negate_lit(+lit, -negated literal)
negate_lit(not(X), X):- !.
negate_lit(X, not(X)):- !.



%
% actually does the gensym.
% does the af keep track of the parents of this?
do_the_gensym([], [], Z, P):- !,
    af_lwp(Z, P).
do_the_gensym([X|Y], [S|D], Z, P):-
    gensym(S, X),
    do_the_gensym(Y, D, Z, P).


%
% this replace_call thing does not look like it is used!
%

% replace_call(+Node, +lit, -Newnode)
% given a node, its clause will contain a literal that unifies with
% call(lit). replace this literal with just X. 
% change the name to new_name, change the parent to the name of Node
replace_call(node(A0, A1, A2, A3, A4, A5, A6, _, A8, A9), X, 
	     new_node(Name, B1, A2, A3, A4, A5, A6, [A0], A8, A9)):- !,
    get_new_node_name(Name),
    index_new_node(new_node(Name, B1, A2, A3, A4, A5, A6, [A0], A8, A9)),
    replace_call_lit(A1, X, B1).

% replace_call_lit(+Clause, +lit, -F)
% look in clause for a literal that unifies with call(lit)
% replace this by lit
% assume that there is such a literal
replace_call_lit([X|Y], L, [L|Y]):-
    X = call(L), !.
replace_call_lit([X|Y], L, [not(L)|Y]):-
    X = not(call(L)), !.
replace_call_lit([X|Y], L, [X|I]):- !,
    replace_call_lit(Y, L, I).

filter_atoms([], X, X):- !.
filter_atoms([X|Y], Z, ZZ):-
    find_node(X, NX),
    get_formula(NX, [AX]), !,
    get_name(NX, Name),
    filter_atoms(Y, [[AX, Name]|Z], ZZ).
filter_atoms([_|Y], Z, ZZ):-
    filter_atoms(Y, Z, ZZ).


% get_bigger_assumptions(+N1, +N2, -ASS)
% N1, N2 are nodes
% if assumtions of one are a subset of the others, return the bigger set
% else fail.
get_bigger_assumptions(node(_, _, _, A1, _, _, _, _, _, _),
		       node(_, _, _, A2, _, _, _, _, _, _), R):-
    (subset(A1, A2); subset(A2, A1)), !,
    union(A1, A2, R).

% delete_node(+Node)
% see in dbman.pl
% is of interest to all


% verify_holds(+Y)
% Y is a list of literals.
% negate each of them and check that it is present in the db.

/*
THIS BELOW WILL NOT WORK COZ THERE IS NO MORE PRED_TO_NODE
BUT I DONT THINK IT IS BEING USED ANYWAY



verify_holds([]):- !.
verify_holds([not(X)|Y]):- !,
    functor(X, XF, _),
    pred_to_node(XF, plus, List),
%    func_node(XF, _, List),
    verify_ident(List, [X]),
    verify_holds(Y).
verify_holds([X|Y]):- !,
    functor(X, XF, _),
%    func_node(XF, List, _),
    pred_to_node(XF, minus, List),
    verify_ident(List, [X]),
    verify_holds(Y).
verify_ident([], _):- !, fail.
verify_ident([X|Y], Z):-
    find_node(X, XN),
    get_form(XN, XF),
    XF == Z, !.
verify_ident([X|Y], Z):- !,
    verify_ident(Y, Z).

*/
