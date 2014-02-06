pp_linkset *pp_linkset_open(int size); 
void pp_linkset_close     (pp_linkset *ls);
void pp_linkset_clear     (pp_linkset *ls);
int  pp_linkset_add       (pp_linkset *ls, char *str);
int  pp_linkset_match     (pp_linkset *ls, char *str);
int  pp_linkset_match_bw  (pp_linkset *ls, char *str);
int  pp_linkset_population(pp_linkset *ls); 

