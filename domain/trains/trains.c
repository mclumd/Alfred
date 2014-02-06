#include "/fs/erewhon/anhan/quintus_prolog/quintus3.5/generic/qplib3.5/IPC/TCP/tcp.h"
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "myX.h"

/* eek() is a crude little error handler */

#define MAXINP 2048

const char *TRAINS[] = {"Metroliner", "Bullet", "Northstar"};
const char *CITIES[] = {"Baltimore", "Buffalo", "Richmond", "Pittsburgh", "Washington", "Newark", "Atlanta"};

#define NUM_TRAINS (sizeof(TRAINS)/sizeof(TRAINS[0]))
#define NUM_CITIES (sizeof(CITIES)/sizeof(CITIES[0]))

int position[NUM_TRAINS];

void eek(s)
char *s;
{
    perror(s);
    exit(errno);
}

int findindex(char *ptr, char *infoarray[MAXINP], int num) {
  int i;

  for (i=0; i <num; i++) {
    if (!strcmp(ptr,infoarray[i]))
      return i;
  }
  return -1;
}

void showtrain(char *ptr, int n, myXwin *window) {
  char bufcpy[MAXINP];
  char city[MAXINP];
  char *tmp;
  int train,k,j, jval;

  strncpy(bufcpy, ptr, n);
  bufcpy[n] = '\0';
  /*  printf("%s\n", bufcpy);*/

  tmp = strtok(bufcpy, " ,[]\n");
  while (tmp != NULL){
    
    j = findindex(tmp, CITIES, NUM_CITIES);
    if (j>=0) {
      jval = j;
      strcpy(city,tmp);
    }
    else {
      k = findindex(tmp, TRAINS, NUM_TRAINS);
      if (k >= 0) {
	train = k + 1; 
      }
    }
    tmp = strtok(NULL, " ,[]\n");
  }
  position[train-1] = jval;
  myXclear(window);
  myXsetcolor(window, train);
  myXline(window, .1,.2,.8,.2);
  myXdrawto(window, .8, .52);
  myXdrawto(window, .77, .52);
  myXdrawto(window, .77, .45);
  myXdrawto(window, .75, .45);
  myXdrawto(window, .75, .48);      
  myXdrawto(window, .72, .48);
  myXdrawto(window, .72, .4);
  myXdrawto(window, .1, .4);
  myXdrawto(window, .1, .2);
  myXprint(window,0.4,0.6,city);
}


void findtrain(char *ptr, int n, int FD) {
  char bufcpy[MAXINP];
  char alma_str[MAXINP];

  char *tmp;
  int k, index;

  strncpy(bufcpy, ptr, n);
  bufcpy[n] = '\0';
  /*  printf("%s\n", bufcpy);*/

  tmp = strtok(bufcpy, " ,[]\n");
  while (tmp != NULL){
    k = findindex(tmp, TRAINS, NUM_TRAINS);
    if (k>=0) 
      tmp = NULL;
    else
      tmp = strtok(NULL, " ,[]\n");
  }
  index = position[k];
  sprintf(alma_str, "%s%s%s\n", "term(af(observation(location,'", CITIES[index], "'))).");
  write(FD, alma_str, strlen(alma_str));
}

main(argc, argv)
int argc;
char *argv[];
{
    int Port;
    char *TheHostName;
    int PassiveSocket;
    char buf[MAXINP];
    int FD;
    char *Host;
    int i;

    myXwin *window; /* Window to draw the trains */

    
    if (argc != 2) {
	printf("Usage: %s ServerFile\n", argv[0]);
	exit(1);
    }

    printf("Valid commands:\n");
    printf("[[send, train name, city name]]\n");
    printf("[undo, [send, train name, city name]]\n");
    
    printf("Valid cities: \n");
    for(i = 0; i < NUM_CITIES-1; i++)
      printf("%s,", CITIES[i]);
    printf("%s\n", CITIES[i]);
    
    printf("Valid trains: \n ");
    for(i = 0; i < NUM_TRAINS-1; i++) {
      printf("%s,", TRAINS[i]);
      position[i] = 0;
    }
    printf("%s\n", TRAINS[i]);
     
      /* if(tcp_create_listener(0, &Port, &Host, &PassiveSocket)) exit(errno);
	 if(tcp_address_to_file(argv[1], Port, Host)) exit(errno);*/
      /*  printf("Passive socket %d created on %s, port number %d\n",
	  PassiveSocket, Host, Port);*/
      PassiveSocket = tcp_listen(argv[1], &Port, &Host);
      if (PassiveSocket == -1) 
	fprintf(stderr, "Error in creating a channel.\n");


    window=myXopen("MyWindow",0.3,0.3,0.6,0.6);
    for (;;) {
	switch (tcp_select(tcp_BLOCK, 0.0, &FD)) {
	  case tcp_ERROR:
	    exit(errno);
	  case tcp_SUCCESS:
	    if (FD == PassiveSocket) {
		if((FD = tcp_accept(PassiveSocket)) == -1) exit(errno);
		printf("Connection to %d accepted\n", FD);
	    } else {
		int n;
		n = read(FD, buf, MAXINP);
		if (!strncmp(buf,"quit",n))
		  exit(1);
		switch (n) {
		  case -1:
		    eek("c_server.read");
		  case 0:
		    if (tcp_shutdown(FD) == -1)
			exit(errno);
		    break;
		  default:
		    if (write(1, buf, n) != n)
			eek("c_server.write");
		    else {
		      printf("\n");

		      if (!strncmp(buf,"[[send",6)) {
			showtrain(buf,n, window);
		      }
		      if (!strncmp(buf,"[[find",6)) {
			findtrain(buf,n,FD);
		      }
		    }
		}
	    }
	}
    }
    myXclose(window);
}



