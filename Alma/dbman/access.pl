/*
File: dbman/access.pl
By: kpurang

What: code for accessfuntions for nodes

Todo: try to remove disorder

*/

%:- ensure_loaded(library(sets)).

% access from the formula to the node.
% ASSUMES that the formula provided ends up as a single clause.
form_to_name(Form, Name):-
    convert_form(Form, [Cform], _),!,
    gp(Cform, [], L),
    intersectnodes(Cform, Can),
    get_actual_nodes(Can, Ada),
    get_variant(Cform, Ada, Var), 
    get_name(Var, Name).



% a bunch of accesses from the node name to the insides

name_to_parents(Name, Parents):- 
    find_node(Name, Node),!, 
    get_parents(Node, Parents).
name_to_formula(Name, Form):- 
    find_node(Name, Node),!, 
    get_formula(Node, Form).
name_to_time(Name, Time):- 
    find_node(Name, Node),!, 
    get_time(Node, Time).
name_to_children(Name, Children):- 
    find_node(Name, Node),!, 
    get_kids(Node, Children).

%__________________________________________________
name_to_derivation(Name, deriv(Name, ListD)):-
    find_node(Name, Node), !,
    get_parents(Node, Par),
    (Par = [] -> ListD = []; gather_parent_derivs(Par, ListD)).
name_to_derivation(Name, Name):- !.

gather_parent_derivs([], []):- !.
gather_parent_derivs([P|Q], [DP|QQ]):- !,
    get_one_deriv(P, DP),
    gather_parent_derivs(Q, QQ).

get_one_deriv([], []):- !.
get_one_deriv([P|Q], [DP|QQ]):- !,
    name_to_derivation(P, DP),
    get_one_deriv(Q, QQ).

/*
% Thi sis no good coz it merges all the derivations. Need to keep them
% separate.
name_to_deriv_fringe(Name, F):- !,
    find_node(Name, Node),
    get_parents(Node, Par),
    df_s_parents(Par, [], F).
%    list_to_ord_set(E, F).
df_s_parents([], X, X):- !.
df_s_parents([X|Y], In, Out):- !,
    df_parents(X, In, Out1),
    df_s_parents(Y, Out1, Out).
df_parents([], X, X):- !.
df_parents([X|Y], In, Out):- !,
    find_node(X, XN),
    get_parents(XN, P),
    (P = [] -> ord_union([X], In, Out1) ; df_s_parents(P, In, Out1)),
    df_parents(Y, Out1, Out).
*/

% Df is a list of lists of axioms for each derivation.
name_to_deriv_fringe(Name, Df):- !,
    find_node(Name, Node),
    get_parents(Node, Par),
    (Par = [] -> Df = [[Name]]; process_each_deriv(Par, Df)).
% if there is no more parents, this is hte fringe

% input is a list of individual derivations 
% we get the results for each and simply list them
process_each_deriv([], []):- !.
process_each_deriv([X|Y], XYP):- !,
    process_one_deriv(X, XP),
    process_each_deriv(Y, YP),
    ord_union(XP, YP, XYP).

% input is a set of nodes that are taken together.
% need to find the fringe for each (list of lsits) and multiply out the
%  results.
process_one_deriv([], []):- !.
process_one_deriv([X|Y], Z):- !,
    name_to_deriv_fringe(X, XF),		  %XF: list of lists
    process_one_deriv(Y, YP),			  %YP: list of lists too
    cross_them(XF, YP, Z).

% input 2 lists of lists. Need to return a list of lists st the number of
% lists is the product of theose in the other 2.
cross_them(X, [], X):- !.
cross_them([], _, []):- !.
cross_them([X|Y], Z, XYZ):- !,
    cross_one(X, Z, XZ),
    cross_them(Y, Z, YZ),
    ord_union(XZ, YZ, XYZ).

% 1st ip is a list, second is a list of lists.
% merge the first with each of the second
cross_one(X, [], []):- !.
cross_one(X, [Y|Z], [XY|XZ]):- !,
    ord_union(X, Y, XY),
    cross_one(X, Z, XZ).



%__________________________________________________
name_to_descendants(Name, T, Desc):-
    find_node(Name, Node), !,
    step_number(T),
    get_kids(Node, Kids),
    list_to_ord_set(Kids, OKids),
    name_to_descendants2(OKids, OKids, Desc).
name_to_descendants(_, _, []):- !.
name_to_descendants2([], X, X):- !.
name_to_descendants2([X|Y], In, Out):-
    find_node(X, Node), !,
    get_kids(Node, Kids),
    list_to_ord_set(Kids, OKids),
    ord_union(OKids, Y, OY),
    ord_union(OKids, In, YO),
    name_to_descendants2(OY, YO, Out).
name_to_descendants2([X|Y], I, O):- !,
    name_to_descendants2(Y, I, O).


find_node(Name, node(Name, A1, A2, A3, A4, A5, A6, A7, A8, A9)):- 
    node(Name, A1, A2, A3, A4, A5, A6, A7, A8, A9), !.
find_new_node(Name, node(Name, A1, A2, A3, A4, A5, A6, A7, A8, A9)):- 
    new_node(Name, A1, A2, A3, A4, A5, A6, A7, A8, A9), !.
    
get_new_node(new_node(_, _, _, _, _, _, _, _, _, _)):- !.
% a family of gets and sets for nodes/new_nodes. all take a node as
% argument. not a node name
get_nodename(node(Name, _, _, _, _, _, _, _, _, _), Name) :- !.
get_nodename(new_node(Name, _, _, _, _, _, _, _, _, _), Name):- !.
set_nodename(node(_, A1, A2, A3, A4, A5, A6, A7, A8, A9), Name,
	     node(Name, A1, A2, A3, A4, A5, A6, A7, A8, A9)) :- !.
set_nodename(new_node(_, A1, A2, A3, A4, A5, A6, A7, A8, A9), Name,
	     new_node(Name, A1, A2, A3, A4, A5, A6, A7, A8, A9)) :- !.


% get_name(+noed, -name)
get_name(node(A0, _, _, _, _, _, _, _, _, _), A0).
get_name(new_node(A0, _, _, _, _, _, _, _, _, _), A0).

get_formula(node(_, Form, _, _, _, _, _, _, _, _), Form):- !.
get_formula(new_node(_, Form, _, _, _, _, _, _, _, _), Form):- !.
set_formula(node(A0, _, A2, A3, A4, A5, A6, A7, A8, A9), Form,
	     node(A0, Form, A2, A3, A4, A5, A6, A7, A8, A9)):- !.
set_formula(new_node(A0, _, A2, A3, A4, A5, A6, A7, A8, A9), Form,
	     new_node(A0, Form, A2, A3, A4, A5, A6, A7, A8, A9)):- !.

% get_form(+node, -formula)
% given a node, retuen the formula
get_form(node(_, A1, _, _, _, _, _, _, _, _), A1):- !.
get_form(new_node(_, A1, _, _, _, _, _, _, _, _), A1):- !.

get_type(node(_, _, Type, _, _, _, _, _, _, _), Type):- !.
get_type(new_node(_, _, Type, _, _, _, _, _, _, _), Type):- !.
set_type(node(A0, A1, _, A3, A4, A5, A6, A7, A8, A9), Type,
	     node(A0, A1, Type, A3, A4, A5, A6, A7, A8, A9)):- !.
set_type(new_node(A0, A1, _, A3, A4, A5, A6, A7, A8, A9), Type,
	     new_node(A0, A1, Type, A3, A4, A5, A6, A7, A8, A9)):- !.

get_ass(node(_, _, _, Ass, _, _, _, _, _, _), Ass):- !.
get_ass(new_node(_, _, _, Ass, _, _, _, _, _, _), Ass):- !.
set_ass(node(A0, A1, A2, _, A4, A5, A6, A7, A8, A9), Ass,
	     node(A0, A1, A2, Ass, A4, A5, A6, A7, A8, A9)):- !.
set_ass(new_node(A0, A1, A2, _, A4, A5, A6, A7, A8, A9), Ass,
	     new_node(A0, A1, A2, Ass, A4, A5, A6, A7, A8, A9)):- !.

% get_assumptions(+Node, - Ass)
get_assumptions(new_node(_, _, _, Ass, _, _, _, _, _, _), Ass) :- !.
get_assumptions(node(_, _, _, Ass, _, _, _, _, _, _), Ass) :- !.

get_target(node(_, _, _, _, Target, _, _, _, _, _), Target):- !.
get_target(new_node(_, _, _, _, Target, _, _, _, _, _), Target):- !.
set_target(node(A0, A1, A2, A3, _, A5, A6, A7, A8, A9), Target,
	     node(A0, A1, A2, _, Target, A5, A6, A7, A8, A9)):- !.
set_target(new_node(A0, A1, A2, A3, _, A5, A6, A7, A8, A9), Target,
	     new_node(A0, A1, A2, A3, Target, A5, A6, A7, A8, A9)):- !.

get_time(node(_, _, _, _, _, Time, _, _, _, _), Time):- !.
get_time(new_node(_, _, _, _, _, Time, _, _, _, _), Time):- !.
set_time(node(A0, A1, A2, A3, A4, _, A6, A7, A8, A9), Time,
	     node(A0, A1, A2, A3, A4, Time, A6, A7, A8, A9)):- !.
set_time(new_node(A0, A1, A2, A3, A4, _, A6, A7, A8, A9), Time,
	     new_node(A0, A1, A2, A3, A4, Time, A6, A7, A8, A9)):- !.

get_priority(node(_, _, _, _, _, _, Priority, _, _, _), Priority):- !.
get_priority(new_node(_, _, _, _, _, _, Priority, _, _, _), Priority):- !.
set_priority(node(A0, A1, A2, A3, A4, A5, _, A7, A8, A9), Priority,
	     node(A0, A1, A2, A3, A4, A5, Priority, A7, A8, A9)):- !.
set_priority(new_node(A0, A1, A2, A3, A4, A5, _, A7, A8, A9), Priority,
	     new_node(A0, A1, A2, A3, A4, A5, Priority, A7, A8, A9)):- !.

set_priority_list(X, P, Y):- !,
    spp_really(X, P, [], Y).
spp_really([], _, X, X):- !.
spp_really([X|Y], Pr, Z, F):- !,
    set_priority(X, Pr, XX),
    spp_really(Y, Pr, [XX|Z], F).

get_parents(node(_, _, _, _, _, _, _, Parents, _, _), Parents):- !.
get_parents(new_node(_, _, _, _, _, _, _, Parents, _, _), Parents):- !.
set_parents(node(A0, A1, A2, A3, A4, A5, A6, _, A8, A9), Parents,
	     node(A0, A1, A2, A3, A4, A5, A6, Parents, A8, A9)):- !.
set_parents(new_node(A0, A1, A2, A3, A4, A5, A6, _, A8, A9), Parents,
	     new_node(A0, A1, A2, A3, A4, A5, A6, Parents, A8, A9)):- !.

set_parents_list(X, Y, Z):- !,
    spl_really(X, Y, [], Z).
spl_really([], _, X, X):- !.
spl_really([X|Y], J, O, N):- !,
    add_parents(X, J, XJ),
    spl_really(Y, J, [XJ|O], N).

% THIS TAKES A LIST OF SETS OF PARENTS
add_parents(node(A0, A1, A2, A3, A4, A5, A6, [], A8, A9), Parents,
	     node(A0, A1, A2, A3, A4, A5, A6, Parents, A8, A9)):- !.
add_parents(node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9), Parents,
	     node(A0, A1, A2, A3, A4, A5, A6, A77, A8, A9)):- !,
             append(Parents, A7, A77).
add_parents(new_node(A0, A1, A2, A3, A4, A5, A6, [], A8, A9), Parents,
	     new_node(A0, A1, A2, A3, A4, A5, A6, Parents, A8, A9)):- !.
add_parents(new_node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9), Parents,
	     new_node(A0, A1, A2, A3, A4, A5, A6, A77, A8, A9)):- !,
             append(Parents, A7, A77).

get_kids(node(_, _, _, _, _, _, _, _, Kids, _), Kids):- !.
get_kids(new_node(_, _, _, _, _, _, _, _, Kids, _), Kids):- !.
set_kids(node(A0, A1, A2, A3, A4, A5, A6, A7, _, A9), Kids,
	     node(A0, A1, A2, A3, A4, A5, A6, A7, Kids, A9)):- !.
set_kids(new_node(A0, A1, A2, A3, A4, A5, A6, A7, _, A9), Kids,
	     new_node(A0, A1, A2, A3, A4, A5, A6, A7, Kids, A9)):- !.

get_junk(node(_, _, _, _, _, _, _, _, _, Junk), Junk):- !.
get_junk(new_node(_, _, _, _, _, _, _, _, _, Junk), Junk):- !.
set_junk(node(A0, A1, A2, A3, A4, A5, A6, A7, A8, _), Junk,
	     node(A0, A1, A2, A3, A4, A5, A6, A7, A8, Junk)):- !.
set_junk(new_node(A0, A1, A2, A3, A4, A5, A6, A7, A8, _), Junk,
	     new_node(A0, A1, A2, A3, A4, A5, A6, A7, A8, Junk)):- !.

set_junk_list(X, Y, Z):- !,
    sjl_really(X, Y, [], Z).
sjl_really([], _, X, X):- !.
sjl_really([X|Y], J, O, N):- !,
    set_junk(X, J, XJ),
    sjl_really(Y, J, [XJ|O], N).


% get_direction(+Node, -Direction)
% Direction = fc or bc or whatever.
get_direction(node(_, _, S, _, _, _, _, _, _, _), S):- !.


% get_target(+node, -target)
get_target(node(_, _, _, _, A0, _, _, _, _, _), A0).
get_target(new_node(_, _, _, _, A0, _, _, _, _, _), A0).

% get_actual_nodes(+Names, -Nodes)
% given a list of node names, return the nodes themselves.
get_actual_nodes(X, Y):- get_actual_nodes(X, [], Y), !.
get_actual_nodes([], _, []).
get_actual_nodes([X|Y], _, [node(X, A1, A2, A3, A4, A5, A6, A7, A8, A9)|F]):- !,
    node(X, A1, A2, A3, A4, A5, A6, A7, A8, A9),
    get_actual_nodes(Y, I, F).

get_actual_new_nodes(X, Y):- get_actual_new_nodes(X, [], Y), !.
get_actual_new_nodes([], X, X).
get_actual_new_nodes([X|Y], I, F):- !,
    new_node(X, A1, A2, A3, A4, A5, A6, A7, A8, A9),
    get_actual_new_nodes(Y, [new_node(X, A1, A2, A3, A4, A5, A6, A7, A8, A9)|I],
		    F).


