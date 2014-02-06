int  maxcost_of_sentence(Sentence sent);
void build_sentence_disjuncts(Sentence sent, int cost_cutoff);
void print_disjunct_list(Disjunct *);
X_node *   build_word_expressions(Sentence sent, char *);
Disjunct * build_disjuncts_for_dict_node(Dict_node *);
