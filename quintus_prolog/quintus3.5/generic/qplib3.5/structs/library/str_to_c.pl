% -*- Mode:Prolog -*-
%   Package: structs_to_c
%   Author : Peter Schachte
%   Updated: 06/01/94
%   Purpose: To generate C type declarations matching Prolog structs decls

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(structs_to_c, [
	structs_to_c/1,
	structs_to_c/2
   ]).

:- use_module(library(basics), [
	member/2,
	nonmember/2
   ]).

sccs_id('"@(#)94/06/01 str_to_c.pl	20.1"').

:- op(1150, fx, [(foreign_type)]).


%  structs_to_c(+Infile)
%  structs_to_c(+Infile, +Outfile)
%  Reads Infile, a Prolog source file containing :- foreign_type declarations,
%  writing Outfile (defaults to the root name of Infile with a .h extension),
%  a file of C type definitions corresponding to the declarations in Infile.
%  For each declaration in Infile, Outfile will contain a typedef defining
%  the name to have the appropriate C declaration.
%
% This code works in two passes.  First, it generates a typedef for each
% type.  Then, it generates the actual struct and union definitions.

structs_to_c(Infile) :-
	absolute_file_name(Infile, Absfile),
	name(Absfile, Inchars),
	(   append(Inroot, [0'.|Extension], Inchars),
	    nonmember(0'., Extension) -> true
	;   Inroot = Inchars
	),
	append(Inroot, ".h", Outchars),
	name(Outfile, Outchars),
	structs_to_c(Absfile, Outfile).

structs_to_c(Infile, Outfile) :-
	tell(Outfile),
	write_header(Infile, Outfile),
	see(Infile),
	read(Term),
	do_typedefs(Term),
	seen,					% end of pass 1
	nl, nl,
	see(Infile),
	read(Term1),
	do_structs(Term1),
	seen,					% end of pass 2
	told,
	format('~w generated from ~w~n', [Outfile, Infile]).

%  runtime_entry(+Mode)
%  toplevel for standalone operation.  Mode is start or abort.

user:(runtime_entry(start) :-
	op(1150, fx, [(foreign_type)]),
	unix(argv(Files)),
	(   basics:member(File, Files),
	    structs_to_c:structs_to_c(File),
	    fail
	;   true
	)).



%  write_header(+Infile, +Outfile)
%  write a header suitable for the top of a machine generated C include
%  file named Outfile, generated from Prolog file Infile.

write_header(Infile, Outfile) :-
	format('/~`*t~72|*~n', []),
	format(' * C include file~t~72|*~n', []),
	format(' *      ~w~t~72|*~n', [Outfile]),
	format(' * generated automatically from Prolog file~t~72|*~n', []),
	format(' *      ~w~t~72|*~n', [Infile]),
	format(' * By structs_to_c utility~t~72|*~n', []),
	format(' ~`*t~72|*/~2n', []),
	format('#include "quintus.h"~2n', []).

%  do_typedefs(+Term)
%  Pass 1: generate typedefs for each user-defined type.  Term is the
%  a term read from the source file.

do_typedefs(Term) :-
	(   Term == end_of_file -> true
	;   (	Term = :-(Goal) ->
		    process_goal_typedefs(Goal)
	    ;   true
	    ),
	    read(Term1),
	    do_typedefs(Term1)
	).

%  process_goal_typedefs(+Goal)
%  Goal may be a foreign_type definition.  If so, write out the
%  apropriate C typedefs.

process_goal_typedefs(Goal) :-
	(   Goal = ','(Goal1,Goal2) ->
		process_goal_typedefs(Goal1),
		process_goal_typedefs(Goal2)
	;   Goal = foreign_type(Types) ->
		process_foreign_typedefs(Types)
	;   Goal = =(X,Y) ->
		X=Y
	;   true
	).


%  process_foreign_typedefs(+Typedefns)
%  Typedefns is a bunch of type definitions for which I must write
%  corresponding C typdefs.

process_foreign_typedefs(','(Type1,Type2)) :-
	process_foreign_typedefs(Type1),
	process_foreign_typedefs(Type2).
process_foreign_typedefs(Name=Type) :-
	inside_out(Type, Name, Itype, Prim),
	phrase(declaration(Name,Prim,Itype), Decl),
	put_chars("typedef "),
	put_chars(Decl),
	put_chars(";
").


%  inside_out(+Type, +Name, -Itype, -Iname)
%  Itype is an inside-out version of Type, where Name is the name
%  of the type, and Iname is the inside-out version of it.  This
%  is used because C type declarations are "inside-out" relative to
%  the structs package's declarations.  That is, where structs says
%  foo is of type pointer to integer, C says that there is an integer
%  that foo points to.  It gets much more complicated when the 
%  declaration is complex.

inside_out(pointer(Type), Name, Itype, Iname) :- !,
	inside_out(Type, pointer(Name), Itype, Iname).
inside_out(array(Num,Type), Name, Itype, Iname) :- !,
	inside_out(Type, array(Num,Name), Itype, Iname).
inside_out(array(Type), Name, Itype, Iname) :- !,
	inside_out(Type, array(Name), Itype, Iname).
inside_out(Type, Itype, Itype, Type).

/*
		Definite Clause Grammar for C type declarations
		(See Kernighan and Richie Appendix A for BNF)
*/



declaration(Name,Prim,Itype) -->
	type_specifier(Prim,Name),
	declarator(Itype).


type_specifier(struct(_), Name) --> !,
	struct_specifier(Name).
type_specifier(union(_), Name) --> !,
	union_specifier(Name).
%% [PM] 3.5 incomplete enums are illegal (and fatal on HPUX 11.00 cc).
%%          So instead of typedef enum foo bar; we must do something like
%%             typedef enum foo {...} bar;
%%          or possibly
%%             enum foo {...};
%%             typedef enum foo bar;
%%
%% type_specifier(enum(_), Name) --> !,
%% 	enum_specifier(Name).
type_specifier(enum(Fields), Name) --> !,
        enum_declaration_body(Fields,Name),
        " ".
type_specifier(Type, _) -->
	full_type_specifier(Type).


full_type_specifier(struct(Fields)) --> !,
	full_struct_specifier(Fields).
full_type_specifier(union(Members)) --> !,
	full_union_specifier(Members).
full_type_specifier(enum(Enums)) --> !,
	full_enum_specifier(Enums).
full_type_specifier(long) --> !,
	"long ".
full_type_specifier(integer) --> !,
	"int ".
full_type_specifier(short) --> !,
	"short ".
full_type_specifier(char) --> !,
	"char ".
full_type_specifier(unsigned_long) --> !,
	"unsigned long ".
full_type_specifier(unsigned_integer) --> !,
	"unsigned int ".
full_type_specifier(unsigned_short) --> !,
	"unsigned short ".
full_type_specifier(unsigned_char) --> !,
	"unsigned char ".
full_type_specifier(float) --> !,
	"float ".
full_type_specifier(double) --> !,
	"double ".
full_type_specifier(atom) --> !,
	"QP_atom ".
full_type_specifier(string) --> !,
	"char *".
full_type_specifier(opaque) --> !,
	"void ".
full_type_specifier(address) --> !,
	"void *".
full_type_specifier(Ident) -->
	identifier(Ident),
	" ".


struct_specifier(Name) -->
	"struct _",
	identifier(Name),
	" ".

union_specifier(Name) -->
	"union _",
	identifier(Name),
	" ".

enum_specifier(Name) -->
	"enum _",
	identifier(Name),
	" ".



full_struct_specifier(Fields) -->
	"struct {",
	struct_decl_list(Fields),
	"} ".

full_union_specifier(Fields) -->
	"union {",
	struct_decl_list(Fields),
	"} ".

full_enum_specifier(Fields) -->
	"enum {",
	enum_list(Fields),
	"} ".


declarator(pointer(Type)) --> !,
	"*(",
	declarator(Type),
	")".
declarator(array(Num,Type)) --> !,
	"(",
	declarator(Type),
	")[",
	number(Num),
	"]".
declarator(array(Type)) --> !,			% C doesn't support unknown-
						% size arrays properly, so
	declarator(Type),			% this hack should work.
	" /",					% Note that your C code must
	"* really an unknown-size array */".	% reference foo->x[2] as
						% *(foo->x)+2 instead.  Sorry.
declarator(Name) -->
	identifier(Name).

%  do_structs(+Term)
%  Pass 2: generate actual C struct or union declarations for each
%  user-defined struct or union.  Term is a term read from the source file.

do_structs(Term) :-
	(   Term = end_of_file -> true
	;   (	Term = :-(Goal) ->
		    process_goal_structs(Goal)
	    ;   true
	    ),
	    read(Term1),
	    do_structs(Term1)
	).


%  process_goal_structs(+Goal)
%  Goal may be a foreign_type definition.  If so, write out the
%  apropriate C struct and union defns.

process_goal_structs(Goal) :-
	(   Goal = ','(Goal1,Goal2) ->
		process_goal_structs(Goal1),
		process_goal_structs(Goal2)
	;   Goal = foreign_type(Types) ->
		process_foreign_structs(Types)
	;   Goal = =(X,Y) ->
		X=Y
	;   true
	).


%  process_foreign_structs(+Typedefns)
%  Typedefns is a bunch of type definitions.  I must write the appropriate
%  C struct or union declaration for all the struct and union defns.

process_foreign_structs((Type1,Type2)) :-
	process_foreign_structs(Type1),
	process_foreign_structs(Type2).
process_foreign_structs(Name=Type) :-
	(   phrase(struct_union_enum_declaration(Type,Name), Decl) ->
		put_chars(Decl)
	;   true
	).

struct_union_enum_declaration(struct(Fields),Name) -->
        struct_declaration_body(Fields,Name),
        ";

".
struct_union_enum_declaration(union(Fields),Name) -->
        union_declaration_body(Fields,Name),
        ";

".
struct_union_enum_declaration(enum(Fields),Name) -->
        %% [PM] 3.5 Do nothing. The enum was declared as part of the typedef in pass 1.
        "".
%% [PM] 3.5 in effect, what QP 3.4 did (emits full declaration of the enum in second pass)
%% struct_union_enum_declaration(enum(Fields),Name) -->
%%         enum_declaration_body(Fields,Name)
%%         ";
%% 
%% ",





struct_declaration_body(Fields,Name) -->
	struct_specifier(Name),
	"{
",
	struct_decl_list(Fields),
	"}".

union_declaration_body(Fields,Name) -->
	union_specifier(Name),
	"{
",
	struct_decl_list(Fields),
	"}".

enum_declaration_body(Fields,Name) -->
	enum_specifier(Name),
	"{
",
	enum_list(Fields),
	"}".


struct_decl_list([]) --> [].
struct_decl_list([Name:Type|Fields]) -->
	{inside_out(Type, Name, Itype, Prim)},
	struct_declaration(Prim, Itype),
	struct_decl_list(Fields).


struct_declaration(Prim, Itype) -->
	"	",
	full_type_specifier(Prim),
	declarator(Itype),
	";
".

enum_list([]) --> [].
enum_list([Name=Value|Fields]) --> !,
	"	",
	identifier(Name),
	" = ",
	number(Value),
	",
",
	enum_list(Fields).
enum_list([Name]) --> !,
        %% [PM] 3.5 Do not emit comma after last identifier. AIX C 6
        %% complains on terminating comman: 1506-275 (S) Unexpected
        %% text ',' encountered.
	"	",
	identifier(Name),
	"
".
enum_list([Name|Fields]) --> !,
	"	",
	identifier(Name),
	",
",
	enum_list(Fields).



%  number(+Num, -List, ?Rest)
%  List is the list of characters composing the spelling of the number Num,
%  followed by Rest.  Efficient hack implementation of DCG.

number(Num, List, Rest) :-
	number_chars(Num, Num_chars),
	append(Num_chars, Rest, List).


%  identifier(+Id, -List, ?Rest)
%  List is the list of characters composing the spelling of the atom Id,
%  followed by Rest.  Efficient hack implementation of DCG.

identifier(Id, List, Rest) :-
	atom_chars(Id, Id_chars),
	append(Id_chars, Rest, List).


%  put_chars(+Chars)
%  Put the characters in list Chars out to standard out.

put_chars([]).
put_chars([C|Cs]) :-
	put(C),
	put_chars(Cs).
