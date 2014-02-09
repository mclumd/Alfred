/*  File   : 12/10/98 @(#)tcp.c	76.2
    Author : Tom Howland
    Defines: various calls to the operating system supporting tcp.pl
    SeeAlso: tcp.pl, man select, man tcp
  
    Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

    This is IPC/TCP/tcp.c
*/

/*
  Per Mildner [PM] April 2000
  See inputservices.c for more comments.

  The WIN32 code never worked. At all. Amazing.

  No way this code is going to work anywhere int is different from
  long int. In particular +integer is assumed to be int as opposed to
  the documentation which says long int.
  
 */

#ifndef	lint
static char *SCCS_ID = "@(#)tcp.c	76.2 12/10/98 Copyright (C) 1990 Quintus";
#endif

#include <fcntl.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#ifdef WIN32
#include <winsock.h>
#include <sys/timeb.h>
#else  /* !WIN32 */
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>		/* [PD] 3.5 */
#include <netdb.h>
#include <unistd.h>             /* [PM] 3.5 close */
#endif /* !WIN32 */

/* [PM] 3.5 no longer defines RS6000 but instead AIX as for rest of QP source */
#if defined(RS6000) || defined(AIX)
#include <sys/select.h>
#endif

#ifdef PROLOG
#include "quintus.h"
#include "socketio.h"
#endif

#include "tcp.h"

#ifndef INVALID_SOCKET
#define INVALID_SOCKET -1
#endif

/*
 *  On NT, a socket descriptor is not represented by the UNIX style
 *  "small non-negative integer". Therefore the map array contains
 *  a mapping of socket descriptors to small integers.
 */

static struct {
    int		    width;
    int             startfd;
#if WIN32
    int             nfds;
    SOCKET          smap[FD_SETSIZE];
#endif
    int             fds[FD_SETSIZE];
    int		    altered;

#ifdef PROLOG

    struct socket_input_stream * stream[FD_SETSIZE];
    QP_atom last_error_msg;
    int last_error_number;
    QP_pred_ref timer_callback, input_callback;

#endif

} tcp;

#ifdef WIN32

#define	close(s)	closesocket(s)

struct timezone {
	int tz_minuteswest;
	int tz_dsttime;
};

int
gettimeofday(struct timeval *tp, struct timezone *tzp)
{
	struct	timeb	tb;

	ftime(&tb);

	tp->tv_sec = tb.time;
	tp->tv_usec = tb.millitm * 1000;
        if (tzp)                /* [PM] April 2000 (QPRM 138) This is
                                   NULL when called from
                                   inputservices.c. So, did no-one
                                   test this on WIN32? */ 
          {
            tzp->tz_dsttime = tb.dstflag;
            tzp->tz_minuteswest = tb.timezone;
          }
	return 0;
}

static void
tcp_cleanup(void)
{
	WSACleanup();
}

static int
tcp_initialized(void)
{
	static int initialized;
	WORD version;
	WSADATA data;

	if (!initialized)
	{	version = MAKEWORD(1,1);
		if (WSAStartup(version, &data) != 0)
			return 0;

		atexit(tcp_cleanup); /* [PM] What happens if this DLL
                                        is unloaded before exit? */
#ifdef PROLOG
		/* allow interrupts */
		QP_pc_safe_module("tcp.dll", "QP_select");
#endif
		initialized = 1;
	}

	return 1;
}

/* [PM] April 2000 errno is not set by winsock */
int tcp_errno(void)
{
  int rc = WSAGetLastError();
  return rc;
}


/* [PM] April 2000 Call this early in any procedure that calls
   report_error to ensure that no lingering error numbers is used
*/
static void tcp_clear_errno(void)
{
  WSASetLastError(0);
  errno = 0;
}

#if 0
#define TCP_EINTR WSAEINTR
#define TCP_SOCKET SOCKET       /* [PM] April 2000 Mainly as
                                   documentation */
#endif

int
map_socket_to_fd(SOCKET socket)
{
	int 	i;

	for (i=0; i<tcp.nfds; i++)
		if (tcp.smap[i] == socket)
			return i;

	tcp.smap[i] = socket;
	tcp.nfds++;
	return i;
}

/* called from inputservices.c */
SOCKET map_fd_to_socket(int fd)
{
  return tcp.smap[fd];
}

#define map_fd_to_socket(fd)		tcp.smap[fd]


#else /* i.e., #if !defined(WIN32) */

#define	tcp_initialized()		1
#if 0                           /* [PM] April 2000 moved to tcp.h */
#define	map_socket_to_fd(s)		s
#define	map_fd_to_socket(fd)		fd
#endif

/* [PM] April 2000 */

#if 0
#define tcp_errno() errno
#endif
#define tcp_clear_errno() (errno = 0)
#if 0
#define TCP_EINTR EINTR
#define TCP_SOCKET int
#endif 
#endif

#ifdef PROLOG

/* error handling */

static void report_error(s)
    char *s;
{
    if(tcp.last_error_number == 0){
        int os_err = errno;
        int tcp_err = tcp_errno();
        
        /* [PM] April 2000 Used to read only errno but that misses WinSock errors */
	tcp.last_error_number = (tcp_err ? tcp_err : os_err);
	tcp.last_error_msg = QP_atom_from_string(s);
    }
}

long int                        /* [PM] Added return type */
tcp_fetch_error(msg)
   QP_atom *msg;
{
    int n;

    *msg = tcp.last_error_msg;
    n = tcp.last_error_number;
    tcp.last_error_number = 0;
    return n;
}

/* add Seconds to absolute time. */

void tcp_time_plus(is, iu, d, os, ou)
    long is, iu, *os, *ou;	/* input time, output time */
    double d;			/* delta time in seconds */
{
    register double x;
    register long s;
    register long u;

    x = d + is + iu / 1.0e6;
    s = (long) x;
    u = (long) ((x - s) * 1.0e6 + 0.5);
    if(u == 1000000) {
	*os = ++s;
	*ou = 0;
    } else {
	*os = s;
	*ou = u;
    }
}

/* return the current time. */

void tcp_now(S, U)
    long *S, *U;
{

    struct timeval  t;
    struct timezone tz;
    
    tcp_clear_errno();
    if (gettimeofday(&t, &tz))
	report_error("tcp_now.gettimeofday");

    *U = t.tv_usec;
    *S = t.tv_sec;
}

void tcp_check_stream(Socket,u)
    TCP_SOCKET  Socket;
    struct socket_input_stream *u;
{
    tcp.stream[ map_socket_to_fd(Socket) ] = u;
}

static void tcp_timer_callback(dummy, cookie)
    long dummy, cookie;
{
    (void) QP_query(tcp.timer_callback, cookie);
}

long int                        /* [PM] 3.5 was missing return type */
tcp_create_timer_callback(s, u, cookie, timer_id)
    long int s, u;
    long int *cookie, *timer_id;
{
    double milliseconds;
    long ns, nu;
    int status;

    static long count;

    tcp_clear_errno();
    if(tcp.timer_callback == (QP_pred_ref) 0) {
	tcp.timer_callback = QP_predicate("timer_callback", 1, "tcp");
	if (tcp.timer_callback == QP_BAD_PREDREF) {
	    report_error("tcp_timer_callback() could not find tcp:timer_callback/1"); /* [PM] was /0 */
	    tcp.timer_callback = (QP_pred_ref) 0;
	    return -1;
	}
    }
    tcp_now(&ns, &nu);
    milliseconds = 1000.0 * (s - ns) + 0.001 * (u - nu) + 0.5;
    status = QP_add_timer((int) milliseconds, tcp_timer_callback,
			  (char *) count);
    if(status == QP_ERROR) {
	report_error("tcp_create_timer_callback.QP_add_timer");
	return -1;
    }
    *timer_id = status;
    *cookie = count++;
    return 0;
}

static void tcp_input_callback(Socket)
    TCP_SOCKET Socket;
{
  /* [PM] April 2000 Coerce arg to ensure it matches extern declaration in tcp.pl */
    (void) QP_query(tcp.input_callback, (long) Socket);
}    

static void tcp_input_check_buffer(Socket, stream)
     TCP_SOCKET Socket;
    QP_stream *stream;
{
#if 0                           /* [PM] 3.5 unused */
    struct socket_input_stream *sock_stream
	= (struct socket_input_stream *) stream;
#endif /* unused */
    while (stream->n_char > 0)
	tcp_input_callback(Socket);
}

long int /* [PM] Added return type */
tcp_create_input_callback(Socket, stream)
    TCP_SOCKET Socket;
    QP_stream *stream;
{
    tcp_clear_errno();
    if (tcp.input_callback == (QP_pred_ref) 0) {
	tcp.input_callback = QP_predicate("input_callback", 1, "tcp");
	if (tcp.input_callback == QP_BAD_PREDREF) {
	    tcp.input_callback = (QP_pred_ref) 0;
	    report_error("tcp_create_input_callback() could not find tcp:input_callback/1");
	    return -1;
	}
    }

    (void) QP_add_input(Socket, tcp_input_callback, NULL,
			tcp_input_check_buffer, (char *) stream);
    return tcp_setmask(Socket, tcp_OFF);
}

void tcp_destroy_input_callback(fd)
    int fd;
{
    (void) QP_remove_input(fd);
    (void) tcp_setmask(fd, tcp_ON);
}

QP_atom tcp_current_mask(Socket)
    int Socket;
{
    static int first = 1;
    static QP_atom on, off;

    if(first) {
	first = 0;
	on = QP_atom_from_string("on");
	off = QP_atom_from_string("off");
        /* [PM] April 2000 Added registration */
        (void) QP_register_atom(on);
        (void) QP_register_atom(off);
    }

    if (tcp.fds[ map_socket_to_fd(Socket) ])
		return on;

    return off;
}

#else /* i.e., ,#elif !defined(PROLOG) */

#define report_error(s) perror(s)

#endif  /* PROLOG */

/* Given a ServerFile, tcp_address_from_file() returns the Port and
Host that was written there by tcp_listen().  It returns 0 if
successful. */

long int tcp_address_from_file(ServerFile,Port,Host)
    char *ServerFile;
    int *Port;
    char **Host;
{
    long int r;
    FILE *h;
    static char hostname[tcp_MAXHOST];

    tcp_clear_errno();
    if ((h = fopen(ServerFile, "r")) == NULL){
	report_error("tcp_address_from_file.fopen");
	return -1;
    }
    if(fscanf(h, "port %d\nhost %s\n", Port, hostname) == 2) r = 0;
    else {
	r = -1;
	report_error("tcp_address_from_file.fscanf");
    }
    (void) fclose(h);
    *Host = hostname;
    return r;
}

/* Given a remote Host1 and ServerFile, tcp_address_from_shell()
returns the Port and Host that was written there by tcp_listen().  It
returns 0 if successful. */

long int tcp_address_from_shell(Host1,UserId,ServerFile,Port,Host)
    char *Host1;
    char *UserId;
    char *ServerFile;
    int *Port;
    char **Host;
{

    tcp_clear_errno();              /* [PM] Also before WIN32 barf */
#ifdef WIN32
    report_error("tcp_address_from_shell.popen");
    return -1;
#else
    {
      long int r;
      FILE *stream;
      char Command[512];
      char user_spec[512];
      static char hostname[tcp_MAXHOST];

    if(strlen(UserId)) (void) sprintf(user_spec,"-l %s",UserId);
    else user_spec[0] = 0;
    (void) sprintf(Command, "rsh %s -n %s cat %s", Host1, user_spec,
		   ServerFile);
    if ((stream = popen(Command, "r"))) {
      ;
    } else {
	report_error("tcp_address_from_shell.popen");
	return -1;
    }
    if(fscanf(stream,"port %d\nhost %s\n,", Port, hostname) == 2) r = 0;
    else {
	r = -1;
	report_error("tcp_address_from_shell.fscanf");
    }
    (void) pclose(stream);
    *Host=hostname;
    return r;
    }
#endif
}

/* tcp_setmask updates the fd_set's used in tcp_select. */

long int tcp_setmask(Socket, On)
     TCP_SOCKET Socket;
    long int        On;
{
    int fd;
    int i;

    tcp_clear_errno();

    /* [PM] April 2000
       tcp_watch_user does setmask on fd zero.
       1. This is not right even on Unix since fd zero is stdin which
          can be different from user_input.
       2. On Windows select cannot be used to watch anything but
          sockets.
       3. However, on windows it is possible to read from both file
          handles and socket handles with the same IO routines. This
          together with the fact that on Windows (as on Unix) the file
          handles for stdin, stdout and stderr are predefined as 0, 1,
          and 2 makes it impossible for a socket handle to have value
          0..2. Thus if Socket is 0 we can safely barf. We could check 
          for a Socket value of 1 and 2 as well, but this should be
          done together with some more systematic range check.

     */
#ifdef WIN32
    if (Socket == 0)
      {
        report_error("tcp_setmask tcp_watch_user unsupported on Win32");
        return -1;
      }
#endif

    
    fd = map_socket_to_fd(Socket);

    if (On) {
#ifdef SIGPIPE
	static int ignore_sigpipe = 1;

	if(ignore_sigpipe) {

	    typedef void (*sigfunc)();
	    sigfunc old_sigpipe_handler;

	    old_sigpipe_handler = signal(SIGPIPE, SIG_IGN);
	    if(old_sigpipe_handler == SIG_ERR) {
		report_error("tcp_setmask.signal1");
		return -1;
	    }
	    ignore_sigpipe = 0;
	}
#endif

	tcp.fds[fd] = 1;

	if (fd >= tcp.width)
	    tcp.width = fd + 1;

    } else {

	tcp.fds[fd] = 0;

	if (fd + 1 == tcp.width) {	
		for (i = fd - 1; i != -1 && tcp.fds[i] == 0; i--)
			;
		if (tcp.startfd > i)
			tcp.startfd = 0;
		tcp.width = i + 1;
	}
    }

    /* if this was reached from a callback, make sure tcp_select() knows. */
    tcp.altered = 1;

    return 0;
}

#ifndef PROLOG
#define QP_select select
/* Return values defined by select */
#define SELECT_TIMEOUT 0
#define SELECT_FAILURE -1
#define SELECT_INTERRUPTED -3
#else
/* Return values defined by QP_select */ 
#define SELECT_TIMEOUT QP_SUCCESS
#define SELECT_FAILURE QP_ERROR
#define SELECT_INTERRUPTED -3
#endif

static int handle_timeouts(Block, Timeout, w, poll, readfds)
    long int Block;
    double *Timeout;
    int w, poll;
    fd_set *readfds;
{
    struct timeval timeout, entry_time, *timeoutp;
    struct timezone tz;
    int r;
    double Timeout0;

    if(!Block) (void) gettimeofday(&entry_time, &tz);
    Timeout0 = *Timeout;

    if (poll || (!Block && Timeout0 <= 0.0)) { /* [PM] 3.5 added () around && to avoid gcc warning */
	timeoutp = &timeout;
	timerclear(&timeout);
    } else if (Block) {
	timeoutp = 0;
    } else {
	long x;

	timeoutp = &timeout;
	timeout.tv_sec = x = (long) Timeout0;
	timeout.tv_usec = (long) (0.5 + ((Timeout0 - x) * 1e6));
    }

    r = QP_select(w, readfds, 0, 0, timeoutp);

    /* As of delta 67.1 QP_select() will not return with SELECT_FAILURE
       and errno EINTR. But when it is fixed to do that we should
       check for it here */
    if (tcp.altered || (r ==  SELECT_FAILURE && tcp_errno() == TCP_EINTR)) { /* [PM] 3.5 added () around && to avoid gcc warning */
	if(!Block){
	    struct timeval  t;
	    
	    (void) gettimeofday(&t, &tz);
	    *Timeout = Timeout0 - t.tv_sec + entry_time.tv_sec -
		(t.tv_usec - entry_time.tv_usec) / 1e6;
	}
	tcp.altered = 1;
	return SELECT_INTERRUPTED;
    } else {
	return r;
    }
}

/* tcp_select(Block, Timeout, selectedfd)

determine the ready file descriptors in a round-robin fashion.

return value is

   tcp_ERROR
   tcp_TIMEOUT
   tcp_SUCCESS data available

*selectedfd is the file descriptor that has input data available. */

long int tcp_select(Block, Timeout, selectedfd)
    long int Block;
    double Timeout;
    long int *selectedfd;       /* Really TCP_SOCKET* */
{
    long int fd;
    long int w, poll;
    long int start = 0;         /* [PM] 3.5 init to avoid gcc warning (see discussion below) */
#ifdef PROLOG
    long int ready = 0;         /* [PM] 3.5 init to avoid gcc warning (it will in fact always be initied before use) */
#endif /* PROLOG */
    fd_set readfds;	/* indicates which fd's have input available */

    tcp_clear_errno();

    FD_ZERO(&readfds);

    do {
	tcp.altered = 0;
	poll = 0;

	if((w = tcp.width) > 0) {
	    fd = start = tcp.startfd;
	    do {
		 if (tcp.fds[fd]) {
#ifdef PROLOG
		    if(!poll) {

			/* check for any unconsumed characters on
			   the individual streams. */

			register struct socket_input_stream * s;

			s = tcp.stream[fd];

			if(s && (s->qpinfo.n_char > 0)) {
			    poll = 1;
			    ready = fd;
			}
		    }
#endif /* PROLOG */
		    FD_SET(map_fd_to_socket(fd) , &readfds);
		}

		++fd;
		fd %= w;
	    } while (fd != start);
	}
	
	switch(handle_timeouts(Block, &Timeout, w, poll, &readfds)) {

	  case SELECT_TIMEOUT:
	    if(!poll) return tcp_TIMEOUT;
	    break;

	  case SELECT_FAILURE:
	    report_error("tcp_select");
	    return tcp_ERROR;
	}
    } while(tcp.altered);

#ifdef PROLOG
    /* [PM] 3.5 Note that ready is always inited if poll is true */
    if(poll) FD_SET(map_fd_to_socket(ready), &readfds);
#endif /* PROLOG */
    /* [PM] 3.5 gcc complains that start can be uninited here (i.e., if tcp.width <= 0).
       However, in that case readfds ought to be empty so the
       following would loop indefinitely anyway.

       Examination of handle_timeouts indicates that if tcp.width is
       zero then select(), and thus QP_select() ought to return an
       error or zero which happens to be the same as SELECT_TIMEOUT
       and if tcp.width is zero then poll is zero as well leading to a
       return of tcp_TIMEOUT if select() does not give an error. So in
       either case, if tcp.width is zero we never get here. For this
       reason I init start above to avoid the gcc warning.

     */
    for (fd=start; !FD_ISSET(map_fd_to_socket(fd), &readfds); fd = (fd+1) % w)
	;

    *selectedfd = map_fd_to_socket(fd);
    tcp.startfd = ++fd % w;
    return tcp_SUCCESS;
}

/* tcp_shutdown is called whenever prolog closes an input stream to a socket.
It is also called directly to kill the server socket */

long int tcp_shutdown(s)
    int          s;
{
    int             q, r;
    TCP_SOCKET Socket = (TCP_SOCKET) s;

    tcp_clear_errno();

    r = 0;

    q = tcp_setmask(Socket, tcp_OFF);
    if(q) r = -1;

    q = close(Socket);
    if (q && !r) {
	report_error("tcp_shutdown.close");
	r = -1;
    }

#ifdef PROLOG
    /* [PM] April 2000 added map_socket_to_fd */
    tcp.stream[map_socket_to_fd(Socket)] = CoerceSocketInputStream(0);
#endif

    return r;
}

/* connect to some server */

long int /* really TCP_SOCKET */tcp_connect(HostName, Port)
    char           *HostName;
    int             Port;
{
    TCP_SOCKET     connection;
    struct hostent *hp;
    struct sockaddr_in sin;
    char emsg[99];

    if (!tcp_initialized())
	return -1;

    tcp_clear_errno();


    /* given the simple host name, get the internal host identification */

    hp = gethostbyname(HostName);

    if (hp == NULL) {
	sprintf(emsg,"tcp_connect.gethostbyname host(%s), port(%d)",
	    HostName, Port);
	report_error(emsg);
	return -1;
    }

    /* get a socket */

    connection = socket(AF_INET, SOCK_STREAM, 0);
    if (connection == INVALID_SOCKET) {
	sprintf(emsg,"tcp_connect.socket host(%s), port(%d)",
	    HostName, Port);
	report_error(emsg);
	return -1;
    }

    /* fill in the name structure */

    memset((char *) &sin, 0, sizeof(sin));
    memcpy((char *) &sin.sin_addr, hp->h_addr, hp->h_length);
    sin.sin_family = hp->h_addrtype;
    sin.sin_port = htons((u_short) Port);

    /* connect to the server */

    if (connect(connection, (struct sockaddr *) & sin, sizeof(sin))) {
	sprintf(emsg,"tcp_connect.connect host(%s), port(%d)",
	    HostName, Port);
	report_error(emsg);
	(void) shutdown(connection, 2);
	(void) close(connection);
	return -1;
    }

    if(tcp_setmask(connection, tcp_ON)) {
	(void) shutdown(connection, 2);
	(void) close(connection);
	return -1;
    }

    return connection;
}

/* accept a connection request. */

long int /* really TCP_SOCKET */ tcp_accept(s)
    int             s;	/* +Service: integer */

{
    TCP_SOCKET Service = (TCP_SOCKET) s;
    TCP_SOCKET connection;	/* The new socket */
    struct sockaddr_in sin;	/* An Internet address record */
    int             sizeof_sin;	/* The sizeof sin */

    tcp_clear_errno();


    /* make a connection with some client; block until there is one */

    sizeof_sin = sizeof sin;
    do {
	connection =
	    accept(Service, (struct sockaddr *) & sin, &sizeof_sin);
    } while (connection == INVALID_SOCKET && tcp_errno() == TCP_EINTR);

    if (connection == INVALID_SOCKET) {
	report_error("tcp_accept");
	return -1;
    }

    if(tcp_setmask(connection, tcp_ON)) {
	(void) shutdown(connection, 2);
	(void) close(connection);
	return -1;
    }
	
    return connection;
}

/* create a socket on which the server can accept connections. */

long int tcp_create_listener(InPort, OutPort, Host, Service)
    register int InPort;
    int *OutPort;
    char **Host;
    int *Service; /* The new socket */
{
    struct sockaddr_in sin; /* An Internet address record */
    int sizeof_sin; /* The sizeof sin */
    register TCP_SOCKET service;

    static char HostName[tcp_MAXHOST];

    if (!tcp_initialized())
	return -1;

    tcp_clear_errno();

    /* get this machine's name */

    if(gethostname(HostName, tcp_MAXHOST)) {
	report_error("tcp_listen.gethostname");
	return -1;
    }

    /* create the initial socket */

    service = socket(AF_INET, SOCK_STREAM, 0);
    if (service == INVALID_SOCKET) {
	report_error("tcp_listen.socket");
	return -1;
    }

    /* make it go away quickly when we close it down */
    {
      int x = 1;
      if (setsockopt(service, SOL_SOCKET, SO_REUSEADDR, (char *) &x, (sizeof x))) {
	report_error("tcp_listen.REUSEADDR");
	return -1;
      }
    }
    {
      struct linger x = {0,0};
      if (setsockopt(service, SOL_SOCKET, SO_LINGER, (char *) &x, (sizeof x))) {
	report_error("tcp_listen.SO_LINGER");
	return -1;
      }
    }

    /* set up the name structure for the socket */

    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = INADDR_ANY;
    sin.sin_port = htons((u_short) InPort);
    sizeof_sin = sizeof sin;

    /* give the name */

    if (bind(service, (struct sockaddr *) &sin, sizeof_sin)) {
	report_error("tcp_listen.bind");
	(void) shutdown(service, 2);
	(void) close(service);
	return -1;
    }

    /* get the port number assigned */

    if (getsockname(service, (struct sockaddr *) &sin, &sizeof_sin)) {
	report_error("tcp_listen.getsockname");
	(void) shutdown(service, 2);
	(void) close(service);
	return -1;
    }

    /* initialize it so clients can request a connection */

    if (listen(service, SOMAXCONN)) {
	report_error("tcp_listen.listen");
	(void) shutdown(service, 2);
	(void) close(service);
	return -1;
    }

    if(tcp_setmask(service, tcp_ON)) {
	(void) shutdown(service, 2);
	(void) close(service);
	return -1;
    }

    *OutPort = ntohs(sin.sin_port);
    *Host = HostName;
    *Service = (int) service;
    return 0;
}

long int                        /* [PM] 3.5 was missing return type */
tcp_address_to_file(FileName, Port, Host)
    char *FileName, *Host;
    int Port;
{
    FILE *f;

    tcp_clear_errno();

    if((f = fopen(FileName, "w")) == NULL) {
	report_error("tcp_address_to_file.fopen");
	return -1;
    }

    if(fprintf(f,"port %d\nhost %s\nprocess %d\n",Port,Host,getpid()) == EOF){
	report_error("tcp_address_to_file.fprintf");
	(void) fclose(f);
	return -1;
    }

    if(fclose(f)){
	report_error("tcp_address_to_file.fclose");
	return -1;
    }

    return 0;
}

long int /* really TCP_SOCKET */ tcp_listen(ServerFile,Port,Host)
    char          *ServerFile;
    int *Port;
    char **Host;
{
    TCP_SOCKET Service;

    if(tcp_create_listener(0, Port, Host, &Service)) return -1;

    if(tcp_address_to_file(ServerFile, *Port, *Host)){
	(void) tcp_shutdown(Service);
	return -1;
    }

    return (long int) Service;
}

/* [PM] 3.5 int is what the rest of this file (incorrectly) uses. FIXME: Need HAVE_SOCKLEN_T in config.h */
#if HAVE_SOCKLEN_T              /* [PM] 3.5 always false, FIXME:
                                   should be set in config.h and 'int'
                                   should be replaced with
                                   qp_socklen_t as appropriate
                                   above. */
#define qp_socklen_t socklen_t
#else  /* !HAVE_SOCKLEN_T */
#define qp_socklen_t int
#endif  /* !HAVE_SOCKLEN_T */

/* [PD] 3.5 interface to getpeername() */

void tcp_get_socket_address(Socket, Port, Host)
    long int Socket;		/* Really TCP_SOCKET */
    long int *Port;
    char **Host;
{
    struct sockaddr_in name;
    qp_socklen_t namelen = sizeof name;

    tcp_clear_errno();
    if (-1 == getpeername(Socket, (struct sockaddr *) &name, &namelen)) {
      report_error("tcp_get_socket_address.getpeername");
    } else {
      *Port = name.sin_port;
      *Host = inet_ntoa(name.sin_addr);
    }
}
