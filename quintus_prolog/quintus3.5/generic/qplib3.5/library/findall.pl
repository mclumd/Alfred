%   Package: findall
%   Author : Richard A. O'Keefe
%   Updated: 13 Nov 1989
%   Defines: the 'findall' routines for finding all solutions

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(findall, [
	% findall/3,		%   Same effect as C&M p152
	findall/4		%   A variant I have found very useful
   ]).
:- meta_predicate
	% findall(+, 0, ?),
	findall(+, 0, +, ?).
:- use_module(library(sofstk), [
	save_instances/2,
	list_instances/1,
	list_instances/2
   ]).

sccs_id('"@(#)89/11/13 findall.pl	36.1"').


/*
%   findall(+Template, +Generator, ?List)
%   is a special case of bagof, where all free variables in the
%   generator are taken to be existentially quantified.  Do not
%   use the version described in Clocksin & Mellish on p152 as
%   that version is buggy.

findall(Template, Generator, List) :-
	save_instances(Template, Generator),
	list_instances(List).
*/



%   findall(+Template, +Generator, ?SoFar, ?List)
%   has the same effect as
%	findall(Template, Generator, Solns),
%	append(Solns, SoFar, List).
%   but doesn't construct the intermediate list Solns.

findall(Template, Generator, SoFar, List) :-
	save_instances(Template, Generator),
	list_instances(SoFar, List).



