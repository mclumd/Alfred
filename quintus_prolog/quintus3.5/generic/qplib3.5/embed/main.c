/* SCCS   : @(#)main.c	76.1 01/24/97
   File   : main.c
   Author : Tom Howland
   Origin : July 5th, 1984, but nothing of that remains.

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdlib.h>
#include "quintus.h"

int                             /* [PM] 3.5 was void */
main(int argc, char **argv)
    {
	int status;

	status = QP_initialize(argc, argv);
	if (status != QP_SUCCESS)
	    exit(1);
	(void) QP_toplevel();
	exit(0);
    }




#if WIN32
#include <windows.h>

/*
 *  if linked with -subsystem:windows, this is the entry point rather
 *  than main.  We use the global variables __argc and __argv to pass
 *  arguments to QP_initialize().
 */

int
PASCAL
WinMain(HINSTANCE current, HINSTANCE prev, LPSTR cmdline, int state)
    {
	/*
	 * initialize Prolog Window
	 */
	QU_winio_init(current, prev, cmdline, state);

	/*
	 * note that in Win32s argv[0] points to first argument
	 * rather than the program name
	 */
	if ( QP_initialize(__argc, __argv) == QP_SUCCESS )
	{
	    QP_toplevel();
	    QP_action(QP_EXIT);
	}
	exit(0);
    }

#endif
