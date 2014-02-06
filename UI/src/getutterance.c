#define MAXINPUT 1024

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "tcp.h"

typedef char Sentence[200];

/* Get_Utterance */
/*added by Darsana to connect to Alfred*/
int connect_alfred(char *ServerFile) {
    int Port, Service;
    char *Host;
   
    Service = tcp_listen(ServerFile, &Port, &Host);
    if (Service == -1) 
	fprintf(stderr, "Error in creating a channel.\n");

    return Service;
}

void print_usage(char *str) {
    fprintf(stderr, 
	    "Usage: %s [-alma alma_host_file]\n", str);
    exit(-1);
}

int fget_input_string(char *input_string, FILE *in, FILE *out) 
{
  fprintf(out, ">>>>>> ");
  fflush(out);
  if (fgets(input_string, MAXINPUT, in)) 
    return 1;
  else 
    return 0;
}


int main(int argc, char * argv[]) 
{
  char 	 *sfile = NULL;
  int             PassiveSocket = -1;
  int 	          FD = -1;
  Sentence        input_string, spelling;
  Sentence        alma_str;
  int             i, SentNum = 0;

  for (i=0; i<argc; i++) {
    if (strcmp("-alma", argv[i])==0) {
      if ((sfile != NULL) || (i+1 == argc))
	print_usage(argv[0]);
      sfile = argv[i+1];
      i++;
    }
  }
  if (sfile == NULL) 
    fprintf(stderr, "No alma host file specified.\n");
  else
    PassiveSocket = connect_alfred(sfile);
  /* Darsana added Code here to get Alma tag once Alma has started up */
  if (PassiveSocket != -1) {
    switch (tcp_select(tcp_BLOCK, 0.0, &FD)) {
    case tcp_ERROR:
      exit(errno);
    case tcp_SUCCESS:
      if (FD == PassiveSocket) {
	if((FD = tcp_accept(PassiveSocket)) == -1) exit(errno);
	printf("Connection to %d accepted\n", FD);
      }
    }
  }

  while (fget_input_string(input_string, stdin, stdout)) 
    {
      if ((strcmp(input_string, "quit\n")==0) ||
	  (strcmp(input_string, "exit\n")==0)) {
	/* Darsana added code here to send quit/exit command to alfred*/
	sprintf(alma_str, "%s", "term(quit).");
	/*	printf("%s", alma_str);*/
	if (FD != -1) write(FD, alma_str, strlen(alma_str));
	break;
      }

      /*darsana added code to send parse to alfred*/  
      SentNum++;
      sprintf(alma_str, "%s%d%s\n", "term(af(isa(s", SentNum, ", new_utterance))).");
      printf("%s", alma_str);
      if (FD != -1) write(FD, alma_str, strlen(alma_str));
      if (input_string[strlen(input_string)-1] == '\n')
	input_string[strlen(input_string)-1] = '\0';
      sprintf(spelling, "%s%d%s\"%s\"%s\n",
	    "term(af(has(s",SentNum, ", ascii_string, ", input_string, "))).");
      printf("%s", spelling);
      if (FD != -1) write(FD, spelling, strlen(spelling));
    }
  return 0;
}

