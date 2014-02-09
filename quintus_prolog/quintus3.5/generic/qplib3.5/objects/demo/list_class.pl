%  SCCS   : @(#)list_class.pl	19.2 01/21/94
%  File   : list_class.pl
%  Author : Georges Saab
%  Purpose: Class definitions for Prolog Lists
%  Origin : 8 Apr 1993
%
%			Abstract
%
%  This example encapsulates the Prolog list in a class and provides some
%  basic list operations as methods.  

:- module(list_class, []).

/**
			Includes

Include the standard objects files and library(lists) for standard List
operations which we will use in our method definitions.
**/

:- load_files(library(obj_decl), [when(compile_time), if(changed)]).
:- use_module(library(objects)).
:- use_module(library(lists), [
        delete/3,
	is_list/1
   ]).

/**
			List Class

Declare the class \verb+list+, which will have one slot,
\verb+list+ which stores our Prolog list.
**/

:- class list = [list:term].

%  create(-List)
%  In order to create an instance of list, check that we have indeed
%  been passed a list, and store the list in the 'list' slot.

Self <- create(List) :-
	is_list(List),
	store_slot(list, List).

%  prepend(+Element)
%  In order to prepend Element to the list, get the list List 
%  currently stored in the 'list' slot, and store the list 
%  [Element|List] back in the 'list' slot.

Self <- prepend(Element) :-
	fetch_slot(list, List),
	store_slot(list, [Element|List]).

%  member(*Element)
%  We can also write non-deterministic methods.  '<-member/1' will return
%  successive elements of our list instance non-deterministically.

Self <- member(Element) :-
	fetch_slot(list, List),
	member(Element, List).

%  append(+Element)
%  Using object-oriented encapsulation is not without some drawbacks.  Method 
%  definitions naturally tend to expect to be called uni-directionally, 
%  and can make definitions of multi-directional Prolog operations awkward.
%  This definition of the list class assumes that oprations are being preformed
%  on a known list.  So making a method for a bidirectional predicate like 
%  'append/3' is somewhat difficult.  This version is callable only to 
%  add Element to the list, not to remove it from the list.

Self <- append(Element) :-
	fetch_slot(list, List),
	append(List, Element, NewList),
	store_slot(list, NewList).

/**
Trying these in Prolog:
++verbatim

| ?- use_module(library(objects)),
     create(list([1,2,3]), L),
     L <- prepend(0),
     L <- append([4,5]),
     L >> list(List).

L = list(1395228),
List = [0,1,2,3,4,5]

--verbatim
**/
