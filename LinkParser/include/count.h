int  table_lookup(int, int, Connector *, Connector *, int);
int  match(Connector *a, Connector *b, int wa, int wb);
int  x_match(Connector *a, Connector *b);
int  count(int lw, int rw, Connector *le, Connector *re, int cost);
void init_table(Sentence sent);
void free_table(Sentence sent);
int  parse(Sentence sent, int mincost, Parse_Options opts);
void conjunction_prune(Sentence sent, Parse_Options opts);
void count_set_effective_distance(Sentence sent);
void count_unset_effective_distance(Sentence sent);
void delete_unmarked_disjuncts(Sentence sent);

