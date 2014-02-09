%   Package: structs_msg
%   Author : Peter Schachte
%   Updated: 12/19/90
%   Purpose: English version of messages for structs package

%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

:- module(structs_msg, []).

sccs_id('"@(#)90/12/19 str_msg.pl    1.1"').

:- multifile
	'QU_messages':typename/3.

'QU_messages':(typename(part_of_foreign_object) -->
	['part of foreign object'-[]]).
'QU_messages':(typename(fixed_size_type) -->
	['fixed-size type'-[]]).
'QU_messages':(typename(foreign_object) -->
	['foreign object'-[]]).
'QU_messages':(typename(foreign_type) -->
	['foreign type'-[]]).
