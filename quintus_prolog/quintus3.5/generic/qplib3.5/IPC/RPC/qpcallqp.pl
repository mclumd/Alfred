%   Module: qpcallqp
%   Author : David S. Warren
%   Updated: 09/05/90
%   Purpose: Let Prolog call Prolog in another process.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.


:- module(qpcallqp, [
	save_servant/1,
	create_servant/2,
	create_servant/3,
	shutdown_servant/0,
	call_servant/1,
	bag_of_all_servant/3,
	set_of_all_servant/3,
	reset_servant/0,
	msg_trace/2,
	start_servant/0
   ]).

:- meta_predicate
	call_servant(0),
	bag_of_all_servant(+, 0, ?),
	set_of_all_servant(+, 0, ?).


:- ensure_loaded(library(basics)).
:- ensure_loaded(socket).

sccs_id('"@(#)90/09/05 qpcallqp.pl	56.1"').


/*  These Prolog routines allow a user to send goals to another process,
    have them evaluated in that process, and have the answers returned
    to the caller.  The user can set up and do remote nondeterministic
    procedure calls.

    There are two ways of doing this:
    -	the connection may be LOCAL (on the same machine) using PIPES.
    -	the connection may be REMOTE (possibly on another machine)
	using SOCKETS (TCP/IP).	
    The latter possibility is specific to 4.xBSD systems and their
    derivatives, and is not generally available under System V.  Note
    that the current interface doesn't make a great deal of sense
    unless the local and remote machines share the same file system,
    as this version of the IPC interface has no way of supplying an
    authentication code to the other machine.  But the two machines
    do not have to be the same hardware type.  You must be able to
    use rsh(1) to access a remote machine in order to use it.

    To start up a servant process, issue the command
	create_servant(+Machine,+SavedState,+Outfile)
    where Machine is the name of the possibly remote machine, and
    SavedState is the name of the previously created saved state file.
    Note that SavedState is interpreted relative to the current value
    of the $PATH environment variable in the current process, just as
    unix(system(SavedState)) would search for the saved state.  The
    possibly remote machine must be able to access files in the local
    machine's file system.

	create_servant(+SavedState,+Outfile)
    runs the saved state locally.  The same effect can be obtained by
    passing '' as Machine to create_servant/3.

    After this command is done, you may use the bag_of_all_servant/3
    (and call_servant/1) predicate.  It has the semantics of (safe)
    findall but allows you to execute goals in the other process.
    See below for details.

    Note that all clauses needed to evaluate a remote goal must be
    available in the Prolog process that is the servant process.  This
    can be done either by consulting or compiling them into the remote
    saved state, or by sending a consult or compile command through
    call_servant.

    Illegal goals sent to the servant process may send it into an aborted
    state.  Standard output for the servant process is routed into a file
    `QP_servantout' in your home directory on the local machine.  Look
    there when things get weird.

    To close down the servant, issue the command:
	:- shutdown_servant.

    The servant Prolog process will shut itself down, and you will get
    its termination message.  (Stderr messages from the servant process
    come back to your window.)

    Possible extensions:  This only supports one remote process.  It
    would not be difficult to support multiple remote servants.  We
    would add an extra argument to bag_of_all_servant to indicate which
    servant to use.
*/

/* The only protocol supported here is called set-at-a-time, and for
    this protocol, the servant computes and writes all the answers
    directly back to the socket.  Thus the caller must read all the
    answers from the socket before sending any other goal to be
    evaluated.  This protocol is invoked by sending the term
    sat(Goal,Template) to the servant.  Goal is the goal to be evaluated
    by the servant.  For each success, Template is written back to the
    socket.  The sequence of answers is terminated by the atom 'fail'.
    The master can access these facilities through bag_of_all_servant/3.
    Other protocols could be written using the facilities here.  The
    bag_of_all_servant seems to be a simple but useful compromise.

    We need the socket routines from socket.pl.  They create sockets and
    make connections through them.  They also include routines for
    sending and receiving messages over them.
*/


/************************************************************************/
/*									*/
/*			Prolog goal servant				*/
/*									*/
/************************************************************************/


/*  Action to be taken when servant is run.
*/

start_servant :-
    prolog_load_context(stream,_),	% just loaded this file
    !.
start_servant :-			% really starting
    connect_and_serve,
    halt.


/*  save_servant(+SavedState)
    creates a saved state in the file SavedState, which can later be
    used by create_servant to create a servant.
*/
save_servant(Savedstate) :-
    save_program(Savedstate, start_servant).


/*  connect_and_serve
    causes this process to become a Prolog command servant.

    There are two cases:
	REMOTE EXECUTION THROUGH SOCKETS
	    This command was started up as
		rsh ${HostName} -n ${SavedState} \
		    -socket ${CallHost} ${CallPort} '&' &
	    or as
		rsh ${HostName} -n ${SavedState} \
		    -socket ${CallHost} ${CallPort} \
		    >${OutputFile} 2>&1 '&' &
	    In either case, the command line as Prolog sees it looks like
		${SavedState} -socket ${CallHost} ${CallPort}
	    and we have to call back to ${CallPort} AT ${CallHost}.

	LOCAL EXECUTION THROUGH PIPES
	    This command was started up directly through fork() & exec(),
	    but could be described roughly as
		${SavedState} </dev/null ${I}<${PipeIn} ${O}>${PipeOut} \
		    -pipe ${I} ${O} &
	    or as
		${SavedState} </dev/null ${I}<${PipeIn} ${O}>${PipeOut} \
		    -pipe ${I} ${O} >${OutputFile} 2>&1 &
	    In either case, the command line as Prolog sees it looks like
		${SavedState} -pipe ${I} ${O}
*/
connect_and_serve :-
	sigsign,		% ignore signals as a servant
	unix(argv(CommandLine)),
	check_command_line(CommandLine, HostName, InPort, OutPort),
	connect_to(HostName, InPort, OutPort),
	!,
	servegoal(_Cmd),		% go process all commands
	shutdown_connection.		% over and out
connect_and_serve :-
	write_sock_error(['Starting servant: incorrect parameters']).


check_command_line(['-pipe',I,O|_], '', I, O) :- !,
	integer(I), integer(O).
check_command_line(['-socket',H,I|_], H, I, 0) :- !,
	atom(H), integer(I).
check_command_line([_|CommandLine], H, I, O) :-
	check_command_line(CommandLine, H, I, O).



/*  servegoal(-Com)
    loops reading goals from connection 1 and calling them, sending the
    answers back.  It returns when it reads either a `close' or
    `shutdown' command, and it returns that command.  Nobody currently
    uses this result.
*/
servegoal(Com) :-
	repeat,
	    recvterm(Com),
	    servecmd(Com),
	!.


/*  servecmd(+Cmd)
    evaluates the command Cmd from the remote process.  The commands can
    be seen below; the main one being sat(G,A) which calls the goal G
    and sends back answers A. The others maintain the connection.
*/
servecmd(shutdown).	% stop serving goals.
servecmd(close).	% stop serving goals.
servecmd(reset) :-	% send `reset' msg to permit re-syncing
	sendterm(reset),
	fail.
servecmd(sat(G,A)) :-
	call(G),
	sendterm(A),
	fail
    ;   sendterm(fail),
	fail.


/************************************************************************/
/*									*/
/*			Prolog Master Routines				*/
/*									*/
/************************************************************************/



/*  create_servant(+Remote_machine, +SavedState, +User_out_file)
    starts up a Prolog process on machine Remote_machine.  It uses the
    Prolog saved state SavedState to do so.  That save state should have
    been created with the command save_servant.  The file name of the
    saved state is evaluated with respect to the $PATH variable of the
    current process on the local machine.  This user must be able to
    execute an rsh to the remote machine.  The output to user by the
    remote Prolog process will be put in the file User_out_file.
*/
create_servant(SavedState, User_out_file) :-
	atom(SavedState),
	atom(User_out_file),
	!,
	pipe_servant(SavedState, User_out_file, FromSlave, ToSlave, PID),
	PID >= 0,
	connect_pipe(FromSlave, ToSlave),
	write_sock_msg(['Child',PID,started]).
create_servant(_, _) :-
	write_sock_error('Illegal parameters to create_servant/2'),
	fail.

create_servant('', SavedState, User_out_file) :- !,
	create_servant(SavedState, User_out_file).
create_servant(RemoteMachine, SavedState, User_out_file) :-
	atom(RemoteMachine),
	atom(SavedState),
	atom(User_out_file),
	!,
	make_socket(ThisPort, ThisMachine, 1),
	(   RemoteMachine == local ->
	    Machine = ThisMachine
	;   Machine = RemoteMachine
	),
	call_servant(RemoteMachine, SavedState, User_out_file,
		ThisMachine, ThisPort, 0),
	connect_socket,
	write_sock_msg(['Servant',Machine,connected]).
create_servant(_, _, _) :-
	write_sock_error('Illegal parameters to create_servant/3'),
	fail.



/*  reset_servant
    is called by master to reset the connection, clearing any unread
    answers and resetting the servant.  Shouldn't be necessary for the
    user, unless there is an abort in the middle of a remote call.
*/
reset_servant :-
	(   outaremcall -> true ; true   ),	% ???
	sendterm(reset),
	repeat,
	    recvterm(reset),
	!.


/*  shutdown_servant
    closes the connection to the servant and causes the servant to
    shut down completely.
*/
shutdown_servant :-
	reset_servant,
	sendterm(shutdown),
	shutdown_connection.


/************************************************************************/
/*									*/
/*			Set-at-a-Time Master Routines			*/
/*									*/
/************************************************************************/


/* '$inremcall'
    is true if a goal is in the process of being evaluated remotely.
    Another goal cannot be sent if one is currently being processed, and
    this flag is used to determine such an attempt and issue an error
    message.
*/
:- dynamic
	'$inremcall'/0.


/*  free_variables(?Generator, ?Template, +OldList, ?NewList)
    finds the free variables in terms.  It is needed to get the
    variables in a goal to be sent to the remote goal servant.
*/
%- use_module(library(freevars), [free_variables/4]).	% why not?
:- ensure_loaded(library(freevars)).


/*  Need strip_module_prefix/4
    to handle module names correctly.
*/
%- use_module(library(call), [strip_module_prefix/4]).	% why not?
:- ensure_loaded(library(call)).


/*  bag_of_all_servant(Template,Goal,-Alist)
    where Template is a template for answers, Goal is a (possibly
    compound) goal that will be evaluated at least partially on the
    remote machine, and Alist is the list of answers.  There must be no
    free variables in the compound goal.  This is logically and
    computationally equivalent to bag_of_all(Template,Goal,Alist).  If
    Goal is not a compound goal (i.e., of the form (Rg,Lg) or (Rg;Lg)),
    it will be entirely evaluated on the remote machine.  If Goal is of
    the form (Rg,Lg) then Rg will be evaluated on the remote machine and
    Lg on the local machine.  In this case the evaluation of Lg must NOT
    access the remote machine.  If Rg and Lg share variables, then Lg is
    called with each answer returned from Rg, and computation of
    subsequent answers for Rg overlap the evaluation extending earlier
    answers through Lg.  If Rg and Lg do not share variables, then the
    computation is entirely in parallel.  If Goal is of the form
    (Rg;Lg), then again Rg is evaluated remotely and Lg locally (and
    again the evaluation of Lg must NOT use the remote machine).  In
    this case the entire computation of Rg and Lg goes on in parallel.
*/
set_of_all_servant(Template, Goal, Set) :-
	bag_of_all_servant(Template, Goal, Bag),
	sort(Bag, Set).

bag_of_all_servant(Template, Goal, _) :-
	free_variables(Goal, Template, [], Vars),
	Vars \== [],
	!,
	write_sock_error([
	  'Free variables not allowed in bag_of_all_servant']),
	fail.
bag_of_all_servant(Template, Goal, Anslist) :-
   /**/ call:strip_module_prefix(Goal, user, Newgoal1, Module),
	strip_quant(Newgoal1, Newgoal),
	(   Newgoal = (Remgoal,Locgoal) ->
	    free_variables(Remgoal, [], [], Rvars),
	    sendterm(sat(Module:Remgoal,Rvars)),
	    inremcall,
	    (   free_variables(Remgoal, Locgoal, [], Rvars) ->
		% no shared vars, so more parallelism
		findall(Template, locollect(Rvars,Module:Locgoal), Anslist1)
	    ;   findall(Template, (get_answers(Rvars), Module:Locgoal), Anslist1)
	    ),
	    outaremcall,
	    Anslist = Anslist1
	;   Newgoal = (Remgoal ; Locgoal) ->
	    sendterm(sat(Module:Remgoal,Template)),
	    inremcall,
	    findall(Template, Module:Locgoal, Anslist1),
	    recvterm(X),
	    collect_answers(X, Anslistall, Anslist1),
	    outaremcall,
	    Anslist = Anslistall
	;   /*otherwise*/
	    bag_of_all_servant1(Template, Goal, Anslist)
	).


/*  strip_quant(+Quant_goal, ?Goal)
    where Goal is Quant_goal with leading existential quantifiers stripped.
*/
strip_quant(_^A, B) :- !,
	strip_quant(A, B).
strip_quant(A, A).


/*  get_answers(?T)
    nondeterministically returns answers sent by a remote goal.  So
    (sendterm(sat(Goal,Ans)),get_answers(Ans)) is a remote call.
    This isn't really a repeat loop.  There is genuine backtracking
    happening at the other end.  The loop stops when the other end
    sends 'fail'.
*/
get_answers(T) :-
	repeat,
	    recvterm(X),
	    (   X = fail, !, fail
	    ;   true
	    ),
	    X = T.


/*  locollect(+Rvars,+Local_goal)
    semantically produces the the effect of calling
    (Remote_goal,Local_goal) under the assumption that Remote_goal has
    variables Rvars and has already been sent to the remote machine, and
    that Local_goal and Remote_goal do NOT share variables.  Under these
    assumptions, local and remote processing can be highly overlapped.
    locollect works by using findall to compute all the local answers,
    and then retrieving the remote ones, and nondeterministically
    producing the cross product.
*/
locollect(Rvars, Locgoal) :-
	free_variables(Locgoal, [], [], Lvars),
	findall(Lvars, Locgoal, Locans),
	get_answers(Rvars),
	member(Lvars, Locans).


/*  collect_answers(+Ans,-AllAns,+SomeAns)
    collects remote answers into a list.  AllAns is the list obtained by
    taking Ans as the first element, following that with all the remote
    answers `still in the socket', and concatenating SomeAns onto the
    end of that.
*/
collect_answers(fail, L, L) :- !.
collect_answers(Ans, [Ans|Alist], Blist) :-
	recvterm(X),
	collect_answers(X, Alist, Blist).


/*  bag_of_all_servant1(+Template,+Remote_goal,-Answer_list)
    is simply findall evaluated completely on the remote machine.
    (Notice that it uses local space more efficiently than local findall
    does, as no database hacking is done at all.
*/
bag_of_all_servant1(Templ, Rgoal, Alist) :-
	sendterm(sat(Rgoal,Templ)),
	inremcall,
	recvterm(X),
	collect_answers(X, Alist1, []),
	outaremcall,
	Alist = Alist1.


/*  call_servant(+Rgoal)
    sends the goal Rgoal to the servant for evaluation.
*/
call_servant(Rgoal) :-
	free_variables(Rgoal, [], [], Vars),
	Template =.. [f|Vars],
	bag_of_all_servant1(Template, Rgoal, Alist),
	member(Template, Alist).


/*  inremcall and outaremcall
    keep track of whether a remote call is in progress.  If so, give an
    error if another is attempted.  This is used to prohibit nested
    remote calls.
*/


inremcall :-
	'$inremcall',
	write_sock_error(['Nested remote operations not allowed']),
	!,
	fail.
inremcall :-
	assert('$inremcall').

outaremcall :-
	retract('$inremcall'),
	!.

