%   File   : plint.pl
%   Author : Richard A. O'Keefe
%   Updated: 01/10/92
%   Purpose: Prolog->Lint filter.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

sccs_id('"@(#)92/01/10 plint.pl	66.1"').

:- ensure_loaded(library(strings)).
:- ensure_loaded(library(files)).

%   plint
%   is the only entry point of this program.  The program is invoked thus:
%	.../plint.save {output} quintus.h {other .h and .pl files}...
%   The argument list is not really checked as the program is not meant
%   to be invoked directly by users, but only through plint.c
%   Note that various things are set up to fail if anything goes wrong,
%   since this program has not yet been updated to take advantage of
%   error handling.

:- extern(plint).

plint :-				% hope all goes well.
	unix(argv([Output|Inputs])),
	open_file(Output, write, Stream),
	set_output(Stream),
	include_headers(Inputs, Sources),
	format("~nvoid PROLOG()~n    {~n", []),
	process_built_in_functions,
	process_sources(Sources),
	format("    }~n~n", []),
	close(Stream).
plint :-				% if anything goes wrong
	close_all_streams,
	unix(argv([Output|_])),		% ensure that
	file_exists(Output),		% the output file
	delete_file(Output).		% does not exist
plint.

%   include_headers(+Inputs, -Sources)
%   takes a list of file names, Inputs, and strips out the elements
%   which end with ".h".  Each such element is written to the current
%   output stream as a cpp #include directive.  The other elements
%   are returned as a list of names of Prolog Sources.  There is a
%   nasty snag here: the C file we are constructing is going to live
%   in /tmp, and if we don't watch out, the header files will be
%   looked for there.  So we interpret the header file names relative
%   to the current directory: the rules for .h files in the command
%   line are DIFFERENT from the rules for .h files included in a C
%   file.  This is all very confusing.

include_headers([], []).
include_headers([Header|Inputs], Sources) :-
	substring(Header, '.h', _, _, 0),
	!,				% Header ends with ".h"
	absolute_file_name(Header, AbsHead),
	write('#include "'), write(AbsHead), write('"'), nl,
	include_headers(Inputs, Sources).
include_headers([Source|Inputs], [Source|Sources]) :-
	include_headers(Inputs, Sources).


%   process_built_in_functions
%   writes out a use of each of the built in functions except
%   QP_make_stream, which takes function arguments.
%   THIS HAS NOT YET BEEN FULLY UPDATED FOR RELEASE 3.0 WHICH
%   SUPPLIES MANY MORE BUILT-IN FUNCTIONS.  ALSO, IT HAS BUILT-IN
%   MACROS SUCH AS QP_getc AND QP_putc WHICH ARE NOT YET HANDLED.

process_built_in_functions :-
	quintus_foreign(Template),
	functor(Template, Fname, _),
	process_foreign(c, Fname, Template, '-', 'built in'),
	fail ; true.

quintus_foreign('QP_string_from_atom'(+atom,[-string])).
quintus_foreign('QP_atom_from_string'(+string,[-atom])).
quintus_foreign('QP_clearerr'(+stream)).
quintus_foreign('QP_close'(+stream, [-integer])).
quintus_foreign('QP_fclose'(+stream, [-integer])).
quintus_foreign('QP_fdopen'(+integer,+string,[-stream])).
quintus_foreign('QP_ferror'(+stream)).
quintus_foreign('QP_fgetc'(+stream,[-integer])).
quintus_foreign('QP_fgets'(+address,+integer,+stream,[-address])).
quintus_foreign('QP_flush'(+stream,[-integer])).
quintus_foreign('QP_fnewln'(+stream, [-integer])).
quintus_foreign('QP_fopen'(+string,+string,[-stream])).
quintus_foreign('QP_fpeekc'(+stream,[-integer])).
quintus_foreign('QP_fputc'(+integer,+stream,[-integer])).
quintus_foreign('QP_fread'(+address(char),+integer,+integer,+stream,
			   [-integer])).
quintus_foreign('QP_fskipln'(+stream,[-integer])).
quintus_foreign('QP_fwrite'(+address(char),+integer,+integer,+stream,
			    [-integer])).
quintus_foreign('QP_prepare_stream'(+stream,+address(char))).
% Unfortunately this has to be commented out because in quintus.h
% QP_register_stream() is defined as returning a long!
% quintus_foreign('QP_register_stream'(+stream,[-integer])).
quintus_foreign('QP_tab'(+stream,+integer,+integer,[-integer])).
quintus_foreign('QP_tabto'(+stream,+integer,+integer,[-integer])).
quintus_foreign('QP_ungetc'(+integer,+stream,[-integer])).


%   process_sources(+Sources)
%   takes a list of Prolog source files, and translates each
%   foreign declaration found therein into a little C "block"
%   which calls the function with appropriate arguments.

process_sources([]).
process_sources([Source|Sources]) :-
	process_source(Source),
	process_sources(Sources).


process_source(Source) :-
	open_file(Source, read, Stream),
	put(9), write('/* Prolog: '), write(Source), write(' */'), nl,
	set_input(Stream),
	repeat,
	    line_count(Stream, Line),
	    read(Clause),
	    filter(Clause, Line, Source),
	    Clause = end_of_file,
	!,
	close(Stream).


filter(end_of_file, _, _).
filter(:-(Command), _, _) :-
	do_ops_in(Command).
filter(?-(Command), _, _) :-
	do_ops_in(Command).
filter(foreign_file(Foreign,_), Line, _) :-
	put(9), write('/* Near line '), write(Line), write(' */'), nl,
	put(9), write('/* Foreign: '), write(Foreign), write(' */'), nl.
filter(foreign(Cname,Template), Line, Source) :-
	process_foreign(c, Cname, Template, Line, Source).
filter(foreign(Fname,Language,Template), Line, Source) :-
	process_foreign(Language, Fname, Template, Line, Source).


%   do_ops_in(+Command)
%   is given the body of a :-Command or ?-Query and executes all the
%   op/3 commands it finds in it.  This is to ensure that you won't
%   get spurious syntax errors.

do_ops_in(true) :- !.	% catch variables
do_ops_in((A,B)) :- !,
	do_ops_in(A),
	do_ops_in(B).
do_ops_in(op(P,T,A)) :- !,
	op(P, T, A).
do_ops_in(_).		% ignore other commands.


%   process_foreign(+Language, +Fname, +Template, +Line, +Source)
%   is called when a foreign declaration
%	foreign(Fname, Language, Template).
%   has been found somewhere after line Line of Prolog file Source.
%   We can't be more precise about the line, though we could give
%   an upper bound as well as a lower bound.

process_foreign(Language, Fname, Template, Line, _) :-
	atom(Language),
	atom(Fname),
	nonvar(Template),
	functor(Template, Pname, Arity),
	atom(Pname),
	put(9), write('/* Near line '), write(Line), write(' */'), nl,
	put(9), put("{"), nl,
	declare(0, Arity, Template, Language, Args, Rtype, Rname),
	!,	
	(   Language \== fortran ->
	    Cname = Fname
	;   substring(Fname, '_', _, _, 0) ->
	    Cname = Fname
	;   midstring(Cname, Fname, '_', 0)
	),
	put(9), tab(4), write('extern '),
	write_type(Rtype), write(Cname), write('();'), nl,
	put(9), tab(4),
	(   Rname = '' -> true
	;   write(Rname), write(' = ')
	),
	write(Cname), put("("),
	current_output(Stream), line_position(Stream, Column),
	(   Column >= 66 ->
	    nl, put(9), put(9), ColumnsLeft is 56
	;   ColumnsLeft is 72-Column
	),
	write_args(Args, ColumnsLeft), write(');'), nl,
	use_result(Rtype, Rname),
	put(9), put("}"), nl.
process_foreign(Language, Fname, Template, _, _) :-
	atom(Language),
	atom(Fname),
	nonvar(Template),
	functor(Template, Pname, _),
	atom(Pname),
	put(9),
	format('   /* foreign(~w,~w,~w) */~n', [Fname,Language,Template]),
	put(9), tab(4), put("}"), nl,
	fail.
process_foreign(Language, Fname, Template, Line, Source) :-
	format(user_error, '~w:~w: invalid ~q~n',
	    [Source,Line,foreign(Fname,Language,Template)]).


/*  When we process a foreign template, the Nth argument of the
    Prolog predicate is mapped to a C identifier whose name is
	i<T><N>	for +Type	where type_abbrev(Type,T,_)
	o<T><N> for -Type	where type_abbrev(Type,T,_)
	r<T><N> for [-Type]	where type_abbrev(Type,T,_)
    For example,
	foreign(fred, c, fred(+integer,-atom,[-float],+string))
    would have arguments      ii1      oa2   rf3      si4
*/


declare(N, N, _, _, [], void, '') :- !.
declare(N, N, _, _, [], _, _) :- !.
declare(I, N, Template, Language, Args, Rtype, Rname) :-
	J is I+1,
	arg(J, Template, Argument),
	argument_direction(Argument, Direction, ArgType),
	type_abbrev(ArgType, Letter, Atype),
	concat_atom([Direction,Letter,J], Aname),
	(   Direction = r ->
	    Rtype = Atype, Rname = Aname, Args = Args0
	;   Direction = o      -> Args = [(Aname, &)|Args0]
	;   Language = fortran -> Args = [(Aname, &)|Args0]
	;			  Args = [(Aname,'')|Args0]
	),
	put(9), tab(4), write_type(Atype), write(Aname), write(' = 0;'), nl,
	declare(J, N, Template, Language, Args0, Rtype, Rname).

argument_direction(+ArgType,   i, ArgType).
argument_direction(-term,      i, term) :- !.
argument_direction(-ArgType,   o, ArgType).
argument_direction([-ArgType], r, ArgType).

type_abbrev(-,		_, _) :- !, fail.	% catch variables
type_abbrev(integer,	i, int).
type_abbrev(float,	f, float).
type_abbrev(double,	d, double).
type_abbrev(single,	g, float).
type_abbrev(atom,	a, 'QPatom').
type_abbrev(term,	t, 'QP_term_ref').
type_abbrev(string,	s, *(char)).
type_abbrev(string(_),	c, *(char)).
type_abbrev(address,	p, *(char)).
type_abbrev(address(X), p, *(X)).
type_abbrev(stream,	k, *('QP_stream')).	% for some built ins ONLY.


use_result(void, _) :- !.
use_result(Type, Name) :-
	result_format(Type, Name, Format, Argument),
	put(9), write('    (void)printf("%'), write(Format),
	write('", '), write(Argument), write(');'), nl.

result_format(*(_),    N, x, N).
result_format(int,     N, d, N).
result_format(float,   N, g, N).
result_format(double,  N, g, N).
result_format(single,  N, g, N).
result_format('QP_term_ref', N, x, N).
result_format('QPchan',N, u, N).
result_format('QPatom',N, s, 'QP_string_from_atom'(N)).


write_type(*(X)) :- !,
	write(X), write('* ').
write_type(X) :-
	write(X), put(" ").


write_args([], _).
write_args([Arg], Columns) :- !,
	write_arg(Arg, Columns, _).
write_args([Arg|Args], Columns) :-
	write_arg(Arg, Columns, ColumnsLeft), write(', '),
	write_args(Args, ColumnsLeft).

write_arg((Name,Direction), Columns, ColumnsLeft) :-
	string_size(Direction,  X1),
	string_size(Name,	X2),
	Size is X1+X2+2,
	(   Size =< Columns ->  C = Columns
	;   nl, put(9), put(9), C = 56
	),
	write(Direction), write(Name),
	ColumnsLeft is C-Size.


