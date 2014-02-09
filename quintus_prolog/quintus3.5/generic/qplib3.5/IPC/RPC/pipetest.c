/*  File   : pipetest.c
    Author : David S. Warren
    Updated: 07 Jan 1988
    Defines: connected_to_pipes()

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    connected_to_pipes()
    is to be called when the Prolog process starts up.
    It checks whether it has been called as a child (through pipes)
    rather than remotely (through sockets), by testing whether the
    channels PIPE_IN_FD and PIPE_OUT_FD are already connected to
    pipes.  The way we check this is a well-known UNIX hack.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/01/07 pipetest.c	21.1";
#endif	lint

#include <stdio.h>
#include "ipc.h"
#include "ipcerror.h"

int connected_to_pipes()
    {
	errno = 0;
	lseek(PIPE_IN_FD,  0L, 1);
	if (errno != ESPIPE) return 0;
	lseek(PIPE_OUT_FD, 0L, 1);
	if (errno != ESPIPE) return 0;
	return 1;
    }


