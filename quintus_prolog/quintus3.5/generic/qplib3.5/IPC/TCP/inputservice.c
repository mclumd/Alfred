/*  SCCS   : @(#)input_service.c	75.2 09 May 1995
    File   : input_service.c
    Authors: Rowena Bruce
    Purpose: QP version of select, and related functions
    Origin : November 1990

        +--------------------------------------------------------+
        | WARNING: This material is CONFIDENTIAL and proprietary |
        |          to Quintus Computer Systems Inc.              |
        |                                                        |
        |  Copyright (C) 1990                                    |
        |  Quintus Computer Systems Inc.  All rights reserved.   |
        |                                                        |
        +--------------------------------------------------------+
*/

/* Per Mildner [PM] April 2000
   The socket code has several problems when used with WinSock & WIN32
   1. WinSock select barfs when called with a timeout but the fds are
      empty, i.e., select cannot be used as a process wait procedure.
      For this reason the non-emptiness of the fds is now checked on
      WIN32. (Refer to "The Lame list" item 2)

   2. On Win32 CTRL-C will not cause select (or other system calls) to
      return with EINTR. Even if select could be interrupted with
      CTRL-C select will not set errno but instead WSAGetLastError
      must be called. We wrap this in tcp_error() macro to do the
      right thing for other error codes.

      Since Ctrl-C will not interrupt select there is not much point
      in calling select with infinite timeout and empty fds. In these
      cases we just fake a time out (return zero).

   3. When the fds are empty and the timeout is finite we use Sleep()
      on WIN32. We should consider using SleepEx and to use
      QueueUserAPC to wake up at CTRL-C. Also consider the deprecated
      WSACancelBlockingCall.

   4. On WinSock select cannot be used to wait for activity on
      non-socket file descriptiors. For this reason I do not know how
      to implement tcp_watch_user() on WIN32. tcp_watch_user appears
      to be implemented by watching fd zero (i.e., stdin by
      convention). I suspect that stdin can be different from
      user_input, if so tcp_watch_user is broken on Unix too. On
      WinSock the argument to tcp_setmask is a WinSock SOCKET number
      not the faked "small non-negative integer" numbers used
      internally, for this reason tcp_watch_user is utterly broken on
      Win32. Luckily tcp_setmask et al. is not documented so it seems
      reasonable to check for the case when prolog calls it with a fd
      argument of zero (When tcp.c etc calls it with fd zero it might,
      concievably, be because WinSock actually returnes a fd with
      value zero).

   5. QP_select and friends are exported and documented for user
      written C code to use as well. This is unfortunate since it is
      documented as behaviing in a BSD style way which we cannot
      implement on WIN32.

    . What should be done is to redesign the QP/SP socket/tcp packages
      using asynchronous procedures wherever possible.

    There were bugs where the WinSock SOCKET ids are used instead of
    the faked "small non-negative integers" or vice versa. Hopefully
    I have squashed most of them.
    
*/



#include <stdio.h>
#include <sys/types.h>
#if HAVE_SELECT_H
#include <sys/select.h>
#endif
#ifdef WIN32                    /* [PM] Was #if WIN32 */
#include <winsock.h>
#else
#include <sys/time.h>
#endif
#include <errno.h>
#include "quintus.h"
#include "tcp.h"                /* [PM] April 2000 */


#ifdef WIN32
/* [PM] April 2000

   WinSock select barfs unless some of the fds are non-empty The
   non-WIN32 case used to be done for all platforms.  There are other
   problems, bugs and misfeatures with the tcp package on the WIN32
   (or rather, WinSock) platform.
*/
#define FDSET_NONEMPTY(FDSET) (((FDSET) != NULL) && ((FDSET)->fd_count > 0))
#endif /* WIN32 [PM] April 2000 */


#if !defined(FD_SET)
#define SIMPLE_FD_SET	1

# define FD_ZERO(fd_mask)	(*fd_mask = (fd_set) 0)
# define FD_SET(fd, fd_mask)	(*fd_mask = (1<<fd) | *fd_mask)
# define FD_CLR(fd, fd_mask)	(*fd_mask = (1<<fd) ^ *fd_mask)
# define FD_ISSET(fd, fd_mask)	((1<<fd) & *fd_mask)
typedef long fd_set;
/* need to defined FD_SETSIZE too */
#endif

#define MAX_DATA 255
#define INPUT_FD 0
#define OUTPUT_FD 1
#define EXCEPT_FD 2


typedef void (*func_type)();
typedef int (*test_func_type)();

typedef struct timer
{   int id;
    struct timeval *start;
    struct timeval *end;
    func_type call_function;
    char *call_data;
    struct timer *next_timer;
} timer_type;


typedef struct fd
{
    TCP_SOCKET id;              /* [PM] April 2000 Was int */
    int type;
    func_type call_function;
    char *call_data;
    func_type flush_function;
    char *flush_data;
    struct fd *last_fd;
    struct fd *next_fd;
} fd_type;

static fd_type *first_fd = NULL;
static fd_type *current_fd = NULL;
static timer_type *first_timer = NULL;
static int timer_count = 0;

static fd_set active_fds[3];
static fd_set inactive_fds[3];
static fd_set to_be_reactivated_fds[3];

/* alloc_timer

   tries to allocate space for a timer

   returns NULL if unable to allocate the space, a pointer to the space
   otherwise
*/

static timer_type *
alloc_timer(void)
{   timer_type *timer;

    timer = (timer_type *) QP_malloc(sizeof(timer_type));
    if (timer == NULL)
	return NULL;
    timer->start = (struct timeval *) QP_malloc(sizeof(struct timeval));
    timer->end = (struct timeval *) QP_malloc(sizeof(struct timeval));
    if ((timer->start == NULL) || (timer->end == NULL))
	return NULL;
    return timer;
}

/* free_timer(timer)

   frees the space pointed to by timer
*/

static void
free_timer(timer_type *timer)
{   QP_free(timer->start);
    QP_free(timer->end);
    QP_free(timer);
}


/* before (time1, time2
   returns 1 if time1 is before time2, 0 otherwise
*/

static int
before(struct timeval *time1, struct timeval *time2)
{   if (time1->tv_sec < time2->tv_sec)
	return 1;
    if ((time1->tv_sec == time2->tv_sec) && (time1->tv_usec < time2->tv_usec))
	return 1;
    return 0;
}

/* add_timeout_in_ms(start, timeout, end) 
   adds timeout (in ms) to time in start struct and puts result in end struct
*/

static void
add_timeout_in_ms(struct timeval *start, int timeout, struct timeval *end)
{   end->tv_sec = start->tv_sec + timeout / 1000;
    end->tv_usec = start->tv_usec + (timeout % 1000) * 1000;
    if (end->tv_usec > 1000000)
    {	end->tv_sec++;
	end->tv_usec -= 1000000;
    }
}

/* add_timeout(start, timeout, end) 
   adds time in timeout struct to time in start struct and puts result in end 
   struct 
*/

static void
add_timeout(struct timeval *start, struct timeval *timeout, struct timeval *end)
{   end->tv_sec = start->tv_sec + timeout->tv_sec;
    end->tv_usec = start->tv_usec + timeout->tv_usec;
    if (end->tv_usec > 1000000)
    {	end->tv_sec++;
	end->tv_usec -= 1000000;
    }
}

/* time_difference(time1, time2, time)
   if time1 is after time2,  
	calculates the difference between time1 struct and time2 struct and 
	stores result in time
   otherwise 
	initialises time struct to zero
*/

static void
time_difference(struct timeval *time1, struct timeval *time2, struct timeval *time)
{   if (before(time1, time2))
    {	time->tv_sec = 0;
	time->tv_usec = 0;
    }
    else
    {	time->tv_sec = time1->tv_sec - time2->tv_sec;
	time->tv_usec = time1->tv_usec - time2->tv_usec;
	if (time->tv_usec < 0)
	{   time->tv_sec = time->tv_sec - 1;
	    time->tv_usec = 1000000 + time->tv_usec;
	}
    }
}

/* time_difference_in_ms(end, start)
   returns the difference between end struct and start struct (may be 
   negative) 
*/

static unsigned long
time_difference_in_ms(struct timeval *end, struct timeval *start)
{   unsigned long result;

    result = (end->tv_sec - start->tv_sec) * 1000;
    result += (end->tv_usec - start->tv_usec) / 1000;
    return result;
}

/* add_timer(timer)
   inserts timer in queue
*/

static void
add_timer(timer_type *timer)
{   timer_type *t1, *t2;

    if (first_timer)
    {	if (before(timer->end, first_timer->end))
	{   timer->next_timer = first_timer;
	    first_timer = timer;
	    return;
	}
	for(t1 = first_timer, t2 = first_timer->next_timer; 
	    (t2 != NULL) && before(t2->end, timer->end);
	    t1 = t2, t2 = t1->next_timer );
	timer->next_timer = t2;
	t1->next_timer = timer;
    }
    else
    {	first_timer = timer;
	timer->next_timer = NULL;
    }
}
    

   
/*
 * int QP_add_timer(relative_time, function, call_data)
 *
 * Creates timer record for timer and adds timer record to set of registered 
 * timers. Timer times out after relative_time milliseconds.
 *
 * Returns QP_ERROR if unable to allocate space for timer record, 
 * id of timer otherwise
 */
int
QP_add_timer(int relative_time, func_type function, char *call_data)
{   struct timeval current_time;
    timer_type *timer;

    timer = alloc_timer();
    if (timer == NULL)
	return QP_ERROR;
    gettimeofday(&current_time, NULL);
    timer->id = ++timer_count;
    *timer->start = current_time;
    add_timeout_in_ms(&current_time, relative_time, timer->end);
    timer->call_function = function;
    timer->call_data = call_data;
    add_timer(timer);

    return timer->id;
}

/*
 * QP_add_absolute_timer(seconds, microseconds, function, call_data)
 *
 * Creates timer record for timer and adds timer record to set of registered 
 * timers. Timer times out at the time specified by seconds/microseconds
 * since Jan 1 1970.
 *
 * Returns QP_ERROR if unable to allocate space for timer record, 
 * id of timer otherwise
 */
int
QP_add_absolute_timer(struct timeval *end_time, func_type function, char *call_data)
{   struct timeval current_time;
    timer_type *timer;

    timer = alloc_timer();
    if (timer == NULL)
	return QP_ERROR;
    gettimeofday(&current_time, NULL);
    timer->id = ++timer_count;
    *timer->start = current_time;
    *timer->end = *end_time;
    timer->call_function = function;
    timer->call_data = call_data;
    add_timer(timer);

    return timer->id;
}

/*
 * QP_remove_timer(id)
 *
 * Attempts to remove timer with identity id from the list of registered timers.
 *
 * Returns QP_SUCCESS if it removes the timer, QP_ERROR if it cannot find the 
 * timer.
 */
int 
QP_remove_timer(int id)
{   timer_type *t1, *t2;

    if (first_timer == NULL)
	return QP_ERROR;
    t1 = first_timer;
    if (t1->id == id)
    {	first_timer = first_timer->next_timer;
	free_timer(t1);
	return QP_SUCCESS;
    }
    for(t2 = t1->next_timer; 
	    (t2 != NULL) && (t2->id != id);
	    t1 = t2, t2 = t1->next_timer );
    if (t2 == NULL)
	return QP_ERROR;
    t1->next_timer = t2->next_timer;
    free_timer(t2);

    return QP_SUCCESS;    
}


/* flush_inputs()

   for each active input, calls the flush function for the input (if one
   exists) 
*/

static void
flush_inputs(void)
{   fd_type *fd;

    for (fd = first_fd; fd != NULL; fd = fd->next_fd)
	if (fd->flush_function && FD_ISSET(fd->id, &active_fds[fd->type]))
	    (fd->flush_function)(fd->id, fd->flush_data);
}

/* initialise_fd(id, type, call_function, call_data, flush_function, flush_data)

   allocates space to store the new fd record, and initialises fields
   returns NULL if unable to allocate enough space, a pointer to the record
   otherwise 
*/


static fd_type *
initialise_fd(TCP_SOCKET id, int type, func_type call_function, char *call_data, func_type flush_function, char *flush_data)
{   fd_type *fd;

    fd = (fd_type *) QP_malloc(sizeof(fd_type));
    if (fd == NULL)
	return NULL;
    fd->id = id;
    fd->type = type;
    fd->call_function = call_function;
    fd->call_data = call_data;
    fd->flush_function = flush_function;
    fd->flush_data = flush_data;
    return fd;
}

/* update_fd(fdp, call_function, call_data, flush_function, flush_data)

   updates the fields of the fd record fdp

*/

static void
update_fd(fd_type *fdp, func_type call_function, char *call_data, func_type flush_function, char *flush_data)
{
    fdp->call_function = call_function;
    fdp->call_data = call_data;
    fdp->flush_function = flush_function;
    fdp->flush_data = flush_data;
}

/* or_fd_sets(width, f1, f2, result)

   combines fd_sets f1 and f2 so that result contains the set of fds that
   are set in f1, f2 or both; contents of f1 are valid up to width bit 
*/

#ifdef WIN32
or_fd_sets(int width, fd_set *f1, fd_set *f2, fd_set *result)
{
    u_int	i;
    FD_ZERO(result);

    if (f1) {
	for (i = 0; i < f1->fd_count; i++) {
	    SOCKET fd = f1->fd_array[i];
	    if (map_socket_to_fd(fd) < width && !FD_ISSET(fd, result)) /* [PM] April 2000 */
		FD_SET(fd, result);
	}
    }
    if (f2) {
	for (i = 0; i < f2->fd_count; i++) {
	    SOCKET fd = f2->fd_array[i];
            #if 0  /* [PM] April 2000
                      1. all of f2 should be used
                      2. map_socket_to_fd needed otherwise
                      3. No need to check if ISSET
                   */
	    if ( fd < width && !FD_ISSET(fd, result))
            #endif
		FD_SET(fd, result);
	}
    }
}
#elif !SIMPLE_FD_SET
static void
or_fd_sets(int width, fd_set *f1, fd_set *f2, fd_set *result)
{   int i;
    fd_mask mask;
    FD_ZERO(result);

    if (f1 && (width > 0)) {
	fd_set tmpf1;

	FD_ZERO(&tmpf1);
	for (i = 0 ; i < width / NFDBITS; i++)
	    tmpf1.fds_bits[i] = f1->fds_bits[i];
	mask = ~(~0 << (width % NFDBITS));
	tmpf1.fds_bits[i] = f1->fds_bits[i] & mask;
	if (f2) {
	    for (i = 0; i < howmany(FD_SETSIZE, NFDBITS); i++)
	     	result->fds_bits[i] = tmpf1.fds_bits[i] | f2->fds_bits[i];
	} else 
	    *result = tmpf1;
    } else if (f2)
	*result = *f2;
}
#else
ERROR: This code need to be fixed as the SUNOS4 case
static void
or_fd_sets(width, f1, f2, result)
    int width;
    fd_set *f1, *f2, *result;
{
    FD_ZERO(result);
    if (f1)
    {   fd_set mask;

	mask = ~(~0 << width);	/* gives mask with rightmost width bits set */
	if (f2)
	    *result = (*f1 & mask) | *f2;
	else
	    *result = *f1 & mask;
    }
    else if (f2)
	*result = *f2;
}
#endif

/*  int fd_sets_intersect(width, f1, f2)

    returns 1 if fd_sets f1 and f2 intersect (ie have common elements set);
    contents of f1 are valid to width bit
*/

#ifdef WIN32
static int
fd_sets_intersect(int width, fd_set *f1, fd_set *f2)
{
    u_int	i;
 
    if (f1 == NULL || f2 == NULL)
	return 0;

    for (i = 0; i < f1->fd_count; i++) {
	SOCKET fd = f1->fd_array[i];
	if (map_socket_to_fd(fd) < width && FD_ISSET(fd, f2)) /* [PM] April 2000 */
	    return 1;
    }
    return 0;
}
#elif !SIMPLE_FD_SET
static int
fd_sets_intersect(int width, fd_set *f1, fd_set *f2)
{   int i, w, intersect = 0;
    fd_mask mask;

    if ((f1 == NULL) || (f2 == NULL))
	return 0;
    for (i = 0; i < width / NFDBITS; i++)
	if (f2->fds_bits[i] & f1->fds_bits[i])
	    return 1;
    mask = ~(~0 << (width % NFDBITS));
    if (f2->fds_bits[i] & f1->fds_bits[i] & mask)
	return 1;
    return 0;
}
#else
static int
fd_sets_intersect(width, f1, f2)
    int width;
    fd_set *f1, *f2;
{   fd_set mask;

    if ((f1 == NULL) || (f2 == NULL))
	return 0;
    mask = ~(~0 << width);	/* gives mask with rightmost width bits set */
    if ((*f1 & mask & *f2) > 0)
	return 1;
    return 0;
}
#endif

/*  long_intersection(width, l1, l2, n)

    masks out any elements in l2 that are not set in l1 and sets n to be the
    total number of elements removed from l2; contents of l1 are valid up to
    width bit
*/

static void
long_intersection(long width, long int *l1, long int *l2, int *n)
{   long i, mask;

    mask = ~(~0 << width);	/* gives mask with rightmost width bits set */
    i = *l2 ^ (mask & *l1 & *l2); 
    for (*n = 0; i != 0 ; i >>= 1)
	*n += i & 01;
    *l2 = mask & *l1 & *l2;
}

/*  fd_sets_intersection(width, f1, f2, n)

    masks out any elements in f2 that are not set in f1 and sets n to be the
    total number of elements removed from f2; width is the number of bits
    valid in f1
*/

#ifdef WIN32

#if 1 /* [PM] April 2000 new working and clearer version */
static void
fd_sets_intersection(int width, fd_set *f1, fd_set *f2, int *n)
{
    fd_set result;
    u_int i;
    int removed;

    if (f2 == NULL)             /* [PM] April 2000 Do the right thing
                                   (However, it will not be called
                                   with f2==NULL) */
      {
        *n = 0;
        return;
      }
    if (f1 == NULL /* && f2 */)       /* [PM] April 2000 do the right thing if !f1 */
      {
        *n = f2->fd_count;
        FD_ZERO(f2);
        return;
      }

    /* [PM] f1 != NULL && f2 != NULL */
    removed = 0;
    for (i = 0; i < f2->fd_count; i++) {
	SOCKET Socket = f2->fd_array[i];
	if ( !(map_socket_to_fd(Socket) < width && FD_ISSET(Socket, f1)) ) {
	    FD_CLR(Socket, f2);
            removed++;
	}
    }
    *n = removed;
}
#else /* [PM] April 2000 Original broken code */
static void
fd_sets_intersection(int width, fd_set *f1, fd_set *f2, int *n)
{
    fd_set result;
    u_int i, count;

    if (f1 == NULL || f2 == NULL)
	return;

    FD_ZERO(&result);
    count = f2->fd_count;
    for (i = 0; i < f1->fd_count; i++) {
	SOCKET fd = f1->fd_array[i];
	if (map_socket_to_fd(fd) < width && FD_ISSET(fd, f2)) {
	    FD_SET(fd, &result); --count;
	}
    }
    *n = count;
}
#endif

#elif !SIMPLE_FD_SET
static void
fd_sets_intersection(int width, fd_set *f1, fd_set *f2, int *n)
{   int i, w, n1 = 0;

    *n = 0;
    if ( !f1 )
	return;
    for (i = 0; i < howmany(FD_SETSIZE, NFDBITS); i++)
    {	w = (width < NFDBITS) ? width : NFDBITS;
    	long_intersection(w, (long int *) &f1->fds_bits[i],
			     (long int *) &f2->fds_bits[i], &n1);
	*n += n1;
	width -= NFDBITS;
    }
}
#else
static void
fd_sets_intersection(width, f1, f2, n)
    int width;
    fd_set *f1, *f2;
    int *n;
{   int i = 0;

    long_intersection(width, f1, f2, n);
}
#endif


/* get_next_fd(fd)

   returns a pointer to the next input to be serviced (ie the next in the queue
   or the first in the queue if the current input is the last
*/

static fd_type *
get_next_fd(fd_type *fd)
{
    if (fd->next_fd)
	return current_fd->next_fd;
    else
	return first_fd;
}

/* find_fd(fd, type)

   finds the input with id fd

   returns a pointer to the input record, or NULL if the record does not exist
*/

static fd_type *
find_fd(TCP_SOCKET Socket, int type)
{   fd_type *fdp;
    for (fdp = first_fd;
	     fdp != NULL && ( fdp->id != Socket || fdp->type != type );
	     fdp = fdp->next_fd);
    return fdp;
}

/* add_fd_to_queue(fd)

   adds fd record pointed to by fd to queue of fds directly 
   before the next fd to be serviced
*/

static void
add_fd_to_queue(fd_type *fd)
{   fd_type *previous;

    if (current_fd == NULL)
    {	first_fd = fd;
	current_fd = fd;
	fd->next_fd = NULL;
	fd->last_fd = NULL;
    }
    else
    {	previous = current_fd->last_fd;
	if (previous)	/* insert before current_fd */
    	    previous->next_fd = fd;
	else		/* current_fd is first in list, so insert */
	    first_fd = fd;
	fd->last_fd = previous;
	fd->next_fd = current_fd;
	current_fd->last_fd = fd;
    }
    FD_SET(fd->id, &active_fds[fd->type]);
}

/* free_fd(fd)

   frees storage associated with fd struct
 */

static void
free_fd(fd_type *fd)
{   QP_free(fd);
}

/* remove_fd_from_queue(fd)

   removes fd record pointed to by fd from queue of registered fds
*/

static void
remove_fd_from_queue(fd_type *fd)
{   fd_type *previous = fd->last_fd,
	    *next = fd->next_fd;

    if (current_fd == fd)
    {	current_fd = get_next_fd(current_fd);
	if (current_fd == fd)
	    current_fd = NULL;
    }
    if (previous)
    	previous->next_fd = next;
    else
	first_fd = next;
    if (next)
	next->last_fd = previous;
    if (FD_ISSET(fd->id, &active_fds[fd->type]))
	FD_CLR(fd->id, &active_fds[fd->type]);
    if (FD_ISSET(fd->id, &inactive_fds[fd->type]))
	FD_CLR(fd->id, &inactive_fds[fd->type]);
    /* [PM] April 2000: What about to_be_reactivated_fds? */
}

/* add_fd(id, type, function, call_data, flush_function, flush_data)

   If function and flush_function are NULL, removes fd record for id from set 
   of registered fds. Otherwise if record for id exists, updates it otherwise
   creates a record containing data and adds it to set of registered fds.

   Returns QP_ERROR if unable to find fd record (when removing) or unable to 
   allocate space (when adding).
*/

static int
add_fd(TCP_SOCKET id, int type, void (*function) (/* ??? */), char *call_data, void (*flush_function) (/* ??? */), char *flush_data)
{   fd_type *fdp;

    if ( (function == NULL) && (flush_function == NULL) )
    {	fdp = find_fd(id, type);
	if (fdp == NULL)
	    return QP_ERROR;
	else
	{   remove_fd_from_queue(fdp);
	    free_fd(fdp);
	    return QP_SUCCESS;
	}
    }
    fdp = find_fd(id, type);
    if (fdp == NULL)
    {	fdp = initialise_fd(id, type, function, call_data, 
					flush_function, flush_data);
	if (fdp == NULL)
	    return QP_ERROR;
	add_fd_to_queue(fdp);
    }
    else
	update_fd(fdp, function, call_data, flush_function, flush_data);
    return QP_SUCCESS;
}	
	
/*
 * QP_add_input(id, function, call_data, flush_function, flush_data)
 *
 * Attempts to add a new fd record to the set of registered input records
 * Returns QP_ERROR if unable to allocate space.
 */

int
QP_add_input(int id, void (*function) (/* ??? */), char *call_data, void (*flush_function) (/* ??? */), char *flush_data)
{   
    return add_fd((TCP_SOCKET) id, INPUT_FD, function, call_data, 
					flush_function, flush_data);
}	
	
/*
 * QP_add_output(id, function, call_data, flush_function, flush_data)
 * 
 * Attempts to add a new fd record to the set of registered output records
 * Returns QP_ERROR if unable to allocate space.
 */
int
QP_add_output(int id, void (*function) (/* ??? */), char *call_data, void (*flush_function) (/* ??? */), char *flush_data)
{   
    return add_fd((TCP_SOCKET)id, OUTPUT_FD, function, call_data, 
					flush_function, flush_data);
}
	
/*
 * QP_add_exception(id, function, call_data, flush_function, flush_data)
 *
 * Attempts to add a new fd record to the set of registered exception records
 * Returns QP_ERROR if unable to allocate space.
 */
int
QP_add_exception(int id, void (*function) (/* ??? */), char *call_data, void (*flush_function) (/* ??? */), char *flush_data)
{   
    return add_fd((TCP_SOCKET)id, EXCEPT_FD, function, call_data, 
					flush_function, flush_data);
}

/*
 * QP_remove_input(id)
 *
 * Attempts to remove callback registrations from the input id
 * Returns QP_SUCCESS if it removes callbacks, QP_ERROR if it cannot find any
 */
int
QP_remove_input(int id)
{
    return add_fd((TCP_SOCKET)id, INPUT_FD, NULL, NULL, NULL, NULL);
}

/*
 * QP_remove_output(id)
 *
 * Attempts to remove callback registrations from the input id
 * Returns QP_SUCCESS if it removes callbacks, QP_ERROR if it cannot find any
 *
 */
int
QP_remove_output(int id)
{
    return add_fd((TCP_SOCKET) id, OUTPUT_FD, NULL, NULL, NULL, NULL);
}

/*
 * QP_remove_exception(id)
 *
 * Attempts to remove callback registrations from the exception id.
 * Returns QP_SUCCESS if it removes callbacks, QP_ERROR if it cannot find any
 */
int
QP_remove_exception(int id)
{
    return add_fd((TCP_SOCKET) id, EXCEPT_FD, NULL, NULL, NULL, NULL);
}

/* activate_fd(fd, type)

   removes fd from set of inactive fds and adds it to the set of active fds
*/

static void
activate_fd(TCP_SOCKET Socket, int type)
{
    if (FD_ISSET(Socket, &inactive_fds[type]))
    {	FD_CLR(Socket, &inactive_fds[type]);
	FD_SET(Socket, &active_fds[type]);
	FD_CLR(Socket, &to_be_reactivated_fds[type]);
    }
}

/* 
   reactivate_fds() is called on abort. See bug 5450.
*/

static void
reactivate_fds()
    {
	fd_type *fd;
	
	for (fd = first_fd; fd != NULL; fd = fd->next_fd) {
	    if (FD_ISSET(fd->id, &to_be_reactivated_fds[fd->type])) {
		activate_fd(fd->id, fd->type);
	    }
	}
    }

/* deactivate_fd(fd, type)

   removes fd from set of active fds and adds it to the set of inactive fds
*/


static void
deactivate_fd(TCP_SOCKET Socket, int type)
{
    FD_CLR(Socket, &active_fds[type]);
    FD_SET(Socket, &inactive_fds[type]);
    FD_SET(Socket, &to_be_reactivated_fds[type]);
}	



/*
 * QP_wait_input(fd, timeout)
 *
 * Waits for input on fd for timeout milliseconds (if timeout = QP_NO_TIMEOUT,
 * waits indefinitely). Calls QP_select to check the fd (and all other
 * registered inputs).
 * 
 * Returns QP_SUCCESS if input arrives on fd, QP_FAILURE if times out and
 * QP_ERROR if an error occurs (eg fd is not valid).
 */
int 
QP_wait_input(int fd_as_int, int relative_time)
{
    TCP_SOCKET Socket = (TCP_SOCKET) fd_as_int;
    struct timeval timeout;
    fd_set fds;
    int width, n, infinite, result,
	deactivated = 0;

    /* 	set timeout variable  */

    if (relative_time == QP_NO_TIMEOUT)
    {	infinite = 1;
    }
    else
    {	infinite = 0;
	timeout.tv_sec = relative_time / 1000;
	timeout.tv_usec = (relative_time % 1000) * 1000;
    }

    /*	initialise the fd_mask and width and remove fd from the set of 
	active fds, if it is one  */

    FD_ZERO(&fds);
    FD_SET(Socket, &fds);
    width = map_socket_to_fd(Socket) + 1; /* [PM] April 2000 added map_socket_to_fd */

    if (FD_ISSET(Socket, &active_fds[INPUT_FD]))
    {	deactivate_fd(Socket, INPUT_FD);
	deactivated = 1;
    }

    /*	call QP_select with timeout  */

    if (infinite)
	n = QP_select(width, &fds, NULL, NULL, NULL);
    else
	n = QP_select(width, &fds, NULL, NULL, &timeout);
 
    switch ( n )
    {   case QP_SUCCESS:	

    /*  timeout so finish  */

	    result = QP_FAILURE;
	    break;

	case QP_ERROR:

    /*  error so finish  */

	    result = QP_ERROR;
	    break;

	default:

    /*	input on fd so finish  */

	    result = QP_SUCCESS;
	    break;
    }

    /*	if fd was in the set of active inputs originally, add it to the
	set again */

    if (deactivated)
	activate_fd(Socket, INPUT_FD);

    return result;
}


/*
 * QP_select(width, read_fds, write_fds, except_fds, relative_time)
 *
 * Waits for input for relative_time on any of the fds represented by the
 * bit masks pointed to by read_fds, write_fds and except_fds. If timeout
 * equals QP_NO_TIMEOUT, QP_select waits indefinitely. While waiting it
 * services any of the registered timers that have timed out and those
 * registered fds with input waiting to be processed.
 *
 * Returns QP_SUCCESS (ie 0) if it times out before input arrives on any of the 
 * fds, QP_ERROR if an error occurs, or the number of fds with input waiting
 * (in which case it modifies the contents of the bit masks to indicate the 
 * relevant fds).
 */
int 
QP_select(int width, fd_set *read_fds, fd_set *write_fds, fd_set *except_fds, struct timeval *relative_time)
{   struct timeval timeout, start, end, current;
    int infinite = 0,
	w, finished, n, result;
    fd_set all_fds[3];

    /*	if there are no user-specified fds to monitor, and no timeouts
	registered, do select and return  */


#ifdef WIN32 /* [PM] April 2000 Used to be the same as non-WIN32 case */
    if ((first_fd == NULL) && (first_timer == NULL))
      {
        if ( FDSET_NONEMPTY(read_fds)
             || FDSET_NONEMPTY(write_fds)
             || FDSET_NONEMPTY(except_fds) )
          {
            do
              {
                /* [PM] April 2000 Q: Should relative_time be adjusted on EINTR? */
                n = select(width, read_fds, write_fds, except_fds, relative_time);
              } while ((n == -1) && (tcp_errno() == TCP_EINTR));
            return (n == -1) ? QP_ERROR : n;
          }
        else
          {
            return 0;           /* [PM] fake a timeout */
          }
      }
#else  /* !WIN32 */
    if ((first_fd == NULL) && (first_timer == NULL))
    {	do
	{   n = select(width, read_fds, write_fds, except_fds, 
							relative_time);
	} while ((n == -1) && (tcp_errno() == TCP_EINTR));

	return (n == -1) ? QP_ERROR : n;
    }
#endif

    /*	if timeout is NULL, record
	else if timeout is 0, do select and return
	otherwise find the time at which to time out  */

    if (relative_time == NULL)
	infinite = 1;
    else if ((relative_time->tv_sec == 0) && (relative_time->tv_usec == 0))
    {
#ifdef WIN32 /* [PM] April 2000 */ 
      if ( FDSET_NONEMPTY(read_fds)
           || FDSET_NONEMPTY(write_fds)
           || FDSET_NONEMPTY(except_fds) )
#endif
        {
          do
            {
              n = select(width, read_fds, write_fds, except_fds, 
                         relative_time);
            } while ((n == -1) && (tcp_errno() == TCP_EINTR));
          return (n == -1) ? QP_ERROR : n;
        }
#ifdef WIN32 /* [PM] April 2000 */
      else                      /* All fds empty */
        {
          return 0;             /* Fake a timeout */
        }
#endif
    }
    else
    {	gettimeofday(&start, NULL);
	add_timeout(&start, relative_time, &end);
    }

    finished = 0;
    while (!finished)
    {	timer_type *timer;
	fd_type *fdp;

    /*	flush all the registered inputs  */

	flush_inputs();

    /*	add active fds to fd_sets given as input */

	or_fd_sets(width, read_fds, &active_fds[INPUT_FD], &all_fds[INPUT_FD]);
	or_fd_sets(width, write_fds, &active_fds[OUTPUT_FD], 
							&all_fds[OUTPUT_FD]);
	or_fd_sets(width, except_fds, &active_fds[EXCEPT_FD], 
							&all_fds[EXCEPT_FD]);

	timer = first_timer;
	gettimeofday(&current, NULL);

    /*	if there are any registered timers and there is no timeout OR
	if there are any registered timers, the timeout has not passed and
	the next timer times out before the timeout  */

	if ((timer != NULL) &&  (infinite || 
		(before(&current,&end) && (before(timer->end, &end)))))
	{   unsigned long delay;

    /*	call select using the timeout of the next timer  */

	    timeout.tv_sec = timer->end->tv_sec;
	    timeout.tv_usec = timer->end->tv_usec;
	    time_difference(&timeout, &current, &timeout);

#ifdef WIN32                       /* [PM] April 2000 */
        if ( FDSET_NONEMPTY(&all_fds[INPUT_FD])
             || FDSET_NONEMPTY(&all_fds[OUTPUT_FD])
             || FDSET_NONEMPTY(&all_fds[EXCEPT_FD]) )
#endif
          {
	    n = select(FD_SETSIZE, &all_fds[INPUT_FD], 
			&all_fds[OUTPUT_FD], &all_fds[EXCEPT_FD], &timeout);
          }
#ifdef WIN32                       /* [PM] April 2000 */
        else                    /* all fds empty */
          {
            /* !! Consider using SLeepEx and use QueueUserAPC to wake up
               on CTRL-C */
            Sleep(timeout.tv_sec*1000+timeout.tv_usec);
            n = 0;              /* timeout */
          }
#endif

	    switch (n)
	    {	case 0:

    /*	timed out, therefore remove timer from set of registered timers,
	call its timeout function and continue  */

		    first_timer = timer->next_timer;
		    gettimeofday(&current, NULL);
		    delay = time_difference_in_ms(&current, timer->start);

		    (timer->call_function)(delay, timer->call_data, all_fds);
		    free_timer(timer);
		    continue;

		case -1:

    /*	select has been interrupted, so repeat  */

		    if (tcp_errno() == TCP_EINTR)
			continue;

    /* 	error so finish  */

		    FD_ZERO(&all_fds[INPUT_FD]);
		    FD_ZERO(&all_fds[OUTPUT_FD]);
		    FD_ZERO(&all_fds[EXCEPT_FD]);
		    result = QP_ERROR;
		    finished = 1;
		    continue;

		default:

    /*	if there is input on user-specified fds, finish; otherwise find the 
	next fd in the queue with input waiting, remove it from the set of 
	active fds, service it and replace it in the active set  */

		    if ( fd_sets_intersect(width, read_fds, &all_fds[INPUT_FD]) 
			 || fd_sets_intersect(width, write_fds, 
						&all_fds[OUTPUT_FD]) 
			 || fd_sets_intersect(width, except_fds, 
						&all_fds[EXCEPT_FD]) )
		    {	int nr, no, ne;
			fd_sets_intersection(width, read_fds, 
						&all_fds[INPUT_FD], &nr);
			fd_sets_intersection(width, write_fds, 
						&all_fds[OUTPUT_FD],&no);
			fd_sets_intersection(width, except_fds, 
						&all_fds[EXCEPT_FD], &ne);
			result = n - nr -no -ne;
			finished = 1;
			continue;
		    }
                    /* [PM] April 2000 Q: What ensures loop termination? */
		    for ( ; !FD_ISSET(current_fd->id, 
					&all_fds[current_fd->type]);
				current_fd = get_next_fd(current_fd) );

		    fdp = current_fd;
		    deactivate_fd(fdp->id, fdp->type);
		    if (fdp->call_function)
			(fdp->call_function)(fdp->id, fdp->call_data, all_fds);
		    activate_fd(fdp->id, fdp->type);
		    continue;
	    }
	}

    /*	otherwise perform select using time remaining to timeout  */

	else
	{   

    /*	if there is a timeout specified, use it; 
	otherwise use a NULL pointer, causing select to block indefinitely  */

#ifdef WIN32                       /* [PM] April 2000 */
        if ( FDSET_NONEMPTY(&all_fds[INPUT_FD])
             || FDSET_NONEMPTY(&all_fds[OUTPUT_FD])
             || FDSET_NONEMPTY(&all_fds[EXCEPT_FD]) )
#endif
          {
	    if (!infinite)
	    {	time_difference(&end, &current, &timeout);
	    	n = select(FD_SETSIZE, &all_fds[INPUT_FD], 
			&all_fds[OUTPUT_FD], &all_fds[EXCEPT_FD], &timeout);
	    }
	    else
	  	n = select(FD_SETSIZE, &all_fds[INPUT_FD], 
			&all_fds[OUTPUT_FD], &all_fds[EXCEPT_FD], NULL);
          }
#ifdef WIN32                       /* [PM] April 2000 */
        else                    /* all fds empty */
          {
            n = 0;              /* fake a timeout */
          }
#endif
	    switch (n)
	    {	case 0:		/*  timed out so finish  */
		    result = QP_SUCCESS;
		    finished = 1;
		    continue;
		case -1:	/*  select was interrupted so continue  */
		    if (errno == EINTR)
			continue;
				/*  error so finish  */
		    FD_ZERO(&all_fds[INPUT_FD]);
		    FD_ZERO(&all_fds[OUTPUT_FD]);
		    FD_ZERO(&all_fds[EXCEPT_FD]);
		    result = QP_ERROR;
		    finished = 1;
		    continue;
		default:

    /*	if there is input on user-specified fds, finish; otherwise find the 
	next fd in the queue with input waiting, remove it from the set of
	active fds, service it and replace it in the active set  */

		    if ( fd_sets_intersect(width, read_fds, &all_fds[INPUT_FD]) 
			 || fd_sets_intersect(width, write_fds, 
						&all_fds[OUTPUT_FD]) 
			 || fd_sets_intersect(width, except_fds, 
						&all_fds[EXCEPT_FD]) )
		    {	int nr, no, ne;
			fd_sets_intersection(width, read_fds, 
						&all_fds[INPUT_FD], &nr);
			fd_sets_intersection(width, write_fds, 
						&all_fds[OUTPUT_FD], &no);
			fd_sets_intersection(width, except_fds, 
						&all_fds[EXCEPT_FD], &ne);
			result = n - nr - no - ne;
			finished = 1;
			continue;
		    }
                    /* [PM] April 2000 Q: What ensures loop termination? */
		    for ( ; !FD_ISSET(current_fd->id, 
					&all_fds[current_fd->type]);
				current_fd = get_next_fd(current_fd) );

		    fdp = current_fd;
	       	    deactivate_fd(fdp->id, fdp->type);
		    if (fdp->call_function)
			(fdp->call_function)(fdp->id, fdp->call_data, all_fds);
	       	    activate_fd(fdp->id, fdp->type);
		    continue;
	    }
	}
    }
    if (read_fds)
	*read_fds = all_fds[INPUT_FD];
    if (write_fds)
	*write_fds = all_fds[OUTPUT_FD];
    if (except_fds)
	*except_fds = all_fds[EXCEPT_FD];
    return result;
}


/*
 * QP_wait_until(test, test_data, fd, relative_time)
 *
 * Waits for test to succeed for relative_time milliseconds (if relative_time
 * = QP_NO_TIMEOUT, waits indefinitely). Input to enable test to succeed
 * expected on fd. While the test fails, services those registered fds with
 * input waiting to be processed and those timers that have timed out.
 * Note that it is assumed that fd has already been registered by QP_add_input.
 *
 * Returns QP_SUCCESS if test succeeds, QP_FAILURE if times out and
 * QP_ERROR if an error occurs.
 */
int 
QP_wait_until(test_func_type test, char *test_data, int relative_time)
{   struct timeval timeout, start, end, current;
    int infinite = 0,
	width = 0, 
	finished, n, result;
    fd_set all_fds[3];
 
    /* 	set timeout variable if there is not timeout, otherwise calculate
	end time  */

    if (relative_time == QP_NO_TIMEOUT)
    {	infinite = 1;
    }
    else
    {	infinite = 0;
	gettimeofday(&start, NULL);
	add_timeout_in_ms(&start, relative_time, &end);
    }

    finished = 0;
    while (!finished)
    {	timer_type *timer;
	fd_type *fdp;

    /*  if test succeeds, return QP_SUCCESS  */

	if ( (test)(test_data) )
	{   result = QP_SUCCESS;
	    finished = 1;
	    continue;
	}

    /*	flush all the registered inputs  */

	flush_inputs();

    /*	add active fds to fd_sets to be used in select */

	all_fds[INPUT_FD] = active_fds[INPUT_FD];
	all_fds[OUTPUT_FD] = active_fds[OUTPUT_FD];
	all_fds[EXCEPT_FD] = active_fds[EXCEPT_FD];

	timer = first_timer;
	gettimeofday(&current, NULL);

    /*	if there are any registered timers and there is no timeout OR
	if there are any registered timers, the timeout has not passed and
	the next timer times out before the timeout  */

	if ((timer != NULL) &&  (infinite || 
		(before(&current,&end) && (before(timer->end, &end)))))
	{   unsigned long delay;

    /*	call select using the timeout of the next timer  */

	    timeout.tv_sec = timer->end->tv_sec;
	    timeout.tv_usec = timer->end->tv_usec;
	    time_difference(&timeout, &current, &timeout);

#ifdef WIN32                       /* [PM] April 2000 */
        if ( FDSET_NONEMPTY(&all_fds[INPUT_FD])
             || FDSET_NONEMPTY(&all_fds[OUTPUT_FD])
             || FDSET_NONEMPTY(&all_fds[EXCEPT_FD]) )
#endif
          {
	    n = select(FD_SETSIZE, &all_fds[INPUT_FD], &all_fds[OUTPUT_FD], 
				&all_fds[EXCEPT_FD], &timeout);
          }
#ifdef WIN32                       /* [PM] April 2000 */
        else
          {
            /* See QP_select above */
            Sleep(timeout.tv_sec*1000+timeout.tv_usec);
            n = 0;              /* timeout */
          }
#endif

	    switch (n)
	    {	case 0:

    /*	timed out, therefore remove timer from set of registered timers,
	call its timeout function and continue  */

		    first_timer = timer->next_timer;
		    gettimeofday(&current, NULL);
		    delay = time_difference_in_ms(&current, timer->start);
		    (timer->call_function)(delay, timer->call_data, all_fds);
		    free_timer(timer);
		    continue;

		case -1:

    /*	select has been interrupted, so repeat  */

		    if (errno == EINTR)
			continue;

    /* 	error so finish  */

		    result = QP_ERROR;
		    finished = 1;
		    continue;

		default:

    /*	find the next fd in the queue with input waiting, remove it from 
	the set of active fds, service it and replace it in the active set  */

                    /* [PM] April 2000 Q: What ensures loop termination? */
		    for ( ; !FD_ISSET(current_fd->id, 
					&all_fds[current_fd->type]);
				current_fd = get_next_fd(current_fd) );

		    fdp = current_fd;
	       	    deactivate_fd(fdp->id, fdp->type);
		    if (fdp->call_function)
			(fdp->call_function)(fdp->id, fdp->call_data, all_fds);
		    activate_fd(fdp->id, fdp->type);
		    continue;
	    }
	}

    /*	otherwise perform select using time remaining to timeout  */

	else
	{   

    /*	if there is a timeout specified, use it; 
	otherwise use a NULL pointer, causing select to block indefinitely  */

#ifdef WIN32                       /* [PM] April 2000 */
        if ( FDSET_NONEMPTY(&all_fds[INPUT_FD])
             || FDSET_NONEMPTY(&all_fds[OUTPUT_FD])
             || FDSET_NONEMPTY(&all_fds[EXCEPT_FD]) )
#endif

          {
	    if (!infinite)
	    {	time_difference(&end, &current, &timeout);
		n = select(FD_SETSIZE, &all_fds[INPUT_FD], &all_fds[OUTPUT_FD], 
				&all_fds[EXCEPT_FD], &timeout);
	    }
	    else
		n = select(FD_SETSIZE, &all_fds[INPUT_FD], &all_fds[OUTPUT_FD], 
				&all_fds[EXCEPT_FD], NULL);
          }
#ifdef WIN32                       /* [PM] April 2000 */
        else                    /* all fds empty */
          {
            n = 0;              /* fake a timeout */
          }
#endif
	    switch (n)
	    {	case 0:		/*  timed out so finish  */
		    result = QP_FAILURE;
		    finished = 1;
		    continue;
		case -1:	/*  select was interrupted so continue  */
		    if (errno == EINTR)
			continue;
				/*  error so finish  */
		    result = QP_ERROR;
		    finished = 1;
		    continue;
		default:

    /*	find the next fd in the queue with input waiting, remove it from the 
	set of active fds, service it and replace it in the active set  */

                    /* [PM] April 2000 Q: What ensures loop termination? */
		    for ( ; !FD_ISSET(current_fd->id, 
					&all_fds[current_fd->type]);
				current_fd = get_next_fd(current_fd) );

		    fdp = current_fd;
	       	    deactivate_fd(fdp->id, fdp->type);
		    if (fdp->call_function)
			(fdp->call_function)(fdp->id, fdp->call_data, all_fds);
		    activate_fd(fdp->id, fdp->type);
		    continue;
	    }
	}
    }
    return result;
}

 
/*
 * QP_enable_input(fd, bool)
 *
 * If bool is TRUE (ie 1), QP_enable_input attempts to activate fd otherwise
 * it attempts to deactivate fd. 
 *
 * Returns QP_SUCCESS if it makes a change, QP_FAILURE if the fd is already in 
 * the requested state and QP_ERROR if fd is not in the set of registered fds.
 */
int 
QP_enable_input(int fd_as_int, int bool)
{
  TCP_SOCKET fd = (TCP_SOCKET) fd_as_int;
    if (bool)
    {	if (FD_ISSET(fd, &active_fds[INPUT_FD]))
	    return QP_FAILURE;
	if (FD_ISSET(fd, &inactive_fds[INPUT_FD]))
	{   FD_CLR(fd, &inactive_fds[INPUT_FD]);
	    FD_SET(fd, &active_fds[INPUT_FD]);
	    return QP_SUCCESS;
	}
    }
    else
    {	if (FD_ISSET(fd, &inactive_fds[INPUT_FD]))
	    return QP_FAILURE;
	if (FD_ISSET(fd, &active_fds[INPUT_FD]))
	{   FD_CLR(fd, &active_fds[INPUT_FD]);
	    FD_SET(fd, &inactive_fds[INPUT_FD]);
	    return QP_SUCCESS;
	}
    }
    return QP_ERROR;
}
