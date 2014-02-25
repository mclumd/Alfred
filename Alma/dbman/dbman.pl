/*
File: dbman/dbman.pl
By: kpurang
What: this loads the files in this directory
      the files are to do with database manipulation

Todo: use makefiles.

*/

%:- ensure_loaded(library(sets)).
%:- ensure_loaded(library(subsumes)).
:- compile([access, makenodes, history, index, delete, cleaning, assumptions,
	    misc]).






