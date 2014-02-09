%   Module : 08/04/98 @(#)tcp.pl	76.1
%   Author : Tom Howland
%   Purpose: inter-process communication over the network using TCP
%   SeeAlso: help(tcp), man tcp
%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

/* [PM] April 2000 See inputservices.c for problems on Win32 */

:- module(tcp,[

    % using tcp

    tcp_trace/2,		  % -OldValue, +On_or_Off
    tcp_watch_user/2,   	  % -Old, +On_or_Off
    tcp_reset/0,

    % maintaining connections

    tcp_create_listener/2,	  % ?Address, -PassiveSocket
    tcp_destroy_listener/1,	  % +PassiveSocket
    tcp_listener/1,		  % -PassiveSocket
    tcp_address_to_file/2,	  % +FileName, +Address
    tcp_address_from_file/2,      % +FileName, -Address
    tcp_address_from_shell/3,     % +Host, +FileName, -Address
    tcp_address_from_shell/4,     % +Host, +UserId, +FileName, -Address
    tcp_connect/2,                % +Address, -Socket
    tcp_connected/1,		  % *Socket
    tcp_connected/2,		  % *Socket, *PassiveSocket
    tcp_shutdown/1,		  % +Socket
    tcp_mask/3,			  % *Socket, *Old_On_or_Off, +New_On_or_Off
%% [PD] 3.5 Necessary for prologbeans
    tcp_get_socket_address/2,	  % +Socket, -Address

    % sending and receiving terms

    tcp_select/1,		  % -Term
    tcp_select/2,		  % +Timeout, -Term
    tcp_send/2,			  % +Socket, +Term

    % time predicates

    tcp_now/1,                    % -Timeval
    tcp_time_plus/3,              % ?Timeval1, ?DeltaTime, ?Timeval2
    tcp_schedule_wakeup/2,        % +Timeval, +Term
    tcp_scheduled_wakeup/2,	  % *Timeval, *Term
    tcp_cancel_wakeup/2,	  % +Timeval, +Term
    tcp_cancel_wakeups/0,
    tcp_date_timeval/2,		  % ?Date, ?Timeval
    tcp_daily/4,		  % +Hour, +Minute, +Second, -Timeval

    % using Prolog streams

    tcp_input_stream/2,		  % *Socket, *Stream
    tcp_output_stream/2,	  % *Socket, *Stream
    tcp_select_from/1,		  % -Term
    tcp_select_from/2,		  % +Timeout, -Term

    % the callback interface

    tcp_create_input_callback/2,  % +Socket, +Goal
    tcp_destroy_input_callback/1, % +Socket
    tcp_input_callback/2,	  % *Socket, *Goal
    tcp_create_timer_callback/3,  % +Timeval, +Goal, -TimerId
    tcp_destroy_timer_callback/1, % +TimerId
    tcp_timer_callback/2,	  % *Timerid, *Goal
    tcp_accept/2,		  % +PassiveSocket, -Socket

    % type checking

    tcp_must_be_socket/3,	  % +Socket, +Arg, +Goal
    tcp_must_be_listener/3,	  % +PassiveSocket, +Arg, +Goal
    tcp_must_be_timeval/3,	  % +Timeval, +Arg, +Goal

% 1991:  obsolete predicates ... these will be deleted in the 1994 release

    tcp_listen/1,		  % +ServerFile
    tcp_listen/2,		  % +ServerFile, -Address
    tcp_listen_at_port/2,	  % ?Port, -Host
    tcp_connect/3,		  % +Address, +Myname, -Connection
    tcp_shutdown_listener/0

   ]).

:- meta_predicate
	tcp_create_input_callback(+, :),	% +Socket, +Goal
	tcp_create_timer_callback(+, :, -).	% +Timeval, +Goal, -TimerId

sccs_id('"@(#)98/08/04 tcp.pl	76.1"').

/* This module is described in the manual. */

:-use_module(library(critical)).
:-use_module(library(date), [datime/1, datime/2]).
:-use_module(library(types), [must_be/4]).
:-use_module(readwrite, [
			 write_term_special/2,
			 read_term_special/2
			]).
:-use_module(socketio).
:-use_module(tcp_msg).

:-dynamic
    msg_trace/0,
    alarm/1,
    fd/2,
    fd_host_port/3,
    host_port_fd/3,
    keyboard_flag/0,
    tcp_input_stream/2,
    tcp_input_callback/2,
    tcp_output_stream/2,
    tcp_listener/1,
    timer/3,
    server_host_port/2,
    wake/3.

:-volatile
    msg_trace/0,
    alarm/1,
    fd/2,
    fd_host_port/3,
    host_port_fd/3,
    keyboard_flag/0,
    tcp_input_stream/2,
    tcp_input_callback/2,
    tcp_output_stream/2,
    tcp_listener/1,
    timer/3,
    server_host_port/2,
    wake/3.

:- extern(timer_callback(+integer)).
:- extern(input_callback(+integer)).

trace(F,L) :-
    (   msg_trace
    ->  write(user_error,'% tcp (trace):  '),
	format(user_error,F,L),
	nl(user_error)
    ;   true
    ).

tcp_connected(Socket) :-
	fd(Socket, _).

tcp_connected(Socket, Passive) :-
	fd(Socket, Passive),
	Socket \== Passive.

vonoff(OnOff, Arg, G):-
    (   var(OnOff)
    ->  true
    ;   onoff(OnOff, Arg, G)
    ).

onoff(OnOff, Arg, G) :- must_be(oneof([on,off]), OnOff, Arg, G).

set_msg_trace(on):-assert(msg_trace).
set_msg_trace(off):-retract(msg_trace).

tcp_trace(Old, New) :-
    G=tcp_trace(Old,New),
    vonoff(Old, 1, G),
    vonoff(New, 2, G),
    (   msg_trace
    ->  Old = on
    ;   Old = off
    ),
    (   New = Old
    ->  true
    ;   set_msg_trace(New)
    ).

tcp_reset :-	    
    critical(protected_reset).

protected_reset :-
    tcp_connected(C),		% shutdown all of the active sockets
    tcp_shutdown(C),
    fail.
protected_reset :-
    tcp_listener(PassiveSocket),
    tcp_destroy_listener(PassiveSocket),
    fail.
protected_reset :-
    tcp_timer_callback(TimerId, _),
    tcp_destroy_timer_callback(TimerId),
    fail.
protected_reset :-
    tcp_cancel_wakeups,
    tcp_watch_user(_, off),	% don't watch stdin by default
    tcp_trace(_, off).	% don't trace by default

tcp_scheduled_wakeup(timeval(S,U), Term) :- wake(S, U, Term).

tcp_cancel_wakeups :-
    begin_critical,
        retractall(wake(_,_,_)),        % kill off the timing stuff
        retractall(alarm(_)),
    end_critical.

/* kill a socket ... tcp_shutdown/1 must be used instead of close */

tcp_shutdown(C) :-
    must_be(ground, C, 1, tcp_shutdown(C)),
    critical(shutdown_please(C)),
    trace('Connection ~p shut down.',[C]).

shutdown_please(C):-
    fd(C, _),
    (   tcp_input_callback(C, _)
    ->  tcp_destroy_input_callback(C)
    ;   true
    ),
    retractall(fd(C, _)),
    (   retract(fd_host_port(C,Host,Port))
    ->  retractall(host_port_fd(Host,Port,C))
    ;   true
    ),
    retract(tcp_output_stream(C,Os)),
    close(Os),
    retract(tcp_input_stream(C,Is)),
    close(Is),
    tcp_shutdown(C, _).

tcp_select(X):-
    select1(1, 0.0, It, tcp_select(X)),
    trace('tcp_select(~q)', [It]),
    X = It.

tcp_select(Timeout, X):-
    select1(0, Timeout, It, tcp_select(Timeout,X)),
    trace('tcp_select(~q,~q)', [Timeout,It]),
    X = It.

select1(Block, Timeout, It, G):-
    sel_aux(Block, Timeout, C),
    read_or_match(C, It, G).

sel_aux(Block, Timeout, X):-
    (   alarm(Alarm)
    ->  Alarm = wake(S,U,Term),
	tcp_now(Now),
	tcp_time_plus(Now, D1, timeval(S,U)),
	(   D1 =< 0.0
	->  X = wakeup(Term),
	    alarm_status
	;   (   Block =:= 1
	    ->  true
	    ;   D1 < Timeout
	    )
	->  sel_tail(D1, wakeup(Term), 0, X)
	;   sel_tail(Timeout, timeout, Block, X)
	)
    ;   sel_tail(Timeout, timeout, Block, X)
    ).

sel_tail(Timeout, TimeAction, Block, X):-
    tcp_select(Block, Timeout, FD, Status),
    status(Status, FD, TimeAction, X).

/* here we dispatch on the return status from tcp_select(). */

status(1, FD, _, X):-
    (   FD =:= 0, keyboard_flag
    ->  X = user_input
    ;   fd(FD, _)
    ->  X = from(FD)
    ;   critical(connection_request(FD, Socket)),
	X = connected(Socket)
    ).
status(0, _, X, X):-
    time_action(X).
status(-1, _, _, _) :- eek.

connection_request(FD, ClientFD) :-
    accept(FD, ClientFD),
    (   ClientFD > 0
    ->  socket_io_open_output(ClientFD, Ocode),
	stream_code(Ostream, Ocode),
	socket_io_open_input(ClientFD, Icode),
	stream_code(Istream, Icode),
	record_connection(ClientFD, Icode, Istream, Ostream, FD),
	trace('Connection to client ~p accepted.', [ClientFD])
    ;   eek
    ).

record_connection(Socket,Icode,Istream,Ostream,Passive):-
    tcp_check_stream(Socket,Icode),
    assert(tcp_input_stream(Socket,Istream)),
    assert(tcp_output_stream(Socket,Ostream)),
    assert(fd(Socket,Passive)).


tcp_create_input_callback(Socket, Goal):-
    G=tcp_create_input_callback(Socket, Goal),
    tcp_must_be_socket(Socket, 1, G),
    must_be(callable, Goal, 2, G),
    on_exception(E, critical(create_input_callback(Socket, Goal)),
		 blame_on(E, G)).

tcp_must_be_socket(Socket, Arg, Goal):-
    must_be(ground, Socket, Arg, Goal),
    (   fd(Socket, _)
    ->  true
    ;	tcp_listener(Socket)
    ->  true
    ;   not_a_socket(Socket, tcp_socket, Arg, Goal)
    ).

not_a_socket(Socket, Type, Arg, Goal) :-
    raise_exception(existence_error(Goal, Arg, Type, Socket, 0)).

create_input_callback(Socket, Goal) :-
    (   tcp_input_stream(Socket, Stream)
    ->  stream_code(Stream, StreamCode),
	tcp_create_input_callback_please(Socket, StreamCode, Status)
    ;	tcp_listener(Socket),
	socket_io_open_input(Socket, Icode),
	tcp_create_input_callback_please(Socket, Icode, Status)
    ),
    check(Status), 
    assert(tcp_input_callback(Socket, Goal)).

blame_on(E, G) :- raise_exception(blame_on(E,G)).

input_callback(Socket) :-
    tcp_input_callback(Socket, X),
    callback(X).

callback(Goal) :-
    on_exception(E, Goal, print_message(warning, blame_on(E, Goal))).

tcp_destroy_input_callback(Socket) :-
    G = tcp_destroy_input_callback(Socket),
    tcp_must_be_socket(Socket, 1, G),
    (   tcp_input_callback(Socket, _)
    ->  begin_critical,
            tcp_destroy_input_callback_please(Socket),
	    retractall(tcp_input_callback(Socket, _)),
        end_critical
    ;   true
    ).

timer_callback(Cookie) :-
    retract(timer(Cookie, _, Goal)),
    callback(Goal).

tcp_timer_callback(Cookie, Goal) :-
    timer(Cookie, _, Goal).

tcp_create_timer_callback(Timeval, Goal, Cookie):-
    G = tcp_create_timer_callback(Timeval, Goal, Cookie),
    tcp_must_be_timeval(Timeval, 1, G),
    Timeval = timeval(S,U),
    must_be(callable, Goal, 2, G),
    must_be(var, Cookie, 3, G),
    critical(create_timer_callback(S, U, Goal, Cookie)).

tcp_must_be_timeval(Timeval, N, G):-
    must_be(ground, Timeval, N, G),
    (   Timeval = timeval(S, U), integer(S), integer(U)
    ->  true
    ;   raise_exception(domain_error(G,N,tcp_timeval,Timeval,0))
    ).

create_timer_callback(S, U, Goal, Cookie):-
    tcp_create_timer_callback(S, U, Cookie, TimerId, Status),
    check(Status),
    assert(timer(Cookie, TimerId, Goal)).

tcp_destroy_timer_callback(Cookie) :-
    integer(Cookie),
    timer(Cookie, TimerId, _),
    begin_critical,
        retractall(timer(Cookie, _, _)),
	'QP_remove_timer'(TimerId),
    end_critical.

tcp_accept(PassiveSocket, Socket) :-
    tcp_must_be_listener(PassiveSocket, 1,
			       tcp_accept(PassiveSocket, Socket)),
    critical(connection_request(PassiveSocket, Socket)).

tcp_must_be_listener(Socket, Arg, Goal):-
    must_be(ground, Socket, Arg, Goal),
    (   tcp_listener(Socket)
    ->  true
    ;   not_a_socket(Socket, tcp_listener, Arg, Goal)
    ).

time_action(timeout).
time_action(wakeup(_)) :- alarm_status.

% The cut after the two retracts ensure that only one alarm/1 clause is being
% retracted. See QP bug 5148 as well as WP bug 1458
alarm_status:-
    begin_critical,
        retract(alarm(G)),
        retract(G),
	!,
        schedule_next_wakeup,
    end_critical.

schedule_next_wakeup:-
    functor(W, wake, 3),
    setof(W, W, [W|_]),
    !,
    (   alarm(W)
    ->  true
    ;   retractall(alarm(_)),
	assert(alarm(W))
    ).
schedule_next_wakeup.

/* 
  Reading from a broken socket raises the exception
  ! read_error('$stream'(655366),errno(54))
  and corresponds to error number 54.  Errno 54 is "Connection reset by peer".
  Ignoring it and reading again positions the stream at end_of_file.
*/
handle_read_error(54, T, S, _G) :- !, read_term_special(S, T).
% Reading past eof error gets mapped to end_of_file
handle_read_error(1001, end_of_file, _S, _G) :- !.
handle_read_error(E, _, S, G) :- blame_on(read_error(S,errno(E)), G).

read_or_match(from(C), X, G):-
    !,
    tcp_input_stream(C, S),
    on_exception(read_error(_,errno(E)), read_term_special(S, T),
		 handle_read_error(E, T, S, G)),
    (   T == end_of_file
    ->  tcp_shutdown(C),
        X = end_of_file(C)
    ;   X = term(C,T)
    ).
read_or_match(X, X, _).

/* enable or disable listening for keyboard input */

tcp_watch_user(Old,New):-
    G = tcp_watch_user(Old,New),
    vonoff(Old, 1, G),
    vonoff(New, 2, G),
    (   keyboard_flag
    ->  Old = on
    ;   Old = off
    ),
    (   New = Old
    ->  true
    ;   prolog_flag(host_type, ix86) -> % [PM] April 2000
        raise_exception(tcp_mishap('tcp_watch_user not supported on Win32', 0))
    ;   critical(set_keyboard(New))
    ).

% [PM] April 2000 Note: These do not work at all on windows and only
%      watch stdin (as opposed to user_input) on unix.
set_keyboard(on):-
    tcp_setmask(0, 1, Status),
    check(Status),
    assert(keyboard_flag).
set_keyboard(off):-
    tcp_setmask(0, 0, Status),
    check(Status),
    retract(keyboard_flag).

tcp_mask(Socket, Old, New) :-
    G=tcp_mask(Socket, Old, New),
    vonoff(Old, 2, G),
    tcp_must_be_socket(Socket, 1, G),
    tcp_current_mask(Socket, Old),
    (   New = Old
    ->  true
    ;   onoff(New, 3, G),
        n(New, N),
	tcp_setmask(Socket, N, Status),
	check(Status)
    ).

n(on, 1).
n(off, 0).

/* It is typically a disaster to interrupt the transmission of a term,
   since the receiving process's input buffers can become corrupted,
   so we wrap the send in a critical region. */

tcp_send(Socket, Term) :-
    (   tcp_output_stream(Socket, OutStream)
    ->  critical(write_term_special(OutStream,Term)),
        trace('Sent ~p:  ~q.',[Socket,Term])
    ;   not_a_socket(Socket, tcp_active_socket, 1, tcp_send(Socket, Term))
    ).

tcp_now(timeval(S,U)):-tcp_now(S, U).

tcp_time_plus(timeval(Si,Ui), D, timeval(So,Uo)):-
    (   var(So)
    ->  tcp_time_plus(Si, Ui, D, So, Uo)
    ;   var(D)
    ->  D is So - Si + (Uo - Ui) / 1.0e6
    ;   D1 is -D, tcp_time_plus(So, Uo, D1, Si, Ui)
    ).

tcp_schedule_wakeup(timeval(S,U),Term):-
    begin_critical,
        assert(wake(S,U,Term)),
	schedule_next_wakeup,
    end_critical.

tcp_cancel_wakeup(timeval(S,U), Term):-
    W=wake(S,U,Term),
    (   alarm(W)
    ->  alarm_status
    ;   retract(W)
    ->  true
    ).

tcp_daily(H,M,S,timeval(Seconds,0)):-
    datime(date(Y,Mo,Day,Hn,Mn,Sn)),
    datime(SS,date(Y,Mo,Day,H,M,S)),
    (	time(H,M,S) @> time(Hn,Mn,Sn)
    ->	Seconds is SS
    ;	Seconds is SS + 86400		% 86400 is 24*60*60.
    ).

tcp_date_timeval(date(Year,Month,Day,Hour,Minute,Second),timeval(S,U)):-
    (   var(S)
    ->  datime(S,date(Year,Month,Day,Hour,Minute,Second)),
        (U=0->true;true)
    ;   datime(S,date(Year,Month,Day,Hour,Minute,Second))
    ).

tcp_connect(Address, Socket):-
    G = tcp_connect(Address, Socket),
    must_be(ground, Address, 1, G),
    Address = address(Port,Host),
    (   nonvar(Socket), fd(Socket, _)
    ->  (   fd_host_port(Socket, Host1, Port1)
	->  (   Port1 = Port, Host1 = Host
	    ->  true
	    ;   raise_exception(permission_error(G,tcp_connect,
		    tcp_connection_id,Socket,
		    tcp_connection_already_exists(Socket)))
	    )
	;   true
	)
    ;   host_port_fd(Host, Port, Socket)
    ->  fd(Socket, _)
    ;   critical(protected_connect(Port, Host, Socket)),
        trace('Connection ~q created to hostname ~q', [Socket,Host])
    ).

protected_connect(Port, Host, Socket):-
    connect(Host, Port, Socket),
    (   Socket =:= -1
    ->  eek
    ;   socket_io_open_output(Socket, Ocode),
        stream_code(Ostream, Ocode),
	socket_io_open_input(Socket, Icode),
	stream_code(Istream, Icode),
	record_connection(Socket, Icode, Istream, Ostream, Socket),
	assert(host_port_fd(Host,Port,Socket)),
	assert(fd_host_port(Socket,Host,Port))
    ).

tcp_create_listener(address(Port, Host), PassiveSocket) :-
    critical(listen_at_port(Port, Host, PassiveSocket)),
    trace('Passive socket ~d at port ~d on host ~a created',
	  [PassiveSocket, Port, Host]).

listen_at_port(Port, Host, PassiveSocket):-
    (   var(Port)
    ->  InPort = 0
    ;   InPort = Port
    ),
    tcp_listen_at_port(InPort, OutPort, OutHost, PassiveSocket, Status),
    check(Status),
    (   Port = OutPort,
        Host = OutHost
    ->  listen_tail(PassiveSocket)
    ;   tcp_shutdown(PassiveSocket, Status),
	check(Status),
	fail
    ).

listen_tail(PassiveSocket):-
    (   PassiveSocket =:= -1
    ->  eek
    ;   assert(tcp_listener(PassiveSocket))
    ).

%% [PD] 3.5
tcp_get_socket_address(Socket, address(Port, Host)) :-
    tcp_get_socket_address(Socket, Port, Host).


tcp_destroy_listener(PassiveSocket) :-
    G=tcp_destroy_listener(PassiveSocket),
    tcp_must_be_listener(PassiveSocket, 1, G),
    critical(protected_shutdown_listener(PassiveSocket)),
    trace('Passive Socket ~d destroyed.', [PassiveSocket]).

protected_shutdown_listener(PassiveSocket) :-
    (   tcp_input_callback(PassiveSocket, _)
    ->  tcp_destroy_input_callback(PassiveSocket)
    ;   true
    ),
    retractall(tcp_listener(PassiveSocket)),
    retractall(server_host_port(_,_)),
    tcp_shutdown(PassiveSocket, Status),
    check(Status).

tcp_address_to_file(FileName, address(Port, Host)) :-
    absolute_file_name(FileName,[file_type(text)],F),
    tcp_address_to_file(F, Port, Host, Status),
    check(Status),
    trace('~q written to ~a', [address(Port, Host), F]).

tcp_select_from(X):-
    sel_aux(1, 0.0, It),
    trace('tcp_select_from(~q)', [It]),
    X = It.

tcp_select_from(Timeout, X):-
    sel_aux(0, Timeout, It),
    trace('tcp_select_from(~q,~q)', [Timeout,It]),
    X = It.

tcp_address_from_file(ServerFile,address(Port,Host)):-
    absolute_file_name(ServerFile,[file_type(text)],SF),
    tcp_address_from_file(SF,Port,Host,Status),
    check(Status).

check(Status):-
    (   Status =:= 0
    ->  true
    ;   eek
    ).

eek:-tcp_fetch_error(Msg, Num), raise_exception(tcp_mishap(Msg, Num)).

tcp_address_from_shell(Host1, ServerFile, address(Port,Host)):-
    tcp_address_from_shell(Host1, '', ServerFile, Port, Host, Status),
    check(Status).

/* tcp_address_from_shell/4:  This adds a User Id parameter, so that the
machine that has the handle file need not have an account for every
user that wishes to access it. */

tcp_address_from_shell(Host1, UserId, ServerFile, address(Port,Host)):-
    tcp_address_from_shell(Host1, UserId, ServerFile, Port, Host, Status),
    check(Status).

/*    accept(+PassiveSocket,-Socket)

accept/2 is used to accept a connection request.  A connection request
is recognized when the file descriptor returned by select/1 is the
file descriptor for the server's socket (+PassiveSocket).  It returns the
file descriptor for the newly created socket (-Socket). */

foreign(tcp_accept,c,accept(+integer,[-integer])).

foreign(tcp_address_from_file,c,tcp_address_from_file(+string,-integer,-string,
						      [-integer])).
foreign(tcp_address_from_shell,c,tcp_address_from_shell(+string,+string,
    +string,-integer,-string,[-integer])).
foreign(tcp_address_to_file,c,tcp_address_to_file(+string,+integer,+string,
						      [-integer])).
foreign(tcp_check_stream,c,tcp_check_stream(+integer,+address)).

/*    connect(+HostName, +Port, -Socket)

connect/3 is used by clients to connect to the server running on
+HostName at +Port.  It returns the file descriptor for the newly
created socket (-Socket). */

foreign(tcp_connect,c,connect(+string,+integer,[-integer])).

foreign(tcp_destroy_input_callback, c,
	tcp_destroy_input_callback_please(+integer)).
foreign('QP_remove_timer', c, 'QP_remove_timer'(+integer)).
foreign(tcp_create_input_callback, c,
	tcp_create_input_callback_please(+integer, +address, [-integer])).
foreign(tcp_create_timer_callback, c, tcp_create_timer_callback(+integer,
    +integer, -integer, -integer, [-integer])).
foreign(tcp_current_mask, c, tcp_current_mask(+integer, [-atom])).
foreign(tcp_fetch_error,c,tcp_fetch_error(-atom, [-integer])).

/* listen(+ServerFile, -Port, -Host, -PassiveSocket)

listen/4 is used by a server to create the passive socket.  The passive
socket is used in later calls to accept/4 when a connection request is
detected from select/1.  Port is the port number, Host is the name of
the local host. */

foreign(tcp_listen, c, listen(+string, -integer, -string, [-integer])).

foreign(tcp_create_listener,c,
	tcp_listen_at_port(+integer, -integer, -string, -integer,
			   [-integer])).

%% [PD] 3.5
foreign(tcp_get_socket_address, c, tcp_get_socket_address(+integer, -integer, -string)).

foreign(tcp_now, c, tcp_now(-integer,-integer)).
foreign(tcp_select, c, tcp_select(+integer, +double, -integer, [-integer])).

/*    tcp_setmask(+FileDescriptor,+ZeroOrOne,-Status)

tcp_setmask/3 sets the mask used in the operating system function
select().  This causes the predicate select/1 to return the file
descriptor specified in tcp_setmask when there is io available. */

foreign(tcp_setmask,c,tcp_setmask(+integer,+integer,[-integer])).

foreign(tcp_shutdown,c,tcp_shutdown(+integer,[-integer])).

foreign(tcp_time_plus,c,tcp_time_plus(+integer,+integer,+double,
					-integer,-integer)).

foreign_file(library(system(tcp_p)),[
    'QP_remove_timer',
    tcp_accept,
    tcp_address_from_file,
    tcp_address_from_shell,
    tcp_address_to_file,
    tcp_check_stream,
    tcp_connect,
    tcp_create_timer_callback,
    tcp_create_input_callback,
    tcp_current_mask,
    tcp_destroy_input_callback,
    tcp_fetch_error,
    tcp_listen,
    tcp_create_listener,
    tcp_get_socket_address,
    tcp_now,
    tcp_select,
    tcp_setmask,
    tcp_shutdown,
    tcp_time_plus]).

:- load_foreign_executable(library(system(tcp_p))),
   abolish(foreign_file, 2),
   abolish(foreign, 3).

% 1991:  obsolete ... the following will be deleted in the 1994 release

tcp_connect(Address, _, Conn_id) :- tcp_connect(Address, Conn_id).
tcp_shutdown_listener:-tcp_listener(S),tcp_destroy_listener(S).

tcp_listen_at_port(Port, Host) :- %  +Port, -Host
    (   tcp_listener(_)
    ->  server_host_port(Host, Port)
    ;   tcp_create_listener(address(Port,Host), _),
        assert(server_host_port(Host,Port))
    ).

tcp_listen(ServerFile):-listen(ServerFile,_,_).

tcp_listen(ServerFile,address(Port,Host)):-listen(ServerFile,Port,Host).

listen(ServerFile,Port,Host):-
    (   tcp_listener(_)
    ->  server_host_port(Host,Port)
    ;   absolute_file_name(ServerFile,[file_type(text)],SF),
        critical(listen_for_connection_requests(SF,Port,Host)),
	trace('Passive socket recorded in ~p',[SF])
    ).

listen_for_connection_requests(SF,Port,Host):-
    listen(SF,Port,Host,PassiveSocket),
    listen_tail(PassiveSocket),
    assert(server_host_port(Host,Port)).
