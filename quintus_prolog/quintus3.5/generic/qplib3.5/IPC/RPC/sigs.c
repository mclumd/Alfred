/*  File   : sigs.c
    Author : David S. Warren
    Updated: 11/10/88
    Purpose: to ignore all interrupts (not a good idea!)

    Note that it is impossible to block SIGKILL, SIGSTOP, or SIGCONT,
    and that it is considered bad manners to block SIGHUP but we do
    it anyway.  The assumption had been made that all the signals
    [1..NSIG) actually existed and that trying to ignore them was
    safe.  This is not true on one UNIX which claims to be System V
    but defines these signals.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/10 sigs.c	27.3";
#endif/*lint*/

#include <stdio.h>
#include <signal.h>
/*  Older C compilers and UNIX systems define  extern int  (*signal())();
    newer C compilers and UNIX systems define  extern void (*signal())();
    The error result is variously -1, BADSIG, and SIG_ERR.  We get around
    this by casting the result of signal() to an appropriate type.
*/
typedef void (*SigFunc)();

void sigsign()
    {
	int signo;

	for (signo = 1; signo < NSIG; signo++)
	    switch (signo) {
		case SIGKILL:
		case SIGHUP:
#ifdef	SIGSTOP
		case SIGSTOP:
		case SIGCONT:
#endif
		    break;
		default:
		    if ((SigFunc)signal(signo, SIG_IGN) != (SigFunc)(-1))
			break;
		    fprintf(stderr,
			"\n! ERROR: signal(%d, SIG_IGN) failed\n", signo);
	    }
    }

