/*  File   : ipc.h
    Author : Richard A. O'Keefe.
    Updated: 11/01/88
    SCCS:    @(#)88/11/01 ipc.h	27.1
    Header : for the shared socket routines.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/

#define	SOCKQUEUELENGTH  5
    /*	You don't want to know
    */

#define	MAXHOSTNAME	32
    /*  This is the maximum length of a host name, plus 1.
	See "% man gethostname" on 4.2BSD systems".
	Hostname arguments are ignored on System V.
    */

extern	int	QP_make_socket();		/* in makesocket.c */
extern	int	QP_connect_socket();		/* in connsocket.c */
extern	int	QP_call_servant();		/* in callservant.c */
extern	int	QP_pipe_servant();		/* in callservant.c */
extern	void	QP_kill_servant();		/* in callservant.c */
extern	int	QP_link_socket();		/* in linksocket.c */
extern	char*	find_executable();		/* in findexec.c */

