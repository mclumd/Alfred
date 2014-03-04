/*
File: handle_contra.pl
By: kpurang

What: handles contradictions

Todo: rationalize the detection and handling of contras.
      move file somewhere else.

*/

%:- ensure_loaded(library(basics)).
:- use_module(library(ordsets)).
%:- ensure_loaded(library(strings)).


% is_contra_node(+N)
% succeeds if the node's contradiction is present.
% fail if clause has more than one disjunct.
% if just one disjunct, look for contra.
% check that the parent of the bc node is not the other node.*******
is_contra_node(N, Contra):-
    is_old_contra(N, Contra), !.
is_contra_node(N, Contra):-  is_new_contra(N, Contra), !.

is_old_contra(N, Contra):- 
    get_predicates(N, [[P, Pol]]), !,
    reverse_pol(Pol, Rpol),
    get_formula(N, Form),
    (Form = [not(SMM)] -> NForm = SMM ; Form = [NForm]),
%    negate(Form, NForm),
%    pred_to_node(P, Rpol, Set),
    match_form(NForm, Rpol, Set),
    get_actual_nodes(Set, ASet),
    pick_contra(N, Pol, ASet, Contra).

is_new_contra(N, Contra):- 
    get_predicates(N, [[P, Pol]]), !,
    get_formula(N, FORM),
%    negate(FORM, NForm),
    (FORM = [not(SMM)] -> NForm = SMM ; FORM = [NForm]),
    reverse_pol(Pol, Rpol),
%    pred_to_new_node(P, Rpol, Set),
    match_form(NForm, Rpol, Set),
    get_actual_new_nodes(Set, ASet),
    pick_contra(N, Pol, ASet, Contra).


% pick_contra(+N, +Pol, +Set, Contra)
% N is a node with a unit clause, Pol is the polarity of that clause,
% Set is a set of other nodes that contain the predicate with opposite
% polarity, 
% returns the contra node if exists. else fails.
pick_contra(N, Pol, Aset, Contra):- !,
    pick_contra(N, Pol, Aset, [], Contra),
    \+ Contra = [].
pick_contra(_, _, [], X, X):- !.
pick_contra(Node, plus, [X|Y], I, F):-
    get_form(X, [not(XF)]),			  % unit clause
    get_form(Node, [NF]),			  % unit clause too
    copy_term(NF, NNF),
    copy_term(XF, XXF),
    XXF = NNF, !,
    pick_contra(Node, plus, Y, [X|I], F).
pick_contra(Node, plus, [_|Y], I, F):- !,
    pick_contra(Node, plus, Y, I, F).
pick_contra(Node, minus, [X|Y], I, F):-
    get_form(X, [XF]),				  % unit clause
    get_form(Node, [NF]),			  % unit clause too
    copy_term(NF, NNF),
    copy_term(XF, XXF),
    not(XXF) = NNF, !,
    pick_contra(Node, minus, Y, [X|I], F).
pick_contra(Node, minus, [_|Y], I, F):- !,
    pick_contra(Node, minus, Y, I, F).
    

% this is from res.pl
% presumably useful only if resolution is the only rule of inference
% handle_contra(+Node, +Contra)
% given contradictory nodes, do something about it.
% for now, nuffin,
% remember to account for cases of contradiction where we have fc and bc
% then, negate first assumption and add to next step.
% is ir dependednt. move.
%
% if neither has any assumption, delete COntra from db.
% if exactly one has an assuption, add the negation of the head of the 
%   assumption as a new node, name, index and assert Node
% if both have assumptions, check if one is a subset of the other.
%   if so, add as new node the head of the bigger ass. set
%   else, ie unrelated assumptions, naem, index and add Node. in this
%      case there is something wrong, but we don;t know what.

% Old and Res are lists here.
handle_contras(New, Old, Res):-
    handle_contras(New, Old, [], Res).
handle_contras(_, [], X, X):- !.
handle_contras(New, [X|Y], I, F):-
    handle_contra(New, X, S),
    append(S, I, SI),
    handle_contras(New, Y, SI, F).

% new version of nov 24. see the todo file for details.

handle_contra(New, Old, []):-
    get_assumptions(New, []), get_assumptions(Old, []), !,
    get_form(New, [NF|_]), get_form(Old, [OF|_]),
    get_name(New, NName), get_name(Old, OName),
    (done_new(Old)-> 
	 true;
       (step_number(Now),
	make_new_node([contra(NName, OName, Now)], Z1), 
	add_parents(Z1, [[NName, OName]], Z2), set_junk(Z2, [if], XNM),
	assert(pending_contra(NF, OF, NName, OName)),
	assert(pending_contra(OF, NF, OName, NName)),
	get_name(Z1, Cname),
	(contra_distrust_descendants(true) -> 
	     distrust_descendants(NName, OName, Now); true),
        (is_an_old_node(Old) -> 
	     unindex(Old, OName); 
	(new_to_node(Old, OLDNEW), assert(OLDNEW), unindexnewone([OF], OName))),
	make_new_node([distrusted(OName, Now)], D01),
	get_name(D01, D1name),
	set_junk(D01, [if], D01_1),
	add_parents(D01_1, [[NName]], D02),
	assert(D02),
	new_to_node(New, NEWOLD), assert(NEWOLD), unindexnewone([NF], NName),
	get_parents(New, Newp), 
	fix_parents(Newp, NName),
	make_new_node([distrusted(NName, Now)], D11),
	set_junk(D11, [if], D11_1),
	add_parents(D11_1, [[OName]], D12),
	get_name(D11, D11name),
	assert(D12),
	assert(XNM))).

/*
handle_contra(New, Old, []):-
    get_assumptions(New, []), get_assumptions(Old, []), !,
    get_form(New, [NF|_]), get_form(Old, [OF|_]),
    get_name(New, NName), get_name(Old, OName),
    (done_new(Old)-> 
	 true ;
       (make_new_node([contra(NName, OName)], Z1), 
	set_parents(Z1, [NName, OName], Z2), set_junk(Z2, [if], XNM),
        (is_an_old_node(Old) -> delete_node(Old); true),
	assert(XNM))).
*/

handle_contra(New0, Old, [NNN]):-
    copy_term(New0, New),
    exactly_one_ass(New, Old, [X|Y], Node), !,
    (is_old_node(New0) -> true;
    (name_nodes([New0], [NNN]),
    index_nodes([NNN]),
    assert(NNN))).
handle_contra(New0, Old, [NNN]):-
    copy_term(New0, New),
    bigger_ass(New, Old, Bigger, [X|Y]), !,
    (is_old_node(New0) -> true;
    (name_nodes([New0], [NNN]),
    index_nodes([NNN]),
    assert(NNN))).
handle_contra(New, Old, [NNN]):-
    name_nodes([New], [NNN]),
    index_nodes([NNN]),
    assert(NNN).


distrust_descendants(O, N, T):- !,
    name_to_descendants(O, _, Do),
    list_to_ord_set(Do, Odo),
    name_to_descendants(N, _, No),
    list_to_ord_set(No, Ono),
    ord_union(Odo, Ono, Oho),
    distrust_each(Oho, T, O, N).

distrust_each([], _, _, _):- !.
distrust_each([X|Y], T, P1, P2):- 
    find_node(X, XF), !,
    get_formula(XF, Form),
    unindex(XF, X),
    make_new_node([distrusted(X, T)], D01),
    get_name(D01, D1name),
    set_junk(D01, [if], D01_1),
    add_parents(D01_1, [[P1, P2]], D02),
    assert(D02),
    distrust_each(Y, T, P1, P2).
distrust_each([X|Y], T, P1, P2):- !,
    assert(abort_it(X)),
    distrust_each(Y, T, P1, P2).

/*
distrust_each([X|Y], T, P1, P2):- !,
    find_new_node(X, XF),
    get_formula(XF, Form),
    unindexnewone(XF, X),
    name_nodes([X], [XNN]),
    assert(XNN),
    get_name(XNN, Xname),
    get_parents(X, Xpar),
    fix_parents(Xpar, Xname),
    make_new_node([distrusted(X, T)], D01),
    get_name(D01, D1name),
    add_parents(D01, [[P1, P2]], D02),
    assert(D02),
    distrust_each(Y, T, P1, P2).
*/
% problem above is that the new child we are distrustung is going to be
% filtered later, and bad things might happen.
% fixed that
% things are even more evil. if pne of the kids is a new one, it will have 
% been removed form the kb by the findall of the cleanit. so there is no
% way to get to it. the only way is to assert something and check that
% at each verification to see that we need not kill the new one. all we
% need to do is to unindexnewone, fixparents, namenodes and assert. the
% only thing we need to know is nothing.

% remember to dynamicize aboit_it/1 anf do the right intiazlise, reset thing.
% it gets even worse: the new child ight have already been processed so we
% have to pick it up at the end of the filtering. then we just unindex it.
