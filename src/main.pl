/* The alma-carne interface routines
Darsana Purushothaman Josyula*/ 

:- consult('matchwords.pl').
:- consult('findlinks.pl').
:- consult('findcommand.pl').
:- consult('findintention.pl').
:- consult('aactions.pl').
:- consult('dactions.pl').
:- consult('think.pl').
:- consult('generator.pl').
:- consult('parsephrase.pl').
:- consult('fixlinkage.pl').
:- consult('misc.pl').
:- consult('postprocess.pl').

%:- ensure_loaded(library(basics)).
%:- ensure_loaded(library(strings)).
:- ensure_loaded(library(ctypes)).
:- ensure_loaded( library(lists)).
%:- ensure_loaded(library(caseconv)).
%:- ensure_loaded( library(listparts)).
:- ensure_loaded(library(socket)).

ac_find_links(U) :-
    find_links(U).

/*change later*************************/

ac_set_pause(Pause) :-
    df(expected_pause(_)),
    af(expected_pause(Pause)).

ac_mclask(Tag, Step) :-
    format('~N hello from ac_mclask pause ~d steps ~N', [Step]),
    mcl_update(Tag, Step).

ac_fix_linkage(Utt,Length) :-
   fix_linkage(Utt, Length).

/*mcl_update(Tag, Step) :-
    format('~N Sending pauselen ~d and tag ~d to MCL ~N', 
[Step, Tag]),
    tcp_output_stream(Tag, S),
	format('~N testing ~N', []),
    format(S, 'monitor(name,{pauselen=~d})', [Step]),
	format('~N testing two ~N', []),
    flush_output(S).*/
    /* todo: receive actual output via ruby script here */
    /*tcp_input_stream(?socket, -stream)*/
/*    tcp_input_stream(Tag, Sin),
    set_input(Sin),
    af(try_again).*/
/* todo: if statements */

mcl_respond(Tag) :-     /* failed/ignored/used */
    format('~Nused~N',[]),
    %tcp_output_stream(Tag, S),
    tcp_open_socket(Tag, _, S),
    format(S, 'used', []).

/* change to use utt_struct */
ac_main_verb(U) :-
    verb(U,Verb),
    value_of(U,Verb,Val),
    af(main_verb(U,Val)).

ac_parse_phrase(Utt,Need) :-
    parse_phrase(Utt, Need).

ac_find_unused_cost(Utt) :-
    findall([V,Val], value_of(Utt, V, Val), Values),
    find_unused_cost(Utt, Values, Unused),
    unused_cost(Utt, K, _),
    df(unused_cost(Utt, K, _)),
    af(unused_cost(Utt, K, Unused)).
    
ac_find_command(Utt) :-
    find_command(Utt). 

ac_find_intention(Utt, Type, Command) :-
    find_intention(Utt, Type, Command).

ac_action(_,alfred, List, CurNow) :-
    alfred_action(List, CurNow).

ac_action(_,alfred, List) :-
    alfred_action(List).

ac_action(Utt, domain, List) :- 
    domain_action(Utt, List).

ac_think(Utt, Needs) :-
    think(Utt, Needs).

ac_ask(_, Needs) :-
    ask(Needs).

ac_prompt(Step,PrevStep) :-
	%prompt_step(PrevStep),
	df(prev_prompt_time(_)),
	af(prev_prompt_time(PrevStep)),
	df(prompt_step(_)),
	af(prompt_step(Step)),
    prompt(Step).

ac_report_fail(_, List) :-
    report_fail(List).

ac_report_action(List) :-
    report_action(List).

ac_report_observation(_,O,current) :-
    setof(T, observation(O,_,T), Times),
    last(_,Last,Times),
    observation(O,R,Last),
    report_observation(O,R).

ac_report_observation(_,O,all) :-
    observation(O,R,_),
    report_observation(O,R).

ac_post_process(Utt, List) :-
    post_process(Utt, List).

