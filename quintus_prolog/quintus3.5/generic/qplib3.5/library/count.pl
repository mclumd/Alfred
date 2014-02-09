%   Package: count
%   Author : Richard A. O'Keefe
%   Updated: 30 Sep 1992
%   Purpose: Count predicate calls

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(count, [
	count/1,		% load(compile) files with counting
	clear_counts/0,		% clear all counters
	write_counts/1,		% write counts to a file
	increment_/1		% increment a counter
   ]).

:- meta_predicate
	count(:).

:- use_module(library(files), [
	can_open_file/3,
	delete_file/1
   ]).

sccs_id('"@(#)92/09/30 count.pl	66.1"').


/*  The idea of this is that you can take a program which you used to
    load by doing
	:- compile([F1,...,Fn]).
    and do
	:- count([F1,...,Fn]).
    instead.  The program will do what it always used to, except that it
    may run twice as slowly.

    library files are compiled, but not otherwise processed.
    Ordinary files are processed by taking clauses like

	p(X1,...,Xm) :-
		...,
		q(Y1,...,Yn),
		... .

    and turning them into

	p(X1,...,Xm) :-
		...,
		increment_(1234),
		q(Y1,...,Yn),
		... .

    This module maintains a table which maps quadruples to counter numbers:
	counter(p, m, q, n, 1234).

	:- clear_counts.

    clears all the counters.  You only have to do this to reset things;
    new counters are created with value 0.

	:- write_counts(FileName).

    writes the current values of the counts to FileName.  To keep the
    size of the file down, this version doesn't write zero counts.
    The format of FileName is

	calleeName/calleeArity<TAB>callerName/callerArity<TAB>count

    This is suitable for processing by awk(1) and other UNIX utilities.

    The major restriction is that this module doesn't know about modules
    at all.  If/when we support something like this, it'll be built in
    at a much lower level.  A consequence of this restriction is that
    meta_predicates are not properly handled.  Some few predicates such
    as setof/3 are handled "transparently".

    Another restriction is that because this is implemented by writing
    a modified file, dynamically asserted clauses will not have the
    right counts, and clauses for dynamic predicates which appear in the
    file will not look the way you might expect.

    This is not really a general facility.  It was put together in an
    evening for one particular application.
*/

:- dynamic
	counter/5.


%   count(+Files)
%   looks pretty much like compile/1 command.  It should always succeed.

count(Files) :-
	count(Files, user).


count([], _) :- !.
count([File|Files], Module) :- !,
	count(File, Module),
	count(Files, Module).
count(library(File), Module) :- !,
	Module:compile(library(File)).
count(Module:Files, _) :- !,
	count(Files, Module).
count(File, Module) :-
	atom(File),
	absolute_file_name(File, AbsFile),
	can_open_file(AbsFile, read, warn),
	counted_file_name(AbsFile, NewFile),
	can_open_file(NewFile, write, warn),
	rewrite_file(AbsFile, NewFile),
	Module:compile(NewFile),
	delete_file(NewFile),
	fail.
count(_, _).


%   counted_file_name(+AbsFile, -NewFile)
%   is given an absolute pathname, and makes a variant of it.  Since
%   the front is absolute (e.g. /usr/local/src/foo.pl) we have to hack
%   the end.  This code isn't quite right, because if the last
%   component is already 14 characters (System V) or 255 characters
%   (4.xBSD) long, the # we add will be lost.

counted_file_name(AbsFile, NewFile) :-
	atom_chars(AbsFile, AbsChars),
	append(AbsChars, "#", NewChars),
	atom_chars(NewFile, NewChars).


%   rewrite_file(+AbsFile, +NewFile)
%   copies clauses from AbsFile to NewFile, adding increment_/1 calls.
%   It's really very stupid.

rewrite_file(AbsFile, NewFile) :-
	seeing(OldInput),
	telling(OldOutput),
	see(AbsFile),
	tell(NewFile),
	repeat,
	    read(Term),
	    expand_term(Term, Clause),
	    rewrite_clause(Clause, CountedClause),
	    user:portray_clause(CountedClause),
	    Term == end_of_file,
	!,
	see(OldInput),
	tell(OldOutput),
	close(AbsFile),
	close(NewFile).


rewrite_clause(:-(Command),	:-(Command)) :- !.
rewrite_clause(?-(Query),	?-(Query))   :- !.
rewrite_clause(:-(Head,Body0),	:-(Head,Body)) :-
	nonvar(Head),
	functor(Head, P, N),
	atom(P),
	!,
	rewrite_body(Body0, P/N, Body).
rewrite_clause(Unit, Unit).


rewrite_body(X, _, X) :- var(X), !.
rewrite_body(setof(T,G0,L), H, setof(T,G,L)) :- !,
	rewrite_body(G0, H, G).
rewrite_body(bagof(T,G0,L), H, bagof(T,G,L)) :- !,
	rewrite_body(G0, H, G).
rewrite_body(findall(T,G0,L), H, findall(T,G,L)) :- !,
	rewrite_body(G0, H, G).
rewrite_body((A0,B0), H, (A,B)) :- !,
	rewrite_body(A0, H, A),
	rewrite_body(B0, H, B).
rewrite_body((A0 ; B0), H, (A ; B)) :- !,
	rewrite_body(A0, H, A),
	rewrite_body(B0, H, B).
rewrite_body((A0 -> B0), H, (A -> B)) :- !,
	rewrite_body(A0, H, A),
	rewrite_body(B0, H, B).
rewrite_body(\+ A0, H, \+ A) :- !,
	rewrite_body(A0, H, A).
rewrite_body(X, P/M, (increment_(Ctr),X)) :-
	\+ special_goal(X),
	!,
	functor(X, Q, N),
	get_counter(P, M, Q, N, Ctr).
rewrite_body(X, _, X).


%   special_goal(+Goal)
%   is a table of the built-in predicates which are regarded as so "basic"
%   that they shouldn't be counted.  Note that control structures have
%   mostly been taken care of already, so don't appear here.

special_goal(compare(_,_,_)).
special_goal(repeat).
special_goal(nl).
special_goal(put(_)).
special_goal(get0(_)).
special_goal(_=.._).
special_goal(tab(_)).
special_goal(get(_)).
special_goal(ttyget(_)).
special_goal(ttyget0(_)).
special_goal(ttyput(_)).
special_goal(ttytab(_)).
special_goal(ttynl).
special_goal(_=_).
special_goal(var(_)).
special_goal(nonvar(_)).
special_goal(atomic(_)).
special_goal(atom(_)).
special_goal(integer(_)).
special_goal(float(_)).
special_goal(number(_)).
special_goal(arg(_,_,_)).
special_goal(functor(_,_,_)).
special_goal(_@<_).
special_goal(_@>_).
special_goal(_@=<_).
special_goal(_@>=_).
special_goal(_==_).
special_goal(_\==_).
special_goal(_^_).
special_goal(\+_).
special_goal(_ is _).
special_goal(_=:=_).
special_goal(_=\=_).
special_goal(_<_).
special_goal(_>_).
special_goal(_=<_).
special_goal(_>=_).
special_goal(!).
special_goal(fail).
special_goal(false).
special_goal(true).
special_goal(otherwise).
special_goal('C'(_,_,_)).




get_counter(P, M, Q, N, Ctr) :-
	counter(P, M, Q, N, Ctr),
	!.
get_counter(P, M, Q, N, Ctr) :-
	top_count(Ctr0),
	Ctr is Ctr0+1,
	add_counter(Ctr),
	asserta(counter(P,M,Q,N,Ctr)).

top_count(Ctr0) :-
	counter(_, _, _, _, Ctr0),
	!.
top_count(0).


write_counts(File) :-
	telling(OldOutput),
	can_open_file(File, write, warn),
	tell(File),
	(   counter(P, M, Q, N, Ctr),
	    read_counter(Ctr, Count),
	    Count > 0,
	    write(Q/N), put(9), write(P/M), put(9), write(Count), nl,
	    fail
	;   true
	),
	tell(OldOutput),
	close(File).

/*  STUBS:

increment_(_) :- true.
clear_counts :- abort.
read_counter(_, _) :- abort.
add_counter(_) :- true.
*/

foreign_file(library(system(libpl)),
    [
	increment_,
	clear_counts,
	read_counter,
	add_counter
    ]).
foreign(increment_,
	increment_(+integer)).
foreign(add_counter,
	add_counter(+integer)).
foreign(clear_counts,
	clear_counts).
foreign(read_counter,
	read_counter(+integer, [-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign, 2),
   abolish(foreign_file, 2).

