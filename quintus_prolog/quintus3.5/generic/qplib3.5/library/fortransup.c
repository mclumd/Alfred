/*
   SCCS   : @(#)fortransup.c	67.2 7/28/93
   Authors: Anil
   Updated: Jul 28, 1993
   Purpose: Stub functions so that you can call the QP_ functions from fortran

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
   QP_atom * atom;
   char *str;
   int * len;
   {
   	return QP_padded_string_from_atom(atom, str, &len);
   }

*/

#include "quintus.h"

long int qp_atom_from_padded_string_(atom, string, len)
    QP_atom * atom;
    char * string;
    int  * len;
    {
	return QP_atom_from_padded_string(atom, string, len);
    }

long int qp_padded_string_from_atom_(atom, string, len)
    QP_atom * atom;
    char * string;
    int  * len;
    {
	return QP_padded_string_from_atom(atom, string, len);
    }


void Qfortransupdummy() {}
