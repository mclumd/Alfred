%   Package: put_file
%   Author : Richard A. O'Keefe
%   Updated: 30 Sep 1992
%   Purpose: Copy the contents of a file to the current output stream

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(put_file, [
	put_file/1
   ]).

sccs_id('"@(#)92/09/30 putfile.pl	66.1"').

foreign_file(library(system(libpl)), ['QP_putfile']).
foreign('QP_putfile', put_file(+string)).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

