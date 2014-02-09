%   Package: more_lists
%   Author : Richard A. O'Keefe
%   Updated: 28 Mar 1990
%   Purpose: some list operations useful for text processing.

:- module(more_lists, [
	adjust/5,	% Direction x Width x Pad x List -> List
	adjust/6,	% Direction x Width x Pad x List -> List\List
	bnd/2,		% Length x List
	bnd/3,		% Length x List\List
	bnd/4,		% Length x List\List x List
	len/2,		% Length <-> List
	len/3,		% Length <-> List\List
	len/4,		% Length <-> List <-> List\List
	lit/3,		% List <-> List\List
	oneof/3,	% Set x List\List
	oneof/4,	% Set x (Element <-> List\List)
	replist/2,	% Datum x List
	replist/3,	% Datum x Length <-> List
	replist/4,	% Datum x Length <-> List\List
	spaces/2,	% Length <-> List
	spaces/3	% Length <-> List\List
   ]).
:- use_module(library(types), [
/*	ground/1,		% now a builtin */
	must_be_integer/3,
	must_be_symbol/3,
	must_be_proper_list/3,
	proper_list/1
   ]).


sccs_id('"@(#)90/03/28 morelists.pl	38.1"').


/* pred
	adjust(atom, integer, T, list(T), list(T)),
	adjust(atom, integer, T, list(T), list(T), list(T)),
	    adjust(atom, integer, T, list(T), list(T), list(T), integer),
	bnd(integer, list(T)),
	    bnd_1(list(T), integer),
	bnd(integer, list(T), list(T)),
	    bnd_1(integer, list(T), list(T)),
	bnd(integer, list(T), list(T), list(T)),
	    bnd_1(list(T), integer, list(T), list(T)),
	len(integer, list(T)),
	    len_find(list(T), integer, integer),
	    len_make(integer, list(T)),
	len(integer, list(T), list(T)),
	    len_find(list(T), list(T), integer, integer),
	    len_make(integer, list(T), list(T)),
	len(integer, list(T), list(T), list(T)),
	    len_find(list(T), list(T), list(T), integer, integer),
	    len_make(integer, list(T), list(T), list(T)),
	lit(list(T), list(T), list(T)),
	replist(T, list(T)),
	    replist_find(list(T), T),
	replist(T, integer, list(T)),
	    replist_find(list(T), T, integer, integer),
	    replist_make(integer, T, list(T)),
	replist(T, integer, list(T), list(T)),
	    replist_find(list(T), list(T), T, integer, integer),
	    replist_make(integer, T, list(T), list(T)),
	spaces(integer, list(integer)),
	spaces(integer, list(integer), list(integer)).
*/

%   bnd(+Length, ?List)
%   is true when Length is a non-negative integer and List is a list
%   having at most Length elements.  This can be used to test the
%   length of a list, or it can be used to generate lists up to a
%   given limit.  When used for generation, it will try shorter lists
%   before longer ones.

bnd(Length, List) :-
	(   integer(Length) ->
	    Length >= 0,
	    bnd_1(List, Length)
	;   must_be_integer(Length, 1, bnd(Length,List))
	).

bnd_1([], _).
bnd_1([_|L], N) :-
	M is N-1, M >= 0,
	bnd_1(L, M).



%   bnd(+Length, ?S0, ?S)
%   is true when Length is a non-negative integer and the list segment
%   S0\S contains at most Length elements.  This is mostly used to
%   generate segments increasing in length from 0 to Length; in a
%   grammar rule len(3) will match exactly 3 elements, while bnd(3)
%   will match 0, 1, 2, or 3 elements.

bnd(Length, S0, S) :-
	(   integer(Length) ->
	    Length >= 0,
	    bnd_1(Length, S0, S)
	;   must_be_integer(Length, 1, bnd(Length,S0,S))
	).

bnd_1(N, S0, S) :-
	(   N =:= 0 -> S0 = S
	;   S0 = S
	;   S0 = [_|S1], M is N-1,
	    bnd_1(M, S1, S)
	).



%   bnd(+Length, ?List, ?S0, ?S)
%   is true when bnd(Length, List) & append(List, S, S0), that is,
%   when Length is a non-negative integer, List is the list represented
%   by the segment S0\S, and List (S0\S) has at most Length elements.
%   It is meant for use in grammar rules, where bnd(3,X) will match
%   0..3 elements and return a list of them as X.

bnd(Length, List, S0, S) :-
	(   integer(Length) ->
	    Length >= 0,
	    bnd_1(List, Length, S0, S)
	;   must_be_integer(Length, 1, bnd(Length,List,S0,S))
	).

bnd_1([], _, S, S).
bnd_1([X|Xs], N, [X|S0], S) :-
	M is N-1, M >= 0,
	bnd_1(Xs, M, S0, S).



%   len(?Length, ?List)
%   is true when List is a list and Length is a non-negative integer
%   and List has exactly Length elements.  The normal use of this is
%   to find the Length of a given List, but it can be used any way
%   around provided that
%	Length is instantiated, or
%	List   is a proper list.
%   This is identical to length/2 except for the argument order.
%   This predicate is the basis of most things in this file.  You'll
%   find another group of similar predicates in library(listparts).

len(Length, List) :-
	(   var(Length) ->
	    len_find(List, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    len_make(Length, List)
	;   must_be_integer(Length, 1, len(Length,List))
	).

len_find([], N, N).
len_find([_|List], N0, N) :-
	N1 is N0+1,
	len_find(List, N1, N).

len_make(0, List) :- !,
	List = [].
len_make(N0, [_|List]) :-
	N1 is N0-1,
	len_make(N1, List).



%   len(?Length, ?List0, ?List)
%   is true when append(Part, List, List0) & len(Length, Part)
%   for some list Part.  The idea is to have something we can use
%   in grammar rules.  For example, if we want to recognise
%   phone numbers in the for "(###) ###-####" and don't want the
%   bother of checking that the # characters are digits, we can
%   write
%	phone --> "(", len(3), ") ", len(3), "-", len(4).
%   The code was derived from len/2.

len(Length, List0, List) :-
	(   var(Length) ->
	    len_find(List0, List, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    len_make(Length, List0, List)
	;   must_be_integer(Length, 1, len(Length,List0,List))
	).

len_find(List, List, N, N).
len_find([_|List0], List, N0, N) :-
	N1 is N0+1,
	len_find(List0, List, N1, N).

len_make(0, List0, List) :- !,
	List0 = List.
len_make(N0, [_|List0], List) :-
	N1 is N0-1,
	len_make(N1, List0, List).



%   len(?Length, ?Part, ?List0, ?List)
%   is true when append(Part, List, List0) & len(Length, Part).
%   This too is for use in grammar rules.  The difference between
%   len(N) and len(N,X) as non-terminals is that len(N,X) gives
%   us the elements which matched.  This predicate can also be
%   used as a version of append/3 which returns (or is guided by)
%   the length of the Part argument.

len(Length, Part, List0, List) :-
	(   var(Length) ->
	    len_find(Part, List0, List, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    len_make(Length, Part, List0, List)
	;   must_be_integer(Length, 1, len(Length,Part,List0,List))
	).


len_find([], List, List, N, N).
len_find([Head|Tail], [Head|List0], List, N0, N) :-
	N1 is N0+1,
	len_find(Tail, List0, List, N1, N).

len_make(0, Part, List0, List) :- !,
	Part = [],
	List0 = List.
len_make(N0, [Head|Tail], [Head|List0], List) :-
	N1 is N0-1,
	len_make(N1, Tail, List0, List).



%   lit(?Part, ?List0, ?List)
%   is true when append(Part, List, List0).  It is just append/3 with
%   the last two argument switched so that it can be used in DCGs.

lit([], List, List).
lit([X|Xs], [X|List1], List) :-
	lit(Xs, List1, List).



%   oneof(+Set, ?List0, ?List)
%   is true when List0\List = [X] and X is an element of Set.
%   It should only be used when Set is ground.

oneof(Set, [Element|List], List) :-
	mem(Element, Set).


%   oneof(+Set, ?Element, ?List0, ?List)
%   is true when List0\List = [Element] and Element is an element of Set.
%   It should only be used when Set is ground.

oneof(Set, Element, [Element|List], List) :-
	mem(Element, Set).


%.  mem(?Element, +Set)
%   where Set is ground, is used either to check whether a given Element
%   occurs in the set, or to enumerate elements from that set.  When the
%   Element is ground, we would rather not leave any choice-points about
%   so we insert a cut.  We need a faster ground test.

mem(Element, [X|Xs]) :-
	(   ground(Element) -> mem(Xs, X, Element), !
	;   /* enumerating */  mem(Xs, X, Element)
	).

mem([], X, X).
mem([_|_], X, X).
mem([X|Xs], _, Element) :-
	mem(Xs, X, Element).



%   replist(?Datum, +List)
%   is true when List is a list all of whose elements equal Datum.
%   It will terminate if either List is a proper list or it is a
%   partial list one of whose known elements does not unify with
%   Datum.  If called with List a variable, it will enumerate
%   successively longer Lists.

replist(Datum, List) :-
	replist_find(List, Datum).

replist_find([], _).
replist_find([X|Xs], X) :-
	replist_find(Xs, X).



%   replist(?Datum, ?Length, ?List)
%   is true when replist(List, Datum) & length(List, Length).
%   Note that the parameters are the wrong way around for this to
%   be part of the library(length) family.

replist(Datum, Length, List) :-
	(   var(Length) ->
	    replist_find(List, Datum, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    replist_make(Length, Datum, List)
	;   must_be_integer(Length, 2, replist(Datum,Length,List))
	).

replist_find([], _, N, N).
replist_find([X|Xs], X, N0, N) :-
	N1 is N0+1,
	replist_find(Xs, X, N1, N).

replist_make(0, _, Xs) :- !,
	Xs = [].
replist_make(N0, X, [X|Xs]) :-
	N1 is N0-1,
	replist_make(N1, X, Xs).



%   replist(?Datum, ?Length, ?List0, ?List)
%   is true when append(Part, List, List0) & replist(Datum, Length, Part)
%   for some list Part.  The idea is to have a version of replist/3 that
%   we can use in grammar rules, e.g.
%	... -> ..., replist(0'*, 20), ...
%   Note that there is no replist(Datum, Length, Part, List0, List) to
%   give us back the elements which matched.  We can rebuild the Part
%   by calling replist/3.

replist(Datum, Length, List0, List) :-
	(   var(Length) ->
	    replist_find(List0, List, Datum, 0, Length)
	;   integer(Length) ->
	    Length >= 0,
	    replist_make(Length, Datum, List0, List)
	;   must_be_integer(Length, 2, replist(Datum,Length,List0,List))
	).

replist_find(List, List, _, N, N).
replist_find([X|List0], List, X, N0, N) :-
	N1 is N0+1,
	replist_find(List0, List, X, N1, N).

replist_make(0, _, List0, List) :- !,
	List0 = List.
replist_make(N0, X, [X|List0], List) :-
	N1 is N0-1,
	replist_make(N1, X, List0, List).



%   spaces(?Length, ?Chars)
%   is true when Chars is a list of Length blanks.

spaces(Length, Chars) :-
	replist(0' , Length, Chars).



%   spaces(?Length, ?Chars0, ?Chars)
%   is true when append(Spaces, Chars, Chars0) & spaces(Length, Spaces)
%   for some list Spaces.  This is for use in grammar rules.

spaces(Length, Chars0, Chars) :-
	replist(0' , Length, Chars0, Chars).



/*  adjust(+Direction, +Width, +Pad, +Chars, ?Result)
    is true when
	Direction is left | right | centre
	Width is an integer
	Pad can be anything type-compatible with Chars
	Chars is a list (normally of characters, but could be anything)
	Result = Before // Chars // After and
	length(Result) >= Width and
	replist(Pad, N1, Before) and
	replist(Pad, N2, After) and
	Direction = left -> N1 = 0 | right -> N2 = 0 | abs(N1-N2) < 2 and
	Result is as short as possible.
    I would dearly like to make this invertible, but consider:
	if Result = Chars there are infinitely many values of Width.
	even if Width is restricted to non-negative values, still too many.
	And of course Direction is ambiguous.
    The deciding factor was the fact that Americans spell 'centre' as
    'center', so we might as well have a strict input.
    Just to make the Direction clearer, it is where the Chars go,
    not where the padding goes.  (Obviously, for 'centre', the Chars
    must go in the centre, not the padding!)

    adjust(+Direction, +Width, +Pad, +Chars, ?Result0, ?Result)
    is a version for use in grammar rules or whenever you want a
    difference list result.
*/

adjust(Direction, Width, Pad, Chars, Result) :-
	adjust(Direction, Width, Pad, Chars, Result, [], 5).

adjust(Direction, Width, Pad, Chars, Result0, Result) :-
	adjust(Direction, Width, Pad, Chars, Result0, Result, 6).

adjust(Direction, Width, Pad, Chars, Result0, Result, _) :-
	integer(Width),
	atom(Direction),
	proper_list(Chars),	
	len_find(Chars, List0, List, 0, Length),
	!,
	(   Length >= Width ->
	    Result0 = List0, Result = List
	;   atom_chars(Direction, [D|_]),
	    Needed is Width-Length,
	    (   D =:= "l" -> N2 = Needed, N1 = 0
	    ;   D =:= "L" -> N2 = Needed, N1 = 0
	    ;   D =:= "r" -> N1 = Needed, N2 = 0
	    ;   D =:= "R" -> N1 = Needed, N2 = 0
	    ;   N1 is Needed // 2,
		N2 is Needed - N1
	    ),
	    replist(Pad, N1, Result0, List0),
	    replist(Pad, N2, List, Result)
	).
adjust(Direction, Width, Pad, Chars, Result0, Result, Which) :-
	(   Which =:= 5 ->
	    Goal = adjust(Direction,Width,Pad,Chars,Result0)
	;   Goal = adjust(Direction,Width,Pad,Chars,Result0,Result)
	),
	must_be_symbol(Direction, 1, Goal),
	must_be_integer(Width, 2, Goal),
	must_be_proper_list(Chars, 4, Goal).

