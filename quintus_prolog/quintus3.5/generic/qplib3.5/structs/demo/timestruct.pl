%   Package: timestruct
%   Author : Peter Schachte
%   Updated: 05/16/95
%   Purpose: demonstration of structs package usage

%   Copyright (C) 1991, Quintus Computer Systems, Inc.  All rights reserved.

:- module(timestruct, [
	localtime/9,
	gmtime/9
   ]).

% [PM] 3.5 renamed from str_decl to structs_decl
%  NOTE:  library(strucs_decl) needs to be loaded at compile-time
%	  in order to process structure and foreign declarations.
%	  It need not and will not be loaded at runtime.
:- load_files(library(structs_decl), [when(compile_time), if(changed)]).

%  NOTE:  We need this because this file uses structs predicates
%	  new/2, dispose/1, and get_contents/3.
:- ensure_loaded(library(structs)).

sccs_id('"@(#)95/05/16 timestruct.pl	21.1"').

:- foreign_type
	timestamp = integer,
	clock = pointer(timestamp),
% Structure declarations copied from <time.h>:
	tm = struct([
		tm_sec:		integer,
		tm_min:		integer,
		tm_hour:	integer,
		tm_mday:	integer,
		tm_mon:		integer,
		tm_year:	integer,
		tm_wday:	integer,
		tm_yday:	integer,
		tm_isdst:	integer
	]).

localtime(Year, Yearday, Month, Day, Weekday, Hour, Minute, Second, DST) :-
	new(timestamp, Stamp),		% No auto variables in Prolog
	time(Stamp, _),			% put current time into Stamp
	% or, I could have done:
	%   null_foreign_term(timestamp, Nullstamp),
	%   time(Nullstamp, Time),
	%   put_contents(Stamp, contents, Time),
	localtime(Stamp, Tm),
	dispose(Stamp),			% done with Stamp
	get_contents(Tm, tm_sec, Second),
	get_contents(Tm, tm_min, Minute),
	get_contents(Tm, tm_hour, Hour),
	get_contents(Tm, tm_mday, Day),
	get_contents(Tm, tm_mon, Month),
	get_contents(Tm, tm_year, Year),
	get_contents(Tm, tm_wday, Weekday),
	get_contents(Tm, tm_yday, Yearday),
	get_contents(Tm, tm_isdst, DST).

gmtime(Year, Yearday, Month, Day, Weekday, Hour, Minute, Second, DST) :-
	new(timestamp, Stamp),		% No auto variables in Prolog
	time(Stamp, _),			% put current time into Stamp
	% or, I could have done:
	%   null_foreign_term(timestamp, Nullstamp),
	%   time(Nullstamp, Time),
	%   put_contents(Stamp, contents, Time),
	gmtime(Stamp, Tm),
	dispose(Stamp),
	get_contents(Tm, tm_sec, Second),
	get_contents(Tm, tm_min, Minute),
	get_contents(Tm, tm_hour, Hour),
	get_contents(Tm, tm_mday, Day),
	get_contents(Tm, tm_mon, Month),
	get_contents(Tm, tm_year, Year),
	get_contents(Tm, tm_wday, Weekday),
	get_contents(Tm, tm_yday, Yearday),
	get_contents(Tm, tm_isdst, DST).


%  These examples mix uses to show alternative declarations.
%  +clock is defined as +pointer(timestamp), which means we will be passing
%  a pointer to a timestamp.  It returns a pointer to a tm structure.
foreign(localtime, c, localtime(+clock, [-pointer(tm)])).
foreign(gmtime, c, gmtime(+clock, [-pointer(tm)])).

foreign(time, c, time(+clock, [-integer])).

foreign_file(library(system('unneeded.o')), [localtime, gmtime, time]).

:- load_foreign_files(library(system('unneeded.o')), ['-lc']).
