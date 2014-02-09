%   Package: pairup
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Defines: assorted flavours of association lists.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(pairup, [
	assoc_cons/3,	assoc_list/3,	assoc_pair/3,
	first_cons/3,	first_list/3,	first_pair/3,	first_side/3,
	first_cons/4,	first_list/4,	first_pair/4,	first_side/4,
	pairup_cons/3,	pairup_list/3,	pairup_pair/3,	pairup_side/3,
	select_cons/4,	select_list/4,	select_pair/4,	select_side/4,
	select_cons/5,	select_list/5,	select_pair/5,	select_side/5,
	value_cons/3,	value_list/3,	value_pair/3,	value_side/3
   ]).

/*  This package is included for interest's sake only.  All of the
    operations are either versions of keys_and_values/3 or of the
    well-known predicate member/2.  If you really need to maintain
    an association between keys and values, you should use library(assoc).

    For each representation, we have

	pairup_<type>(?Keys, ?Values, ?Pairs)
	    which may be used to build Pairs or to take it apart.
	    Either Keys, Values, or Pairs should be a proper list.
	    It is like keys_and_values/3.

	value_<type>(?Key, +Pairs, ?Value)
	    which may be used to find the Value associated with
	    a Key or the Key associated with a Value.  It is like
	    member/2.

	select_<type>(?Key, ?Pairs0, ?Value, ?Pairs)
	    which is like select/4:  it enumerates Key-Value pairs
	    which are in Pairs0, and states that Pairs is the same
	    as Pairs0 except for lacking that pair.  Note that the
	    first three arguments agree with value_<type>/3.

	select_<type>(?Key, ?Pairs1, ?Value1, ?Pairs2, ?Value2)
	    is true when Pairs1 and Pairs2 are identical except that
	    where Pairs1 assigns Key->Value1, in exactly the same
	    place Pairs2 assigns Key->Value2.  It is like select/4.
	    Note that the argument order agrees with select_<type>/4.

	first_<type>(?Key, +Pairs, ?Value)
	    has only the first solution of value_<type>/3.  It may
	    be used to find a Key or a Value, but has only one
	    solution.  It is like memberchk/2.

	first_<type>(+Key, +Pairs, +Default, ?Value)
	    is like first_<type>/3, except that if the Key does not
	    correspond to any pair in Pairs Value will be unified
	    with Default.  It is often useful to pass Default=Key.
	    Note that there is no assoc_<type>/4, because when it
	    gets to the end of the Pairs list, assoc_<type>/3 cannot
	    tell whether nothing matched or whether the caller
	    rejected the matches it found, so cannot tell whether to
	    use the default or not.  The Default value is returned
	    when the Pairs list is malformed, as well as when empty.
	    These predicates were motivated by the Lazy ML library.

	assoc_<type>(?Key, +Pairs, ?Pair)
	    returns the actual Pair of Pairs which has the key Key.
	    It is like member/2.  This is not always defined, as
	    some versions of pairup do not make a separate data
	    structure for each pair.

    Note that {value,first,assoc}_<type>/3 follow the "indexed
    selector" convention: first the index/selector, then the collection
    to be selected from, finally the value selected.  This is just like
    arg/3.

    The ONLY predicates in this file which are considered to be good
    use of Prolog data structures are the _pair family.  The others are
    included because people have thought they had a use for them, and
    we might as well use the same names for things even if we don't
    agree about whether they are good.
*/

sccs_id('"@(#)89/08/29 pairup.pl    33.1"').



%   pairup_cons(Keys, Values, KeysAndValues)
%   makes a list of [Key|Value] pairs.  This is how Lisp would do it,
%   but it is appallingly bad style in Prolog.  In Prolog, you should
%   NEVER use "cons" to represent records with a fixed number of
%   fields.  The recommended "pair" constructor is (-)/2.

pairup_cons([], [], []).
pairup_cons([Key|Keys], [Value|Values], [[Key|Value]|Pairs]) :-
	pairup_cons(Keys, Values, Pairs).


%   value_cons(Key, Pairs, Value)
%   enumerates the Values associated with Key in Pairs.

value_cons(Key, [[Key|Value]|_], Value).
value_cons(Key, [_|Pairs], Value) :-
	value_cons(Key, Pairs, Value).


%   first_cons(Key, Pairs, Value)
%   returns the first Value associated with Key in Pairs.

first_cons(Key, [[Key|Value]|_], Value) :- !.
first_cons(Key, [_|Pairs], Value) :-
	first_cons(Key, Pairs, Value).


%   first_cons(Key, Pairs, Default, Value)
%   returns the first Value associated with Key in Pairs,
%   or Default if there is no such Value.

first_cons(Key, [[Key|Value]|_], _, Value) :- !.
first_cons(Key, [_|Pairs], Default, Value) :- !,
	first_cons(Key, Pairs, Default, Value).
first_cons(_, _, Value, Value).


%   select_cons(Key, Pairs0, Value, Pairs)
%   enumerates the [Key|Value] pairs in Pairs0 and withdraws them,
%   yielding Pairs (compare select/3).

select_cons(Key, [[Key|Value]|Pairs], Value, Pairs).
select_cons(Key, [Pair|Pairs0], Value, [Pair|Pairs]) :-
	select_cons(Key, Pairs0, Value, Pairs).


%   select_cons(Key, Pairs1, Value1, Pairs2, Value2)
%   is true when Pairs1 and Pairs2 are identical except that
%   value_cons(Key, Pairs1, Value1) and value_cons(Key, Pairs2, Value2).

select_cons(Key, [[Key|Value1]|Pairs], Value1, [[Key|Value2]|Pairs], Value2).
select_cons(Key, [Pair|Pairs1], Value1, [Pair|Pairs2], Value2) :-
	select_cons(Key, Pairs1, Value1, Pairs2, Value2).


%   assoc_cons(Key, Pairs, Pair)
%   enumerates the [Key|Value] pairs associated with Key in Pair.

assoc_cons(Key, [Pair|_], Pair) :-
	Pair = [Key|_].
assoc_cons(Key, [_|Pairs], Pair) :-
	assoc_cons(Key, Pairs, Pair).



%   pairup_list(Keys, Values, KeysAndValues)
%   makes a list of [Key,Value] pairs.  This is how Lisp might do it,
%   but it is appallingly bad style in Prolog.  In Prolog, you should
%   NEVER use "list" to represent records with a fixed number of
%   fields.  The recommended "pair" constructor is (-)/2.

pairup_list([], [], []).
pairup_list([Key|Keys], [Value|Values], [[Key,Value]|Pairs]) :-
	pairup_list(Keys, Values, Pairs).


%   value_list(Key, Pairs, Value)
%   enumerates the Values associated with Key in Pairs.

value_list(Key, [[Key,Value]|_], Value).
value_list(Key, [_|Pairs], Value) :-
	value_list(Key, Pairs, Value).


%   first_list(Key, Pairs, Value)
%   returns the first Value associated with Key in Pairs.

first_list(Key, [[Key,Value]|_], Value) :- !.
first_list(Key, [_|Pairs], Value) :-
	first_list(Key, Pairs, Value).


%   first_list(Key, Pairs, Default, Value)
%   returns the first Value associated with Key in Pairs,
%   or Default if there is no such Value.

first_list(Key, [[Key,Value]|_], _, Value) :- !.
first_list(Key, [_|Pairs], Default, Value) :- !,
	first_list(Key, Pairs, Default, Value).
first_list(_, _, Value, Value).


%   select_list(Key, Pairs0, Value, Pairs)
%   enumerates the [Key,Value] pairs in Pairs0 and withdraws them,
%   yielding Pairs (compare select/3).

select_list(Key, [[Key,Value]|Pairs], Value, Pairs).
select_list(Key, [Pair|Pairs0], Value, [Pair|Pairs]) :-
	select_list(Key, Pairs0, Value, Pairs).


%   select_list(Key, Pairs1, Value1, Pairs2, Value2)
%   is true when Pairs1 and Pairs2 are identical except that
%   value_list(Key, Pairs1, Value1) and value_list(Key, Pairs2, Value2).
%   Things which are not [K,V] pairs are retained in both lists.

select_list(Key, [[Key,Value1]|Pairs], Value1, [[Key,Value2]|Pairs], Value2).
select_list(Key, [Pair|Pairs1], Value1, [Pair|Pairs2], Value2) :-
	select_list(Key, Pairs1, Value1, Pairs2, Value2).


%   assoc_list(Key, Pairs, Pair)
%   enumerates the [Key,Value] pairs associated with Key in Pair.
%   Note that if Pairs contains lists [Key|...] which are not
%   two-element lists, assoc_list/3 will NOT find them, though
%   assoc_cons/3 WOULD.

assoc_list(Key, [Pair|_], Pair) :-
	Pair = [Key,_].
assoc_list(Key, [_|Pairs], Pair) :-
	assoc_list(Key, Pairs, Pair).



%   pairup_pair(Keys, Values, KeysAndValues)
%   makes a list of Key-Value pairs.  This is the recommended method
%   in Prolog.  Not the least of the virtues of this representation
%   is that you can give it to keysort/2.  Also, it can be type-
%   checked if you have the DEC-10 Prolog type checker.

pairup_pair([], [], []).
pairup_pair([Key|Keys], [Value|Values], [Key-Value|Pairs]) :-
	pairup_pair(Keys, Values, Pairs).


%   value_pair(Key, Pairs, Value)
%   enumerates the Values associated with Key in Pairs.

value_pair(Key, [Key-Value|_], Value).
value_pair(Key, [_|Pairs], Value) :-
	value_pair(Key, Pairs, Value).


%   first_pair(Key, Pairs, Value)
%   returns the first Value associated with Key in Pairs.

first_pair(Key, [Key-Value|_], Value) :- !.
first_pair(Key, [_|Pairs], Value) :-
	first_pair(Key, Pairs, Value).


%   first_pair(Key, Pairs, Default, Value)
%   returns the first Value associated with Key in Pairs,
%   or Default if there is no such Value.

first_pair(Key, [[Key-Value]|_], _, Value) :- !.
first_pair(Key, [_|Pairs], Default, Value) :- !,
	first_pair(Key, Pairs, Default, Value).
first_pair(_, _, Value, Value).


%   select_pair(Key, Pairs0, Value, Pairs)
%   enumerates the Key-Value pairs in Pairs0 and withdraws them,
%   yielding Pairs (compare select/3).

select_pair(Key, [Key-Value|Pairs], Value, Pairs).
select_pair(Key, [Pair|Pairs0], Value, [Pair|Pairs]) :-
	select_pair(Key, Pairs0, Value, Pairs).


%   select_pair(Key, Pairs1, Value1, Pairs2, Value2)
%   is true when Pairs1 and Pairs2 are identical except that
%   value_pair(Key, Pairs1, Value1) and value_pair(Key, Pairs2, Value2).

select_pair(Key, [Key-Value1|Pairs], Value1, [Key-Value2|Pairs], Value2).
select_pair(Key, [Pair|Pairs1], Value1, [Pair|Pairs2], Value2) :-
	select_pair(Key, Pairs1, Value1, Pairs2, Value2).


%   assoc_pair(Key, Pairs, Pair)
%   enumerates the Key-Value pairs associated with Key in Pair.

assoc_pair(Key, [Pair|_], Pair) :-
	Pair = Key-_.
assoc_pair(Key, [_|Pairs], Pair) :-
	assoc_pair(Key, Pairs, Pair).



%   pairup_side(Keys, Values, KeysAndValues)
%   makes a list where Keys and Values alternate.  For example,
%   pairup_side([a,b,c], [1,2,3], [a,1,b,2,c,3]) is true.
%   This is called "side" because the keys and values are
%   side-by-side in the result.  This isn't nicely typed, but
%   it could be typed by overloading cons.
%   type list(X) --> [] | [X|list(X)].	  	is standard.
%   type side(X,Y) --> [] | [X|side(Y,X)].	would be needed.

pairup_side([], [], []).
pairup_side([Key|Keys], [Value|Values], [Key,Value|Pairs]) :-
	pairup_side(Keys, Values, Pairs).


%   value_side(Key, Pairs, Value)
%   enumerates the Values associated with Key in Pairs.
%   Note that this and first_side have to step in twos down Pairs.

value_side(Key, [Key,Value|_], Value).
value_side(Key, [_,_|Pairs], Value) :-
	value_side(Key, Pairs, Value).


%   first_side(Key, Pairs, Value)
%   returns the first Value associated with Key in Pairs.

first_side(Key, [Key,Value|_], Value) :- !.
first_side(Key, [_,_|Pairs], Value) :-
	first_side(Key, Pairs, Value).


%   first_side(Key, Pairs, Default, Value)
%   returns the first Value associated with Key in Pairs,
%   or Default if there is no such Value.

first_side(Key, [Key,Value|_], _, Value) :- !.
first_side(Key, [_,_|Pairs], Default, Value) :- !,
	first_side(Key, Pairs, Default, Value).
first_side(_, _, Value, Value).


%   select_side(Key, Pairs0, Value, Pairs)
%   enumerates the Key, Value pairs in Pairs0 and withdraws them,
%   yielding Pairs (compare select/3).

select_side(Key, [Key,Value|Pairs], Value, Pairs).
select_side(Key, [K,V|Pairs0], Value, [K,V|Pairs]) :-
	select_side(Key, Pairs0, Value, Pairs).


%   select_side(Key, Pairs1, Value1, Pairs2, Value2)
%   is true when Pairs1 and Pairs2 are identical except that
%   value_side(Key, Pairs1, Value1) and value_side(Key, Pairs2, Value2).

select_side(Key, [Key,Value1|Pairs], Value1, [Key,Value2|Pairs], Value2).
select_side(Key, [K,V|Pairs1], Value1, [K,V|Pairs2], Value2) :-
	select_side(Key, Pairs1, Value1, Pairs2, Value2).


%   There is no assoc_side/3 because the Key and Value are not
%   wrapped up in a common term.  Instead, you should use
%   value_side(Key, Pairs, Value), which will give you every
%   Key and Value in turn.

