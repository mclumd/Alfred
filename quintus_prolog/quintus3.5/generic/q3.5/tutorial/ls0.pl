/*
  SCCS: @(#)ls0.pl	70.1 01/26/94
  File: ls0.pl

    This is only an approximate solution, but it is concise!
*/

:- use_module(library(strings)).

ls0_print(Arg) :-
	concat_atom(['/usr/5bin/ls -n ', Arg], Command),
	unix(system(Command)).



