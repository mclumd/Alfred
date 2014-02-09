%   Program: makelib
%   Author : Richard A. O'Keefe
%   Updated: 27 Aug 1990
%   Purpose: Build the Packages.Pl, Contents, and Index files.
%   Needs  : basics, lineio, files

/*========================================================================
		    Library File Headers.

    makelib writes out two text files.  These are "Index", which has

	<name>/<arity> <tab> <package> <tab> <file>

for each predicate in the library, and the other is Contents, which has

	<package> <tab> -- <space> <comment>
	<package> <tab> in <space> <file>
	<package> <tab> : <spaces> <name>/<arity>
	<blank line>

for each package in the library.   The idea is that to find out about a
package "fred" you give the UNIX command

	fgrep "fred<tab>" Contents

while to find out about predicate foobaz/3 you do

	fgrep "foobaz/3" Index

    A library file should start with one or more attribute lines, then
have at least one blank line, possibly some comments, and a  :- public
declaration.  All of the information needed by MakeLib.Pl is there.  A
header attribute line has one of the following forms:

	%   Module : <word> <comment>			(or)
	%   Package: <word> <comment>			(or)
	%   File   : <word> <comment>
	%   Author : <comment>				(or)
	%   Authors: <comment>
	%   Updated: <day> <month> <year> <comment>	(or)
	%   SCCS   : <comment>
	%   Defines: <comment>				(or)
	%   Purpose: <comment>
	%   Needs  : <packages>
	%   SeeAlso: <packages>
	%   WriteUp: <word> <comment>

where a <word> is one or more lower case letters or underscores, and
<packages> is one or more <word>s separated by commas and layout.  The
Package line names the package contained in this file; there must be a
Package line.  The Defines or Purpose line specifies the comment which
is to be written in the Contents file.  The Needs line says what other
packages must be present at run time if this package is to work.  That
has been rendered obsolete by ensure_loaded/1, and later use_module/1 
and use_module/2.

    In order to build a library description, prepare a file containing
the names of all the files you want included in the library, each file
on a separate line with no extra spaces or punctuation, then do

	% prolog
	?- compile(makelib).
	?- makelib(<the file name>).
	?- halt.

You would be well advised to save the old Contents and Index files
before doing this.

    Most library files should be module-files, and should start with

:- module(ModuleName, [
	ExportedPredicate,		% The predicate/arity specifications
	...
	ExportedPredicate		% are best in alphabetic order
   ]).

:- meta_predicate			% NOTE: if present, these must go
	<exported meta-predicates>.	% immediately after the module decl
					% to ensure correctness.  (A warning
					% is given otherwise.)
:- use_module(AnotherModuleFile, [
	ImportedPredicate,
	...
	ImportedPredicate
   ]),
   ...
   use_module(YetAnotherModule, [
	...
   ]).

:- op(...).

sccs_id('"@(#)90/08/27 makelib.pl	56.1"').

    If not a module-file, a library file should start with

:- public
	<declarations of predicates to go in Contents>.
[ :- mode
	<mode declarations for all predicates in alphabetic order>.]
[ :- op(...). ]...
[ :- ensure_loaded(...).]...

    The order may vary a bit.  The :- module(_,_) header or :- public
    declaration is ESSENTIAL.  The original design of the library had
    everything in the headers, so that "Needs" was a meta-fact.  What got
    implemented instead was :- ensure_loaded([...]). So MakeLib will now
    process such a command and build the needs information from that.

    Makelib requires two names from you:
    --	the name of a directory containing the library files.
	It may be given as an atom '' or as a string "" and may
	end with a solidus if you like but needn't.
	Thus "library", "library/", 'library', and 'library/'
	are all ok.  The default is '.'.
    --	the name of a file which names all the files to be processed.
	It must be given as an atom.  The default is 'FILES'.
	This file need not be in the library directory.  It can be anywhere.
	It contains file names (relative to the library directory),
	one per line, with no extra layout, and WITH the ".pl" extension.
	You will typically do "ls *.pl >FILES".
	The file names don't need to be in alphabetic order, but it will
	be much easier to fix things if they are.

    To make the Contents and Index files,
	% prolog
	| ?- compile(makelib).
	| ?- makelib.		% Directory='.', FileOfFiles='FILES'
OR	| ?- makelib(FileOfFiles).	% Directory='.'
OR	| ?- makelib(Directory, FileOfFiles).
	| ?- halt.

    The Contents and Index files will be written in the current directory,
    which may be the library directory but doesn't have to be.

    The makelib/[0,1,2] query may fail.  If this happens, *immediately*
    call seeing(File).  File will be instantiated to the name of the file
    which couldn't be parsed.  (Of course any syntax errors should have
    been fixed beforehand.)  The usual problem is that someone has added
    a new file which doesn't obey the library header conventions.  A
    library file should start with comment lines of the general form
	% <layout> <Property> <layout> : <layout> <value>
    including
	% {File|Package|Module} : <package name>
	% {Purpose|Defines} : <topic>
    Module is used for library modules which are documented in the manual.
    Package is used for other library modules.
    File is used for everything else.

========================================================================*/


:- public
	makelib/0,
	makelib/1,
	makelib/2.

:- dynamic
	file_todo/1,
	pack_todo/3,
	pred_todo/3.

:- ensure_loaded([
	library(basics),
	library(files),
	library(lineio)
    ]).


makelib :-
	makelib(., 'FILES').

makelib(FileOfFiles) :-
	makelib(., FileOfFiles).

makelib(Prefix, FileOfFiles) :-
	(   atom(Prefix), name(Prefix, Prefix1)
	;   append(Prefix, [], Prefix1) % check it's a list!
	),
	(   append(_, "/", Prefix1), Prefix2 = Prefix1
	;   append(Prefix1, "/", Prefix2)
	),  !,
	see(FileOfFiles),
	repeat,
	    (   get_line(FileChars),
		(   FileChars = [0'/|_], FullChars = FileChars
		;   append(Prefix2, FileChars, FullChars)
		) ->
		atom_chars(File, FullChars),
		can_open_file(File, read, warn),
		assert(file_todo(File)),
		fail
	    ;   true
	    ),
	!,
	seen,
	setof(FileName, file_todo(FileName), Files),
	tell('Contents'),
	do_files(Files),
	told,
	setof(pred_todo(P,N,F), pred_todo(P,N,F), Ps),
	tell('Index'),
	do_index(Ps),
/*	told,
	setof(pack_todo(P,F,N), pack_todo(P,F,N), Ks),
	tell('Packages.pl'),
	do_packages(Ks),	*/
	told.


do_files([]).
do_files([File|Files]) :-
	see(File),
	do_headers(package('UNKNOWN',[],[]), package(Pack,Note,Need)),
	assert(pack_todo(Pack,File,Need)),
	write(Pack), write('	% '), put_line(Note),
	write(Pack), write('	- '), write(File), nl,
	read(Term),
	do_public(Term, Pack),
	seen,
	!,
	do_files(Files).



do_public(:-(module(_,Preds)), Pack) :- !,
	sort(Preds, Exports),
	do_exports(Exports, Pack),
	setof(pred_todo(P,N,Pack), pred_todo(P,N,Pack), Ps),
	do_contents(Ps).
do_public(:-(public(Preds)), Pack) :- !,
	do_publics(Preds, Pack),
	setof(pred_todo(P,N,Pack), pred_todo(P,N,Pack), Ps),
	do_contents(Ps).
do_public(:-(mode(Preds)), Pack) :- !,
	write('Missing :- public declaration, :- mode used instead'), nl,
	do_public(:-(public(Preds)), Pack).
do_public(:-(meta_predicate(Preds)), Pack) :- !,
	write('Missing :- module declaration, :- meta_predicate used instead'), nl,
	do_public(:-(public(Preds)), Pack).

do_publics((A,B), Pack) :- !,
	do_publics(A, Pack),
	do_publics(B, Pack).
do_publics(P/N, Pack) :- !,
	assert(pred_todo(P,N,Pack)).
do_publics(G, Pack) :-
	functor(G, P, N),	% from :- mode or :- meta_predicate.
	assert(pred_todo(P,N,Pack)).

do_exports([], _).
do_exports([P/N|Exports], Pack) :- !,
	assert(pred_todo(P,N,Pack)),
	do_exports(Exports, Pack).
do_exports([Export|Exports], Pack) :-
	format(user_error, '% ignoring :-module(~q,[~q]).~n', [Pack,Export]),
	do_exports(Exports, Pack).

do_contents([]) :-
	nl.
do_contents([pred_todo(P,N,Pack)|Ps]) :-
	write(Pack), write('	: '), write(P/N), nl,
	do_contents(Ps).


do_index([]).
do_index([pred_todo(P,N,Pack)|Ps]) :-
	pack_todo(Pack, File, _),
	write(P/N), put(9), write(Pack), put(9), write(File), nl,
	!,
	do_index(Ps).




do_headers(OldInfo, NewInfo) :-
	get_line(Chars),
	do_header([C1,C2|_], Value, Chars, []),
	!,
	do_header(C1,C2, Value, OldInfo, MidInfo),
	do_headers(MidInfo, NewInfo).
do_headers(Info, Info).

do_header(0'n,0'e, Value, package(P,R,N0), package(P,R,N1)) :- !, % NEeds
	packages(N1, N0, Value, []).
do_header(0'd,0'e, Value, package(P,_,N), package(P,Value,N)) :- !. %DEfines
do_header(0'p,0'u, Value, package(P,_,N), package(P,Value,N)) :- !. %PUrpose
do_header(0'p,0'a, Value, package(_,R,N), package(P,R,N)) :- !,	% PAckage
	packages([P|_], [], Value, []).
do_header(0'm,0'o, Value, package(_,R,N), package(P,R,N)) :- !,	% MOdule
	packages([P|_], [], Value, []),
	write(P), write('	+ documented in manual'), nl.
do_header(0'f,0'i, Value, package(_,R,N), package(P,R,N)) :- !, % FIle
	packages([P|_], [], Value, []).
do_header(_,_, _, PackageInfo, PackageInfo).


do_header(Attribute, Value) -->
	"%",
	layout,
	word(Attribute),
	":",
	layout,
	literal(Value).

layout -->
	[C], {C =< " "}, !,
	layout.
layout --> [].

word([C|Cs]) -->
	[C], {C >= "a", C =< "z"}, !,
	word(Cs).
word([C|Cs]) -->
	[D], {D =< "Z", D >= "A", C is D+32}, !,
	word(Cs).
word([C|Cs]) -->
	[C], {C >= "0", C =< "9"}, !,
	word(Cs).
word([0'_|Cs]) -->
	"_", !,
	word(Cs).
word(Cs) -->
	[D], {D =< " "}, !,
	word(Cs).
word([]) --> [].

literal(X, X, []).	% hack


packages([Pack|Packs], Tail) -->
	word([Char|Chars]), {atom_chars(Pack, [Char|Chars])},
	!,
	packages(Packs, Tail).
packages(Tail, Tail) -->
	literal(_).

/*
do_packages([]).
do_packages([pack_todo(Pack,File,Needs)|Packs]) :-
	write('library_package('),
	write(Pack), put(","), nl,
	put(9), writeq(File), put(","), nl,
	put(9), write(Needs), write(').'), nl, nl,
	do_packages(Packs).
*/

