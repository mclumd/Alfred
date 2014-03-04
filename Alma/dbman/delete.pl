/*
file :dbman.delete.pl
By: kpurang
What: code used to delete stuff
      deletes single nodes
      deletes bs trees

Todo: make it st the args for delete are same as for make

*/



% delete_node(+Node)
% remove Node from the database and from the indices.
% need to do more stuff? eg resuscitate it?
delete_node(Node):- !,
    get_name(Node, Name),
    get_form(Node, Form),
    ((debug_level(2); debug_level(3); debug_level(1)) ->
	  (debug_stream(DS), 
	   print(DS, 'Deleting '), print(DS, Name), print(DS, ': '), 
	   print(DS, Form), nl(DS)); true),
    unindex(Node, Name),
    retract(node(Name, _, _, _, _, _, _, _, _, _)),
    retract(number_of_nodes(NON)),
    (draw_graph(true) -> g_del_node(Name); true),
    NO is NON - 1,
    assert(number_of_nodes(NO)).


delete_bs_tree(Form):-
    convert_form(Form, [Cform], _),
    gp(Cform, [], L),
%% gotta verifyof Cform is what we really want below
    intersectnodes(Cform, Can),
    get_actual_nodes(Can, Ada),
    get_variant(Cform, Ada, Var), !,
    get_name(Var, Name),
    retract(tree_to_delete(TTD)),
%    get_name(Bigger, NodeName),
    append([Name], TTD, TTT),
    assert(tree_to_delete(TTT)),
    af(deleted_tree(Form)).

% delete_bc_tree(+Node)
% Node is an actual node.
% climb to the root of the bc tree, then delete all children that have the
% same assumption
% climb to root by parent nodes. take one path that has the same ass.
% 
% delete only after all processing has been done for one step. perhaps at
% the beginning of the next step.
% have a to_delete list.

delete_bc_tree(Node):- !,
    get_to_root(Node, Root),
    delete_tree(Root),
    get_name(Root, Rname),
    get_form(Root, [NRForm]),
    negate_lit(NRForm, RForm),
    df(doing_bs(Rname, RForm)),
    get_new_node_name(Nome),
    assert(new_node(Nome, [done_bs(Rname, RForm)], fc, [], 
		    [], 0, 1, [Rname], [], [])),
    index_new_node(new_node(Nome, [done_bs(Rname, RForm)], fc, [], 
			    [], 0, 1, [Rname], [], [])).

get_to_root(Node, Root):-
    get_parents(Node, ParentNames),
    find_good_parent(Node, ParentNames, Parent), !,
    get_to_root(Parent, Root).
get_to_root(Node, Node):- !.



% delete_tree(+Node)
delete_tree(Node):-
    get_kids(Node, Kids),
    delete_kids(Kids, Node),
    delete_node(Node).

delete_kids([], _):- !.
delete_kids([X|Y], Node):-
    get_assumptions(Node, ANode),
    find_node(X, NodeX),
    get_assumptions(NodeX, ANode), !,
    delete_tree(NodeX),
    delete_kids(Y, Node).
delete_kids([X|Y], Node):- delete_kids(Y, Node), !.


