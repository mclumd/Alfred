#define MAX_PARSE_TIME_DEFAULT -1
#define MAX_MEMORY_DEFAULT 128000000

void      print_time(Parse_Options opts, char * s);
void      print_total_time(Parse_Options opts);
void      print_total_space(Parse_Options opts);
void      resources_reset(Resources r);
void      resources_reset_time(Resources r);
void      resources_reset_space(Resources r);
void      resources_print_total_time(int verbosity, Resources r);
void      resources_print_total_space(int verbosity, Resources r);
void      resources_print_time(int verbosity, Resources r, char * s);
int       resources_timer_expired(Resources r);
int       resources_memory_exhausted(Resources r);
int       resources_exhausted(Resources r);
Resources resources_create(); 
void      resources_delete(Resources ti);
