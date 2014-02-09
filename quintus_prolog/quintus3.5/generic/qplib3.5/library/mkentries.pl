% -*- Mode: Prolog -*-

%  File   : mkentries.pl
%  Author : Jim Crammond
%  SCCS   : @(#)95/05/12 mkentries.pl 75.2
%  Purpose: to build a linkage table and lookup function from foriegn decls
%	    for rs6000 "executables"
%
%  To create link file invoke as follows:  cat <plfiles> | mkentries > <cfile> 
%  To create exports file invoke as follows:
%       cat <plfiles> | mkentries <expheaderfile> > expfile
%  read prolog source, extracting function names from foreign/3 facts and
%  generate a C program with a linkage table and function to retrieve the
%  function descriptors.
%
runtime_entry(start) :-
	read(X),
	read_functions(X, Fns),
	unix(argv(ArgList)),
	switch(ArgList, Fns),
	halt.

switch([], Fns) :- !,
	print_link_table(Fns, 'QP_table').
switch(['-nt',DLLFile|_], Fns) :- !,
	gen_defs_file(Fns, DLLFile).
switch([ExpFile|_], Fns) :-
	gen_exports_file(Fns, ExpFile).

read_functions(end_of_file, []) :- !.
read_functions(foreign(F,_,_), [F|L]) :- !,	% foreign/3
	read(X1),
	read_functions(X1, L).
read_functions(foreign(F,_), [F|L]) :- !,	% foreign/2
	read(X1),
	read_functions(X1, L).
read_functions(_, L) :- !,
	read(X1),
	read_functions(X1, L).

print_link_table(Entries, Link) :-
	format('/* Prolog -> C linkage table (generated) */~2n', []),
	format('#include <string.h> /* strcmp() */~2n', []), % [PM] 3.5

	print_entries(Entries, 'extern int ~w();~n'),
	format('~n', []),
	format('static char *~w_s[] = {~n', [Link]),
	print_entries(Entries, '        "~w",~n'),
	format('        0 };~2n', []),
	format('~nstatic int (*(~w_f[]))() = {~n', [Link]),
	print_entries(Entries, '        ~w,~n'),
	format('        0 };~2n', []),
	format('/* entry function - returns addresses of functions */~n', []),
	format('QP_entry(sym)~nchar *sym;~n{~n  register int i;~2n', []),
	format('  for (i=0; ~w_s[i]; i++)~n', [Link]),
	format('    if (strcmp(sym, ~w_s[i]) == 0)~n', [Link]),
	format('      return (int) ~w_f[i];~n  return 0;~n}~n', [Link]).

print_entries([], _) :- !.
print_entries([Symbol|Rest], Format) :-
	format(Format, [Symbol]),
	print_entries(Rest, Format).

gen_defs_file(Entries, DLLFile) :-
        format('LIBRARY ~a~n~nEXPORTS~n~n',[DLLFile]),
        print_exports_list(Entries).

gen_exports_file(Entries, ExpFile) :-
        format('#! ~a~n',[ExpFile]),    % Write the #! file name header
        print_exports_list(Entries).

print_exports_list([]) :- !.
print_exports_list([Entry|Entries]) :-
        format('~a~n', [Entry]),
        print_exports_list(Entries).
