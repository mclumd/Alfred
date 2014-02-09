%   Package: filename
%   Author : Richard A. O'Keefe
%   Updated: 02 Apr 1994
%   Purpose: Portable file name manipulation a la Common Lisp

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(file_name, [
	filename/1,		% FileName ->	
	filename/2,		% FileSpec -> FileName
	filename/3,		% Property x FileSpec -> FileName
	filename_atom/2,	% FileName <-> Atom
	filename_atom/3,	% Property x FileSpec -> Atom
	filename_chars/2,	% FileName <-> Chars
	filename_chars/3,	% Property x FileSpec -> Chars
	filename_chars/4,	% Property x FileSpec -> Chars\Chars
	filename_directory/4,	% Integer x AtomList x FileName -> Directory
	open_file/3,		% FileSpec x Mode -> Stream
	portray_filename/1
   ]).

:- use_module(library(basics), [
	memberchk/2
   ]),
   use_module(library(environment), [
	environment/1
   ]).

sccs_id('"@(#)94/04/02 filename.pl	72.1"').


/*  For documentation, see filename.txt.
*/


%   filename(+FileName)
%   is true when FileName is a plausible file name record, that is, it
%   has the right functor and each of the fields is individually plausible.
%   It does NOT check that the combination of the fields makes sense on
%   the local file system, or that the various atoms are are within the
%   length limits.

filename(file_name(Host,Device,AbsRel,Dirs,Name,Type,Version)) :-
	(   atom(Device) -> true		% specified
	;   integer(Device) -> Device =:= -1	% omitted
	),
	integer(AbsRel), AbsRel >= -3,
	proper_atoms(Dirs),	% if AbsRel = -1, is []
	(   atom(Type) -> true			% specified
	;   integer(Type) -> Type =:= -1	% omitted
	),
	atomic(Version),	% integer -> supplied, '' -> omitted
	(   atom(Name) -> true			% specified
	;   integer(Name) -> Name =:= -1	% omitted
	;   Name = {Remote}, atom(Remote)	% VMS "foreign file-spec"
	),
	(   atom(Host) -> true			% specified
	;   integer(Host) -> Host =:= -1	% omitted
	;   Host = Site/Access, atom(Site), atom(Access)
	).


%.  proper_atoms(+Atoms)
%   succeeds when Atoms is a proper list of Atoms.  Note that we DON'T
%   check the length of this list.

proper_atoms(*) :- !, fail.
proper_atoms([]).
proper_atoms([Atom|Atoms]) :-
	atom(Atom),
	proper_atoms(Atoms).


/*  One noticable difference between the operations in this file and the
    similar operations in Common Lisp is that Common Lisp will take a
    stream as a surrogate for the name of the file the stream is connected
    to.  However, in Quintus Prolog it is quite common for streams to be
    connected to things other than files (in Quintus LPA Prolog -- ahem --
    streams may be connected to windows), and there is as yet no way for
    a user-defined stream connected to a file to proclaim which file it
    is connected to.  Use current_stream/3 in the mean time.
*/

%   filename(+FileSpec, ?FileName)
%   takes a file specification as an atom, string, list of character
%   codes, file name record, or list of fields, and returns a file
%   name record which is a normal form of the FileSpec.  The idea is
%   that filename(A, X) & filename(B, X) => A and B represent the same
%   file no matter what the state of the file system.

%   This uses chars_to_file_name//1 in filename.$OS

filename(FileSpec, FileName) :-
	(   atom(FileSpec) ->
	    atom_chars(FileSpec, Chars),
	    chars_to_file_name(X, Chars, "")
	;   FileSpec = [C|_], integer(C) ->
	    chars_to_file_name(X, FileSpec, "")
	;   FileSpec = [_|_] ->
	    pack_file_name(FileSpec, -1,-1,-1,[],-1,-1,'', X)
	;   FileSpec = library(Foo) ->
	    absolute_file_name(library(Foo), LibSpec),
	    filename(LibSpec, X)
	;   filename(FileSpec) ->
	    X = FileSpec
	),
	FileName = X.


%   filesite(+FileSpec, ?Site)
%   takes a site specification (a file name with name, type, and version
%   omitted) as an atom, string, list of character codes, file name
%   record, or list of fields, and returns a file name record containing
%   the "site" part of the FileSpec.  This is not exported.

%   This uses chars_to_file_site//1 in filename.$OS

filesite(SiteSpec, SiteName) :-
	(   atom(SiteSpec) ->
	    atom_chars(SiteSpec, Chars),
	    chars_to_file_site(X, Chars, "")
	;   SiteSpec = [C|_], integer(C) ->
	    chars_to_file_site(X, SiteSpec, "")
	;   SiteSpec = [_|_] ->
	    pack_file_name(SiteSpec, -1,-1,-1,[],-1,-1,'', X)
	;   SiteSpec = library(Foo) ->
	    absolute_file_name(library(Foo), LibSpec),
	    filesite(LibSpec, X)
	;   filename(SiteSpec) ->
	    X = SiteSpec
	),
	SiteName = X.


%   fileword(+WhichWord, +WordSpec, -Word)
%   takes a single file component (device, name, or version) as an
%   atom, string, or list of character codes, and returns an atom
%   containing the normalised form of that word.  This is not exported.
%   The point of it is to take into account OS-specific normalisation,
%   e.g. "FredTheOyster" -> 'FREDTHEOYSTER'.  

%  This uses chars_to_file_word//1 in filename.$OS

fileword(WhichWord, WordSpec, Word) :-
	(   atom(WordSpec) ->
	    atom_chars(WordSpec, Chars)
	;   WordSpec = [C|_], integer(C) ->
	    Chars = WordSpec
	),
	chars_to_file_word(WhichWord, Word, Chars, "").


pack_file_name([], H,D,A,L,N,T,V, file_name(H,D,A,L,N,T,V)).
pack_file_name([F|Fs], H,D,A,L,N,T,V, X) :-
	pack_file_name(F, H,D,A,L,N,T,V, X, Fs).

pack_file_name(host(S), _,D,A,L,N,T,V, X, Fs) :-
	fileword(host, S, H),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(device(S), H,_,A,L,N,T,V, X, Fs) :-
	fileword(device, S, D),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(directory(F), H,D,_,_,N,T,V, X, Fs) :-
	filesite(F, file_name(_,_,A,L,_,_,_)),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(name(S), H,D,A,L,_,T,V, X, Fs) :-
	fileword(name, S, N),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(type(S), H,D,A,L,N,_,V, X, Fs) :-
	fileword('type', S, T),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(extension(S), H,D,A,L,N,_,V, X, Fs) :-
	fileword('type', S, T),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(version(V), H,D,A,L,N,T,_, X, Fs) :-
	integer(V),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(site(S), _,_,_,_,N,T,V, X, Fs) :-
	filesite(S, file_name(H,D,A,L,_,_,_)),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(base(B), H,D,A,L,_,_,V, X, Fs) :-
	filename(B, file_name(_,_,_,_,N,T,_)),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(stem(S), _,_,_,_,_,T,V, X, Fs) :-
	filename(S, file_name(H,D,A,L,N,_,_)),
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(all(F), H0,D0,A0,L0,N0,T0,V0, X, Fs) :-
	filename(F, file_name(H1,D1,A1,L1,N1,T1,V1)),
	( integer(H1) -> H = H0 ; H = H1 ),
	( integer(D1) -> D = D0 ; D = D1 ),
	( A1 =:= -1 -> A = A0, L = L0 ; A = A1, L = L1 ),
	( integer(N1) -> N = N0 ; N = N1 ),
	( integer(T1) -> T = T0 ; T = T1 ),
	( integer(V1) -> V = V1 ; V = V0 ),	% this is right!
	pack_file_name(Fs, H,D,A,L,N,T,V, X).
pack_file_name(no(F), H,D,A,L,N,T,V, X, Fs) :-
	pack_no_part(F, H,D,A,L,N,T,V, X, Fs).

pack_no_part(host, _,D,A,L,N,T,V, X, Fs) :-
	pack_file_name(Fs, -1,D,A,L,N,T,V, X).
pack_no_part(device, H,_,A,L,N,T,V, X, Fs) :-
	pack_file_name(Fs, H,-1,A,L,N,T,V, X).
pack_no_part(directory, H,D,_,_,N,T,V, X, Fs) :-
	pack_file_name(Fs, H,D,-1,[],N,T,V, X).
pack_no_part(name, H,D,A,L,_,T,V, X, Fs) :-
	pack_file_name(Fs, H,D,A,L,-1,T,V, X).
pack_no_part('type', H,D,A,L,N,_,V, X, Fs) :-
	pack_file_name(Fs, H,D,A,L,N,-1,V, X).
pack_no_part(extension, H,D,A,L,N,_,V, X, Fs) :-
	pack_file_name(Fs, H,D,A,L,N,-1,V, X).
pack_no_part(version, H,D,A,L,N,T,_, X, Fs) :-
	pack_file_name(Fs, H,D,A,L,N,T,'', X).
pack_no_part(site, _,_,_,_,N,T,V, X, Fs) :-
	pack_file_name(Fs, -1,-1,-1,[],N,T,V, X).
pack_no_part(base, H,D,A,L,_,_,V, X, Fs) :-
	pack_file_name(Fs, H,D,A,L,-1,-1,V, X).
pack_no_part(stem, _,_,_,_,_,T,V, X, Fs) :-
	pack_file_name(Fs, -1,-1,-1,[],-1,T,V, X).
pack_no_part(all, _,_,_,_,_,_,_, X, Fs) :-
	pack_file_name(Fs, -1,-1,-1,[],-1,-1,'', X).


%   filename_chars(?FileName, ?Chars)
%   is true when FileName is a file name record and Chars is a list of
%   character codes and both of them convey the same information about
%   a file name.  If FileName is given, a unique Chars will result and
%   if Chars is given, a unique FileName will result.  However, you'll
%   find that it isn't perfectly invertible:
%   Unix : "///fred" -> FileName -> "/fred" -> FileName
%   VMS  : "fred" -> FileName -> "FRED" -> FileName
%   MSDOS: "a/fred" -> FileName -> "A\FRED" -> FileName
%   The file name need not be complete:  it might for example name a
%   directory rather than a file.  But what there is of it must suit
%   the conventions of the local file system.

filename_chars(File, Chars) :-
    (	var(File) ->
	chars_to_file_name(File, Chars, "")
    ;	file_name_to_chars(File, Chars, "")
    ).


%   filename_atom(?FileName, ?Atom)
%   is true when FileName is a file name record and Atom is an atom
%   and both of them convey the same information about a file name.
%   See the comments on filename_chars/2.

filename_atom(File, Atom) :-
    (	var(File) ->
	atom_chars(Atom, Chars),
	chars_to_file_name(File, Chars, "")
    ;	file_name_to_chars(File, Chars, ""),
	atom_chars(Atom, Chars)
    ).


%   filename(?Property, +FileSpec, ?Value)
%   FileSpec is any sort of file specification at all: an atom, a string,
%   a list of character codes, a file name record, or a list of "fields".
%   filename/3 is true when Property is the name of a property of file
%   names and Value is a file name record containing just that part of
%   the file name record corresponding to FileSpec.  For example,
%   filename(stem, '[FOO]BAZ.PL;3', X) has (in VMS) the answer
%   X = file_name(-1,-1,-2,['FOO'],'BAZ',-1,''), which prints as
%   '[FOO]BAZ'.

filename(Property, FileSpec, Value) :-
	filename(FileSpec, FileName),
	filename_1(Property, FileName, Value).

filename_1(all,		FileName,
			FileName).
filename_1(host,	file_name(Host, _, _, _, _, _, _),
			file_name(Host,-1,-1,[],-1,-1,'')) :- Host \== -1.
filename_1(device,	file_name( _,Device, _, _, _, _, _),
			file_name(-1,Device,-1,[],-1,-1,'')) :- atom(Device).
filename_1(directory,	file_name( _, _,AbsRel,Dirs, _, _, _),
			file_name(-1,-1,AbsRel,Dirs,-1,-1,'')) :- AbsRel =\= -1.
filename_1(name,	file_name( _, _, _, _,Name, _, _),
			file_name(-1,-1,-1,[],Name,-1,'')) :- atom(Name).
filename_1('type',	file_name( _, _, _, _, _,Type, _),
			file_name(-1,-1,-1,[],-1,Type,'')) :- atom(Type).
filename_1(extension,   file_name( _, _, _, _, _,Type, _),
			file_name(-1,-1,-1,[],-1,Type,'')) :- atom(Type).
filename_1(version,	file_name( _, _, _, _, _, _,Version),
			file_name(-1,-1,-1,[],-1,-1,Version)) :- integer(Version).
filename_1(site,	file_name(Host,Device,AbsRel,Dirs, _, _, _),
			file_name(Host,Device,AbsRel,Dirs,-1,-1,'')).
filename_1(base,	file_name( _, _, _, _,Name,Type, _),
			file_name(-1,-1,-1,[],Name,Type,'')).
filename_1(stem,	file_name(Host,Device,AbsRel,Dirs,Name, _, _),
			file_name(Host,Device,AbsRel,Dirs,Name,-1,'')).


%   filename_chars(?Property, +FileSpec, ?Chars)
%   FileSpec is any sort of file specification and must be given.
%   filename_chars/3 is true when Property is the name of a property
%   of file names, and Chars is that part of the file name as a list
%   of characters.  E.g.
%   filename_chars(extension, 'zabbo.qof', "qof").

filename_chars(Property, FileSpec, Chars) :-
	filename(FileSpec, FileName),
	filename_1(Property, FileName, Value),
	file_name_to_chars(Value, Chars, "").


%   filename_chars(?Property, +FileSpec, ?Chars0, ?Chars)
%   is like filename_chars/3 except that it returns the part of the
%   file name in question as a difference list.  For example, in a
%   grammar rule you can use filename_chars(all, FileSpec) to generate
%   the normalised text of the file name.

filename_chars(Property, FileSpec, Chars0, Chars) :-
	filename(FileSpec, FileName),
	filename_1(Property, FileName, Value),
	file_name_to_chars(Value, Chars0, Chars).


%   filename_atom(?Property, +FileSpec, ?Atom)
%   returns part of a file specification as an atom.  It includes
%   whatever punctuation would normally go with that part of the
%   file name.  For example, in VMS:
%	FileSpec = 'Erewhon::disc:[my]zabbo.dat',
%	filename_atom(host, FileSpec, 'EREWHON::'),
%	filename_atom(directory, FileSpec, '[MY]')
%   where you might reasonably have expected
%*	filename_atom(host, FileSpec, 'EREWHON'),
%*	filename_atom(directory, FileSpec, 'MY').
%   Note that a version number (";3") will be returned as an atom
%   like ';3' rather than a number like 3.  There is nothing which
%   returns a version number as a number.

filename_atom(Property, FileSpec, Atom) :-
	filename(FileSpec, FileName),
	filename_1(Property, FileName, Value),
	file_name_to_chars(Value, Chars, ""),
	atom_chars(Atom, Chars).


%   filename_directory(+RootWards, +LeafWards, +FileName, -Site)
%   RootWards is a non-negative integer.
%   LeafWards is a possibly empty list of atoms.
%   FileName is a *FILE* name (not a directory name).  The name, type,
%   and version of FileName will be ignored, and only the site (host,
%   device, and directory) information used.  If you want to refer to
%   a directory such as /usr/ok/library.d/SCCS, you have to add a slash
%   to ensure that it is read as a directory:
%	/usr/ok/library.d/SCCS/		==> that directory itself
%   but /usr/ok/library.d/SCCS		==> the directory containing it!
%   The same trick is used for MS-DOS (use a trailing / or \) and the
%   Macintosh file system (use a trailing :).  No such trick is needed
%   for VMS.  For CMS, use '+ + ' in front of the directory, e.g.
%	+ + VMsysu:MyLogin.Subdir
%   Site is a file name record with omitted name, type, version
%   which refers to the directory obtained by going RootWards
%   steps towards the root of the file system, then attaching the
%   given LeafWards directories.  For example,
%	filename_directory(2, '/usr/ok/library.d/SCCS/', [quintus.d], X)
%   => X is a file name record representing '/usr/ok/quintus.d/'.
%   Note that the Site result can be given to filename_directory/4
%   again, as the file name record representing a directory is unambiguous.
%   Note that the LeafWard names have to be normalised, e.g.
%	filename_directory(0, [foo,baz], ugh, X)
%   =>	X = \FOO\BAZ\	on MS-DOS, or X = [.FOO.BAZ] on VMS.

filename_directory(RootWards, LeafWards, FileName, Site) :-
	integer(RootWards), RootWards >= 0,
	proper_atoms(LeafWards),
	filename(FileName, Record),
	!,
	normalise_subdirs(LeafWards, NewDirs),
	filename_directory_1(RootWards, NewDirs, Record, Site).
/*
filename_directory(RootWards, LeafWards, FileName, Site) :-
	Goal = filename_directory(RootWards,LeafWards,FileName,Site),
	should_be(nonneg,   RootWards, 1, Goal),
	should_be(atoms,    LeafWards, 2, Goal),	% NO SUCH TYPE YET
	should_be(filespec, FileName,  3, Goal).	% NO SUCH TYPE YET
*/
	
filename_directory_1(RootWards, LeafWards,
		file_name(Host,Device,AbsRel0,Dirs0,_,_,_),
		file_name(Host,Device,AbsRel, Dirs, -1,-1,'')) :-
	(   AbsRel0 =:= -1 ->		% if unspecified
	    AbsRel1 = 0			% treat it as relative
	;   AbsRel1 = AbsRel0
	),
	(   RootWards =:= 0 ->		% fast path
	    AbsRel = AbsRel1,
	    lit(Dirs0, Dirs, LeafWards)
	;   reverse(Dirs0, Dirs1),
	    pop_dirs(Dirs1, AbsRel1, RootWards, LeafWards, AbsRel, Dirs)
	).

pop_dirs([], AbsRel0, RootWards, LeafWards, AbsRel, LeafWards) :-
	(   AbsRel0 >= 0 -> AbsRel is AbsRel0+RootWards
	;   AbsRel0 =:= -2 -> RootWards =:= 0, AbsRel is AbsRel0
    /*	;   AbsRel0 =:= -3 -> fail {we have gone too far}  */
	).
pop_dirs([Dir0|Dirs0], AbsRel0, RootWards, LeafWards, AbsRel, Dirs) :-
	(   RootWards =:= 0 ->
	    AbsRel = AbsRel0,
	    reverse(Dirs0, [Dir0|LeafWards], Dirs)
	;   RootWards1 is RootWards-1,
	    pop_dirs(Dirs0, AbsRel0, RootWards1, LeafWards, AbsRel, Dirs)
	).



%   open_file(+FileSpec, +Mode, -Stream)
%   FileSpec can be an atom or a library(...) form as in open/3.
%   It can also be a list of character codes, a file name record,
%   or a list of properties.

open_file(FileSpec, Mode, Stream) :-
	filename_atom(all, FileSpec, Atom),
	open(Atom, Mode, Stream).


%   explode(+Constant) --> name

explode(Constant) --> { name(Constant, Chars) }, lit(Chars).

%   lit(A, AZ, Z) :- append(A, Z, AZ)

lit([]) --> [].
lit([C|Cs]) --> [C], lit(Cs).

reverse(L, R) :-
	reverse(L, [], R).

reverse([], L, L).
reverse([H|T], L, R) :-
	reverse(T, [H|L], R).


cms_rest_name(0, T, []) --> !, cms_rest_name(T).
cms_rest_name(N, T, [D|Ds]) --> [C], { cms_char(C, S, D), S < T }, !,
	{ M is N-1 },
	cms_rest_name(M, T, Ds).
cms_rest_name(_, _, []) --> [].

cms_rest_name(T) --> [C], { cms_char(C, S, _), S < T }, !, cms_rest_name(T).
cms_rest_name(_) --> [].

dotdots(N, DotDot, End) -->
	(   { N =:= 0 } -> lit(End)
	;   { M is N-1 }, lit(DotDot), dotdots(M, DotDot, End)
	).

portray_filename(FileName) :-
	filename(FileName),
	!,
	file_name_to_chars(FileName, Chars, ""),
	format('~s', [Chars]).

:- ensure_loaded('filename.unix').


end_of_file.


/* debugging */

:- ensure_loaded(library(printchars)).
:- ensure_loaded(library(addportray)).
:- ensure_loaded(library(lineio)).

:- add_portray(portray_filename).

go :-
	repeat,
	get_line(Chars),
	chars_to_file_name(File, Chars, ""),
	filename(Field, File, Value),
	print((Field->Value)), nl,
	fail.

/*  Test cases for filename_directory  */
%   Call with all arguments variables.

t(R, L, F, D) :-
	(   F = '/usr/ok/library.d/filename.pl'
	;   F = "/usr/ok/library.d/"
	;   F = "~ok/library.d/."
        ;   F = "."
	;   F = "example/"
	),
/* VMS version:
	(   F = '[user.ok.library]filename.pl'
	;   F = "[user.ok.library]"
	;   F = "[]"
	;   F = "[.example]"	
	;   F = '[-]'
	),
*/
/* MS-DOS version:
	(   F = '/usr/ok/library.d/filename.pl'
	;   F = "/usr/ok/library.d/"
	;   F = "."
	;   F = "example/"
	;   F = '..'
	),
*/
	(   L = []
	;   L = [demo]
	;   L = [demo,protalk]
	),
	(   R = 0
	;   R = 1
	;   R = 2
	;   R = 3
	;   R = 4
	),
	filename_directory(R, L, F, D).

/*  Here is the expected output from
	:- t(R,L,F,D), print(t(R,L,F,D)), nl, fail.

t(0,[],/usr/ok/library.d/filename.pl,/usr/ok/library.d/)
t(1,[],/usr/ok/library.d/filename.pl,/usr/ok/)
t(2,[],/usr/ok/library.d/filename.pl,/usr/)
t(3,[],/usr/ok/library.d/filename.pl,/)
t(0,[demo],/usr/ok/library.d/filename.pl,/usr/ok/library.d/demo/)
t(1,[demo],/usr/ok/library.d/filename.pl,/usr/ok/demo/)
t(2,[demo],/usr/ok/library.d/filename.pl,/usr/demo/)
t(3,[demo],/usr/ok/library.d/filename.pl,/demo/)
t(0,[demo,protalk],/usr/ok/library.d/filename.pl,/usr/ok/library.d/demo/protalk/)
t(1,[demo,protalk],/usr/ok/library.d/filename.pl,/usr/ok/demo/protalk/)
t(2,[demo,protalk],/usr/ok/library.d/filename.pl,/usr/demo/protalk/)
t(3,[demo,protalk],/usr/ok/library.d/filename.pl,/demo/protalk/)
t(0,[],"/usr/ok/library.d/",/usr/ok/library.d/)
t(1,[],"/usr/ok/library.d/",/usr/ok/)
t(2,[],"/usr/ok/library.d/",/usr/)
t(3,[],"/usr/ok/library.d/",/)
t(0,[demo],"/usr/ok/library.d/",/usr/ok/library.d/demo/)
t(1,[demo],"/usr/ok/library.d/",/usr/ok/demo/)
t(2,[demo],"/usr/ok/library.d/",/usr/demo/)
t(3,[demo],"/usr/ok/library.d/",/demo/)
t(0,[demo,protalk],"/usr/ok/library.d/",/usr/ok/library.d/demo/protalk/)
t(1,[demo,protalk],"/usr/ok/library.d/",/usr/ok/demo/protalk/)
t(2,[demo,protalk],"/usr/ok/library.d/",/usr/demo/protalk/)
t(3,[demo,protalk],"/usr/ok/library.d/",/demo/protalk/)
t(0,[],"~ok/library.d/.",~ok/library.d/)
t(1,[],"~ok/library.d/.",~ok/)
t(0,[demo],"~ok/library.d/.",~ok/library.d/demo/)
t(1,[demo],"~ok/library.d/.",~ok/demo/)
t(0,[demo,protalk],"~ok/library.d/.",~ok/library.d/demo/protalk/)
t(1,[demo,protalk],"~ok/library.d/.",~ok/demo/protalk/)
t(0,[],".",)
t(1,[],".",../)
t(2,[],".",../../)
t(3,[],".",../../../)
t(4,[],".",../../../../)
t(0,[demo],".",demo/)
t(1,[demo],".",../demo/)
t(2,[demo],".",../../demo/)
t(3,[demo],".",../../../demo/)
t(4,[demo],".",../../../../demo/)
t(0,[demo,protalk],".",demo/protalk/)
t(1,[demo,protalk],".",../demo/protalk/)
t(2,[demo,protalk],".",../../demo/protalk/)
t(3,[demo,protalk],".",../../../demo/protalk/)
t(4,[demo,protalk],".",../../../../demo/protalk/)
t(0,[],"example/",example/)
t(1,[],"example/",)
t(2,[],"example/",../)
t(3,[],"example/",../../)
t(4,[],"example/",../../../)
t(0,[demo],"example/",example/demo/)
t(1,[demo],"example/",demo/)
t(2,[demo],"example/",../demo/)
t(3,[demo],"example/",../../demo/)
t(4,[demo],"example/",../../../demo/)
t(0,[demo,protalk],"example/",example/demo/protalk/)
t(1,[demo,protalk],"example/",demo/protalk/)
t(2,[demo,protalk],"example/",../demo/protalk/)
t(3,[demo,protalk],"example/",../../demo/protalk/)
t(4,[demo,protalk],"example/",../../../demo/protalk/)
*/

/*  The following operations have not yet been coded:

	change_directory/1,	% DirectoryAndDevice ->
	change_directory/2,	% Device x Directory ->
	current_directory/1,	% -> DirectoryAndDevice
	current_directory/2,	% Device -> Directory

%   current_directory(?Directory)
%   returns the current default (host, device, and) directory.  In the
%   terms I use here, what it really returns is a "Site".  We have a
%   choice here:  we could return a filename record, or we could return
%   an atom.  An important point is that we want to refer unambiguously
%   to the directory AS a directory, not as a file.  Unix, VMS, and
%   MS-DOS all represent a directory on disc as an actual file (I note
%   that Burroughs speeded up file opening and closing in the B6700 MCP
%   by providing a single hash table per disc for all file names on that
%   disc, so that opening a file one was disc access, not several).  For
%   example, if I call
%	absolute_file_name(., X)
%   on the machine where I'm editing this, I get
%	X = '/usr/ok/library.d'
%   but that has the form of a file name.  To make it unambiguously a
%   directory, I'd need to change it to
%	X = '/usr/ok/library.d/'
%   I have chosen to return directories as filename records.  This
%   means that we can easily do
%	current_directory(CWD),
%	...
%	open_file([site(CWD),name(fred),type(pl)], read, Stream)
%   or that we can do
%	current_directory(CWD),
%	filename_directory(0, [subdir], CWD, SubDir)

*/


