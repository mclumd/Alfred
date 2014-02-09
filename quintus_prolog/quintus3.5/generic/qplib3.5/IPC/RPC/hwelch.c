/*  File   : hwelch.c
    Author : Richard A. O'Keefe
    Updated: 01 Nov 1988
    Purpose: test findexec.c

    hwelch is Old English for "which", and is rather like the C-shell
    "which" command.
	hwelch cmd ... cmd
    searches your $PATH for each cmd in turn and prints out where it
    came from.

    This file is purely a test file which allows one to easily test
    the find_executable() function from findexec.c. It is not otherwise
    a part of the IPC package.

*/

#include <stdio.h>

extern char *find_executable();

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/01 hwelch.c	27.1";
#endif/*lint*/


main(argc, argv)
    int argc;
    char **argv;
    {
	char buffer[1024];
	int errs = 0;
	int i;

	for (i = 1; i < argc; i++)
	    if (find_executable(argv[i], 0, buffer, sizeof buffer)) {
		printf("%s\n", buffer);
	    } else {
		fprintf(stderr, "Can't find %s\n", argv[i]);
		errs++;
	    }
	exit(errs >= 128 ? 127 : errs);
    }

