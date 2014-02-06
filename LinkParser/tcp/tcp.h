
#include <sys/select.h>

#define tcp_ON 1
#define tcp_OFF 0

#define tcp_ERROR -1
#define tcp_TIMEOUT 0
#define tcp_SUCCESS 1

#define tcp_BLOCK 1
#define tcp_POLL 0

/* MAXHOST is how many bytes a hostname can be */
#define tcp_MAXHOST 34

int tcp_listen(char*, int*, char**);
int tcp_setmask(int, int);
int tcp_accept(int);
int tcp_select(int, double, int*);
int address_to_file(char*, char*, int);
int create_listener(int, int*, char**, int*);
int handle_timeouts(int, double*, int, int, fd_set*);
void DieWithError(char*);
void HandleTCPClient(int);
