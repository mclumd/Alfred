/* 
  file: carne.pl

______________________________
  dec 9 1998 
  to modify so that the following is possible: 
  a command that will be used to run the loop once, or any number of times.  
  the inputs to the kqml parser in that case will come form the keyboard.
  the point of this is so that it is possible to run carne from the qui
  interface, that so that it is possible to debug action code.

______________________________
  slave version of after aug 4 1998
  should be run as a separate process

  args: 'debug Fname' will print comments to Fname
        'sfile Fname' will write tcp info to Fname
	'actions Fname' will load an action file
	'init Fname' will load an initfile after the actions 
	'delay T' will add a delay of T to the loop


  should load the KQML code
  set up to look for KQML input at stdin if 'kqml'
  when has stuff to execute, calls 'process' and once that returns, sends
    back the success things. No need the extra arg.
  has a 'af' predicate that sends 'af(X)' back to alma that 

-------**
add these to the kqml file
copy stuff from some ~cfa/res/dialog/dm-110497/tdm1.pl
predicates for domain_pred1 and domain_pred2
comma([44|Rest],Rest).
-------**
*/
:- ensure_loaded(library(tcp)).
:- ensure_loaded(library(date)).
:- ensure_loaded(library(basics)).
:- ensure_loaded(library(lists)).
%:- ensure_loaded(kqml).
%:- ensure_loaded('/fs/that/cfa/res/dialog/dm/kqml1.pl').
%:- ensure_loaded('/tmp/kqml.pl').
%% load the kqml converter thing

:- dynamic failure/1.
:- dynamic tag/1.
:- dynamic debug/1.
:- dynamic sfile/1.
:- dynamic initfile/1.
:- dynamic delay/1.
:- dynamic almatag/1.
:- dynamic in_kqml/1.
:- dynamic debug_stream/1.
:- dynamic new_message/1.
:- dynamic new_message/2.
:- dynamic new_message_kv/2.
:- prolog_flag(fileerrors,_,on).
:- prolog_flag(syntax_errors,_,error).

%
% here we intialize things in the case of running at the keyboard.
% argument is a list of terms that is the same as the command-line
%  arguments one would want
%

qinitialize(L):-
    initialize,
    process_args(L),
    sfile(SF),
    tcp_listen(SF).

% do loop  once
%

qs:-
    debug(true), !,
    delay(T),
    debug_stream(DS),
    tcp_select(T, X),
    process(X),
    flush_output(DS),
    try_n_get_a_line_dbg(DS).
qs:-
    debug(false), !,
    delay(T),
    tcp_select(T, X),
    process(X),
    try_n_get_a_line_ndbg.
qs:- true.

try_n_get_a_line_ndbg:-
    get_a_line2([], Line),
    (in_kqml(false) -> shortcut(Line);  handle_kqml(Line)).
try_n_get_a_line_ndbg:- true.

try_n_get_a_line_dbg(DS):-
    get_a_line2([], Line),
    print(DS, 'Kqml'), 
    name(LL, Line), print(DS, LL), nl(DS),
    (in_kqml(false) -> shortcut(Line);  handle_kqml(Line)),
    debug_stream(NS),
    flush_output(NS).
try_n_get_a_line_dbg(_):- true.

%
% do loop n times
%

qs(0):- true.
qs(N):-
    M is N - 1,
    qs,
    qs(M).
    

/*
  this will set default values for arguments
*/

initialize:-
    assert(failure(false)),
    assert(sfile(tcpfile)),
    assert(debug(false)),
    assert(initfile(nul)),
    assert(delay(0.5)),
    assert(in_kqml(true)),
    assert(debug_stream(nil)),
    true.

go:-
    sfile(SF),
    tcp_listen(SF),
    (initfile(nul) -> true ; dump_init_file),
    tcp_watch_user(_, on),
    debug(true)-> loopv; loopnv.

% get the filename, print contents to stdout

dump_init_file:-
    initfile(X),
    dump_file(X).

dump_file(X):-
    open(X, read, S),
    set_input(S),
    repeat,
      get0(Z),
      put(Z),
      at_end_of_file, !,
    close(S).

/**
dump_init_file:-
    initfile(X),
    open(X, read, S),
    set_input(S),
    repeat,
      get0(Z),
      put(Z),
      at_end_of_file, !,
    close(S).
**/

loopv:-
    delay(T),
    debug_stream(DS),
    repeat,
%     nl(DS),
      tcp_select(T, X),
      process(X),
      debug_stream(NS),
      flush_output(NS),
    fail.


loopnv:-
    delay(T),
    repeat,
      tcp_select(T, X),
      process(X),
    fail.

process(connected(Tag)):- !,
    assert(almatag(Tag)).

% what is that one for???

process(term(_, quit)) :-
    halt.

process(term(_, X)):- 
    var(X), !.

% this is for kqml input
process(user_input):-
    handle_stdin.

% this is from alma
%darsana - June 27, 2003

print_stats(DS) :-
    statistics(memory,L),
    print(DS,memory), print(DS,L), nl(DS),
    fail.
print_stats(DS) :-
    statistics(global_stack,L),
    print(DS,global_stack), print(DS,L), nl(DS),
    fail.
print_stats(DS) :-
    statistics(local_stack,L),
    print(DS,local_stack), print(DS,L), nl(DS),
    fail.
print_stats(DS) :-
    statistics(atoms,L),
    print(DS,atoms), print(DS,L), nl(DS),
    fail.
print_stats(_).

process(term(Tag, TC)):- 
%    copy_term(T, TC),
    (debug(true) -> (debug_stream(DS), print(DS, 'Received: '), 
		     print(DS, TC), nl(DS), 
		     print_time(DS), print_stats(DS)); true),
    TC = call(C, A, X),
    passertall(A),
    (on_exception('alma-call-failure', call(C), fail_call)
    -> reply(Tag, TC, C, X); 
       reply_failed(Tag, TC, C, X)),
    pretractall(A),!.


process(term(Tag, T)):- 
%    copy_term(T, TC),
    (debug(true) -> (debug_stream(DS), print(DS, 'Received: '), 
		     print(DS, TC), nl(DS), print_time(DS)); true),
    T = call(C, X),
    (on_exception('alma-call-failure', call(C), fail_call)
    -> reply(Tag, T, C, X); reply_failed(Tag, T, C, X)),!.

process(timeout).

process(_, _).

process(_).

fail_call:-
    retract(failure(_)),
    assert(failure(true)).

reply(Tag, T, TC, K):-
    failure(false), debug(true), debug_stream(DS), !,
    print(DS, 'Sending '), print(DS, done(T, TC)), nl(DS),
    tcp_send(Tag, done(T, TC, K)).

reply(Tag, T, TC, K):-
    failure(false), debug(false), !,
    tcp_send(Tag, done(T, TC, K)).

reply(Tag, T, TC, K):-
    failure(true), debug(true), debug_stream(DS), !, 
    print(DS, error(T, TC, K)), nl(DS),
    tcp_send(Tag, error(T, TC, K)),
    retract(failure(_)),
    assert(failure(false)).

reply(Tag, T, TC, K):-
    failure(true), debug(false), !, 
    tcp_send(Tag, error(T, TC, K)),
    retract(failure(_)),
    assert(failure(false)).

reply_failed(Tag, T, TC, K):-
    debug(true) -> (debug_stream(DS), print(DS, failed(T, TC)), nl(DS), print_time(DS); true),
    tcp_send(Tag, failed(T, TC, K)).

% there is input at stdin (a kqml thing)
handle_stdin:-
    get_a_line2([], Line),
    (debug(true) -> debug_stream(DS), print(DS, 'Kqml'), 
     name(LL, Line), print(DS, LL), nl(DS), print_time(DS); true),
% here we parse and do whatever to the kqml
% for now do a shortcut:
    (in_kqml(false) -> shortcut(Line); handle_kqml(Line)).

% handle_kqml(X) :- !.

/*handle_kqml(X):-
    retractall(gathered_asserts(_)),
    assert(gathered_asserts([])),
    parse_kqml_perf_asserts(X, ID, Asserts),
    delete_gathered_asserts,
%CFA 020500 - note that code needs to be added to wipe these assertions from carne upon a "restart"
    assert(new_message(ID,Asserts)),
    af(new_message(ID)), !.*/

handle_kqml(_) :- print('Failed to parse KQML'), nl, !.

% this is modified from bpostow's code.

get_a_line2(Less, More) :- get_a_line(Less,More, 0).

get_a_line(Less,More, NUM) :- 
    prompt(_, ''),
    (get0(user_input, Char),
     (Char = 40 -> (append(Less, [Char] , Lesser), 
		    NN is NUM + 1,  
		    get_a_line(Lesser, More, NN));
     (Char = 41  -> (NN is NUM - 1,
		     (NN = 0 -> append(Less, [Char] , More);
		     append(Less, [Char] , Lesser), 
		     get_a_line(Lesser, More, NN))));
     ((Char = 10, NUM = 0) -> fail;
     (Char = 10 -> get_a_line(Less,More, NUM);
     (append(Less, [Char], Lesser),
      get_a_line(Lesser, More, NUM)))))).
            
% shortcut

shortcut(Line):-
    strip_end_parens(Line, S1),
%    print(S1), nl,
    name(short, S1), !,
    read(X),
    on_exception(_, call(X), you_dummy).
shortcut(_).

strip_end_parens([40|X], Y):-
    strip_last(X, Y).
strip_end(X, X).

strip_last(X, Y):-
    append(Y, [41], X).
strip_last(X, X).

you_dummy:-
    print('Get lost, dummy!'), nl.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% entry 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
runtime_entry(start):- 
    initialize,
    unix(argv(Args)),
%    print(Args), nl,
    process_args(Args),
    (debug(true)->  (debug_stream(DS), print(DS, 'Args: '), print(DS, Args));
    true),
    go.

debugcarne(Args):- 
    initialize,
%    unix(argv(Args)),
%    print(Args), nl,
    process_args(Args),
    (debug(true)->  (debug_stream(DS), print(DS, 'Args: '), print(DS, Args));
    true),
    go.




/*
List of arguments:

sfile X
X is the file into which to write connection information for the alma
Default: none

load X
X is the file that contains the actions.
Default: none

init X
X is the name of the file that contains text that is to be spewed onto
stdout on startup.
Default: none

delay X
X is a real number
Default: 0.1

debug Fname
Fname is the name of the debug dump file

inkqml X
X is true or false. True means to parse all input as KQML.
Defaule: true

*/

/*

++++++++beginning of mail++++++++++++++++

the kqml code is kqml.pl.  I actually think my comments
in it are unusually helpful, so take a look and let me know if they're
confusing.

The KQML assertions we need to have made in ALMA are all the assertions
necessary to represent the message in BOTH of the formats discussed at the
top of the code.  My old DM code (~cfa/res/dialog/dm/tdm1.pl) does just
that - look for the procedure "getmsg" in it.

SO these assertions will be (borrowing the example in the kqml code)

kqml_expr(1,[tell,:sender,dave,:receiver,sally,:content,2])
kqml_expr(2,[3])
kqml_expr(3,Howdy)
kqml_head(tell),
kqml_kv(1,[:sender,dave])
kqml_kv(1,[:receiver,sally])
kqml_kv(1,[:content,2])

Plus, we need an assertion "newmsg(ID)" to announce that there is a new
msg.

++++++++++end of mail++++++++++

getmsg(ID) :-
repeat,
gram4:get_a_line(user_input,[],Out),
parse_kqml_perf(Out,ID),
convert_keyvals1(ID), !,
convert_keyvals2(ID), !.


*/


process_args([]).

process_args([help | X]):-
    dump_file('./carnehelp'), halt.


process_args([sfile, X|Y]):-
    retract(sfile(_)),
    assert(sfile(X)),
    process_args(Y).

process_args([load, X|Y]):-
    load_files(X),
    process_args(Y).

process_args([init, X|Y]):-
    retract(initfile(_)),
    assert(initfile(X)),
    process_args(Y).

process_args([delay, X|Y]):-
    retract(delay(_)),
%    assert(delay(X)),
    assert(delay(0.5)),
    process_args(Y).

process_args([debug, X|Y]):-
    retract(debug(_)),
    assert(debug(true)),
    retract(debug_stream(_)),
    open(X, write, S),
    assert(debug_stream(S)),
    process_args(Y).

process_args([inkqml, X|Y]):-
    retract(in_kqml(_)),
    assert(in_kqml(X)),
    process_args(Y).

% default 
process_args([X|Y]):-
    process_args(Y).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% these few should not be used, i think
debug_or_not(Args):-
    member(debug, Args),
    retract(debug(_)),
    assert(debug(true)).

set_tcp_fname(Args):-
    nth0(N, Args, sfile), !,
    N1 is N + 1,
    nth0(N1, Args, F),
    print('asserted '), print(F),
    assert(sfile(F)).
set_tcp_fname(Args):-
    print('asserted sfile'), nl,
    assert(sfile(sfile)).

set_tcp_fname(_).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

af(X):-
    almatag(T),
    (debug(true)-> debug_stream(DS), 
     print(DS, 'Sending '), print(DS, af(X)), nl(DS), print_time(DS); true),
    tcp_send(T, af(X)).

df(X):-
    almatag(T),
    (debug(true)-> debug_stream(DS), 
     print(DS, 'Send '), print(DS, df(X)), nl(DS), print_time(DS); true),
    tcp_send(T, df(X)).

%
% cdebug(+X), where X is a term corresponding to a pathname (with trailing
%  slash), will close the current debug file if any, then continue the
%  debug trace in a file called Carne in the directory indicated by X.
%
cdebug(X):-
    debug(true), !,
    retract(debug_stream(DS)),
    close(DS),
    name(X, NX),
    append(NX, "Carne", NY),
    name(NNY, NY),
    open(NNY, write, S),
    assert(debug_stream(S)).

cdebug(X):-
    debug(_), !.
/*
    retract(debug_stream(_)),
    retract(debug(false)),
    assert(debug(true)),
    name(X, NX),
    append(NX, "Carne", NY),
    name(NNY, NY),    
    open(NNY, write, S),
    assert(debug_stream(S)).
  */  


print_time(SS):-
    tcp:tcp_now(timeval(Seconds, MicroSeconds)),
    tcp_date_timeval(Date,timeval(Seconds, MicroSeconds)),
    time_stamp(Date,'%02c:%02i:', Stamp),
    Date = date(_, _, _, _, _, S),
    name(S, NSec),
    name(MicroSeconds, Nmicro),
    name(Stamp, NS),
    append(NS, NSec, NN),
    append(NN, [58|Nmicro], XCX),
    name(Stamps, XCX),
    print(SS, Stamps), nl(SS).

%The gathered_asserts mechanism is intended to track and delete
%assertions made in the course of execution of a carne script.  The
%predicate gathered_asserts is used to track these assertions, which
%are deleted at the end of the carne call code (above).
%We make an exception for new_message_kv, as we want to keep these
%assertions in carne.
/*
delete_gathered_asserts :-
gathered_asserts(Asserts),
delete_all(Asserts).
delete_gathered_asserts.

delete_all([new_message_kv(ID,_)|Asserts]) :-
delete_all(Asserts).
delete_all([new_message_kv(ID)|Asserts]) :-
delete_all(Asserts).
delete_all([A|Asserts]) :-
retractall(A),
delete_all(Asserts).
delete_all([]).
   
*/ 
%used to assert formulas which are not to be passed on to alma
%if Var is uninstantiated do nothing.
passertall(Var) :-
    var(Var).

passertall([A|Asserts]) :-
    passert(A),  
    passertall(Asserts).
passertall([]).

passert(Form) :-
    (clause(Form,true);
    assert(Form)).

% do nothing for now
pretractall([A|Asserts]) :-
    pretract(A),
    pretractall(Asserts).
pretractall([]).

pretract(Form) :-
    (retractall(Form);
    true).








