%%% -*- Mode: Prolog; Module: pbtest; -*-
%%% pbtest.pl
%%% Copyright (c) 2003 SICS AB. All rights reserved.
%%% -----------------------------------------------------------------
%%%
%%% Author  : Joakim Eriksson
%%% Created : 03-5-22
%%% Updated : $Date: 2004/01/13 14:02:18 $
%%%	      $Revision: 1.2 $
%%% Purpose : PrologBeans example
%%%

:- module(pbtest,[main/0,my_predicate/2]).

:- use_module(library(prologbeans)).
:- use_module(library(lists),[]).

%% Register acceptable queries and start the server (using default port)
main:-
    register_query(evaluate(C,P), my_predicate(C, P)),
    register_query(reverse(C,P), lists:reverse(C, P)),
    register_query(developers(Dev), developers(Dev)),
    register_query(shutdown, shutdown_server),
    register_event_listener(server_started, server_started_listener),
    register_event_listener(server_shutdown, server_shutdown_listener),
    register_event_listener(session_started(SessionID), session_started_listener(SessionID)),
    register_event_listener(session_ended(SessionID), session_ended_listener(SessionID)),
    %% Note: By specifying an uninstantiated port we will let the OS assign an unused port.
    %%       The port used will be obtained by server_started_listener below.
    start([port(_Port)]),
    halt.

%% Event listener callbacks
server_started_listener :-
    get_server_property(port(Port)),
%    format(user_error, 'port:~w\n', [Port]),
    format(user_error, 'port:~w~n', [Port]), % [PD]
    flush_output(user_error).

server_shutdown_listener :-
   format(user_error, '~Npbtest.pl: Shutdown server~n', []),
   flush_output(user_error).

session_started_listener(SessionID) :-
   format(user_error, '~Npbtest.pl: Starting session ~q~n', [SessionID]),
   flush_output(user_error).
session_ended_listener(SessionID) :-
   format(user_error, '~Npbtest.pl: Ending session ~q~n', [SessionID]),
   flush_output(user_error).


%% In this case we know that we have received a list of characters
%% that needs to be converted into an expression!
my_predicate(Chars, P) :-
    prologbeans:pb_read_term_from_chars(Chars, X, []),
    P is X.

% get all the answers from the "developer" predicate
developers(Dev) :-
    findall(D, developer(D), Dev).

shutdown_server :-
    shutdown(now).

%% The developers
developer('Joakim').
developer('Niclas').
developer('Per').
