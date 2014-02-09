%   Package: show
%   Author : Richard A. O'Keefe
%   Updated: 25 Oct 1990
%   Defines: Some analogues of 'listing'.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(show, [
	show_builtins/0,	%  ->
	show_builtins/1,	%  KeySpec ->
	show_records/0,		%  ->
	show_records/1		%  KeySpec->
   ]).

sccs_id('"@(#)90/10/25 show.pl	58.1"').


/*  show_builtins		
    prints the names of all the built-in predicates
    on the current output stream, one per line.
*/
show_builtins :-
	binspec(_, Bins),
	'show builtins'(Bins).

/*  show_builtins(SPec)
    prints the names of all the built-in predicates matching Spec
    on the current output stream, one per line.
    Spec is Name, Name/Arity, or a list of them.
*/

show_builtins(Spec) :-
	binspec(Spec, Bins),
	'show builtins'(Bins).

'show builtins'([]) :-
	write('% ----'), nl.
'show builtins'([Spec|Specs]) :-
	user:portray_clause(Spec),
	'show builtins'(Specs).


%.  binspec takes a "bin specification", which is
%	a variable	-- any builtin
%	an atom		-- builtins with that name, any arity
%	Name/Arity	-- (either could be a variable)
%	[Spec,...,Spec]	-- all matches for any Spec
%   and returns a set of all the built-in predicates which match.
%   Bins is a list of Name/Arity pairs (not of skeletons).

binspec(BinSpec, Bins) :-
	binspec(BinSpec, List, []),
	sort(List, Bins).

binspec(Name/Arity, List0, List) :- !,
	(   (   atom(Name) ; var(Name)   ),
	    (   integer(Arity) ; var(Arity)   ) 
	->  binspec(Name, Arity, List0, List)
	;   format(user_error,
		'~N% Invalid argument ~q ignored by ~w~n',
		[Name/Arity,show_builtins]),
	    List0 = List
	).
binspec([Head|Tail], List0, List) :- !,
	binspec(Head, List0, List1),
	binspecs(Tail, List1, List).
binspec(Name, List0, List) :- atom(Name), !,
	binspec(Name, _, List0, List).
binspec(Other, List, List) :-
	format(user_error,
		'~N% Invalid argument ~q ignored by ~w~n',
		[Other,show_builtins]).

binspecs([], List, List).
binspecs([Head|Tail], List0, List) :-
	binspec(Head, List0, List1),
	binspecs(Tail, List1, List).

binspec(Name, Arity, List0, List) :-
	bagof(Name/Arity, current_bin_1(Name,Arity), L),
	!,
	append(L, List, List0).
binspec(_, _, List, List).

current_bin_1(Name, Arity) :-
	user:predicate_property(Skeleton, built_in),
	functor(Skeleton, Name, Arity).



/*  show_records		and
    show_records(Spec)

    write data base records to the current output stream.  The idea is
    that, like listing, it should be possible to reconsult the output
    and get back the records you started with (except that of course
    all the data base references will have changed).

    In order to do this, we have to write out commands, not clauses.
    The commands we write out could be built in Prolog commands, but
    if you can stand loading THIS library file, you can stand loading
    library(retract).  So for a data base key a/3 we would write
	:- wipe_every(a(A,B,C)).
	:- recordz(a(A,B,C), --first term--).
	...
	:- recordz(a(A,B,C), --last term--).
*/

show_records :-
	keyspec(_, Keys),
	'show records'(Keys).

show_records(Spec) :-
	keyspec(Spec, Keys),
	'show records'(Keys).


%.  keyspec takes a "key specification", which is
%	a variable	-- any key
%	an atom		-- keys with that name, any arity
%	Name/Arity	-- (either could be a variable)
%	a number	-- that key
%	[Spec,...,Spec]	-- all matches for any Spec
%   and returns a set of all the current keys which match.
%   Keys is a list of Name/Arity pairs (not of skeletons).

keyspec(KeySpec, Keys) :-
	keyspec(KeySpec, List, []),
	sort(List, Keys).

keyspec(Name/Arity, List0, List) :- !,
	(   atom(Name), integer(Arity)
	->  List0 = [Name/Arity|List]
	;   (   atom(Name) ; var(Name)   ),
	    (   integer(Arity) ; var(Arity)   ) 
	->  keyspec(Name, Arity, List0, List)
	;   number(Name) ->
	    List0 = [Name/0|List]
	;   format(user_error,
		'~N% Invalid argument ~q ignored by ~w~n',
		[Name/Arity,show_records]),
	    List0 = List
	).
keyspec([Head|Tail], List0, List) :- !,
	keyspec(Head, List0, List1),
	keyspecs(Tail, List1, List).
keyspec(Name, [Name/0|List], List) :- number(Name), !.
keyspec(Name, List0, List) :- atom(Name), !,
	keyspec(Name, _, List0, List).
keyspec(Other, List, List) :-
	format(user_error,
	    '~N% Invalid argument ~q ignored by ~w~n',
	    [Other,show_records]),

keyspecs([], List, List).
keyspecs([Head|Tail], List0, List) :-
	keyspec(Head, List0, List1),
	keyspecs(Tail, List1, List).

keyspec(Name, Arity, List0, List) :-
	bagof(Name/Arity, current_key_1(Name,Arity), L),
	!,
	append(L, List, List0).
keyspec(_, _, List, List).

current_key_1(Name, Arity) :-
	current_key(Name, Skel),
	functor(Skel, Name, Arity).


%   'show records'(NameAndArityPairs)
%   writes out each key in the list.  Note the user: prefixes on
%   the calls to portray_clause to suppress module name expansion
%   on these commands.  It is only because the recorded data base
%   is not a module of clauses that we want this.

'show records'([]).
'show records'([Name/Arity|Keys]) :-
	functor(Key, Name, Arity),
	user:portray_clause(:-(wipe_every(Key))),
	(   recorded(Key, Term, _),
	    user:portray_clause(:-(recordz(Key,Term))),
	    fail
	;   nl
	),
	'show records'(Keys).


