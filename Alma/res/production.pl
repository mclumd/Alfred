/*
File: res/production.pl
By: kpurang
What: this is the code to deal with production riles

Todo: maybe do the productions elsewhere- not inalma
      the functional thing

  modified jun 12 1999 kpurang:
    added more debug output
    push evals that fail to the end of the production

*/


produc(N1, N2):-
    get_actual_nodes([N1, N2], [AN1, AN2]),
    get_form(AN1, Nf1), get_form(AN2, Nf2),
    (Nf1 = [_] ; Nf2 = [_]), 
    resolve(Nf1, Nf2, [], [[R, _]]), 
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Production '),
     print(DS, resolve(Nf1, Nf2, [], [[R, _]])), nl(DS)); true),
    !,
% since one of the two is a single atom, there will be at most one resolvent
    get_junk(AN1, [JN1|_]), get_junk(AN2, [JN2|_]),
    ((JN1 = fif) -> (P = [N1, N2]); (P = [N2, N1])),
    continue_prod(R, P).
produc(_, _):-!.

continue_prod([], _):-!.
continue_prod([conclusion(reinstate(X))], P):- !, 
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Conclusion '),
     print(DS, X), nl(DS)); true),
    find_node(X, Xnode),
    get_formula(Xnode, Form),
    make_new_node(Form, NN),
    Form = [FF], 
    findall(X2, pending_contra(FF, X2, _, _), XX_XX),
    clearpending([FF|XX_XX]),
    add_parents(NN, [P], NN2),
    set_priority(NN2, 1, NN3),
    set_junk(NN3, [if], NN4),
    get_name(NN4, Newname),
%    get_kids(Node, C),
%   set_kids(Node, [Newname|C], Node2),
%    assert(Node2),
    assert(NN4).
continue_prod([conclusion(X)], P):- !, 
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Conclusion '),
     print(DS, X), nl(DS)); true),
    (X = eval_bound(_, _) -> make_new_node([X], 1, [if], Node);
    make_new_node([X], 1, [if], Node)),
    add_parents(Node, [P], NNode),
    assert(NNode).
continue_prod([conclusion(X)|Y], P):- 
    \+ Y = [], !, 
    append(Y, [conclusion(X)], Z),
    continue_prod(Z, P).
continue_prod([not(eval_bound(X, Y))|Rest], P):-
    all_bound(Y), 
    (debug_level(3) -> (debug_stream(DS), print(DS, 'going to Neg Eval: '),
     print(DS, X), nl(DS)); true),

    on_exception(EX, findall([X, Rest], call(X), Res), error_beval(X, EX)), !,
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Neg Eval: '),
     print(DS, Res), nl(DS)); true),
    strip_heads(Res, [], Tails),
    mult_continue_prods(Tails, P).
continue_prod([not(eval_bound(X, Y))|Rest], P):- !,
    (debug_level(3) -> (debug_stream(DS), print(DS, 'not bound Neg Eval: '),
     print(DS, [X, Y]), nl(DS)); true),

    append(Rest, [not(eval_bound(X, Y))], More),
    continue_prod(More, P).
continue_prod([eval_bound(X, Y)|Rest], P):-
    all_bound(Y), 
    on_exception(EX, findall([X, Rest], call(X), Res), error_beval(X, EX)), !,
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Pos Eval: '),
     print(DS, Res), nl(DS)); true),
    continue_prod(Rest, P).
continue_prod([eval_bound(X, Y)|Rest], P):- !,
    append(Rest, [eval_bound(X, Y)], More),
    continue_prod(More, P).
continue_prod([X|Y], P):-
    get_atoms(X, AXL),
    \+ AXL = [], !,				  % need to skip not quit
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Candidates: '),
     print(DS, AXL), nl(DS)); true),
    try_each_atom([X|Y], AXL, P).
continue_prod(_, _):-!.

mult_continue_prods([], _):- !.
mult_continue_prods([X|Y], P):- !,
    (debug_level(3) -> (debug_stream(DS), print(DS, 'MultContinue '),
     print(DS, [X|Y]), nl(DS)); true),
    continue_prod(X, P),
    mult_continue_prods(Y, P).

get_atoms(not(X), AXL):- !,
    functor(X, XP, _),
    negate(X, XN),
    match_form(X, plus, AX),
    match_new_form(X, plus, AXN),
    append(AX, AXN, AXX),
    filter_atoms(AXX, [], AXL).
get_atoms(X, AXL):- !,
    functor(X, XP, _),
    match_form(X, minus, AX),
    match_new_form(X, minus, AXN),
    append(AX, AXN, AXX),
    filter_atoms(AXX, [], AXL).

try_each_atom(_, [], _):-!.
try_each_atom(Y, [[L, LName]|Rest], P):-
    resolve([L], Y, _, X), 
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Resolving '),
     print(DS, resolve([L], Y, _, X)), nl(DS)); true),
    \+ X = [], !,
    X = [[R, _]],
    append(P, [LName], PP),
    continue_prod(R, PP),
    try_each_atom(Y, Rest, P).
try_each_atom(Y, [_|Rest], X):- !,
    try_each_atom(Y, Rest, X).

