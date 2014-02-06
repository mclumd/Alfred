/*
File: res/eval.pl
By: kpurang
What: code to do evaluation of formulas


*/

%%%
% beval(Node)
% if node is a production rule, exit WHY????
% if formula is a single positive eval:
%  evaluate the \phi, succeeds: assert the set of successful bindings
%                     fails: assert \phi and not \phi to get a contra
% if formula is a single negative eval:
%  evaluate the \phi, fails: assert \phi
%                     succeeds: assert the set of successful \phi and 
%                       not \phi to get a contra
% else walk down clause looking for a +/- eval.
% if find +, evaluate \phi
%    succeds: for each successful binding, make a new formula with the
%             variables bound appropriately without the eval
%      the above is not right.
%    succeeds: do nuffin.
%    fails: bind appropriately, remove \phi, assert new formula.
% if find -, evaluate \phi
%    succeds: for each successful binding, make a new formula with the
%             variables bound appropriately without the eval
%    fails: do nuffin.
%
%
% have to negate smartly. no need to. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    on_exception(EX, findall([PZ, XX], call(XX), Res), error_beval(XX, EX)),
%
% there is a problem here: say a formula consists of 2 evals, one of which
% can succeed. we must make sure the one that can succeed gets evaluated
% else the thing just dies. this seems to mean that we have to look for
% multiple evals. while the task lister makes sure things are bound before
% requesting a beval, once it gets here, we do not know anymore which eval
% is bound. have to check for a bound eval while finding the eval. is that
% sufficient?

beval(N):-
    get_junk(N, [fif|_]), !.
beval(N):-
    get_formula(N, [not(eval_bound(Phi, _))]),
    on_exception(EX, findall([Phi], call(Phi), Res), error_beval(Phi, EX)), !,
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Eval '),
			print(DS, Res), nl(DS)); true),
    beval_c1(N, Res, Phi).
beval(N):-
    get_formula(N, [eval_bound(Phi, _)]), !,
    on_exception(EX, findall([Phi], call(Phi), Res), error_beval(Phi, EX)), !,
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Eval '),
			print(DS, Res), nl(DS)); true),
    beval_c2(N, Res, Phi).
beval(N):-
    get_formula(N, F),
    get_parents(N, Par),
    find_eval(F, [], Car, [E|Cdr]), !,
    append(Car, Cdr, Rest),
    beval_c3(N, Par, E, Rest).
%
% assert the negation of \phi
%
beval_c1(N, [], Phi):- !,
    negate_lit(Phi, NPhi),
    clone_node(N, NC),
    delete_node(N),
    set_formula(NC, [NPhi], N1),
    set_ass(N1, [], N5),
    assert(N5),
    index_new_node(N5), true.

beval_c1(N, [X|Y], Phi):- !, beval_rc1(N, [X|Y], Phi).
beval_rc1(N, [], _):- !,
    clone_node(N, NN),
    get_formula(N, [not(eval_bound(P, _))]),
    set_formula(NN, [not(P)], N2),
    get_name(N, Name),
    add_parents(N2, [Name], N3),
    assert(N3),
    index_new_node(N3),
    delete_node(N).
beval_rc1(N, [X|Y], Phi):- !,			  % we assert the contras
    clone_node(N, NC),
    get_parents(N, PP), 
    set_formula(NC, X, N1),
    set_ass(N1, [], N2),
    add_parents(N2, PP, N5),
    assert(N5),
    index_new_node(N5),
    beval_rc1(N, Y, Phi).

    
beval_c2(N, [], Phi):- !,			  % ass phi, not phi
    negate_lit(Phi, NPhi),
    get_parents(N, PP), get_type(N, T), get_junk(N, J),
    delete_node(N),
    make_new_node([NPhi], NoPhi),
    get_name(NoPhi, Nphiname),
    set_priority(NoPhi, 1, N2),
    set_parents(N2, PP, N3), set_type(N3, T, N4), set_junk(N4, J, N5),
%    fix_parents(PP, Nphiname),
    assert(N5),
    make_new_node([Phi], Phi2),
    get_name(Phi2, N2name),
    set_priority(Phi2, 1, Np2),
    set_parents(Np2, PP, Np3), set_type(Np3, T, Np4), set_junk(Np4, J, Np5),
%    fix_parents(PP, N2name),
    assert(Np5), true.
beval_c2(N, L, _):- !,			  % ass all bindings
    get_parents(N, NP),
    get_junk(N, Junk), get_type(N, Type),
    delete_node(N),
    ass_litswp(L, NP, Junk, Type).

%
% given a node, its parent, an eval, the rest of the clause the eval is
% from, do the appropriate thing.
%
beval_c3(N, Par, eval_bound(XX, _), Rest):-
    on_exception(EX, findall([XX, Rest], call(XX), Res), 
		 error_beval(XX, EX)), !,
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Eval '),
			print(DS, Res), nl(DS)); true),
    beval_c3_1(N, Par, Res, Rest).
beval_c3(N, Par, not(eval_bound(XX, _)), Rest):-
    on_exception(EX, findall([XX, Rest], call(XX), Res), 
		 error_beval(XX, EX)), !,
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Eval '),
			print(DS, Res), nl(DS)); true),
    beval_c3_2(N, Par, Res, Rest).

% beval_c3_1(+N, +Par, +Res, +Rest)
% case that the eval was positive. Res is a list of pairs: [theformula,
% therestoftheclause] Rest is the formula without the eval
%
beval_c3_1(N, Par, [], Rest):- !,
    get_type(N, Type), get_junk(N, Junk),
    make_new_node(Rest, NN),
    get_name(NN, Nname),
    set_priority(NN, 1, NX),
    set_parents(NX, Par, N1), set_type(N1, Type, N2), set_junk(N2, Junk, N3),
%    fix_parents(Par, Nname),
    assert(N3).
beval_c3_1(_, _, _, _):- !.

% beval_c3_2(+N, +Par, +Res, +Rest)
% case that the eval was negative. Res is a list of pairs: [theformula,
% therestoftheclause] Rest is the formula without the eval
%
% what is Rest for???
beval_c3_2(N, Par, Res, _):- 
    strip_heads(Res, [], Shres), !,
    get_type(N, Type), get_junk(N, Junk),
    ass_litswp(Shres, Par, Junk, Type).
beval_c3_2(_, _, [], _):- !.


% #####

%
% given a clause, split the clause into 1. the prefix 2. the suffix which
% starts with an eval
%
find_eval([], _, _, _):- 
    print(user_error, 'Eval not found'),
    nl(user_error), halt.
find_eval([not(eval_bound(Z, ZZ))|Y], IA, IA, [not(eval_bound(Z, ZZ))|Y]):- 
    all_bound(ZZ), !.
find_eval([eval_bound(Z, ZZ)|Y], IA, IA, [eval_bound(Z, ZZ)|Y]):- 
    all_bound(ZZ), !.
find_eval([X|Y], IA, FA, CD):- !,
    find_eval(Y, [X|IA], FA, CD).
    
error_beval(X, E):- !,
    print(user_error, 'Error in '), print(user_error, X), nl(user_error),
    print(user_error, E), nl(user_error).


