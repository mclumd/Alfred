%%% Copyright (c) 2003 SICS AB. All rights reserved.
%%% -----------------------------------------------------------------
%%%
%%% PROLOGBEANS
%%%
%%% Author  : Joakim Eriksson, Niclas Finne
%%% Created : 03-5-20
%%% Updated : $Date: 2004/01/13 14:02:18 $
%%%	      $Revision: 1.3 $
%%%
%%% A prologbeans server that is intended to be used for communication
%%% between Java (or other applications) and a prolog application.
%%% The prolog application needs to start up the server and
%%% register acceptable queries with associated predicates to call.
%%%

:- module(prologbeans, [start/0,start/1, shutdown/0, shutdown/1,
			register_query/2, register_query/3, unregister_query/1,
			%% register_session_listener/1,
			%% unregister_session_listener/1,
			%% register_server_listener/1,
			%% unregister_server_listener/1,

                        %% [PM] 3.10.1 consolidate all listeners
                        register_event_listener/2,
                        register_event_listener/3,
                        unregister_event_listener/1,
                        
			get_server_property/1,
			session_remove/1, session_get/4,
			session_put/3
%			pb_read_term_from_chars/3 %% [PD] Quintus 3.5
		       ]).

:- meta_predicate register_query(+,:).
:- meta_predicate register_query(+,:,+).
:- meta_predicate register_event_listener(+,:).
:- meta_predicate register_event_listener(+,:,-).
   
% for xref; these are metacalled from prologbeansserver
:- public
	connection/2,
	connection_closed/1,
	data_received/1,
	resume/0.

%%% [PD] Quintus 3.5/SICStus 3.11.1
%%%      Keep the source code synchronized between SICStus and Quintus.
%%%      The pseudo operators 'if' and 'endif' are an aid for keeping track
%%%      of the necessary differences in the two versions.

%%% if SICSTUS
/*
:- use_module(library(lists), [
        memberchk/2
	]).
:- use_module(library(terms), [
        acyclic_term/1
        ]).
:- use_module(library(charsio), [
	read_term_from_chars/3
	]).
:- use_module(library(system), [
        now/1
        ]).
*/
%%% endif SICSTUS
%%% if QUINTUS
%/*
:- use_module(library(basics), [
        memberchk/2
	]).
:- use_module(library(charsio), [
	with_input_from_chars/2
	]).
:- use_module(library(date), [
        now/1
        ]).
%*/
%%% endif QUINTUS

:- use_module(library(fastrw), [
        fast_read/2,
        fast_write/2
        ]).

%:- use_module(library(prologbeansserver)).
:- use_module(prologbeansserver).

:- dynamic session_info/2.
:- dynamic session_data/2.
%% :- dynamic session_listener_db/1.
:- dynamic session_timeout/1.
:- dynamic session_gc_timeout/1.
:- dynamic session_last_gc/1.
%% :- dynamic server_listener_db/1.
:- dynamic query_db/3.
:- dynamic accepted_host/1.
:- dynamic shutdown_mode/1.
:- dynamic server_port/1.
:- dynamic event_listener_db/2.


%% [PD] Quintus 3.5 We need something to emulate 'read_term_from_chars'
pb_read_term_from_chars(Chars, Term, Options) :-
    ( prologsystem(sicstus) ->
	read_term_from_chars(Chars, Term, Options)
    ;
	with_input_from_chars(read_term(Options,Term),Chars)
    ).

%% ------------------------------------------------------
%% start-up predicates
%% ------------------------------------------------------
start :-
    start([]).
start(Options):-
    init,
    retractall(accepted_host(_)),
    get_option(accepted_hosts(Hosts), Options, accepted_hosts(['127.0.0.1'])),
    set_hosts(Hosts),
    get_option(session_timeout(Timeout), Options, session_timeout(0)),
    session_set_timeout(Timeout),
    get_option(session_gc_timeout(GCTimeout), Options, session_gc_timeout(0)),
    session_set_gc_timeout(GCTimeout),
    get_option(port(Port), Options, port(8066)),
    open_socket(Port),
    retractall(server_port(_)),
    assert(server_port(Port)),
    new_thread(prologbeans),
    call_server_listeners(server_started),
    run,
    call_server_listeners(server_shutdown).

open_socket(Port) :-
    open_socket(Port, prologbeans).

shutdown:-
    shutdown(now).

shutdown(now) :-
    stop.
shutdown(no_sessions) :-
    assert(shutdown_mode(no_sessions)).
shutdown(no_connections) :-
    assert(shutdown_mode(no_connections)).

set_hosts([]).
set_hosts([Host|Hosts]) :-
    assert(accepted_host(Host)),
    set_hosts(Hosts).

get_option(Option, OptionList, DefaultValue) :-
    (  memberchk(Option, OptionList) ->
	true
    ;  otherwise ->
	Option = DefaultValue
    ).


%% ------------------------------------------------------
%% 'Hooks' for the communication server
%% ------------------------------------------------------
connection(Host, Stream) :-
    accepted_host(Host),!,
    new_stream(Stream, prologbeans).
connection(Host, _) :-
    print_message(error, prologbeans(denied(Host))).

connection_closed(Stream) :-
    session_remove(Stream).

data_received(Stream) :-
    pb_input_stream(Stream,IStream), % [PD]
    fast_read(IStream, Term),
    handle_input(Term, Stream).

%% ------------------------------------------------------
%% Query handling
%% ------------------------------------------------------
handle_input(query(Query, Bindings), Stream) :- !,
    get_session(Stream, Session),
    handle_input(query(Query, Bindings, Session), Stream).
handle_input(query(Query, Bindings, Session), Stream) :- !,
    now(CurrentTime),
    session_set_last_access(Session, CurrentTime),
    handle_query(Query, Bindings, Session, Stream).
handle_input(end_session(Session), Stream) :- !,
    session_remove(Session),
    send_result(Stream, session_removed(Session)).
handle_input(_Query, Stream) :-
    send_result(Stream, error('unknown query')).


%% A simple way of getting a "unique"? session ID of a Stream...
get_session(Stream, Stream).

prepare_vars([], _, []).
prepare_vars([VarBinding|Vars], Bindings, Unbounds) :-
    memberchk(VarBinding, Bindings), !,
    prepare_vars(Vars, Bindings, Unbounds).
prepare_vars([VarBinding|Vars], Bindings, [VarBinding|Unbounds]) :-
    prepare_vars(Vars, Bindings, Unbounds).


handle_query(Query, Bindings, Session, Stream) :-
    on_exception(Error, pb_read_term_from_chars(Query, Term,
						[variable_names(Variables)]),
                        syntax_error(Error)), !,
    prepare_vars(Variables, Bindings, Unbound),
    query(Term, Session, Unbound, Stream).
handle_query(_, _, _, Stream) :-
    send_result(Stream, error('syntax error')).

syntax_error(Error) :-
	print_message(error, prologbeans(read)),
	print_message(error, Error),
	fail.

query(Query, Session, Variables, Stream) :-
    query_db(Query, Predicate, Session), !,
    call_query(Predicate, Variables, Result),
    send_result(Stream, Result).
query(_Query, _, _, Stream) :-
    send_result(Stream, error('unknown query')).

call_query(Predicate, Preliminary, Result) :-
    on_exception(Error, (call(Predicate), Result = Preliminary),
		 Result = error(Error)), !.
call_query(_, _, no).

%% [PD] Quintus 3.5/SICStus 3.11.1
pb_acyclic_term(T) :-
    ( prologsystem(sicstus) ->
	acyclic_term(T)
    ;
	true			% A cyclic term in Quintus should be
				% considered a bug. Crash and burn!
    ).

send_result(Stream, Result) :-
    pb_acyclic_term(Result), !,	% [PD]
    pb_output_stream(Stream, OStream), % [PD]
    fast_write(OStream, Result),
    flush_output(OStream).
send_result(Stream, Result) :-
    print_message(error, prologbeans(cyclic(Stream,Result))),
    pb_output_stream(Stream, OStream), % [PD]
    fast_write(OStream, error('cyclic result')),
    flush_output(OStream).


%% ------------------------------------------------------
%% Query registry/unregistering
%% ------------------------------------------------------
register_query(Query, Predicate) :-
    nonvar(Query),
    retractall(query_db(Query, _, _)),
    assert(query_db(Query, Predicate, _)).

register_query(Query, Predicate, SessionVar) :-
    nonvar(Query),
    retractall(query_db(Query, _, _)),
    assert(query_db(Query, Predicate, SessionVar)).

unregister_query(Query) :-
    nonvar(Query),
    retractall(query_db(Query, _, _)).

%%%% [PM] 3.10.2 replaced by event listener API
%% %% ------------------------------------------------------
%% %% Session listener registration
%% %%
%% %% These predicates will be called in the session listener module
%% %% session_started(+SessionID)
%% %% session_ended(+SessionID)
%% %% ------------------------------------------------------
%%
%% register_session_listener(SessionListenerModule) :-
%%     nonvar(SessionListenerModule),
%%     retractall(session_listener_db(SessionListenerModule)),
%%     assert(session_listener_db(SessionListenerModule)).
%%
%% unregister_session_listener(SessionListenerModule) :-
%%     nonvar(SessionListenerModule),
%%     retractall(session_listener_db(SessionListenerModule)).
%%
%% call_session_listeners(Predicate) :-
%%     findall(SS, session_listener_db(SS), List),
%%     call_listeners(List, Predicate).
%%
%% %% ------------------------------------------------------
%% %% Server listener registration
%% %%
%% %% These predicates will be called in the server listener module
%% %% server_started
%% %% server_shutdown
%% %% ------------------------------------------------------
%% register_server_listener(ServerListenerModule) :-
%%     nonvar(ServerListenerModule),
%%     retractall(server_listener_db(ServerListenerModule)),
%%     assert(server_listener_db(ServerListenerModule)).
%%
%% unregister_server_listener(ServerListenerModule) :-
%%     nonvar(ServerListenerModule),
%%     retractall(server_listener_db(ServerListenerModule)).
%%
%% call_server_listeners(Predicate) :-
%%     findall(SS, server_listener_db(SS), List),
%%     call_listeners(List, Predicate).
%%
%% call_listeners([], _).
%% call_listeners([Module|Rest], Predicate) :-
%%     call_robust(Module,Predicate),
%%     call_listeners(Rest, Predicate).
%%
%% call_robust(H, G) :-
%%     catch(H:G, E, call_error(H,G,E)), !.
%% call_robust(H, G) :-
%%     format(user_error,'[PBEANS] - ~q failed to handle ~q~n',[H,G]).
%%
%% call_error(H, G, E) :-
%%     format(user_error,'[PBEANS] - ~q could not handle ~q: ~q ~n', [H,G,E]).
%%

%% ------------------------------------------------------
%% Event listener registration
%% ------------------------------------------------------

%% Register Goal as a handler for Event. Replaces any previosly
%% registered handler for Event.
register_event_listener(Event, Goal, Id) :-
   registrable_event(Event), !,
   %% functor(F,A,Event),
   %% functor(F,A,Template),
   %% retractall(event_listener_db(Template, _, _)),

   %% event listeners will be called last-registered-first. This is
   %% intentionally not documented.
   asserta(event_listener_db(Event, Goal), Ref),
   Id = Ref.
register_event_listener(Event, Goal, Id) :-
   ErrGoal = register_event_listener(Event, Goal, Id),
%%% if SICSTUS
%  prolog:illarg(domain(term,'valid event'), ErrGoal, 1, Event).
%%% endif SICSTUS
%%% if QUINTUS
   raise_exception(domain_error(ErrGoal,1,event-value,Event,0)).
%%% endif QUINTUS

register_event_listener(Event, Goal) :-
   register_event_listener(Event, Goal, _Id).

%% it is an error to unregister an event twice
unregister_event_listener(Id) :-
   erase(Id).


call_event_listeners(Event) :-
   event_listener_db(Event, Goal), % BT
   call_event_robust(Event, Goal),
   fail.
call_event_listeners(_Event).   

call_event_robust(Event, Goal) :-
   on_exception(Exception,
		call(Goal),
		call_event_error(Exception, Event, Goal)),
   !,
   true.
call_event_robust(Event, Goal) :-   
   call_event_failure(Event, Goal).

call_event_failure(Event, Goal) :-
    print_message(warning, prologbeans(handler_failure(Goal,Event))).

call_event_error(Exception, Event, Goal) :-
    print_message(error, prologbeans(handler_error(Goal,Event,Exception))).

%% matches valid events
registrable_event(Event) :- var(Event), !, fail.
registrable_event(server_started).
registrable_event(server_shutdown).
registrable_event(session_started(_SessionID)).
registrable_event(session_ended(_SessionID)).

call_server_listeners(Event) :-
   call_event_listeners(Event).

call_session_listeners(Event) :-
   call_event_listeners(Event).

%% ------------------------------------------------------
%% Session handling
%% ------------------------------------------------------

session_remove(SessionID) :-
    nonvar(SessionID),
    session_info(SessionID, _),!,
    call_session_listeners(session_ended(SessionID)),
    retractall(session_info(SessionID, _LastAccess)),
    retractall(session_data(SessionID, _Data)).
session_remove(SessionID) :-
    nonvar(SessionID).

session_get(SessionID, Name, _DefaultValue, Value) :-
    nonvar(SessionID),
    session_data(SessionID, List),
    memberchk(Name-Value, List), !.
session_get(_SessionID, _Name, Value, Value).

session_put(SessionID, Name, Value) :-
    nonvar(SessionID),
    session_data(SessionID, List),!,
    update_list(Name, Value, List, NewList),
    retractall(session_data(SessionID, _)),
    assert(session_data(SessionID, NewList)).
session_put(SessionID, Name, Value) :-
    nonvar(SessionID),
    assert(session_data(SessionID, [Name-Value])).

update_list(Name, Value, List, NewList) :-
    select(Name-_, List, Name-Value, NewList), !.
update_list(Name, Value, List, [Name-Value | List]).

% ripped off from QP/SP4
select(X, [X|Tail], Y, [Y|Tail]).
select(X, [Head|Xlist], Y, [Head|Ylist]) :-
	select(X, Xlist, Y, Ylist).

%% ---------------------------------------------------------
%% Server properties (more properties will be added in future versions)
%% ---------------------------------------------------------
get_server_property(port(Port)) :-
    server_port(Port).

%% ---------------------------------------------------------
%% Session timeout handling
%% ---------------------------------------------------------

session_set_last_access(SessionID, Time) :-
    nonvar(SessionID),
    retract(session_info(SessionID, _)),!,
    assert(session_info(SessionID, Time)).
session_set_last_access(SessionID, Time) :-
    nonvar(SessionID),
    assert(session_info(SessionID, Time)),
    call_session_listeners(session_started(SessionID)).

session_set_timeout(TimeoutSeconds) :-
    integer(TimeoutSeconds),
    retractall(session_timeout(_)),
    (  TimeoutSeconds > 0 ->
	assert(session_timeout(TimeoutSeconds))
    ;  otherwise ->
	true
    ).

session_set_gc_timeout(TimeoutSeconds) :-
    integer(TimeoutSeconds),
    retractall(session_gc_timeout(_)),
    (  TimeoutSeconds > 0 ->
	assert(session_gc_timeout(TimeoutSeconds))
    ;  otherwise ->
	true
    ).

session_get_last_garbage_collect(LastTime) :-
    session_last_gc(LastTime), !.
session_get_last_garbage_collect(0).

session_set_last_garbage_collect(LastTime) :-
    retractall(session_last_gc(_)),
    assert(session_last_gc(LastTime)).

session_maybe_garbage_collect :-
    session_gc_timeout(GCTimeout),
    session_timeout(_),
    session_get_last_garbage_collect(LastGarbage),
    now(CurrentTime),
    LastGarbage + GCTimeout < CurrentTime, !,
    session_garbage_collect(CurrentTime).
session_maybe_garbage_collect.

% unreachable
% session_garbage_collect :-
%     now(CurrentTime),
%     session_garbage_collect(CurrentTime).

session_garbage_collect(CurrentTime) :-
    session_timeout(TimeoutSeconds), !,
    OldestTime is CurrentTime - TimeoutSeconds,
    findall(Session, (session_info(Session, LastAccess),
			 LastAccess < OldestTime),
	    SessionsToRemove),
    session_gc(SessionsToRemove),
    session_set_last_garbage_collect(CurrentTime).
session_garbage_collect(CurrentTime) :-
    session_set_last_garbage_collect(CurrentTime).

session_gc([Session|Ss]) :-
    session_remove(Session),
    session_gc(Ss).
session_gc([]).


%% ---------------------------------------------------------
%% Timeout and shutdown handling
%% ---------------------------------------------------------

resume :-
    session_maybe_garbage_collect,
    check_shutdown.

check_shutdown :-
    shutdown_mode(Mode), !,
    check_shutdown(Mode).
check_shutdown.

check_shutdown(no_sessions) :-
    (  session_info(_, _) ->
	true
    ;  otherwise ->
	stop
    ).
check_shutdown(no_connections) :-
    (  has_open_connections ->
	true
    ;  otherwise ->
	stop
    ).
