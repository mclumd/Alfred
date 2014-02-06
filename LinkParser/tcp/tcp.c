/*Written with the help of
 * "TCP/IP Sockets in C: Practical Guide for Programmers" by Michael J. Donahoo and Kenneth L. Calvert
 */



#include <stdio.h> /* for printf() and fprintf() */ 
#include <sys/types.h> /* for Socket data types */ 
#include <sys/socket.h> /* for socket(), connect(), send(), and recv() */ 
#include <netinet/in.h> /* for IP Socket data types */ 
#include <arpa/inet.h> /* for sockaddr_in and inet_addr() */ 
#include <stdlib.h> /* for atoi() */ 
#include <string.h> /* for memset() */ 
#include <unistd.h> /* for close() */
#include <signal.h> /* for signals */
#include <sys/time.h>
/*#include <sys/select.h>*/
#include <errno.h>
#include "tcp.h"

#define RCVBUFSIZE 32   /* Size of receive buffer */
#define MAXPENDING 5    /* Maximum outstanding connection requests */

#define SELECT_TIMEOUT 0
#define SELECT_FAILURE -1
#define SELECT_INTERRUPTED -3


static struct {
    int             width;      /* used to limit search in tcp_select */
    int             startfd;
    int             fds[FD_SETSIZE];
    int             altered;
} tcp;


int tcp_listen(char *serverFile, int *port, char **host)
{
  int service;

  if(create_listener(0, port, host, &service))
    return -1;

  if(address_to_file(serverFile, *host, *port))
    {
      shutdown(service, 2);
      return -1;
    }

  return service;
}

int address_to_file(char *filename, char *host, int port){

  FILE *f;
  
  if((f = fopen(filename, "w")) == NULL) {
    DieWithError("fopen() failed");
    return -1;
  }
  
  if(fprintf(f,"port %d\nhost %s\nprocess %d\n",port,host,getpid()) == EOF){
    DieWithError("fprintf() failed");
    fclose(f);
    return -1;
  }
  
  if(fclose(f)){
    DieWithError("fclose() failed");
    return -1;
  }
  
  return 0;

}


/* create a socket for the sercer to accept connections on */
int create_listener(int inPort, int *outPort, char **host, int *service)
{
  struct sockaddr_in sin; /*internet address record*/
  int sizeof_sin;  /* the sizeof sin */
  int sock;

  static char hostname[tcp_MAXHOST];

  /*get machine's name*/

  if(gethostname(hostname, tcp_MAXHOST)){
    DieWithError("gethostname() failed");
    return -1;
  }

  /*create initial socket*/
  sock = socket(AF_INET, SOCK_STREAM, 0);
  if(sock == -1){
    DieWithError("socket() failed");
    return -1;
  }

  /* set up the name structure for the socket */

    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = INADDR_ANY;
    sin.sin_port = htons((u_short) inPort);
    sizeof_sin = sizeof sin;
    
    /* give the name */

    if (bind(sock, (struct sockaddr *) &sin, sizeof_sin)) {
        DieWithError("bind() failed");
        shutdown(sock, 2);
        close(sock);
        return -1;
    }
    
    
    /* get the port number assigned */

    if (getsockname(sock, (struct sockaddr *) &sin, (socklen_t *) &sizeof_sin)) {
        DieWithError("getsockname() failed");
        shutdown(sock, 2);
        close(sock);
        return -1;
    }

    /* initialize it so clients can request a connection */

    if (listen(sock, SOMAXCONN)) {
        DieWithError("listen() failed");
	shutdown(sock, 2);
        close(sock);
        return -1;
    }

    if(tcp_setmask(sock, tcp_ON)) {
        shutdown(sock, 2);
        close(sock);
        return -1;
    }

    *outPort = ntohs(sin.sin_port);
    *host = hostname;
    *service = sock;
    return 0;

}

/* tcp_setmask updates the fd_set's used in tcp_select. */

int tcp_setmask(int fd, int On)
{

    if (On) {

        static int ignore_sigpipe = 1;

        if(ignore_sigpipe) {

            typedef void (*sigfunc)();
            sigfunc old_sigpipe_handler;

            old_sigpipe_handler = signal(SIGPIPE, SIG_IGN);
            if(old_sigpipe_handler == SIG_ERR) {
                DieWithError("signal1() failed");
                return -1;
            }
            ignore_sigpipe = 0;
        }

        tcp.fds[fd] = 1;

        if (fd >= tcp.width)
            tcp.width = fd + 1;

    } else {

        tcp.fds[fd] = 0;

        if (fd + 1 == tcp.width) {
            register long int i;

            for (i = fd - 1; i != -1 && tcp.fds[i] == 0; i--);
            if (tcp.startfd > i)
                tcp.startfd = 0;
            tcp.width = i + 1;
        }
    }

    /* if this was reached from a callback, make sure tcp_select() knows. */
    tcp.altered = 1;

    return 0;
}



void DieWithError(char *errorMessage)    /* Error handling function */
{
  perror(errorMessage);
  
}


int handle_timeouts(int Block, double *Timeout, int w, int poll, fd_set* readfds)
{
    struct timeval timeout, entry_time, *timeoutp;
    struct timezone tz;
    int r;
    double Timeout0;

    if(!Block) 
      gettimeofday(&entry_time, &tz);
    Timeout0 = *Timeout;

    if (poll || !Block && Timeout0 <= 0.0) {
        timeoutp = &timeout;
        timerclear(&timeout);
    } else if (Block) {
        timeoutp = 0;
    } else {
        long x;

        timeoutp = &timeout;
        timeout.tv_sec = x = Timeout0;
        timeout.tv_usec = 0.5 + (Timeout0 - x) * 1e6;
    }

    r = select(w, readfds, 0, 0, timeoutp);

    /* As of delta 67.1 select() will not return with SELECT_FAILURE
       and errno EINTR. But when it is fixed to do that we should
       check for it here */
    if (tcp.altered || r ==  SELECT_FAILURE && errno == EINTR) {
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


int tcp_select(int Block, double Timeout, int *selectedfd)
{

    int fd, w, start, ready, poll;
    fd_set readfds;     /* indicates which fd's have input available */

    do {
        tcp.altered = 0;
        poll = 0;
        if(w = tcp.width) {
            start = tcp.startfd;
            fd = start;
            do {
                if (tcp.fds[fd]) {
                    FD_SET(fd, &readfds);
                } else FD_CLR(fd, &readfds);
                fd = ++fd % w;
            } while (fd != start);
        }

        switch(handle_timeouts(Block, &Timeout, w, poll, &readfds)) {

          case SELECT_TIMEOUT:
            if(!poll) return tcp_TIMEOUT;
            break;

          case SELECT_FAILURE:
            DieWithError("tcp_select() failed");
            return tcp_ERROR;
        }

   } while(tcp.altered);


    for(fd = start; ! FD_ISSET(fd, &readfds); fd = ++fd % w);
    *selectedfd = fd;
    tcp.startfd = ++fd % w;
    return tcp_SUCCESS;
}


int tcp_accept(int servSock)
{
  int clntSock;                    /* Socket descriptor for client */
  struct sockaddr_in echoClntAddr; /* Client address */
  unsigned int clntLen;            /* Length of client address data structure */

  /* Set the size of the in-out parameter */
  clntLen = sizeof(echoClntAddr);
    
  /* Wait for a client to connect */
  if ((clntSock = accept(servSock, (struct sockaddr *) &echoClntAddr, 
			 &clntLen)) < 0){
    DieWithError("accept() failed");
    return -1;
  }
  
  if(tcp_setmask(clntSock, tcp_ON)) {
    shutdown(clntSock, 2);
    close(clntSock);
    return -1;
  }

 
  
  return clntSock;
}

void HandleTCPClient(int clntSocket)
{
  char echoBuffer[RCVBUFSIZE];        /* Buffer for echo string */
  int recvMsgSize;                    /* Size of received message */

  /* Receive message from client */
  if ((recvMsgSize = recv(clntSocket, echoBuffer, RCVBUFSIZE, 0)) < 0){
    DieWithError("recv() failed");
    exit(1);
  }

  printf(echoBuffer);

  /* Send received string and receive again until end of transmission 
     while (recvMsgSize > 0)       zero indicates end of transmission 
     {
     Echo message back to client 
       if (send(clntSocket, echoBuffer, recvMsgSize, 0) != recvMsgSize){
	DieWithError("send() failed");
	exit(1);
	}
      
      See if there is more data to receive 
      if ((recvMsgSize = recv(clntSocket, echoBuffer, RCVBUFSIZE, 0)) < 0){
	DieWithError("recv() failed");
	exit(1);
	}
    } 
  */

  /*  close(clntSocket);     Close client socket*/ 
}



