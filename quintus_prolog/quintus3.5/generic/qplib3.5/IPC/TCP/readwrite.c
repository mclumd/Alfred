/* SCCS:	@(#)readwrite.c	76.2 12/10/98
   Author: 	Anil Nair
   Purpose: 	Support for efficient reading and writing of terms

   Update:	tail recursion optimisation has been implemented in
		functions that traverse terms recursively. This alleviates
		a problem with very long lists overflowing the C stack.
*/

#include <memory.h>
#include "quintus.h"

/* DEFINITIONS */

typedef struct atom_node {
    struct atom_node * next;
    QP_atom old_atom_num;
    int new_atom_num;
    char * atom_string;
    int  atom_size;
    struct atom_node * next_atom;
} Atom_Node, *P_Atom_Node;

P_Atom_Node * atable;
int amask;
int apop;
int total_size_of_atoms = 0;
int atom_count = 0;
P_Atom_Node last_atom;
P_Atom_Node first_atom;

#define swap(i)	(i = (swapping ? ((((i)<<24) & 0xff000000) | \
				  (((i)<< 8) & 0x00ff0000) | \
				  (((i)>> 8) & 0x0000ff00) | \
				  (((i)>>24) & 0x000000ff))  \
		      : i))

#define hash(key, mask)		((key & mask) >> 2)

#define SIZE_OF_BUCKET	4

#define QP_ATOM_1	7	/* (if atom number < 256) */

/* ----------------------------------------------------------------------
   init_hash_table;

   Initialize the hashtable.
   ---------------------------------------------------------------------- */

void init_hash_table()
    {
	P_Atom_Node * curr_table = atable;
	P_Atom_Node bucket, nextb;
#if 0                           /* [PM] 3.5 unused */
	int i;
#endif /* unused */

	if (atable) {
	    int num = (amask + SIZE_OF_BUCKET) >> 2;
	    int n;

	    for (n = 0; n < num; n++) {
		for (bucket = curr_table[n]; bucket != 0; bucket = nextb) {
		    nextb = bucket->next;
		    QP_free(bucket);
		}
	    }
	    QP_free(curr_table);
	}
	apop = 0;
	last_atom = (P_Atom_Node) 0;
	first_atom = (P_Atom_Node) 0;
	atom_count = 0;
	total_size_of_atoms = 0;
	atable = (P_Atom_Node *) QP_malloc(16*sizeof(P_Atom_Node *));
	amask = 60;
	memset((char *) atable, 0, 16*sizeof(P_Atom_Node *));
    }

/* ----------------------------------------------------------------------
   intern_atom(atom)
    
   Insert a new entry into the hash table. The table might be expanded.
   ---------------------------------------------------------------------- */

void atom_insert(node)
    P_Atom_Node node;
    {
	P_Atom_Node * curr_table = atable;	
	int h, n, num;
	int size0, size;
	P_Atom_Node bucket, nextb;
	P_Atom_Node * new_table;
	P_Atom_Node * old_table;

	/*  make sure hash table is big enough to accept a new entry.  */

	if ((apop + 1) > ((amask >> 2) + 1)) {
	    size0 = amask + SIZE_OF_BUCKET;
	    size  = size0<<1;
	    num = size0 >> 2;
	    new_table = (P_Atom_Node *) QP_malloc(size);
	    memset((char *) new_table, 0, size);
	    amask = size - SIZE_OF_BUCKET;	/* resets amask  */
	    for (n = 0; n < num; n++) {
		for (bucket = curr_table[n]; bucket != 0; bucket = nextb) {
		    h = hash((bucket->old_atom_num >> 1), amask);
		    nextb = bucket->next;
		    bucket->next = new_table[h];
		    new_table[h] = bucket;
		}
	    }
	    old_table = curr_table;
	    curr_table = new_table;
	    QP_free(old_table);
	}
	
	h = hash((node->old_atom_num>>1), amask); /*Table may have expanded!*/

	node->next = curr_table[h];
	curr_table[h]  = node;	/* reset table itself */
	apop += 1;			/* increment apop */
	if (last_atom) {
	    last_atom->next_atom = node;
	    last_atom = node;
	} else {
	    first_atom = node;
	    last_atom = node;
	}
	atable = curr_table;
    }

/* ----------------------------------------------------------------------
    lookup_atom(key)

    Looks up a node given a key
   ---------------------------------------------------------------------- */

int lookup_atom(key)
    QP_atom key;
    {
	P_Atom_Node p = atable[hash((key>>1),amask)];

	while (p != 0) {
	    if (p->old_atom_num == key) {
		return p->new_atom_num;
	    }
	    p = p->next;
	}
	return -1;

    }

int intern_atom(atom)
    QP_atom atom;
    {
	P_Atom_Node anode;
	P_Atom_Node p;

	for (p = atable[hash((atom>>1),amask)]; p != 0; p = p->next) {
	    if (p->old_atom_num == atom) return p->new_atom_num;
	}

	anode = (P_Atom_Node) QP_malloc(sizeof(Atom_Node));
	anode->next = (P_Atom_Node) 0;
	anode->old_atom_num = atom;
	anode->new_atom_num = atom_count; atom_count++;
	anode->atom_string = QP_string_from_atom(atom);
	anode->atom_size = QP_atomlength(anode->atom_string) + 1;
	total_size_of_atoms += anode->atom_size;
	anode->next_atom = (P_Atom_Node) 0;
	atom_insert(anode);
	return anode->new_atom_num;
    }

/* ----------------------------------------------------------------------
   copy_all_atoms
   display_atom_table
   
   ---------------------------------------------------------------------- */

char * copy_all_atoms(mem)
    char * mem;
    {
	P_Atom_Node p;

	for (p = first_atom; p != (P_Atom_Node) 0; p = p->next_atom) {
	    (void) strcpy((char *) mem, p->atom_string);
	    mem += p->atom_size;
	}
	return mem;
    }

/* [PM] 3.5 was missing both return type and argument list. This
   function is not called (debug?). */
void
display_atom_table(void)
    {
	P_Atom_Node * curr_table = atable;
	P_Atom_Node bucket;

	if (atable) {
	    int num = (amask + SIZE_OF_BUCKET) >> 2;
	    int n;

	    for (n = 0; n < num; n++) {
		bucket = curr_table[n];
		QP_printf("Table entry %d\n", n);
		while (bucket != 0) {
		    QP_printf("Bucket: %d %d\n",
			      bucket->old_atom_num,
			      bucket->new_atom_num);
		    bucket = bucket->next;
		}
	    }
	} else {
	    QP_printf("Table is empty\n");
	}
    }

/* Prolog terms are stored in C in contiguous memory as follows:

   ----------------------------------------------------------------------
   | number of	| # of  | atom  |Elem1	| Elem2	| Elem3	| Elem4	| Elem5	|
   | variables	| atoms	|strings|	|	|	|	|	|
   ----------------------------------------------------------------------

   Each Element has a type and a value. The types are QP_INTEGER,
   QP_ATOM, QP_FLOAT, QP_VARIABLE and QP_COMPOUND.
   And the corresponding values are integers, atom indices, floats,
   variable indices and name-arity pairs.

   A compound term is stored in prefix notation.

   e.g. foo(1, g(A, 2, bar, B), A) is stored as

   1 (number of variables),
   3 (number of atoms)
   bar, foo, g
   QP_COMPOUND/foo,1 (name,arity),
   QP_INTEGER /1
   QP_COMPOUND/g,2 (name,arity)
   QP_VARIABLE/1   (variable index)
   QP_INTEGER /2
   QP_VARIABLE/2   (variable index)
   QP_VARIABLE/1   (variable index)
*/

int size_of_elements(term, varlist)
    QP_term_ref term;
    QP_term_ref varlist;
    {
#if 0                           /* [PM] 3.5 unused */
      int int_val;
#endif /* unused */
        int index;
	QP_atom atom;
	int size = 0;

    again:
	switch (QP_term_type(term)) {
	  case QP_INTEGER:
	    size += sizeof(int) + sizeof(char);
	    break;
	  case QP_ATOM:
	    QP_get_atom(term, &atom);
	    index = intern_atom(atom);
	    if (index < 256) {
		size += sizeof(char) + sizeof(char);	/* for atom index */
	    } else {
		size += sizeof(int) + sizeof(char);	/* for atom index */
	    }
	    break;
	  case QP_FLOAT:
	    size += sizeof(double) + sizeof(char); 	/* for double value */
	    break;
	  case QP_COMPOUND:
		{
		    QP_term_ref arg = QP_new_term_ref();
		    QP_atom name;
		    int i, arity;

		    size += sizeof(int) + sizeof(char); /* name and arity */
		    QP_get_functor(term, &name, &arity);
		    index = intern_atom(name);
		    for (i = 1; i < arity; i++) {
			QP_get_arg(i, term, arg);
			size += size_of_elements(arg, varlist);
		    }
		    /* tail recursion optimization */
		    QP_get_arg(arity, term, term);
		    goto again;
		}
	  case QP_VARIABLE:
	    QP_cons_list(varlist, term, varlist);
	    size += sizeof(int) + sizeof(char); /* for variable index */
	    break;
	  default:
	    QP_printf("Dont know term type %d\n", QP_term_type(term));
	    return 0;
	}

	return size;
    }


int traverse_term(term, varlist)
    QP_term_ref term;
    QP_term_ref varlist;
    {
	int size;
	QP_put_atom(varlist, QP_atom_from_string("[]"));
	
	size = size_of_elements(term, varlist);

	size = size + 16 + total_size_of_atoms;
		/* one word for num_of_atoms,
		   one word for num_of_variables,
		   one word to write the swap word
		   one word to record the size of the term */
	return size;
    }

/* term_to_skeleton(+term, +varassoc, +no_of_vars, +mem, +size)
   
   'term' which has 'no_of_vars' variables 
   is stored at memory starting at 'mem'. 'varassoc' is an assoc list 
   of all the distinct variables in 'term'. Each of these distinct
   variables is associated with an unique integer index.
   'mem' is expected to have enough memory. The amount of memory 
   required to store term can be determined by calling traverse_term().

   term_to_skel(+term, +varassoc, +pred)

   global variable 'elem' points to an array of Elements which gets
   filled with the prefix representation of Term. 'elem' is set to the
   first location after. If we come across a variable while traversing
   the subterms, then we call the Prolog predicate, find_index/3
   with 'varassoc' and the variable as argument to get back an index
   for that variable which gets saved. If we come across a
   atom while traversing the subterms, then we call lookup_atom()
   to get back an index for that atom which gets saved.
   term_to_skel() is recursive.
*/

unsigned char * elem;

void term_to_skel();

void term_to_skeleton(term, varassoc, no_of_vars, mem, size)
    QP_term_ref term, varassoc;
    int no_of_vars;
    char * mem;
    int size;
    {
#if 0                           /* [PM] 3.5 */
      QP_atom atom;
#endif /* unused */

	QP_pred_ref pred = QP_predicate("find_index",3,"read_write");
	int no_of_atoms;
	long int swapword = 0x01020304;

	no_of_atoms = apop;

	if (pred == QP_BAD_PREDREF) {
	    QP_printf("find_index/3 is not callable\n");
	    return;
	}

	memcpy(mem, (char *) &swapword, sizeof(int));
	mem += sizeof(int);
	memcpy(mem, (char *) &size, sizeof(int));
	mem += sizeof(int);

	memcpy(mem, (char *) &no_of_vars, sizeof(int));
	mem += sizeof(int);
	memcpy(mem, (char *) &no_of_atoms, sizeof(int));
	mem += sizeof(int);

	mem = copy_all_atoms(mem);
	elem = (unsigned char *) mem;
	term_to_skel(term, varassoc, pred);
    }

void term_to_skel(term, varassoc, pred)
    QP_term_ref term;
    QP_term_ref varassoc;
    QP_pred_ref pred;
    {
	char type;
	int index;
	long int_val;
	double float_val;
	QP_atom atom;

    again:
	switch (type = QP_term_type(term)) {
	  case QP_INTEGER:
	    QP_get_integer(term, &int_val);
	    *elem = QP_INTEGER; elem++;
	    memcpy(elem, (char *) &int_val, sizeof(int));
	    elem += sizeof(int);
	    break;
	  case QP_ATOM:
	    QP_get_atom(term, &atom);
	    index = lookup_atom(atom);
	    if (index < 256) {
		*elem = QP_ATOM_1; elem++;
		*elem = index; elem++;
	    } else {
		*elem = QP_ATOM; elem++;
		memcpy(elem, (char *) &index, sizeof(int));
		elem += sizeof(int);
	    }
	    break;
	  case QP_FLOAT:
	    *elem = type; elem++;
	    QP_get_float(term, &float_val);
	    memcpy(elem, (char *) &float_val, sizeof(double));
	    elem += sizeof(double);
	    break;
	  case QP_COMPOUND:
	    {
		int arity, i;
		QP_term_ref arg = QP_new_term_ref();
		QP_atom name;
		
		*elem = type; elem++;
		QP_get_functor(term, &name, &arity);
		index = lookup_atom(name);
		index = ((arity << 24) + index);
		memcpy(elem, (char *) &index, sizeof(int));
		elem += sizeof(int);
		for (i = 1; i < arity; i++) {
		    QP_get_arg(i, term, arg);
		    term_to_skel(arg, varassoc, pred);
		}
		/* tail recursion optimization */
		QP_get_arg(arity, term, term);
		goto again;
	    }
	  case QP_VARIABLE:
	    {
#ifdef ALPHA
	      long tmp_index;
	      if (QP_query(pred, varassoc, term, &tmp_index) != QP_SUCCESS) {
		QP_printf("Couldnt lookup variable\n");
		index = 0;
	      }
	      index = (int)tmp_index;
#else
	      if (QP_query(pred, varassoc, term, &index) != QP_SUCCESS) {
		QP_printf("Couldnt lookup variable\n");
		index = 0;
	      }
#endif
	      *elem = QP_VARIABLE; elem++;
	      memcpy(elem, (char *) &index, sizeof(int));
	      elem += sizeof(int);
	      break;
	    }
	  default:
	    QP_printf("Dont know how to store term of type %d\n", type);
	    break;
	}
    }

/*
   skeleton_to_term(+mem, -term)
   
   'mem' points to a sequence of Elements which is the prefix
   notation of a term and has been stored by term_to_skeleton().
   skeleton_to_term() converts it back into a Prolog term.

   skel_to_term(-term)

   Global variable 'elem' points to a sequence of Elements.
   skel_to_term interprets this prefix sequence and creates a term from it.

   If we find a variable, and it is the first time we see the
   variable with that index say 'i', we create a new variable and keep
   a reference to that variable in vars[i]. Subsequent occurences
   of a variable with index 'i' will result in a new variable
   created which is unified with vars[i].
*/

QP_term_ref * vars;
QP_atom * atoms;

void skel_to_term();

void skeleton_to_term(mem, term)
    char * mem;
    QP_term_ref term;
    {
	int num_of_atoms, num_of_vars;
	int i;
	int size;
	int swapword, swapping;

	memcpy((char *) &swapword, mem, sizeof(int));
	swapping = (swapword == 0x04030201);
	mem += sizeof(int);
       
	memcpy((char *) &size, mem, sizeof(int)); 
	swap(size);
	mem += sizeof(int);
	
	memcpy((char *) &num_of_vars, mem, sizeof(int));
	swap(num_of_vars);
	mem += sizeof(int);
	memcpy((char *) &num_of_atoms, mem, sizeof(int));
	swap(num_of_atoms);
	mem += sizeof(int);

	vars = (QP_term_ref *) QP_malloc(num_of_vars * sizeof(QP_term_ref));
	memset(vars, 0, num_of_vars * sizeof(QP_term_ref));
	atoms = (QP_atom *) QP_malloc(num_of_atoms * sizeof(QP_atom));
	memset(atoms, 0, num_of_atoms * sizeof(QP_atom));

	for (i = 0; i < num_of_atoms; i++) {
	    atoms[i] = QP_atom_from_string(mem);
	    mem += (strlen(mem)+1);
	}
	elem = (unsigned char *) mem;
	QP_put_variable(term);
	(void) skel_to_term(term, swapping);
	QP_free(vars);
	QP_free(atoms);
    }

void skel_to_term(term, swapping)
    QP_term_ref term;
    register int swapping;
    {
	char type;
	int int_val;
	unsigned int index;
	double float_val;
	QP_term_ref nextterm = QP_new_term_ref();

    again:
	type = *elem;
	elem += sizeof(char);
	switch (type) {
	  case QP_INTEGER:
	    memcpy((char *) &int_val, elem, sizeof(int));
	    swap(int_val);
	    elem += sizeof(int);
	    QP_put_integer(nextterm, int_val);
	    break;
	  case QP_ATOM:
	    memcpy((char *) &index, elem, sizeof(int));
	    swap(index);
	    elem += sizeof(int);
	    QP_put_atom(nextterm, atoms[index]);
	    break;
	  case QP_ATOM_1:
	    index = *elem; elem++;
	    QP_put_atom(nextterm, atoms[index]);
	    break;
	  case QP_FLOAT:
	    if(swapping){
	      unsigned char * s = elem;
	      unsigned char * t = (unsigned char *) &float_val;
	      t[0] = s[7];
	      t[1] = s[6];
	      t[2] = s[5];
	      t[3] = s[4];
	      t[4] = s[3];
	      t[5] = s[2];
	      t[6] = s[1];
	      t[7] = s[0];
	    } else memcpy((char *) &float_val, elem, sizeof(double));
	    elem += sizeof(double);
	    QP_put_float(nextterm, float_val);
	    break;
	  case QP_VARIABLE:
	    QP_put_variable(nextterm);
	    memcpy((char *) &index, elem, sizeof(int));
	    swap(index);
	    elem += sizeof(int);
	    if (vars[index]) {
		/* All variables with the same index have to be unified */
		QP_unify(nextterm, vars[index]);
	    } else {
		/* The first time this variable index has been encountered */
		vars[index] = QP_new_term_ref();
		QP_put_term(vars[index],nextterm);
	    }
	    break;
	  case QP_COMPOUND:
		{
		    QP_term_ref arg = QP_new_term_ref();
		    int i, arity;

		    memcpy((char *) &index, elem, sizeof(int));
		    swap(index);
		    elem += sizeof(int);
		    arity = index>>24;
		    QP_put_functor(nextterm, atoms[index&0x00ffffff],arity);
		    for (i = 1; i < arity; i++) {
			QP_get_arg(i, nextterm, arg);
			skel_to_term(arg, swapping);
		    }
		    /*  tail recursion optimization  */
		    QP_get_arg(arity, nextterm, arg);
		    QP_unify(term, nextterm);	/* unify term with functor */
		    term = arg;			/* then set it to last arg */
		    goto again;
		}
	  default:
	    QP_printf("Dont know how to get term of type %d\n", type);
	    break;
	}

	QP_unify(term, nextterm);
    }

int write_buffer_to_stream(stream, buf, size)
    QP_stream * stream;
    char * buf;
    int size;
    {
	int stat = QP_fwrite(buf, size, 1, stream);
	if (stat >= 0) {
	    stat = QP_flush(stream);
	}
	if (stat >= 0) {
	    return stat;
	} else {
	    return -(QP_errno);
	}
    }

int read_stream_to_buffer(stream, address)
    QP_stream * stream;
    char ** address;
    {
	int size;
	int swapword, swapping;
	int stat = QP_fread((char *)&swapword, sizeof(int), 1, stream);

	if (stat == 0) return 0;
	if (stat > 0) {
	    if (swapword == 0x7465726d || swapword == 0x6d726574)
		return 1;	/* "term" - signal text term to follow  */
	    else if (swapword == 0x01020304)
		swapping = 0;	/*  encoded term, not swapped  */
	    else if (swapword == 0x04030201)
		swapping = 1;	/*  encoded term, swapped  */
	    else
		return 0;	/* garbage - signal eof */

	    stat = QP_fread((char *)&size, sizeof(int), 1, stream);
	    
	    if (stat == 0) return 0;
	    if (stat > 0) {
		swap(size);
		if ((*address = (char *) QP_malloc(size+2*sizeof(int)))
		    != NULL) {
		    *((int *) *address) = swapword;
		    *((int *) *address+1) = size;
		    stat = QP_fread(*address+2*sizeof(int),size-2*sizeof(int),
				    1,stream);
		} else {
		    return -(QP_E_NOMEM);
		}
	    }
	    if (stat == 0) return 0;
	    if (stat > 0) {
		return 2;	/*  encoded term read into buffer  */
	    } else {
		return -(QP_errno);
	    }
	} else {
	    return -(QP_errno);
	}
    }
