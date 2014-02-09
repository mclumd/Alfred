%   File   : socket.pl
%   Author : David S. Warren
%   Updated: 03/23/93
%   SCCS:    @(#)93/03/23 socket.pl	66.1
%   Purpose: Prolog interface to socket.c

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*----------------------------------------------------------------------+
|									|
| 				Sockets					|
| 									|
+----------------------------------------------------------------------*/


/*  A socket allows two processes to communicate.  One of the two
    processes is called the server.  The server initiates the connection
    by creating a socket (using make_socket).  This associates a Port
    number with the socket.  Then the server must actually connect the
    socket to another process (using connect_socket).  The other
    process, called the client, must provide the Port number and the
    machine name of the server in order connect to the server's socket
    (using connect_to).  After the connection has been established the
    two processes can read and write over the connection.  The
    connection can be closed, and the server may use the same socket to
    connect to another client (the server using another connect_socket,
    and the (new) client using connect_to).  The server can shutdown the
    entire socket (using shutdown_socket).
*/


/*----------------------------------------------------------------------+
| 									|
| 		C Routines for Connecting Sockets			|
| 									|
+----------------------------------------------------------------------*/

/*  make_socket(+InPortNum, -OutPortNum, -HostName, -ServiceFD)
    Creates a main socket and returns the fd associated with it.
    InPortNum is the port number (number > 2400 to uniquely identify
    this server on this machine) to use.  If InPortNum is 0, then the
    system chooses a port number to use.  In any case, OutPortNum is
    returned as the port number actually used.  HostName is returned as
    the name of this machine.
*/
foreign(make_socket,
	make_socket(+integer,-integer,-string,[-integer])). 


/*  connect_socket(+ServiceFD, -Isc, -Osc, -ConnectionFD)
    given a main socket fd (returned by make_socket) waits for and
    establishes a connection with another process.  Returns the fd of
    the connecting socket in ConnectionFD (or -1 if an error), and two
    stream codes to be used to read from and write to the other process
    over the socket.  The streams should be close-d to terminate the
    connection.  After closing, another connect_socket can be done for
    the same ServiceFD to obtain a connection to another process.
*/
foreign(connect_socket,
	connect_socket(+integer,-integer,-integer,[-integer])).


/*  connect_to(+HostName,+InPort,+OutPort-Isc,-Osc,-ConnectionFD)
    given a port number and a machine name, makes a connection to the
    socket on that host with that port number.  If there is no socket
    with that port on that machine, it prints an error message and
    returns -1 in ConnectionFD.  Otherwise, it makes the connection and
    returns the Fd of the connecting socket in ConnectionFD, and two
    stream codes to be used to read from and write to the server over
    the socket.  The streams should be close-d to terminate the
    connection.  In the case of connection to pipes, Host='', InPort and
    OutPort are the FD numbers given in the command line, and 0 is
    returned as the ConnectionFD.
*/
foreign(connect_to,
	connect_to(+string,+integer,+integer,-integer,-integer,[-integer])).


/*  shutdown_socket(+ServiceFD)
    given an Fd for a main socket, shut down the entire socket.
*/
foreign(shutdown_socket,
	shutdown_socket(+integer)).


/*  pipe_servant(+SavedState, +Output, -FromSlave, -ToSlave, -PID)
    is a Prolog-callable version of QP_pipe_servant (callservant.c)
    which returns Prolog streams instead of stdio streams.
*/
foreign(pipe_servant,
	pipe_servant_1(+string,+string,-integer,-integer,[-integer])).

/*  call_servant(+HostName, +SavedState, +Output, +ThisHost, +ThisPort, -Ret)
    is a Prolog-callable version of QP_call_servant (callservant.c).
    In fact no further change is needed.
*/
foreign('QP_call_servant',
	call_servant(+string,+string,+string,+string,+integer,[-integer])).

/*  sigsign
    ignores all ignorable interrupts.
*/
foreign(sigsign,
	sigsign).


foreign_file(library(system('socket.o')),
    [
	make_socket,
	connect_socket,
	connect_to,
	shutdown_socket,
	sigsign,
	pipe_servant,
	'QP_call_servant'
    ]).

:- load_foreign_files([library(system('socket.o'))], ['-lqp']),
   abolish(foreign_file, 2),
   abolish(foreign, 2).


pipe_servant(SavedState, Output, StreamFromSlave, StreamToSlave, PID) :-
	pipe_servant_1(SavedState, Output, FromCode, ToCode, PID),
	PID >= 0,
	stream_code(StreamFromSlave, FromCode),
	stream_code(StreamToSlave,   ToCode).


/************************************************************************/
/*									*/
/*		Socket Connection Routines (Prolog)			*/
/*									*/
/************************************************************************/

/*  $sock_stream(Conn_id,Istream,Ostream,Nfd,Fd)
    is a relation for maintaining information about open sockets.  It
    contains a tuple if there is a socket for connection Conn_id.
    Connections are simply numbered 1 to N. (The routines here only use
    one connection, numbered 1.)  If the connection is a server socket
    that is not connected (i.e., not yet done an accept), Istream=dummy,
    Ostream=dummy, and Nfd=-1.  If it is connected, then Istream is the
    input stream to read from to get input over the socket, and Ostream
    is the output stream to write to to send output over the socket; Nfd
    is the Fd of the connection socket, and Fd is the Fd of the main
    socket.

    This has been completely broken up into pieces that make sense.
	connection_input_stream( Conn_id -> Stream)
	connection_output_stream(Conn_id -> Stream)
	connection_master(       Conn_id -> Socket)
	connection_servant(      Conn_id -> Socket)
    There are four cases
	master	servant		What state?
	exists	exists		master connected to servant
	exists	absent		master started, connect_socket() not done
	absent	exists		servant connected to master
	absent	absent		connection is through pipes
*/
:- dynamic
	connection_input_stream/2,
	connection_output_stream/2,
	connection_master/2,
	connection_servant/2.



/************************************************************************/
/*									*/
/*		Routines for Connecting Sockets				*/
/*									*/
/************************************************************************/


/*  connect_pipe(+IStream, +OStream[, +Conn_id])
*/
connect_pipe(IStream, OStream) :-
	connect_pipe(IStream, OStream, 1).

connect_pipe(IStream, OStream, Conn_id) :-
	(   connection_input_stream(Conn_id, _) ->
	    shutdown_connection(Conn_id)	% close automatically
	;   true
	),
	assert(connection_input_stream(Conn_id, IStream)),
	assert(connection_output_stream(Conn_id, OStream)).



/*  make_socket(?ThisPort, ?ThisHost, +Conn_id)
    creates a socket using port ThisPort (generating one if ThisPort is
    a variable) for connection numbered Conn_id.  ThisHost is returned
    and is the name of the machine on which this process is running.
    The way the ThisPort argument is handled is disgusting.

    make_socket(?ThisPort)
    creates a socket for connection 1 Conn_id using port ThisPort.
    The name of the machine on which this process is running is ignored.
*/

make_socket(ThisPort) :-
	make_socket(ThisPort, _, 1).

make_socket(ThisPort, ThisHost, Conn_id) :-
	(   var(ThisPort) ->		% OOH, HORRIBLE!
	    make_socket(    0   , ThisPort, ThisHost, MasterFd)
	;   make_socket(ThisPort, ThisPort, ThisHost, MasterFd)
	),
	MasterFd >= 0,
	(   connection_input_stream(Conn_id, _) ->
	    shutdown_connection(Conn_id)	% close automatically
	;   true
	),
	assert(connection_master(Conn_id, MasterFd)),
	msg_trace1(['Socket',Conn_id,'created on',ThisHost,ThisPort,MasterFd]).


/*  connect_socket_n(+Conn_id)
    given a connection number (indicating which connection to use) sets
    up a connection to a client.  make_socket/3 must have already been
    done.  It waits until another process has done a connect_to this
    socket (using this machine's name and this port number) before
    returning the new connected-up socket.

    connect_socket
    connects a socket to a client through connection 1.  
    The difference in names is unfortunate.
*/

connect_socket :-
	connect_socket_n(1).

connect_socket_n(Conn_id) :-
	connection_master(Conn_id, MasterFd),
	connect_socket(MasterFd, Icode, Ocode, ServantFd),
	ServantFd >= 0,
	stream_code(Istream, Icode),
	stream_code(Ostream, Ocode),
	assert(connection_input_stream(Conn_id, Istream)),
	assert(connection_output_stream(Conn_id, Ostream)),
	assert(connection_servant(Conn_id, ServantFd)),
	msg_trace1(['Connection',Conn_id,created,ServantFd,MasterFd]).


/*  connect_to_n(+HostName, +InPort, +OutPort, +Conn_id)
    sets up a connection with the server on machine HostName with port
    number InPort, and numbers it connection Conn_id on this machine.
    When this returns, "sendterm"s and "recvterm"s can be done.

    connect_to(+HostName, +InPort, +OutPort)
    does the same, using connection 1.
    The difference in names is unfortunate.
*/
connect_to(HostName, InPort, OutPort) :-
	connect_to_n(HostName, InPort, OutPort, 1).

connect_to_n(HostName, InPort, OutPort, Conn_id) :-
	connect_to(HostName, InPort, OutPort, Icode, Ocode, ServantFd),
	ServantFd >= 0,
	stream_code(Istream, Icode),
	stream_code(Ostream, Ocode),
	assert(connection_input_stream(Conn_id, Istream)),
	assert(connection_output_stream(Conn_id, Ostream)),
	assert(connection_servant(Conn_id, ServantFd)),
	msg_trace1(['Connection',Conn_id,'created to',HostName,InPort]).


/*  shutdown_connection(+Conn_id)
    shuts down the server Conn_id, and closes the connection if still open.

    shutdown_connection
    shuts down connection 1.
*/

shutdown_connection :-
	shutdown_connection(1).

shutdown_connection(Conn_id) :-
	(   retract(connection_input_stream(Conn_id, Stream)),
	    close(Stream),
	    fail
	;   retract(connection_output_stream(Conn_id, Stream)),
	    close(Stream),
	    fail
	;   retract(connection_servant(Conn_id, Socket)),
	    shutdown_socket(Socket),
	    fail
	;   retract(connection_master(Conn_id, _)),
	    fail
	;   true
	),
	msg_trace1(['Connection',Conn_id,shut,down]).


/************************************************************************/
/*									*/
/*		Sending and Receiving Terms over Sockets		*/
/*									*/
/************************************************************************/


/*  recvterm(+Conn_id, ?Term)
    receives a term from connection Conn_id as defined in $sock_stream.

    recvterm(?Term)
    receives a term from connection 1.
*/

recvterm(Term) :-
	recvterm(1, Term).

recvterm(Conn_id, Term) :-
	connection_input_stream(Conn_id, InStream),
	!,
	read(InStream, Term),
	msg_trace1(['Received',Conn_id,:,Term]).
recvterm(Conn_id, _) :-
	write_sock_error(['Connection',Conn_id,'is not open']),
	fail.


/*  sendterm(+Conn_id, +Term)
    sends a term through connection Conn_id as defined in $sock_stream.
    This routine automatically does a flush to make sure the term is
    sent.  If there are to be many terms sent one after the other, it
    might make sense to do a flush only after the last one.
    Note the use of write_canonical/2.

    sendterm(+Term)
    sends a term through connection 1.
*/

sendterm(Term) :-
	sendterm(1, Term).

sendterm(Conn_id, Term) :-
	connection_output_stream(Conn_id, OutStream),
	!,
	write_canonical(OutStream, Term),
	write(OutStream, ' .'),
	nl(OutStream),
	flush_output(OutStream),
	msg_trace1(['Sent',Conn_id,:,Term]).
sendterm(Conn_id, _) :-
	write_sock_error(['Connection',Conn_id,'not open']),
	fail.


/************************************************************************/
/*									*/
/*		Socket Utilities for Tracing and Errors			*/
/*									*/
/************************************************************************/

:- ensure_loaded(sockutil).

