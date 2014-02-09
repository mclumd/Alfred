%   Package: statistics
%   Author : Richard A. O'Keefe
%   Updated: 30 Sep 1992
%   Defines: full_statistics/[0,2]

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(statistics, [
	full_statistics/2,
	full_statistics/0
   ]).

sccs_id('"@(#)92/09/30 statistics.pl	66.1"').

/*  The full_statistics/[0,2] predicates are exactly like the built-in
    statistics/[0,2] predicates except that
    (1) Integers are written out with commas every three digits, and
    (2) The number of page faults is reported (if known).
*/

full_statistics(runtime, X) :-			% [Total,Increment]
        statistics(runtime, X).
full_statistics(memory, X) :-			% [Size,0]
        statistics(memory, X).
full_statistics(program, X) :-			% [Size,Free]
        statistics(program, X).
full_statistics(global_stack, X) :-		% [Size,Free]
        statistics(global_stack, X).
full_statistics(local_stack, X) :-		% [Size,Free]
        statistics(local_stack, X).
full_statistics(trail, X) :-			% [Size,Free{=0}]
        statistics(trail, X).
full_statistics(garbage_collection, X) :-	% [Count,Freed,Time]
        statistics(garbage_collection, X).
full_statistics(stack_shifts, X) :-		% [Global,Local,Time]
        statistics(stack_shifts, X).
full_statistics(core, X) :-			% [Size,0]	= memory
        statistics(core, X).
full_statistics(heap, X) :-			% [Size,Free]	= program
        statistics(heap, X).
full_statistics(page_faults, [Total,Incr]) :-	% [Total,Increment]
        'QPageN'(Total, Incr, /*Errno*/ 0).

full_statistics :-
	statistics(memory, [Mtotal,_]),
	statistics(program, [Pused,Pfree]),
	Ptotal is Pused+Pfree,
	statistics(global_stack, [Gused,Gfree]),
	statistics(trail, [Tused|_]),
	Gtotal is Gused+Gfree+Tused,
	Gused2 is Gused+Tused,
	statistics(local_stack, [Lused,Lfree]),
	Ltotal is Lused+Lfree,
	statistics(stack_shifts, [Pshifts,Lshifts,Tshift]),
	Gshifts is Lshifts-Pshifts,
	statistics(garbage_collection, [GCs,GCspace,GCtime]),
	statistics(runtime, [Time|_]),
	format('~Nmemory (total) ~t~D bytes.~35+~n', [Mtotal]),
	format('   program space ~t~D bytes: ~36|~t~D in use, ~18+~t~D free.~15+~n',
		[Ptotal,Pused,Pfree]),
	format( '   global space ~t~D bytes: ~36+~t~D in use, ~18+~t~D free.~15+~n',
		[Gtotal,Gused2,Gfree]),
	format('      global stack ~t~D bytes.~52|~n', [Gused]),
	format('      trail        ~t~D bytes.~52|~n', [Tused]),
	format('   local stack ~t~D bytes: ~36+~t~D in use, ~18+~t~D free.~15+~n~n',
		[Ltotal,Lused,Lfree]),
	format(' ~3D sec. for ~D program, ~D global and ~w local space overflows.~n',
		[Tshift,Pshifts,Gshifts,?]),
	format(' ~3D sec. for ~D garbage collections which collected ~D bytes.~n',
		[GCtime,GCs,GCspace]),
	'QPageN'(Faults, _, Errno),
	(   Errno =:= 0 ->
	    format(' ~3D sec. runtime, ~D pagefaults.~n', [Time,Faults])
	;   format(' ~3D sec. runtime.~n', [Time])
	),
	fail.
full_statistics.


foreign_file(library(system(libpl)), [
	'QPageN'
]).
foreign('QPageN', 'QPageN'(-integer,-integer,[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish([foreign_file/2,foreign/2]).


