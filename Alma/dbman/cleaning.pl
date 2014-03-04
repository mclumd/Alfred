/*
File: dbman/cleaning.pl
By: kpurang
What:  code about cleaning nodes after a step

Todo: see that the comments are true.
      need a better way to do this. or rather a way not to have to do so 
      much cleaning

*/

/*
clean_new_nodes(-NewNodes)
this retracts from the databse all the "new_nodes" that were asserted at the
previous step, filters them and returns the good ones as "NewNodes"

filtering handles duplicate and contradictory nodes. It unindexes the
resulting nodes from the new-node-index converts them to regular nodes
and moves them to the regular index. It also asserts that it is done
with all the nodes it looked at. The resulting nodes are the good
nodes that are returned.

*/

/* need to fix the duplicating so that it keeps track of multiple
  derivations */

% clean_new_nodes(-Cnn)
% Looks for all asserted new_nodes and adds to dbase good ones: non-
% duplicates and non-contra
%
% feb 1 1999, kp added the retract and commented the retract. problem
% of contras disappearing. hope that fixes it. come to think of it, it
% might not work: we still need the new_nodes when we do the filtering,
% dont we?


clean_new_nodes(Fnn):- !,
    findall(new_node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9), 
	    retract(new_node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9)),
	    Ann),
    choose_what_to_filter(Ann, Bnn),
    filter_old_nodes(Bnn, Fnn),
    true.
%    retractall(new_node(_, _, _, _, _, _, _, _, _, _)).

choose_what_to_filter(X, X) :- !.

% filter_old_nodes(+Old, -New)
% for each node in the Old list, do the following:
%  check for duplicates. If there is a duplicate, assert that we are done
%    with the node and ignore it.
%  check for contradictions. This is handled at the irlevel. If the node
%    is a contradictand, assert that it has been processed, add new formulas
%    about the formula in the New list
%  otherwise, remove the node from the index of new nodes, reindex it as a
%    regular node and assert that we are done with it.

% for each node in Old list, check if it already exists and if it contras
% something else. if not, give a name, assert in dbase, index it. return
% survivors in New list. (is that a list of nodes or node names?)
filter_old_nodes(O, N):- !,
    filter_old_nodes(O, [], N).
filter_old_nodes([], X, X):- !,			  % distrust all new bad guys
    findall(X, retract(abort_it(X)), Abs),
    abort_em_all(Abs).
filter_old_nodes([X|Y], Z, ZZ):-		  % take care of pending 
    get_formula(X, Xf),				  % contras
    get_name(X, Xname),
    Xf = [Xff],
    pending_contra(Xff, NXf, OXname, XFNname), !,
    step_number(Now),
    make_new_node([contra(Xname, XFNname, Now)], Z1), 
    set_junk(Z1, [if], Z1_1),
    add_parents(Z1_1, [[Xname, XFNname]], Z2), 
    assert(pending_contra(Xff, NXf, Xname, XFNname)),
    assert(pending_contra(NXf, Xff, XFNname, Xname)),
    assert(Z2),
    make_new_node([distrusted(Xname, Now)], Dis0),
    set_junk(Dis0, [if], Dis0_1),
    add_parents(Dis0_1, [[XFNname]], Dis1),
    assert(Dis1),
    new_to_node(X, XZS), 
    assert(XZS), 
    unindexnewone(Xf, XZS),
    retract(distrusted_forms(DF)),
    assert(distrusted_forms([XZS|DF])),
    filter_old_nodes(Y, Z, ZZ).
filter_old_nodes([X|Y], Z, ZZ):-
    is_old_node(X), !,				  % here need to add to par.
    assert(done_new(X)),
    filter_old_nodes(Y, Z, ZZ).
filter_old_nodes([X|Y], Z, ZZ):-
    is_contra_node(X, Contra), 
    retract(to_add_to_hist(TATH)),		  %KP added 02/01
    assert(to_add_to_hist([X|TATH])),
%    historicize([X]),				  %KP added 09/30/00
    handle_contras(X, Contra, SX), !,
    assert(done_new(X)),
    append(SX, Z, ZZZ),
    filter_old_nodes(Y, ZZZ, ZZ).
%filter_old_nodes([X|Y], Z, ZZ):-
%    is_contra_node(X, Contra), 
%    handle_contra(X, Contra, XX), !,
%    filter_old_nodes(Y, [XX|Z], ZZ).
filter_old_nodes([X|Y], Z, ZZ):- !,
    get_predicates(X, Xpred),
    get_formula(X, XFORM),
    get_name(X, Xname),
    get_parents(X, Xpar),
    unindexnewone(XFORM, Xname),
    name_nodes([X], [XX]),
    assert(done_new(X)),
    index_nodes([XX]),
    step_number(T),
    set_time(XX, T, XXT),
    assert(XXT),
    fix_parents(Xpar, Xname),
    get_formula(XXT, FOrm),
    ((debug_level(2); debug_level(3)) -> 
	  (debug_stream(DS), 
	   print(DS, 'Asserted '), print(DS, Xname), print(DS, ': '),
	   print(DS, FOrm), nl(DS)); true),
    filter_old_nodes(Y, [XXT|Z], ZZ).



% is_old_node(+Node) succeeds if the node already exists.
% get all predicates and their polarities for the node.
% for each predicate, get the set of nodes it appears in
% intersect all the sets
% search the result for the node.
% if we don't find, we succeed.
% this is hopefully more efficient than searching through all the nodes.
is_old_node(N):- is_old_old(N), !.
is_old_node(N):- is_new_old(N), !.

is_old_old(N):- !,
    get_formula(N, F),
    intersectnodes(F, IN),
    get_actual_nodes(IN, INN),
    variant_nodes(N, INN, VX),			  % this should be just one
    (VX = [] -> fail; add_all_parents(N, VX)).

is_new_old(N):- !,				  % is a new duplicate
    get_formula(N, F),
    intersectnewnodes(F, XIN),		  % potential candidates
    get_name(N, NNAme),
    %del_element(NNAme, XIN, IN),			  % remove myself
    delete(XIN, NNAme, IN), % delete NNAme from XIN, may need library(lists)
    get_actual_new_nodes(IN, INN),		  % get em
    variant_nodes(N, INN, VX),			  % one or more the same
    one_not_done(VX, NDX),			  % i am not the first
    (NDX = [] -> fail; add_all_parents(N, NDX)).

one_not_done([], []):- !.
one_not_done([X|_], [X]):-
    done_new(X), !.
one_not_done([_|Y], Z):-
    one_not_done(Y, Z).
    
add_all_parents(N, []):- !.
add_all_parents(N, [X|Y]):- !,
    get_parents(N, NP),
    get_name(N, Nname),
    add_parents(X, NP, XX),
    retract(X), assert(XX),
    fix_parents(NP, Nname),
    add_all_parents(N, Y).

add_each_parent(X, [], X):- !.
add_each_parent(X, [P1|Pn], XX):- !,
    add_parents(X, P1, X1),
    add_each_parent(X1, Pn, XX).

%
% watfor?
%

is_an_old_node(node(_, _, _, _, _, _, _, _, _, _)):- !.

abort_em_all([]):- !.
abort_em_all([X|Y]):-
    find_node(X, Xn),!,
    unindex(Xn, X),
    abort_em_all(Y).

