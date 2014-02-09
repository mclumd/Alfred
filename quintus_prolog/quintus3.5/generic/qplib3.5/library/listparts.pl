%   Module : list_parts
%   Author : Richard A. O'Keefe
%   Updated: 26 Dec 1989
%   Defines: names for parts of lists.

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(list_parts, [
	cons/3,			last/3,
	head/2,			tail/2,
	prefix/2,		proper_prefix/2,
	suffix/2,		proper_suffix/2,
	segment/2,		proper_segment/2,
	sublist/2,		proper_sublist/2	% COMPATIBILITY ONLY
   ]).

/* pred
	cons(T, list(T), list(T)),
	last(list(T), T, list(T)),
	head(list(T), T),
	tail(list(T), list(T)),
	prefix(list(T), list(T)),
	suffix(list(T), list(T)),
	segment(list(T), list(T)),
	proper_prefix(list(T), list(T)),
	proper_suffix(list(T), list(T)),
	proper_segment(list(T), list(T)).
*/

sccs_id('"@(#)89/12/26 listparts.pl    36.1"').


/*  The main purpose of this file is to establish a common vocabulary
    for names of parts of lists among Prolog programmers.  You will
    seldom have occasion to use head/2 or tail/2 in your programs
    -- pattern matching is clearer and faster -- but you will often
    use these words when talking about your programs, and we shall
    all benefit if we use the same words with the same meanings.

    It really has not been clear what to call segments.  I originally
    called them "sublists", but when I came to generalise these predicates
    to other kinds of sequences, I found that I could talk about a prefix
    or a suffix or a segment of a general sequence, but that talking about
    a sublist of a general sequence didn't make sense.  The old names
    sublist/2 and proper_sublist/2 are retained for the benefit of people
    who were already using this package, but new code should use segment/2
    and proper_segment/2.

    Please send in your suggestions for other parts of lists (or of
    other standard data structures) which need agreed names, and for
    what those names should be.
*/

%   cons(?Head, ?Tail, ?List)
%   is true when Head is the head of List and Tail is its tail.
%   i.e. append([Head], Tail, List).   No restrictions.

cons(Head, Tail, [Head|Tail]).


%   last(?Fore, ?Last, ?List)
%   is true when Last is the last element of List and Fore is the
%   list of preceding elements, e.g. append(Fore, [Last], List).
%   Fore or Last should be proper.  It is expected that List will
%   be proper and Fore unbound, but it will work in reverse too.
%   In QP 2.4.2 on a Sun-3/50M, this is >3x faster than append/3.

last(Fore, Last, [Head|Tail]) :-
	last_1(Tail, Fore, Head, Last).

last_1([], [], Last, Last).
last_1([Head|Tail], [Prev|Fore], Prev, Last) :-
	last_1(Tail, Fore, Head, Last).



/*  All of the remaining predicates in this file are binary, and
    <part>(Whole, Part) is to be read as "Part is the/a <part>
    of Whole".  When both <part>/2 and proper_<part>/2 exist,
    proper <part>s are strictly smaller than Whole, whereas
    Whole may be a <part> of itself.  In the comments, N is the
    length of the Whole argument, assumed to be a proper list.

    Version 9.1 of this file had the Whole and Part arguments
    swapped.  I had allowed the order of the words in the English
    sentence to influence the order of the arguments, which is a
    very poor way to choose an argument order.  The new order is
    strictly in accord with the fundamental principle of
    argument ordering in Prolog: INPUTS BEFORE OUTPUTS.
    lists:last/2 was intended to have this argument order too,
    but we slipped.

    The predicates bear their indicated meanings only when their
    arguments are of the right types.  They are undefined for other
    terms.  Thus tail([e|g], g) succeeds despite the fact that 'g'
    isn't any sort of list.  Similarly, prefix(g, []) succeeds.
    This is not a bug!  'g' not being a list, the behaviour of
    prefix/2 in that case is not defined.

    The picture to keep in mind is
	Whole = Prefix || SubList || Suffix
	      = [Head] || Tail
	      =                 _ || [Last]
*/


%   head(List, Head)
%   is true when List is a non-empty list and Head is its head.
%   A list has only one head.  No restrictions.

head([Head|_], Head).


%   tail(List, Tail)
%   is true when List is a non-empty list and Tail is its tail.
%   A list has only one tail.  No restrictions.

tail([_|Tail], Tail).



%   prefix(List, Prefix)
%   is true when List and Prefix are lists and Prefix is a prefix of List.
%   It terminates if either argument is proper, and has at most N+1 solutions.
%   Prefixes are enumerated in ascending order of length.

prefix(List, Prefix) :-
	prefix_1(Prefix, List).

prefix_1([], _).
prefix_1([Head|Prefix], [Head|List]) :-
	prefix_1(Prefix, List).


%   proper_prefix(List, Prefix)
%   is true when List and Prefix are lists and Prefix is a proper prefix
%   of List.  That is, Prefix is a prefix of List but is not List itself.
%   It terminates if either argument is proper, and has at most N solutions.
%   Prefixes are enumerated in ascending order of length.

proper_prefix(List, Prefix) :-
	proper_prefix_1(Prefix, List).

proper_prefix_1([], [_|_]).
proper_prefix_1([Head|Prefix], [Head|List]) :-
	proper_prefix_1(Prefix, List).



%   suffix(List, Suffix)
%   is true when List and Suffix are lists and Suffix is a suffix of List.
%   It terminates only if List is proper, and has at most N+1 solutions.
%   Suffixes are enumerated in descending order of length.

suffix(List, List).
suffix([_|List], Suffix) :-
	suffix(List, Suffix).


%   proper_suffix(List, Suffix)
%   is true when List and Suffix are lists and Suffix is a proper suffix
%   of List.  That is, Suffix is a suffix of List but is not List itself.
%   It terminates only if List is proper, and has at most N solutions.
%   Suffixes are enumerated in descending order of length.

proper_suffix([_|List], Suffix) :-
	suffix(List, Suffix).



%   segment(List, Segment)
%   is true when List and Segment are lists and Segment is a segment
%   of List.  That is, List = _ <> Segment <> _ .
%   segment/2 terminates only if List is proper.  If Segment is proper
%   it enumerates all solutions.  If neither argument is proper, it
%   would have to diagonalise to find all solutions, but it doesn't, so
%   it is then incomplete.  If Segment is proper, it has at most N+1
%   solutions.  Otherwise, it has at most (1/2)(N+1)(N+2) solutions.

segment([], []).
segment([Head|Tail], [Head|Segment]) :-
        prefix_1(Segment, Tail).
segment([_|Tail], Segment) :-
        segment(Tail, Segment).


%   proper_segment(List, Segment)
%   is true when List and Segment are lists and Segment is a proper
%   segment of List.  It terminates only if List is proper.  The only
%   solution of segment/2 which is not a solution of proper_segment/2
%   is segment(List,List).  So proper_segment/2 has one solution fewer.

proper_segment(List, Segment) :-
	proper_prefix_1(Segment, List).
proper_segment([_|List], Segment) :-
	segment(List, Segment).



/*  These two predicates are retained for compatibility with an earlier
    version of this file.  New code should use {proper_,}segment/2 instead,
    and old code should be converted.
*/
sublist(List, Sublist) :-
	segment(List, Sublist).

proper_sublist(List, Sublist) :-
	proper_segment(List, Sublist).
