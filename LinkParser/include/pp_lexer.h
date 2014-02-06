PPLexTable *pp_lexer_open(FILE *f);
void  pp_lexer_close                  (PPLexTable *lt);
int   pp_lexer_set_label              (PPLexTable *lt, const char *label);
int   pp_lexer_count_tokens_of_label  (PPLexTable *lt);
char *pp_lexer_get_next_token_of_label(PPLexTable *lt);
int   pp_lexer_count_commas_of_label  (PPLexTable *lt);
char **pp_lexer_get_next_group_of_tokens_of_label(PPLexTable *lt,int *n_toks);
