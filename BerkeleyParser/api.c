 /****************************************************************************/
 /*                                                                          */
 /*  Copyright (C) 1991-2000, all rights reserved                            */
 /*  Daniel Sleator, David Temperley, and John Lafferty                      */
 /*  See file "README" for information about commercial use of this system   */
 /*                                                                          */
 /****************************************************************************/

#include "api-structures.h"

/***************************************************************
*
* Routines for manipulating Dictionary 
*
****************************************************************/


static Dictionary internal_dictionary_create(char * dict_name, char * pp_name, char * cons_name, char * affix_name, char * path) {
    Dictionary dict;
    static int rand_table_inited=FALSE;
    Dict_node *dict_node;
    char * dictionary_path_name;

    dict = (Dictionary) xalloc(sizeof(struct Dictionary_s));

    if (!rand_table_inited) {
        init_randtable();
	rand_table_inited=TRUE;
    }

    dict->string_set = string_set_create();
    dict->name = string_set_add(dict_name, dict->string_set);
    dict->num_entries = 0;
    dict->is_special = FALSE;
    dict->already_got_it = '\0';
    dict->line_number = 1;
    dict->root = NULL;
    dict->word_file_header = NULL;
    dict->exp_list = NULL;
    dict->affix_table = NULL;

     
    if (path != NULL) dictionary_path_name = path; else dictionary_path_name = dict_name;

    if (!open_dictionary(dictionary_path_name, dict)) {
	lperror(NODICT, dict_name);
	string_set_delete(dict->string_set);
	xfree(dict, sizeof(struct Dictionary_s));
	return NULL;
    }

    if (!read_dictionary(dict)) {
	string_set_delete(dict->string_set);
	xfree(dict, sizeof(struct Dictionary_s));
	return NULL;
    }

    dict->left_wall_defined  = boolean_dictionary_lookup(dict, LEFT_WALL_WORD);
    dict->right_wall_defined = boolean_dictionary_lookup(dict, RIGHT_WALL_WORD);
    dict->postprocessor      = post_process_open(dict->name, pp_name);
    dict->constituent_pp     = post_process_open(dict->name, cons_name);
    
    dict->affix_table = NULL;
    if (affix_name != NULL) {
	dict->affix_table = internal_dictionary_create(affix_name, NULL, NULL, NULL, dict_name);
	if (dict->affix_table == NULL) {
	    fprintf(stderr, "%s\n", lperrmsg);
	    exit(-1);
	}
    }
    
    dict->unknown_word_defined = boolean_dictionary_lookup(dict, UNKNOWN_WORD);
    dict->use_unknown_word = TRUE;
    dict->capitalized_word_defined = boolean_dictionary_lookup(dict, PROPER_WORD);
    dict->pl_capitalized_word_defined = boolean_dictionary_lookup(dict, PL_PROPER_WORD);
    dict->hyphenated_word_defined = boolean_dictionary_lookup(dict, HYPHENATED_WORD);
    dict->number_word_defined = boolean_dictionary_lookup(dict, NUMBER_WORD);
    dict->ing_word_defined = boolean_dictionary_lookup(dict, ING_WORD);
    dict->s_word_defined = boolean_dictionary_lookup(dict, S_WORD);
    dict->ed_word_defined = boolean_dictionary_lookup(dict, ED_WORD);
    dict->ly_word_defined = boolean_dictionary_lookup(dict, LY_WORD);
    dict->max_cost = 1000;

    if ((dict_node = dictionary_lookup(dict, ANDABLE_CONNECTORS_WORD)) != NULL) {
	dict->andable_connector_set = connector_set_create(dict_node->exp);
    } else {
	dict->andable_connector_set = NULL;
    }

    if ((dict_node = dictionary_lookup(dict, UNLIMITED_CONNECTORS_WORD)) != NULL) {
	dict->unlimited_connector_set = connector_set_create(dict_node->exp);
    } else {
	dict->unlimited_connector_set = NULL;
    }

    free_lookup_list();
    return dict;
}

Dictionary dictionary_create(char * dict_name, char * pp_name, char * cons_name, char * affix_name) {
    return internal_dictionary_create(dict_name, pp_name, cons_name, affix_name, NULL);
}

int dictionary_delete(Dictionary dict) {

    if (verbosity > 0) {
	fprintf(stderr, "Freeing dictionary %s\n", dict->name);
    }

    if (dict->affix_table != NULL) {
        dictionary_delete(dict->affix_table);
    }

    connector_set_delete(dict->andable_connector_set);
    connector_set_delete(dict->unlimited_connector_set);

    post_process_close(dict->postprocessor);
    post_process_close(dict->constituent_pp);
    string_set_delete(dict->string_set);
    free_dictionary(dict);
    xfree(dict, sizeof(struct Dictionary_s));

    return 0;
}

int dictionary_get_max_cost(Dictionary dict) {
    return dict->max_cost;
}


/***************************************************************
*
* Routines for creating and destroying processing Sentences
*
****************************************************************/

Sentence sentence_create(char *input_string, Dictionary dict) {
    Sentence sent;
    int i;

    free_lookup_list();

    sent = (Sentence) xalloc(sizeof(struct Sentence_s));
    sent->dict = dict;
    sent->length = 0;
    sent->num_linkages_found = 0;
    sent->num_linkages_alloced = 0;
    sent->num_linkages_post_processed = 0;
    sent->num_valid_linkages = 0;
    sent->link_info = NULL;
    sent->deletable = NULL;
    sent->effective_dist = NULL;
    sent->num_valid_linkages = 0;
    sent->null_count = 0;
    sent->parse_info = NULL;
    sent->string_set = string_set_create();

    if (!separate_sentence(input_string, sent)) {
	string_set_delete(sent->string_set);
	xfree(sent, sizeof(struct Sentence_s));
	return NULL;
    }
   
    sent->q_pruned_rules = FALSE; /* for post processing */
    sent->is_conjunction = (char *) xalloc(sizeof(char)*sent->length);
    set_is_conjunction(sent);
    initialize_conjunction_tables(sent);

    for (i=0; i<sent->length; i++) {
	/* in case we free these before they set to anything else */
	sent->word[i].x = NULL;
	sent->word[i].d = NULL;
    }
    
    if (!(dict->unknown_word_defined && dict->use_unknown_word)) {
	if (!sentence_in_dictionary(sent)) {
	    sentence_delete(sent);
	    return NULL;
	}
    }
    
    if (!build_sentence_expressions(sent)) {
	sentence_delete(sent);
	return NULL;
    }

    return sent;
}

void sentence_delete(Sentence sent) {

  /*free_andlists(sent); */
    free_sentence_disjuncts(sent);      
    free_sentence_expressions(sent);
    string_set_delete(sent->string_set);
    free_parse_set(sent);
    free_post_processing(sent);
    post_process_close_sentence(sent->dict->postprocessor);
    free_lookup_list();
    free_deletable(sent);
    free_effective_dist(sent);
    xfree(sent->is_conjunction, sizeof(char)*sent->length);
    xfree((char *) sent, sizeof(struct Sentence_s));
}

void free_andlists(Sentence sent) {

  int L;
  Andlist * andlist, * next;
  for(L=0; L<sent->num_linkages_post_processed; L++) {
    /* printf("%d ", sent->link_info[L].canonical);  */
    /* if (sent->link_info[L].canonical==0) continue; */
    andlist = sent->link_info[L].andlist; 
    while(1) {
      if(andlist == NULL) break;
      next = andlist->next;
      xfree((char *) andlist, sizeof(Andlist));
      andlist = next;
    }
  }
  /* printf("\n"); */
}

int sentence_length(Sentence sent) {
    return sent->length;
}

char * sentence_get_word(Sentence sent, int index) {
    return sent->word[index].string;
}

int sentence_null_count(Sentence sent) {
    return sent->null_count;
}

int sentence_num_linkages_found(Sentence sent) {
    return sent->num_linkages_found;
}

int sentence_num_valid_linkages(Sentence sent) {
    return sent->num_valid_linkages;
}

int sentence_num_linkages_post_processed(Sentence sent) {
    return sent->num_linkages_post_processed;
}

int sentence_num_violations(Sentence sent, int i) {
    return sent->link_info[i].N_violations;
}

int sentence_disjunct_cost(Sentence sent, int i) {
    return sent->link_info[i].disjunct_cost;
}

