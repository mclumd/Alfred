/*  File   : servant.c
    Author : David S. Warren
    Updated: 03/03/94
    Purpose: Allow QP to communicate through a socket using XDR routines

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This file used to be called xdrsock.c, but it is now just one of
    several files whose code is linked to form xdrsock.o
*/

#include <stdio.h>
#include "quintus.h"
#include "ipcerror.h"
#include "ipc.h"
#include "xdr.h"

#ifndef	lint
static	char SCCSid[] = "@(#)94/03/03 servant.c	71.1";
#endif/*lint*/

#ifndef	SYS5

#ifdef	lint
#include <sys/uio.h>
#endif/*lint*/
#include <sys/socket.h>
#include <netdb.h>

#endif/*SYS5*/

#define PASSIVE	   0		/* not established as anything */
#define	LISTENING  1		/* service set up, but not connection */
#define	STARTED    2		/* not used here */
#define	CONNECTED  3		/* fully set up as server */
#define	AGREED     4		/* fully set up as client */
#define	CONSULTING AGREED
#define RUNNING    5		/* not used here */

static	int	state = PASSIVE;
static	int	service;	/* main socket fd */
static	int	connection;	/* connecting socket fd */
static	XDR	ixdrs, oxdrs;	/* input and output XDR structures */
static	FILE	*ifp,  *ofp;	/* i and o for buffering socket msgs */


/*  establish_xdr_service(+InPortNum, -OutPortNum)
    is a Prolog-callable version of QP_make_socket() which
    (a) makes a checked state transition (PASSIVE->LISTENING)
    (b) doesn't return the host name.
    It returns 0 for success, -1 for failure.
    It sets the global variable 'service' to the new socket.
*/
int establish_xdr_service(InPortNum, OutPortNum)
    int   InPortNum;		/* caller-supplied port# or 0 */
    int  *OutPortNum;		/* actual port# */
    {
	if (state != PASSIVE) {
	    errno = EFSMBLK;
	    IOError("establish_xdr_service");
	    return -1;
	}
	service = QP_make_socket(InPortNum, OutPortNum, (char*)0);
	if (service < 0) return -1;
	state = LISTENING;
	return 0;
    }


/*  establish_xdr_server()
    is a Prolog-callable version of QP_connect_socket() which
    (a) makes a checked state transition and
    (b) sets up XDR streams atop the stdio streams.
    It returns 0 for success, -1 for failure.
*/
int establish_xdr_server()
    {
	if (state != LISTENING) {
	    errno = EFSMBLK;
	    IOError("establish_xdr_server");
	    return -1;
	}

	connection = QP_connect_socket(service, &ifp, &ofp);
	if (connection < 0) return -1;

	/* Make an XDR stream for input from the server */
	xdrstdio_create(&ixdrs, ifp, XDR_DECODE);
	/* Make an XDR stream for output to the server */
	xdrstdio_create(&oxdrs, ofp, XDR_ENCODE);

	state = CONNECTED;
	return 0;
    }

/*  Create a socket and connect it to a server as a client.
    Need the port number and machine name that server is on.
    Return 0 if successful,  -1 if not.
    YOU CANNOT USE THESE ROUTINES TO BE BOTH A CLIENT AND
    A SERVER AT THE SAME TIME! 
*/
int establish_xdr_client(HostName, InPort, OutPort)
    char *HostName;		/* CallHost or "" */
    int   InPort;		/* CallPort or InputFd */
    int   OutPort;		/* unused   or OutputFd */
    {				/* sets global connection */
	if (state != PASSIVE) {
	    errno = EFSMBLK;
	    IOError("establish_xdr_client");
	    return -1;
	}
	connection = QP_link_socket(HostName, InPort, OutPort, &ifp, &ofp);
	if (connection < 0) return -1;
	/* make an XDR stream for input from the servant */
	xdrstdio_create(&ixdrs, ifp, XDR_DECODE);
	/* make an XDR stream for output to the servant */
	xdrstdio_create(&oxdrs, ofp, XDR_ENCODE);

	state = CONSULTING;
	return 0;
    }


/*  shutdown_xdr_connection()
    shuts the connection down.  It doesn't send any message to
    the other end of the connection.
*/
void                            /* [PM] was missing return type and argument list */
shutdown_xdr_connection(void)
    {
	switch (state) {
	    case RUNNING:			/* not used */
	    case AGREED:			/* = CONSULTING */
	    case CONNECTED:
		xdr_destroy(&ixdrs);
		xdr_destroy(&oxdrs);
		fclose(ifp);			/* will close(connection) */
		fclose(ofp);			/* will close(connection) AGAIN */
	    case STARTED:	
	    case LISTENING:
#ifndef	SYS5
		shutdown(service, 2);
		close(service);
#endif/*SYS5*/
	    case PASSIVE:
		break;
	}
	ifp = NULL;
	ofp = NULL;
	state = PASSIVE;
    }


/*----------------------------------------------------------------------+
|	Interface to XDR transfer routines.				|
|	The Prolog code calls these routines, which refer to the	|
|	global variables ixdrs and oxdrs, to avoid passing the		|
|	XDR streams around.  This has to be redesigned so that we	|
|	can have [parent]+{child}... rather than [parent|child].	|
+----------------------------------------------------------------------*/


static	char	space[QP_MAX_ATOM+4];


int xdr_getinteger(num)
    long *num;
    {	
	return xdr_long(&ixdrs, num);
    }

int xdr_getfloat(num)
    float *num;
    {
	double tempdoub;
	int ret;

	ret = xdr_double(&ixdrs, &tempdoub);
	*num = (float)tempdoub;
	return ret;
    }

int xdr_getstring(strp)
    char **strp;
    {
	*strp = space;
	return xdr_string(&ixdrs, strp, QP_MAX_ATOM);
    }

int xdr_getatom(atom)
    QP_atom *atom;
    {
	return xdr_u_long(&ixdrs, atom);
    }


int xdr_putinteger(num)
    long num;
    {	
	return xdr_long(&oxdrs, &num);
    }

int xdr_putfloat(num)
    double num;
    {
	return xdr_double(&oxdrs, &num);
    }

int xdr_putstring(str)
    char *str;
    {
	return xdr_string(&oxdrs, &str, QP_MAX_ATOM);
    }

int xdr_putatom(atom)
    QP_atom atom;
    {
	return xdr_u_long(&oxdrs, &atom);
    }


int xdr_flush()
    {
	return fflush(ofp);
    }

void xdr_atom_from_string(void)  /* [PM] 3.5 added arglist; was returning int */
    {
	char *str;
	QP_atom atom;

	str = space;
	xdr_string(&ixdrs, &str, QP_MAX_ATOM);
	atom = QP_atom_from_string(space);
	xdr_u_long(&oxdrs, &atom);
	fflush(ofp);
    }

void xdr_string_from_atom(void) /* [PM] 3.5 added arglist; was returning int */
    {
	QP_atom atom;
	char *str;

	xdr_u_long(&ixdrs, &atom);
	str = QP_string_from_atom(atom);
	xdr_string(&oxdrs, &str, QP_MAX_ATOM);
	fflush(ofp);
    }

