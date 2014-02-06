String_set * string_set_create(void);
char *       string_set_add(char * source_string, String_set * ss);
char *       string_set_lookup(char * source_string, String_set * ss);
void         string_set_delete(String_set *ss);
