%   Module : subsumes
%   Author : Richard A. O'Keefe
%   Updated: 26 Dec 1989
%   Purpose: term subsumption

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(subsumes, [
	% subsumes_chk/2, (now a built-in predicate)
	subsumes/2,
	variant/2
   ]).

sccs_id('"@(#)89/12/26 subsumes.pl	36.1"').


%   subsumes_chk(General, Specific)
%   is true when Specific is an instance of General.  However, it
%   does not bind any variables in General or Specific.
%
%   subsumes_chk/2 is provided as a built-in predicate, beginning with 
%   Release 2.5 of Quintus Prolog.  It still behaves as if it were 
%   defined by the original library code below, except that low-level
%   support has been used to make it considerably faster.
%
% subsumes_chk(General, Specific) :-
% 	\+  (	numbervars(Specific, 0, _),
% 		\+ General = Specific
% 	    ).



%   subsumes(General, Specific)
%   is true when Specific is an instance of General.  It will bind
%   variables in General (but not those in Specific) so that General
%   becomes identical to Specific.


subsumes(General, Specific) :-
	subsumes_chk(General, Specific),
	General = Specific.



%   variant(A, B)
%   is true when A and B are alphabetic variants.  The definition here
%   is not quite right; if A and B share any variables it may give the
%   wrong answer.  It is only meant to be used when the two have no
%   variables in common.  If this is not adequate for your programming
%   needs we could supply a version which works with overlapping vars.

variant(A, B) :-
	subsumes_chk(A, B),
	subsumes_chk(B, A).


