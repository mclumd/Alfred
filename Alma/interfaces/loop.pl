/*
File: interfaces/loop.pl
By: kpurang
What: top level loops.

Todo: why are the loops so big?     


*/

% do this if run is true
almar:-
    (keyboard(true)-> tcp_watch_user(_, on); true),
    repeat,
    sr,
    fail, !,
    true.

sr:- !,
   ((debug_level(2); debug_level(3); statistics(true)) -> statistics(runtime, [_, _]); true),
    checklimits,
    retract(almagenda(ALMAGENDA)),
    assert(almagenda([])),
    do_almagenda(ALMAGENDA),
    delay(DT),
    step_number(PStep),
    increment_step,
    step_number(Step),
    ((debug_level(1); debug_level(2); debug_level(3)) -> 
	  (debug_stream(DBGS), nl(DBGS), print_time(DBGS), print(DBGS, 'Step'),
	   print(DBGS, Step), nl(DBGS)); true),
    df(now(PStep)),
    get_new_node_name(StepName),
%
% reacts immediately if there is something to work on, else sleeps
%  ignores that agenda might someday be nonempty
%
%    listing(new_node),
    (new_node(DTN, DTF, _, _, _, _, _, _, _, _) -> 
    Deetee = 0 ; Deetee = DT),
    assert(new_node(StepName, [now(Step)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    index_new_node(new_node(StepName, [now(Step)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    unindex_new_done,
    retractall(done_new(_)),
      (tcp_select(Deetee, Ans) -> respond_input(Ans); true),
    handle_action_list,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    findall(Name, new_node(_,Name, _, _, _, _, _, _, _, _), NewNodes),    
    assert_idle(NewNodes,Step),
    
    clean_new_nodes(Cnn),	
    delete_bad_trees,
    historicize(Cnn),
    ((debug_level(2); debug_level(3); statistics(true)) -> statistics(runtime, [_, Filter_Time]); true),
    list_tasks(Cnn, Lot),
    order_tasks(Lot, Olot),
    ((debug_level(2); debug_level(3)) -> (debug_stream(DBGS2), 
                                          print(DBGS2, 'Agenda'), nl(DBGS2), 
					  print_agenda(DBGS2, Olot)); true),
    do_tasks(Olot),
    his_deletes,
    ((debug_level(1); debug_level(2); debug_level(3)) -> 
	  (debug_stream(DBGS3), nl(DBGS3), print_time(DBGS3)); true),
    ((debug_level(3); debug_level(2); statistics(true)) ->
	 (debug_stream(DBGS4), statistics(runtime, [_, Exec_Time]),
	 format(DBGS4, 'Filter time: ~dms~n', Filter_Time),
	 format(DBGS4, 'Inference time: ~dms~n', Exec_Time),
	 statistics(memory, [M, _]),
	 format(DBGS4, 'Memory used: ~d~n', M),
	 number_of_nodes(NN),
	 format(DBGS4, 'Number of clauses: ~d~n', NN),
	 agenda(AN), length(AN, ALN),
	 format(DBGS4, 'Length of agenda: ~d~n', ALN)); true),
   ((debug_level(1); debug_level(2); debug_level(3)) -> 
    debug_stream(DBGS5), flush_output(DBGS5); true).


assert_idle([], Step) :-
    af(idling(Step)),
    assert(idling_step(Step)),!.

assert_idle([[now(_)]|Nodes], Step) :-
    assert_idle(Nodes, Step),!.

assert_idle(_,Step) :-
    ((debug_level(1); debug_level(2); debug_level(3)) -> 
	  (debug_stream(DBGS3), nl(DBGS3), format(DBGS3, 'not idling ~d~n', Step)); true).

respond_input(A):- 
    respond_input1(A),
    tcp_select(0, term(X, Y)), !,
    respond_input(term(X, Y)).
respond_input(_):- !.

respond_input1(user_input):- !,
    prompt(_, 'AlMa> '),
    on_exception(_, read(Input), handle_call),
    handle_input(Input).
respond_input1(term(Tag, T)):- !,
    ((debug_level(1); debug_level(2); debug_level(3)) -> 
	  (debug_stream(DS), print(DS, 'Received '), 
	   print(DS, T), nl(DS)); true),
    (verbose(true) -> print(T), nl; true),
    answer_process(term(Tag, T)).
respond_input1(_):- !.


% do this if run is false
almanr:-
    alma_prompt(false), !, 
    almanrpf.
almanr:- !,
    almanrpt.

almanrpt:-
    print('For help, type alma_help.'), nl, nl,
    repeat,
    format('alma: ', []), ttyflush,
    on_exception(_, read(Input), handle_call),
    handle_input(Input), 
    Input = 'quit', !.

almanrpf:-
    repeat,
    on_exception(_, read(Input), handle_call),
    handle_input(Input), 
    ttyflush,
    Input = 'quit', !.

/*
almanr:-
    print('For help, type alma_help.'), nl, nl,
    repeat,
    format('alma: ', []), ttyflush,
    on_exception(_, read(Input), handle_call),
    handle_input(Input), 
    Input = 'quit', !.
*/

s:- !,
    delay(DT),
    step_number(PStep),
    increment_step,
    step_number(Step),
    (verbose(true) -> print(Step), nl; true),
    df(now(PStep)),
    % delete the old NOW,
    % add the new NOW,
    get_new_node_name(StepName),
    assert(new_node(StepName, [now(Step)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    index_new_node(new_node(StepName, [now(Step)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    unindex_new_done,
    retractall(done_new(_)),
    (slave_tag(false) -> true;
      (tcp_select(DT, Ans) -> answer_process(Ans); true)),
    handle_action_list,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    (show_step(true) -> (step_number(Sn),
			 format('Step: ~d~n', Sn)); true),
    (statistics(true) -> statistics(runtime, [_, _]); true),
    clean_new_nodes(Cnn),
    delete_bad_trees,
    historicize(Cnn),
    (statistics(true) -> statistics(runtime, [_, Filter_Time]); true),
    list_tasks(Cnn, Lot),
    (statistics(true) -> (length(Lot, LAg),
                          format('Agenda size: ~d~n', [LAg])); true),
    order_tasks(Lot, Olot),
    do_tasks(Olot),
    his_deletes,
    (statistics(true) ->
	 (statistics(runtime, [_, Exec_Time]),
	 format('Filter time: ~dms~n', Filter_Time),
	 format('Inference time: ~dms~n', Exec_Time),
	 statistics(memory, [M, _]),
	 format('Memory used: ~d~n', M),
	 number_of_nodes(NN),
	 format('Number of clauses: ~d~n', NN)); true).

s(0).
s(N):-
    M is N - 1,
    s,
    s(M).

sts:- 
    increment_step,
    step_number(Step),
    df(now(_)),
    % delete the old NOW,
    % add the new NOW,
    get_new_node_name(StepName),
    assert(new_node(StepName, [now(Step)], fc, [], [], 
                    Step, 1, [], [], [if])), 
    print('New nodes before cleaning:'), nl,
    listing(new_node/10),
    clean_new_nodes(N),
    delete_bad_trees,
    historicize(N),
    print('All nodes:'), nl,
    listing(node/10),nl,
    list_tasks(N, Lt), nl,
    print('New nodes after listing tasks:'), nl,
    listing(new_node/10), nl,
    print('Agenda:'), nl,
    print_agenda(user_output, Lt),
    do_tasks(Lt),
    print('new nodes after applying rules:'), nl,
    listing(new_node/10).












