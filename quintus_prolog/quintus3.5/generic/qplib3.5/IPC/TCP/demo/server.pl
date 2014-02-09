%   SCCS   : @(#)94/01/17 server.pl	71.1
%   Author : Tom Howland
%   Purpose: demonstration of the tcp software.  Creates a simple server.
%   SeeAlso: help(tcp), client.pl, cs.c, add_2_numbers.c
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/* Arbitrarily many clients may connect to this server.

The simple directions for running this demo is to issue the following
command.

?- [demo(server)],go.

But all it will do is sit there, waiting for someone to start talking
to it.

The example programs listed in the files "client.pl", "cs.c" and
"add_2_numbers.c" use this demo.

If you are interested in Prolog calling this server, follow the
directions in the file "client.pl".  The client repeatedly requests
solutions to the relation "r/2".  It does this by sending it the term
"satisfy(Goal)".

If you are interested in C calling this server, follow the directions
in the files "cs.c" or "add_2_numbers.c".  Both of these work by sending
the server the term "not_prolog(Goal)".

*/

:-use_module(library(tcp)).

/* these r/2 relations are used by the sample program "client.pl" */

r(a,b).
r(b,c).
r(c,d).

init:-
    prolog_flag(fileerrors, _, on),
    prolog_flag(syntax_errors, _, error),
    tcp_trace(_, on).

go:-
    init,
    tcp_create_listener(Address, _),
    tcp_address_to_file('~/tcp_demo_ServerFile', Address),
    loop.

loop:-
    repeat,
        tcp_select(X),
        dispatch(X),
    fail.

dispatch(term(C,T)) :- dispatch_term(T,C).

/* the term "satisfy(RG)" is sent by the sample program "client.pl".  It
   is a form of remote procedure call. */

dispatch_term(satisfy(RG), C) :-
    (   on_exception(E, user:RG, eek(RG,C,E)),
        tcp_send(C, solution(RG))
    ;   tcp_send(C, fail)
    ).

/* the term not_prolog/1 is sent by the example programs "cs.c" and
"add_2_numbers.c".  All output is sent down the socket: current output
is set to the socket for the duration of the call.

Note that we're in a failure driven loop here.  It is assumed that the
sent goal has a finite number of solutions. */

dispatch_term(not_prolog(G), C):-
    current_input(CI),
    tcp_input_stream(C, I),
    set_input(I),
    current_output(CO),
    tcp_output_stream(C, O),
    set_output(O),
    (   on_exception(E, user:G, eek(G, C, E))
    ;   flush_output(O), set_input(CI), set_output(CO)
    ).

/* eek/3 is a little exception handler. */

eek(RG,C,E):-
    format(user_error,'*** exception while attempting ~q from ~q~n',[RG,C]),
    print_message(error, E).
