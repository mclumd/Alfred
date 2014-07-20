/*
File: toplevel.pl
By: kpurang
What: the toplevel file 
      initializes
      processes command line args
      has a bunch of interactive settable parameters

Todo: split the initialization into a real_init and a save_parm_init and
      more if need be
      split into makefiles rather thn acompileing all here.

*/


% toplevel.pl
%added by anna 1/9/07
%:- ensure_loaded(library(shlib).
%:- ensure_loaded(library(ask)).
%:- ensure_loaded(library(tcp)).
:- ensure_loaded(library(date)).
:- ensure_loaded(library(lists)).
:- compile(['dbman/dbman.pl', ds, 'res/res.pl', 'interfaces/ui.pl', 
	    'parser/cnf.pl', misc, 'interfaces/xint.pl', almahelp, 
	    handle_contra, 'internal/decl.pl', 'interfaces/do_demo.pl']).
% :- load_files(['advice.pl']).
:- load_files(ctime2, [when(compile_time)]).
:- compile([compdate]).

% below is for staticcall

%:- load_files(['dbman.pl', 'ds.pl', 'res.pl', 'ui.pl', 'cnf.pl', 
%	       'misc.pl', 'xint.pl'], [all_dynamic(true)]).





initialize:-
    retractall(node(_,_,_,_,_,_,_,_,_,_)),
    retractall(new_node(_,_,_,_,_,_,_,_,_,_)),
    retractall(func_node(_,_, _)),
    retractall(conn_node(_, _)),
    retractall(agenda(_)),
    retractall(node_count(_)),
    retractall(step_number(_)),
    retractall(history(_, _)),
    retractall(agenda_time(_)),
    retractall(agenda_number(_)),
    retractall(bc_rules(_)),
    retractall(fc_rules(_)),
    retractall(tree_to_delete(_)),
    retractall(statistics(_)),
    retractall(number_of_nodes(_)),
    retractall(verbose(_)),
    retractall(show_step(_)),
    retractall(func_new_node(_, _, _)),
    retractall(new_node_count(_)),
    retractall(done_new(_)),
    retractall(delete_trees(_)),
    retractall(draw_graph(_)),
    retractall(slave_tag(_)),
    retractall(parser_tag(_)),
    retractall(domain_tag(_)),    
    retractall(action_list(_)),
    retractall(failed_call(_)),
    retractall(delay(_)),
    retractall(keyboard(_)),
    retractall(run(_)),
    retractall(history_file(_)),
    retractall(history_dump(_)),
    retractall(deleted_forms(_)),
    retractall(history_stream(_)),
    retractall(debug_level(_)),
    retractall(debug_stream(_)),
    retractall(timelimit(_)),
    retractall(memlimit(_)),
    retractall(almagenda(_)),
    retractall(al_files_to_load(_)),
    retractall(functionalist(_, _, _, _)),
    retractall(node_index(_, _, _)),
    retractall(new_node_index(_, _, _)),
    retractall(pred2hash(_, _)),
    retractall(newpred2hash(_, _)),
    retractall(contra_distrust_descendants(_)),
    retractall(abort_it(_)),
    retractall(pending_contra(_, _, _, _)),
    retractall(alma_prompt(_)),
    retractall(hist_add(_, _)),
    retractall(hist_del(_, _)),
    retractall(to_add_to_hist(_)),
    retractall(deleted_forms(_)),

    assert(agenda([])),
    assert(node_count(0)),
    assert(new_node_count(0)),
    assert(step_number(0)),
    assert(agenda_time(0)),
    assert(agenda_number(2000)),
    assert(bc_rules([])),			  % read from file?
    assert(fc_rules([])),
    assert(tree_to_delete([])),
    assert(statistics(false)),
    assert(number_of_nodes(0)),
    assert(verbose(false)),
    assert(show_step(false)),
    assert(delete_trees(false)),
    assert(draw_graph(false)),
    assert(history_stream(nohistory)),
    assert(history_dump(false)),
    assert(deleted_forms([])),
    assert(contra_distrust_descendants(true)),
    assert(to_add_to_hist([])),
    assert(distrusted_forms([])),

						  % taken care of by args
    assert(slave_tag(false)),    
    assert(parser_tag(false)),
    assert(domain_tag(false)),
    assert(action_list([])),
    assert(failed_call(false)),
    assert(delay(0.1)),
    assert(keyboard(false)),
    assert(run(true)),
    assert(debug_level(0)),
    assert(debug_stream(nil)),
    assert(timelimit(6000000)),
    assert(memlimit(100000000)),
    assert(almagenda([])),
    assert(al_files_to_load([])),
    assert(alma_prompt(true)),
%    assert(functionalist(dummy, 0, null, nul)),

%    compile('aux.pl'),
    res_init.					  % for inference rules


set_agenda_number(X):-
    retract(agenda_number(_)),
    assert(agenda_number(X)).

get_agenda_number(X):-
    agenda_number(X).

yesverbose:-
    retract(verbose(_)),
    assert(verbose(true)).
noverbose:-
    retract(verbose(_)),
    assert(verbose(false)).

yesstatistics:-
    retract(statistics(_)),
    assert(statistics(true)).
nostatistics:-
    retract(statistics(_)),
    assert(statistics(false)).

yesshowstep:-
    retract(show_step(_)),
    assert(show_step(true)).
noshowstep:-
    retract(show_step(_)),
    assert(show_step(false)).

yesdeletetrees:-
    retract(delete_trees(_)),
    assert(delete_trees(true)).
nodeletetrees:-
    retract(delete_trees(_)),
    assert(delete_trees(false)).

yesdrawgraph:-
    retract(draw_graph(_)),
    assert(draw_graph(true)).
nodrawgraph:-
    retract(draw_graph(_)),
    assert(draw_graph(false)).

main:- 
    initialize,
    unix(argv(L)),
    statistics(_),
    handle_args(L),
    ((debug_level(1); debug_level(2); debug_level(3)) -> 
	  (debug_stream(DBGS), print(DBGS,'Args: '), print(DBGS, L)
	  , nl(DBGS)); true),
    debug_stream(DBGS),nl(DBGS),print(DBGS, 'before loading'),nl(DBGS),
	load_alma_files,
    debug_stream(DBGS),nl(DBGS),print(DBGS, 'loaded files'),nl(DBGS),
	(verbose(true) -> print(L), nl; true),
    (verbose(true) -> print_compiled; true),
    (keyboard(true) -> print_compiled; true),
    (run(true) -> almar; almanr).

/* 
List of arguments:

verbose X
X is true or false
default: false

sfile X
X is the name of the tcpfile written by the action process
default: none

keyboard X
X is true or false
default: false

delay X
X is a real number.
default: 0.1

run X
X is true or false
Default: true

alfile X
X is the file with active logic sentences
Default: none

load X
X is the name of the prolog file to be loaded.
Default: none.

history X
X is the name of the file into which to dump history

histoken X
X is the tcp file that contains info as to where the history is to be sent

prompt X
X is true or false. Default true. Useful only at keyboard.

debug N Fname
Fname is the name of the file in which the debugging information will go.
N is the debug level:
0: nothing
1: show step, afs, dfs, tcp input, tcp output
2: show agenda
3: show successful resolutions

demo Fname
Start a demo, interpreting Fname instuctions.

mclfile X
X is the file with host info for MCL

*/

handle_args([]):- !.
handle_args([help|_]):- !,
    dump_file('./almaargs'),
    halt.
handle_args([deletetrees, F|Z]):- !,
    retract(delete_trees(_)),
    assert(delete_trees(F)),
    (verbose(true) -> print('delete_trees'), nl; true),
    handle_args(Z).
handle_args([alfile, F|Z]):- !,
    retract(al_files_to_load(F2)),
    assert(al_files_to_load([F|F2])),
    (verbose(true) -> print('loading'), nl; true),
    handle_args(Z).
/*Added Darsana for parser process communication*/
handle_args([pcfile, F|X]):- !,
    connect_parser(F),
    (verbose(true) -> print('connecting to parser'), nl; true),
    handle_args(X).
/*END of Addition - Sep 14*/

/*For domain communication - July 4th - Darsana*/
handle_args([dfile, F|X]):- !,
    connect_domain(F),
    (verbose(true) -> print('connecting to domain'), nl; true),
    handle_args(X).


handle_args([sfile, F|X]):- !,
    connect_slave(F),
    (verbose(true) -> print('connecting'), nl; true),
    handle_args(X).
handle_args([histocket, F|X]):- !,
	print('connecting to history toplevel'),nl,
    connect_history(F),
    (verbose(true) -> print('connecting'), nl; true),
    handle_args(X).
handle_args([keyboard, A|X]):- !,
    (verbose(true) -> print('keyboard'), nl; true),
    retractall(keyboard(_)),
    assert(keyboard(A)),
    handle_args(X).
handle_args([delay, T|X]):-
    (verbose(true) -> print('delay'), nl; true),
    retractall(delay(_)),
    assert(delay(T)),
    handle_args(X).
handle_args([run, A|X]):- !,
    (verbose(true) -> print('run'), nl; true),
    retractall(run(_)),
    assert(run(A)),
    handle_args(X).
handle_args([verbose, A|X]):- !,
    retractall(verbose(_)),
    assert(verbose(A)),
    handle_args(X).
handle_args([load, A|X]):- !,
    on_exception(_, load_files(A), halt),
    handle_args(X).
handle_args([history, A|X]):- !,
    (verbose(true) -> print('History'), nl; true),
    open(A, write, S),
    retract(history_dump(_)),
    assert(history_dump(true)),
    retract(history_stream(_)),
    assert(history_stream(S)),
    handle_args(X).
handle_args([statistics|X]):-
    retract(statistics(_)),
    assert(statistics(true)),
    handle_args(X).
handle_args([debug, N, Fname|X]):-
    retract(debug_level(_)),
    assert(debug_level(N)),
    retract(debug_stream(_)),
    open(Fname, write, S),
    assert(debug_stream(S)),
    handle_args(X).
handle_args([timelimit, T|X]):-
    retract(timelimit(_)),
    assert(timelimit(T)),
    handle_args(X).
handle_args([memlimit, T|X]):-
    retract(memlimit(_)),
    assert(memlimit(T)),
    handle_args(X).
handle_args([demo, F|_]):-!, 
    do_demo(F).
handle_args([prompt, A|X]):- !,
    retractall(alma_prompt(_)),
    assert(alma_prompt(A)),
    handle_args(X).

/*handle_args([mclfile, F|X]):- !,
    connect_mcl(F),
    (verbose(true) -> print('connecting to mcl'), nl; true),
    handle_args(X).
*/

handle_args([_|X]):- !,
    (verbose(true) -> print('error'), nl; true),
    handle_args(X).


handle_args:-
    unix(argv(L)),
    print(L), nl, 
    handle_slave_arg(L).

handle_slave_arg(L):-
    nth0(N, L, slave), !,
    N1 is N + 1,
    nth0(N1, L, F),
    print(F),
    assert(slave_tag(false)).
handle_slave_arg(_):- 
    print('no slave'), nl,
    assert(slave_tag(false)).


dump_file(X):-
    open(X, read, S),
    set_input(S),
    repeat,
      get0(Z),
      put(Z),
      at_end_of_stream, !,
    close(S).

load_alma_files:- 
    al_files_to_load(F),
    real_laf(F).

real_laf([]):- !, true.
real_laf([X|Y]):-
    lf(X),!,
    print('done loading lf'),nl,
    real_laf(Y).

%:-runtime_entry(start).

