/*
File: dbman/makenodes.pl
By: kpurang
What: code to make new nodes

Todo: rationalize this process

*/


% new_to_node(+new_node, -node)
new_to_node(new_node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9),
	    node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9)):- !.


make_new_node_named(bs(F), Name,
	      new_node(Name, F, bc, [], [], 0, 1, [], [], []) ) :- !,
     index_new_node(new_node(Name, F, bc, [], [], 0, 1, [], [], [])).
make_new_node_named(F, Name, 
		    new_node(Name, F, fc, [], [], 0, 1, [], [], [])):- !,
    index_new_node(new_node(Name, F, fc, [], [], 0, 1, [], [], [])).		    

% make_new_node(+Formula, -Node)
% makes a node with a dummy nodename.
make_new_node(bs(F), 
	      new_node(Name, F, bc, [], [], 0, 1, [], [], [])) :- !,
     get_new_node_name(Name),
     index_new_node(new_node(Name, F, bc, [], [], 0, 1, [], [], [])).
make_new_node(F, new_node(Name, F, fc, [], [], 0, 1, [], [], [])):- !,
    get_new_node_name(Name),
    index_new_node(new_node(Name, F, fc, [], [], 0, 1, [], [], [])).


% make_new_node(+Formula, +Priority, -Node)
% makes a node with a dummy nodename.
make_new_node(bs(F), P, 
	      new_node(Name, F, bc, [], [], 0, P, [], [], [])) :- !,
     get_new_node_name(Name),
     index_new_node(new_node(Name, F, bc, [], [], 0, P, [], [], [])).
make_new_node(F, P, new_node(Name, F, fc, [], [], 0, P, [], [], [])):- !,
    get_new_node_name(Name),
    index_new_node(new_node(Name, F, fc, [], [], 0, P, [], [], [])).

% here T is the type of clause: if, fif, bif
make_new_node(bs(F), P, T,
	      new_node(Name, F, bc, [], [], 0, P, [], [], T)) :- !,
    get_new_node_name(Name),
    index_new_node(new_node(Name, F, bc, [], [], 0, P, [], [], T)).
make_new_node(F, P, T, new_node(Name, F, fc, [], [], 0, P, [], [], T)):- !,
         get_new_node_name(Name),
	 index_new_node(new_node(Name, F, fc, [], [], 0, P, [], [], T)).

%
%make_new_nodes(+F, -N)
% now F is a list of formulas.
%
make_new_nodes(X, Z):- !,
    mnn_really(X, [], Z).

mnn_really([], X, X):- !.
mnn_really([X|Y], O, NN):- !,
    make_new_node(X, N),
    mnn_really(Y, [N|O], NN).


% name_nodes(+Noname, -Named)
% for each node, check if it has a name, if not, give it one. also changes
% them from new_nodes to nodes.
name_nodes(NN, N):- name_nodes(NN, [], N).
name_nodes([], X, X):- !.
name_nodes([new_node(A0 ,A1, A2, A3, A4, A5, A6, A7, A8, A9)|X], Y, Z):- !,
    (var(A0) -> get_new_name(Name); Name = A0),
    get_parents(new_node(A0 ,A1, A2, A3, A4, A5, A6, A7, A8, A9), Par),
%    fix_parents(Par, Name),
    step_number(Step),
    (draw_graph(true) -> g_add_node(Step, Name, Par, A1, A2); true),
    name_nodes(X, [node(Name, A1, A2, A3, A4, A5, A6, A7, A8, A9)|Y], Z).
name_nodes([new_node(A0 ,A1, A2, A3, A4, A5, A6, A7, A8, A9)|X], Y, Z):- !,
    name_nodes(X, [node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9)|Y], Z).


% get_new_name(-Name) returns a new node name.
get_new_name(X):-
%assert(node_count(0)),
	retract(node_count(X)), % FAILS HERE but above line 'fixes'
	Y is X + 1,
	assert(node_count(Y)),
%assert(number_of_nodes(0)), % same as above 
	retract(number_of_nodes(NON)),
	NONN is NON + 1,
	assert(number_of_nodes(NONN)).

% i am not sure why this is being distinguished from the nodes. 
% get_new_name(-Name) returns a new node name.
%get_new_node_name(X):-
%        retract(new_node_count(X)),
%        Y is X + 1,
%        assert(new_node_count(Y)).

get_new_node_name(X):-
    get_new_name(X).



%
% clone_node(+Node, -New_Node)
% given a node, return a new_node identical to the one given but with a 
% new name.
%
clone_node(node(_, A1, A2, A3, A4, A5, A6, A7, A8, A9),
	   new_node(Name, A1, A2, A3, A4, A5, A6, A7, A8, A9)):-
    get_new_name(Name).



%see res.pl
make_new_nodes_for_res([], _, _, _):- !.
make_new_nodes_for_res([[X,_]|Y], Pri, Junk, Pars):- !,
%    print(X), nl,
    make_new_node(X, Pri, Junk, Node),
    add_parents(Node, Pars, NNode),
    assert(NNode),
    get_name(NNode, NName),
%    fix_parents(Pars, NName),
    make_new_nodes_for_res(Y, Pri, Junk, Pars).


