/*
File: interfaces/addndel.pl
By: kpurang
What: adding and deleting nodes at user level

Todo: ratinoalize this 
      do the functional thing

Mods:
-kpurang jul 27 99
  modified the deletion of formulas so that the list of deleted formulas is
  a list of nodes, not of the formulas only.

*/


% af(+formula, +priority)
%  adds formula to the set of formulas at the next step with a priority
% shoudl change these so that af returns the name of the node it asserted.

af(named(Form, Name), Pri):- !,
	print('af name 1'),nl,
    convert_form(Form, Forms, Y),
    print('af convert name 1'),nl,
    %((debug_level(2); debug_level(3)) -> 
	%  (debug_stream(DS), 
	%   print(DS, 'Adding '), print(DS, Form), nl(DS)); true),
    (var(Y) -> Y = if; true),
    merge_forms(Forms, MForms),
    assert_new_nodes_named(MForms, Y, Pri, Name).


af(Form, Pri):- !,
	print('af pri 1:'),print(Form),nl,
    convert_form(Form, Forms, Y),
    print('convert form 1'),nl,
    %((debug_level(2); debug_level(3)) -> 
	%  (debug_stream(DS), 
	%   print(DS, 'Adding '), print(DS, Form), nl(DS)); true),
    (var(Y) -> Y = if; true),
    merge_forms(Forms, MForms),
    assert_new_nodes(MForms, Y, Pri).

% af(+formula)
%  adds formula to the set of formulas at the next step. priority is set.

af(Form):- !, af(Form, 1).

% df(+formula)
% deletes formula from the set of formulas at the next step.

% remember to get rid of this formula from its parents kidslist!!!

df(X) :- !, df1(X).

df1(Form):- 
    convert_form(Form, [Cform], _),
    gp(Cform, [], L),
    intersectnodes(Cform, Can),
    get_actual_nodes(Can, Ada),
    get_variant(Cform, Ada, Var), !,

    get_name(Var, Name),
%
% modify to use delete_node: commented the block below, added the 2 lines
% before the block
%
    get_actual_nodes([Name], [Node]),
    get_form(Node, FF),
    delete_node(Node),
    retract(deleted_forms(DF)),
    assert(deleted_forms([Node|DF])),
    retract(number_of_nodes(NON)),
    NO is NON - 1,
    step_number(Step),
    (draw_graph(true) -> g_del_node(Name); true),
    assert(number_of_nodes(NO)).
df1(_) :- !.

%
% deletes all nodes that unify with Form
%

dfu(Form):- !,
    convert_form(Form, Forms, _),
    merge_forms(Forms, MForms),
    dfueach(MForms).

dfueach([]):- !.
dfueach([X|Y]):-
    dfur(X),
    dfueach(Y).

dfur(Cform):- !,
    gp(Cform, [], L),
    intersectnodes(Cform, Can),
    get_actual_nodes(Can, Ada),
    get_subsumers(Cform, Ada, [], Var), 
    delete_all_df(Var).

delete_all_df([]):- !.
delete_all_df([Var|Y]):-
    get_name(Var, Name),
%
% modify to use delete_node: commented the block below, added the 2 lines
% before the block
%
%CFA 082599 changed second arg of get_form from DF to Form for bug fix
% looked very fishy. modified 

    get_actual_nodes([Name], [Node]),
    get_form(Node, Form),
    delete_node(Node),
    retract(deleted_forms(DF)),
    assert(deleted_forms([Node|DF])),
    retract(number_of_nodes(NON)),
    NO is NON - 1,
    step_number(Step),
    (draw_graph(true) -> g_del_node(Name); true),
    assert(number_of_nodes(NO)),
    delete_all_df(Y).



assert_new_nodes_named([], _, _, _).
assert_new_nodes_named([X|Y], T, P, Name):-
%    (X = [_] -> functcheck(X, Y, T, P); true),
    make_new_node_named(X, Name, N0),
    set_junk(N0, [T], N1),
    set_priority(N1, P, N2),
    assert(N2),   
    ((debug_level(1); debug_level(2); debug_level(3)) -> 
	  (debug_stream(DS), get_nodename(N2, NNAME), print(DS, 'Asserted '), 
	   print(DS, NNAME), print(DS, ': '), print(DS, X), nl(DS)); true),
    assert_new_nodes_named(Y, T, P, Name).



assert_new_nodes([], _, _).
assert_new_nodes([X|Y], T, P):-
%    (X = [_] -> functcheck(X, Y, T, P); true),
    make_new_node(X, P, [T], N),
    get_name(N, NName),
%    fix_parents(P, NName),
    assert(N),   
    ((debug_level(1); debug_level(2); debug_level(3)) -> 
	  (debug_stream(DS), get_nodename(N, NNAME), print(DS, 'Asserted '), 
	   print(DS, NNAME), print(DS, ': '), print(DS, X), nl(DS)); true),
    assert_new_nodes(Y, T, P).


% we assume this will never be a not(foo). always positive literals.
%


functcheck([Atom], Rest, T, P):-
    functor(Atom, Funct, Arity),
    functionalist(Funct, Arity, Form, Forall), !,
% get the node
    (Form = null -> true ; (
%    pred_to_node(Funct, plus, Set),
%    get_the_node(Atom, Arity, Set, Node),
% delete the old one
    find_node(Form, Node),
    delete_node(Node))),
    make_new_node([Atom], P, [T], Newone),
    assert(Newone),
    get_name(Newone, Newname),
    (Forall = null -> true ; 
      (find_node(Forall, Forallnode), 
      delete_node(Forallnode))),
    functor(Dummy, Funct, Arity),
    make_new_node([eval_bound( subsumes_chk(Atom, Dummy), []), not(Dummy)], P, [T], Newforall),
%    new_to_node(RealNewforall, Newforall),
    get_name(Newforall, Newforallname),
    retract(functionalist(Funct, Arity, Form, Forall)),
    assert(functionalist(Funct, Arity, Newname, Newforallname)),
    assert(Newforall),
    assert_new_nodes(Rest, T, P).
functcheck([Atom], Rest, T, P):-
    make_new_node([Atom], P, [T], N),
    assert(N),       
    assert_new_nodes(Rest, T, P).

% given a functor and its arity, and a list of node names, return a node 
% whose formula is a single literal of the same arity and functor.

get_the_node(_, _, [], _):- fail, !.
get_the_node(A, Ari, [X|Y], CNode):-
    find_node(X, CNode),
    get_formula(CNode, [Form]),
    functor(Form, A, Ari),!.
get_the_node(A, Ari, [X|Y], Node):-
    get_the_node(A, Ari, Y, Node),!.
    

