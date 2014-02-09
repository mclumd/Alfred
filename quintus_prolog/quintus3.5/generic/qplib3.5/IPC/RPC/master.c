/*  File   : master.c
    Author : David S. Warren
    Updated: 06/29/94
    Purpose: C routines to support C calling Prolog

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This file used to be called ccallqp.c, but it is now just one of
    several files which are linked to produce ccallqp.o
*/

#include <stdio.h>
#include <varargs.h>
#include <malloc.h>
#include <string.h>             /* [PM] 3.5 strcmp */
#include "quintus.h"
#include "ipcerror.h"
#include "ipc.h"
#include "xdr.h"
#include "ccallqp.h"

#ifndef	lint
static	char SCCSid[] = "@(#)94/06/29 master.c	73.1";
#endif/*lint*/

#ifndef	SYS5

#include <sys/types.h>
#ifdef	lint
#include <sys/uio.h>
#endif/*lint*/
#include <sys/socket.h>
#include <netdb.h>

#endif/*SYS5*/
#include <unistd.h>             /* [PM] 3.5 close */

#define	QP_MAX_SPEC 256		/* argument specifier limit */

#define	PASSIVE	    0		/* nothing happening */
#define LISTENING   1		/* socket set up, no child yet */
#define STARTED     2		/* "child" process has been started */
#define CONNECTED   3		/* connected to child */
#define AGREED      4		/* child has sent "external" table */
#define RUNNING     5		/* child is executing a goal */

static	int	state = PASSIVE;
static	int	child;
static	int	service;	/* main socket fd */
static	int	connection;	/* connecting socket fd */


static	XDR	ixdrs, oxdrs;	/* input and output XDR structures */
static	FILE	*ifp,  *ofp;	/* i and o for buffering socket msgs */


/*----------------------------------------------------------------------+
|	When C calls Prolog, it needs a typed interface.  The		|
|	first thing the Prolog process does is to send the C		|
|	process a table of its external predicates.  Each entry		|
|	in the table is a triple <arity,name,spec>, where name/arity	|
|	identify the predicate, and spec is a sequence of bytes, one	|
|	for argument, saying whether input or output and what type.	|
|	Here "put" means C sends a parameter to Prolog,			|
|	 and "get" means Prolog sends a parameter to C.			|
+----------------------------------------------------------------------*/

#define	PUT_INTEGER	 1
#define	PUT_FLOAT	 2
#define PUT_ATOM	 3
#define PUT_STRING	 4

#define GET_INTEGER	 9
#define GET_FLOAT	10
#define GET_ATOM	11
#define GET_STRING	12

typedef struct predicate_descriptor *QPface;

struct predicate_descriptor
    {
	int    	arity;
	char*	name;
	char*	spec;
    };

/*  externals and num_exts are only valid when state >= AGREED.
    current_ext is only valid when state == RUNNING.
*/
static	QPface	externals;	/* array of external records */
static	int	num_exts;	/* number of external records */
static	int	current_ext;	/* cmd number of current query */


static void free_external_table(i) /* [PM] 3.5 was returning int */
    int i;
    {
	while (--i >= 0) {
	    if (externals[i].name) free(externals[i].name);
	    if (externals[i].spec) free(externals[i].spec);
	}
	free(externals);
	externals = NULL;
	num_exts = 0;
    }

#if 0                           /* [PM] 3.5 unused */
/*  show_external_table()
    prints out the table of external records in a dump format for debugging.
*/
static void show_external_table()
    {
	int i, j;

	for (i = 0; i < num_exts; i++) {
	    printf("Ext: %d %s /%d ( ",
		i, externals[i].name, externals[i].arity);
	    for (j = 0; externals[i].spec[j] != '\0'; j++) 
		printf("%d ", externals[i].spec[j]);
	    printf(")\n");
	}
    }
#endif /* unused */

/*  read_external_table()
    allocates space for and reads the table of externals from
    the Prolog servant.  If anything goes wrong, all the space
    allocated by this routine is freed before it returns.
*/
static int read_external_table()
    {
	int i;
	char *msg;

	if (state != CONNECTED) {
	    msg = "read_external_table.STATE";
	    goto BYE;
	}
	if (!xdr_int(&ixdrs, &num_exts)) {
	    msg = "reading external table";
	    goto BYE;
	}

	externals = (QPface)malloc(num_exts*sizeof(*externals));
	if (externals == NULL) {
	    msg = "cannot allocate external table";
	    goto BYE;
	}

	for (i = 0; i < num_exts; i++) {
	    externals[i].name = NULL;	/* so xdr will get space */
	    externals[i].spec = NULL;
	    if (!xdr_int(&ixdrs, &externals[i].arity)) {
		msg = "reading external arity";
		goto DIE;
	    }
	    if (!xdr_string(&ixdrs, &externals[i].name, QP_MAX_ATOM)) {
		msg = "reading external name";
		goto DIE;
	    }
	    if (!xdr_string(&ixdrs, &externals[i].spec, QP_MAX_SPEC)) {
		msg = "reading external spec";
		goto DIE;
	    }
	}
	state = AGREED;
	return 0;

DIE:	free_external_table(i+1);
BYE:	XDRerror(msg);
	return -1;
    }


/*  QP_ipc_lookup(name) is given a character string name of a command,
    looks it up in the externals table and returns the index of the
    corresponding external record.  This is a pain: given that we are
    not using the C namespace, there is no reason not to use the arity
    as part of the name, or failing that not to check the arity.
*/
int QP_ipc_lookup(name)
    char *name;
    {
	int i;

	if (state < AGREED) {
	    XDRerror("QP_ipc_lookup: no servant");
	    return -1;
	}
	for (i = 0; i < num_exts; i++)
	    if (!strcmp(externals[i].name, name))
		return i;
	return -1;
    }



/*  get_acknowledgement()
    gets an ack message from the remote Prolog servant, 
    returning 0 if ok, and whatever came back if not.
*/
static int get_acknowledgement()
    {
	int ack = -1;

	if (state < AGREED || !xdr_int(&ixdrs, &ack))
	    XDRerror("getting ack");
	return ack;
    }


/*  There are five commands that are identified entirely by a
    special negative code.
*/
#define	CMD_NEXT	(-1)		/* please send next answer */
#define	CMD_CLOSE	(-2)		/* no more answers, thanks */
#define	CMD_QUIT	(-3)		/* kindly drop dead */
#define	CMD_ATM_TO_STR	(-4)		/* QP_string_from_atom */
#define	CMD_STR_TO_ATM	(-5)		/* QP_atom_from_string */


/*  send_command_number(cmd)
    sends a command number to the remote Prolog servant.
*/
static void send_command_number(cmd)
    int cmd;
    {
	if (state < AGREED || !xdr_int(&oxdrs, &cmd))
	    XDRerror("sending command");
    }


/*----------------------------------------------------------------------+
|									|
|   The following routines are callable from external C programs.	|
|   They and QP_ipc_lookup() provide the interface for C programs	|
|   to call Prolog routines.						|
|									|
+----------------------------------------------------------------------*/


/*  QP_ipc_create_servant(HostName, SavedStatePath, OutputPath)
	
    HostName	is NULL or "" to indicate an ordinary child process
		running on the local machine, connected through pipes.

		is "local" to indicate a "remote" process which is
		actually running on this machine, but is still connected
		through sockets.

		is the name of a remote host (it should exist in /etc/hosts)
		when the remote process should execute on machine $HostName.

    SavedStatePath
		is the UNIX pathname of the Prolog saved state to run.
		This saved state should have been created by
		save_ipc_servant/1.

    OutputPath	is NULL or "" to indicate that the standard output of
		the servant should be routed to /dev/null.

		is "user" to indicate that the standard output of the
		servant should be connected to the standard output of
		the master.

		is otherwise the UNIX pathname of a **local** file to
		which the standard output and standard error output
		of the servant are to be directed.

    RESULTS:	PASSIVE->LISTENING->STARTED->CONNECTED->AGREED
		If sockets are used,
		    child is set to -1, and service and connection
		    are set to sockets.
		If pipes are used,
		    child is set to the PID of the servant process,
		    and service and connection are left unchanged.

		If anything obvious went wrong, the result is -1,
		otherwise it is 0.  Problems in the servant tend to
		slip past the error checking.

    Note:	The result used to be 'connection' in case of success.
		But this is not always defined, and the caller had no
		business knowing it anyway, so we now always return 0
		for success.
*/
int QP_ipc_create_servant(HostName, SavedStatePath, OutputPath)
    char *HostName;
    char *SavedStatePath;
    char *OutputPath;
    {				/* sets globals: connection, service */
	char *msg = NULL;

	if (state != PASSIVE) {
	    msg = "Prolog servant already opened";
	    goto DIE;
	}

	/* empty host name means use pipes */
	if (!HostName || !*HostName) {
	    child = QP_pipe_servant(SavedStatePath, OutputPath, &ifp, &ofp);
	    if (child < 0) {
		msg = "Prolog servant wouldn't start";
		goto DIE;
	    }
	    state = STARTED;
	} else {
#ifdef	SYS5
	    errno = ESOCKUI;
	    IOError("QP_ipc_create_servant");
	    return -1;
#else /*4BSD*/
	    int ThisPort;
	    char ThisHost[MAXHOSTNAME];

	    service = QP_make_socket(0, &ThisPort, ThisHost);
	    if (service < 0) goto DIE;
	    state = LISTENING;
	    if (QP_call_servant(HostName, SavedStatePath, OutputPath,
				ThisHost, ThisPort) < 0) {
		msg = "Prolog servant wouldn't start";
		goto DIE;
	    }
	    child = -1;
	    state = STARTED;

	    connection = QP_connect_socket(service, &ifp, &ofp);
	    if (connection < 0) goto DIE;
#endif/*SYS5*/
	}
	/* Make an XDR stream for input from the server */
	xdrstdio_create(&ixdrs, ifp, XDR_DECODE);
	/* Make an XDR stream for output to the server */
	xdrstdio_create(&oxdrs, ofp, XDR_ENCODE);
	state = CONNECTED;

	if (read_external_table()) goto DIE;
	state = AGREED;

	/* everything went well */
	return 0;

DIE:;
	if (msg) XDRerror(msg);
	QP_ipc_shutdown_servant();
	return -1;
    }


/*  QP_ipc_shutdown_servant()
    shuts down the Prolog servant.  It sends a message that causes the
    servant to terminate execution.
*/
int QP_ipc_shutdown_servant()	    /* use global: (connection, service) */
    {
	int ret = 0;

	switch (state) {
	    case RUNNING:
	    case AGREED:
		send_command_number(CMD_QUIT);
		fflush(ofp);
		ret = get_acknowledgement();
		free_external_table(num_exts);
	    case CONNECTED:
#ifndef	SYS5
		if (child < 0) shutdown(connection, 2);
#endif/*SYS5*/
		xdr_destroy(&ixdrs);
		xdr_destroy(&oxdrs);
		fclose(ifp);		/* will close(connection) */
		fclose(ofp);		/* will close(connection) AGAIN */
	    case STARTED:
		if (child >= 0) QP_kill_servant(child);
	    case LISTENING:
#ifndef	SYS5
		if (child < 0) shutdown(service, 2);
#endif/*SYS5*/
		close(service);
	    case PASSIVE:
		break;
	}
	state = PASSIVE;
	child = service = connection = -1;
	return ret;
    }


/*  QP_ipc_prepare(cmd, arg1, ..., argn)
    sends a command number and the input arguments (arg1, ..., argn) to
    the Prolog servant.  It returns 0 if successful and -1 if not.

    These two functions really need a marker discipline in the XDR
    stream so that the end of a block can be detected, and if something
    goes wrong in the call or reply we would then be able to synchronise.
    I've hacked this code a lot, but if an argument transmission error
    occurs we are still DEAD.
*/

int QP_ipc_prepare(va_alist)   /* variable arg list, first is extcall */
    va_dcl
    {
	va_list ap;
	int i;
	int pi;
	double pf;
	char *ps;
	QP_atom pa;
	register QPface pred;	/* points to predicate descriptor */

	switch (state) {
	    case AGREED:
		break;
	    case RUNNING:
		XDRerror("QP_ipc_prepare: previous query still running");
		return -1;
	    default:
		XDRerror("QP_ipc_prepare: no servant");
		return -1;
	}

	va_start(ap);
	current_ext = va_arg(ap, int);
	if (current_ext < 0 || current_ext >= num_exts) {
	    XDRerror("QP_ipc_prepare: illegal predicate id");
	    return -1;
	}
	send_command_number(current_ext);
	state = RUNNING;

	pred = externals + current_ext;
	for (i = 0; i < pred->arity; i++) {
	    switch (pred->spec[i]) {
		case PUT_INTEGER:
		    pi = va_arg(ap, int);
		    if (!xdr_int(&oxdrs, &pi)) 
			XDRerror("writing integer"); 
		    break;
		case PUT_FLOAT:
		    pf = va_arg(ap, double); 
		    if (!xdr_double(&oxdrs, &pf))
			XDRerror("writing float"); 
		    break;
		case PUT_ATOM:
		    pa = va_arg(ap, QP_atom);
		    if (!xdr_u_long(&oxdrs, &pa))
			XDRerror("writing atom"); 
		    break;
		case PUT_STRING:
		    ps = va_arg(ap, char *);
		    if (!xdr_string(&oxdrs, &ps, QP_MAX_ATOM))
			XDRerror("writing string"); 
		    break;
		case GET_INTEGER:
		case GET_FLOAT:
		case GET_ATOM:
		case GET_STRING:
		    break;
		default:
		    XDRerror("QP_ipc_prepare: Illegal type");
		    return -1;
	    }
	}
	va_end(ap);
	fflush(ofp);
	return QP_ipc_OK;
    }


/*  QP_ipc_next(cmd, arg1, ..., argm)
    retrieves the next answer from the Prolog servant for the current
    query.  It puts the output values for that answer in the arguments
    arg1, ..., argm.  It returns 0 if successful, -1 if there are not
    more answers (the last answer, if any, was already returned), and -2
    if there is some other problem.
*/
int QP_ipc_next(va_alist)
    va_dcl
    {
	va_list ap;
	int nomore;
	int i;
	int *ppi;
	float *ppf;
	double tempdoub;
	char *ps;		/* note: **NOT** char **ps! */
	QP_atom *ppa;
	register QPface pred;	/* points to predicate descriptor */

	switch (state) {
	    case RUNNING:
		break;
	    case AGREED:
		XDRerror("QP_ipc_next: no active query");
		return QP_ipc_ERR;
	    default:
		XDRerror("QP_ipc_next: no servant");
		return QP_ipc_ERR;
	}

	va_start(ap);
	i = va_arg(ap, int);
	if (i != current_ext) {
	    XDRerror("QP_ipc_next: current query not for this predicate");
	    return QP_ipc_ERR;
	}

	send_command_number(CMD_NEXT);
	fflush(ofp);
	if (!xdr_int(&ixdrs, &nomore)) {
	    XDRerror("reading signal");
	    return QP_ipc_ERR;
	}
	if (nomore) {			/* more coming? */
	    state = AGREED;		/* not open any longer */
	    return QP_ipc_FAIL;		/* no more answers */
	}

	pred = externals + current_ext;
	for (i = 0; i < pred->arity; i++) {
	    switch (pred->spec[i]) {
		case PUT_INTEGER:
		case PUT_FLOAT:
		case PUT_ATOM:
		case PUT_STRING:
		    break;
		case GET_INTEGER:
		    ppi = va_arg(ap, int *);
		    if (!xdr_int(&ixdrs, ppi))
			XDRerror("reading integer"); 
		    break;
		case GET_FLOAT:
		    ppf = va_arg(ap, float *);
		    /* floats sent as doubles */
		    if (!xdr_double(&ixdrs, &tempdoub))
			XDRerror("reading float"); 
		    *ppf = (float)tempdoub;
		    break;
		case GET_ATOM:
		    ppa = va_arg(ap, QP_atom *);
		    if (!xdr_u_long(&ixdrs, ppa))
			XDRerror("reading atom"); 
		    break;
		case GET_STRING:
		    ps = va_arg(ap, char *);
		    if (!xdr_string(&ixdrs, &ps, QP_MAX_ATOM))
			XDRerror("reading string"); 
		    break;
		default:
		    XDRerror("QP_ipc_next: Illegal type");
		    return QP_ipc_ERR;
	    }
	}
	return QP_ipc_OK;
    }
	
	
/*  QP_ipc_close()
    ensures that there is no current query.  It prints an error if
    there is no active servant.
*/

int QP_ipc_close()
    {
	switch (state) {
	    case RUNNING:
		send_command_number(CMD_CLOSE);
		fflush(ofp);

		state = AGREED;
		current_ext = -1;
		return get_acknowledgement();
	    case AGREED:
		return 0;
	    default:
		XDRerror("QP_ipc_close: no servant");
		return -1;
	}
    }


/*  QP_ipc_atom_from_string(str)
    returns the atom number for the string str.
    It sends a nestable command to the Prolog process to do this.
*/
QP_atom QP_ipc_atom_from_string(str)
    char *str;
    {
	QP_atom atom;

	if (state < AGREED) {
	    XDRerror("QP_ipc_atom_from_string: no servant");
	    return -1;
	}

	send_command_number(CMD_STR_TO_ATM);
	xdr_string(&oxdrs, &str, QP_MAX_ATOM);
	fflush(ofp);

	xdr_u_long(&ixdrs, &atom);
	return atom;
    }


/*  QP_ipc_string_from_atom(atom, str)
    is given an atom number and returns in str the corresponding string.
    It sends a nestable command to the Prolog process to do this.
*/
void QP_ipc_string_from_atom(atom, str)
    QP_atom atom;
    char *str;
    {
	if (!str) {
	    XDRerror("QP_ipc_string_from_atom: no buffer");
	} else
	if (state < AGREED) {
	    XDRerror("QP_ipc_string_from_atom: no servant");
	} else {

	    send_command_number(CMD_ATM_TO_STR);
	    xdr_u_long(&oxdrs, &atom);
	    fflush(ofp);

	    xdr_string(&ixdrs, &str, QP_MAX_ATOM);
	}
    }

