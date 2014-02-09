%   File   : sockutil.pl
%   Author : David S. Warren
%   Updated: 11/01/88
%   SCCS:    @(#)88/11/01 sockutil.pl	27.1
%   Purpose: IPC tracing.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  These routines support a primitive tracing facility, so you can see
    what is being sent and received through the sockets.  Notice that
    tracing is done only by the process that turns tracing on.  To have
    the remote process trace (into the servant's output file)
    call_servant(msg_trace(_,on)) must be called.
*/

/*  $msg_trace(1)  if IPC calls should be traced
    $msg_trace(0) if IPC calls should not be traced
*/
:- dynamic
	'$msg_trace'/1.

'$msg_trace'(0).		% Start out not tracing.

/*  msg_trace(-Old_value, +On_or_Off)
    turns IPC tracing on and off
*/
msg_trace(Old, New) :-
	'$msg_trace'(O),
	(   O =:= 0 -> Old = off
	;   O =:= 1 -> Old = on
	),
	(   New == on  -> set_msg_trace(1)
	;   New == off -> set_msg_trace(0)
	;   write_sock_error(['Illegal argument to msg_trace:',New])
	).

set_msg_trace(New) :-
	retractall('$msg_trace'(_)),
	assert('$msg_trace'(New)).


/*  msg_trace1(Items)
    prints a message if tracing is on.
    It was not clear where this message was supposed to go, so I have
    made it go to user_output.
*/
msg_trace1(Items) :- 
	'$msg_trace'(N),
	(   N =:= 0 -> true
	;   write_list(user_output, 'IPC (trace):', Items, '')
	).


/*----------------------------------------------------------------------+
|									|
|		Socket Error Routines					|
|									|
+----------------------------------------------------------------------*/


/*  write_sock_error(+Items)
    writes the error message Items to the error stream.
*/
write_sock_error(Items) :-
	write_list(user_error, '[IPC ERROR:', Items, '.]').


/*  write_sock_msg(+Items)
    writes the IPC message to the current output stream.
    Should this not be 'user_output' instead?
*/
write_sock_msg(Items) :-
	current_output(S),
	write_list(S, '[IPC:', Items, '.]').


%   write_list(+Stream, +Prefix, +Items, +Suffix)
%   is a generic routine for writing various messages to a stream.
%   We really should be using format/3 instead.

write_list(Stream, Prefix, List, Suffix) :-
	current_output(OldOutput),
	set_output(Stream),
	    write(Prefix),
	    write_list(List),
	    write(Suffix),
	    nl,
	set_output(OldOutput),
	flush_output(Stream).
	
write_list([]) :- !.
write_list([Item|Items]) :- !,
	put(" "), write(Item),
	write_list(Items).
write_list(Item) :-
	write(Item).


