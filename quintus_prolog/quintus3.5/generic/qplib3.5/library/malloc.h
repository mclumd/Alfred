/*  File   : malloc.h
    Author : Richard A. O'Keefe
    SCCS   : @(#)90/12/07 malloc.h	60.1
    Purpose: Header file for type casting malloc call

*/

#ifdef	lint
#define	Malloc(Type,Size)	((void)QP_malloc((unsigned)(Size)), (Type)0)
#else	/*real*/
#define	Malloc(Type,Size) 	(Type)QP_malloc(Size)
#endif	/*lint*/

#define	Free(Pointer)     	QP_free((char *)(Pointer))
