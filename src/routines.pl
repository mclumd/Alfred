/* this file should contain the prolog code that alma can use */

:- ensure_loaded(library(caseconv)).
:- ensure_loaded(library(sets)).
:- consult('readdata.pl').
:- consult('domain.pl').
:- consult('introspectmatch.pl').

mult_gather_all([S|Schemae],Asserts) :-
    gather_all(S,Asserts1),
    mult_gather_all(Schemae,Asserts2),
    append(Asserts1,Asserts2,Asserts).

mult_gather_all([],[]).

idling_for_steps(Steps):-
    step_number(CurNow),
    idling_for_past(CurNow, Steps).

idling_for_past(Current,Steps) :-
    Prev is Current - 1,
    clause(idling_step(Prev), true),
    Count is Steps - 1,
    idling_for_past(Prev, Count).
idling_for_past(_,0).


delete_expect_lists([List|Lists]) :-
    df(expect_list(List)),
    delete_expect_lists(Lists).
delete_expect_lists([]).

satisfied_expects(Utt) :-
    gather_all(expect(Utt,_), EList),
    gather_all(satisfied(Utt, _), SList),
    length(EList,L),
    length(SList,L).

satisfied_needs(Utt) :-
    gather_all(need(Utt,_), NList),
    gather_all(satisfied(Utt, _), SList),
    length(NList,L),
    length(SList,L).

thought(Utt,Need, Asserts):-
    pos_int_u(done(ac_think(Utt, Need), Asserts,Utt)).

thinking(Utt,Need, Asserts):-
    pos_int_u(doing(ac_think(Utt, Need), Asserts,Utt)).

asked(Utt,Need, Asserts):-
    pos_int_u(done(ac_ask(Utt, Need), Asserts,Utt)).

asking(Utt,Need, Asserts):-
    pos_int_u(doing(ac_ask(Utt, Need), Asserts,Utt)).


sending_to_domain(Tag, List) :-
    tcp_output_stream(Tag,S),
    print(S,List), nl(S), nl(S),
    format(S, '~N',[]).

print_pauselen(PauseLength) :-
	format('~N pauselength = ~d ~N', [PauseLength]).

/*update_pauselen(Step, CurrUttStep, PromptStep, PrevPause, _) :-
	step_number(Step),
	CurrUttStep > PromptStep,!,
	Pause is Step - CurrUttStep,
	Discrep is CurrUttStep-PromptStep,
	format('~N 1. Pause = ~d ~N', [Pause]),
	format('~N 1. Discrep = ~d ~N', [Discrep]),
	NewPause is PrevPause + Discrep,
	df(expected_pause(PrevPause)),
	af(expected_pause(NewPause)).

update_pauselen(Step, _, PromptStep, _, CurrWait) :-
	step_number(Step),
	PromptPause is Step - PromptStep,
	NewWait is CurrWait + 1,
	df(curr_wait_time(CurrWait)),
	af(curr_wait_time(NewWait)),
	format('~N 2. CurrWait = ~d ~N', [NewWait]),
	format('~N 2. Pause = ~d ~N', [PromptPause]).
*/

/*update_wait_time(Step, CurrUttStep, _, _, CurrWait,_) :-
	CurrUttStep = Step-2, !,
	step_number(Step),
	df(curr_wait_time(CurrWait)),
	af(curr_wait_time(0)),
	format('~N 1. WAIT RESET = 0 ~N', []).
*/
update_wait_time(Step, _, _, ExpPause, CurrWait,LocalViol) :-
	step_number(Step),
	NewWait is CurrWait + 1,
	NewWait > ExpPause, !,
	df(curr_wait_time(CurrWait)),
	af(curr_wait_time(0)),
	NewViolations is LocalViol + 1,
	df(local_violations(LocalViol)),
	af(local_violations(NewViolations)),
	format('~N 1. CurrWait = ~d ~N', [NewWait]),
	format('~N 1. PAUSE TIME EXCEEDED, NumViolations = ~d ~N', [NewViolations]).

update_wait_time(Step, _, _, ExpPause, CurrWait,_) :-
	step_number(Step),
	NewWait is CurrWait + 1,
	df(curr_wait_time(CurrWait)),
	af(curr_wait_time(NewWait)),
	format('~N 2. CurrWait = ~d ~N', [NewWait]),
	NewWait > ExpPause.

switch_user(PrevUser, CurrUser) :-
	\+ (CurrUser = PrevUser),
	df(curr_user(PrevUser)),
	df(equil(_,CurrUser)).

add_user_to_utt(Utt) :-
	pos_int_u(curr_user(Username)), !,
	af(user_utt(Utt,Username)).

add_user_to_utt(Utt) :-
	af(user_utt(Utt,none)).

revise_expectation(MaxViol, ExpPause, LocalViol, GlobViol, CurrUttStep) :-
	%GlobViol >= MaxViol,
	pos_int_u(utt_on_time(UttOnTime)),
	TotalUtt is UttOnTime + GlobViol,
	TotalUtt>=3,
	pos_int_u(violation_density(Density)),
	Density > 0.5,
	df(global_violations(GlobViol,LocalViol,CurrUttStep)),
	af(global_violations(0,0,0)),
	df(expected_pause(ExpPause)),
	Avg is LocalViol / MaxViol,
	NewPause is Avg,
	format('~N NEW EXPECTATION ~N', []),
	af(expected_pause(NewPause)).	

update_global_violations(CurNow) :-
	pos_int_u(global_violations(GlobViol,GLoc,PrevUtt)),
	pos_int_u(violation_density(PrevDensity)),
	pos_int_u(utt_on_time(UttOnTime)),
	pos_int_u(local_violations(LocalViol)),
	pos_int_u(expected_pause(ExpPause)),
	pos_int_u(prompt_step(PrevPrompt)),
	LocalViol > 0, !,
	Discrep is (CurNow-PrevPrompt)/2.0,
	NewViol is GlobViol + 1,
	TotalUtt is UttOnTime + NewViol,
	NewDensity is NewViol/TotalUtt,
	df(violation_density(PrevDensity)),
	af(violation_density(NewDensity)),
	format('~N GlobalViolation = ~d ~N', [NewViol]),
	df(global_violations(GlobViol,GLoc,PrevUtt)),
	NewLoc is LocalViol*ExpPause + GLoc + Discrep,
	af(global_violations(NewViol,NewLoc,CurNow)),
	df(local_violations(LocalViol)),
	af(local_violations(0)).

update_global_violations(_) :-
	pos_int_u(utt_on_time(PrevOnTime)),
	CurrOnTime is PrevOnTime + 1,
	df(utt_on_time(PrevOnTime)),
	af(utt_on_time(CurrOnTime)),
	format('~N Utterance On Time ~N', []).

update_current_utterance(Utt, CurNow) :-
	pos_int_u(currUtt(PrevUtt, PrevNow)),
	\+ (Utt = PrevUtt),
	format('~N UTTERANCE = ~d, ~d ~N', [PrevNow, CurNow]),
	df(prev_utt_time(_)),
	af(prev_utt_time(PrevNow)),
	df(currUtt(PrevUtt, PrevNow)),
	af(currUtt(Utt, CurNow)),
	pos_int_u(curr_wait_time(CurrWait)),
	df(curr_wait_time(CurrWait)),
	af(curr_wait_time(0)).

list_sum([], 0).
list_sum([Head | Tail], TotalSum) :-
	list_sum(Tail, Sum1),
	TotalSum is Head + Sum1.

compute_new_expectation(Avg) :-
    gather_all(global_violations(_,_,_), VList),
	length(VList,L),
	list_sum(VList,VTotal),
	Avg is L/VTotal,
	format('~N GLOBAL VIOLATIONS = ~d ~N', [VList]).


