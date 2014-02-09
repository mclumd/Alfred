/*  File   : plint.c
    Author : Richard A. O'Keefe
    Updated: 09/10/90
    Purpose: Prolog->Lint main program.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    The idea is that we have a set of files written in Prolog and
    in C, and some of the Prolog files contain foreign declarations,
    and we want to check that the Prolog files are consistent with
    the C files.

    Three programs are involved.
    (1) This is the main program.  It scans its argument list,
	and constructs a temporary file and two commands.
    (2) There is a Prolog program which reads the Prolog files
	and constructs a temporary file which contains C code
	declaring and calling the foreign functions.
    (3) There is a standard utility called "lint" which
	checks C programs for all sorts of stuff.

    This program is compiled by the command
	cc -DLIBRARY=\"..\" -DQUINTUS_H=\"..\" -DSTDLINT=\"..\" \
	   -o plint -O plint.c
    It is important that these three strings come in like this.
*/


#ifndef	lint
static	char SCCSid[] = "@(#)90/09/10 plint.c	56.3";
#endif/*lint*/

#include <signal.h>
#include <stdio.h>

#ifdef SYS5
#include <sys/types.h>
#include <fcntl.h> 
#else /*BSD4*/
#include <sys/file.h>
/* 
   In SunOS version prior to 4.1, umask returned an int.  Now it returns
   a mode_t.  This is supposed to be the way that Sys V does it.
*/
#ifndef __sys_stdtypes_h
typedef int mode_t;
#endif
#endif/*SYS5*/

#include "quintus.h"

extern int   strlen(/*char^*/);
extern int   strncmp(/*char^,char^,int*/);
extern int   strcmp(/*char^,char^*/);
extern char *strcpy(/*char^,char^*/);
extern char *strcat(/*char^,char^*/);
extern char *malloc(/*int*/);

extern int      open(/*char^,int,int*/);
extern int      close(/*int*/);
extern int      unlink(/*char^*/);
extern int      access(/*char^,int*/);
extern mode_t   umask(/*int*/);
extern int      getpid();

extern int   fprintf();
#ifdef SYS5
extern int   sprintf();
#else  /*BSD4*/
extern char *sprintf();
#endif/*SYS5*/

#define	Fprintf (void)fprintf
#define Sprintf (void)sprintf

static char  SrcName[80];

void make_temp_file()
    {
	int fd;
	mode_t omask;

	omask = umask(0000);
	Sprintf(SrcName, "/tmp/plint%.5u.c", getpid());
	fd = open(SrcName, O_WRONLY+O_CREAT+O_EXCL, 0600);
	if (fd < 0) {
	    Fprintf(stderr, "qplint:");
	    perror(SrcName);
	    exit(1);
	}
	(void) close(fd);
	(void) umask(omask);
    }


void kill_temp_file()
    {
	(void) unlink(SrcName);
    }


void catch_lethal_signals()
    {
	kill_temp_file();
	exit(1);
    }


void set_signals()
    {
	int s;

	for (s = SIGHUP; s <= SIGTERM; s++)
	    (void) signal(s, catch_lethal_signals);
    }


/*  library_file(p)
    is called when the argument list contains "-Qp" or "-Q p"
    and returns a new string "$LIBRARY/p".
*/
char *library_file(p)
    char *p;
    {
	int Ll = strlen(LIBRARY);
	int Lp = strlen(p);
	char *result = malloc(Ll+Lp+2);

	if (!result) {
	    perror("qplint:malloc:");
	    catch_lethal_signals();
	}
	(void)strcpy(result, LIBRARY);
	result[Ll] = '/';
	(void)strcpy(result+Ll+1, p);
	return result;
    }


/*  has_extension(p, e)
    is true when p points to a file name and e points to an extension
    (which must begin with ".") and p ends with with e.
*/
int has_extension(p, e)
    char *p, *e;
    {
	int Lp = strlen(p);
	int Le = strlen(e);

	return Lp > Le && !strcmp(p+Lp-Le, e);
    }

/*  is_prolog_file(p)
    is true when p has a ".pl" extension.
*/
#define is_prolog_file(p) has_extension((p), ".pl")

/*  is_header_file(p)
    is true when p has a ".h" extension.
*/
#define is_header_file(p) has_extension((p), ".h")



#ifdef	DEBUG
void print_command(program, argv)
    char *program;
    char **argv;
    {
	printf("About to run %s with arguments\n", program);
	while (*argv) printf("    %s\n", *argv++);
    }


void print_result(program, child, status)
    char *program;
    int child, status;
    {
	printf("Program %s ran as process %d with status %d\n",
	    program, child, status);
    }
#else /*!DEBUG*/
#define print_command(program, argv)
#define print_result(program, child, status)
#endif/*DEBUG*/


/*  run(Program, Argv, Envv)
    does a fork and then an execve with the same arguments.
    We don't have to close any files, because when run() is
    called only the three standard streams should be open.
*/
void run(program, argv, envv)
    char *program;
    char **argv, **envv;
    {
	extern int fork();
	extern int wait(/*int^*/);
	extern int execve(/*char^,char^^,cahr^^*/);
	int status = -1;
	int child = fork();
        /* [PM] 3.5 errno is often a macro these days: extern int errno; */

	if (child == 0) {
	    (void) execve(program, argv, envv);
	    exit(errno);
	}
	print_command(program, argv);
	if (child < 0 || wait(&status) != child || status) {
	    Fprintf(stderr, "qplint: %s failed with status %#x\n",
		program, status);
	    catch_lethal_signals();
	}
	print_result(program, child, status);
    }

		/*ARGSUSED*/
main(argc, argv, envv)
    int argc;
    char **argv;
    char **envv;
    {
	char *arg;		 /* element of argv[] */
	int c_files;		 /* count of .c files */
	int p_files;		 /* count of .pl files */
	char **prog_argp;	 /* points into prog_argv */
	char **lint_argp;	 /* points into lint_argv */
	char *(prog_argv)[1030]; /* arguments for program */
	char *(lint_argv)[1030]; /* arguments for stdlint */

	set_signals();
	make_temp_file();

	c_files = 0;
	p_files = 0;
	prog_argp = prog_argv;
	lint_argp = lint_argv;
	argv++;			 /* Skip this program's name */
	*prog_argp++ = "prolog";	/* fake argv[0] for Prolog */
	*prog_argp++ = SrcName;		/* output file */
	*prog_argp++ = QUINTUS_H;	/* embed/quintus.h */
#ifdef SYS5
        *lint_argp++ = "sh";
#endif/*SYS5*/
	*lint_argp++ = STDLINT;	 /* lint */
	while (arg = *argv++) {
	    if (!strncmp(arg, "-Q", 2)) {
		if (strlen(arg) == 2) arg = *argv++;
		else arg += 2;
		arg = library_file(arg);
	    }
	    if (*arg == '-') {	/* lint option */
		*lint_argp++ = arg;
	    } else
	    if (is_prolog_file(arg)) {
		p_files++;	/* *.pl file */
		*prog_argp++ = arg;
	    } else
	    if (is_header_file(arg)) {
		*prog_argp++ = arg;
	    } else {
		c_files++;	/* not *.pl or *.h or -* */
		*lint_argp++ = arg;
	    }
	}

	if (p_files) {
	    QP_pred_ref plint;

	    QP_initialize(prog_argp - prog_argv, prog_argv);
	    plint = QP_predicate("plint",0,"user");
	    *prog_argp = (char*)0;

	    if ((QP_query(plint) != QP_SUCCESS) 
	     || (access(SrcName, 0) != 0)) 
		exit(1);

	    *lint_argp++ = SrcName;
	    c_files++;
	} else {
	    Fprintf(stderr, "qplint: no prolog.pl files specified\n");
	}
	if (c_files) {
	    *lint_argp = (char*)0;
#ifdef SYS5
            run("/bin/sh", lint_argv, envv);
#else
	    run(STDLINT, lint_argv, envv);
#endif/*SYS5*/
	} else {
	    Fprintf(stderr, "qplint: no foreign.c files specified\n");
	}
	kill_temp_file();
	exit(0);
    }


