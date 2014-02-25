/*
 File: misc.pl
 By: kpurang

 What: miscellaneous things including:
       printing stuff
       positive introspection
       gather_all

 Todo: fix the printing. Looks funny sometimes.
       make printing more parseable
       separate the printing from the rest

*/

%:- ensure_loaded(library(strings)).

print_agenda(S, X):- !,
    print_task(S, X).
print_task(_, []):- !.
print_task(S, [T|TT]):- !,
    print(S, T), nl(S),
    print_task(S, TT).


show_db:- !,
    findall([A1, J, N], node(N, A1, _, [], _, _, _, _, _, J), Ann),
    print_each(Ann).
print_each([]):- nl, !.
print_each([[X, XJ, XN]|Y]):- !,
    print(XN), print(': '),
    separate_signs(X, [], Plus, [], Minus),
    (Plus = [] -> print_antecedents_or(Minus);
    (reverse_signs(Minus, [], Inus),
    print_antecedents(Inus),
    (Inus = [] -> true ; (XJ = [fif] -> print(' -f-> ');
      (XJ = [bif] -> print(' -b-> '); print(' ---> ')))),
    print_consequents(Plus))), nl,
    print_each(Y).

separate_signs([], X, X, C, C):- !.
separate_signs([not(X)|Y], IP, IPP, IM, [not(X)|IMM]):- !,
    separate_signs(Y, IP, IPP, IM, IMM).
separate_signs([X|Y], IP, [X|IPP], IM, IMM):- !,
    separate_signs(Y, IP, IPP, IM, IMM).

reverse_signs([], M, M):- !.
reverse_signs([X|Y], M, [NX|MX]):- !,
    negate_lit(X, NX),
    reverse_signs(Y, M, MX).

print_antecedents([]) :- !.
print_antecedents([X]):- !,
    print(X).
%
% kp changed this on 05/11/00 coz of printing problem.
%
%
print_antecedents([X|Y]):- !,
    print(X), print(' & '),
    print_antecedents(Y).

print_antecedents_or([]) :- !.
print_antecedents_or([X]):- !,
    print(X).
print_antecedents_or([X|Y]):- !,
    print(X), print(' | '),
    print_antecedents_or(Y).


print_consequents([]) :- !.
print_consequents([X]):- !,
    print(X).
print_consequents([X|Y]):- !,
    print(X), print(' | '),
    print_consequents(Y).


show_bdb:- !,
    findall([A1, X, J, N], (node(N, A1, _, X, _, _, _, _, _, J), \+ X = []), Ann),
    print_each(Ann).
print_each([]):- nl, !.
print_each([[X, XA, XJ, XN]|Y]):-
    print(XN), print(': '),
    print_assumptions(XA),
    separate_signs(X, [], Plus, [], Minus),
    (Plus = [] -> print_antecedents(Minus);
    (reverse_signs(Minus, [], Inus),
    print_antecedents(Inus),
    (Inus = [] -> true ; 
     (XJ = [fif] -> print(' -f-> ');
      (XJ = [bif] -> print(' -b-> '); print(' ---> ')))),
    print_consequents(Plus))), nl,
    print_each(Y).

print_assumptions([]):- !, print(': ').
print_assumptions([X|Y]):-
    print(X), print(' '),!,
    print_assumptions(Y).

sdb:- show_db, print('---Back Searches---'), nl, nl, show_bdb, ttyflush.


%
% do same as the print things above, but put result in a list instead.
%

strprint(X, Y, Z):- !,
    t2s(X, R),
    append(Y, R, Z).

%
% note that second arg has to be the type of if.
%
% we ignore backward searches for now.
%
% big problem is to turn terms into strings!
% some old code might help, if I can find it.
%
sprint_one([XC, XJ], S):- !,
    copy_term(XC, X),
    separate_signs(X, [], Plus, [], Minus),
    (Plus = [] -> sprint_antecedents_or(Minus, [], S);
    (reverse_signs(Minus, [], Inus),
    sprint_antecedents(Inus, [], S1),
    (Inus = [] ->  S1 = S2 ; 
      (XJ = fif -> strprint(' -f-> ', S1, S2);
         (XJ = bif -> strprint(' -b-> ', S1, S2); 
            strprint(' ---> ', S1, S2)))),
     sprint_consequents(Plus, S2, S))).

sprint_antecedents([], X, X) :- !.
sprint_antecedents([X], Y, Z):- !,
    strprint(X, Y, Z).
sprint_antecedents([X|Y], ZZ, ZZZ):- !,
    strprint(X, ZZ, ZZa), strprint(' & ', ZZa, ZZb),
    sprint_antecedents(Y, ZZb, ZZZ).

sprint_antecedents_or([], X, X) :- !.
sprint_antecedents_or([X], Y, Z):- !,
    strprint(X, Y, Z).
sprint_antecedents_or([X|Y], ZZ, ZZZ):- !,
    strprint(X, ZZ, ZZa), strprint(' | ', ZZa, ZZb),
    sprint_antecedents_or(Y, ZZb, ZZZ).


sprint_consequents([], C, C) :- !.
sprint_consequents([X], C, V):- !,
    strprint(X, C, V).
sprint_consequents([X|Y], V, B):- !,
    strprint(X, V, F), strprint(' | ', F, G),
    sprint_consequents(Y, G, B).


/*

nov 3 1998:
  add commas beteween arguments
  do something about the weird var naming thing.
*/

/*
var2cons(X, XC):-
    copy_term(X, XC),
    get_vars(XC, [], XCV),
    bind_vars(XCV).
*/

var2cons(X, X):-
    get_vars(X, [], XCV), !,
    bind_vars(XCV).

get_vars(Y, X, X):- \+ var(Y), Y = [], !.
get_vars(XY, C, V):- \+ var(XY), 
    XY = [X|Y], !,
    get_vars(X, C, D),
    get_vars(Y, D, V).

get_vars(X, Y, [X|Y]):-
    var(X), !.
get_vars(Term, X, Y):- 
    functor(Term, _, D), !,
    get_each_arg(Term, D, X, Y).
get_vars(_, X, X):- !.

get_each_arg(_, 0, X, X):- !.
get_each_arg(T, D, X, Y):-
    arg(D, T, A), !,
    get_vars(A, X, AX),
    C is D - 1,
    get_each_arg(T, C, AX, Y).

bind_vars([]):-!.
bind_vars([X|Y]):-
    var(X), !,
    gensym('X', X),
    bind_vars(Y).
bind_vars([_|Y]):- !,
    bind_vars(Y).

t2s(Term, Result):- !,
        var2cons(Term, TT),
	term2str(TT, [], Result).



term2str([], X, X):- !, true.

term2str(L, B, A):-
    ((L = [X|Y], \+ var(L)) -> (append(B, [91], BX),
		   term2strlst(L, BX, A)); 
    (atom(L) -> (name(L, XN),
		 append(B, XN, A)); 
    (number(L) -> (name(L, XN),
		   append(B, XN, A)); 
    (L=..[X|Y] -> (name(X, XN),
		   append(XN, [40], XNN),
		   append(B, XNN, Sometime),
		   term2strcom(Y, [], Result),
		   append(Result, [41], RR),
		   append(Sometime, RR, A)); true)))), !.


% sp 32 , 44
term2strcom([], Y, X):- !, append(X, [44, 32], Y).
term2strcom([], X, X):- !, print(problem), nl.

term2strcom([X|Y], Before, After):- !,
    term2str(X, [], AA),
    append(Before, AA, A1),
    append(A1, [44, 32], A2),
    term2strcom(Y, A2, After).


term2strlst([], B, A):- !,
    append(XX, [44, 32], B), 
    append(XX, [93], A).
term2strlst([X], B, A):- !,
    term2str(X, B, C),
    append(C, [93], A).
term2strlst([X|Y], B, A):- !,
    term2str(X, B, C),
    append(C, [44, 32], D),
    (Y = [Z|Q] -> term2strlst(Y, D, A); 
    (term2str(Y, [], YY), 
     append(D, YY, YDY), 
     append(YDY, [93], A))).

/*
term2strlst([], B, A):- !,
    (append(XX, [44, 32], B);
     XX = B), 
    append(XX, [93], A).
term2strlst([X], B, A) :- !,
    term2str(X, B, C),
    append(C, [93], A).
term2strlst([X|[Y]], B, A):- !,
    term2str(X, B, C),
    append(C, [44, 32], D),
    term2strlst([Y], D, A).
term2strlst([X|Y], B, A):- !,
    term2str(X, B, C),
    append(C, [124], D),
    term2strlst([Y], D, A).
*/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% here we have the evaluable things that need to be in al
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% introspection.
% we have only positive introspection. negative will be failure to
% get positive.
% we can only introspect literals. NOT FORMULAS or clauses.
%
% pos_int(F) succeeds with F bound 

pos_int(F):-
    gp([F], [], [[Pred, plus]]), !,
    match_form(F, plus, Set),
%    pred_to_node(Pred, plus, Set),
    pick_one(Set, One),
    copy_term(F, FF),
    find_node(One, ON),
    get_formula(ON, [ONF]),
    subsumes_chk(FF, ONF),
    subsumes_chk(ONF, FF),
    F = ONF.
pos_int(F):-
    gp([F], [], [[Pred, minus]]), !,
    F = not(Fnot),
    match_form(Fnot, minus, Set),
%    pred_to_node(Pred, minus, Set),
    pick_one(Set, One),
    copy_term(F, FF),
    find_node(One, ON),
    get_formula(ON, [ONF]),
    subsumes_chk(FF, ONF),
    subsumes_chk(ONF, FF),
    F = ONF.

pick_one([], _):- fail.
pick_one([X|Y], X).
pick_one([X|Y], Z):-
    pick_one(Y, Z).


% this version UNIFIES rather than does mutual subsumption
% do i perhaps need to check all possible matches?

%
% ERROR here!!!
%

pos_int_u(F):-
    gp([F], [], [[Pred, plus]]), !,
    match_form(F, plus, Set),
%    pred_to_node(Pred, plus, Set),
    pick_one(Set, One),
    copy_term(F, FF),
    find_node(One, ON),
    get_formula(ON, [ONF]),
    FF = ONF,
%    subsumes_chk(FF, ONF),
%    subsumes_chk(ONF, FF),
    F = ONF.
pos_int_u(F):-
    gp([F], [], [[Pred, minus]]), !,
    F = not(Fnot),
    match_form(Fnot, minus, Set),
%    pred_to_node(Pred, minus, Set),
    pick_one(Set, One),
    copy_term(F, FF),
    find_node(One, ON),
    get_formula(ON, [ONF]),
    FF = ONF,
%    subsumes_chk(FF, ONF),
%    subsumes_chk(ONF, FF),
    F = ONF.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pos_int(Form, Time)
% Form is either a literal or a clause written as a list of literals.
% if the form is in the database at time Time and is not distrusted,
% this will succeed.
% vars are existentially quantified by default
% nononono. is misleading. if we are asked for p(S), make sure p(S) is in
% the kb, not anything else.
% so once we get the list, we need to find mutual subsumers.

pos_int(X, Time):-
    var(Time), !,
    step_number(Now),
    pos_int_interval(X, 1, Now, Time).
pos_int([H|T], Time):- !,
    sort([H|T], S),
    gather_all(S, Time, Res),
    subsume_check_list(S, Res).
%    (Res = [] -> fail; true).
pos_int(L, Time):- !,
    gather_all([L], Time, Res),
    subsume_check_list([L], Res).
%    (Res = [] -> fail; true).

pos_int_interval(X, S, E, S):-
    S < E,
    pos_int(X, S).
pos_int_interval(X, S, E, U):-
    T is S + 1,
    T < E, 
    pos_int_interval(X, T, E, U).
    

subsume_check_list(_, []):- !, fail.
subsume_check_list(F, [G|Rest]):- !,
    ((subsumes_chk(F, G), subsumes_chk(G, F)) -> true;
       subsume_check_list(F, Rest)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we first do a gather_all
% can only gather literals NOT FORMULAS OR CLAUSES!!!
% gather_all(+F, -L) 
% F is a literal
% L is a list of literals that are subsumed by F

gather_all(F, L):-
    gp([F], [], [[Pred, plus]]), !,
    match_form(F, plus, Set),
%    pred_to_node(Pred, plus, Set),
    gather_wheat(F, Set, [], L).
gather_all(F, L):-
    gp([F], [], [[Pred, minus]]), !,
    F = not(FFR), 
    match_form(FFR, minus, Set),
%    pred_to_node(Pred, minus, Set),
    gather_wheat(F, Set, [], L).

gather_wheat(_, [], X, X):- !.
gather_wheat(Fp, [X|Y], I, F):-
    copy_term(Fp, FF),
    find_node(X, XN),
    get_formula(XN, [XF]),
    subsumes_chk(FF, XF), !,
    gather_wheat(Fp, Y, [XF|I], F).
gather_wheat(Fp, [X|Y], I, F):- !,
    gather_wheat(Fp, Y, I, F).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% feb 01
% we do gather_all with time. Note that this will NOT owrk for the
% current time, but it should work for clauses too.
%
% this is not a very efficient implementation. a better implementation
% will take too long to write.

gather_all(Clause, Time, _):-
    step_number(X),
    X =< Time, fail, !.
gather_all([H|T], Time, List):- !,
    remember_them([H|T], Time, [], 1, List).
gather_all(Clause, Time, List):- !,
    remember_them([Clause], Time, [], 1, List).

% remember_them(Clause, Target_time, Current_list, Time_to_look_at, Result)

remember_them(Clause, Target, Out, Look, Out):- 
    Look > Target, !.
remember_them(Clause, Target, In, Look, Out):- !,
    hist_add(Look, Adds),
    findall(Clause, member(Clause, Adds), QQ),
    ord_union(In, QQ, M1),
    hist_del(Look, Dels),
    findall(Clause, member(Clause, Dels), DD),
    ord_subtract(M1, DD, M2),
    Next is Look + 1,
    remember_them(Clause, Target, M2, Next, Out).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% all_bound(+List)
% are all the elements in the list bound?
%
all_bound([]):- !, true.
all_bound([X|Y]):-
    \+ var(X), !,
    all_bound(Y).
all_bound(_):- !, fail.

% compute_priority(+Node, +Node, +Direction, -Priority)
compute_priority(_, _, _, 1).


%
% given a list of pairs, return a list of the 2nd elements
%
strip_heads([], X, X):- !.
strip_heads([[_, Wheat]|Y], I, O):- !,
    strip_heads(Y, [Wheat|I], O).


% merge_forms(+In, -Out)
% In is a list of clauses.
% Out is the list merged.

merge_forms([], []):- !.
merge_forms([X|Y], [MX|Z]):- !,
    merge_form(X, MX),
    merge_forms(Y, Z).

% merge_form(+X, -Y)
% X is a clause
% Y is the clause with repetitions eliminated.
merge_form(X, Y):- !,
    sort(X, SX),
    unrepeat(SX, [], Y).

% unrepeat(+X, H, -Y)
% X is a list of literals, possibly eith repetitions
% Y is the same list with no repetitions.
% H is a rtemp list
unrepeat([], H, H):- !.
unrepeat([X], H, [X|H]):- !.
unrepeat([X, Y|Z], H, R):- 
    X == Y, !,
    unrepeat([Y|Z], H, R).
unrepeat([X, Y|Z], H, R):- !,
    unrepeat([Y|Z], [X|H], R).


reverse_pol(plus, minus).
reverse_pol(minus, plus).




