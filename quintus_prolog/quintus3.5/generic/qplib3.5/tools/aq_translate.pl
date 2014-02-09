%   File   : translate.pl
%   Author : Richard A. O'Keefe
%   Updated: 03 Jun 1990
%   Purpose: Convert Arity rule bodies to Prolog rule bodies.

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/*  This file exports a single predicate:

	translate(+Arity, -Quintus)

    It takes the body of a clause which was written in Arity/Prolog and
    tries to convert it to Quintus Prolog.  Sometimes this can be done
    exactly.  Sometimes it can be done with the aid of ordinary Quintus
    library predicates.  Sometimes it can be done with the aid of some
    library predicates which were written just for this purpose.  Some
    things can be approximated (such as strings).  And some things just
    cannot be done.  The rule is that we print an error message to the
    user_error stream whenever a translation cannot be done properly.
    Currently, error reporting is pretty feeble.  Later we shall want to
    identify the source line where the clause started and identify the
    clause.  Time enough for that later.

    Each rule in this file is preceded by the section number and page
    number in "The Arity/Prolog Language Reference Manual" (1988) which
    justifies it.  Sometimes I am not sure what something does.

*/

%   Prevent infinite loops

translate(X, G) :-
	(   var(X) -> G = X
	;   number(X) -> G = X,
	    aq_error('Number ~w appeared as goal', [X])
	;   trans(X, G)
	).

%   Section 1.3 Page 8

trans((A, B), (A1, B1)) :- !,
	translate(A, A1),
	translate(B, B1).

trans((A ; B), (A1 ; B1)) :- !,
	translate(A, A1),
	translate(B, B1).

trans(!, !) :- !.

trans(once(A), (A1 -> true)) :- !,	% source form was [! A !]
	translate(A, A1).		% See section 1.3.6 page 16

trans(call(A), A2) :- !,
	(   var(A) -> A2 = call(A)
	;   translate(A, A2)
	).

%   Section 1.3 Page 9
/*  Note:  not(X) in Arity/Prolog is identical to \+(X).  In DEC-10
    Prolog not(X) was a library predicate which checked that X was
    ground, and that's the way it is in Quintus Prolog too, so we
    have to translate not(X) to \+(X).
*/
trans(not(A), \+(A1)) :- !,
	translate(A, A1).

trans(\+(A), \+(A1)) :- !,
	translate(A, A1).

trans(and(A,B), (A1, B1)) :- !,
	translate(A, A1),
	translate(B, B1).

trans(or(A,B), (A1 ; B1)) :- !,
	translate(A, A1),
	translate(B, B1).

trans(true, true) :- !.

trans(fail, fail) :- !.

trans(repeat, repeat) :- !.

trans(ifthen(A,B), (A1 -> B1 ; fail)) :- !,
	translate(A, A1),
	translate(B, B1).

trans(ifthenelse(A,B,C), (A1 -> B1 ; C1)) :- !,
	translate(A, A1),
	translate(B, B1),
	translate(C, C1).

trans(case(Cases), Ifs) :- !,
	trans_cases(Cases, Ifs).

trans(abort, abort) :- !.

%   Section 1.3  Page 9

trans(break, break) :- !.

%   Section 2.2  Page 25

trans(E > F, G) :- !,
	expr(E, E1, L0, L1),
	expr(F, F1, L1, [E1 > F1]),
	list_to_code(L0, G).

trans(E =< F, G) :- !,
	expr(E, E1, L0, L1),
	expr(F, F1, L1, [E1 =< F1]),
	list_to_code(L0, G).

trans(E < F, G) :- !,
	expr(E, E1, L0, L1),
	expr(F, F1, L1, [E1 < F1]),
	list_to_code(L0, G).

trans(E >= F, G) :- !,
	expr(E, E1, L0, L1),
	expr(F, F1, L1, [E1 >= F1]),
	list_to_code(L0, G).

trans(E =:= F, G) :- !,
	expr(E, E1, L0, L1),
	expr(F, F1, L1, [E1 =:= F1]),
	list_to_code(L0, G).

trans(E =\= F, G) :- !,
	expr(E, E1, L0, L1),
	expr(F, F1, L1, [E1 =\= F1]),
	list_to_code(L0, G).

trans(V is F, G) :- !,
	(   var(V)    -> expr(F, F1, L0, [V is F1])
	;   number(V) -> expr(F, F1, L0, [V is F1])
	;   aq_error('Strange term on lhs of 'is': ~q', [V]),
	    L0 = [V is F]
	),
	list_to_code(L0, G).

trans(randomize(X), arity_randomise(X)) :- !.

trans(inc(X,Y), Y is X+1) :- !.

trans(dec(X,Y), Y is X-1) :- !.

%   Section 2.3  Page 26

trans(ctr_set(Ctr,N), ctr_set(Ctr,N)) :- !,
	need_library(ctr).

trans(ctr_dec(Ctr,N), ctr_dec(Ctr,1,N)) :- !,
	need_library(ctr).

trans(ctr_inc(Ctr,N), ctr_inc(Ctr,1,N)) :- !,
	need_library(ctr).

trans(ctr_is(Ctr,N), ctr_is(Ctr,N)) :- !,
	need_library(ctr).

%   Section 3.1  Page 30

trans(atom(X),	  atom(X)) :- !.
trans(integer(X), integer(X)) :- !.
trans(float(X),	  float(X)) :- !.
trans(number(X),  number(X)) :- !.
trans(string(X),  atom(X)) :- !, string_warning.
trans(ref(X),	  arity_ref(X)) :- !.
trans(atomic(X),  atomic(X)) :- !.
trans(var(X),	  var(X)) :- !.
trans(nonvar(X),  nonvar(X)) :- !.

%   Section 3.2  Page 31

trans(X=Y,     X=Y) :- !.
trans(\=(X,Y), ( X = Y -> fail ; true )) :- !.

%   Section 3.3  Page 33

/*  AWOO!  There is a ***BIG*** ***BUG*** in Arity/Prolog's definition
    of term comparison:  X == Y is supposed to mean that X and Y are
    absolutely identical in every possible way that a Prolog program
    can detect.  In particular, a programmer is entitled to trust the
    following axioms
	if X == Y, then it is already the case that X = Y
	if X \= Y, then it will never be the case that X == Y.
    Arity/Prolog violates both of these, for no good reason.  (Note
    that the Quintus strings library provides *separate* comparison
    predicates which regard strings and atoms as the same.)  Try
	$a$ == a, this succeeds but $a$ = a fails.
	$b$ \= b, this succeeds but so does $b$ == b.
    Because this version of Quintus Prolog does not support strings,
    $a$ will be read as the atom 'a', so $a$==a will succeed, as you
    will have come to expect in Arity/Prolog, but so will $a$ = a
    succeed.

    Note that it is IMPOSSIBLE to implement eq(X,Y) in Quintus Prolog;
    that would block some important optimisations.
*/
trans(X == Y, X == Y) :- !.
trans(X\== Y, X\== Y) :- !.
trans(X @< Y, X @< Y) :- !.
trans(X @>=Y, X @>=Y) :- !.
trans(X @> Y, X @> Y) :- !.
trans(X @=<Y, X @=<Y) :- !.
trans(eq(X,Y),X == Y) :- !,
	ac_error('eq/2 cannot be simulated', []).
trans(compare(R,X,Y),	compare(R,X,Y)) :- !.
trans(sort(X,Y),	sort(X,Y)) :- !.
trans(keysort(X,Y),	keysort(X,Y)) :- !.

%   Section 3.4  Page 35

trans(T=..L,		T=..L) :- !.
trans(functor(T,F,N),	functor(T,F,N)) :- !.
trans(arg(N,T,A),	arg(N,T,A)) :- !.
trans(arg0(M,T,A),	(N is M+1, arg(N,T,A))) :- !.
trans(argrep(T,N,A,R),	arity_argrep(T,N,A,R)) :- !,
	need_library(arity).
trans(name(A,L),	name(A,L)) :- !.
trans(length(L,N),	length(L,N)) :- !.

%   Section 3.5  Page 39
/*  Arity claim that "findall ... is generally the most useful".
    That depends on whether you want something which comes close to
    having a logical reading (which setof does) or something which
    is easy to implement but nearly impossible to explain (which
    findall is).  If it would make sense for your program to use
    setof, it is nearly always a mistake to use findall.
*/

trans(X^A,	    X^A1	 ) :- !, trans(A, A1).
trans(setof(T,A,S), setof(T,A1,S)) :- !, trans(A, A1).
trans(bagof(T,A,B), bagof(T,A1,B)) :- !, trans(A, A1).
trans(findall(T,A,L), (bagof(T,A^A1,X) -> L = [] ; L = X)) :- !, trans(A, A1).

%   Section 4.1  Page 47

trans(recorda(K,T,R),	recorda(K,T,R)) :- !.
trans(recordz(K,T,R),	recordz(K,T,R)) :- !.
trans(record_after(R,T,R1), G) :- !,
	cannot_hack(record_after(R,T,R1), G).
trans(recorded(K,T,R),	recorded(K,T,R)) :- !.
trans(recorded_tro(K,T,R), recorded(K,T,R)) :- !.
trans(instance(R,T),	instance(R,T)) :- !.
trans(key(K,R),		G) :- !,
	cannot_hack(key(K,R), G).
trans(keys(K),		arity_keys(K)) :- !,
	need_library(arity).
trans(nref(R,N),	G) :- !,
	cannot_hack(nref(R,N), G).
trans(pref(R,N),	G) :- !,
	cannot_hack(pref(R,N), G).
trans(nth_ref(K,N,R),	G) :- !,
	cannot_hack(nth_ref(K,N,R), G).
trans(replace(R,T),	G) :- !,
	cannot_hack(replace(R,T), G).
trans(erase(R),		erase(R)) :- !.
trans(eraseall(Key),	(recorded(Key,_,R), erase(R), fail ; true)) :- !.
trans(expunge,		true) :- !.

%   Section 4.2  Page 55

trans(clause(H,B),	clause(H,B1)) :- !, translate(B, B1).
trans(asserta(C),	asserta(C1))  :- !, trans_clause(C, C1).
trans(assertz(C),	assertz(C1))  :- !, trans_clause(C, C1).
trans(retract(C),	retract(C1))  :- !, trans_clause(C, C1).
trans(assert(C),	assert(C1))   :- !, trans_clause(C, C1).

%   Section 4.3  Page 56

trans(listing,		listing) :- !.
trans(listing(L),	listing(L)) :- !.

%   Section 4.4  Page 59

trans(save,		save_program('arity.idb'))	:- !, save_warning.
trans(save(X),		save_program(X))		:- !, save_warning.
trans(restore,		restore('arity.idb'))	:- !, save_warning.
trans(restore(X),	restore(X))		:- !, save_warning.

%   Section 4.5  Page 60

/*  None of the 'worlds' stuff is implemented at all.  We might be
    able to hack it using modules, but we'll have to see about that.
*/

trans(create_world(A), G) :-!,
	cannot_hack(create_world(A), G).
trans(code_world(A,B), G):- !,
	cannot_hack(code_world(A,B), G).
trans(data_world(A,B), G):- !,
	cannot_hack(data_world(A,B), G).
trans(what_worlds(A), G):- !,
	cannot_hack(what_worlds(A), G).
trans(delete_world(A), G) :- !,
	cannot_hack(delete_world(A), G).

%   Section 5.1  Page 68

trans(recordb(A,B,C), G) :- !,
        cannot_hack(recordb(A,B,C), G).
trans(retrieveb(A,B,C), G) :- !,
        cannot_hack(retrieveb(A,B,C), G).
trans(betweenb(A,B,C,D,E,F,J), G) :- !,
        cannot_hack(betweenb(A,B,C,D,E,F,J), G).
trans(betweenkeysb(A,B,C,D), G) :- !,
        cannot_hack(betweenkeysb(A,B,C,D), G).
trans(defineb(A,B,C,D), G) :- !,
        cannot_hack(defineb(A,B,C,D), G).
trans(replaceb(A,B,C,D), G) :- !,
        cannot_hack(replaceb(A,B,C,D), G).
trans(removeb(A,B,C), G) :- !,
        cannot_hack(removeb(A,B,C), G).
trans(what_btrees(A), G) :- !,
        cannot_hack(what_btrees(A), G).
trans(removeallb(A), G) :- !,
        cannot_hack(removeallb(A), G).

%   Section 5.2  Page 78
/*  Why are there no equivalents of replaceb/4 and what_btrees/1
    for hash tables?
*/

trans(recordh(A,B,C), G) :- !,
        cannot_hack(recordh(A,B,C), G).
trans(retrieveh(A,B,C), G) :- !,
        cannot_hack(retrieveh(A,B,C), G).
trans(defineh(A,B), G) :- !,
        cannot_hack(defineh(A,B), G).
trans(removeh(A,B,C), G) :- !,
        cannot_hack(removeh(A,B,C), G).
trans(removeallh(A), G) :- !,
        cannot_hack(removeallh(A), G).


%   Section 6.1  Page 85
/*  Note:  I have assumed that it is ok for reading and writing to
    use Edinburgh syntax rather than Arity syntax.  It wouldn't be
    hard (in fact it'd be downright easy) to make reading use Arity
    syntax.  We'd just plug in the Arity reader we had to make anyway.
    It would be _almost_ as easy to plug in the public-domain output
    routines, but someone who is taking the trouble to port his code
    to Quintus Prolog probably doesn't mind porting his data as well,
    or trying to make them intrinsically portable.

    It really is NOT clear what Arity mean when they say that something
    writes to "the standard output device".  In UNIX, and in every
    PC C compiler I've ever seen, STANDARD input and output are fixed,
    and mean either the terminal or something else specific on the
    command line.  Arity seem to use this phrase to mean what Quintus
    and others mean by CURRENT streams.  display/1 is defined in DEC-10
    and Quintus Prolog to write to the STANDARD stream whatever the
    CURRENT stream is.  If Arity's display/1 writes to the CURRENT
    output stream, use write_canonical/1 instead (which produces 
    somewhat different output).
*/

trans(read(X),		read(X)) :- !.
trans(write(X),		write(X)) :- !.
trans(writeq(X),	writeq(X)) :- !.
trans(display(X),	display(X)) :- !.
trans(op(P,T,O),	op(P,T,O)) :- !.
trans(current_op(P,T,O),current_op(P,T,O)) :- !.
trans(reset_op,		reset_op) :- !,
	need_library(arity).


%   Section 6.2  Page 91

/*  There is a nasty problem with character input/output, which is
    that Arity have chosen to make the end-of-line character 13,
    which isn't _quite_ what MS-DOS does.  (It is quite likely that
    I have misunderstood the manual.)  To work around that, I here
    provide a **macro** is_newline(X) which replaces X by 10.  The
    same should be done in Arity/Prolog, there binding X to 13.
    For output, you should be relying on nl/0 anyway.

    We could hack get0_noecho/1 and flush/0 by doing our own character
    at a time UNIX I/O, but it's better not to.  The keyb* /2 things
    can't be hacked in any reasonable way because neither the ANSI
    standard keyboard layout, the DEC "VT-100" keyboard layout, the
    DEC "VT-200" keyboard layout, the Selectric layout, nor the
    IBM 3270 layout resembles the PC keyboard (thank God).


*/
trans(is_newline(10),	true) :- !.
trans(get0(C),		get0(C)) :- !.
trans(get(C),		get(C)) :- !.
trans(get0_noecho(C),	G) :- !,
	cannot_hack(get0_noecho(C), G).
trans(keyb(A,S),	G) :- !,
	cannot_hack(keyb(A,S), G).
trans(keyb_peek(A,S),	G) :- !,
	cannot_hack(keyb_peek(A,S), G).
trans(flush,		G) :- !,
	cannot_hack(flush, G).
trans(nl,		nl) :- !.
trans(put(E),		G) :- !,
	expr(E, E1, L0, [put(E1)]),
	list_to_code(L0, G).
trans(tab(E),		G) :- !,
	expr(E, E1, L0, [tab(E1)]),
	list_to_code(L0, G).
trans(skip(E),		G) :- !,
	expr(E, E1, L0, [skip(E1)]),
	list_to_code(L0, G).

%   Section 7  Page 97

trans(read(H,X),	read(S,X))	      :- !, h_to_s(H, S).
trans(write(H,X),	write(S,X))	      :- !, h_to_s(H, S).
trans(writeq(H,X),	writeq(S,X))          :- !, h_to_s(H, S).
trans(display(H,X),	write_canonical(S,X)) :- !, h_to_s(H, S).

trans(get0(H,C),	get0(S,C))	      :- !, h_to_s(H, S).
trans(get(H,C),		get(S,C))	      :- !, h_to_s(H, S).
trans(nl(H),		nl(S))		      :- !, h_to_s(H, S).
trans(put(H,E),		G)		      :- !, h_to_s(H, S),
	expr(E, E1, L0, [put(S,E1)]),
	list_to_code(L0, G).
trans(tab(H,E),		G)		      :- !, h_to_s(H, S),
	expr(E, E1, L0, [tab(S,E1)]),
	list_to_code(L0, G).
trans(skip(H,E),	G)		      :- !, h_to_s(H, S),
	expr(E, E1, L0, [skip(S,E1)]),
	list_to_code(L0, G).

trans(create(H,F),	open(F,write,H)) :- !,
	file_warning(create(H,F)).
trans(open(H,F,M),	open(F,Mode,H)) :-
	nonvar(M),
	access_mode(M, Mode), !,
	file_warning(open(H,F,M)).
trans(open(H,F,M),	arity_open(M,F,H)) :- !,
	need_library(arity),
	file_warning(open(H,F,M)).
trans(p_open(H,F,M),	G) :- !,
	p_open_warning,
	trans(open(H,F,M), G).
trans(close(X),		close(X)) :- !.

%   Section 7.2  Page 102

trans(seek(A,B,C,D),	arity_seek(C,B,A,D)) :- !,
	need_library(arity).

%   Section 7.3  Page 104
/*  It is very far from clear to me what these operations are supposed
    to do when the Goal is not determinate.  We are told that i/o is
    restored when the Goal "completes", but does that mean exit,
    determinate exit, failure, or some combination of them?  If these
    operations _do_ work with non-determinate Goals, and if your
    program depends on that, let us know.  We do know what to do about
    it, but it would be rather more work than this translator was
    supposed to be.
*/
trans(stdin(Input,A),
	( open(Input, read, NewInput),
	  current_input(OldInput),
	  set_input(NewInput),
	  ( A1 -> set_input(OldInput), close(NewInput)
	  ; set_input(OldInput), close(NewInput), fail
	  )
	)) :- !,
	translate(A, A1).
trans(stdout(Output,A),
	( open(Output, write, NewOutput),
	  current_output(OldOutput),
	  set_output(NewOutput),
	  ( A1 -> set_output(OldOutput), close(NewOutput)
	  ; set_output(OldOutput), close(NewOutput), fail
	  )
	)) :- !,
	translate(A, A1).
trans(stdinout(Input,Output,A),
	( open(Input, read, NewInput),
	  current_input(OldInput),
	  set_input(NewInput),
	  open(Output, write, NewOutput),
	  current_output(OldOutput),
	  set_output(NewOutput),
	  ( A1 -> set_input( OldInput),  close(NewInput),
		  set_output(OldOutput), close(NewOutput)
	  ;       set_input( OldInput),  close(NewInput),
		  set_output(OldOutput), close(NewOutput)
	  )
	)) :- !,
	translate(A, A1).

trans(filelist(F), A1) :- !,
	trans(stdout(F,listing), A1).
trans(filelist(F,L), A1) :- !,
	trans(stdout(F,listing(L)), A1).

%   Section 7.4  Page 105

trans(see(F),		see(F)) :- !.
trans(seeing(F),	seeing(F)) :- !.
trans(seen,		seen) :- !.
trans(tell(F),		tell(F)) :- !.
trans(telling(F),	telling(F)) :- !.
trans(told,		told) :- !.

trans(see_h(H),
	( H == 0 -> set_input(user_input) ; set_input(H) )	) :- !.
trans(tell_h(H),
	( H == 1 -> set_output(user_output)
	; H == 2 -> set_output(user_error)
	; set_output(H)
	) ) :- !.

%   Chapter 8.  Page 109

trans(in(A,B),		G) :- !,
	cannot_hack(in(A,B), G).
trans(out(A,B),		G) :- !,
	cannot_hack(out(A,B), G).

%   Chapter 9.  Page 114

trans(string_search(A,B,C),	string_search(A,B,C)) :- !,
	string_warning, need_library(arity_strings).
trans(string_search(A,B,C,D),	string_search(A,B,C,D)) :- !,
	string_warning, need_library(arity_strings).
trans(substring(A,B,C,D),	arity_substring(A,B,C,D)) :- !,
	string_warning, need_library(arity_strings).
trans(nth_char(A,B,C),		nth_char(A,B,C)) :- !,
	string_warning, need_library(arity_strings).
trans(string_length(A,B),	string_length(A,B)) :- !,
	string_warning, need_library(arity_strings).
trans(concat(A,B,C),		concat(A,B,C)) :- !,
	string_warning, need_library(arity_strings).
trans(concat(A,B),		concat(A,B)) :- !,
	string_warning, need_library(arity_strings).
trans(string_term(A,B),		string_term(A,B)) :- !,
	string_warning, need_library(arity_strings).
trans(atom_string(A,B),		atom_string(A,B)) :- !,
	string_warning, need_library(arity_strings).
trans(int_text(A,B),		int_text(A,B)) :- !,
	string_warning, need_library(arity_strings).
trans(float_text(A,B,C),	float_text(A,B,C)) :- !,
	string_warning, need_library(arity_strings).
trans(list_text(A,B),		list_text(A,B)) :- !,
	string_warning, need_library(arity_strings).
trans(read_string(A,B),		read_string(A,B)) :- !,
	string_warning, need_library(arity_strings).
trans(read_string(A,B,C),	read_string(A,B,C)) :- !,
	string_warning, need_library(arity_strings).
trans(read_line(A,B),		read_line(A,B)) :- !,
	string_warning, need_library(arity_strings).


%   Chapter 10.  Page 123.
/*  We could approximate the text window stuff quite well with the
    aid of the UNIX "curses" package.  However, the {get,set}_cursor/2
    stuff and the "attributes" are peculiar to IBM PCs.  Also, these
    operations are usually used together with keyb/2, whose scan codes
    are again peculiar to IBM PCs.  It should be possible to develop
    a common interface which could be built on top of curses for us
    and on top of Arity's stuff for Arity, but _that_ is the thing which
    should be translated by this program, not stuff which is peculiar to
    IBM PCs.  If text windows are important to you, get in touch with
    Quintus to discuss your requirements.  We have concentrated on
    producing high-level graphics tools (such as ProWindows), but are
    not too proud to do work for ANSI terminals if there's money in it...
*/
trans(define_window(A,B,C,D,E), G) :- !,
	cannot_hack_window(define_window(A,B,C,D,E), G).
trans(window_info(A,B,C,D,E), G) :- !,
	cannot_hack_window(window_info(A,B,C,D,E), G).
trans(current_window(A,B), G) :- !,
	cannot_hack_window(current_window(A,B), G).
trans(hide_window(A,B), G) :- !,
	cannot_hack_window(hide_window(A,B), G).
trans(what_windows(A), G) :- !,
	cannot_hack_window(what_windows(A), G).
trans(resize_window(A,B), G) :- !,
	cannot_hack_window(resize_window(A,B), G).
trans(move_window(A,B), G) :- !,
	cannot_hack_window(move_window(A,B), G).
trans(relabel_window(A), G) :- !,
	cannot_hack_window(relabel_window(A), G).
trans(recolor_window(A,B), G) :- !,
	cannot_hack_window(recolor_window(A,B), G).
trans(store_windows, G) :- !,
	cannot_hack_window(store_windows, G).
trans(refresh, G) :- !,
	cannot_hack_window(refresh, G).
trans(delete_window(A), G) :- !,
	cannot_hack_window(delete_window(A), G).
trans(create_popup(A,B,C,D), G) :- !,
	cannot_hack_window(create_popup(A,B,C,D), G).
trans(exit_popup, G) :- !,
	cannot_hack_window(exit_popup, G).

%   Chapter 11.  Page 137.

trans(tget(A,B), G) :- !,
	cannot_hack_window(tget(A,B), G).
trans(tmove(A,B), G) :- !,
	cannot_hack_window(tmove(A,B), G).
trans(set_cursor(A,B), G) :- !,
	cannot_hack_window(set_cursor(A,B), G).
trans(get_cursor(A,B), G) :- !,
	cannot_hack_window(get_cursor(A,B), G).
trans(tchar(A,B), G) :- !,
	cannot_hack_window(tchar(A,B), G).
trans(wc(A,B), G) :- !,
	cannot_hack_window(wc(A,B), G).
trans(wa(A,B), G) :- !,
	cannot_hack_window(wa(A,B), G).
trans(wca(A,B,C), G) :- !,
	cannot_hack_window(wca(A,B,C), G).
trans(tscroll(A,B,C), G) :- !,
	cannot_hack_window(tscroll(A,B,C), G).
trans(cls, G) :- !,
	cannot_hack_window(cls, G).
trans(region_ca(A,B,C), G) :- !,
	cannot_hack_window(region_ca(A,B,C), G).
trans(region_cc(A,B,C), G) :- !,
	cannot_hack_window(region_cc(A,B,C), G).
trans(region_c(A,B,C), G) :- !,
	cannot_hack_window(region_c(A,B,C), G).


%   Chapter 12.  Page 158

trans(begin_dialog(A,B,C,D,E,F,J), G) :- !,
	cannot_hack_window(begin_dialog(A,B,C,D,E,F,J), G).
trans(end_dialog(A), G) :- !,
	cannot_hack_window(end_dialog(A), G).
trans(load_key(A,B), G) :- !,
	cannot_hack_window(load_key(A,B), G).
trans(dialog_run(A), G) :- !,
	cannot_hack_window(dialog_run(A), G).
trans(dialog_run(A,B), G) :- !,
	cannot_hack_window(dialog_run(A,B), G).
trans(which_control(A), G) :- !,
	cannot_hack_window(which_control(A), G).
trans(send_dialog_msg(A,B,C), G) :- !,
	cannot_hack_window(send_dialog_msg(A,B,C), G).
trans(send_control_msg(A,B,C), G) :- !,
	cannot_hack_window(send_control_msg(A,B,C), G).
trans(exit_dbox(A), G) :- !,
	cannot_hack_window(exit_dbox(A), G).
trans(write_ctrl_text(A,B), G) :- !,
	cannot_hack_window(write_ctrl_text(A,B), G).


%   Chapter 13.  Page 213.

trans(begin_menu(A,B,C,D,E,F), G) :- !,
	cannot_hack_window(begin_menu(A,B,C,D,E,F), G).
trans(end_menu(A), G) :- !,
	cannot_hack_window(end_menu(A), G).
trans(send_menu_msg(A,B), G) :- !,
	cannot_hack_window(send_menu_msg(A,B), G).



%   Chapter 14.  Page 232
/*  Fair enough for Arity/Prolog to be missing phrase/3; we invented
    that one.  But why are they missing phrase/2?
*/
trans(expand_term(X,Y),	expand_term(X,Y)) :- !.


%   Chapter 15.  Page 235

trans(shell,		unix(shell)) :- !.
trans(shell(Cmd),	unix(system(Cmd))):- !,
	(   var(Cmd) -> true
	;   format(user_error,
		'~N% MS-DOS commands must be translated by hand.~n', []),
	    format(user_error,
		'~N% Command: ~w~n', [Cmd])
	).
trans(halt,		halt) :- !.
trans(halt(N),		exit(N)) :- !,
	need_library(exit),
	format(user_error,
	    '~N% MS-DOS exit codes must be translated by hand.~n', []),
	format(user_error,
	    '~N% See /usr/include/sysexits.h for some useful numbers.~n', []).
trans(lock,		begin_critical) :- !,
	need_library(critical).
trans(unlock,		end_critical) :- !,
	need_library(critical).
trans(gc,		garbage_collect) :- !.
trans(statistics,	statistics) :- !.
trans(statistics(X,Y),	G) :- !,
	cannot_hack(statistics(X,Y), G).
trans(system(X),	arity_system(X)) :- !,
	need_library(arity).
trans(consult(X),	G) :- !,
	cannot_hack(consult(X), G).
trans(reconsult(X),	consult(X)) :- !.
trans([-X],		consult(X)) :- !.
trans([X],		G) :- !,
	cannot_hack([X], G).
trans(edit(F),		arity_command('${EDITOR:-vi}', F)) :- !,
	file_warning(edit(F)),
	need_library(arity).
trans(syntax_errors(O,N), G) :- !,
	cannot_hack(syntax_errors(O,N), G).	% **YET**
trans(fileerrors(O,N),	prolog_flag(fileerrors,O,N)) :- !.
trans(errcode(E),	G) :- !,
	cannot_hack(errcode(E), G).
trans(disk(X),		G) :- !,
	cannot_hack(disk(X), G).
trans(mkdir(Path),	arity_command(mkdir,Path)) :- !,
	file_warning(mkdir(Path)),
	need_library(arity).
trans(chdir(Path),	unix(cd(Path))):- !,
	file_warning(chdir(Path)).
trans(rmdir(Path),	arity_command(rmdir,Path)) :- !,
	file_warning(rmdir(Path)),
	need_library(arity).
trans(directory(P,N,M,T,D,S), G) :- !,
	cannot_hack(directory(P,N,M,T,D,S), G),
	format(user_error,
	    '~N% See "Looking up files" in the Library manual.~n', []).
trans(delete(File),	delete_file(File)) :- !,
	file_warning(delete(File)),
	need_library(files).
trans(rename(File),	rename_file(File)) :- !,
	file_warning(rename(File)),
	need_library(files).
trans(chmod(File,X),	arity_command(Cmd,File)) :-
	(   X == 0, !, Cmd = 'chmod ug+rw'
	;   X == 1, !, Cmd = 'chmod a-wx'
	),
	file_warning(chmod(File,X)).
trans(chmod(File,X),	G) :- !,
	cannot_hack(chmod(File,X), G).
trans(date(X),		arity_date(X)) :- !,
	need_library(arity).
trans(time(X),		arity_time(X)) :- !,
	need_library(arity).
trans(date_day(X),	arity_date_day(X)) :- !,
	need_library(arity).


%   Chapter 16.  Page 253

trans({X}, G) :- !,
	cannot_hack({X}, G).


%   Chapter 17.  Page 289

trans(trace,		trace) :- !.
trans(notrace,		notrace) :- !.
trans(spy(X),		spy(X)) :- !.
trans(nospy(X),		nospy(X)) :- !.
trans(leash(X),		leash(X)) :- !.

/*  At long last, we come to the reason for all those horrible cuts.
    Anything else is deemed to be user-written code, and is copied intact.
    This isn't quite right; we want some sort of meta-predicate stuff so
    that Arity customers can tell the translator about their meta-
    predicates.  But that can wait for a bit.
*/
trans(X,		X).



%   Section 1.3  Page 8, Section 1.3.7 Page 18

trans_cases([], true) :- !.
trans_cases([Case|Cases], (A1 -> B1 ; Ifs)) :- !,
	(   nonvar(Case), Case = (A -> B) ->
	    translate(A, A1),
	    translate(B, B1)
	;   aq_error('Invalid ''case'' branch ~q', [Case])
	),
	trans_cases(Cases, Ifs).
trans_case(A, A1) :-
	translate(A, A1).


%   expr(+ArityExpr, -PrologExpr, ?L0, ?L)
%   converts an arithmetic expression.  Some of the subterms turn into
%   goals (e.g. the trig functions), and those we accumulate in left-
%   to-right order in the list segment L0\L.


expr(A, A) --> {var(A)}, !.
expr(A, A) --> {number(A)}, !.

%   Section 2.1  Page 23

expr(pi,	3.14159265358979323846) --> !.
expr(random,	X)	--> !, [arity_random(X)], {need_library(arity)}.
expr(A+B,	Q+R)	--> !, expr(A, Q), expr(B, R).
expr(A-B,	Q-R)	--> !, expr(A, Q), expr(B, R).
expr(A*B,	Q*R)	--> !, expr(A, Q), expr(B, R).
expr(A/B,	Q/R)	--> !, expr(A, Q), expr(B, R).
expr(A//B,	Q//R)	--> !, expr(A, Q), expr(B, R).
expr(A^B,	X)	--> !, binary(pow, A, B, X).
expr(-A,	-Q)	--> !, expr(A, Q).
expr(A/\B,	Q/\R)	--> !, expr(A, Q), expr(B, R).
expr(A\/B,	Q\/R)	--> !, expr(A, Q), expr(B, R).
expr(\+/(A,B),	\(Q,R))	--> !, expr(A, Q), expr(B, R).
expr(\(A),	\(Q))	--> !, expr(A, Q).
expr(A<<B,	Q<<R)	--> !, expr(A, Q), expr(B, R).
expr(A>>B,	Q>>R)	--> !, expr(A, Q), expr(B, R).

%   Section 2.1  Page 24

expr([A],	Q)	--> !, expr(A, Q).
expr(A mod B,	Q mod R)--> !, expr(A, Q), expr(B, R).
expr(abs(A),	X)	--> !, expr(A, Q), is(V, Q), [(V < 0 -> X is -V ; X is V)].
expr(acos(A),	X)	--> !, unary(acos, A, X).
expr(asin(A),	X)	--> !, unary(asin, A, X).
expr(atan(A),	X)	--> !, unary(atan, A, X).
expr(cos(A),	X)	--> !, unary(cos,  A, X).
expr(sin(A),	X)	--> !, unary(sin,  A, X).
expr(tan(A),	X)	--> !, unary(tan,  A, X).
expr(exp(A),	X)	--> !, unary(exp,  A, X).
expr(ln(A),	X)	--> !, unary(log,  A, X).
expr(log(A),	X)	--> !, unary(log10,  A, X).
expr(sqrt(A),	X)	--> !, unary(sqrt, A, X).
expr(Other,	Other)	-->
	{aq_error('Expression cannot be converted: ~q', [Other])}.



binary(F, A, B, X) -->
	{need_library(math)},
	expr(A, Q), is(Q, V),
	expr(B, R), is(R, W),
	{T =.. [F,V,W,X]},
	[T].

unary(F, A, X) -->
	{need_library(math)},
	expr(A, Q), is(Q, V),
	{T =.. [F,V,X]},
	[T].

is(A, X) -->
	( {var(A)} -> {X=A}
	| {number(A)} -> {X=A}
	| [X is A]
	).


%   list_to_code(+[G1,...,Gn], -(G1,...,Gn))
%   converts a list of goals to a conjunction.

list_to_code([], true).
list_to_code([Goal|Goals], Code) :-
	list_to_code(Goals, Goal, Code).

list_to_code([], Goal, Goal).
list_to_code([Next|Goals], Goal, (Goal,Code)) :-
	list_to_code(Goals, Next, Code).


%   access_mode(+Access, -Mode)
%   converts r, w, a, &c to read, write, append, &c.

access_mode(r, read) :- !.
access_mode(w, write) :- !.
access_mode(a, append) :- !.
access_mode(rw, write) :- !,
	format(user_error, '~N! Access mode "~w" is not portable.~n', [rw]).
access_mode(ra, append) :- !,
	format(user_error, '~N! Access mode "~w" is not portable.~n', [ra]).
access_mode(Other, read) :-
	format(user_error, '~N! Illegal access mode "~w".~n', [Other]).


%   h_to_s(+Handle, -Stream)
%   tries to convert Handle to a Stream.

h_to_s(Handle, Stream) :-
	(   var(Handle) -> Stream = Handle
	;   integer(Handle) ->
	    (   Handle =:= 0 -> Stream = user_input
	    ;	Handle =:= 1 -> Stream = user_output
	    ;	Handle =:= 2 -> Stream = user_error
	    ;   Stream = Handle,
		aq_error('Unsupported built-in handle: ~w~n', [Handle])
	    )
	;   aq_error('Invalid handle: ~q~n', [Handle]),
	    Stream = user
	).


%   cannot_hack(Goal, Apology)
%   is called when Goal is an Arity-specific predicate which we cannot
%   or should not support.  It produces an error message at the time of
%   translation, and returns Apology code which prints a similar message
%   at run time.  All unsupported goals currently fail; soon they will
%   signal errors.

cannot_hack(Goal, arity_apology(Goal)) :-
	need_library(arity),
	functor(Goal, F, N),
	format(user_error,
	       '~N! Unsupported Arity/Prolog predicate ~q~n! Goal: ~q~n',
	       [F/N, Goal]).


cannot_hack_window(Goal, Apology) :-
	cannot_hack(Goal, Apology),
	window_warning.


:- dynamic
	already_warned/1.

save_warning :-
	(   already_warned(save) -> true
	;   format(user_error,
		'~N% ~w save/1 and restore/1 are as in ~w.~n',
		['Quintus Prolog', 'DEC-10 Prolog']),
	    assert(already_warned(save))
	).

p_open_warning :-
	(   already_warned(p_open) -> true
	;   format(user_error,
		'~N% Accessing data via $PATH is a security risk.~n', []),
	    format(user_error,
		'~N% Well-behaved UNIX programs must not do it.~n', []),
	    format(user_error,
		'~N% p_open/3 is thus treated as open/3.~n', []),
	    assert(already_warned(p_open))
	).


window_warning :-
	(   already_warned(window) -> true
	;   format(user_error,
		'~N% Arity''s text windows are Arity-specific.~n', []),
	    format(user_error,
		'~N% Consider using ProWindows (Quintus-specific).~n', []),
	    assert(already_warned(window))
	).


string_warning :-
	(   already_warned(strings) -> true
	;   format(user_error,
		'~N% Arity''s strings will be represented by atoms.~n', []),
	    assert(already_warned(strings))
	).

%   trans_clause(+C, -C1)
%   translates the argument of assert or retract.

trans_clause(C, C1) :-
	(   nonvar(C), C = :-(H,B) ->
	    C1 = :-(H,B1),
	    translate(B, B1)
	;   C1 = C
	).


file_warning(Command) :-
	format(user_error,
	    '~N% MS-DOS file names may need manual conversion.~n', []),
	format(user_error,
	    '~N% Goal: ~q~n', [Command]).


%   need_library(+LibName)
%   notes that this program needs that library.  We'll insert
%   :- ensure_loaded(library(..)) at the end of the program.

:- dynamic
	library_needed/1.

need_library(LibName) :-
	(   library_needed(LibName) -> true
	;   assert(library_needed(LibName))
	).

ensure_libraries :-
	(   retract(library_needed(LibName)),
	    portray_clause(:-(ensure_loaded(library(LibName)))),
	    fail
	;   true
	).


end_of_file.

/*  Arity give this example of a dialogue box definition:

	begin_dialog(test1, 'Example box', (6,15), (16,65),
			(112,79), 47, popup).
	ctrl(choice, 1, $Print file$, (2,2),  79, [], unchecked).
	ctrl(choice, 1, $Copy file$,  (5,2), 111, [], unchecked).
	ctrl(text,   0, $Press enter to exit$, (8,10), 63, 19).
	end_dialog(test1).

    A more Prolog-like approach would be something like

	dialog_box(test1,
	    [
		title('Example box'),
		area(6,15,16,65),
		border(112,79),
		accelerator(47),
		type(popup),
		item( 2, 2, 79, choice('Print file', unchecked)),
		item( 5, 2,111, choice('Copy file',  unchecked)),
		item( 8,10, 63, text('Press enter to exit', 19))
	    ]).

    Items have the form
	item(Row,Col,Attr, ItemInfo)
    where ItemInfo is
	text(Label, Width)
	choices([Choice,...,Choice])
	choice(Label, checked/unchecked/greyed)
	radios([Radio,...,Radio])
	radio(Label, checked/unchecked/greyed)
	efield(Text, Width, BorderAttr)
	button(Label, Goal, BorderAttr)		% Arity 'push'
	default(Label, Goal, BorderAttr)	% Arity 'push' ('default')
	radio_box(Label, Rows, Cols, BorderAttr, [Element,...,Element])
	choice_box(Label, Rows, Cols, BorderAttr, [Element,...,Element])
		where Element is +(Text) {selected} or -(Text) {not}
	edit_box(Label, Rows, Cols, BorderAttr, read/write, *Key)
	edit_region(Rows, Cols, read/write, *Key)

    Another example;

	dialog_box(dbox(Files),
	    [
		title('Delete File'),
		area(5,10,13,60),
		border(79,79),
		accelerator(0'/),
		type(popup),
		item( 2, 2, 14, choice_box('Filename', 8,17, 47,Files)),
		item(10,35,111, button('Delete',delete,14)),
		item(13,35,111, default('Cancel',cancel,14))
	    ]).
*/
