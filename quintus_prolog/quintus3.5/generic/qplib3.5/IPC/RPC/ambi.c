/*  File   : ambi.c
    Author : David S. Warren
    Updated: 08/18/94
    Purpose: communicate through sockets

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This file used to be called socket.c, but it is now one
    of several files whose objects are linked to make socket.o
*/

#include <stdio.h>
#include "quintus.h"
#include "ipcerror.h"
#include "ipc.h"

#ifndef	lint
static	char SCCSid[] = "@(#)94/08/18 ambi.c	73.1";
#endif/*lint*/

#ifndef	SYS5

#include <sys/types.h>
#ifdef	lint
#include <sys/uio.h>
#endif/*lint*/
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#endif/*SYS5*/

/* declare the stdio routines so they can be passed to QP_make_stream */

extern int fgetc();
extern int fputc();
extern int fflush();
extern int fclose();


int feofp(stream)	/* needed because feof may be a macro */
    FILE *stream;
    {
	return feof(stream);
    }

int clearerrp(stream)	/* needed because clearerr may be a macro */
    FILE *stream;
    {
	clearerr(stream);
	return 0;	/* and because clearerr is void() not int() */
    }


/*  make_socket()
    is a Prolog-callable version of QP_make_socket()
    which returns a string parameter instead of being passed a
    buffer.  If we were willing to build the magic number 32
    into the Prolog code, we could actually use -string(32) as
    the type and call QP_make_socket directly.  Oh well.
*/
int make_socket(InPortNum, OutPortNum, HostName)
    int    InPortNum;
    int   *OutPortNum;
    char **HostName;
    {
	static char my_host_name[MAXHOSTNAME];

	*HostName = my_host_name;
	return QP_make_socket(InPortNum, OutPortNum, my_host_name);
    }


/*  connect_socket()
    is a Prolog-callable version of QP_connect_socket()
    which yields Prolog streams instead of stdio streams.
*/
int connect_socket(service, icode, ocode) 
    int  service;	/* +Service: integer */
    QP_stream **icode;	/* -Icode: integer */
    QP_stream **ocode;	/* -Ocode: integer */
    {
	FILE *ifp, *ofp;
	int fd;

	fd = QP_connect_socket(service, &ifp, &ofp);
	if (fd < 0) return -1;

	/*  Wrap the stdio streams up as Prolog streams  */
	/*  BUG: if QP_make_stream fails we don't shut things  */
	/*  down properly.  We currently can't.  */
	QP_make_stream((char *) ifp,
		fgetc, 0, fflush, feofp, clearerrp, fclose, icode);
	QP_make_stream((char *) ofp,
		0, fputc, fflush, 0, clearerrp, fclose, ocode);
	return fd;
    }


/*  create a socket and connect it to a server as a client.
    Need port number and machine name that server is on.  Return
    an input and an output stream code for reading and writing
    to the socket.
    The "portnum" and "host_name" identify the server.
    "<port>@<host>" would be a good representation.
    Why don't we have a version that uses getserventbynam() to
    access standard ports as defined in /etc/services?
*/
int connect_to(HostName, InPort, OutPort, icode, ocode) 
    char *HostName;
    int   InPort;
    int   OutPort;
    QP_stream **icode;
    QP_stream **ocode;
    {
	int connection;
	FILE *ifp, *ofp;

	connection = QP_link_socket(HostName, InPort, OutPort, &ifp, &ofp);
	if (connection < 0) return -1;

	/* make a stream for input from the client socket for Prolog */
	QP_make_stream((char *) ifp,
			fgetc, 0, fflush, feofp, clearerrp, fclose, icode);
	/* make a stream for output to the client socket for Prolog */
	QP_make_stream((char *) ofp,
			0, fputc, fflush, 0, clearerrp, fclose, ocode);
	return connection;
    }


/*  shut the baby down
*/
void shutdown_socket(fd)
    int fd;
    {
#ifndef	SYS5
	shutdown(fd, 2);
	close(fd);
#endif/*SYS5*/
    }


/*  pipe_servant()
    is a Prolog-callable version of QP_pipe_servant().
*/
int pipe_servant(SavedStatePath, OutputPath, icode, ocode)
    char *SavedStatePath;
    char *OutputPath;
    QP_stream **icode;
    QP_stream **ocode;
    {
	FILE *ifp, *ofp;
	int child;

	child = QP_pipe_servant(SavedStatePath, OutputPath, &ifp, &ofp);
	if (child < 0) return -1;

	/*  Wrap the stdio streams up as Prolog streams  */
	/*  BUG: if QP_make_stream fails we don't shut things  */
	/*  down properly.  We currently can't.  */
	QP_make_stream((char *)ifp,
			fgetc, 0, fflush, feofp, clearerrp, fclose, icode);
	QP_make_stream((char *)ofp,
			0, fputc, fflush, 0, clearerrp, fclose, ocode);
	return child;
    }

