%  SCCS   : @(#)color.pl	1.3 10/16/93
%  File   : color.pl
%  Author : Georges Saab
%  Purpose: foreign interface to color functions
%  Origin : 20 Apr 1993
%

:- module(color, [get_color/5]).

:- load_files(library(structs_decl), [when(compile_time),if(changed)]).

:- foreign_type
	widget        =  opaque.

foreign(get_color, c, get_color(+pointer(widget), +integer, +integer, 
	                         +integer, [-integer])).

foreign_file(system('color.o'), [get_color]).

:- load_foreign_files([system('color.o')], ['-lXm','-lXt','-lX11']),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

