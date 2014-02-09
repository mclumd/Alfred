%   Package: structs
%   Author : Peter Schachte
%   Updated: 12/10/98
%   Purpose: to allow access to C/Pascal data structures from Prolog

%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

% see accompanying README file for usage documentation.

:- module(structs, [
	(foreign_type)/2,
	get_contents/3,
	put_contents/3,
	get_address/3,
	new/2,
	new/3,
	dispose/1,
	cast/3,
	null_foreign_term/2,
	type_definition/2,
	atomic_type/1,
	atomic_type/2,
	atomic_type/3
   ]).

:- ensure_loaded(library(basics)).
:- ensure_loaded(library(between)).
:- ensure_loaded(language(str_msg)).
:- ensure_loaded(library(system(alignments))).

sccs_id('"@(#)98/12/10 structs.pl    22.1"').

/*
				Dynamic procedures
*/

%  Multifile procedures used by this module:
%
%	user_type_defn(Type_name, Simple_type_expr)
%		Type_name is the name of a user-defined type,
%		Simple_type_expr is a type expression defining
%		the type (see doc for new_atomic_type/8 for a
%		description of what a "simple" type expr is).
%
%	user_type_size(Type_name, Size, Alignment)
%		Size is the size of a Type_name, in bytes.
%		Alignment is the byte alignment required for this
%		type; that is, the address of the beginning of an
%		instance of Type_name must be divisible by Alignment.
%		Sadly, alignment is completely machine and compiler
%		specific.
%
%	user_get_contents(Datum, Part, Value)
%		This procedure is actually code used to get Part
%		of Datum, which is a compound datum.  Value is
%		bound to the contents of Part of Datum.
%
%	user_put_contents(Datum, Part, Value)
%		This procedure is actually code used to put Part
%		of Datum, which is a compound datum.  Part of Datum
%		is set to Value.
%
%	user_get_address(Datum, Part, Value)
%		This procedure is actually code used to get the
%		address of Part	of Datum, which is a compound datum.
%		Value is bound to the address of Part of Datum.
%
%  There are also three separate procedures for each struct defined,
%  using the names get_X_field, put_X_field, and get_X_address,
%  where X is the name of the structure.  Similarly, there are two
%  procedures for each union defined, named get_X_field and
%  get_X_address.  All of these procedures are 3-ary.
%

:- multifile
	user_type_defn/2,
	user_type_size/3,
	user_get_contents/3,
	user_put_contents/3,
	user_get_address/3,
	user:unknown_predicate_handler/3.

user:unknown_predicate_handler(user_type_defn(_,_), structs, fail).
user:unknown_predicate_handler(user_type_size(_,_,_), structs, fail).

%  Start out knowing how to deal with the primitives

%  note that long is assumed == address here - but will be truncated
%  to 32 bits even on machines where a long is 64 bits

user_get_contents(long(Ptr), contents, Value) :-
	Value is /*long*/address_at(Ptr).
user_get_contents(integer(Ptr), contents, Value) :-
	Value is integer_at(Ptr).
user_get_contents(short(Ptr), contents, Value) :-
	Value is integer_16_at(Ptr).
user_get_contents(char(Ptr), contents, Value) :-
	Value is integer_8_at(Ptr).
user_get_contents(unsigned_long(Ptr), contents, Value) :-
	Value is /*long*/address_at(Ptr).
user_get_contents(unsigned_integer(Ptr), contents, Value) :-
	Value is integer_at(Ptr).
user_get_contents(unsigned_short(Ptr), contents, Value) :-
	Value is unsigned_16_at(Ptr).
user_get_contents(unsigned_char(Ptr), contents, Value) :-
	Value is unsigned_8_at(Ptr).
user_get_contents(float(Ptr), contents, Value) :-
	Value is single_at(Ptr).
user_get_contents(double(Ptr), contents, Value) :-
	Value is double_at(Ptr).
user_get_contents(atom(Ptr), contents, Value) :-
	get_atom(Ptr, 0, Value).
user_get_contents(string(Ptr), contents, Value) :-
	get_string(Ptr, 0, Value).


user_put_contents(long(Ptr), contents, Value) :-
	assign(/*long*/address_at(Ptr), Value).
user_put_contents(integer(Ptr), contents, Value) :-
	assign(integer_at(Ptr), Value).
user_put_contents(short(Ptr), contents, Value) :-
	assign(integer_16_at(Ptr), Value).
user_put_contents(char(Ptr), contents, Value) :-
	assign(integer_8_at(Ptr), Value).
user_put_contents(unsigned_long(Ptr), contents, Value) :-
	assign(/*long*/address_at(Ptr), Value).
user_put_contents(unsigned_integer(Ptr), contents, Value) :-
	assign(integer_at(Ptr), Value).
user_put_contents(unsigned_short(Ptr), contents, Value) :-
	assign(unsigned_16_at(Ptr), Value).
user_put_contents(unsigned_char(Ptr), contents, Value) :-
	assign(unsigned_8_at(Ptr), Value).
user_put_contents(float(Ptr), contents, Value) :-
	assign(single_at(Ptr), Value).
user_put_contents(double(Ptr), contents, Value) :-
	assign(double_at(Ptr), Value).
user_put_contents(atom(Ptr), contents, Value) :-
	put_atom(Ptr, 0, Value).
user_put_contents(string(Ptr), contents, Value) :-
	put_string(Ptr, 0, Value).


user_get_address(long(Ptr), contents, long(Ptr)).
user_get_address(integer(Ptr), contents, integer(Ptr)).
user_get_address(short(Ptr), contents, short(Ptr)).
user_get_address(char(Ptr), contents, char(Ptr)).
user_get_address(unsigned_long(Ptr), contents, unsigned_long(Ptr)).
user_get_address(unsigned_integer(Ptr), contents, unsigned_integer(Ptr)).
user_get_address(unsigned_short(Ptr), contents, unsigned_short(Ptr)).
user_get_address(unsigned_char(Ptr), contents, unsigned_char(Ptr)).
user_get_address(float(Ptr), contents, float(Ptr)).
user_get_address(double(Ptr), contents, double(Ptr)).
user_get_address(atom(Ptr), contents, atom(Ptr)).
user_get_address(string(Ptr), contents, string(Ptr)).


/****************************************************************
			    Public procedures
 ****************************************************************/

%  foreign_type(+Datum, -Type)
%  Datum is a data structure as returned by some of the procedures
%  in this module, and Type is its type.

foreign_type(Datum, Type) :-
	(   var(Datum) ->
		raise_exception(
			instantiation_error(foreign_type(Datum,Type),1))
	;   functor(Datum, Type, 1),
	    arg(1, Datum, Addr),
	    integer(Addr),
	    (   user_type_size(Type, _, _) -> true
	    ;   primitive_type_size(Type, _, _)
	    )
	).


%  get_contents(+Datum, ?Type, ?Part, -Value)
%  Value is unified with the contents of the Part part of Datum.
%  If Datum is an array, Part should be an integer index into the array,
%  where 0 is the first element.  For a pointer, Part should be the
%  atom 'contents' and Value will be what the pointer points to.  For
%  a struct, Part should be a field name, and Value will be the contents
%  of that field.  If Part is unbound, then get_contents will backtrack
%  through all the valid parts of Datum, binding both Part and Value.
%  A C programmer might thing of get_contents(Foo, Bar, Baz) as being
%  like Baz = Foo->Bar.
%  
%  The hitch is that only atomic and pointer types can be returned.
%  This is because Prolog can only hold pointers to C structures, not
%  the structures themselves.  This isn't quite as bad as it might seem,
%  though, since usually structures contain pointers to other structures,
%  anyway.  When a structure directly contains another structure, Prolog
%  can get a pointer to it with get_address/3.

get_contents(Datum, Part, Value) :-
	(   var(Datum) ->
		raise_exception(
			instantiation_error(get_contents(Datum,Part,Value),1))
	;   nonvar(Part) ->
		% if Part is bound at call, print error if it's invalid
		(   user_get_contents(Datum, Part, Value1) -> Value=Value1
		;   raise_exception(
			domain_error(get_contents(Datum,Part,Value),2,
				part_of_foreign_object, Part, ''))
		)
	% if Part is unbound, backtrack through all valid Parts
	;   user_get_contents(Datum, Part, Value)
	).


% put_contents(+Datum, +Part, +Value)
% Value is put into the Part field of Datum.  Value is checked to make
% sure it is the expected type.  Interpretation of the arguments is as
% for get_contents/3 above.  Note that for put_contents, Part must be
% bound and cannont be backtracked through.
%  A C programmer might thing of put_contents(Foo, Bar, Baz) as being
%  like Foo->Bar = Baz.

put_contents(Datum, Part, Value) :-
	(   var(Datum) ->
		raise_exception(
			instantiation_error(put_contents(Datum,Part,Value),1))
	% for put_contents, Part MUST be bound at call time
	;   var(Part) ->
		raise_exception(
			instantiation_error(put_contents(Datum,Part,Value),2))
	;   user_put_contents(Datum, Part, Value) -> true
	;   raise_exception(
		domain_error(put_contents(Datum,Part,Value),2,
			part_of_foreign_object,Part,''))
	).


% get_address(+Datum, ?Part, -Value)
% Value is unified with a pointer to the Part part of Datum.
% Interpretation of the arguments is as for get_contents/3 above.
%  A C programmer might thing of get_address(Foo, Bar, Baz) as being
%  like Baz = &Foo->Bar.

get_address(Datum, Part, Value) :-
	(   var(Datum) ->
		raise_exception(
			instantiation_error(get_address(Datum,Part,Value),1))
	;   nonvar(Part) ->
		% if Part is bound at call, print error if it's invalid
		(   user_get_address(Datum, Part, Value1) -> Value = Value1
		;   raise_exception(
			domain_error(get_address(Datum,Part,Value),2,
				part_of_foreign_object,Part,''))
		)
	% if Part is unbound, backtrack through all valid Parts
	;   user_get_address(Datum, Part, Value)
	).


% type_size(+Type, -Size)
% Type is user defined or a primitive type
type_size(Type, Size) :-
    ( user_type_size(Type, Size, _) -> true
    ; primitive_type_size(Type, Size, _)
    ).


%  new(+Type, -Datum)
%  Datum is a freshly allocated object of type Type.
%  Note, this uses calloc which initializes the returned memory to zeros

new(Type, Datum) :-
	(   var(Type) ->
		raise_exception(instantiation_error(new(Type,Datum),1))
	;   type_size(Type, Size),
	    integer(Size) ->
		functor(Datum, Type, 1),
		arg(1, Datum, Ptr),
		calloc(1, Size, Ptr)
	;   raise_exception(
		    domain_error(new(Type,Datum),1,fixed_size_type,Type,''))
	).


%  new(+Type, +Size, -Datum)
%  Datum is a freshly allocated object of type Type, which is an
%  unknown-size array type (as defined by array(Type), rather than
%  array(Type,Size)), and Size is the number of elements that should
%  be allocated.  The contents of Datum are zeroed.

new(Type, Size, Datum) :-
	(   var(Type) ->
		raise_exception(instantiation_error(new(Type,Size,Datum),1))
	;   var(Size) ->
		raise_exception(instantiation_error(new(Type,Size,Datum),2))
	;   \+ integer(Size) ->
		raise_exception(
			type_error(new(Type,Size,Datum),2,integer,Size))
	;   user_type_defn(Type, array(Component_type)),
	    (   user_type_size(Component_type, Elt_size, _) -> true
	    ;   primitive_type_size(Component_type, _, Elt_size)
	    ),
	    integer(Elt_size) ->
		functor(Datum, Type, 1),
		arg(1, Datum, Ptr),
		calloc(Size, Elt_size, Ptr)
	    % shouldn't be possible for integer(Elt_size) to fail, since it
	    % shouldn't be possible to declare an array of non-fixed size elts.
	;   raise_exception(
		domain_error(new(Type,Size,Datum),1,fixed_size_type, Type,''))
	).


%  dispose(+Datum)
%  Datum is a data structure as returned by some of the procedures in
%  this module.  After this call, Datum is deallocated, and MUST not
%  be referenced again.  No effort is made by this package to prevent
%  the horrible death that could follow using Datum after it has been
%  disposed.

dispose(Datum) :-
	(   var(Datum) ->
		raise_exception(instantiation_error(dispose(Datum),1))
	;   functor(Datum, Type, 1),
	    user_type_size(Type, _, _) ->
		arg(1, Datum, Ptr),
		free(Ptr)
	;   raise_exception(
		    domain_error(dispose(Datum),1,foreign_object,Datum,''))
	).


%  cast(+Foreign0, +New_type, -Foreign)
%  Foreign is the foreign term which is the same data as Foreign0, only
%  is of foreign type New_type.  Foreign0 is not affected.  This also works
%  if Foreign0 is an address type (i.e., an integer address) or New_type
%  is an address type.  If New_type is an atomic type, Foreign will still
%  be a foreign term.

cast(Foreign0, New_type, Foreign) :-
	(   var(Foreign0) ->
		raise_exception(instantiation_error(
				cast(Foreign0,New_type,Foreign),1))
	;   var(New_type) ->
		raise_exception(instantiation_error(
				cast(Foreign0,New_type,Foreign),2))
	;   (   user_type_defn(New_type, New_type_defn)
	    ;   primitive_type_size(New_type, _, _), New_type_defn = New_type
	    ) ->
		(   integer(Foreign0) ->
			Addr = Foreign0		% casting FROM address type
		;   arg(1, Foreign0, Addr)	% casting FROM foreign term
		),
		(   New_type_defn == address ->
			Foreign = Addr		% casting TO address type
		;   functor(Foreign, New_type, 1),
						% casting TO foreign term
		    arg(1, Foreign, Addr)
		)
	;   raise_exception(
		    domain_error(cast(Foreign0,New_type,Foreign),2,
			    foreign_type,New_type,''))
	).


%   null_foreign_term(?Term, ?Type)
%   holds when Term is a foreign term of Type, but is NULL (the address
%   is 0).  At least one of Term and Type must be bound.  This can be
%   used to generate NULL foreign terms, or to check a foreign term to
%   determine whether or not it is NULL.

null_foreign_term(Term, Type) :-
	functor(Term, Type, 1),
	arg(1, Term, 0).


%  type_definition(?Type, -Definition)
%  type_definition(?Type, -Definition, -Size)
%  Type is a previously defined type, and Definition is its definition.
%  A definition looks much like the definition given when the type was
%  defined with type/1, except that it has been simplified.  Firstly,
%  intermediate type names have been elided.  For example, if foo is
%  defined as foo=integer, and bar as bar=foo, then
%  type_definition(bar, integer) would hold.  Also, in the definition
%  of a compound type, types of parts are always defined by type names,
%  rather than complex specifications.  So if the type of a field in
%  a struct was defined as pointer(fred), it will show up in the
%  definition as '$fred'.  Of course, type_definition('$fred', pointer(fred))
%  would hold, also.  Size is the size in bytes one of these objects
%  would occupy.

type_definition(Type, Definition) :-
	user_type_defn(Type, Definition0),
	cleanup_definition(Definition0, Definition).

type_definition(Type, Definition, Size) :-
	user_type_defn(Type, Definition0),
	cleanup_definition(Definition0, Definition),
	user_type_size(Type, Size, _).


%  atomic_type(?Type)
%  atomic_type(?Type, -Primitive_type)
%  atomic_type(?Type, -Primitive_type, -Size)
%  atomic_type(?Type, -Primitive_type, -Size, -Alignment)
%  Type is an atomic.  See the discussion above for the definition of
%  an atomic type.  Primitive_type is the primitive type that Type
%  is defined in terms of.  Size is the number of bytes occupied by
%  an object of type Type.  Alignment is the byte alignment expected
%  for things of this type.  That is, the address of one of these
%  things will be divisible by Alignment.

atomic_type(Type) :-
	atomic_type(Type, _, _, _).

atomic_type(Type, Primitive_type) :-
	atomic_type(Type, Primitive_type, _, _).

atomic_type(Type, Primitive_type, Size) :-
	atomic_type(Type, Primitive_type, Size, _).

atomic_type(Type, Primitive_type, Size, Alignment) :-
	atom(Type),
	(   primitive_type_size(Type, Size, Alignment) -> Primitive_type = Type
	;   user_type_defn(Type, Type_expr),
	    atomic_type(Type_expr, Primitive_type, Size, Alignment)
	).



/****************************************************************
			Procedures for all types
 ****************************************************************/

%  cleanup_definition(+Definition0, -Definition)
%  Definition is the definition we want to show users corresponding to
%  Definition0, a definition as we store them internally.
%  NB:  this is also defined in structs_decl.pl.

cleanup_definition(Definition0, Definition) :-
	(   Definition0 = struct(Fields0) ->
		Definition = struct(Fields),
		cleanup_struct_fields(Fields0, Fields)
	;   Definition = Definition0
	).


%  cleanup_struct_fields(+Fields0, -Fields)
%  Fields0 is a list of field(Name,Type,Offset) terms; Fields is a list
%  of corresponding Name:Type terms.
%  NB:  this is also defined in structs_decl.pl.

cleanup_struct_fields([], []).
cleanup_struct_fields([field(N,T,_)|Fields0], [N:T|Fields]) :-
	cleanup_struct_fields(Fields0, Fields).



/****************************************************************
			Interface to foreign accessors
 ****************************************************************/

foreign_file(library(system(structs)),
	     ['_Sget_atom', '_Sget_string', 
	      '_Sput_atom', '_Sput_string', calloc, free]).

foreign('_Sget_atom', c, get_atom(+address(char), +integer, [-atom])).
foreign('_Sget_string', c, get_string(+address(char), +integer, [-string])).
foreign('_Sput_atom', c, put_atom(+address(char), +integer, +atom)).
foreign('_Sput_string', c, put_string(+address(char), +integer, +string)).

foreign(calloc, c, calloc(+integer, +integer, [-address(opaque)])).
foreign(free, c, free(+address(opaque))).

:- load_foreign_executable(library(system(structs))).
