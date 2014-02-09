/*  File   : makesocket.c
    Author : David S. Warren
    Updated: 11/01/88
    Defines: QP_make_socket()

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    QP_make_socket(InPortNum, OutPortNum, HostName)
	InPortNum	is the port to use.  If it is 0,
			the operating system will assign a new number.
	OutPortNum	returns the port which will actually be used
	HostName	a buffer of size MAXHOSTNAME is passed.  The
			name of the local machine is put in it.
	result		is a UNIX file descriptor for a new socket.

    This operation creates a new socket in the Internet domain.
    The socket is associated with the port OutPortNum @ HostName.
    QP_make_socket sets the socket up so that anyone who wants to
    communicate with this process can do so by attaching to
    OutPortNum @ HostName, and that will result in a connection
    being made to this socket.

    The point of InPortNum/OutPortNum is that if you want a particular
    port number, you can supply it as InPortNum, and you should get it
    back.  But if you want the operating system to supply a new number
    you pass 0 for InPortNum, and get back in OutPortNum the number it
    chose for you.  In this case you can be sure that no other process
    on the same machine is using the same generated port number.

    If anything goes wrong, an error message will be printed on the
    standard error stream, and the value -1 will be returned.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/01 makesocket.c	27.2";
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

#ifdef	SYS5

int QP_make_socket(InPortNum, OutPortNum, HostName)
    int   InPortNum;		/* caller-supplied port# or 0 */
    int  *OutPortNum;		/* actual port# */
    char *HostName;		/* caller supplies buffer, we supply contents */
    {
	errno = ESOCKUI;
	IOError("make_socket");
	return -1;
    }

#else /*4BSD*/

int QP_make_socket(InPortNum, OutPortNum, HostName)
    int   InPortNum;		/* caller-supplied port# or 0 */
    int  *OutPortNum;		/* actual port# */
    char *HostName;		/* caller supplies buffer, we supply contents */
    {
	int service;		/* The file descriptor of the new socket */
	struct sockaddr_in sin;	/* An Internet address record */
	int sizeof_sin;		/* The sizeof sin */

	/* get this machine's name if it is wanted */
	if (HostName) gethostname(HostName, MAXHOSTNAME);

	/* create the initial socket */
	service = socket(AF_INET, SOCK_STREAM, 0);
	if (service < 0) {
	    IOError("make_socket.OPEN");
	    return -1;
	}

	/* make it go away quickly when we close it down */
	if (setsockopt(service, SOL_SOCKET, SO_REUSEADDR, (char *)0, 0) < 0) {
	    IOError("make_socket.REUSEADDR");
	    return -1;
	}
#ifdef	SUN
	if (setsockopt(service, SOL_SOCKET, SO_DONTLINGER, (char *)0, 0) < 0) {
	    IOError("make_socket.DONTLINGER");
	    return -1;
	}
#endif/*SUN*/
	/* set up the name structure for the socket */
	sin.sin_family      = AF_INET;
	sin.sin_addr.s_addr = INADDR_ANY;
	sin.sin_port        = htons((u_short)InPortNum);
	sizeof_sin	    = sizeof sin;

	/* give the name */
	if (bind(service, (struct sockaddr *) &sin, sizeof_sin) < 0) {
	    IOError("make_socket.BIND");
	    close(service);
	    return -1;
	}

	/* get the port number assigned */
	if (getsockname(service, &sin, &sizeof_sin) < 0) {
	    IOError("make_socket.GETSOCKNAME");
	    close(service);
	    return -1;
	}
	*OutPortNum = ntohs(sin.sin_port);

	/* initialize it so clients can request a connection */
	if (listen(service, SOCKQUEUELENGTH) < 0) {
	    IOError("make_socket.LISTEN");
	    close(service);
	    return -1;
	}
	return service;
    }

#endif/*SYS5*/

