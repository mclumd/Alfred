/*
File: res/process_tasks.pl
By: kpurang
What:  this takes care of inferential tasks


*/


                   
% agenda is a list of [task, priority]
% task is [rulename, formula] where formula is a formula on which the rule
% is to be applied. not quite.

% list_tasks(+New, -All)
% New: list of new nodes
% cross-product the new nodes with the inference rules,
% throw out the nonsensical combinations,
% append this to the old agenda.
%
% for each new node:
%  if the first literal is a +/-bs(X),
%    start a back chain for X
%    add (X -> bs(X))
%       do the right thing with the polarity.
%    return
%  if the first literal is a +/-call(X),
%    call(X) as a prolog program (or put on task list to do later?)
%    add result as a new node
%    add as new a node similar to the previous but with X iso call(X)
%       do the right thing with the polarity.
%    return
% **** we don't need to do all of the above now
% **** the call is restricted to be on the rhs of a if-then
% **** so we do the call only if it is the only thing in the clause
% **** no need to do the replace business.
% **** but leave the replace code. things might break otherwise.
%  else
%    look for all nodes that have a predicate same as that of Y but of
%      opposite polarity.
%    if both the nodes are fc, task=[fcres, node, node, fc]
%    if either node is bc, task=[bcres, node, node, bc]

% Maybe add the following:
%  if either node is fif, task = [production, node, node, ??]
%


%% all these will be in the inference rule specific files.

% list_tasks(+New, -All)
% cross-product the new nodes with the inference rules,
% throw out the nonsensical combinations,
% append this to the old agenda.

% order_tasks(+Unordered, -Ordered)
% Sort the Unordered agenda according to priority

% do_tasks(+Agenda)
% while there is still time, pop tasks off the agenda, execute them.


list_tasks(New, All):- !,
    retract(agenda(Agl)),
    list_to_ord_set(Agl, Ag),
    list_tasks(New, Ag, All).
%    assert(agenda(All)).
list_tasks([], X, X):- !.
list_tasks([X|Y], I, F):- !,
    get_form(X, XF),
    do_each_lit(XF, X, I, L),
    list_tasks(Y, L, F).

% make_new_tasks(+Node, +Set, +I, -F)
% Node is a node, 
% set is a set of nodes that potentially unify with Node
% I is the initial and F is the final set of tasks (agenda)
%
make_new_tasks(_, [], I, I):- !.
%
% october 24 1998
% the following is commented out for the next bloxk of code.
% intention is to identify situations where either node is a fif and
% then make a 'produc' task
%
% come to think of it, what about atoms? are they f/b/if? should be plain
% if, I guess.
/*
make_new_tasks(Node, [X|Y], I, II):-
    get_direction(Node, fc),
    (node(X, _, fc, _, _, _, _, _, _, [if|_]); 
    node(X, _, fc, _, _, _, _, _, _, [fif|_])), 
    (Node = node(Name, _, fc, _, _, _, _, _, _, [if|_]);
    Node = node(Name, _, fc, _, _, _, _, _, _, [fif|_])),
    \+ member([[fcres, X, Name, fc],_], I), !, 
    compute_priority(X, Name, fc, P),
    ord_add_element(I, [[fcres, Name, X, fc],P], IXC),
    make_new_tasks(Node, Y, IXC, II).
*/
%%%%% this is for productions
/*

  should we ever allow resolutions between the same clause? this
  implies that the clause is a tautology, if the bindings are
  right. if that is true, and it looks like it is, we should either
  detect tautologies and remove them, or prevent this sort of task
  from being listed. the last one is easier. mebbe do this then. is it
  ever useful to resolve something with itself?  well assume never.
  so KP CHANGED THAT 04/25/00. ADDED THE FOLL.

*/

make_new_tasks(Node, [X|Y], I, II):- 
    get_name(Node, X), !,
    make_new_tasks(Node, Y, I, II).

make_new_tasks(Node, [X|Y], I, II):-
%    print('Making a produc task '), nl,
    get_direction(Node, fc),
    (node(X, _, fc, _, _, _, _, _, _, [fif|_]); 
%
% SHOULDNT BE USING THIS, USE THE ACCESS PREDS
%
     Node = node(Name, _, fc, _, _, _, _, _, _, [fif|_])),
     Node = node(Name, _, fc, _, _, _, _, _, _, _),
    \+ member([[produc, X, Name, fc],_], I), !, 
    compute_priority(X, Name, fc, P),
    ord_add_element(I, [[produc, Name, X, fc],P], IXC),
%    print('Added '), print([[produc, Name, X, fc],P]), nl, 
    make_new_tasks(Node, Y, IXC, II).
%%%%%
%%%%% this is for pure fcs (will we have any?)
make_new_tasks(Node, [X|Y], I, II):-
    get_direction(Node, fc),
    node(X, _, fc, _, _, _, _, _, _, [if|_]),
    Node = node(Name, _, fc, _, _, _, _, _, _, [if|_]),
    \+ member([[fcres, X, Name, fc],_], I), !, 
%    print('Making a regular if task '), nl,
    compute_priority(X, Name, fc, P),
    ord_add_element(I, [[fcres, Name, X, fc],P], IXC),
    make_new_tasks(Node, Y, IXC, II).
%%%%%
/*  
  aug 18 00
  something wrong here.
  i want to do a bs if
    either node is bc OK
    both nodes are bif or if??? well, ok

    hmmm need to make suyre the X is not hijacked by some other rule...
*/
make_new_tasks(Node, [X|Y], I, II):-
    (node(X, _, bc, _, _, _, _, _, _, _); 
          get_direction(Node, bc)),
    (node(X, _, _, _, _, _, _, _, _, [bif|_]); 
          node(X, _, _, _, _, _, _, _, _, [if|_])),
    (Node = node(Name, _, _, _, _, _, _, _, _, [bif|_]);     
          Node = node(Name, _, _, _, _, _, _, _, _, [if|_])),
%    (Node = node(Name, _, bc, _, _, _, _, _, _, [bif|_]);     
%          Node = node(Name, _, bc, _, _, _, _, _, _, [if|_])),
    \+ member([[bcres, X, Name, bc],_], I), !, 
    compute_priority(X, Name, fc, P),
    ord_add_element(I, [[bcres, Name, X, bc],P], ISS),
    make_new_tasks(Node, Y, ISS, II).
make_new_tasks(Node, [_|Y], I, II):- !,
    make_new_tasks(Node, Y, I, II).


% order_tasks(+Unordered, -Ordered)
% Sort the Unordered agenda according to priority
% for now, don't care. eventually order according to fc/bc, priority,
% size of clauses.

order_tasks(X, X):- !.

% do_tasks(+Agenda)
% while there is still time, pop tasks off the agenda, execute them.
% now, dont care about time
% tasks look like [[pred name to call, node, node, fc/bc], P]
%?? what is P? priority???
% change that so that there can be any number of args. the last element
%  of the inner list is still fc/bc if we want it for whatever reason.

do_tasks(X):- !, do_tasks1(X).

do_tasks1([]):- !, assert(agenda([])).
do_tasks1(Ag):- 
    agenda_time(0), !,
    agenda_number(X),
    do_tasks_number(Ag, X).
do_tasks1(Ag):- 
    agenda_number(0), !,
    agenda_time(X),
    do_tasks_time(Ag, X).

do_tasks_number(Ag, X):-
    X > 0, \+ Ag = [], !,
    Y is X - 1,
%    Ag = [Hag|Tag],
%    format('Going to do: ~p~n', [Hag]),
    do_a_task(Ag, Agf),
%    format('~d left~n', [Y]),
    do_tasks_number(Agf, Y).
do_tasks_number(AG, _):-
    assert(agenda(AG)).

do_a_task([], []):- !.

do_a_task([[[Func|Args], _]|AA], AA):- !,
    length(Args, LTC),
    MTC is LTC - 1,
    functor(CX, Func, MTC),
    add_args(Args, 1, CX, CXX),
    call(CXX).

add_args([_], _, X, X):- !.
add_args([AX|Y], N, X, CX):-
    arg(N, X, AX),
    O is N + 1,
    add_args(Y, O, X, CX).



