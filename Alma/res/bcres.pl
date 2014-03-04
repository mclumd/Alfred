/*
File: res/bcres.pl
By: kpurang
What: resolution for  back search

Todo: looks too complicated

*/

% bcres(+Node1, +Node2)
% Nodes are names of nodes that may resolve.
% apply resolution to the nodes, result is an asserted new_node
% we do not expect to derive the empty clause here since we do the 
% stupid contra filtering thing.
% if one is a fc node , make into bc with the same assumptions as before
% else if both are bc, assumptions of one must be subset of other. then
%  assumtions of new node = bigger set.

% jan6 mofidy appropriately for a list of resolvents.

bcres(N1, N2):-
    get_actual_nodes([N1, N2], [AN1, AN2]),
    get_form(AN1, Nf1), get_form(AN2, Nf2),
    bigger_ass(AN1, AN2, Bigr, Ass),
    get_target(Bigr, Tar),
    resolve(Nf1, Nf2, Tar, R), 
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Bcres '),
    print(DS, resolve(Nf1, Nf2, Tar, R)), nl(DS)); true),
    !,
    bcres_proc(R, AN1, AN2, Ass, Tar, N1, N2).
bcres(_, _):- !.

bcres_proc([], _, _, _, _, _, _):- !.
bcres_proc([[R, T]|RR], AN1, AN2, Ass, _, N1, N2):- !,
    ((R = []) -> add_bc_conc(AN1, AN2);
    (get_new_node_name(NAme),
     assert(new_node(NAme, R, bc, Ass, T, 0, 0, [N1, N2], [], [bif])),
    index_new_node(new_node(NAme, R, bc, Ass, T, 0, 0, 
			    [N1, N2], [], [bif])))),
    bcres_proc(RR, AN1, AN2, Ass, T, N1, N2).



%    \+ R = [], !,
% what is this about???
% why is it so complicated?

add_bc_conc(New0, Old0):-
    copy_term(New0, New),
    copy_term(Old0, Old),
    exactly_one_ass(New, Old, [X|Y], Node), !,
    get_target(Node, [T|XX]),
    get_form(New, [NF]), get_form(Old, [OF]),
    negate_lit(NF, NNF),
    NNF = OF,
    negate_lit(T, TC),
    get_name(New, NName), get_name(Old, OName),
    (Y = [] -> 
	 ( get_new_node_name(Namr),
	   assert(new_node(Namr, [TC], fc, [], [], 0, 1, [NName, OName],
			   [], [if])),
	 index_new_node(new_node(Namr, [TC], fc, [], [], 0, 1, [NName, OName],
				 [], [if])));
	       (get_new_node_name(WW),
	       assert(new_node(WW, [TC], bc, [Y], [XX], 0, 1, 
		     [NName, OName], [], [bif])),
	       index_new_node(new_node(WW, [TC], bc, [Y], [XX], 0, 1, 
		     [NName, OName], [], [bif])))),
    (delete_trees(true) ->
	 (retract(tree_to_delete(TTD)),
	  get_name(Node, NodeName),
	  append([NodeName], TTD, TTT),
	  assert(tree_to_delete(TTT)));
    true).


add_bc_conc(New0, Old0):-
    copy_term(New0, New),
    copy_term(Old0, Old),
    bigger_ass(New, Old, Bigger, [X|Y]), !,
    get_name(New, NName), get_name(Old, OName),
    get_target(Bigger, [T|XX]),
    get_form(New, [NF]), get_form(Old, [OF]),
    negate_lit(NF, NNF),
    NNF = OF,
    negate_lit(T, TC),
    get_new_node_name(Nome),
    assert(new_node(Nome, [TC], bc, Y, [XX], 0, 1, [NName, OName], [], [])),
    index_new_node(new_node(Nome, [TC], bc, Y, [XX], 0, 1, 
			    [NName, OName], [], [])),
    (delete_trees(true) ->
	 (retract(tree_to_delete(TTD)),
	  get_name(Bigger, NodeName),
	  append([NodeName], TTD, TTT),
	  assert(tree_to_delete(TTT)));
    true).

% find_good_parent(+Node, +List of Parents, -GoodParent)
find_good_parent(_, [], _):- fail, !.
find_good_parent(Node, [X|Y], NodeX):-
    find_node(X, NodeX),
    get_assumptions(Node, AN),
    get_assumptions(NodeX, AN), !.
find_good_parent(Node, [X|Y], Parent):-
    find_good_parent(Node, Y, Parent).

