%%% Copyright (c) 2003, 2004 SICS AB. All rights reserved.
%%% -----------------------------------------------------------------
%%%
%%% PROLOGBEANSSERVER
%%% an implementation of a simple Internet server listening to one
%%% or several ports. Currently used for the PrologBeans module/library
%%%
%%% Author  : Joakim Eriksson, Niclas Finne
%%% Created : 03-5-20
%%% Updated : $Date: 2004/01/13 14:02:18 $
%%%	      $Revision: 1.2 $
%%%

:- module(prologbeansserver, [
	init/0,
	new_thread/1,
	run/0,
	open_socket/2,
	stop/0,
	new_stream/2,
	has_open_connections/0,
	prologsystem/1,
	pb_input_stream/2,
	pb_output_stream/2
	]).

%%% [PD] Quintus 3.5/SICStus 3.11.1
%%%      Keep the source code synchronized between SICStus and Quintus.
%%%      The pseudo operators 'if' and 'endif' are an aid for keeping track
%%%      of the necessary differences in the two versions.

%%% if SICSTUS
/*
:- use_module(library(sockets),[
        socket/2,
        socket_bind/2,
        socket_listen/2,
        socket_close/1,
        socket_select/5
        ]).
*/
%%% endif SICSTUS
%%% if QUINTUS
%/*
:- use_module(library(tcp),[
        tcp_create_listener/2,
        tcp_destroy_listener/1,
	tcp_shutdown/1,
	tcp_select_from/1,
	tcp_select_from/2,
	tcp_input_stream/2,
	tcp_output_stream/2,
	tcp_get_socket_address/2,
	tcp_connected/2
        ]).
%*/
%%% endif QUINTUS

:- dynamic is_running/0.	% is_running
:- dynamic current_timeout/1.	% current_timeout(<seconds>:<microseconds>)
:- dynamic socket/3.		% socket(<socket>,<handler>,<port>)
:- dynamic stream/3.		% stream(<stream>,<socket>,<handler>)
:- dynamic thread/1.		% thread(<handler>)
:- dynamic prologsystem/1.	% prologsystem(<system-name>) [PD]

%% [PD] Hack to test for which prolog we are running.
prolog_system(P) :-
/*   (prolog_flag(source_info,_) -> P = sicstus; P = quintus). */
   (prolog_flag(quintus_directory,_) -> P = quintus; P = sicstus).

%% [PD] Quintus does not have bidirectional streams. Combine the output stream
%%      and the input stream into an opaque entity. Do this for both SICStus
%%      and Quintus and use the predicates below to extract the necessary
%%      stream.
%%      Within this module care has to be taken whenever handling streams.
%%      Sometimes it is an opaque stream entity and sometimes a real stream.
pb_input_stream(Stream, InputStream) :-	  % [PD]
    pb_opaque_stream(InputStream, _, Stream). % [PD]
pb_output_stream(Stream, OutputStream) :- % [PD]
    pb_opaque_stream(_, OutputStream, Stream). % [PD]
pb_opaque_stream(InputStream,OutputStream,Stream) :- % [PD]
    Stream = '$pbstream'(InputStream,OutputStream). % [PD]


open_socket(P, H) :-
    prologsystem(Psys),			    % [PD]
    open_socket(P, Psys, SocketAndOptions), % [PD]
    assert(socket(SocketAndOptions,H,P)).

open_socket(P, sicstus, SocketAndOptions) :- % [PD]
    socket('AF_INET', S),
    socket_bind(S, 'AF_INET'(_A,P)),
    socket_listen(S, 5),
    SocketAndOptions = (S-[type(binary)]). % [PM] 3.10.2

open_socket(P, quintus, SocketAndOptions) :-   % [PD]
    tcp_create_listener(address(P, _Host), S), % [PD]
    %% *** do we have to specify something like type(binary) here, or are
    %% Quintus streams binary by default?
    %% Hm, it appears that socket streams are binary. *** VERIFY THIS!
    SocketAndOptions = (S-[]).		       % [PD]

current_sockets(HSs) :-
    findall(H-S, socket(S,H,_), HSs).


%% [PM] 3.10.2 support new functionality in library(sockets).
socket_options(SocketAndOptions, Socket, Options) :-
   SocketAndOptions = Socket0-Options0, !,
   Socket = Socket0,
   Options = Options0.
socket_options(Socket0, Socket, Options) :-
   Socket = Socket0,
   Options = [].


socket_closer(sicstus, S, SC) :-	     % [PD]
    SC = socket_close(S).		     % [PD]

socket_closer(quintus, S, SC) :-	     % [PD]
    SC = tcp_destroy_listener(S).	     % [PD]

close_socket(H-SocketAndOptionalOptions) :-
    socket_options(SocketAndOptionalOptions, S, _Options),
    prologsystem(Psys),			     % [PD]
    socket_closer(Psys, S, SC),		     % [PD]
    on_exception(Error,
		 SC,
		 print_message(error, prologbeans(close_socket_h(H,Error)))),
    retractall(socket(S,_,_)).

close_sockets :-
    current_sockets(HSs),
    close_sockets(HSs).

close_sockets([]).
close_sockets([HS|HSs]) :-
    close_socket(HS),
    close_sockets(HSs).

set_timeout(off) :- !,
    retractall(current_timeout(_)),
    assert(current_timeout(off)).
set_timeout(T) :-
    retractall(current_timeout(_)),
    assert(current_timeout(T)).

init :-
    set_timeout(10:0),
    prolog_system(Psys),
    assert(prologsystem(Psys)).

stop :-
    retractall(is_running).

run :-
    %% Make sure the server has been initialized
    current_timeout(_), !,
    assert(is_running),
    loop.
run :-
    throw(system_error('server not initialized')).

loop :-
    is_running,!,
    listen_robust,
    loop.
loop :-
    close_sockets,
    close_streams.

listen_robust :-
    on_exception(E,listen,listen_error(E)), !.
listen_robust :-
    print_message(warning, prologbeans(listen)).

listen :-
    prologsystem(Psys),			% [PD]
    listen(Psys).			% [PD]

listen(sicstus) :-			% [PD]
    current_timeout(To),
    current_sockets(HSs),
    current_input_streams(Ss),		% [PD]
    socket_select(HSs, Cs, To, Ss, RSs),
    s_handle_connections(Cs),
    s_handle_inputs(RSs),
    get_threads(Threads),
    handle_threads(Threads).

listen(quintus) :-			% [PD]
    current_timeout(To),		% [PD]
    q_select_from(To, R),		% [PD]
    q_handle_select(R),			% [PD]
    get_threads(Threads),		% [PD]
    handle_threads(Threads).		% [PD]

q_select_from(off, R) :-		% [PD]
    tcp_select_from(R).			% [PD]
q_select_from(Timeout, R) :-		% [PD]
    Seconds:Microseconds = Timeout,	% [PD]
    Qtimeout is Seconds + Microseconds / 1000, % [PD]
    tcp_select_from(Qtimeout, R).	% [PD]

q_handle_select(from(Socket)) :-	% [PD]
    tcp_input_stream(Socket, IStream),	% [PD]
    tcp_output_stream(Socket, OStream),	% [PD]
    pb_opaque_stream(IStream,OStream,Stream), % [PD]
    handle_input(Stream).		% [PD]
q_handle_select(connected(Socket)) :-	% [PD]
    socket_owner(Socket),		% [PD]
    tcp_get_socket_address(Socket, address(_, Host)), % [PD]
    tcp_input_stream(Socket, IStream),	% [PD]
    tcp_output_stream(Socket, OStream),	% [PD]
    tcp_connected(Socket,Passive),
    socket(Passive-_,H,_),	        % [PD]
    pb_opaque_stream(IStream,OStream,Stream), % [PD]
    handle_connection(H-connection(Host,Stream)). % [PD]
    
q_handle_select(wakeup(_)).	% [PD] there should be no scheduled wakeups
q_handle_select(user_input).		% [PD] ignore user input
q_handle_select(timeout).		% [PD] ignore timeout
    
%% [PD] Quintus 3.5 Check if this socket belongs to us.
socket_owner(Socket) :-
    tcp_connected(Socket,Passive),
    socket(Passive-_Options,_Handler,_Port).

s_handle_connections([]).
s_handle_connections([H-connection(A,S)|Cs]) :-
    pb_opaque_stream(S,S,Stream),  % [PD]
    handle_connection(H-connection(A,Stream)), % [PD]
    s_handle_connections(Cs).

handle_connection(H-connection(A,S)) :-	% [PD]
    call_handler_robust(H, connection(A, S)),
    maybe_close_new_connection(S).

% Closes the new connection if the handler did not add it as a new stream
maybe_close_new_connection(S) :-
    stream(S,_,_), !.
maybe_close_new_connection(S) :-
    on_exception(Error,
		 close_stream(S),
		 print_message(error, prologbeans(close_stream(S,Error)))).

has_open_connections :-
    stream(_,_,_).

new_stream(S,H) :-
    assert(stream(S,nil,H)).

stream_handler(S,H) :-
    stream(S,_,H).

current_streams(Ss) :-
    findall(S, stream(S,_,_), Ss).

current_input_streams(Ss) :-
    findall(IS, ( stream(S,_,_), pb_input_stream(S,IS) ), Ss).

maybe_close_stream(S) :-
    stream(S,_,H),!,
    call_handler_robust(H, connection_closed(S)),
    close_stream(S).
maybe_close_stream(_).

close_stream(S) :-
    nonvar(S),
%    maybe_close_connection(S),	% [PD] Quintus 3.5 Bogus, see (commented out)
				%      maybe_close_connection/1.
    prologsystem(P),
    pb_input_stream(S,IS),
    stream_closer(P,IS,SC),
    on_exception(Error,
		 SC,
		 print_message(error, prologbeans(close_stream(IS,Error)))),
    retractall(stream(S,_,_)).

stream_closer(quintus,IS,SC) :-
    tcp_input_stream(Socket,IS), !,
    SC = tcp_shutdown(Socket).

stream_closer(sicstus,IS,SC) :-
    SC = close(IS).    

% [PD] Quintus 3.5 This is all bogus 
% maybe_close_connection(S) :-
% %    stream(S,Socket0,_), !,
%     stream(S,Socket,_), !,
% %     ( prologsystem(quintus) ->
% % 	%% [PD] Quintus 3.5 Currently Socket0 is always nil. We need the socket
% % 	%%      to be able to call tcp_shutdown/1, since we can't close a
% % 	%%      socket stream with close/1.
% %         pb_input_stream(S, IS),
% % 	tcp_input_stream(ActiveSocket, IS),
% % 	tcp_connected(ActiveSocket,Socket)
% %     ; otherwise ->
% %         Socket = Socket0
% %     ),
%     maybe_close_connection(Socket, S).
% maybe_close_connection(_).
%
% maybe_close_connection(nil, _) :- !.
% maybe_close_connection(Socket, S) :-
%     prologsystem(Psys),				% [PD]
%     socket_closer(Psys, Socket, SC),		% [PD]
%     on_exception(Error,
% %		 socket_close(Socket),    % [PD]
% %		 close_socket(_H-Socket), % [PD]
% 		 SC,			  % [PD]
% 		 print_message(error, prologbeans(close_socket_c(S,Error)))).

close_streams :-
    current_streams(Ss),
    close_streams(Ss).

close_streams([]).
close_streams([S|Ss]) :-
    %% would be faster to simply close stream and retractall(stream(_,_))...
    close_stream(S),
    close_streams(Ss).


s_handle_inputs([]).
s_handle_inputs([S|RSs]) :-
    pb_opaque_stream(S,S,Stream), % [PD]
    handle_input(Stream),
    s_handle_inputs(RSs).

handle_input(S) :-
    stream_handler(S, H), !,
    handle_input(S, H).
handle_input(S) :-
    print_message(error, prologbeans(no_handler(S))),
    close_stream(S).

handle_input(S, H) :-
%    (  at_end_of_stream(S) ->  % [PD]
    (  check_end_of_stream(S) -> % [PD]
	maybe_close_stream(S)
    ;
	call_handler_robust(H, data_received(S))
    ).

%% [PD] Quintus 3.5/SICStus 3.11.1
check_end_of_stream(S) :-
    pb_input_stream(S,IS),
    ( prologsystem(sicstus) ->
	at_end_of_stream(IS)
    ;
	at_end_of_file(IS)
    ).

new_thread(H) :-
    nonvar(H),
    thread(H),!.
new_thread(H) :-
    nonvar(H),
    assert(thread(H)).

% unreachable
% remove_thread(H) :-
%     nonvar(H),
%     retractall(thread(H)).

get_threads(Hs) :-
    findall(H, thread(H), Hs).

handle_threads([H|Hs]) :-
    call_handler_robust(H, resume),
    handle_threads(Hs).
handle_threads([]).

call_handler_robust(H, G) :-
    on_exception(E, H:G, handler_error(H,G,E)), !.
call_handler_robust(H, G) :-
    print_message(warning, prologbeans(handler_failure(H,G))).

handler_error(H, G, E) :-
    print_message(error, prologbeans(handler_error(H,G,E))).

listen_error(system_blocked(M)) :- !,
    throw(system_blocked(M)).
listen_error(existence_error(_,1,stream,Stream,0)) :- !,
    %% stream no longer exists
    print_message(error, prologbeans(no_stream(Stream))),
    %% notify stream handler about the closed stream
    maybe_close_stream(Stream).
listen_error(E) :-
    print_message(error, prologbeans(listen(E))).

/* ----------------------------------------------------------------------
    Messages
   ---------------------------------------------------------------------- */

:- multifile user:generate_message_hook/3.
%%% if SICSTUS
/*
:- dynamic   user:generate_message_hook/3.
*/
%%% endif SICSTUS

user:generate_message_hook(prologbeans(What)) --> !,
    pbmessage(What).

pbmessage(close_socket_h(H,Error)) -->
	['[PBEANS] - could not close socket for handler ~q: ~q'-[H,Error],nl].
pbmessage(close_socket_c(S,Error)) -->
	['[PBEANS] - could not close socket connection ~q: ~q'-[S,Error],nl].
pbmessage(no_handler(S)) -->
	['[PBEANS] - no stream handler found for ~q'-[S],nl].
pbmessage(handler_failure(H,G)) -->
	['[PBEANS] - ~q failed to handle ~q'-[H,G],nl].
pbmessage(handler_error(H,G,E)) -->
	['[PBEANS] - ~q could not handle ~q: ~q'-[H,G,E],nl].
pbmessage(no_stream(S)) -->
	['[PBEANS] - stream ~q no longer exists (closing)'-[S],nl].
pbmessage(close_stream(S,Error)) -->
	['[PBEANS] - could not close stream ~q: ~q'-[S,Error],nl].
pbmessage(listen) -->
	['[PBEANS] - listen failed'-[],nl].
pbmessage(listen(Error)) -->
	['[PBEANS] - listen error: ~q'-[Error],nl].
pbmessage(denied(Host)) -->
	['[PBEANS] - denied connection from ~w'-[Host],nl].
pbmessage(read) -->
	['[PBEANS] - could not read data'-[],nl].
pbmessage(cyclic(Stream,Result)) -->
	['[PBEANS] - cyclic result to ~q: ~p'-[Stream,Result],nl].
