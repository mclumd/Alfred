#!/bin/sh
prolog <<EOF
%   What   : @(#)makelinks.sh	28.2 10/04/94
%   Author : Richard A. O'Keefe
%   Purpose: shell+Prolog script to get files from IPC library.

:- ensure_loaded(library(basics)).
:- [user].

concat_atom(Constants, Atom) :-
	concat_chars(Constants, Chars),
	atom_chars(Atom, Chars).

concat_chars([], []).
concat_chars([Constant|Constants], Chars) :-
	name(Constant, C),
	append(C, Chars1, Chars),
	concat_chars(Constants, Chars1).

link_command('ln -s').
	/*   'ln -s'	for symbolic links */
	/*   ln		for hard links */


make_link_to(Src,Dest) :-
	absolute_file_name(library(Src), Source),
	absolute_file_name(Dest, Destination),
	link_command(Link),
	concat_atom([Link,' ',Source,' ',Destination], Command),
	unix(system(Command)).

end_of_file.
:- make_link_to('ccallqp.h','ccallqp.h'),
   make_link_to(system('ccallqp.o'),'ccallqp.o'),
   halt.

EOF
