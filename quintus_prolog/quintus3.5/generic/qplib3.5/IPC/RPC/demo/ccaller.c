/*  SCCS   : @(#)ccaller.c	28.3 06/17/02
    Author : David S. Warren
    Purpose: Example C program to call Prolog: testing

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)02/06/17 ccaller.c	28.3";
#endif/*lint*/

#include <stdio.h>
#include <quintus/quintus.h>
#include "ccallqp.h"

#ifdef	SYS5
#define	LOCAL	""
#else
#define	LOCAL	"local"
#endif

/*  This program is set up to call only one servant.
    But you might want to change the host or output file.
    So we fix SavedState and pick up the others from
    the arguments.
*/
static	char*	SavedState = "cpservant";
static	char*	DefaultHost = "";
static	char*	DefaultFile = "";

void GetExternalId(Handle, Name)
    int *Handle;
    char *Name;
    {
	if ((*Handle = QP_ipc_lookup(Name)) < 0) {
	    printf("External '%s' is not defined.\n", Name);
	    exit(1);
	}
    }

main(argc, argv)
    int argc;
    char **argv;
    {
	int rc;
	int paddints, ptable, pdupl, ptrue, pfalse, psettrace, pgettrace;
	char *HostName;
	char *OutputFile;
	int int1, int2, int3;
	int tabint;
	char tabstr1[20], tabstr2[20];
	float tabflt;
	long unsigned tabatom;
	char str[50];
	char inbuf[80];

	HostName = argc > 1 ? argv[1] : DefaultHost;
	OutputFile = argc > 2 ? argv[2] : DefaultFile;

	if (QP_ipc_create_servant(HostName, SavedState, OutputFile) < 0) {
	    printf("Error starting up servant.\n");
	    exit(1);
	}
	printf("Server started successfully\n");

	GetExternalId(&psettrace, "settrace");
	GetExternalId(&paddints,  "addints");
	GetExternalId(&ptable,    "table");
	GetExternalId(&pdupl,     "dupl");

	QP_ipc_prepare(psettrace, "on");
	if (QP_ipc_next(psettrace)) printf("Error: settrace failed\n");
	QP_ipc_close();

	for (;;) {
	    rc = 0;
	    do {
	        printf("Enter 2 integers (or 0 0 to go on): ");
		if (fgets(inbuf, sizeof inbuf, stdin) == NULL)
		    int1 = int2 = 0, rc = 2;
		else
	            rc = sscanf(inbuf, "%d%d\n", &int1, &int2);
	    } while (rc != 2);
	    if (int1 == 0 && int2 == 0) break;

	    QP_ipc_prepare(paddints, int1, int2);
	    QP_ipc_next(paddints, &int3);
	    if (QP_ipc_close()) printf("Error closing\n");

	    printf("The sum is: %d\n", int3);
	}

	printf("Now read all answers from a Prolog predicate: table\n");

	QP_ipc_prepare(ptable);
	while (!QP_ipc_next(ptable, &tabint, tabstr1, &tabflt, &tabatom)) {
	    QP_ipc_string_from_atom(tabatom, tabstr2);
	    printf("Answer is: %d %s %e %s (%d)\n",
		tabint, tabstr1, tabflt, tabstr2, tabatom);
	}

	printf("Now duplicate values\n");

	QP_ipc_prepare(psettrace, "off");
	if (QP_ipc_next(psettrace)) printf("Error: settrace failed\n");
	QP_ipc_close();

	for (;;) {
	    printf("Enter int, str, flt, str (or 'stop it' to terminate): ");
	    rc = scanf("%d%s%f%s", &tabint, tabstr1, &tabflt, tabstr2);
	    if (rc != 4) break;
	    tabatom = QP_ipc_atom_from_string(tabstr2);
	    printf("Str: %s  Atom: %d\n", tabstr2, tabatom);
	    if (QP_ipc_prepare(pdupl, tabint, tabstr1, tabflt, tabatom)) {
		printf("dupl prepare error\n");
		break;
	    }
	    QP_ipc_next(pdupl, &tabint, tabstr1, &tabflt, &tabatom);
	    QP_ipc_string_from_atom(tabatom, tabstr2);
	    if (QP_ipc_close()) printf("ERROR closing\n");
	    printf("Answer is: %d %s %e %s (%d)\n",
		tabint, tabstr1, tabflt, tabstr2, tabatom);
	}

	if (QP_ipc_shutdown_servant()) {
	    printf("Error shutting down servant\n");
	} else {
	    printf("Servant shut down successfully. Bye.\n");
	}
    }

