%   Package: lpa
%   Author : Richard A. O'Keefe
%   Updated: 04/15/99
%   Purpose: LPA Prolog compatibility.

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/* 
    This file is intended for use with Quintus Prolog when running
    programs that are required to be portable between Quintus Prolog,
    Quintus MacProlog and Quintus DOS Prolog.  See also quintus.mac and
    quintus.dec.

    These routines have not yet been well tested: please let us know if
    you find problems.  Also let us know if you have portability problems
    between these three systems which are not addressed by these libraries.
*/


:- module(lpa, [
/*	append/3,		% now a builtin		*/
	remove/3,		select/3,
	remove_all/3,		subtract/3,
	on/2,			member/2,
	p_functor/3,
	p_sin/2,		p_asin/2,
	p_cos/2,		p_acos/2,
	p_tan/2,		p_atan/2,
	p_log/2,		p_exp/2,
	p_log/3,		p_exp/3,
	p_abs/2,		p_sign/2,
	p_sqrt/2,
	deg_rad/2,		pi/1,
	load_program/1,		reverse/2,
	kill/1,
	dec10_abolish/2,
	lst/1,			atom/2,
/*	compound/1,		% now a builtin		*/
	environment/1,
	sys/1,
	def/1,			dict/1,
	cdef/1,			cdict/1,
	idef/1,			idict/1,
	pdef/1,
	sdef/1,			sdict/1,
				adict/1,
				fdict/1,
				gdict/1,
				mdict/1,
				wdict/1,
	open_file/3,		p_close/1,
				writev/2,		writev/3,
    /*	writeq/1,		writeq/2,	*/	writeq/3,
	writeseq/1,		writeseq/2,
	writeqseq/1,		writeqseq/2,		writeqseq/3,
	writenl/1,		writenl/2,
	writeqnl/1,		writeqnl/2,		writeqnl/3,
	writeseqnl/1,		writeseqnl/2,
	writeqseqnl/1,		writeqseqnl/2,		writeqseqnl/3,
	dec10_display/1,	p_get/1,
	charof/2,		char_atoms/2,
	stringof/2,		textof/2,

	gread/1,		prompt_gread/2,
	gread/2,		prompt_gread/3,
	gread/3,		prompt_read/2,
	prompt_yesno/1,		prompt_message/1,
	prompt_error/1,		prompt_warning/1,
	beep/1,			beep/2,

	one/1,			force/1,
	(not)/1,		(\=)/2,
	apply/2,		p_call/1,
	p_call/2,		p_call/3,
	p_call/4,		p_call/5,
	p_call/6,		p_call/7,
	mem/3,			keysort/3,
	sort/3,			sort/4,
	ems/0,
	crarray/4,		crarray/5,
	szarray/3,		szarray/4,
	aload/1,
	asave/2,
	setblk/6,
	getblk/6,
	rotblk/7,
	schline/5,		schline/6,
	get_prop/3,
	recall/2,
	default/3,
	set_prop/3,
	remember/2,
	del_prop/2,
	forget/1,
	get_cons/2,
	del_cons/1,
	get_props/2,
	del_props/1,
	p_date/3,
	p_datime/6,
	p_time/3,
	run_time/2,			run_time/3,
	toground/2,			toground/3,
	toground/4,			toground/5,
	tohollow/3,			tohollow/4,
	varsin/2,
	file_exists/1,
	delete_file/1,
	rename_file/2,
	current_directory/1,
	set_directory/1
   ]).
:- meta_predicate
	apply(:, +),
	p_call(0),
	p_call(1, ?),
	p_call(2, ?, ?),
	p_call(3, ?, ?, ?),
	p_call(4, ?, ?, ?, ?),
	p_call(5, ?, ?, ?, ?, ?),
	p_call(6, ?, ?, ?, ?, ?, ?),
	force(0),
	one(0),
	not(0),
	run_time(0, ?),
	run_time(+, 0, ?).

:- use_module(library(basics), [
	%append/3,		% append/3 is now a built-in predicate
	member/2
   ]).
:- use_module(library(not), [
	(not)/1,
	(\=)/2
   ]).
:- use_module(library(environment), [
	environment/1
   ]).
:- use_module(library(files), [
	file_exists/1,
	delete_file/1,
	rename_file/2
   ]).
:- use_module(library(lists), [
	nth0/3,			% for internal use
	rev/2,			% for internal use
	reverse/2		% for re-export
   ]).
:- use_module(library(sets), [
	select/3,
	subtract/3
   ]).
:- use_module(math, [
	sin/2,			asin/2,
	cos/2,			acos/2,
	tan/2,			atan/2,
	sqrt/2,			pow/3,
	log/2,			exp/2
   ]).
:- use_module(library(types), [
	%compound/1,		% compound/1 is now a built-in predicate
	must_be/4,
	should_be/4
   ]).
:- use_module(library(date), [
	datime/1,
	date/3,
	time/3
   ]).
:- use_module(library(call), [
	apply/2,
	call/2,
	call/3,
	call/4,
	call/5,
	call/6,
	call/7
   ]).
:- use_module(library(read), [
	portable_gread/1,
	portable_gread/2
   ]).
:- use_module(library(strings), [
	char_atom/2
   ]).

:- op(700, xfx, \=).

sccs_id('"@(#)99/04/15 lpa.pl	76.1"').


/*  A note on the way I've done this.  Suppose the input list has
    N elements, then there are going to be about N*lg(N) comparisons.
    If we leave it until comparison time to locate the keys, we will
    call lpa_key/3 (or its functional equivalent) 2NlgN times.  Ugh.
    If, however, we compute the keys once at the beginning and leave
    them where keysort/2 can find them, we call lpa_key/3 N times.
    That is an _extremely_ worthwhile tradeoff!  We turn over 5N
    more cells to build the list of pairs, but that is acceptable
    compared with the 2NlgN we are going to turn over during the sort
    anyway.  Key computations done during the sort must be kept as
    simple as possible.  See Lindemann's paper for some UNIX-related
    observations on sorting.

    Verbum sapientes:  if you have a list of
	person(Name,Age)
    records which you want sorted by Age, it is better software
    engineering practice to do
	age_ordered(People, OrderedPeople) :-
		keyed_by_age(People, Keyed),
		keysort(Keyed, Sorted),
		rem_keys(Sorted, OrderedPeople).

	keyed_by_age([], []).
	keyed_by_age([Person|People], [Age-Person|Keyed]) :-
		age(Person, Age),
		keyed_by_age(People, Keyed).

    That way if you later decide to change your representation, and
    pass around just the names of people and store their ages in the
    data base as age/2 facts, you won't have to rewrite your sorting
    routine.  In fact, if you are going to sort on some key, there's
    a pretty good chance that you want to get your hands on it again
    soon, so you seldom _want_ to strip the keys off straight away.
    You may find library(clump) of interest.
*/


keysort(List, SortedList, Direction) :-
	keysort(List, OrderedList),
	(   Direction < 0 ->
	    SortedList = OrderedList
	;   Direction > 0 ->
	    rev(OrderedList, SortedList)
	).


sort(List, SortedList, Path) :-
	sort(List, SortedList, Path, -1).

sort(List, SortedList, Path, Direction) :-
	add_lpa_keys(List, Path, KeyedList),
	keysort(KeyedList, SortedKeyedList),
	(   Direction < 0 ->
	    strip_lpa_keys(SortedKeyedList, SortedList)
	;   Direction > 0 ->
	    strip_lpa_keys(SortedKeyedList, [], SortedList)
	).

add_lpa_keys([], _, []).
add_lpa_keys([Val|List], Path, [Key-Val|Pairs]) :-
	lpa_key(Path, Val, Key),
	add_lpa_keys(List, Path, Pairs).


%   mem(+Term, +Path, ?SubTerm)
%   follows a Path (a list of strictly positive integers) to a place in
%   the given Term and unifies SubTerm with whatever is found there.  It
%   is like path_arg/3 in library(arg), sort of, only weird.  It is not
%   clear to us just what errors mem/3 is supposed to report.  

mem(Record, Path, Field) :-
	lpa_key(Path, Record, Field).

lpa_key([], Key, Key).
lpa_key([N|Ns], Term, Key) :-
	integer(N),
	M is N-1,
	(   nonvar(Term), Term = [_|_] ->
	    M >= 0,
	    nth0(M, Term, Next)
	;   M > 0 ->
	    arg(M, Term, Next)
	;   M =:= 0 ->
	    functor(Term, Next, _)
	),
	lpa_key(Ns, Next, Key).

strip_lpa_keys([], []).
strip_lpa_keys([_-Val|Pairs], [Val|List]) :-
	strip_lpa_keys(Pairs, List).

strip_lpa_keys([], List, List).
strip_lpa_keys([_-Val|Pairs], List0, List) :-
	strip_lpa_keys(Pairs, [Val|List0], List).


/*  force(X) has no special effect in Quintus Prolog, just a plain call.
    one(X) is normally called once(X).
    not(X) comes from library(not) and is strictly Edinburgh-compatible;
    the LPA version is NOT Edinburgh-compatible: use \+ instead to make your 
    code portable.
*/

force(G) :-
	call(G).

one(G) :-
	call(G),
	!.

p_call(G)				:- call(G).
p_call(G, X1)				:- call(G, X1).
p_call(G, X1, X2)			:- call(G, X1, X2).
p_call(G, X1, X2, X3)			:- call(G, X1, X2, X3).
p_call(G, X1, X2, X3, X4)		:- call(G, X1, X2, X3, X4).
p_call(G, X1, X2, X3, X4, X5)		:- call(G, X1, X2, X3, X4, X5).
p_call(G, X1, X2, X3, X4, X5, X6)	:- call(G, X1, X2, X3, X4, X5, X6).


on(Element, List) :-
	format(user_error, '~N% Convert ~q to ~q.~n', [on/2,member/2]),
	member(Element, List).

remove(Element, List, Residue) :-
	format(user_error, '~N% Convert ~q to ~q.~n',
			   [remove/3,select/3]),
	select(Element, List, Residue).

remove_all(Set2, Set1, Difference) :-
	format(user_error, '~N% Convert ~q to ~q.~n',
			   [remove_all/3,subtract/3]),
	subtract(Set1, Set2, Difference).

/*  LPA Prolog Professional release 2.6 has a rather nasty bug in
    functor:  it is an important property of functor/3 that if F, N,
    and C are new variables and T is ANY non-variable, then after doing
	functor(T, F, N), functor(C, F, N)
    C is a skeletal copy of T, so that C = T will succeed.  But in LPA
    PP 2.6, if T is a list cell [_|_], the resulting C will _NOT_ unify
    with T but is quite a different term.  p_functor/3 is supposed to
    be a version of functor/3 which works.
*/

p_functor(T, F, N) :-
	functor(T, F, N).


p_sin(R, S) :- sin(R, S).
p_cos(R, C) :- cos(R, C).
p_tan(R, T) :- tan(R, T).

p_asin(S, R) :- asin(S, R).
p_acos(C, R) :- acos(C, R).
p_atan(T, R) :- atan(T, R).

p_abs(X, A) :-
	( X < 0 -> A is - X ; A is X ).

p_sign(X, A) :-
    (	X > 0 ->
	( integer(X) -> A = 1 ; A = 1.0 )
    ;   X < 0 ->
	( integer(X) -> A = -1 ; A = - 1.0 )
    ;/* X = 0 */
	A = X
    ).

p_sqrt(X, Sqrt) :-
	sqrt(X, Sqrt).

p_exp(Y, Exp) :-
	exp(Y, Exp).

p_exp(X, Y, Exp) :-
	pow(X, Y, Exp).

p_log(Y, Log) :-
	log(Y, Log).

p_log(X, Y, Log) :-
	log(X, LogX),
	log(Y, LogY),
	Log is LogY/LogX.

deg_rad(Deg, Rad) :-
	(   number(Deg) -> Rad is Deg * 0.017453292519943295769237
	;   number(Rad) -> Deg is Rad * 57.29496951308231087679815
	).

%   The value of "pi" used in LPA Mac Prolog 2.5 is not as precise as
%   LPA Mac Prolog is capable of representing.  You might prefer to use
%   environment(float(pi(X))), which is as accurate as read/1 will let
%   a floating-point number be.  My proposal for Prolog floating-point
%   arithmetic has the expression form
%	X is pi(N)
%   which can be implemented more accurately than pi*X (strange but true).

pi(3.141592653589793238462643).


load_program(File) :-
	restore(File).

dec10_abolish(P, N) :-
	abolish(P, N).

kill([]) :- !.
kill([Atom|Atoms]) :- !,
	kill(Atom),
	kill(Atoms).
kill(Atom) :-
	atom(Atom),
	user:current_predicate(Atom, Skel),
	functor(Skel, Atom, Arity),
	user:abolish(Atom, Arity),
	fail
    ;   true.



%   atom(+Atom, -Type)
%   is supposed to tell an LPA Prolog programmer what is the one thing
%   that the Atom is totally reserved to.  For example, in LPA Prolog
%   you cannot have a predicate and a file with the same spelling (it
%   isn't the full name of the file that counts but the name you cite;
%   so "compile(not)" -- which defines not/1 -- would be Big Trouble).
%   Quintus Prolog, like DEC-10 Prolog, has no such awful restrictions.
%   Type = 0	no analogous test
%	   1	use current_module(Atom)
%	   2	current_dec10_stream(Atom, _) is close
%	   3	no text windows (see ProWindows)
%	   4	environment(arithmetic(Atom(_,_))) will be provided some time
%	   5	environment(arithmetic(Atom(_))) will be provided some time
%	   6	predicate_property(..., {built_in,compiled}) are close
%	   7	predicate_property(..., (dynamic)) is close
%	   8	predicate_property(..., compiled) is close
%   The point of defining this predicate at all is to help you find any
%   unconverted uses of atom/2 (note that LPA MacProlog lacks it).

atom(Atom, Type) :-
	(   atom(Atom) ->
	    format(user_error, '~N% ~q is not portable.~n', [atom/2]),
	    Type = 0
	;   should_be(atom, Atom, 1, atom(Atom,Type))
	).


lst(*) :- !, fail.		% catch and reject variables
lst([]).
lst([_|_]).


/*  The following predicates accept
    -- an atom, testing whether there is a predicate with the
       specified property of ANY arity
    -- a compound term, testing whether there is a predicate
       of THAT arity having the specified property.
    The latter is stricter than LPA Prolog.
    Note that none of these predicates will solve for their argument.
    It is clearly stated in the LPA manuals that if the argument is
    not an atom or a compound term these predicates FAIL.
*/


%   The following definition of sys/1 is approximate; it includes the names
%   of all the built-in predicates, the names of all the predicates exported
%   from this module (so that many of the LPA predicates appear), the names
%   of all the arithmetic functions, and the reserved stream names.  It is
%   far from clear what should be here; please tell us what if anything
%   gives you trouble, whether by its inclusion or by its exclusion.

sys(!).
sys(',').
sys('.').
sys('C').
sys('LC').
sys('NOLC').
sys(*).
sys(+).
sys(-).
sys(-->).
sys(->).
sys(/).
sys(//).
sys(/\).
sys(:).
sys((:-)).
sys(;).
sys(<).
sys(<<).
sys(=).
sys(=..).
sys(=:=).
sys(=<).
sys(==).
sys(=\=).
sys(>).
sys(>=).
sys(>>).
sys((?-)).
sys(@<).
sys(@=<).
sys(@>).
sys(@>=).
sys(\).
sys(\+).
sys(\=).
sys(\==).
sys(\/).
sys(^).
sys(abolish).
sys(abort).
sys(absolute_file_name).
sys(adict).
sys(aload).
sys(ancestors).
sys(append).
sys(apply).
sys(arg).
sys(asave).
sys(assert).
sys(asserta).
sys(assertz).
sys(atom).
sys(atom_chars).
sys(atomic).
sys(bagof).
sys(beep).
sys(break).
sys(call).
sys(cdef).
sys(cdict).
sys(char_atoms).
sys(character_count).
sys(charof).
sys(clause).
sys(close).
sys(compare).
sys(compile).
sys(compound).
sys(consult).
sys(copy_term).
sys(crarray).
sys(current_atom).
sys(current_directory).
sys(current_functor).
sys(current_input).
sys(current_key).
sys(current_module).
sys(current_op).
sys(current_output).
sys(current_predicate).
sys(current_stream).
sys(debug).
sys(debugging).
sys(dec10_abolish).
sys(dec10_display).
sys(def).
sys(default).
sys(deg_rad).
sys(del_cons).
sys(del_prop).
sys(del_props).
sys(delete_file).
sys(depth).
sys(dict).
sys(display).
sys((dynamic)).
sys(ems).
sys(ensure_loaded).
sys(environment).
sys(erase).
sys(expand_term).
sys(fail).
sys(false).
sys(fdict).
sys(file_exists).
sys(fileerrors).
sys(float).
sys(flush_output).
sys(force).
sys(forget).
sys(format).
sys(functor).
sys(garbage_collect).
sys(gc).
sys(gcguide).
sys(gdict).
sys(get).
sys(get0).
sys(get_cons).
sys(get_prop).
sys(get_props).
sys(getblk).
sys(gread).
sys(halt).
sys(help).
sys(idef).
sys(idict).
sys(incore).
sys(instance).
sys(integer).
sys(is).
sys(keysort).
sys(kill).
sys(leash).
sys(length).
sys(line_count).
sys(line_position).
sys(listing).
sys(load_foreign_files).
sys(load_program).
sys(log).
sys(lst).
sys(manual).
sys(maxdepth).
sys(mdict).
sys(mem).
sys(member).
sys((meta_predicate)).
sys(mod).
sys((mode)).
sys(module).
sys((multifile)).
sys(name).
sys(nl).
sys(no_style_check).
sys(nodebug).
sys(nofileerrors).
sys(nogc).
sys(nolog).
sys(nonvar).
sys(nospy).
sys(nospyall).
sys(not).
sys(notrace).
sys(number).
sys(number_chars).
sys(numbervars).
sys(on).
sys(one).
sys(op).
sys(open).
sys(open_file).
sys(open_null_stream).
sys(otherwise).
sys(p_abs).
sys(p_acos).
sys(p_asin).
sys(p_atan).
sys(p_call).
sys(p_close).
sys(p_cos).
sys(p_date).
sys(p_datime).
sys(p_exp).
sys(p_get).
sys(p_log).
sys(p_sign).
sys(p_sin).
sys(p_sqrt).
sys(p_tan).
sys(p_time).
sys(pdef).
sys(phrase).
sys(pi).
sys(plsys).
sys(portray_clause).
sys(predicate_property).
sys(print).
sys(prolog_flag).
sys(prompt).
sys(prompt_error).
sys(prompt_gread).
sys(prompt_message).
sys(prompt_read).
sys(prompt_warning).
sys(prompt_yesno).
sys((public)).
sys(put).
sys(read).
sys(recall).
sys(reconsult).
sys(recorda).
sys(recorded).
sys(recordz).
sys(reinitialise).
sys(remember).
sys(remove).
sys(remove_all).
sys(rename_file).
sys(repeat).
sys(restore).
sys(retract).
sys(retractall).
sys(reverse).
sys(revive).
sys(rotblk).
sys(run_time).
sys(save).
sys(save_program).
sys(schline).
sys(sdef).
sys(sdict).
sys(see).
sys(seeing).
sys(seen).
sys(select).
sys(set_directory).
sys(set_input).
sys(set_output).
sys(set_prop).
sys(setblk).
sys(setof).
sys(skip).
sys(sort).
sys(source_file).
sys(spy).
sys(statistics).
sys(stream_code).
sys(stream_position).
sys(stringof).
sys(style_check).
sys(subgoal_of).
sys(subtract).
sys(sys).
sys(szarray).
sys(tab).
sys(tell).
sys(telling).
sys(textof).
sys(toground).
sys(tohollow).
sys(told).
sys(trace).
sys(trimcore).
sys(true).
sys(ttyflush).
sys(ttyget).
sys(ttyget0).
sys(ttynl).
sys(ttyput).
sys(ttyskip).
sys(ttytab).
sys(unix).
sys(unknown).
sys(use_module).
sys(user).
sys(user_error).
sys(user_input).
sys(user_output).
sys(var).
sys(varsin).
sys(version).
sys(vms).
sys(wdict).
sys(write).
sys(write_canonical).
sys(writenl).
sys(writeq).
sys(writeqnl).
sys(writeqseq).
sys(writeqseqnl).
sys(writeseq).
sys(writeseqnl).
sys(writev).


sdef(Term) :-	% LPA MacProlog
	nonvar(Term),
	(   atom(Term) ->
	    user:predicate_property(Skel, built_in),
	    functor(Skel, Term, _),
	    !
	;   number(Term) -> fail
	;   user:predicate_property(Term, built_in)
	).


def(Term) :-
	nonvar(Term),
	functor(Term, Atom, _),
	atom(Atom),
	(   atom(Term) ->
	    current_predicate(Atom, _),
	    !
	;   current_predicate(Atom, Term)
	).

pdef(Term) :-
	nonvar(Term),
	(   atom(Term) ->
	    (   user:predicate_property(Skel, built_in),
		functor(Skel, Term, _)
	    ;   user:predicate_property(Skel, foreign),
		functor(Skel, Term, _)
	    ),
	    !
	;   number(Term) -> fail
	;   user:predicate_property(Term, built_in) -> true
	;   user:predicate_property(Term, foreign) -> true
	).

idef(Term) :-
	nonvar(Term),
	(   atom(Term) ->
	    user:predicate_property(Skel, interpreted),
	    functor(Skel, Term, _),
	    !
	;   number(Term) -> fail
	;   user:predicate_property(Term, interpreted)
	).

cdef(Term) :-
	nonvar(Term),
	(   atom(Term) ->
	    user:predicate_property(Skel, compiled),
	    \+ user:predicate_property(Skel, foreign),
	    functor(Skel, Term, _),
	    !
	;   number(Term) -> fail
	;   user:predicate_property(Skel, compiled),
	    \+ user:predicate_property(Skel, interpreted)
	).


/*  The following predicates are not particularly efficient.
    They are only intended as scaffolding while you rewrite
    your program to manage without them.
*/


dict(Atoms) :-	% LPA MacProlog
	setof(Atom, Skel^(
	    user:current_predicate(Atom,Skel)),
	    Atoms).

idict(Atoms) :-	% LPA MacProlog
	setof(Atom, Skel^Arity^(
	    user:predicate_property(Skel, interpreted),
	    functor(Skel,Atom,Arity)),
	    Atoms).

cdict(Atoms) :-	% LPA MacProlog
	setof(Atom, Skel^Arity^(
	    user:predicate_property(Skel, compiled),
	    functor(Skel,Atom,Arity)),
	    Atoms).

sdict(Atoms) :-	% Both LPA Prologs
	setof(Atom, sys(Atom), Atoms).

mdict(Atoms) :-	% LPA Prolog Professional
	setof(Atom, current_module(Atom), Atoms).

fdict(Atoms) :-	% LPA Prolog Professional
	(   setof(Atom, M^S^current_stream(Atom,M,S), L) ->
	    Atoms = L
	;   Atoms = []
	).

adict([]).	% LPA Prolog Professional

gdict([]).	% LPA Prolog Professional

wdict([&:]).	% LPA Prolog Professional

current_directory(Dir) :-
	environment(os(OS)),
	current_directory(OS, Dir).

current_directory(unix, D) :-
	absolute_file_name('.', D).
current_directory(vms, D) :-
	absolute_file_name('[]', D).

set_directory(Dir) :-
	environment(os(OS)),
	set_directory(OS, Dir).

set_directory(unix, D) :-
	unix(chdir(D)).
set_directory(vms, D) :-
	vms(chdir(D)).



open_file(File, Mode, Stream) :-
	open(File, Mode, Stream).

/*  In DEC-10 Prolog, the built-in predicates seen/0 and told/0 are redundant:
	seen :- seeing(X),  close(X).
	told :- telling(X), close(X).
    The way this works is that close(X) does this:
	if we are seeing(X),  see(user)  instead.
	if we are telling(X), tell(user) instead.
	then close the file, release buffers, &c.
    Quintus Prolog adds streams to this, so that
	if current_input(X),  set_input(user_input)   instead.
	if current_output(X), set_output(user_output) instead.
    If there were any other 'current' streams (a current error, or trace,
    or logging stream) they would similarly be reset by close/1.
    This is extremely important, because at all times you are supposed to
    be able to trust the current streams.  That is,
	if seeing(X),  then X **must** be a valid input file or stream.
	if telling(X), then X **must** be a valid output file or stream.
    Alas, neither of the LPA dialects has this property.  If you do
	see(fred), close(fred), seeing(X)
    in DEC-10 Prolog, you get X=user, which is valid, but in LPA Prolog
    Professional 2.6 and LPA Mac Prolog 2.5 you get X=fred, which is no
    longer a valid file.  In order to avoid disaster in your programs,
    you will have to use p_close/1.

    Although the LPA dialects have (incompatible) error *handling* features,
    they do not have any user-accessible error *signalling*.  Now another
    property of close/1 inherited from DEC-10 Prolog is that it may succeed
    quietly or it may report an error, but it may NOT fail.  For the sake of
    consistency, therefore, p_close/1 always succeeds in all versions.
*/
p_close(Thing) :-
	(   atom(Thing) ->
	    close(Thing)
	;   nonvar(Thing), current_stream(_, _, Thing) ->
	    close(Thing)
	;   true
	).


/*  In DEC-10 Prolog and some versions of C Prolog,
	get0(X)		returns X = 26 at end of file
    In other versions of C Prolog, Quintus Prolog, LPA Prolog Professional,
    NIP (New edInburgh Prolog) and most other versions of Prolog,
	get0(X)		returns X = -1 at end of file
    just like C.  But in LPA Mac Prolog, in appalling contrast,
	get0(X)		FAILS at end of file
    That is, the two LPA dialects are not compatible with each other.
    We therefore need an operation which IS portable across the dialects,
    and p_get/1 is it.  Define
	p_get(X) :- get0(C), (C =:= 26, !, X = -1 ; X = C ).	% DEC-10
	p_get(X) :- ( get0(C) -> X = C; X = -1 ).		% LPA Mac
	p_get(X) :- get0(X).					% compatible
    If anyone can suggest a way of making the LPA Prologs report an error if
    you keep on reading past the end of the file, please let me know and it
    will go in the next version of the compatibility package; that's a very
    important safety feature.
*/
p_get(X) :-
	get0(X).


/*  The following come from LPA MacProlog
*/


writev(Term, VarNames) :-
	tohollow(Term, Copy, VarNames, Vars),
	'bind var names'(VarNames, Vars),
	writeq(Copy),
	fail
    ;   true.

writev(Stream, Term, VarNames) :-
	tohollow(Term, Copy, VarNames, Vars),
	'bind var names'(VarNames, Vars),
	writeq(Stream, Copy),
	fail
    ;   true.

'bind var names'([], []).
'bind var names'([Name|Names], ['$VAR'(Name)|Vars]) :-
	'bind var names'(Names, Vars).

writeq(Stream, Term, VarNames) :-
	writev(Stream, Term, VarNames).

/*  For compatibility with LPA MacProlog
*/


writeseq(Terms) :-
	'write seq'(Terms, write).

writeseq(Stream, Terms) :-
	'write seq'(Stream, Terms, write).

writeqseq(Terms) :-
	'write seq'(Terms, writeq).

writeqseq(Stream, Terms) :-
	'write seq'(Stream, Terms, writeq).

writeqseq(Stream, Terms, VarNames) :-
	'write seq'(Stream, Terms, writev(VarNames)).


'write seq'(Stream, Terms, Action) :-
	current_output(Old),
	tell(Stream),
	'write seq'(Terms, Action),
	set_output(Old).

'write seq'([], _).
'write seq'([Term|Terms], Action) :-
	'write one'(Action, Term),
	'write rest'(Terms, Action).

'write one'(write, Term) :-
	write(Term).
'write one'(writeq, Term) :-
	writeq(Term).
'write one'(writev(VarNames), Term) :-
	writev(Term, VarNames).

'write rest'([], _).
'write rest'([Term|Terms], Action) :-
	put(" "),
	'write one'(Action, Term),
	'write rest'(Terms, Action).

writenl(Term) :-
	write(Term),
	nl.

writenl(Stream, Term) :-
	write(Stream, Term),
	nl(Stream).

writeqnl(Term) :-
	writeq(Term),
	nl.

writeqnl(Stream, Term) :-
	writeq(Stream, Term),
	nl(Stream).

writeqnl(Stream, Term, VarNames) :-
	writev(Stream, Term, VarNames),
	nl(Stream).

writeseqnl(Terms) :-
	writeseq(Terms),
	nl.

writeseqnl(Stream, Terms) :-
	writeseq(Stream, Terms),
	nl(Stream).

writeqseqnl(Terms) :-
	writeqseqnl(Terms),
	nl.

writeqseqnl(Stream, Terms) :-
	writeqseqnl(Stream, Terms),
	nl(Stream).

writeqseqnl(Stream, Terms, VarNames) :-
	writeqseq(Stream, Terms, VarNames),
	nl(Stream).

dec10_display(Term) :-
	display(Term).


charof(Atom, Char) :-
	char_atom(Char, Atom).

%   BEWARE:  In LPA Prolog Professional,
%	stringof(X, [])	=> FAILS!
%   In Quintus Prolog (except on the Xerox Lisp machines),
%	stringof(X, [])	=> X = ['[',']'].

stringof(Atoms, Atom) :-
	(   atom(Atom) ->
	    atom_chars(Atom, Chars),
	    char_atoms(Chars, Atoms)
	;   var(Atom) ->
	    char_atoms(Chars, Atoms),
	    atom_chars(Atom, Chars)
	;   must_be(atom, Atom, 2, stringof(Atoms,Atom))
	).


%   BEWARE:  In LPA Prolog Professional,
%	textof(X, [])	=> X = ['(',')'].
%   In Quintus Prolog (except on the Xerox Lisp machines),
%	textof(X, [])	=> X = ['[',']'].
%   This is not strictly correct:  I have treated it as an LPA equivalent
%   of name/2, but it is actually supposed to convert between TERMS and
%   lists of atoms.  In particular, something like
%	textof(['(',a,b,' ','(','c',')','|','e',')', X)
%   is supposed to succeed with X = [ab,[c]|e].  However, I was assured by
%   LPA that textof/2 is being phased out, so that may not matter to you.

textof(Atoms, Constant) :-
	(   atomic(Constant) ->
	    name(Constant, Chars),
	    char_atoms(Chars, Atoms)
	;   var(Constant) ->
	    char_atoms(Chars, Atoms),
	    name(Constant, Chars)
	;   must_be(atomic, Constant, 2, textof(Atoms,Constant))
	).

char_atoms([], []).
char_atoms([Char|Chars], [Atom|Atoms]) :-
	char_atom(Char, Atom),
	char_atoms(Chars, Atoms).


%   gread(-Term) is pretty harmless, it reads a term treating identifiers
%   which start with capital letters or underscores as if they were atoms.
%   The result is thus always Ground, hence the 'g'.
%   gread(+Stream, -Term) is also harmless, except for having a stream
%   argument, which you should avoid where-ever possible.
%   gread(+Stream, -Term, -Names), however, can most charitably be
%   described as "muddled".  It reads the term in treating the variables
%   as if they were constants, and returns a list of the variables' names.
%   So, for example,
%	| ?- gread(user_input, Term, Names).
%	|: f(X, 'X', 'Y').
%	Term = f('X','X','Y'),
%	Names = ['X'] 
%   That is, you cannot tell the difference between the X which was an
%   occurrence of a variable and the 'X' which was an atom.
%   If you want to read a term and get the names of the variables in it,
%   use portable_read/2, which in this case would return
%	Term = f(_177,'X','Y'),
%	Dict = ['X'=_177] 

gread(Term) :-
	portable_gread(Term).

gread(Stream, Term) :-
	current_input(Old),
	see(Stream),
	( portable_gread(X) -> true ; true ),
	set_input(Old),
	nonvar(X),
	Term = X.

gread(Stream, Term, Names) :-
	current_input(Old),
	see(Stream),
	( portable_gread(X, Y) -> true ; true ),
	set_input(Old),
	nonvar(X),
	Term = X,
	Names = Y.

/*  The following is a first attempt at the "predefined dialogues"
    of LPA MacProlog.  We should provide two versions of this; one
    version, as here, using just basic TTY operations, the other
    using the Emacs interface.  In LPA MacProlog, the user types
    into a window, then clicks Ok, in which case a result is
    returned.  Or the user can click Cancel, in which case the
    call fails.  In order to provide a similar facility, I've
    chosen to reject end_of_file as a possible answer.  If you
    type ^Z in reply to the prompt, the call will thus fail.
    The `repeat' calls are so that syntax errors will act as
    in LPA MacProlog.  You can only exit by typing a valid
    term or end-of-file.
*/


prompt_read(Prompt, Term) :-
	'prompt read'(Prompt, Term, X, read(X)),
	X \== end_of_file.

prompt_gread(Prompt, Term) :-
	'prompt read'(Prompt, Term, X, gread(X)),
	X \== end_of_file.

prompt_gread(Prompt, Term, Names) :-
	'prompt read'(Prompt, Term/Names, X/Y, gread(X,Y)).

prompt_yesno(Prompt) :-
	repeat,
	'prompt read'(Prompt, 0, Char),
	(   Char =:= "y", !, true
	;   Char =:= "n", !, fail
	;   beep(440, 500), fail
	).

prompt_message(Message) :-
	'prompt read'(Message, ['Press RETURN to proceed'], _).

prompt_warning(Message) :-
	repeat,
	'prompt read'(Message, ['(C)ontinue, (F)ail, or (S)top'], Char),
	(   Char =:= "c", !, true
	;   Char =:= "f", !, fail
	;   Char =:= "s", !, abort
	;   beep(440, 500), fail
	).

prompt_error(Message) :-
	'prompt read'(Message, 'Press RETURN to proceed', _),
	abort.


'prompt read'(Prompt, Ans, X, Goal) :-
	current_input(Input),
	current_output(Output),
	set_input(user_input),
	set_output(user_output),
	repeat,
	    format('~N', []),
	    ( Prompt = [_|_] -> writeseq(Prompt) ; write(Prompt) ),
	    write('? '), ttyflush,
	    'prompt read'(Goal),
	!,
	set_output(Output),
	set_input(Input),
	Ans = X.

'prompt read'(read(X)) :-
	read(X).
'prompt read'(gread(X)) :-
	gread(X).
'prompt read'(gread(X,Y)) :-
	gread(X, Y).

'prompt read'(Prompt, Next, Char) :-
	current_input(Input),
	current_output(Output),
	set_input(user_input),
	set_output(user_output),
	format('~N', []),
	( Prompt = [_|_] -> writeseq(Prompt) ; write(Prompt) ),
	(   integer(Next) -> true
	;   Next = [_|_] -> nl, writeseq(Next)
	;   nl, write(Next)
	),
	write('? '), ttyflush,
	repeat,
	    get0(X),
	    (   X > 32, X < 127 -> true
	    ;   X =:= 10 -> true
	    ;   X > 160 -> true
	    ),
	!,
	(   X =:= 10 -> C = X
	;   skip(10), C is X \/ 32
	),
	set_output(Output),
	set_input(Input),
	Char = C.


beep(_, _) :-
	ttyput(7),
	ttyflush.

beep(_) :-
	ttyput(7),
	ttyflush.


/*  EMS Array Handling
*/

ems :-
	fail.

crarray(Name, Rows, Cols, Init) :-
	'EMS not portable'(crarray(Name,Rows,Cols,Init)).

crarray(Name, Rows, Cols, Init, Size) :-
	'EMS not portable'(crarray(Name,Rows,Cols,Init,Size)).

szarray(Name, Rows, Cols) :-
	'EMS not portable'(szarray(Name,Rows,Cols)).

szarray(Name, Rows, Cols, Size) :-
	'EMS not portable'(szarray(Name,Rows,Cols,Size)).

asave(File, Arrays) :-
	'EMS not portable'(asave(File,Arrays)).

aload(File) :-
	'EMS not portable'(aload(File)).

setblk(Name, Top, Left, Depth, Width, Block) :-
	'EMS not portable'(setblk(Name,Top,Left,Depth,Width,Block)).

getblk(Name, Top, Left, Depth, Width, Block) :-
	'EMS not portable'(getblk(Name,Top,Left,Depth,Width,Block)).

rotblk(Name, Top, Left, Depth, Width, Rows, Cols) :-
	'EMS not portable'(rotblk(Name,Top,Left,Depth,Width,Rows,Cols)).

schline(Name, From, Until, Match, Row) :-
	'EMS not portable'(schline(Name,From,Until,Match,Row)).

schline(Name, From, Until, Match, Row, Col) :-
	'EMS not portable'(schline(Name,From,Until,Match,Row,Col)).

%   For future release, this should signal an implementation fault.

'EMS not portable'(Goal) :-
	format(user_error,
	    '~N! EMS Array Handling is not portable.~n', []),
	format(user_error, '! Goal: ~q~n', [Goal]),
	fail.

/*  LPA MacProlog Property Management.
*/


:- dynamic
	recall/2,
	get_prop/3.

set_prop(Object, Property, Value) :-
	(   atomic(Object),
	    atomic(Property) ->
	    retractall(get_prop(Object,Property,_)),
	    assert(get_prop(Object,Property,Value))
	;   Goal = set_prop(Object, Property, Value),
	    must_be(atomic, Object, 1, Goal),
	    must_be(atomic, Property, 2, Goal)
	).

del_prop(Object, Property) :-
	(   atomic(Object),
	    atomic(Property) ->
	    retractall(get_prop(Object,Property,_))
	;   Goal = del_prop(Object, Property),
	    must_be(atomic, Object, 1, Goal),
	    must_be(atomic, Property, 2, Goal)
	).

del_props(Object) :-
	(   atomic(Object) ->
	    retractall(get_prop(Object,_,_))
	;   must_be(atomic, Object, 1, del_props(Object))
	).

del_cons(Property) :-
	(   atomic(Property) ->
	    retractall(get_prop(_,Property,_))
	;   must_be(atomic, Property, 1, del_cons(Property))
	).

get_cons(Property, Objects) :-
	(   atomic(Property) ->
	    (   setof(Object, Value^get_prop(Object,Property,Value), Os) ->
		Objects = Os
	    ;   Objects = []
	    )
	;   must_be(atomic, Property, 1, get_cons(Property,Objects))
	).

get_props(Object, Properties) :-
	(   atomic(Object) ->
	    (   setof(Property, Value^get_prop(Object,Property,Value), Ps) ->
		Properties = Ps
	    ;   Properties = []
	    )
	;   must_be(atomic, Object, 1, get_props(Object,Properties))
	).

remember(Object, Value) :-
	(   atomic(Object) ->
	    retractall(recall(Object,_)),
	    assert(recall(Object,Value))
	;   must_be(atomic, Object, 1, remember(Object,Value))
	).

forget(Object) :-
	(   atomic(Object) ->
	    retractall(recall(Object,_))
	;   must_be(atomic, Object, 1, forget(Object))
	).

default(Object, Value, Default) :-
	(   atomic(Object) ->
	    (   recall(Object, Val) ->
		Value = Val
	    ;   Value = Default
	    )
	;   must_be(atomic, Object, 1, default(Object,Value,Default))
	).

%   Portable date and time

p_date(Year, Month, Day) :-
	date(Year, Month, Day).

p_time(Hours, Minutes, Seconds) :-
	time(Hours, Minutes, Seconds).

p_datime(Year, Month, Day, Hours, Minutes, Seconds) :-
	datime(date(Year,M,Day,Hours,Minutes,Seconds)),
	Month is M + 1.

'Repeat'(1) :- !.
'Repeat'(_).
'Repeat'(N) :-
	M is N - 1,
	'Repeat'(M).

run_time(N, Goal, Duration) :-
	integer(N),
	N >= 0,
	statistics(runtime, [T0|_]),
	( call(( 'Repeat'(N), (Goal -> fail) )) ; true ),
	statistics(runtime, [T1|_]),
	( call(( 'Repeat'(N), (true -> fail) )) ; true ),
	statistics(runtime, [T2|_]),
	Duration is ((T1-T0) - (T2-T1))/1000.0.

run_time(Goal, Duration) :-
	statistics(runtime, [Start|_]),
	( call(Goal) -> true ; true ),
	statistics(runtime, [Finish|_]),
	Duration is (Finish-Start)/1000.0.

/** Let the total size of a term be S, the number of distinct variables
    be V, and the number of variable occurrences be N. Then the cost of
    this approach is O(S + N.lg N). If we did it the obvious way, by
    carrying around a list of the variables so far and only adding a
    variable when it was new, the cost would be O(S + V.N), which can be
    much larger.  It could be done in the emulator at cost O(S), but
    we'd have to be able to garbage collect in the middle of the
    instruction, or else bound the number of variables allowed.
*/

varsin(Term, Vars) :-
	varsin(Term, Vs, []),
	sort(Vs, Vars).

varsin(Term) -->
	(   {var(Term)} -> [Term]
	;   {functor(Term, _, N)},
	    varsin(N, Term)
	).

varsin(N, Term) -->
	(   {N =:= 0} -> []
	;   {arg(N, Term, Arg)},
	    varsin(Arg),
	    {M is N-1},
	    varsin(M, Term)
	).

/*  tohollow(+Term, ?Copy, +Names[, ?Vars])
    is true when Copy is the same as Term, except that wherever
    Term has one of the atoms in Names, Copy has the corresponding
    element of Vars.  Note that Term need not be ground, nor need
    the elements of Vars be variables, nor need Copy be uninstantiated.
    The one restriction is that Names must be a proper list of atoms;
    in this draft it will simply fail if that is not so.

    It operates by building a balanced binary tree mapping elements of
    Names to the corresponding elements of Vars.  This costs O(N.lgN)
    where N is the number of names.  The rest of the tree traversal
    costs O(S.lgN) where S is the size of the Term.

    The operation could be performed in O(S+N) time if it were built
    in, but this is NOT a good operation to use because it has no
    way of telling atoms which are to be read as variables from atoms
    which are to be read as themselves.
*/

tohollow(Term, Copy, Names) :-
	tohollow(Term, Copy, Names, _).

tohollow(Term, Copy, Names, Vars) :-
	pairup(Names, Vars, Pairs, 0, N),
	(   N =:= 0 ->
	    Copy = Term
	;   keysort(Pairs, DictList),
	    totree(N, Dict, DictList, []),
	    tohollow_1(Term, Copy, Dict)
	).

pairup([], [], [], N, N).
pairup([Name|Names], [Var|Vars], [Name-Var|Pairs], N0, N) :-
	N1 is N0+1,
	atom(Name),
	pairup(Names, Vars, Pairs, N1, N).

totree(0, empty) --> !.
totree(1, leaf(W,V)) --> !,
	[W-V].
totree(N, node(W,V,L,R)) -->
	{A is (N-1) >> 1, Z is N-1-A},
	totree(A, L),
	[W-V],
	totree(Z, R).

lookup(empty, X, X).
lookup(leaf(W,V), A, X) :-
	( W == A -> X = V ; X = A ).
lookup(node(W,V,L,R), A, X) :-
	compare(O, A, W),
	lookup(O, A, X, L, R, V).

lookup(=, _, V, _, _, V).
lookup(<, A, X, L, _, _) :-
	lookup(L, A, X).
lookup(>, A, X, _, R, _) :-
	lookup(R, A, X).

tohollow_1(Term, Copy, Dict) :-
	(   var(Term) ->
	    Copy = Term
	;   functor(Term, F, N),
	    (   N > 0 ->
		functor(Copy, F, N),
		tohollow_1(N, Term, Copy, Dict)
	    ;   atom(Term) ->
		lookup(Dict, Term, Copy)
	    ;   Copy = Term
	    )
	).

tohollow_1(N, Term, Copy, Dict) :-
	(   N =:= 0 ->
	    true
	;   arg(N, Term, TermN),
	    arg(N, Copy, CopyN),
	    tohollow_1(TermN, CopyN, Dict),
	    M is N-1,
	    tohollow_1(M, Term, Copy, Dict)
	).

/*  The LPA Prolog Professional manual says of toground/2 says that
    "there will be no clash with any atom in Hollow that begins with
    an underscore".  Pleasant, but false.  If there is an atom which
    begins with an underscore, even if it is not one that toground/2
    could produce, toground/2 (and the others) reports a Control Error.
    Although *this* definition could clash with names _Q_#, at least
    it doesn't produce bogus error messages.

    tohollow/[3,4] and toground/[2,3,4] have been tested.
    toground/5 has not been tested, because I have not been able to
    get the one in LPA Prolog `Professional' to give me any answers
    that I can compare it with.
*/


toground(Term, Copy) :-
	toground(Term, Copy, _, _).

toground(Term, Copy, CopyVars) :-
	toground(Term, Copy, _, CopyVars).

toground(Term, Copy, TermVars, CopyVars) :-
	varsin(Term, TermVars),
	copy_term(Term/TermVars, Copy/CopyVars),
	bind(CopyVars, 0).

toground(Term, Copy, TermIn, CopyIn, UsedVars) :-
	varsin(Term, TermVars),
	pairup(TermIn, CopyIn, Pairs),
	keysort(Pairs, OrdPairs),
	matchup(TermVars, OrdPairs, InVars, InNames),
	copy_term(/(Term,InVars,TermVars), /(Copy,InNames,UsedVars)),
	bind(UsedVars, 0).

pairup([], [], []).
pairup([Var|Vars], [Name|Names], [Var-Name|Pairs]) :-
	var(Var),
	!,
	pairup(Vars, Names, Pairs).
pairup([_|Vars], [_|Names], Pairs) :-
	pairup(Vars, Names, Pairs).


matchup([], _, [], []).
matchup([V|Vars], Pairs, InVars, InNames) :-
	matchup_1(Pairs, V, InVars, InNames, Vars).

matchup_1([], _, [], [], _).
matchup_1([W-N|Pairs], V, InVars, InNames, Vars) :-
	compare(O, V, W),
	matchup_12(O, V, InVars, InNames, Vars, Pairs, W, N).

matchup_12(=, V, [W|InVars], [N|InNames], Vars, Pairs, W, N) :-
	matchup_1(Pairs, V, InVars, InNames, Vars).
matchup_12(<, _, InVars, InNames, Vars, Pairs, W, N) :-
	matchup_2(Vars, Pairs, InVars, InNames, W, N).
matchup_12(>, V, InVars, InNames, Vars, Pairs, _, _) :-
	matchup_1(Pairs, V, InVars, InNames, Vars).

matchup_2([], _, [], [], _).
matchup_2([V|Vars], Pairs, InVars, InNames, W, N) :-
	compare(O, V, W),
	matchup_12(O, V, InVars, InNames, Vars, Pairs, W, N).

bind([], _).
bind([Var|Vars], N0) :-
	N1 is N0+1,
	(   nonvar(Var) -> true
	;   number_chars(N1, Chars),
	    atom_chars(Var, [0'_,0'Q,0'_|Chars])
	),
	bind(Vars, N1).


