/* from utilities.c */
extern int verbosity;                 /* the verbosity level for error messages */
extern int space_in_use;              /* space used but not yet freed during parse */
extern int max_space_in_use;          /* maximum of the above for this parse */
extern int external_space_in_use;     /* space used by "user" */
extern int max_external_space_in_use; /* maximum of the above */

#define RTSIZE 256
/* size of random table for computing the
   hash functions.  must be a power of 2 */

extern unsigned int randtable[RTSIZE];   /* random table for hashing */

/* from error.c */
extern int   lperrno;
extern char  lperrmsg[];
