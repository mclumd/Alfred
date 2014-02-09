%   File   : readints.pl
%   Author : Richard A. O'Keefe
%   SCCS   : @(#)88/11/02 readints.pl	27.2
%   Purpose: Read integers from current input.

:- public
	read_integers/1.

/*  read_integer(?List)
    reads integers from the current input stream, and unifies List
    with a list of the results.  Input stops as soon as a new-line
    character not preceded by a comma is read, or as soon as any
    character which is not part of an integer is read.  The stop
    character is consumed (it should be ";" or ".").
    Apart from the fact that this only reads integers, the main
    difference between it and read_constants(List) is that in the
    latter case the List must be proper and determines how many
    constants are read, while here the data determine how many
    they are, and List may be a variable.
    This will eventually be replaced by a version of read_constants/1.
*/
	
read_integers(List) :-
	get0(C),
	'read integers'(C, 0, X),
	List = X.

'read integers'(C0, F, X0) :-
	(   C0 =:= "-" ->
	    get0(C1),
	    'read integers'(C1, 0, M, C2),
	    N is -M,
	    X0 = [N|X1],
	    'read integers'(C2, 0, X1)
	;   C0 >= "0", C0 =< "9" ->
	    'read integers'(C0, 0, N, C1),
	    X0 = [N|X1],
	    'read integers'(C1, 0, X1)
	;   C0 =:= 10, F =:= 0 ->
	    X0 = []
	;   C0 =:= 10, F =:= 1 ->
	    get0(C1),
	    'read integers'(C1, 0, X0)
	;   C0 =:= "," ->
	    get0(C1),
	    'read integers'(C1, 1, X0)
	;   C0 =\= " ", C0 =\= 9 ->
	    X0 = []
	;   get0(C1),
	    'read integers'(C1, F, X0)
	).

'read integers'(C0, N0, N, C) :-
	(   C0 >= "0", C0 =< "9" ->
	    N1 is N0*10 + C0 - "0",
	    get0(C1),
	    'read integers'(C1, N1, N, C)
	;   C = C0, N = N0
	).

