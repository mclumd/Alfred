% SCCS:	@(#)readwrite.pl	73.1 08/22/94
% Module: read_write
% Author: Anil Nair
% Purpose: Support for reading and writing terms effeciently
%	   in some canonical form

:- module(read_write, [
		      write_term_special/2,	% +Stream, +Term
		      read_term_special/2	% +Stream, -Term
		      ]).

:- use_module(library(assoc), [
			      ord_list_to_assoc/2,
			      get_assoc/3
			      ]).
:- use_module(library(between), [numlist/3]).
:- use_module(library(lists), [keys_and_values/3]).

write_term_special(Stream, Term):-
	write_to_buffer(Term, Address, Size),
	stream_code(Stream, Code),
	write_buffer_to_stream(Code, Address, Size, Status),
	free(Address),
	( Status >= 0 ->
	      true
	; Errno is -Status,
	  raise_exception(write_error(Stream,errno(Errno)))
	).


%  trick: if read_from_buffer returns 1, that signals the string "term" (or
%  "mret") has been read; which indicates that the sender sent term(Term) in
%  text format.  Let read/2 read the (Term) part from the stream.

read_term_special(Stream, Term):-
	stream_code(Stream, Code),
	read_stream_to_buffer(Code, Address, Status),
	( Status =:= 2 ->
	      read_from_buffer(Address, Term),
	      free(Address)
	; Status =:= 1 ->
	      read(Stream, Term)
	; Status =:= 0 ->
	      Term = end_of_file
	; Errno is -Status,
	  raise_exception(read_error(Stream,errno(Errno)))
	).

:- multifile 'QU_messages':generate_message/3.

'QU_messages':generate_message(read_error(Stream, Error)) -->
    ['Read error on stream ~w'-[Stream],nl],
    'QU_messages':msg(Error),
    [nl].
'QU_messages':generate_message(write_error(Stream, Error)) -->
    ['Write error on stream ~w'-[Stream],nl],
    'QU_messages':msg(Error),
    [nl].
			      

%	read_from_buffer(+Address, -Term)
%	returns the term stored at Address using write_to_buffer/3

%	write_to_buffer(+Term, -Address, -Size)
%	allocates a buffer large enough to write term and writes Term
%	to it. It returns the address and size of the buffer.
%	The memory allocated can be freed using free/1.
%	First we traverse the Term in prolog and collect all the distinct
%	variables in a dictionary and associate them with distinct integer
%	indices. This dictionary is passed to foreign code along with the term
%	to be stored.
%	In foreign code we traverse the term and if we come
%	across a variable, we make a Prolog call to variable_index/3 passing
%	the dictionary and the variable. variable_index/3 returns
%	the index of the variable.

write_to_buffer(Term, Address, Size) :-
	init_hash_table,
	traverse_term(Term, VarList, Size),
	malloc(Size, Address),

	sort(VarList, SortedVarList), % removes duplicates
	length(SortedVarList, NumOfVars),
	NV is NumOfVars - 1,
	numlist(0, NV, NumListForVars),
	keys_and_values(IndexedVarList, SortedVarList, NumListForVars),
	ord_list_to_assoc(IndexedVarList, VarAssoc),

	term_to_skeleton(Term, VarAssoc, NumOfVars, Address, Size).

:- extern(find_index(+term, +term, -integer)).

find_index(Assoc, Elem, Index) :-
	get_assoc(Elem, Assoc, Index).


foreign(traverse_term,    c, traverse_term(+term, -term, [-integer])).
foreign(term_to_skeleton, c, term_to_skeleton(+term,+term,+integer,+address,
					      +integer)).
foreign(skeleton_to_term, c, read_from_buffer(+address, -term)).
foreign(write_buffer_to_stream, c,
	write_buffer_to_stream(+integer, +address, +integer, [-integer])).
foreign(read_stream_to_buffer, c,
	read_stream_to_buffer(+integer, -address, [-integer])).
foreign(init_hash_table, c, init_hash_table).

% QP_malloc and QP_free are defined in the main program
foreign('QP_malloc', c, malloc(+integer, [-address])).
foreign('QP_free', c, free(+address)).

foreign_file(library(system(tcp_p)), [
				     traverse_term,
				     term_to_skeleton,
				     skeleton_to_term,
				     write_buffer_to_stream,
				     read_stream_to_buffer,
				     init_hash_table,
				     'QP_malloc',
				     'QP_free'
				     ]).
:- load_foreign_executable(library(system(tcp_p))),
		      abolish(foreign/3),
		      abolish(foreign_file/2).

end_of_file.

% test cases

:- user:ensure_loaded('/q/ptg/suite/termdb2').

test :-
	( user:term(X, Y),
	  (X mod 10 =:= 0 -> write(X), nl; true),
	  ( write_to_buffer(Y, Address, _) ->
		read_from_buffer(Address, A),
		( numbervars(Y, 1, _), numbervars(A, 1, _), Y == A ->
		      true
		; format('This should not happen~n', [])
		),
		free(Address)
	  ; format('write_to_buffer failed~n', [])
	  ),
	  fail
	; true
	).


test(X) :-
	( user:term(X, Y),
	  ( write_to_buffer(Y, Address, _) ->
		read_from_buffer(Address, A),
		( numbervars(Y, 1, _), numbervars(A, 1, _), Y == A ->
		      true
		; format('This should not happen~n', [])
		)
	  ; format('write_to_buffer failed~n', [])
	  ),
	  free(Address),
	  fail
	; true
	).
