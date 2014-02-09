/*  File   : fcntl.h
    Author : David S. Warren
    Updated: 01/22/94
    SCCS:    @(#)94/01/22 fcntl.h	71.1
    Header : For portability between System V and 4.2BSD
*/

#ifdef	SYS5
#include <fcntl.h>
#else /*4BSD*/
#include <sys/file.h>
#endif/*SYS5*/

#ifndef	X_OK
#define	R_OK 4
#define	W_OK 2
#define	X_OK 1
#define	F_OK 0
#endif/*X_OK*/

#ifndef	STD_IN
#define	STD_IN	0
#define	STD_OUT 1
#define	STD_ERR 2
#endif/*STD_IN*/

#ifndef	SEEK_SET
#define	SEEK_SET 0
#define	SEEK_CUR 1
#define	SEEK_END 2
#endif/*SEEK_SET*/

#ifndef	MAXPATHNAME
#define	MAXPATHNAME 1024
#endif
