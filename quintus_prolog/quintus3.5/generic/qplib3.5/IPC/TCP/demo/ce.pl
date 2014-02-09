%   SCCS   : @(#)94/01/17 ce.pl	71.1
%   Author : Tom Howland
%   Purpose: demonstration of tcp software.
%   SeeAlso: help(tcp)
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/* The example is the producer, filter, consumer problem.  The
producer produces successive terms and passes them on to filter.
Filter reads successive terms from producer and then either passes
them on to the consumer or discards them.  The consumer simply reads
the term passed to it by filter.

ce stands for "Canonical Example".

To run this example,

    1	open three windows running prolog
    2	in the first window, say
	    ?- [demo(ce)]. consumer.
    3	in the second window, say
	    ?- [demo(ce)]. filter.
    4	in the third, say
	    ?- [demo(ce)]. producer.
    5	to exit, hit ^C and then either tcp_reset or halt.

*/

:-use_module(library(random)).
:-use_module(library(tcp)).

handle(filter,'~/tcp_demo_filter').
handle(consumer,'~/tcp_demo_consumer').

init:-
    prolog_flag(fileerrors,_,on),
    prolog_flag(syntax_errors,_,error),
    tcp_trace(_,on).

% on machine A we have the consumer process:

consumer:-
    init,
    tcp_create_listener(Address, _),
    handle(consumer, C),
    tcp_address_to_file(C, Address),
    repeat,
	tcp_select(_),
    fail.

% on machine B we have the filter process:

filter:-
    init,
    tcp_create_listener(Address, _),
    handle(filter,F),
    tcp_address_to_file(F, Address),
    handle(consumer, C),
    tcp_address_from_file(C, A),
    tcp_connect(A, Consumer),
    repeat,
	tcp_select(term(_, X)),
	0.2 < X, X < 0.7,
	tcp_send(Consumer, X),
    fail.

% and on machine C we have the producer process:

producer:-
    init,
    handle(filter,F),
    tcp_address_from_file(F, Address),
    tcp_connect(Address, Filter),
    repeat,
	random(X),
	tcp_send(Filter,X),
    fail.
