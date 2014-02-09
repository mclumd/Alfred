%   Module : 01/24/94 @(#)tcp_msg.pl	71.1
%   Author : Tom Howland
%   Purpose: messages for library(tcp)
%   Copyright (C) 1991, Quintus Computer Systems, Inc.  All rights reserved.

:- module(tcp_msg,[]).

%% [PM] 3.5+ If we do use_module here then qpc -cH tcp_msg.pl will
%% modify (hide/compile/?) QU_messages.qof which will make
%% QU_messages.qof newer than the timestamps embedded in the already
%% built executables. This will make the already built executables
%% re-load QU_messages.qof and thus also QU_message.o/.obj when
%% tcp_msg.qof is loaded. A showstopper, especially on Windows where
%% the distributed executables are not rebuilt during installation.
%%
%% Note that other ..._msg.pl files (e.g., proxl_msg.pl) never did
%% use_module on QU_messages.
%%
%% I do not know why qpc -cH tcp_msg.pl wants to modify QU_messages.qof.
%%
%% :- use_module(messages(language('QU_messages'))).

:- multifile
	'QU_messages':msg/3,
	'QU_messages':operation/3,
	'QU_messages':generate_message/3,
	'QU_messages':typename/3.

sccs_id('"@(#)94/01/24 tcp_msg.pl	71.1"').

'QU_messages':(operation(tcp_connect) --> ['connect using'-[]]).

'QU_messages':(generate_message(tcp_eof_when_looking_for_name) -->
    ['TCP:  end_of_file reached when looking for the name of the connecting process'-[],nl]).

'QU_messages':(generate_message(tcp_mishap(Msg, Num)) -->
    ['~a, ' - [Msg]], message(errno(Num))).

'QU_messages':(typename(tcp_socket) --> ['socket'-[]]).
'QU_messages':(typename(tcp_passive_socket) --> ['passive socket'-[]]).
'QU_messages':(typename(tcp_timeval) --> ['A time value'-[]]).

'QU_messages':(msg(tcp_connection_already_exists(Conn_id)) -->
    ['you already have a connection labeled ~q'-[Conn_id]]).
