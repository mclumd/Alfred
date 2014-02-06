#ifndef _PRINTUTILH_
#define _PRINTUTILH_

typedef struct String_s String;
struct String_s {
    unsigned int allocated;  /* Unsigned so VC++ doesn't complain about comparisons */
    char * p;
    char * eos;
};

String * String_create();
int append_string(String * string, char *fmt, ...);

#endif


