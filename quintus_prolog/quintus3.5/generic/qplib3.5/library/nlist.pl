%   Package: nlist
%   Author : Richard A. O'Keefe
%   Updated: 30 Sep 1992
%   Purpose: Interface to the Unix library function nlist(3)

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(nlist, [
	nlist/3
   ]).

sccs_id('"@(#)92/09/30 nlist.pl	66.1"').


nlist(FileName, Names, Descriptions) :-
	atom(FileName),
	check_nlist(Names, Descriptions),
	normalise(Descriptions, Normalised, N),
	allocate_name_list_vector(N, NList),
	NList =\= 0,
	fill_in_names(Normalised, NList, 0),
	nlist_(FileName, NList, Status),
	(   Status >= 0,
	    gather_descriptions(Normalised, NList, 0),
	    Flag = 0
	;   Flag = 1
	),
	free_name_list_vector(NList),
	Flag =:= 0.

check_nlist([], []).
check_nlist([Name|Names], [nlist(Name,_,_,_)|Descriptions]) :-
	atom(Name),
	check_nlist(Names, Descriptions).

%   Because some implementations of the Unix library functino nlist(3)
%   do not work correctly when the same name appears more than once,
%   we have to prevent that.  What we do is sort the list of
%   descriptions, and then fuse entries for the same name.

normalise(Descriptions, Normalised, N) :-
	sort(Descriptions, Sorted),
	normalise(Sorted, Normalised),
	length(Normalised, N).


normalise([], []).
normalise([nlist(Name,A,B,C),nlist(Name,D,E,F)|Descs], Normalised) :- !,
	A = D, B = E, C = F,
	normalise([nlist(Name,D,E,F)|Descs], Normalised).
normalise([Desc|Descs], [Desc|Normalised]) :-
	normalise(Descs, Normalised).


fill_in_names([], _, _).
fill_in_names([nlist(Name,_,_,_)|Descs], NList, N0) :-
	set_name_list_name(N0, NList, Name),
	N1 is N0+1,
	fill_in_names(Descs, NList, N1).

gather_descriptions([], _, _).
gather_descriptions([nlist(_,Type,Where,Value)|Descriptions],
		    NList, N0) :-
	get_name_list_type_and_value(N0, NList, T, Value),
	nlist_place_and_type(T, Where, Type),
	N1 is N0+1,
	gather_descriptions(Descriptions, NList, N1).

nlist_place_and_type(16'00, internal, undefined).
nlist_place_and_type(16'01, external, undefined).
nlist_place_and_type(16'02, internal, absolute).
nlist_place_and_type(16'03, external, absolute).
nlist_place_and_type(16'04, internal, text).
nlist_place_and_type(16'05, external, text).
nlist_place_and_type(16'06, internal, data).
nlist_place_and_type(16'07, external, data).
nlist_place_and_type(16'08, internal, bss).
nlist_place_and_type(16'09, external, bss).
nlist_place_and_type(16'12, internal, common).
nlist_place_and_type(16'13, external, common).
nlist_place_and_type(16'1f, external, file).


foreign_file(library(system(libpl)),
    [
	allocate_name_list_vector,
	set_name_list_name,
	get_name_list_type_and_value,
	free_name_list_vector,
	nlist
    ]).
foreign(allocate_name_list_vector,
	allocate_name_list_vector(+integer,[-address('struct nlist')])).
foreign(set_name_list_name,
	set_name_list_name(+integer,+address('struct nlist'),+string)).
foreign(get_name_list_type_and_value,
	get_name_list_type_and_value(+integer,
		+address('struct nlist'),[-integer],-integer)).
foreign(free_name_list_vector,
	free_name_list_vector(+address('struct nlist'))).
foreign(nlist,
	nlist_(+string,+address('struct nlist'),[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).
