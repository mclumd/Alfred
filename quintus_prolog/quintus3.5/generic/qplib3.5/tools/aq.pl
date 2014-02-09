%   File   : qc.pl
%   Author : Richard A. O'Keefe
%   Updated: 28 Jul 1993
%   Purpose: Arity Prolog to Quintus Prolog translator

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/*
    arity2quintus translation package: see makefile for how to build
    an executable saved state.

    This package is distributed in the hope that it will be useful,
    but without any warranty.  You are expressly warned that it is meant
    to serve as a model, not for direct use:  all error checking and
    reporting has been omitted, and mistakes are almost surely present.
*/

:- compile([
	aq_tokens,
	aq_read,
	aq_translate
   ]).

aq(Stem) :-
	atom_chars(Stem, StemChars),
	append(StemChars, ".pro", InputChars),
	atom_chars(Input, InputChars),
	append(StemChars, ".pl", OutputChars),
	atom_chars(Output, OutputChars),
	aq(Input, Output).

aq(Input, Output) :-
	seeing(OldInput),
	see(Input),
	telling(OldOutput),
	tell(Output),
	repeat,
	    arity_read(Term, Dictionary),
	    process(Term, Dictionary),
	!,
	ensure_libraries,
	told, tell(OldOutput),
	seen, see(OldInput).

process(end_of_file, _) :- !.
process(-->(Lhs,Rhs), Dictionary) :- !,
	expand_term(-->(Lhs,Rhs), :-(H,B)),
	translate(B, BPrime),
	portray_clause_with_vars(:-(H,BPrime), Dictionary).
process(:-(H,B), Dictionary) :- !,
	translate(B, BPrime),
	portray_clause_with_vars(:-(H,BPrime), Dictionary).
process(:-(Decl), Dictionary) :- !,
	process_decl(Decl, Dictionary),
	fail.
process(?-(Decl), Dictionary) :- !,
	process_decl(Decl, Dictionary),
	fail.
process(H, Dictionary) :-
	portray_clause_with_vars(H, Dictionary).

process_decl(visible(_), _) :- !,
	format(user_error, '~N% :- ~w declaration ignored.~n', [(visible)]).
process_decl(extern(_), _) :- !,
	format(user_error, '~N% :- ~w declaration ignored.~n', [(extern)]).
process_decl(module(_), _) :- !,
	format(user_error, '~N% :- ~w declaration ignored.~n', [(module)]).
process_decl(mode(_), _) :- !,
	format(user_error, '~N% :- ~w declaration ignored.~n', [(mode)]).
process_decl(public(_), _) :- !,
	format(user_error, '~N% :- ~w declaration ignored.~n', [(public)]).
process_decl(D, Dictionary) :-
	translate(D, DPrime),
	portray_clause_with_vars(:-(DPrime), Dictionary).


portray_clause_with_vars(Clause, Dictionary) :-
	bind(Dictionary),
	portray_clause(Clause),
	fail.

bind([]).
bind([Name='$VAR'(Name)|Dictionary]) :-
	bind(Dictionary).

user_help :-
	write('This is an Arity/Prolog to Quintus Prolog translator.'), nl,
	write('It works one file at a time.'), nl,
	write('To translate a file foobaz.pro to foobaz.pl,'), nl,
	write('   give the command :- aq(foobaz).'), nl,
	write('To translate a file snibbo.sno to threadgold.gar,'), nl,
	write('   give the command :- aq(''snibbo.sno'', ''threadgold.gar'').'), nl,
	write('Snips, ifthenelse, case, and so on are supported,'), nl,
	write('but windowing isn''t.'), nl.

