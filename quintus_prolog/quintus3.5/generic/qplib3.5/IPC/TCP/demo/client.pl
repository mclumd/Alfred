%   SCCS   : @(#)93/04/21 client.pl	66.1
%   Author : Tom Howland
%   Purpose: demonstration of tcp software.
%   SeeAlso: server.pl, help(tcp)
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/* This is an example of a client repeatedly requesting a server to solve some
goal (r/2).  Arbitrarily many clients may connect to the server.

Follow these steps to run this demo.

    1. ?- [demo(server)]. go.

    2. open another window

    3. ?- [demo(client)].

    4. Then, if you're using a network transparent file system,

        ?- nfs.

       otherwise

        ?- rsh(Host),

       where Host is the name of a machine that can read the ServerFile.
*/

:-use_module(library(tcp)).

init:-
    prolog_flag(fileerrors, _, on),
    prolog_flag(syntax_errors, _, error),
    tcp_trace(_, on).

nfs:-
    init,
    tcp_address_from_file('~/tcp_demo_ServerFile', Address),
    tcp_connect(Address, _),
    loop.

rsh(Host):-
    init,
    tcp_address_from_shell(Host, '~/tcp_demo_ServerFile', Address),
    tcp_connect(Address, _),
    loop.
    
loop:-
    G = r(_,_),
    tcp_connected(Server),
    tcp_send(Server, satisfy(G)),
    repeat,
       tcp_select(Term),
       dispatch(Term, G),
    !.

dispatch(end_of_file(_), _).
dispatch(term(_,T), G):-
    dispatch_term(T, G),
    fail.

dispatch_term(fail, G):-
    tcp_connected(Server),
    tcp_send(Server, satisfy(G)).
