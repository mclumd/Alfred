%   Package: terms
%   Author : Richard A. O'Keefe
%   Updated: 04/20/99
%   Purpose: pass terms between Prolog and C.
%   SeeAlso: terms.doc

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(terms, [
	prolog_to_c/2,
	erase_c_term/1,
	c_to_prolog/2
   ]).
:- use_module(library(types), [
	must_be_var/3,
	must_be_integer/3
   ]).

sccs_id('"@(#)99/04/20 terms.pl	76.1"').

%   To pass Prolog terms to C and back, check out the +term and -term
%   option of the Foreign Language Interface. You can also access and
%   manipulate Prolog terms in C using the QP_get/QP_put functions/macros
%   provided.

%.  It doesn't make any sense to call prolog_to_c(Term, Address) with
%   Address instantiated; that should be checked for.  If the Term is
%   too big to be copied, prolog_to_c fails quietly, without having
%   allocated any storage.  A proper error message should be produced.

%   prolog_to_c(+Term, -Address)
%   takes a Prolog term Term, copies it into the C world in prefix
%   Polish form, and then returns the Address of the copy as an integer.

prolog_to_c(Term, Address) :-
    (	nonvar(Address) ->
	must_be_var(Address, 2, prolog_to_c(Term,Address))
    ;	term_size(Term, -3, _, 0, Size),
	'QTallo'(Size, 0),
	copy_into_c(Term),
	fail
    ;	'QTaddr'(Address, 0)
    ).


%.  term_size(+Term, +Vars0, -Vars, +Size0, -Size)
%   succeeds when there are Vars0-Vars distinct unbound variables in
%   Term, and when it will take Size-Size0 cells to represent Term
%   in prefix Polish form.  The variable counter starts at -3 and
%   is decremented, so that the numbers are already right.  The size
%   starts at 0, and is incremented.  This is much like numbervars/3.
%   term_size/5 binds the variables so that copy_into_c will have an
%   easy time of it, but the term isn't supposed to be changed in
%   the long run, so prolog_to_c fails back over the whole lot.

term_size('$VAR'(V0), V0, V, Size0, Size) :- !,
	V is V0-1,
	Size is Size0+1.
term_size(Term, V0, V, Size0, Size) :-
	Size1 is Size0+2,
	functor(Term, _, N),
	term_size(N, Term, V0, V, Size1, Size).

term_size(0, _, V, V, Size, Size) :- !.
term_size(N, Term, V0, V, Size0, Size) :-
	arg(N, Term, Arg),
	term_size(Arg, V0, V1, Size0, Size1),
	M is N-1,
	term_size(M, Term, V1, V, Size1, Size).


%.  copy_into_c(Term)
%   takes a term which has had its variables replaced by $VAR(V)
%   and flattens it into prefix Polish, calling QTpsh? routines
%   to push suitable words into the memory block we've allocated.
%   Note that QTpshV pushes one word, all the other QTpsh? routines
%   push two words.  We want, as usual, to minimise the number of C
%   calls, and do as much as possible in each call.

copy_into_c('$VAR'(V)) :- !,
	'QTpshV'(V).
copy_into_c(Term) :-
	atomic(Term),
	!,
	(   float(Term)   -> 'QTpshF'(Term)
	;   integer(Term) -> 'QTpshI'(Term)
	;   atom(Term)    -> 'QTpshA'(Term, 0)
	).
copy_into_c(Term) :-
	functor(Term, F, N),
	'QTpshA'(F, N),
	copy_into_c(1, Term, N).

copy_into_c(N, Term, N) :- !,
	arg(N, Term, Arg),
	copy_into_c(Arg).
copy_into_c(I, Term, N) :-
	arg(I, Term, Arg),
	copy_into_c(Arg),
	J is I+1,
	copy_into_c(J, Term, N).


%   Some fine points about c_to_prolog(Address, Term):
%   (1) We have no idea whether the Address points to a Polish form
%   that was created by prolog_to_c or to something that C code made
%   up.  It doesn't matter.  It is checked that the argument is an
%   integer, but that's all the checking done.
%   (2) It is currently the case in Quintus Prolog that you can free
%   a record and then use it, but only if you don't allocate any more
%   memory while you're examining the corpse.  This is because the C
%   function free() doesn't erase the freed storage.  Perhaps there
%   should be an operation combining c_to_prolog/2 and erase_c_term/1.
%   (3) While copying a Polish term to Prolog, we maintain a sparse
%   An extremely interesting point is the way we maintain a sparse
%   half-infinite "array" mapping variable numbers to variables; if
%   the variable numbers in the term have a reasonable range this
%   will work pretty well, and it isn't limited to some maximum
%   number of variables.

%   c_to_prolog(+Address, ?Term)
%   unifies Term with a new copy of the term represented in prefix
%   Polish form at the address encoded as the integer Address.  It
%   is the converse of prolog_to_c.

c_to_prolog(Address, Term) :-
	(   integer(Address) ->
	    'QTinit'(Address),
	    copy_from_c(Datum, _),
	    Term = Datum
	;   must_be_integer(Address, 1, c_to_prolog(Address,Term))
	).


%.  copy_from_c(-Term, +Vars)
%   constructs the next term from the prefix Polish thingy pointed
%   to by the variable "p" in terms.c, and advances "p" over that
%   term.  Vars is a 4-way tree mapping variable numbers to variables.
%   Note that QTpshA pushes an atom and an arity both, but coming back
%   the other way we have already picked up the arity, so QTnxtA just
%   picks up the atom code.

copy_from_c(Term, Vars) :-
	'QTnxtI'(N),
	(   N > 0 ->
	    'QTnxtA'(F),
	    functor(Term, F, N),
	    copy_from_c(1, Term, N, Vars)
	;   N < -2 ->
	    V is -3-N,
	    var_entry(V, Vars, Term)
	;   N =:= 0 ->
	    'QTnxtA'(Term)
	;   N =:= -1 ->
	    'QTnxtI'(Term)
	; /*N =:= -2 */
	    'QTnxtF'(Term)
	).

copy_from_c(N, Term, N, Vars) :- !,
	arg(N, Term, Arg),
	copy_from_c(Arg, Vars).
copy_from_c(I, Term, N, Vars) :-
	arg(I, Term, Arg),
	copy_from_c(Arg, Vars),
	J is I+1,
	copy_from_c(J, Term, N, Vars).


%   A variable table is a tree made up of 5-element records:
%	$(ThisVar,S0,S1,S2,S3)
%   where ThisVar is the variable associated with this node,
%   and S0..S3 are the sons of the node.  As this predicate
%   is only used in this module, we rely on N being >= 0.
%   To understand this better, you might like to look at the
%   related "array" package library(logarr).  There is a
%   reason why the unfication for Node is done in the body
%   rather than the head; can you see what that reason is?

var_entry(N, Node, Var) :-
	Node = $(V,_,_,_,_),
	(   N =:= 0 -> Var = V
	;   K is (N/\3)+2,
	    arg(K, Node, Son),
	    M is (N-1)>>2,
	    var_entry(M, Son, Var)
	).


%   erase_c_term(+Address)
%   releases the space occupied by the prefix Polish term stored at Address.
%   (C data structures are not garbage collected, and need explicit freeing.)

foreign('QTfree', erase_c_term(+address(long))).


foreign('QTallo', 'QTallo'(+integer,[-integer])).
foreign('QTaddr', 'QTaddr'(-address(long),[-integer])).
foreign('QTpshV', 'QTpshV'(+integer)).
foreign('QTpshF', 'QTpshF'(+double)).
foreign('QTpshI', 'QTpshI'(+integer)).
foreign('QTpshA', 'QTpshA'(+atom,+integer)).
foreign('QTinit', 'QTinit'(+address(long))).
foreign('QTnxtI', 'QTnxtI'([-integer])).
foreign('QTnxtA', 'QTnxtA'([-atom])).
foreign('QTnxtF', 'QTnxtF'([-double])).

foreign_file(library(system(libpl)), [
	'QTallo', 'QTaddr', 'QTfree',
	'QTpshV', 'QTpshF', 'QTpshI', 'QTpshA',
	'QTinit', 'QTnxtF', 'QTnxtI', 'QTnxtA'
]).


:- load_foreign_executable(library(system(libpl))),
   abolish([foreign_file/2, foreign/2]).

end_of_file.

%   TEST CODE

/*  As a test,  cdisplay/1 was benchmarked against display/1,
    writing the term given by data(_).  This term has also been
    used to check that c_to_prolog works.
*/

foreign(printerm, printerm(+address(long))).

cdisplay(X) :-
	prolog_to_c(X, A),
	erase_c_term(A),
	printerm(A), nl.

data((bench_mark(Name) :-
	bench_mark(Name,Iterations,Action,Control), 
	get_cpu_time(T0),
	(   repeat(Iterations), call(Action), fail
	;   get_cpu_time(T1)
	),
	(   repeat(Iterations), call(Control), fail
	;   get_cpu_time(T2)
	),
	write(Name), write(' took '), report(Iterations,T0,T1,T2)
)).


/*  The times were

	display	: 42 milliseconds
	cdisplay: 52 milliseconds
	printerm: 13 milliseconds

    We see that the time to needed for prolog_to_c and erase_c_term on
    this particular hairy thing was 39 milliseconds.  Given that
    display spends most of its time traversing the structure, calling
    C to print tokens, while prolog_to_c traverses the structure twice,
    in the second pass calling a C routine for each node in the tree,
    it isn't surprising that the times are so similar.  The difference
    is that prolog_to_c **could** be supported by low-level code, with
    essentially no C procedure calls.  So could c_to_prolog.
*/

