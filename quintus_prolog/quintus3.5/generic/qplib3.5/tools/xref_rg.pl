/* @(#)xref_rg.pl	76.1 07/31/98

Author: Tom Howland

*/

usage :- write(user_error,
'usage: qpxref [-v] [-c] [-i ifile] [-w wfile] [-x xfile] [-u ufile] fspec ...

  -c ......... generate standard compiler style error messages
  -v ......... verbose output. This echoes the names of the files being read to
	       stderr.
  -i ifile ... an initialization file. This is the same as the initialization
	       file supplied to qpc.
  -w wfile ... warning file. Warnings are written to stderr by default.
  -x xfile ... cross reference file. The cross reference is written to stdout by
	       default.
  -m mfile ... generate a file indicating which predicates are imported and
	       which are exported for each file. This is not generated by
	       default.
  -u ufile ... generate a file listing all the undefined predicates.  This is
	       not generated by default.
  fspec ...... one or more prolog file specifications.

The cross referencer follows initializations, runtime_entry/1, and externs.
').

:- use_module(library(charsio)).
:- use_module(messages(language('QU_messages'))).
:- use_module(xref).

runtime_entry(start) :- unix(argv(Args)), parse(Args, Files, Options),
    functor(Files, '.', 2), !, xref(Files, Options).
runtime_entry(start) :- usage, prolog_flag(system_type, runtime), halt(1).

parse([], [], []).
parse([H,A|R], F, L0) :- prs(H, A, L0, L),
    !, parse(R, F, L).
parse([H|T], F, L0) :- atom_chars(H, [0'-|V]),
    !, prsc(V, L0, L), parse(T, F, L).
parse([H|T], [F|R], L) :- fn(H, F), parse(T, R, L).

prs('-i', A,                    L, L) :- fn(A, IFile), compile(IFile).
prs('-m', A,       [mod(MFile)|L], L) :- fn(A, MFile).
prs('-w', A,  [warnings(WFile)|L], L) :- fn(A, WFile).
prs('-u', A, [undefined(UFile)|L], L) :- fn(A, UFile).
prs('-x', A,      [xref(XFile)|L], L) :- fn(A, XFile).

prsc([], L, L).
prsc([H|T], L0, L) :- prsc1(H, L0, L1), prsc(T, L1, L).

prsc1(0'c, [compiler_errors|L], L).
prsc1(0'v, [verbose|L], L).

fn(A, F) :- prolog_flag(syntax_errors, Old, quiet), name(A, C),
    (   chars_to_term(C, F), \+ functor(F, /, 2)
    ->  true
    ;   F = A
    ), prolog_flag(syntax_errors, _, Old).