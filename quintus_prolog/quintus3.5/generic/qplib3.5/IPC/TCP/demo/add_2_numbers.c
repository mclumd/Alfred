/*  File   : 02/17/99 @(#)add_2_numbers.c	76.1 
    Author : Tom Howland
    Purpose: call the remote prolog session from the c-shell.
    SeeAlso: help(tcp), man tcp

This file is nearly identical to the example program cs.c, which is
more generally useful.  It is supplied to show how a C program might
use the output of a Prolog server.

usage

    arg 1 ... the handle file of the remote session.

For example,

    % add_2_numbers ~/tcp_demo_ServerFile

It works by copying all user_output from the prolog server to stdout.
It assumes that there is code like that found in the example program
server.pl for handling its requests.  It will NOT work on any server, just
on servers that have clauses for terms of the form

    term(_,not_prolog(G))

See the example program server.pl for a full explanation.

Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)99/02/17 add_2_numbers.c	76.1";
#endif	/* lint */

#include <stdio.h>

#ifdef WIN32
#include <winsock.h>
#else
#include <sys/socket.h>
#endif

#include "tcp.h"

/* [PM] 3.5 errno is often a macro these days: extern int errno; */

void eek(s)
char *s;
{
    extern errno;

    perror(s);
    exit(errno);
}

main(argc, argv)
int argc;
char *argv[];

{
    int descriptor, port, n;
    float f;
    long int FD;
    FILE *file;
    char *host, buf[BUFSIZ];	/* BUFSIZ defined in stdio */

    if (argc != 2) {
	printf("Usage: %s ServerFile\n", argv[0]);
	exit(1);
    }

/* fetch the port and host name from the file that was written by
prolog calling tcp_listen/1 */

    if(tcp_address_from_file(argv[1], &port, &host))exit(errno);

/* connect to the prolog server */

    descriptor = tcp_connect(host, port);
    if(descriptor == -1) exit(errno);

/* build the query we're going to send to prolog.  not_prolog/1 is a
form defined in the example program server.pl.  In English, what this
query is saying is

    - term(not_prolog((%s))).\n ... solve the query ... see server.pl
    - term(end_of_file).\n ... kill the connection
*/
    {
	float f1, f2;
	printf("Enter two numbers:  ");
	n = scanf("%e %e", &f1, &f2);
	sprintf(buf, "term(not_prolog((X is %e + %e, write(X), nl))).\nterm(end_of_file).\n", f1,f2);
    }

/* copy the prolog command to the buffer */

    n = strlen(buf);
    if (send(descriptor, buf, n, 0) != n) eek("send1");

/* interpret the output as the printed representation of a floating point
number.  */

    if (recv(descriptor, buf, sizeof(buf), 0) == -1) eek("recv");
    if (sscanf(buf, "%e", &f) != 1) eek("sscanf");
    printf("The result of the remote addition is %e\n", f);

/* shut down the socket */

    if (tcp_shutdown(descriptor) == -1) exit(errno);
}
