#include "tcp.h"
#include <stdio.h>
#include <stdlib.h>     /* for atoi() and exit() */
#include <errno.h>

int main(int argc, char *argv[])
{
  int port, service, clntSock;
  char *host;

  service = tcp_listen(argv[1], &port, &host);

  if(service == -1){
    perror("service failed");
    exit(1);
  }

  for(;;){
    clntSock = tcp_accept(service);
    HandleTCPClient(clntSock);
    if(send(clntSock, "testing string", 14, 0) != 14){
      perror("send failed");
      exit(1);
    }
    close(clntSock);
  }
  
  return 0;
}
