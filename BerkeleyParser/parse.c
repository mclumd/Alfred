/*/usr/local/quintus3.2-sol26/generic/qplib3.2/IPC/TCP/demo */

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include "tcp.h"
//#include "api-structures.h"

#define MAXINPUT 1024
#define DISPLAY_MAX 1024
#define COMMENT_CHAR '%'  /* input lines beginning with this are ignored */
#define TRUE 1
#define FALSE 0 

#define MAX_WORD 60           /* maximum number of chars in a word */
#define MAX_LINE 1500         /* maximum number of chars in a sentence */
#define MAX_SENTENCE 250      /* maximum number of words in a sentence */
#define MAX_TAGS 500		  /* maximum number of tags in a sentence */

typedef struct Word_struct Word;
struct Word_struct {
    char * string;
    char * tag;    /* eventually these get generated */
};

typedef struct Sentence_s * Sentence;
struct Sentence_s {
    //Dictionary  dict;           /* words are defined from this dictionary */
    int    length;              /* number of words */
    Word   word[MAX_SENTENCE];  /* array of words after tokenization */
    
    //Parse_info *   parse_info;  /* set of parses for the sentence */
    //String_set *   string_set;  /* used for word names, not connectors */
  
};

typedef struct Tag {
	int tagnum;
	int size;
	int children[MAX_TAGS];
	struct Tag* parent;
} Tag;


/*added by Darsana to connect to Alfred*/
int connect_alfred(char *ServerFile) {
    int Port, Service;
    char *Host;
   
    Service = tcp_listen(ServerFile, &Port, &Host);
    if (Service == -1){
		fprintf(stderr, "Error in creating a channel.\n");
    }

    return Service;
}

void print_usage(char *str) {
    fprintf(stderr, 
	    "Usage: %s [dict_file] [-pp pp_knowledge_file] [-alma alma_host_file]\n", str);
    exit(-1);
}

int fget_input_string(char *input_string, FILE *in, FILE *out) {
    fprintf(out, "BerkeleyParser> ");
    fflush(out);
    if (fgets(input_string, MAXINPUT, in)) return 1;
    else return 0;
}

int main(int argc, char * argv[]) {
  //  Dictionary      dict;
    Sentence        sent;
    char            *dictionary_file=NULL;
    char	    *sfile = NULL;
    int             pp_on=TRUE;
    int             af_on=TRUE;
    int             cons_on=TRUE;
    int             num_linkages, i;
    char            input_string[MAXINPUT];
  //  Label           label = NO_LABEL;  
    int             parsing_space_leaked, reported_leak, dictionary_and_option_space;
    int             PassiveSocket = -1;
    int 	    	FD = -1;
    int             SentNum = 0;
    char 	    	alma_str[100];

    i = 1;
    if ((argc > 1) && (argv[1][0] != '-')) {
		/* the dictionary is the first argument if it doesn't begin with "-" */
		dictionary_file = argv[1];	
		i++;
    }

    for (; i<argc; i++) {
		if (argv[i][0] == '-') {
			if (strcmp("-alma", argv[i])==0) {
					if ((sfile != NULL) || (i+1 == argc))
						print_usage(argv[0]);
					sfile = argv[i+1];
					i++;
			}
		} else {
			print_usage(argv[0]);
		}
    }

    if (sfile == NULL){ 
		fprintf(stdout, "No alma host file specified. Running Parser independently.\n");
    }
    else
      	PassiveSocket = connect_alfred(sfile);

    /* Darsana added Code here to get Alma tag once Alma has started up */
    if (PassiveSocket != -1) {
       switch (tcp_select(tcp_BLOCK, 0.0, &FD)) {
          case tcp_ERROR:
			fprintf(stdout, "tcp_ERROR.\n");
            exit(errno);
          case tcp_SUCCESS:
			fprintf(stdout, "tcp_SUCCESS.\n");
            if (FD == PassiveSocket) {
				fprintf(stdout, "PassiveSocket.\n");
                if((FD = tcp_accept(PassiveSocket)) == -1){
					fprintf(stdout, "tcp_accept(PassiveSocket)==-1.\n");
					exit(errno);
				}
                printf("Connection to %d accepted\n", FD);
				fprintf(stdout, "connection accepted.\n");
			}
		}
	}

	/* parsing each sentence until user prompts either "quit" or "exit"*/
	while (fget_input_string(input_string, stdin, stdout)) {
		if ((strcmp(input_string, "quit\n")==0) || (strcmp(input_string, "exit\n")==0)) {
			/* Darsana added code here to send quit/exit command to alfred*/
			sprintf(alma_str, "%s", "term(quit).");
			if (FD != -1) write(FD, alma_str, strlen(alma_str));

			break;
		}

		char buf[MAXINPUT];
		FILE *fp;
		char out[MAXINPUT];
		char parsed[MAXINPUT];
		strncpy(out, input_string, strlen(input_string)-1);
		out[strlen(input_string)-1] = '\0';
		sent = malloc(MAXINPUT*sizeof(Sentence));
		sent->length=0;

		// store words in sentence
		char * word;
		word = strtok (input_string," \n");
		SentNum++;
		int val = 0;
		while (word != NULL)
		{
			sent->length++;
			sent->word[val].string=word;
			word = strtok (NULL, " \n");
			val++;
		}

		//run Berkeley parser to get the part of speech tag(POS) and the parse tree
		sprintf(buf,"/bin/echo %s | java -Xmx1024m -jar ../BerkeleyParser/berkeleyParser.jar -gr ../BerkeleyParser/eng_sm6.gr",out);
		fp = popen(buf,"r");
		while(fgets(parsed,MAXINPUT,fp)!= NULL)
			fprintf(stdout, parsed);
		pclose(fp);

		char *pch1;
		pch1 = strtok (parsed," (\n");
		int j=0;
		int tagval=0;

		Tag * curTag;
		curTag = (struct Tag *)malloc(sizeof(struct Tag));
		curTag->size = 0;
		curTag->tagnum = tagval;
		curTag->parent = NULL;

		//insert utterance number
		sprintf(alma_str, "%s%d%s\n", "term(af(utterance(s", SentNum, "))).");
		if (FD != -1) write(FD, alma_str, strlen(alma_str));

		// construct utt_struct given parse
		while (pch1 != NULL && j < sent->length)
		{
			if (strstr(pch1,sent->word[j].string) != NULL) { // i.e., this token is a word
				// add value of tag
				sprintf(alma_str, "%s%d%s%d%s%d%s\n", "term(af(utt_struct(s", SentNum, ", tag", curTag->tagnum, 
						", [val", j, "]))).");
				printf("%s%d%s%d%s%d%s\n", "term(af(utt_struct(s", SentNum, ", tag", curTag->tagnum,
						", [val", j, "]))).");
				if (FD != -1) write(FD, alma_str, strlen(alma_str));
				
				// add value of word
				sprintf(alma_str, "%s%d%s%d%s%s%s\n", "term(af(value_of(s", SentNum, 
						", val", j, ", '", sent->word[j].string, "')))." );
				printf("%s%d%s%d%s%s%s\n", "term(af(value_of(s", SentNum, 
						", val", j, ", '", sent->word[j].string, "')))." );
				if (FD != -1) write(FD, alma_str, strlen(alma_str));
				
				// since we just got a word, tag was just closed
				
				// find how many tags were just closed
				int tagsClosed = strlen(pch1) - strcspn(pch1, ")");
//printf("num tags closed: %d, curTag size:%d, curTag tagnum:%d\n", tagsClosed, curTag->size, curTag->tagnum);
				
				while(tagsClosed > 0 && curTag != NULL) {
					// update this tag's utt_struct
					if (curTag->size > 0) {
						char tagstr[60] = "";
						const char *pad = "";
						int k;
						for (k = 0; k < curTag->size; k++) {
							char temp[10] = "";
							sprintf(temp, "%stag%i", pad, curTag->children[k]);
							strcat(tagstr, temp);
							pad = ", ";
						}
// TODO: special case for sentence tag (S)?
//printf("CURTAG = %d, TAGSTR = %s\n", curTag->tagnum, tagstr);
						sprintf(alma_str, "%s%d%s%d%s%s%s\n", "term(af(utt_struct(s", SentNum, ", tag", curTag->tagnum,
								", [", tagstr, "]))).");
						printf("%s%d%s%d%s%s%s\n", "term(af(utt_struct(s", SentNum, ", tag", curTag->tagnum,
								", [", tagstr, "]))).");
						if (FD != -1) write(FD, alma_str, strlen(alma_str));
					} else {
						// do nothing
						//printf("CLOSED TAG but size = %d\n",curTag->size);
					}

					// go to parent
					curTag = curTag->parent;

					tagsClosed--;
				}
				
				j++;
				if (j==sent->length) break;
			} else {	// this token is a tag
				// add as tag
				sprintf(alma_str, "%s%d%s%d%s%s%s\n", "term(af(tag(s", SentNum, ", tag", 
						tagval, ", '", pch1, "'))).");
				printf("%s%d%s%d%s%s%s\n", "term(af(tag(s", SentNum, ", tag", 
						tagval, ", '", pch1, "'))).");
				if (FD != -1) write(FD, alma_str, strlen(alma_str));
		
				// add to utt_struct
				Tag * newTag;
				newTag = (struct Tag *)malloc(sizeof(struct Tag));
				newTag->size = 0;
				newTag->parent = curTag;
				newTag->tagnum = tagval;
				
				curTag->children[curTag->size] = tagval;
				curTag->size++;
				curTag = newTag;
				tagval++;
			}
			
			// get next token
			pch1 = strtok(NULL, " (\n");
		}

		free(sent);
		sent=NULL;
		
		//insert utterance, you can leave this part as the way it is.
		sprintf(alma_str, "%s%d%s\n", "term(af(utterance(s", SentNum, "))).");
		if (FD != -1) write(FD, alma_str, strlen(alma_str));
		
		//end of parse, you can start working on this later when everything else is done.
		sprintf(alma_str, "%s%d%s\n","term(af(end_of_parse(s" , SentNum, "))).");
		if (FD != -1) write(FD, alma_str, strlen(alma_str));
		
		//dictionary_delete(dict);
	}
    return 0;
}
