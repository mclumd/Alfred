/*  File   : connsocket.c
    Author : David S. Warren
    Updated: 11/01/88
    Defines: QP_connect_socket()

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    QP_connect_socket(Service, FD, InputStream, OutputStream)
	Service		is the UNIX file descriptor of our socket.
			This should be the result of QP_make_socket().
	InputStream	returns a stdio stream which can be used to
			read data sent by the other process.
	OutputStream	returns a stdio stream which can be used to
			send data to be read by the other process.
	result		is -1 if anything went wrong, otherwise is
			the UNIX file descriptor of a socket which
			is connected to another process which wants
			to talk with this one (the "client").

    If anything goes wrong, an error message will be printed on the
    standard error stream, and the value -1 will be returned.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/01 connsocket.c	27.2";
#endif/*lint*/

#include <stdio.h>
#include "ipc.h"
#include "ipcerror.h"

#ifdef	SYS5
							/*ARGSUSED*/
int QP_connect_socket(Service, InputStream, OutputStream)
    int    Service;		/* Our socket, made by QP_make_socket() */
    FILE **InputStream;		/* Can be used to read from client */
    FILE **OutputStream;	/* Can be used to write to client */
    {
	errno = ESOCKUI;
	IOError("connect_socket");
	return -1;
    }


#else /*4BSD*/

#include <sys/types.h>
#ifdef  lint
#include <sys/uio.h>
#endif/*lint*/
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

int QP_connect_socket(Service, InputStream, OutputStream)
    int    Service;		/* Our socket, made by QP_make_socket() */
    FILE **InputStream;		/* Can be used to read from client */
    FILE **OutputStream;	/* Can be used to write to client */
    {
	int connection;		/* The new socket */
	struct sockaddr_in sin;	/* An Internet address record */
	int sizeof_sin;		/* The sizeof sin */

	if (Service < 0) return -1;	/* Just in case... */

	/* make a connection with some client; block until there is one */
	sizeof_sin = sizeof sin;
	do { connection = 
		accept(Service, (struct sockaddr *) &sin, &sizeof_sin);
	} while (connection < 0 && errno == EINTR);

	if (connection < 0) {
	    IOError("connect_socket.ACCEPT");
	    return -1;
	}

	/* Make a stdio stream to buffer input from the server socket */
	*InputStream  = fdopen(connection, "r");
	/* Make a stdio stream to buffer output to the server socket */
	*OutputStream = fdopen(connection, "w");

	return connection;
    }

#endif/*SYS5*/

