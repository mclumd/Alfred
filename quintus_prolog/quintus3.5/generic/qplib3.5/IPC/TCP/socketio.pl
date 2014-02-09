%   Module : 04/04/91 @(#)socketio.pl	63.2
%   Author : Tom Howland
%   Purpose: buffered Prolog streams connected to sockets
%   SeeAlso: man socket socket_io.c
%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

:-module(socket_io,[
    socket_io_open_input/2,    % +FileDescriptor, -StreamCode
    socket_io_open_output/2    % +FileDescriptor, -StreamCode
		]).

sccs_id('"@(#)91/04/04 socketio.pl	63.2"').

/* socket_io_open_input(+Fd,-StreamCode)

Create a buffered Prolog input stream for the socket file descriptor Fd.

*/

socket_io_open_input(Fd,StreamCode):-
    check(Fd,StreamCode,socket_io_open_input(Fd,StreamCode)),
    socket_io_open_input(Fd,StreamCode,0),
    StreamCode =\= 0.

check(Fd,StreamCode,Goal):-
    (   var(Fd)
    ->  raise_exception(instantiation_error(Goal,1))
    ;   var(StreamCode)
    ->  true
    ;   raise_exception(instantiation_error(Goal,2))
    ).

/* socket_io_open_output(+Fd,-StreamCode)

Create a buffered Prolog output stream for the socket file descriptor Fd.

*/

socket_io_open_output(Fd,StreamCode):-
    check(Fd,StreamCode,socket_io_open_output(Fd,StreamCode)),
    socket_io_open_output(Fd,StreamCode,0),
    StreamCode =\= 0.

foreign(socket_io_open_input,c,socket_io_open_input(+integer,
    -address,[-integer])).
foreign(socket_io_open_output,c,socket_io_open_output(+integer,
    -address,[-integer])).

foreign_file(library(system(tcp_p)),[
    socket_io_open_input,
    socket_io_open_output]).

:- load_foreign_executable(library(system(tcp_p))),
   abolish(foreign_file, 2),
   abolish(foreign, 3).
