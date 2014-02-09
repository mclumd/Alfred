/*  File   : unix.c
    Author : Richard A. O'Keefe
    Updated: 11/12/89
    Purpose: Invoking UNIX commands.

    Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

    Qshell(shell, command)
    invokes one of the UNIX shells (if shell=="", the environment variable
    SHELL is used, failing that /bin/sh) to run command (if command=="",
    the shell is run interactively).

    QPtemp(template, &atom, race)
    makes a temporary file name as mktemp() would do it, except that
    -- if it succeeds, it returns the file name as an atom
    -- if it fails, it returns the value of errno
    --  if it succeeds and race is zero, it leaves the file created so
	that a later call to QPtemp will not reuse the same name; you
	can still create the file, but it is safer.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)95/05/30 unix.c  75.1";
#endif/*lint*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifdef WIN32
#include <io.h>
#include <process.h>
#endif
#if unix                        /* [PM] 3.5 this is the test used in the code around uses of fork et al */
#include <unistd.h>             /* [PM] 3.5 fork etc */
#endif /* unix */

#include "quintus.h"

/*  Older C compilers and UNIX systems define  extern int  (*signal())();
    newer C compilers and UNIX systems define  extern void (*signal())();
    The error result is variously -1, BADSIG, and SIG_ERR.  We get around
    this by casting the result of signal() to an appropriate type.
*/
typedef void (*SigFunc)();

/*  Most UNIX systems now define FOPEN_MAX in <stdio.h> to be the
    the maximum number of streams which could be open at one time.
    We try NOFILE in <sys/param.h> for old Unix's like SunOS4.

    We use this number to close all open files in the child; it is important
    that we do NOT close stdio streams because we DON'T want output
    buffers flushed twice.
*/

#ifndef FOPEN_MAX
#include <sys/param.h>
#define	FOPEN_MAX NOFILE
#endif

/*  Qshell(shell, command, flag)
    flag = 0 :	shell names a command interpreter to be run,
		command is ignored.
    flag = 1 :	shell names a program to be run,
		command is its single argument.
    flag = 2 :	shell names a command interpreter to be run,
		command is the command it is to interpret.
    This is really designed for UNIX, and of the Prolog commands
    built from it in unix.pl, only shell(x) and shell really make
    much sense under VMS.  (system(..) from strings.pl makes some
    sense too.)  There is currently no provision for selecting
    Dec/Shell or DCL specifically.
    The general rule of operating-system-related functions in this
    library is that they should either return 0 to indicate
    success or else they should return an "errno" error code
    (which will always be non-zero).  See errno.pl for a table of
    error codes; we've added a few of our own.
    DEFICIENCY: Qshell does not obey this rule.
    Instead, it just returns 0 for success, non-0 for failure.
*/
int Qshell(shell, command, flag)
    char *shell, *command;
    int flag;				/* use the -c flag? */
    {
#if unix
	int status = -1;		/* child's termination+exit status */
	pid_t child = fork();		/* child's process id */
	int fd;				/* for closing files */

	if (child == 0) {		/* this is the child process */
	/*  all open files other than std{in,out,err} must be closed, but  */
	/*  we just want to close the channels, not call fclose(), as the  */
	/*  parent process will do that itself in due course.		   */

	    for (fd = FOPEN_MAX; --fd > 2; ) (void) close(fd);

	/*  work out which shell to use  */

	    if (*shell == '\0')
		if (!(shell = getenv("SHELL")))
		    shell = "/bin/sh";

	/*  try to execute the shell. NB: same standard files!  */

	    switch (flag) {
		case 0:			/* interactive shell (no args) */
		    execl(shell, shell, (char*)0);
		    break;
		case 1:			/* other program (1 arg) */
		    execl(shell, shell, command, (char*)0);
		    break;
		case 2:			/* non-interactive shell (2 args) */
		    execl(shell, shell, "-c", command, (char*)0);
		    break;
	    }

	/*  if we get here, the execl() call failed  */

	    exit(1);
	}
	{
	    SigFunc oldsig = (SigFunc)signal(SIGINT, SIG_IGN);
	    int result =  child < 0 || wait(&status) != child || status != 0;
	    (void)signal(SIGINT, oldsig);
	    return result;
	}
#elif WIN32
	int status = -1;

	if(*shell == '\0')
	    if(!(shell = getenv("COMSPEC")))
		shell = "C:\\command.com";

	switch(flag) {
	    case 0:	/* interactive shell (no args) */
		status = spawnl(P_WAIT, shell, shell, (char *)0);
		break;
	    case 1:	/* other program (1 arg) */
		status = spawnl(P_WAIT, shell, command, (char*)0);
		break;
	    case 2:	/* non-interactive shell (2 args) */
		status = spawnl(P_WAIT, shell, shell, "/C", command, (char*)0);
		break;
	}
	return status;
#else
#if !QP_TCP_INHIBIT_BARF_AT_UNSUPPORTED_PLATFORM /* [PM] 3.5 booby trap, either unix or win32 should be true */
#error "This platform is not supported"
#endif /* !QP_TCP_INHIBIT_BARF_AT_UNSUPPORTED_PLATFORM */
	return 1;			/* not supported */
#endif
    }


/*  QPtemp(template, &atom, race)

    is based on the BSD function mktemp().  template is a string which must
    contain a block of 6 consecutive Xs somewhere in it (this generalises
    the BSD function, which insists that the Xs must be at the end, and
    makes it easier to use e.g. "[-.TEMPDIR]BUGXXXXXX.LOG" under VMS).  It
    is not changed in any way.  If template is longer than an atom name
    can be, or if it does not contain 6 consecutive Xs, an error code is
    returned.  Let the template have the form ${prefix}XXXXXX${suffix}.
    Then QPtemp tries all the names of the form
	${prefix}${char}${pid}${suffix}
    where ${pid} is the last 5 digits of the process number and ${char} is
	a--zA--Z0--9	in UNIX
	    A--Z0--9	in VMS
    When it succeeds in creating a file with such a name, it returns the
    successful name  as the value of *atom and returns a zero "error code".
    If it determines that it can't possibly succeed, it returns an error
    code at once, leaving *atom untouched.

    BSD Unix has two versions of this: mktemp() -- which doesn't leave a
    file behind, which means that races are possible -- and mkstemp() --
    which returns an open file descriptor.  It would be a good idea to
    put together an operation "create temporary file and return stream",
    but that has not been done yet.  Instead, the "race" argument says
	-- race == 0 => leave an empty file in the file system.
			It is safe to open this file 'write' or 'append'
			and future calls to QPtemp won't be misled.
	-- race != 0 =>	do not leave an empty file behind.  This means
			that there is nothing to clean up, but the next
			QPtemp call will return the same name.
*/

int QPtemp(name, atom, race)
    char *name;
    QP_atom *atom;
    {
	int n, fd;
	char *p;
	char buff[QP_MAX_ATOM+1];
	
	if ((int)strlen(name) > QP_MAX_ATOM) {	/* the name is too long */
#ifdef	ENAMETOOLONG
	    return ENAMETOOLONG;
#else
	    return EINVAL;
#endif
	}
	(void) strcpy(buff, name);		/* make a mutable copy */

	p = strrchr(buff, 'X');
	if (!(p = strrchr(buff, 'X'))		/* no 'X's at all */
         || (n = (p-buff)+1) < 6		/* last X too near start */
	 || strncmp((p -= 5), "XXXXXX", 6)	/* there are not six Xs */
	) {					/* name has no XXXXXX in it */
	    return EINVAL;
	}

	(void) sprintf(p+1, "%05d", getpid() % 100000);
	/* That smashed the next character after the Xs */
	(void) strcpy(buff+n, name+n);		/* restore <suffix> */

	n = 'a';

	for (;;) {
	    *p = n;
	    fd = open(buff, O_WRONLY | O_CREAT | O_EXCL, 0666);
	    if (fd >= 0) {
		(void) close(fd);
		*atom = QP_atom_from_string(buff);
		if (race) (void) unlink(buff);
		return 0;
	    }
#ifdef WIN32
	    if (errno != EEXIST && errno != EACCES) return errno;
#else
	    if (errno != EEXIST && errno != EISDIR) return errno;
#endif
	    if (n == 'Z') n = '0'; else
	    if (n == '9') break; else
	    n++;
	}
	return -3;				/* nothing left to try */
    }

