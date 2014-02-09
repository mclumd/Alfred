%   File   : 07/29/91 @(#)c_server.pl	64.2 
%   Author : Tom Howland
%   SCCS   : @(#)91/07/29 c_server.pl	64.2
%   Purpose: demonstration of the tcp software.  Connects to a simple c server.
%   SeeAlso: c_server.c, help(tcp)
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/* This file demonstrates a Prolog client interacting with a C server.
The name c_server.pl is somewhat confusing.

Follow these steps to run this demo.

    1. open another window and run the c program c_server.

        % c_server foo

       where "foo" is the name of the file that this prolog program will use
       to attach to the server.

    2. In a prolog window, compile this file, then issue the command

        ?- it(foo).
*/

:-use_module(library(tcp)).
:-use_module(library(between)).

it(F):-
    prolog_flag(fileerrors,_,on),
    prolog_flag(syntax_errors,_,error),
    tcp_address_from_file(F, A),
    tcp_connect(A, C),
    tcp_output_stream(C, S),
    (   between(0, 9, X),format(S, '~N~d ~*chi there', [X,X,0' ]), fail
    ;   nl(S), nl(S), tcp_shutdown(C)
    ).
