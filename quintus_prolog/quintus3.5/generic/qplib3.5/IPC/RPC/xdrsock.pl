%   File   : xdrsock.pl
%   Author : David S. Warren
%   Updated: 09/07/90
%   SCCS:    @(#)90/09/07 xdrsock.pl	56.1
%   Purpose: Prolog interface to xdrsock.c

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  sigsign
    ignores all ignorable interrupts.
*/
foreign(sigsign,
	sigsign).


/*  establish_xdr_service(+InPortNum, -OutPortNum, -Retcode)
    is a Prolog-callable version of QP_make_socket() which
    (a) makes a checked state transition (PASSIVE->LISTENING)
    (b) doesn't return the host name.
    It returns 0 for success, -1 for failure.
*/
foreign(establish_xdr_service,
	establish_xdr_service(+integer,-integer,[-integer])).


/*  establish_xdr_server(-Retcode)
    is a Prolog-callable version of QP_connect_socket() which
    (a) makes a checked state transition (LISTENING->CONNECTED)
    (b) sets up XDR streams atop the stdio streams.
    It returns 0 for success, -1 for failure.
*/
foreign(establish_xdr_server,
	establish_xdr_server([-integer])).


/*  establish_xdr_client(+HostName,+InPort,+OutPort,-Retcode)
    makes a connection to an existing port InPort on machine HostName 
    and returns 0 if ok, -1 if not.  A single prolog process can only
    be a server OR a client, but not both at the same time using these
    routines.  To connect through pipes, pass '' and the fds.
*/
foreign(establish_xdr_client,
	establish_xdr_client(+string,+integer,+integer,[-integer])).


/*  shutdown_xdr_connection()
    closes down the xdr connection, freeing all the sockets.
*/ 
foreign(shutdown_xdr_connection,
	shutdown_xdr_connection).


/*  The following predicates have the form
    xdr_get<sometype>(-SomethingOfThatType, -ReturnCode)
    where ReturnCode is 0 for success.
*/
foreign(xdr_getinteger,
	xdr_getinteger(-integer,[-integer])).

foreign(xdr_getfloat,
	xdr_getfloat(-float,[-integer])).

foreign(xdr_getstring,
	xdr_getstring(-string,[-integer])).

foreign(xdr_getatom,
	xdr_getatom(-atom,[-integer])).

/*  The following predicates have the form
    xdr_put<sometype>(+SomethingOfThatType, -ReturnCode)
    where ReturnCode is 0 for success.
*/
foreign(xdr_putinteger,
	xdr_putinteger(+integer,[-integer])).

foreign(xdr_putfloat,
	xdr_putfloat(+float,[-integer])).

foreign(xdr_putstring,
	xdr_putstring(+string,[-integer])).

foreign(xdr_putatom,
	xdr_putatom(+atom,[-integer])).

/*  Miscellaneous operations.
*/
foreign(xdr_flush,		xdr_flush).
foreign(xdr_atom_from_string,	xdr_atom_from_string).
foreign(xdr_string_from_atom,	xdr_string_from_atom).


%   Note that file names are now interpreted relative to the file
%   containing the compile or load command.  So we do not put a
%   'library' wrapper around 'xdrsock.o' here.

foreign_file(library(system('xdrsock.o')),
    [
	establish_xdr_service,
	establish_xdr_server,
	establish_xdr_client,
	shutdown_xdr_connection,
	sigsign,
	xdr_getinteger,
	xdr_getfloat,
	xdr_getstring,
	xdr_getatom,
	xdr_putinteger,
	xdr_putfloat,
	xdr_putstring,
	xdr_putatom,
	xdr_flush,
	xdr_atom_from_string,
	xdr_string_from_atom
    ]).

%   xdrsock.o is actually made from many files, but 'make xdrsock.o'
%   (which should have been done when the library was installed) has
%   already linked them into a single object file.

:- load_foreign_files([library(system('xdrsock.o'))], []),
   abolish(foreign_file, 2),
   abolish(foreign, 2).


