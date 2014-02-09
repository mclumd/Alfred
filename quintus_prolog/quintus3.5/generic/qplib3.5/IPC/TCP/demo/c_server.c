/*  File   : 02/17/99 @(#)c_server.c	76.1 
    Author : Tom Howland
    Updated: 8/2/89
    Purpose: Demonstration of a simple tcp server.
    SeeAlso: c_server.pl, help(tcp)

    Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

This program is a server that echos what is sent to it via it's sockets
to stdout.

An example its use is described in c_server.pl

*/

#ifndef	lint
static	char SCCSid[] = "@(#)99/02/17 c_server.c	76.1";
#endif	/* lint */

#ifdef WIN32
#include <winsock.h>
#else
#include <sys/socket.h>
#endif
 
#include "tcp.h"
#include <errno.h>

/* eek() is a crude little error handler */

void eek(s)
char *s;
{
    perror(s);
    exit(errno);
}

/* 4096 happens to be the size of a socket buffer.  There is no reason you
couldn't declare the following constant BUFSIZE as something smaller */

#define BUFSIZE 4096

main(argc, argv)
int argc;
char *argv[];
{
    int Port;
    char *TheHostName;
    int PassiveSocket;
    char buf[BUFSIZE];
    int FD;
    char *Host;

    if (argc != 2) {
	printf("Usage: %s ServerFile\n", argv[0]);
	exit(1);
    }

    if(tcp_create_listener(0, &Port, &Host, &PassiveSocket)) exit(errno);
    if(tcp_address_to_file(argv[1], Port, Host)) exit(errno);
    printf("Passive socket %d created on %s, port number %d\n",
	   PassiveSocket, Host, Port);
    for (;;) {
	switch (tcp_select(tcp_BLOCK, 0.0, &FD)) {
	  case tcp_ERROR:
	    exit(errno);
	  case tcp_SUCCESS:
	    if (FD == PassiveSocket) {
		if((FD = tcp_accept(PassiveSocket)) == -1) exit(errno);
		printf("Connection to %d accepted\n", FD);
	    } else {
		int n;

		n = recv(FD, buf, BUFSIZE, 0);
		switch (n) {
		  case -1:
		    eek("c_server.recv");
		  case 0:
		    if (tcp_shutdown(FD) == -1)
			exit(errno);
		    break;
		  default:
		    if (write(1, buf, n) != n)
			eek("c_server.write");
		}
	    }
	}
    }
}
