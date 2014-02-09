%   SCCS   : @(#)94/01/17 sibling.pl	71.1
%   Author : Tom Howland
%   Purpose: demonstration of tcp software.
%   SeeAlso: help(tcp)
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/* sibling.pl ...  this file demonstrates the tcp software for three connected
processes.

It has several interesting aspects.  Each is sending terms to each of
the other as fast as it can.  The messages are goals, so each process
has to satisfy a goal request before it can start demanding solutions
again.

Once connected, all three are sending and receiving goals to each other as
peers.  They may be interupted with a carriage return.

To run this demo,

    1	In each of three windows, invoke prolog and then say
        ?- [demo(sibling)].
    2   to each of the prolog windows running say ?- go.
    3   choose sue, then bob, then ann

*/

:-use_module(library(ask), [ask_oneof/3]).
:-use_module(library(date), [date_and_time/2]).
:-use_module(library(tcp)).

go :-
    prolog_flag(fileerrors, _, on),
    prolog_flag(syntax_errors, _, error),
    tcp_trace(_, on),
    %% [PM] April 2000, Added guard, tcp_watch_user not supported on windows
    ( prolog_flag(host_type, ix86) ->
        true
    ; tcp_watch_user(_,  on)
    ),
    ask_oneof('My Name (? for help)', [ann,bob,sue], N),
    'connect and/or listen'(N, r(_,_)),
    loop.

/* the distinction between clients and servers is based solely on how
connections are established.  Servers get connections by accepting
connection requests, clients get connections by requesting a
connection from a server. */

'connect and/or listen'(ann, G) :-  % ann is a pure client
    connect(bob, G),
    connect(sue, G).
'connect and/or listen'(bob, G) :-  % bob is a server to ann and a client to sue
    listen(bob),
    connect(sue, G).
'connect and/or listen'(sue, _) :-  % sue is a pure server
    listen(sue).

connect(Tag, G) :-
    server_file(Tag, F),
    tcp_address_from_file(F, A),
    tcp_connect(A, Socket),
    tcp_send(Socket, satisfy(G)).

server_file(bob,'~/tcp_demo_bob').
server_file(sue,'~/tcp_demo_sue').

listen(Tag) :-
    tcp_create_listener(Address, _),
    server_file(Tag, F),
    tcp_address_to_file(F, Address).

loop :-
    G = r(_,_),
    repeat,
	tcp_select(R),
	dispatch(R, G),
    fail.

dispatch(connected(C), G) :- tcp_send(C, satisfy(G)).
dispatch(user_input, _) :- format('
Received notification of keyboard input.  Type one of the following:

  a ... abort.  This clears the tcp database, sending an end_of_file to the
        other connected processes, and then aborts.
  b ... break. Enter prolog, return with a ^D.
  c ... continue.
',[]),
    ask_oneof('',[a,b,c],Action),
    action(Action).
dispatch(term(C,T), G) :-
    dispatch_term(T, C, G).

action(a) :- tcp_reset,abort.
action(b) :- break.
action(c).

dispatch_term(fail, C, G) :- tcp_send(C, satisfy(G)).
dispatch_term(satisfy(RG), C, _) :-
    (   on_exception(E, user:RG, eek(RG, C,  E)), tcp_send(C, solution(RG))
    ;   tcp_send(C, fail)
    ).

eek(RG,C,E):-
    format(user_error,'*** exception while attempting ~q from ~q~n', [RG,C]),
    print_message(error, E),
    fail.

/* r/2 is the goal that the siblings keep asking each other to solve. */

r(a, b).
r(b, c).
r(c, d).
r(Date, Time) :- date_and_time(Date, Time).
