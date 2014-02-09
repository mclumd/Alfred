/*  File   : ipcerror.h
    Author : David S. Warren
    Updated: 11/01/88
    SCCS:    @(#)88/11/01 ipcerror.h	27.1
    Header : for ipcerror.c
*/

#include <errno.h>
#define	ESOCKUI	200		/* SOCKets are UnImplemented */
#define	EFSMBLK	201		/* Finite State Machine transition BLocKed */
/* [PM] 3.5 errno is often a macro these days: extern int errno; */

extern	void	IOError(/*char^*/);
extern	void	XDRerror(/*char^*/);

