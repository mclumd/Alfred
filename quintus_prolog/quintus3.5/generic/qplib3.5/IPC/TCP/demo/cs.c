/*  File   : 02/17/99 @(#)cs.c	76.1 
    Author : Tom Howland
    Updated: 02/17/99
    Purpose: call the remote prolog session from the c-shell.
    SeeAlso: tcp.doc

cs stands for Call Server.

    arg 1 ... the handle file of the remote session.
    arg 2 ... the goal

For example,

    % cs ~/tcp_demo_ServerFile "write('hi there')"

will write the string "hi there" to the terminal.

It works by copying all user_output from the remote prolog server to
this local client's stdout.

It assumes that there is code like that found in the example program
server.pl for handling its requests.  It will NOT work on any server, just
on servers that have clauses for terms of the form

    term(_,not_prolog(G))

See the example program server.pl for a full explanation.

Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)99/02/17 cs.c	76.1";
#endif	/* lint */

#ifdef WIN32
#include <winsock.h>
#else
#include <sys/socket.h>
#endif
 
#include "tcp.h"

#include <errno.h>

/* 4096 happens to be the size of a socket buffer.  There is no reason you
couldn't declare the following constant BUFSIZE as something smaller */

#define BUFSIZE 4096

/* cs_eek() is a little error reporting function */

void static cs_eek(s)
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
    int c, port,n;
    long int FD;
    char *host, buf[BUFSIZE];

    if (argc != 3)
    {
	printf("Usage: %s ServerFile PrologCommand\n", argv[0]);
	exit(1);
    }

/* fetch the port and host name from the file that was written by the
call to tcp_listen() */

    if(tcp_address_from_file(argv[1], &port, &host))exit(errno);

/* connect to the prolog server */

    c = tcp_connect(host, port);
    if(c == -1) exit(errno);

/* build the query we're going to send to prolog.  not_prolog/1 is a
form defined in the example program server.pl.  In English, what this
query is saying is

    - term(not_prolog((%s))).\n ... solve the query ... see server.pl
    - term(end_of_file).\n ... kills the connection
*/

    sprintf(buf, "term(not_prolog((%s))).\nterm(end_of_file).\n", argv[2]);

/* copy the prolog command to the buffer */

    n = strlen(buf);
    if (send(c, buf, n, 0) != n) cs_eek("cs.send1");

/* copy the output from the prolog server to stdout (1) */

    for (;;)
    {
	n = recv(c, buf, BUFSIZE, 0);
	switch (n)
	{
	  case -1:	/* error while reading socket */
	    cs_eek("recv");
	  case 0:	/* end of file */
	    exit(0);
	  default:	/* result.  The file descriptor for stdout is 1 */
	    if (write(1, buf, n) != n)
		cs_eek("cs.write2");
	}
    }
}
