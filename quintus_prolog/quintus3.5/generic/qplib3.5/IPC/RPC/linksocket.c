/*  File   : linksocket.c
    Author : David S. Warren
    Updated: 11/01/88
    Defines: QP_link_socket()

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    QP_link_socket(HostName, InPort, OutPort, InputStream, OutputStream)
	HostName	is the name of the machine to connect to.
			We'll connect as a servant to InPort@HostName.
			If HostName is "", we're connecting through pipes.
	InPort		is the port to connect to.
			If HostName is "", it is the input file descriptor.
	OutPort		If HostName is "", it is the output file descriptor.

	InputStream	returns a stdio stream which can be used to
			read data sent by the other process.
	OutputStream	returns a stdio stream which can be used to
			send data to be read by the other process.
	RESULT		is -1 if anything went wrong, otherwise is
			the UNIX file descriptor of a socket which
			is connected to another process which wants
			to talk with this one (the "client").
			(It is 0 for connection through pipes.)

    If anything goes wrong, an error message will be printed on the
    standard error stream, and the value -1 will be returned.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/01 linksocket.c	27.2";
#endif/*lint*/

#include <stdio.h>
#include "ipc.h"
#include "ipcerror.h"

#ifndef	SYS5

#include <sys/types.h>
#ifdef  lint
#include <sys/uio.h>
#endif/*lint*/
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#endif/*SYS5*/


int QP_link_socket(HostName, InPort, OutPort, InputStream, OutputStream)
    char  *HostName;		/* Machine to connect to */
    int    InPort;		/* Port to connect to */
    int    OutPort;
    FILE **InputStream;		/* Can be used to read from client */
    FILE **OutputStream;	/* Can be used to write to client */
    {
#ifndef	SYS5
	struct hostent *hp;
	struct sockaddr_in sin;
	int connection;
#endif/*SYS5*/

	if (!HostName || !*HostName) {	/* connect through pipes */
	    if (!(*InputStream  = fdopen(InPort,  "r"))) return -1;
	    if (!(*OutputStream = fdopen(OutPort, "w"))) {
		(void)fclose(*InputStream);
		return -1;
	    }
	    return 0;
	}
#ifdef	SYS5
	errno = ESOCKUI;
	IOError("QP_link_socket.V");
	return -1;
#else /*4BSD*/
	/* given the simple host name, get the internal host identification */
	hp = gethostbyname(HostName);
	if (hp == NULL) {
	    IOError("QP_link_socket.gethostbyname");
	    return -1;
	}

	/* fill in name structure */
	bzero((char *) &sin, sizeof(sin));
	bcopy(hp->h_addr, (char *) &sin.sin_addr, hp->h_length);
	sin.sin_family = hp->h_addrtype;
	sin.sin_port   = htons((u_short)InPort);

	/* get a socket */
	connection = socket(AF_INET, SOCK_STREAM, 0);
	if (connection < 0) {
	    IOError("QP_link_socket.socket");
	    return -1;
	}

	/* connect it to the servant */
	if (connect(connection,(struct sockaddr *) &sin,sizeof(sin)) < 0) {
	    IOError("QP_link_socket.connect");
	    close(connection);
	    return -1;
	}

	/*  Make a stdio stream for input from the socket  */
	*InputStream  = fdopen(connection, "r");
	/*  Make a stdio stream for output to the socket  */
	*OutputStream = fdopen(connection, "w");
	return connection;
#endif/*SYS5*/
    }


