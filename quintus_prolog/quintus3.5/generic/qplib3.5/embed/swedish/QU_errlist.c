/*  SCCS   : @(#)QU_errlist.swedish.c	69.1 09/07/93
    File   : QU_errlist.swedish.c
    Author : Jonas Almgren from QU_errlist.c
    Updated: Dec. 90
    Purpose: Prolog Interface to C error messages in Swedish
    SeeAlso: quintus.h

    Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifdef SYMHIDE
#include "symap.h"
#endif

char *QU_errlist[] =	{ 
	"inget fel",				/* 0, QP_START_ECODE */
	"input efter filslut",  		/* QP_E_EXHAUSTED */
	"okaent stroemparameterval",    	/* QP_E_STATE */
	"stroem aer i otillaatet tillstaand",	/* QP_E_CONFUSED */
	"misslyckande i laagnivas laesfunktion",	/* QP_E_CANT_READ */
	"misslyckande i laagnivas skrivfunktion",	/* QP_E_CANT_WRITE */
	"misslyckande i laagnivas flushfunktion",	/* QP_E_CANT_FLUSH */
	"misslyckande i laagnivas soekfunktion",	/* QP_E_CANT_SEEK */
	"misslyckande i laagnivas staengfunktion",	/* QP_E_CANT_CLOSE */
	"operation skulle blockera",		/* QP_E_NONBLOCK */
	"felaktigt argument",			/* QP_E_INVAL */
	"inget tillstaand foer stroem",		/* QP_E_PERMISSION */
	"spill i output-record",		/* QP_E_OVERFLOW */
	"stroem aer felaktig eller ej registrerad",	/* QP_E_BAD_STREAM */
	"stroembuffert aer ej tom",		/* QP_E_BUFFERED */
	"inget filnamn specificerat",		/* QP_E_FILENAME */
	"fil aer en katalog",			/* QP_E_DIRECTORY */
	"felaktig input/output-mod",		/* QP_E_BAD_MODE */
	"felaktigt format",			/* QP_E_BAD_FORMAT */
	"felaktig soektyp",			/* QP_E_SEEK_TYPE */
	"felaktig flushtyp",			/* QP_E_FLUSH_TYPE */
	"felaktig spilltyp",		/* QP_E_OV_TYPE */
	"felaktig record-storlek",			/* QP_E_REC_SIZE */
	"felaktig systemoeppningsval",		/* QP_E_SYS_OPTION */
	"ej tillraeckligt med minne",			/* QP_E_NOMEM */
	"stroemtabell aer full",			/* QP_E_MFILE */
	"%s ej foeljt av sparat tillstaand",	/* QP_E_CMDSS */
	"%s ej foeljt av kommandostraengsargument", /* QP_E_CMDCS */
	"%s ej foeljt av spaarningsflaggargument",	/* QP_E_CMDTF */
	"mer aen ett %s val",			/* QP_E_OPTIONS */
	"%s och %s val aer ofoerenliga",		/* QP_E_CMDOI */
	"okaent Prologval: %s",			/* QP_E_CMDUO */
	"ej tillraeckligt med utrymme foer stignamn",		/* QP_E_CMDNSPN */
	"ej tillraeckligt med utrymme foer prologkommando",		/* QP_E_CMDNSPC */
	"putenv misslyckades",				/* QP_E_CMDPF */
	"foer maanga emacsargument",			/* QP_E_CMDTMEA */
	"Laddar %s med %s ...",			/* QP_I_CMDELOAD */
	"kunde ej exec %s",				/* QP_E_CMDEE */
	"%s ej qsetpath-ad",				/* QP_E_CMDNQSP */
	"ej toppnivaa",					/* QP_E_NO_TOP_LEVEL */
	"Prologavbrott (h foer hjaelp)? ",	     /* QP_I_INTERRUPT_PROMPT */
						/* QP_I_INTERRUPT_HELP_1 */
	"\n\
Prologavbrottsval:\n\
  h  hjaelp       - denna meny\n\
  c  fortsaett    - goer inget\n",		/* QP_I_INTERRUPT_HELP_2 */
    "\
  d  avlusa       - avlusaren boerjar skutta\n\
  t  spaara       - avlusaren boerjar krypa\n", /* QP_I_INTERRUPT_HELP_3 */
    "\
  a  avbryt       - avbryt aktuell brytnivaa\n\
  q  verkligen avbryt - abryt till toppnivaa\n\
  e  avsluta      - avsluta Prologkoerning\n",
	"okaent fel",			     /* QP_END_ECODE */
    };
