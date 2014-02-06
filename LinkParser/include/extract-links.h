int   build_parse_set(Sentence sent, int cost, Parse_Options opts);
void  free_parse_set(Sentence sent);
void  extract_links(int index, int cost, Parse_info * pi);
void  build_current_linkage(Parse_info * pi);
void  advance_parse_set(Parse_info * pi);
void  init_x_table(Sentence sent);
