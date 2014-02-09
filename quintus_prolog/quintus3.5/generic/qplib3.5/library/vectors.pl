%   Package: vectors.pl
%   Author : Richard A. O'Keefe
%   Updated: 04/20/99
%   Purpose: support Prolog list <-> C vector interface

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(vectors, [
	list_to_vector/2,
	list_to_vector/3,
	lists_to_vectors/2,
	kill_vector/1,
	kill_vector/2,
	make_vector/3,
	set_vector_element/3,
	vector_element/3,
	vector_size/2,
	vector_to_list/2
   ]).
:- mode
	check_numeric_list(+, +, +, -, -),
	list_to_vector(+, -),
	list_to_vector(+, +, -),
	make_vector(+, +, -),
	next_element(-, +),
	next_elements(+, +),
	push_element(+, +),
	push_elements(+, +),
	set_vector_element(+, +, +),
	vector_element(+, +, ?),
	vector_to_list(+, -),
	vector_type_code(+, -).

sccs_id('"@(#)99/04/20 vectors.pl	76.1"').


/*  This file provides a way to pass one-dimensional numeric arrays
    between Prolog and C, Fortran, or Pascal.  (This is what the
    "address(Type)" foreign argument type is all about.)

    Given a list of numbers,
	list_to_vector(List, Type, Vector)
    will make a vector of the indicated type (see vector_type_code/2
    in this file for a table of the known types).  If the list is of
    floating point numbers and the Type is 'float', you can omit the
    type.  If the list is of integers, and the Type is 'int', you can
    omit the type.  You probably shouldn't omit the type.

    Given a desired number of elements and a type,
	make_vector(Size, Type, Vector)
    will make a vector of the indicated type (see vector_type_code/2
    in this file for a table of the known types) and size.  The
    initial contents of this vector are undefined.  In the case of a
    floating-point vector, the initial contents might not be proper
    floating-point values!  Vectors created this way are meant to be
    used to hold results from a foreign call.

    To receive a vector back from C, use
	make_vector(Size, Type, Vector)
    to create the vector.  You can then use
	vector_to_list(Vector, List)
    to extract the contents.

    You should explicitly destroy vectors.
	kill_vector(Vector)
    deallocates a vector, and
	kill_vector(Vector, List)
    combines that with vector_to_list.

    Vector parameters are declared in Prolog as
	+address('Type')
    and in C as
	Type *id;

    To call a foreign routine with vector parameters, you'll need a
    wrapper predicate in addition to the foreign routine.  For
    example, suppose we had a routine

	SUBROUTINE ADDVEC(A, B, C, N)
	    INTEGER N
	    REAL A(N), B(N), C(N)
	    INTEGER I

	    DO 10 I = 1, N
		A(I) = B(I)+C(I)
    10	    CONTINUE
	    RETURN
	END

    Here is how we would interface to it:

	foreign('addvec_', fortran, 'ADDVEC'(
		+address(float), +address(float), +address(float),
		+integer)).

	add_vector(A, B, C) :-
		same_length(B, C, N),
		lists_to_vectors([float(B),float(C)], [Bvec,Cvec]),
		make_vector(N, float, Avec),
		'ADDVEC'(Avec, Bvec, Cvec, N),
		kill_vector(Cvec),
		kill_vector(Bvec),
		kill_vector(Avec, A).
*/

%%  check_numeric_list(+List, +Type0, +Size0, -Type, -Size)
%   is given a list which should be a proper list of numbers,
%   an initial guess at the type (0/1/2/3 = char/int/float/double)
%   and the number of elements checked so far (Size0).  It checks
%   that every element is a number, returns the full Size of the
%   list, and a Type which is big enough for every element.

check_numeric_list(0, _, _, _, _) :- !, fail.
check_numeric_list([], Type, Size, Type, Size).
check_numeric_list([Head|Tail], Type0, Size0, Type, Size) :-
	(   integer(Head) ->
	    (   Type0 >= 1 -> Type1 = Type0
	    ;   Head >= 0, Head < 256 -> Type1 = Type0
	    ;   Type1 = 1 /* int */
	    )
	;   float(Head) ->
	    (   Type0 >= 2 -> Type1 = Type0
	    ;   Type1 = 2 /* float */
	    )
	),
	Size1 is Size0+1,
	check_numeric_list(Tail, Type1, Size1, Type, Size).


%   list_to_vector(+List, -Vector)
%   succeeds when List is a list of numbers, and unifies Vector with
%   a vector of the strictest type which can accomodate those elements,
%   the elements of which vector are the (converted) members of List.
%   An error message is produced if anything goes wrong, because this
%   operation normally allocates memory.

list_to_vector(List, Vector) :-
	var(Vector),
	check_numeric_list(List, 1, 0, Code, Size),
	!,
	'QVmake'(Size, Code, Vector),
	push_elements(List, Vector).
list_to_vector(List, Vector) :-
	format(user_error, '~N! Bad argument(s) to ~q~n! Goal: ~q~n',
	    [list_to_vector/2, list_to_vector(List,Vector)]),
	fail.


%   list_to_vector(+List, ?Type, -Vector)
%   succeeds when List is a list of numbers, Type is a name of a numeric
%   type, each member of List is (or can be converted to) that type, and
%   unifies Vector with a vector of the given Type, the elements of which
%   are the (converted) members of List.  If the Type is a variable, 
%   this works like list_to_vector/2 and will unify Type with the type
%   name used in C for the selected type.
%   An error message is produced if anything goes wrong, because this
%   operation normally allocates memory.

list_to_vector(List, Type, Vector) :-
	vector_type_code(Type, Code),	% initial and final type.
	check_numeric_list(List, Code, 0, Code, Size),
	var(Vector),
	!,
	'QVmake'(Size, Code, Vector),
	push_elements(List, Vector).
list_to_vector(List, Type, Vector) :-
	format(user_error, '~N! Bad argument(s) to ~q~n! Goal: ~q~n',
	    [list_to_vector/3, list_to_vector(List,Type,Vector)]),
	fail.


%   lists_to_vectors(+TaggedLists, -Vectors)
%   succeeds when TaggedLists and Vectors are same-length lists, the
%   elements of TaggedLists have the form <Type>(List) or List, and
%   the lists can be converted to vectors as indicated.  This is done
%   in two phases: lists_to_types_and_sizes checks the arguments, and
%   lists_to_vectors actually makes the vectors.  If you want to turn
%   several lists into vectors, use this, because it will make
%   recovery from error easier.  You should check the lengths of the
%   lists before calling this operation.

lists_to_vectors(TaggedLists, Vectors) :-
	lists_to_types_and_sizes(TaggedLists, Lists, Codes, Sizes, Vectors),
	!,
	lists_to_vectors(Lists, Codes, Sizes, Vectors).
lists_to_vectors(TaggedLists, Vectors) :-
	format(user_error, '~N! Bad argument(s) to ~q~n! Goal: ~q~n',
	    [lists_to_vectors/2, lists_to_vectors(TaggedLists,Vectors)]),
	fail.

lists_to_types_and_sizes([], [], [], [], []).
lists_to_types_and_sizes([T|Ts], [L|Ls], [C|Cs], [S|Ss], [V|Vs]) :-
	var(V),
	list_to_type_and_size(T, L, C, S),
	lists_to_types_and_sizes(Ts, Ls, Cs, Ss, Vs).

list_to_type_and_size(Tagged, List, Code, Size) :-
	functor(Tagged, Type, 1),
	!,
	vector_type_code(Type, Code),
	arg(1, Tagged, List),
	check_numeric_list(List, Code, 0, Code, Size).
list_to_type_and_size(List, List, Code, Size) :-
	check_numeric_list(List, 1, 0, Code, Size).

lists_to_vectors([], [], [], []).
lists_to_vectors([List|Lists], [Code|Codes], [Size|Sizes], [Vector|Vectors]) :-
	'QVmake'(Size, Code, Vector),
	push_elements(List, Vector),
	lists_to_vectors(Lists, Codes, Sizes, Vectors).


%   make_vector(+Size, +Type, -Vector)
%   succeeds when Size is an integer in the range 0..65535
%   and Type is one of the numeric type names, and unifies Vector
%   with a new vector of that size and type, all of whose elements
%   are zero.  If the arguments are no good, an error message is printed.

make_vector(Size, Type, Vector) :-
	integer(Size),
	Size >= 0, Size < 65536,
	vector_type_code(Type, Code),
	var(Vector),
	!,
	'QVmake'(Size, Code, Vector).
make_vector(Size, Type, Vector) :-
	format(user_error, '~N! Bad argument(s) to ~q~n! Goal: ~q~n',
	    [make_vector/3, make_vector(Size,Type,Vector)]),
	fail.



vector_type_code(char,		0).
vector_type_code(character,	0).
vector_type_code(int,		1).
vector_type_code(integer,	1).
vector_type_code(float,		2).
vector_type_code(single,	2).
vector_type_code(real,		2).
vector_type_code(double,	3).


push_elements([], _).
push_elements([Head|Tail], Vector) :-
	push_element(Head, Vector),
	push_elements(Tail, Vector).


push_element(Element, Vector) :-
	(   integer(Element) -> 'QVIpsh'(Element, Vector, 0)
	;   float(Element)   -> 'QVDpsh'(Element, Vector, 0)
	).


%   vector_to_list(+Vector, ?List)
%   unifies List with the elements of the vector that Vector points to.
%   Vector still exists afterwards.

vector_to_list(Vector, List) :-
	vector_size(Vector, Length),
	reset_vector_fill_point(Vector),
	length(List, Length),
	next_elements(List, Vector).


next_elements([], _).
next_elements([Head|Tail], Vector) :-
	next_element(Head, Vector),
	next_elements(Tail, Vector).


next_element(Element, Vector) :-
	'QVnext'(Vector, Int, Flt, Code),
	(   Code >= 2 -> Element = Flt
	;   Code >= 0 -> Element = Int
	).


%   kill_vector(+Vector, ?List)
%   deallocates Vector and unifies List with the list of Vector's
%   elements.  After this, the vector that Vector pointed to no
%   longer exists, and you should not use it again.

kill_vector(Vector, List) :-
	vector_to_list(Vector, Ans),
	kill_vector(Vector),
	List = Ans.


%   vector_element(+Index, +Vector, ?Element)
%   unifies Element with the Indexth element of Vector, where the
%   first element of Vector has index 1.
%   This operation was added for the GKS interface, and may not be
%   present in this form in future releases.  No errors are reported.

vector_element(Index, Vector, Element) :-
	'QVtype'(Vector, Code),
	(   Code >= 2 -> 'QVFget'(Vector, Index, Element, 0)
	;   Code >= 0 -> 'QVIget'(Vector, Index, Element, 0)
	).



%   set_vector_element(+Index, +Vector, +NewElement)
%   sets the Indexth element of Vector to NewElement, which should
%   be an appropriate number.  The first element has Index 1.
%   This operation was added for the GKS interface, and may not be
%   present in this form in future releases.  No errors are reported.

set_vector_element(Index, Vector, Element) :-
	'QVtype'(Vector, Code),
	(   Code >= 2 -> 'QVFput'(Vector, Index, Element, 0)
	;   Code >= 0 -> 'QVIput'(Vector, Index, Element, 0)
	).



foreign_file(library(system(libpl)),
    [	'QVDpsh', 'QVIpsh', 'QVkill', 'QVmake', 'QVIget', 'QVFget',
	'QVnext', 'QVrset', 'QVsize', 'QVtype', 'QVIput', 'QVFput'
    ]).



%   vector_size(+Vector, ?Size)
%   unifies Size with the number of elements in Vector, which had
%   better be a pointer to a vector.

foreign('QVsize',	vector_size(+address,[-integer])).

%   kill_vector(+Vector)
%   deallocates Vector.

foreign('QVkill',	kill_vector(+address)).


foreign('QVIpsh',	'QVIpsh'(+integer,+address,[-integer])).
foreign('QVDpsh',	'QVDpsh'(+double,  +address,[-integer])).
foreign('QVrset',	reset_vector_fill_point(+address)).
foreign('QVmake',	'QVmake'(+integer,+integer,[-address])).
foreign('QVnext',	'QVnext'(+address,-integer,-double,[-integer])).
foreign('QVtype',	'QVtype'(+address,[-integer])).
foreign('QVIget',	'QVIget'(+address,+integer,-integer,[-integer])).
foreign('QVFget',	'QVFget'(+address,+integer,-double,  [-integer])).
foreign('QVIput',	'QVIput'(+address,+integer,+integer,[-integer])).
foreign('QVFput',	'QVFput'(+address,+integer,+double,  [-integer])).


:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

