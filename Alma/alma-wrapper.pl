% alma-wrapper.pl -- M. Covington 2010

% For starting Alma using Quintus interactively instead of compiled.

:- write('Compiling Alma...'), nl.
:- compile('toplevel.pl').
:- runtime_entry(start).

