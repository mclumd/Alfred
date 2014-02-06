/*
File: res/process_lits.pl
By: kpurang
What: process the literals of the new formulas at a step

Todo: the functional thing

*/

% do_each_lit(+Node, +clause, +initial agenda, -final agenda)
% see main res file
% Clause is in Node

do_each_lit([], _, X, X):- !.
do_each_lit([not(bs(X))], C, I, I):- !,
    negate_lit(X, NX),
    get_name(C, NmX),
    get_assumptions(C, AssC),
    get_target(C, Tarc),
    get_new_node_name(Name),
    assert(new_node(Name, [NX], bc, [NX|AssC], [NX|Tarc], 
		    0, 1, [NmX], [], [bif])),
    index_new_node(new_node(Name, [NX], bc, [NX|AssC], [NX|Tarc], 
		    0, 1, [NmX], [], [bif])),
    get_new_node_name(Name2),
    assert(new_node(Name2, [doing_bs(Name, X)], fc, [], [], 
		    0, 1, [Name], [], [if])),
    index_new_node(new_node(Name2, [doing_bs(Name, X)], fc, [], [], 
	     0, 1, [Name], [], [if])).


% we only process bs when that is the only thing left.
do_each_lit([not(bs(X))|Y], C, I, F):- !,
    do_each_lit(Y, C, I, F).

% this will never happen, I think
do_each_lit([bs(X)], C, I, I):- !,
    get_name(C, NmX),
    get_assumptions(C, AssC),
    get_target(C, TarC),
    negate_lit(X, NX),
    get_new_node_name(Name),
    assert(new_node(Name, [NX], bc, [NX|AssC], [NX|TarC], 
		    0, 1, [NmX], [], [bif])),
    index_new_node(new_node(Name, [NX], bc, [NX|AssC], [NX|TarC], 
		    0, 1, [NmX], [], [bif])),
    get_new_node_name(Name2),
    assert(new_node(Name2, [doing_bs(Name, X)], fc, [], [], 
		    0, 1, [Name], [], [if])),
    index_new_node(new_node(Name2, [doing_bs(Name, X)], fc, [], [], 
	     0, 1, [Name], [], [if])).

% this will never happen, I think
do_each_lit([bs(X)|Y], C, I, I):- !,		  % can there be bs(X)??
    get_name(C, NmX),
    get_assumptions(C, AssC),
    get_target(C, TarC),
    negate_lit(X, NX),
    get_new_node_name(Name),
    assert(new_node(Name, [NX], bc, [NX|AssC], [NX|TarC], 
    0, 1, [NmX], [], [bif])),
    index_new_node(new_node(Name, [NX], bc, [NX|AssC], [NX|TarC], 
    0, 1, [NmX], [], [bif])),
% the following does not seem used
%    get_junk(C, J),
    make_new_node([X|Y], [NmX], [fif], D),
    get_name(D, Dname),
%    fix_parents([NmX], Dname),
    assert(D),
    get_new_node_name(Name2),
    assert(new_node(Name2, [doing_bs(Name, X)], fc, [], [], 
		    0, 1, [Name], [], [if])),
    index_new_node(new_node(Name2, [doing_bs(Name, X)], fc, [], [], 
	     0, 1, [Name], [], [if])).


/*
  why do these assume that call etc are the only things left in the
  clause? coz they will be on the rhs?
  do things work out ok if there are things after them?
*/
do_each_lit([call(_, _)], Node, I, F):-
    get_formula(Node, Form),
    copy_term(Form, FF),
    FF = [call(XX, YY)], !,
    delete_node(Node),
    get_priority(Node, Pri),
    ord_add_element(I, [[handle_call, XX, YY, nil], Pri], F).

% added mar 99
do_each_lit([call(_, _)| Y], Node, I, F):- !,
    do_each_lit(Y, Node, I, F).

/*For new calls that asserts items in the list before calling carne code*/
do_each_lit([call(_, _, _)], Node, I, F):-
    get_formula(Node, Form),
    copy_term(Form, FF),
    FF = [call(XX, YY, ZZ)], !,
    delete_node(Node),
    get_priority(Node, Pri),
    ord_add_element(I, [[handle_call, XX, YY, ZZ, nil], Pri], F).

do_each_lit([call(_, _, _)| Y], Node, I, F):- !,
    do_each_lit(Y, Node, I, F).  


% not used i think
do_each_lit([xicall(_, _)], Node, I, F):-
    get_formula(Node, Form),
    copy_term(Form, FF),
    FF = [xicall(XX, YY)], !,
    delete_node(Node),
    get_priority(Node, Pri),
    ord_add_element(I, [[handle_icall, XX, YY, nil], Pri], F).

do_each_lit([gensym(_, _, _)], Node, I, I):-
    get_formula(Node, Form),
    copy_term(Form, FF),
    FF = [gensym(XX, YY, ZZ)], !,
    get_parents(Node, Parents),
    delete_node(Node),
    do_the_gensym(XX, YY, ZZ, Parents).

% added mar 99 
do_each_lit([gensym(_, _, _)|Y], Node, I, F):- !,
    do_each_lit(Y, Node, I, F).

do_each_lit([alma(_)], Node, I, I):-
    get_formula(Node, Form),
    copy_term(Form, FF),
    FF = [alma(Termm)], !,
    delete_node(Node),
    retract(almagenda(AA)),
    assert(almagenda([Termm|AA])).
   
% added nov 24 1999

do_each_lit([reinstate(X)], Node, I, I):- 
    get_formula(Node, [reinstate(X)]), !, 
    find_node(X, Xnode),
    get_formula(Xnode, Form),
    make_new_node(Form, NN),
    get_parents(Node, Par),
    get_priority(Node, Pri),
    get_junk(Node, Junk),
    Form = [FF], 
    findall(X2, pending_contra(FF, X2, _, _), XX_XX),
    clearpending([FF|XX_XX]),
    set_parents(NN, Par, NN2),
    set_priority(NN2, Pri, NN3),
    set_junk(NN3, Junk, NN4),
    get_name(NN4, Newname),
    retract(Node),
%    get_kids(Node, C),
%   set_kids(Node, [Newname|C], Node2),
%    assert(Node2),
    assert(NN4).



% added mar 99 
do_each_lit([alma(_)|Y], Node, I, F):- !,
    do_each_lit(Y, Node, I, F).

% what happens here if the things are not bound? does it just fall through?
% lets redo it so no fall through
%KP - 081899 fixed bug - changed IF to I in second disjunct
do_each_lit([not(eval_bound(X, Y)) | Z], Node, I, F):- !,
    (all_bound(Y) -> (get_priority(Node, Pri),
		      ord_add_element(I, [[beval, Node, nil], Pri], IF),
		      do_each_lit(Z, Node, IF, F));
    do_each_lit(Z, Node, I, F)).


/*
do_each_lit([not(eval_bound(X, Y)) | Z], Node, I, F):-
    print("got here"),
    do_each_lit(Z, Node, I, F).
*/

%fixed 2nd disjunct
do_each_lit([eval_bound(X, Y) | Z], Node, I, F):- !,
    (all_bound(Y) -> (get_priority(Node, Pri),
		      ord_add_element(I, [[beval, Node, nil], Pri], IF),
		      do_each_lit(Z, Node, IF, F));
    do_each_lit(Z, Node, I, F)).


%
% these below are the actual resolutions
%
/*
  we are going to add here code that will check each atom to see if it 
  is 'pf' which is a functional thing. if it is, then look to see if we have
  a pf in the kb that does not unify with that. If we do, add not(pf) to the 
  kb.
  do we do anything if it is 'not(pf)'? nope.

  aha! this won't work! cox if we try to assert pf with the intention of it
  killing the old value, we will add 'not(pf)' in the kb leading to a 
  contra. so we need to look for pfs that are not alone. This is too
  complex.

  what we want is that if we have 'not(pf(a)) -> q', and we have 'pf(b)' in
  the kb, we wnat to get 'q'. the formula will eb clausified into 'pf(a) |
  q'. then we can't distinguish between asserting 'pf(a)' and this being
  part of a formula.

*/

do_each_lit([X|Y], Node, I, F):-
    gp([X], [], [[Pred, minus]]),
    negate(X, XN),
    match_form(XN, plus, Set), !,
%    pred_to_node(Pred, plus, Set), !,
%    func_node(Pred, Set, _), !,
    make_new_tasks(Node, Set, I, IF),
    do_each_lit(Y, Node, IF, F).
do_each_lit([X|Y], Node, I, F):-
    gp([X], [], [[Pred, plus]]),
    negate(X, XN),
    match_form(X, minus, Set), !,
%    pred_to_node(Pred, minus, Set), !,
%    func_node(Pred, _, Set), !,
    make_new_tasks(Node, Set, I, IF),
    do_each_lit(Y, Node, IF, F).
do_each_lit([X|Y], Node, I, F):- !,
%    print('do_each_node fallthrough '), print([X|Y]), nl,
    do_each_lit(Y, Node, I, F).


clearpending([]) :- !.
clearpending([X|Y]):- !,
    retractall(pending_contra(X, _, _, _)),
    clearpending(Y).
