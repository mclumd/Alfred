%   Package: structs_decl_msg
%   Author : Peter Schachte
%   Updated: 02/19/91
%   Purpose: English version of messages for structs declarations

%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

:- module(structs_decl_msg, []).

sccs_id('"@(#)91/02/19 str_decl_msg.pl    15.1"').

:- multifile
	'QU_messages':typename/3,
	'QU_messages':operation/3,
	'QU_messages':commandtype/3,
	'QU_messages':contexttype/3,
	'QU_messages':msg/3.


'QU_messages':(typename(foreign_type_name) -->
	['name for user-defined type'-[]]).
'QU_messages':(typename(foreign_type) -->
	['name of foreign type'-[]]).
'QU_messages':(typename(fixed_size_type) -->
	['fixed size type'-[]]).
'QU_messages':(typename(type_definition) -->
	['type definition'-[]]).
'QU_messages':(typename(foreign_arg_decl) -->
	['foreign argument declaration'-[]]).

'QU_messages':(operation(define) -->
	['define'-[]]).

'QU_messages':(commandtype(opaque_type_definition) -->
	['definition of opaque type'-[]]).

'QU_messages':(contexttype(before_use) -->
	['before use'-[]]).

'QU_messages':(msg(already_defined) -->
	['that type is already defined'-[]]).
