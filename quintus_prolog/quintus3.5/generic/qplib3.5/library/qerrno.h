/*  File   : qerrno.h
    Author : Richard A. O'Keefe
    SCCS   : @(#)88/11/02 qerrno.h	27.3
    Purpose: Define error codes specific to Quintus Prolog

    The point of this is that there are errors which we want to report
    through library(errno) which do not have any standard assignment
    among the UNIX errnos.  These numbers were original 99-x, but as
    UNIX gets bigger (SunOS 4.0, System V.3) the UNIX numbers were
    getting dangerously close, so now they are 999-x.
*/

#define	EUNIMP   996	/* Operation not implemented */
#define	ENOTARCH 997	/* Archive not in ar(5) format */
#define	ENOTMEMB 998	/* Member not present in archive */
#define	EUNKVAR  999	/* $variable not defined in environment */

