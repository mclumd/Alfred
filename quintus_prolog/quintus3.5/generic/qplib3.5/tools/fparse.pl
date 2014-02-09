% %W% %G%

:- module(fparse, [
    fparse/4,	% +FileSpec, -Dir, -Name, -Suffix
    fparse/3,	% +FileSpec1, +FileSpec2, -FileSpec
    remove_filename_suffix/2, basename/2,
    filename/5,
    proper_directory_name/2	% +Dir0, -Dir
		  ]).

:- use_module(char_dcgs).
:- use_module(library(ctypes)).

fparse(FN, Dir, Name, Suffix) :-
    absolute_file_name(FN, [solutions(all)], Abs), % [MC] 3.5
    atom_chars(Abs, FS),
    filename(DirS, NameS, SuffixS, FS, []),
    atom_chars(Dir, DirS),
    atom_chars(Name, NameS),
    atom_chars(Suffix, SuffixS).

/* fparse/3 picks up specs from the second argument. For example,

   fparse(foo,'/tmp/x.pl', '/tmp/foo.pl')

*/

fparse(FN1, FN2, F) :-
    absolute_file_name(FN1, [solutions(all)], Abs), % [MC] 3.5
    atom_chars(Abs, C1),
    filename(D1x, N1, S1, C1, ""),
    relative_pathname(D1x, R1, D1),
    atom_chars(FN2, C2),
    filename(D2x, N2, S2, C2, ""),
    relative_pathname(D2x, R2, D2),
    def(D1, D2, X, X1),
    def(R1, R2, X1, X2),
    def(N1, N2, X2, X3),
    def(S1, S2, X3, []),
    atom_chars(F, X).

relative_pathname(X, X, "") :- X = [H|_], H =\= 0'/, !.
relative_pathname(X, "", X).

def(X1, X2, S0, S) :- def(X1, X2, X), append(X, S, S0).

def([], X, X) :- !.
def(X, _, X).

filename(Dir, Name, Suffix) --> graphs(Dir), nsp(Name),
    ("", {Suffix=""} | ".", {Suffix=[0'.|Sfix]}, ns(Sfix)), !.

nsp("") --> [].
nsp([A|T]) --> [A], {is_graph(A), A =\= 0'., A =\= 0'/}, nsp(T).

ns("") --> [].
ns([A|T]) --> [A], {is_graph(A), A =\= 0'/}, ns(T).

/* given a file specification, return the same without the suffix.

examples,

remove_filename_suffix('a/b.c', 'a/b')
remove_filename_suffix('a/b', 'a/b').
remove_filename_suffix('a.b', a).
remove_filename_suffix(a,a).

*/

remove_filename_suffix(FileSpec, Name) :-
    name(FileSpec, FC),
    filename(NC, _, FC, []),
    name(Name, NC).

filename(Prefix, Suffix) --> graphs(Prefix),
    ("", {Suffix=""} | ".", ns(Suffix)), !.

basename(FileSpec, BaseName) :-
    atom_chars(FileSpec, Chars),
    basename(BC, Chars, []),
    atom_chars(BaseName, BC).

basename(BC) --> graph, ns(BC), ("/" | ""), !.

proper_directory_name(D0, D) :- atom_chars(D0, C), append(_, [L], C),
    (   L =:= 0'/
    ->  D = D0
    ;   append(C, "/", X), atom_chars(D, X)
    ).
