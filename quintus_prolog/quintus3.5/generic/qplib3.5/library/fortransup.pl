%   SCCS   : @(#)fortransup.pl	67.2 28 Jul 1993
%   Module : fortransup
%   Authors: Anil
%   Updated: Jul 28, 1993
%   Purpose: Stub functions so that you can call the QP_ functions from fortran


/*
  Fortran compilers traditionally lowercase all identifiers
  and appends an _ to the names of all functions.
  
  e.g. if users call QP_atom_from_padded_string() from their Fortran
  code, it gets translated to a call to qp_atom_from_padded_string_().

  When the Fortran .o file gets loaded into Prolog you are not going to
  find the symbol qp_atom_from_padded_string_ and you get an error.

  This library works around this problem. If you have to call any of
  the QP_ functions from Fortran make sure that you load this
  library (with :- use_module(library(fortransup)). ) before you
  load the fortran .o file.

  Basically, this module just ensures that you load a .o file which
  has stub definitions of the form:

  int qp_padded_string_from_atom_(atom, str, len)
  int *atom, len;
  char *str;
  {
  	return QP_padded_string_from_atom(atom, str, &len);
  }

*/

:- module(fortransup, []). % There is nothing to export

% We just want to make sure that fortransup.o is loaded.
% But we have to have atleast 1 foreign_file/2 and foreign/3 fact
% So we define a dummy function.
foreign_file(library(system(libpl)), ['Qfortransupdummy']).
foreign('Qfortransupdummy', c, 'Qfortransupdummy').

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).
