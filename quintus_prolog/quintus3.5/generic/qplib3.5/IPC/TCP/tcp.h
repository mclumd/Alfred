/*  File   : 06/29/98 @(#)tcp.h	76.1
    Purpose: Header file for the C interface to the tcp package.
    Author : Tom Howland
    Updated: 7/10/89
    SCCS   : @(#)89/07/10 tcp.h	1.2
    SeeAlso: 

    Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef tcp_ON

#define tcp_ON 1
#define tcp_OFF 0

#define tcp_ERROR -1
#define tcp_TIMEOUT 0
#define tcp_SUCCESS 1

#define tcp_BLOCK 1
#define tcp_POLL 0

long int
    tcp_accept(),
    tcp_connect(),
    tcp_listen(),
    tcp_listen_at_port(),
    tcp_select(),
    tcp_setmask(),
    tcp_shutdown(),
    tcp_address_from_file(),
    tcp_address_from_shell();

/* MAXHOST is how many bytes a hostname can be.  See QP #1301. */

#ifdef WIN32
# define tcp_MAXHOST 255
#else
# define tcp_MAXHOST 64
#endif

/* Per Mildner April 2000. See tcp.c and inputservice.c for details. */
#ifdef WIN32

extern int map_socket_to_fd(SOCKET socket);
extern SOCKET map_fd_to_socket(int fd);

/* [PM] April 2000 errno is not set by winsock */
extern int tcp_errno(void);

#if 0
/* [PM] April 2000 Call this early in any procedure that calls
   report_error to ensure that no lingering error numbers is used
*/
extern  void tcp_clear_errno(void)
#endif

#define TCP_EINTR WSAEINTR
#define TCP_SOCKET SOCKET       /* [PM] April 2000 Mainly as
                                   documentation */

#else /* i.e., #if !defined(WIN32) */

#define	map_socket_to_fd(s)		s
#define	map_fd_to_socket(fd)		fd

/* [PM] April 2000 */
#define tcp_errno() errno
#if 0
#define tcp_clear_errno() (errno = 0)
#endif

#define TCP_EINTR EINTR
#define TCP_SOCKET int

#endif



#endif
