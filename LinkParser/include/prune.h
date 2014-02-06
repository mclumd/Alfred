void       prune(Sentence sent);
int        power_prune(Sentence sent, int mode, Parse_Options opts);
void       pp_and_power_prune(Sentence sent, int mode, Parse_Options opts);
int        prune_match(Connector * a, Connector * b, int wa, int wb);
int        x_prune_match(Connector * a, Connector * b);
void       expression_prune(Sentence sent);
Disjunct * eliminate_duplicate_disjuncts(Disjunct * );
