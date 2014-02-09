/*  SCCS   : @(#)QU_errlist.c	69.1 09/07/93
    File   : QU_errlist.c
    Author : Tom Howland
    Updated: 5/11/90
    Purpose: Prolog Interface to C error messages
    SeeAlso: quintus.h

    Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifdef SYMHIDE
#include "symap.h"
#endif

char *QU_errlist[] =	{ 
	"no error",				/* 0, QP_START_ECODE */
	"input past end of file",		/* QP_E_EXHAUSTED */
	"unknown stream parameter option",	/* QP_E_STATE */
	"stream is in an inconsistent state",	/* QP_E_CONFUSED */
	"fail in low level read function",	/* QP_E_CANT_READ */
	"fail in low level write function",	/* QP_E_CANT_WRITE */
	"fail in low level flush function",	/* QP_E_CANT_FLUSH */
	"fail in low level seek function",	/* QP_E_CANT_SEEK */
	"fail in low level close function",	/* QP_E_CANT_CLOSE */
	"operation would block",		/* QP_E_NONBLOCK */
	"invalid argument",			/* QP_E_INVAL */
	"no permission for the stream",		/* QP_E_PERMISSION */
	"overflow the output record",		/* QP_E_OVERFLOW */
	"stream is invalid or not registered",	/* QP_E_BAD_STREAM */
	"stream buffer is not empty",		/* QP_E_BUFFERED */
	"no filename specified",		/* QP_E_FILENAME */
	"file is a directory",			/* QP_E_DIRECTORY */
	"invalid input/output mode",		/* QP_E_BAD_MODE */
	"invalid format",			/* QP_E_BAD_FORMAT */
	"invalid seeking type",			/* QP_E_SEEK_TYPE */
	"invalid flush type",			/* QP_E_FLUSH_TYPE */
	"invalid overflow type",		/* QP_E_OV_TYPE */
	"bad record size",			/* QP_E_REC_SIZE */
	"bad system open option",		/* QP_E_SYS_OPTION */
	"not enough memory",			/* QP_E_NOMEM */
	"stream table is full",			/* QP_E_MFILE */
	"%s not followed by a saved-state argument",	/* QP_E_CMDSS */
	"%s not followed by a command string argument", /* QP_E_CMDCS */
	"%s not followed by a trace-flag argument",	/* QP_E_CMDTF */
	"more than one %s option",			/* QP_E_OPTIONS */
	"%s and %s options are incompatible",		/* QP_E_CMDOI */
	"unknown Prolog option: %s",			/* QP_E_CMDUO */
	"not enough space for path names",		/* QP_E_CMDNSPN */
	"not enough space for prolog command",		/* QP_E_CMDNSPC */
	"putenv failed",				/* QP_E_CMDPF */
	"too many emacs arguments",			/* QP_E_CMDTMEA */
	"Loading %s with %s ...",			/* QP_I_CMDELOAD */
	"could not exec %s",				/* QP_E_CMDEE */
	"%s not qsetpath'd",				/* QP_E_CMDNQSP */
	"no top level",					/* QP_E_NO_TOP_LEVEL */
	"Prolog interruption (h for help)? ",	     /* QP_I_INTERRUPT_PROMPT */
					     /* QP_I_INTERRUPT_HELP_1 */
	"\n\
Prolog interrupt options:\n\
  h  help         - this list\n\
  c  continue     - do nothing\n",                  /* QP_I_INTERRUPT_HELP_2 */
        "\
  d  debug        - debugger will start leaping\n\
  t  trace        - debugger will start creeping\n",/* QP_I_INTERRUPT_HELP_3 */
        "\
  a  abort        - abort to the current break level\n\
  q  really abort - abort to the top level\n\
  e  exit         - exit from Prolog\n",
	"unknown error",			     /* QP_END_ECODE */
    };
