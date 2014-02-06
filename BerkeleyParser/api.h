 /****************************************************************************/
 /*                                                                          */
 /*  Copyright (C) 1991-2000, all rights reserved                            */
 /*  Daniel Sleator, David Temperley, and John Lafferty                      */
 /*  See file "README" for information about commercial use of this system   */
 /*                                                                          */
 /****************************************************************************/

/*****************************************************************************
*
* Functions to manipulate Dictionaries
*
*****************************************************************************/


Dictionary dictionary_create(char * dict_name, char * pp_name, char * cons_name, char * affix_name);
int           dictionary_delete(Dictionary dict);
int           dictionary_get_max_cost(Dictionary dict);
/*  obsolete *DS*
void          dictionary_open_affix_file(Dictionary dict, char * affix_file);
void          dictionary_open_constituent_knowledge(Dictionary dict, char * cons_file);
*/



/*****************************************************************************
*
* Functions to manipulate Sentences
*
*****************************************************************************/


Sentence     sentence_create(char *input_string, Dictionary dict);
void         sentence_delete(Sentence sent);
int          sentence_parse(Sentence sent, Parse_Options opts);
int          sentence_length(Sentence sent);
char *       sentence_get_word(Sentence sent, int wordnum);
int          sentence_null_count(Sentence sent);
int          sentence_num_linkages_found(Sentence sent);
int          sentence_num_valid_linkages(Sentence sent);
int          sentence_num_linkages_post_processed(Sentence sent);
int          sentence_num_violations(Sentence sent, int i);
int          sentence_disjunct_cost(Sentence sent, int i);

