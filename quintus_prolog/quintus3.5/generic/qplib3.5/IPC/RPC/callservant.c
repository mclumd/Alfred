/*  File   : callservant.c
    Author : David S. Warren
    Updated: 11/01/88
    Defines: QP_{call,pipe}_servant()

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    QP_pipe_servant(SavedStatePath, OutputPath, &ToSlave, &FromSlave)
	creates a child process on the same machine
	and connects to it through pipes.
	This is available in all UNIX ports.
	THIS ROUTINE ACTUALLY SETS UP THE PIPES, and returns them.

	If all goes well, ToSlave and FromSlave are set to the UNIX
	file descriptors of pipes connected, not to the child's
	*standard* input and output, but
	    ToSlave   --> PIPE_IN_FD in servant
	    FromSlave <-- PIPE_OUT_FD in servant.

    QP_call_servant(HostName, SavedStatePath, OutputPath,
		    ThisHost, ThisPort)
	creates a child process on a remote machine (or the same one)
	and connects to it through sockets.
	This requires the 4.2BSD network support routines.
	THIS ROUTINE REQUIRES THE CALLER TO SET UP THE SOCKETS.

	If all goes well, the servant will connect to the port
	ThisPort @ ThisHost using its own sockets.

    SavedStatePath is the UNIX pathname of a Prolog saved state which
    had better have been created by
	save_servant/1		(in qpcallqp.pl)
    or	save_ipc_servant/1	(in  ccallqp.pl)

    OutputPath is the UNIX pathname of the local file that the standard
    output of the servant process is to be written to.  There are two
    special cases: "user" means the standard output of the servant is to
    be written to the standard output of this process, and "" means that
    the standard output of the servant is to be written to /dev/null.

    The main point of these routines is set up the child, and to
    conceal the details of how the command is constructed.

    If the servant process cannot be started, the value -1 is
    returned.  Otherwise, the value 0 is returned.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/01 callservant.c	27.2";
#endif/*lint*/
#define	NullS (char*)0

#include <stdio.h>
#include <signal.h>
#include <unistd.h>             /* [PM] 3.5 read() */
#include <string.h>             /* [PM] 3.5 strcmp() */

#include "fcntl.h"
#include "ipc.h"
#include "ipcerror.h"

static char NullFile[] = "/dev/null";

/* [PM] 3.5 errno is often a macro these days: extern int errno; */
#define HCECK(x) if ((x) < 0) { \
	fprintf(stderr, "x failed with errno %d\n", errno); \
	_exit(1); }
#define	CHECK(x) if ((x) < 0) _exit(1)
    /*  It is IMPORTANT that if anything goes wrong in a child
	it calls _exit(), NOT exit().  Otherwise it might smash
	files that the parent still has open.  See vfork(2).
    */

#if 0                           /* [PM] 3.5 get these from headers instead */
extern	int	execv(/* char *path, char **argv */);
extern	void	_exit(/* int code */);
extern	int	kill(/* int pid, int sig */);
extern	int	pipe(/* int filedes[2] */);
extern	int	wait(/* int *status */);

extern	int	strncmp(/* char*, char*, int */);
extern	char*	strcpy(/* char*, char* */);
#endif /* [PM] 3.5 get these from headers instead */

#ifdef	SYS5

#if 0                           /* [PM] 3.5 get these from headers instead */
extern	int	fork();
extern	int	dup(/* int olddes */);
#endif /* [PM] 3.5 get these from headers instead */

#define	VFORK	fork
#define	DUP2(old,new) { (void)close(new); if (dup(old) != new) _exit(1); }
#else /*4BSD*/

#if 0                           /* [PM] 3.5 get these from headers instead */
extern	int	vfork();
extern	int	dup2(/* int olddes, int newdes */);
#endif /* [PM] 3.5 get these from headers instead */

#define	VFORK	vfork
#define	DUP2(old,new) { CHECK(dup2(old, new)); }

#endif/*SYS5*/


/*  This is an auxiliary routine which closes all the open file
    descriptors except STD_{IN,OUT,ERR}.  The method of determining
    the number of descriptors to close is system-dependent.
*/
static void close_all_but_standard_descriptors(keep1, keep2) /* [PM] 3.5 was returning int */
    int keep1, keep2;
    {
	int i;
#ifdef	SYS5
	i = -1;
#else /*4BSD*/
	i = getdtablesize();
#endif/*SYS5*/
	if (i < 0)
#ifdef	_NFILE
	    i = _NFILE;
#else
	    i = 20;
#endif/*_NFILE*/
	while (--i > STD_ERR)
	    if (i != keep1 && i != keep2)
		(void)close(i);
    }



/*  interpreter(Program, Buffer, BufLen)
    checks whether Program is the UNIX pathname of an executable and
    readable file, and if so whether it is an object file or one which
    should be given to an interpreter, and in the latter case, to what
    interpreter.

	Program	is the UNIX pathname of a file to be checked.

	Buffer	is where the name of the interpreter will be written
		if Program should be given to an interpreter.
	BufLen	is the size of Buffer.

	RESULT:	if Program is readable and starts with a suitable
		magic line, Buffer is returned, otherwise NULL.

	errno:	if Program can't be read, see open(2) or read(2).
		if Program can be read, but hasn't got a magic header,
		ENOEXEC.  If it has a magic header, but there is no
		room in Buffer, E2BIG (not quite right, but close).

    Note: this is only needed in really strict System Vs.  Most other
    UNIXes will give programs lacking the "magic bytes" to /bin/sh,
    or follow the 4.xBSD convention of using #!<interpreter> as the
    header of a file.  Those UNIX systems handle all this rubbish in
    exec(2), which is where it belongs.
*/
static char *interpreter(Program, Buffer, BufLen)
    char *Program;
    char *Buffer;
    int   BufLen;
    {
	int fd;
	int l, e;
	register char *p, *q;
	static char prefix[] = "#!";
	char scratch[MAXPATHNAME + sizeof prefix + 4];

	fd = open(Program, O_RDONLY);
	if (fd < 0) return NullS;
	l = read(fd, scratch, sizeof scratch);
	e = errno;
	close(fd);
	if (strncmp(scratch, "exec ", 5) == 0) {
	    (void) strcpy(Buffer, "/bin/sh");
	    return Buffer;
	}
	errno = e;
	if (l < sizeof prefix) return NullS;
	scratch[l] = '\0';
	for (p = prefix, q = scratch; *p; )
	    if (*p++ != *q++) return NullS;
	for (l = BufLen, p = Buffer; l > 0 && *q > ' '; l--) *p++ = *q++;
	errno = E2BIG;
	if (l <= 0) return NullS;
	*p = '\0';
	return Buffer;
    }


/*  QP_pipe_servant()
    executes the command
	${SavedStatePath} -pipe ${I} ${O} ${I}<${*ToSlave} ${O}>${*FromSlave}
    with standard I/O redirection
	case OutputPath = NULL or ""
	    </dev/null >/dev/null
	case OutputPath = "user"
	    </dev/null
	default
	    </dev/null >${OutputPath} 2>1

    The pipe numbers $I and $O are whatever they happen to be in the parent.
    We used to reserve 3 and 4 for them, but some systems preconnect them.
    The child looks at its argument to see whether it has
	-pipe	PIPE_IN_FD	PIPE_OUT_FD
	-socket	HOSTNAME	PORTNUM
    and acts appropriately.

    You may well wonder why we don't construct a string and ship it off
    to system(3).  The answer is that, due to the juggling with pipes,
    we CAN'T.  There is no way of passing pipes to system().

    BEWARE!  BEWARE!  If all goes well, we return the child PID.  The
    child is left running.  If the child dies before we expect it, it
    may show up in some entirely unrelated call to wait().
*/
int QP_pipe_servant(SavedStatePath, OutputPath, FromSlave, ToSlave)
    char *SavedStatePath;
    char *OutputPath;
    FILE**FromSlave;
    FILE**ToSlave;
    {
	int undo;		/* how far did we get? */
	int tochild[2];		/* connect to PIPE_IN_FD */
	int fromchild[2];	/* connect to PIPE_OUT_FD */
	int child;		/* child's UNIX Process ID */
	int fd;			/* used in I/O redirection */
	int status;		/* how did child die? */
	char fdnums[2][12];	/* pipe numbers as text */
	char fullcmd[MAXPATHNAME];
	char interp [MAXPATHNAME];

        child = 0;              /* [PM] 3.5 avoid gcc warning. It will have a proper value before use. */

	undo = 0;
	if (!find_executable(SavedStatePath, NullS, fullcmd, sizeof fullcmd)) {
	    errno = ENOENT;	/* can't find file */
	    IOError(SavedStatePath);
	    goto ERROR;
	}
	if (pipe(tochild) < 0) goto ERROR;
	(void)sprintf(fdnums[0], "%d", tochild[0]);
	undo = 2;
	if (pipe(fromchild) < 0) goto ERROR;
	(void)sprintf(fdnums[1], "%d", fromchild[1]);
	undo = 3;
	child = VFORK();
	if (child == 0) {
	    /* This is the child process */

	    /*  Redirect standard I/O streams  */
	    close_all_but_standard_descriptors(
		tochild[0], fromchild[1]);

	    if (!OutputPath || !*OutputPath) {
		/* route output to /dev/null */

		CHECK(fd = open(NullFile, O_WRONLY, 0));
		DUP2(fd, STD_OUT)
		CHECK(close(fd));
	    } else
	    if (strcmp(OutputPath, "user")) {
		/* route output to OutputPath */
		CHECK(fd = open(OutputPath, O_WRONLY+O_CREAT+O_TRUNC, 0666));
		DUP2(fd, STD_OUT)
		DUP2(fd, STD_ERR)
		CHECK(close(fd));
	    }
	    CHECK(fd = open(NullFile, O_RDONLY));
	    DUP2(fd, STD_IN)
	    CHECK(close(fd));

	    CHECK(access(fullcmd, X_OK));
	    if (interpreter(fullcmd, interp, sizeof interp)) {
		(void) execl(interp, interp, fullcmd,
		    "-pipe", fdnums[0], fdnums[1], NullS);
	    } else {
		(void) execl(fullcmd, SavedStatePath,
		    "-pipe", fdnums[0], fdnums[1], NullS);
	    }
	    perror(fullcmd);
	    _exit(1);
	    /*NOTREACHED*/
	}

	/* This is the parent process */
	if (child < 0) goto ERROR;
	undo = 4;			/* child was started */
	if (!(*ToSlave = fdopen(tochild[1], "w"))) goto ERROR;
	undo = 5;			/* stream opened */
	if (!(*FromSlave = fdopen(fromchild[0], "r"))) goto ERROR;
	undo = 6;			/* stream opened */
	(void)close(fromchild[1]);	/* close "write" end */
	(void)close(tochild[0]);	/* close "read" end */	
	return child;

ERROR:
	switch (undo) {
	    case 6:	(void)fclose(*FromSlave);
	    case 5:	(void)fclose(*ToSlave);
			(void)kill(child, SIGHUP);
	    case 4:	(void)wait(&status);	/* BLIND HOPE */
	    case 3:	(void)close(fromchild[0]);	
			(void)close(fromchild[1]);
	    case 2:	(void)close(tochild[0]);
	    		(void)close(tochild[1]);
	    case 0:	break;
	}
	return -1;
    }


/*  QP_kill_servant(who)
    is given a process number and told to kill it.  There are several
    more or less civilised things we could do to the process, but the
    one thing which is exactly right in context is to tell it SIGHUP.
    The process's one caller has indeed "hung up".  It is considered
    good UNIX manners never to suppress this signal, but always to
    abandon ship as expeditiously as is consistent with safety when
    this signal is received.

    Having sent the SIGHUP signal, we then wait for the child to die.
    There ought to be a time-out in here, and there will be before we
    release this.
*/
void QP_kill_servant(who)
    int who;
    {
	int status;

	(void)kill(who, SIGHUP);
	(void)wait(&status);
    }



/*  QP_call_servant()
    executes the command
	rsh ${HostName} -n ${SavedStatePath} \
		-socket ${ThisHost} ${ThisPort} '&'
    with I/O redirection
	case OutputPath = NULL or ""
	    </dev/null >/dev/null
	case OutputPath = "user"
	    </dev/null
	default
	    </dev/null >${OutputPath} 2>1

    The child looks at its argument to see whether it has
	-pipe	PIPE_IN_FD	PIPE_OUT_FD
	-socket	HOSTNAME	PORTNUM
    and acts appropriately.

    You may well wonder why we don't construct a string and ship it off
    to system(3) as the first release of this code did.  There are two
    reasons.  The main one is that the old code imposed a total limit
    of 200 characters on a command (C version) or 512 characters (Prolog
    version) and this is just not acceptable when you realise that a
    file name can be 1,024 characters long in some versions of UNIX, and
    we have two file names to worry about.  With this code, we impose NO
    limits at all other than the limits execve(2) imposes on ALL programs.
    The minor reason is that this avoids a call to /bin/sh on the local
    machine, so we start up that much faster.
*/
int QP_call_servant(HostName, SavedStatePath, OutputPath, ThisHost, ThisPort)
    char *HostName;
    char *SavedStatePath;
    char *OutputPath;
    char *ThisHost;
    int  ThisPort;
    {
	int child;		/* PID of "rsh" process */
	int fd;			/* for redirecting I/O */
	char fullcmd[MAXPATHNAME];
	static char PortName[12];
	static char *(argv[]) =
	    {
		"rsh",		/* short name of the remote shell */
		NullS,		/* for HostName */
		"-n",		/* disconnect standard input */
		NullS,		/* for SavedStatePath */
		"-socket",	/* tells the child what it has got */
		NullS,		/* for ThisHost */
		PortName,	/* for ThisPort */
		NullS		/* genuine end of argument vector */
	    };

	if (!find_executable(SavedStatePath, NullS, fullcmd, sizeof fullcmd)) {
	    errno = ENOENT;	/* can't find file */
	    IOError(SavedStatePath);
	    return -1;
	}
	if (!strcmp(HostName, "local")) HostName = ThisHost;
	argv[1] = HostName;	/* where to run the servant */
	argv[3] = fullcmd;
	argv[5] = ThisHost;
	(void)sprintf(PortName, "%d", ThisPort);

	child = VFORK();
	if (child == 0) {
	    /*  This is the child process  */

	    close_all_but_standard_descriptors(STD_IN, STD_OUT);
	    CHECK(fd = open(NullFile, O_RDONLY));
	    DUP2(fd, STD_IN)
	    CHECK(close(fd));
	    if (!OutputPath || !*OutputPath) {
		/* route output to /dev/null */

		CHECK(fd = open(NullFile, O_WRONLY, 0));
		DUP2(fd, STD_OUT)
		CHECK(close(fd));
	    } else
	    if (strcmp(OutputPath, "user")) {
		/* route output to OutputPath */

		CHECK(fd = open(OutputPath, O_WRONLY+O_CREAT+O_TRUNC, 0666));
		DUP2(fd, STD_OUT)
		DUP2(fd, STD_ERR)
		CHECK(close(fd));
	    }

	    (void) execv("/usr/ucb/rsh", argv);
	    _exit(1);
	    /*NOTREACHED*/		/* tell Lint about _exit */
	}
	return  child < 0 ? -1 : 0;
    }

