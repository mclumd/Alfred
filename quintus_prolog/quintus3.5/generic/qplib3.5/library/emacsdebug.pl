/*  SCCS   : @(#)emacsdebug.pl	1.1 04/06/99
    File   : emacsdebug.pl
    Authors: Peter Schachte
    Purpose: Source-linked debugger (Emacs version)
    Origin : January 1999

        +--------------------------------------------------------+
        | WARNING: This material is CONFIDENTIAL and proprietary |
        |          to the Swedish Institute of Computer Science. |
        |                                                        |
        |  Copyright (C) 1999 Swedish Institute of Computer      |
	|  Science.  All rights reserved.                        |
        |                                                        |
        +--------------------------------------------------------+
*/

:- module(emacs_debug, [
	emacs_debugger/2,
	window_format/2,
	window_format/3
%	initial_trace_state/1
   ]).

:- use_module(library(basics)).
:- use_module(library(files)).
:- use_module(library(directory)).
:- use_module(library(lineio)).
:- use_module(library(types)).
:- use_module(library(unix)).
%% [PM] 3.5 these two used to be duplicated in gnu3.4/ and qui/
:- use_module(library(srcpos)).
:- use_module(library(showport)).

user:(:- multifile message_hook/3).

:- dynamic
	frame_depth/1,
	current_debugger_extra_windows/1,
	loaded_file/2,
	no_source_pos/3,
	currently_open/1,
	current_window_format/2,
	selection/4,
	temp_file/1.



/*****************************************************************
			Debugging the Debugger

This code implements a crude Byrd box debugger for debugging the
debugger itself.  The idea is you put '***' at the beginning of any
goal you want traced.  When the goal is executed, it will be printed
following a '>'; when it exits, the goal is again printed after a '<';
when the goal is retried, after a ')'; on failure, a '('.  There is
no leashing.  Good luck.

*****************************************************************/

:- op(999, fy, (***)).

***(G) :-
	(   write('> '),
	    write(G), nl
	;   write('( '),
	    write(G), nl,
	    fail
	),
	G,
	(   write('< '),
	    write(G), nl
	;   write(') '),
	    write(G), nl,
	    fail
	).

/****************************************************************
		Turning on and off the Emacs debugger
****************************************************************/

%  emacs_debugger(-Before, +After)
%  If After is 'on', then use the emacs source linked debugger for
%  debugging.  If it is 'off', then use the usual debugger.  Before is
%  bound to 'on' if before this call the emacs debugger was being
%  used, otherwise it is 'off'.  This can be called as:
%  emacs_debugger(State, State) to find out which debugger is being
%  used without changing it.

emacs_debugger(Before, After) :-
	(   '$Quintus: debugger'(X, X),
	    X = emacs_debug:emacs_debugger ->
		Before = on
	;   Before = off
	),
	(   var(After) ->
		raise_exception(instantiation_error(
			emacs_debugger(Before, After), 2))
	;   After == on, Before == off ->
		'$Quintus: debugger'(_, emacs_debugger)
	;   After == off, Before == on ->
		'$Quintus: debugger'(_, standard)
	;   true
	).




/****************************************************************
			   Talking to Emacs
****************************************************************/

% Cmds is a list of atoms and/or lists of character codes.  Paste them
% together and execute them as an Emacs command (or several).

emacs_exec(Cmds) :-
	must_be(proper_list, Cmds, 1, emacs_exec(Cmds)),
	put(30),
	put_cmds(Cmds),
	put(29).

put_cmds([]) :- !.
put_cmds([Cmd|Cmds]) :-
	!,
	(   Cmd = [N|_], integer(N) ->
		put_chars(Cmd)
	;   write(Cmd)
	),
	put_cmds(Cmds).


% Put a message in the Emacs message window

emacs_msg(Msg) :-
	append(Msg, ['")'], Tail),
	emacs_exec(['(&qp-message "'|Tail]).


% Put a message in the Emacs message window

emacs_error(Msg) :-
	append(Msg, ['")'], Tail),
	emacs_exec(['(&qp-error "'|Tail]).


% Load a file into the source debugger window.

load_source(Filename) :-
	emacs_exec(['(prolog-debug-source "', Filename, '")']).


% Load a non-source file into the source debugger window.

load_no_source(Filename) :-
	emacs_exec(['(prolog-debug-no-source "', Filename, '")']).


% Load a file into a debugger window.  If Append is `true', don't
% clear the window first.

load_other_window(Window, Filename, Append) :-
	(   Append == true ->
		Ap = "t"
	;   Ap = "nil"
	),
	emacs_exec(['(prolog-debug-extra ''', Window, ' "', Filename,
	            '" ', Ap, ')']).


% Make the source debugger window point to the specified port.  Start
% and End delimit the current goal or clause head.  Alternate
% indicates the start of the next clause to try for a head port.
% Depth and Port describe the current debugger port.  Module, Name and
% Arity specify the pred being called.  Extra1 and Extra2 give info
% about what type of pred is being called and whether or not we are at
% a spypoint.

show_source(Start, End, Alternate, Depth, Port, Module, Name, Arity, Extra1, Extra2) :-
	emacs_exec(['(prolog-debug-port ', Start, ' ', End, ' ',
		      Alternate, ' ', Depth, ' ''', Port, ' "', Module,
		      '" "', Name, '" ', Arity, ' "', Extra1, 
		      '" "', Extra2, '")']).

/****************************************************************
			 The Actual Debugger
****************************************************************/

% Entry point when Prolog reaches a debugger port.  DEBUG is an opaque
% datastructure carrying info needed for many debugger operations.
% Tracestate0 is the tracing state we're in on reaching this port;
% Tracestate is the trace state selected for this port.

emacs_debugger(DEBUG, TraceState0, TraceState) :-
	ensure_debugger_is_open,
	(   '$Quintus: query_debugger'(should_leash, DEBUG) ->
		emacs_debugger_interaction(DEBUG, first, TraceState0,
	   		TraceState)
  	;   currently_open(standard) ->
		update_other_window(standard, DEBUG, DEBUG, first, _),
		fail			% debugger will decide what to do
	;   fail			% debugger will decide what to do
	).

emacs_debugger_interaction(TOPDEBUG, Arrival, TraceState0, TraceState) :-
%	retractall(selection(_,_,_,_)),		% remove old selection
	selection_sensitivity,
	emacs_debugger_interaction1(TOPDEBUG, Arrival, TraceState0,
		TraceState).
                              %% What about an abort ????

emacs_debugger_interaction1(TOPDEBUG, Arrival, TraceState0, TraceState) :-
	update_source_window(TOPDEBUG, DEBUG, Aux),
	update_other_windows(DEBUG, TOPDEBUG, Arrival, Aux),
	await_reply(DEBUG, TOPDEBUG, TraceState0, TraceState, Aux).

show_source(Caller, Clausenum0, Called, Callnum, DEBUG, Clause, Call, Vars) :-
	\+ '$Quintus: query_debugger'(
			predicate_property(Caller,(dynamic)), DEBUG),
	'$Quintus: query_debugger'(source_file(Caller,Clausenum0,File), DEBUG),
	'$Quintus: query_debugger'(source_file(Caller,FirstInFile,File),
				   DEBUG),
					% hack:  source_file/3 returns clauses
					% in order
	Clausenum is Clausenum0-FirstInFile+1,
	call_source_position(File, Caller, Clausenum, Called, Callnum,
			     Clause, Call, Vars, Start1, End1, _, _),
	Start is Start1 + 1,
	End is End1 + 1,
	% If we get here, File exists and is readable !!
	maybe_load_file(File, DEBUG),
	'$Quintus: query_debugger'(port(Port0), DEBUG),
	figure_port(Port0, FirstInFile, File, Caller, DEBUG, Port, Alternate),
	show_position(Start, End, Alternate, Port, DEBUG),
	!.
show_source(_, _, _, _, DEBUG, 0, 0, []) :-	% 0 means no source linkage
	show_no_source(DEBUG).


show_no_source(DEBUG) :-
	'$Quintus: query_debugger'(goal(Goal), DEBUG),
	open_temp_stream(Stream, Name),
	'$Quintus: query_debugger'(port(Port), DEBUG),
	(   Port \== 'Head' ->
		write(Stream, '... :- '),
		Start = 8
	;   Start = 1
	),
	window_format(source, Format),
	write_term(Stream, Goal, Format),
	character_count(Stream, End1),
	(   Port == 'Head' -> write(Stream, ' :- ...')
	;   true
	),
	End is End1 + 1,
	put(Stream, 0'.), nl(Stream),
	close(Stream),
	load_temp_file(Name),
	get_mod_prefixed_skel(Goal, Pred),
	retractall(no_source_pos(_,_,_)),
	assert(no_source_pos(Start,End,Pred)),
	show_position(Start, End, -1, Port, DEBUG).

get_mod_prefixed_skel(Mod:Goal, Mod:Pred) :-
	!,
	get_mod_prefixed_skel(Goal, Pred).
get_mod_prefixed_skel(Goal, Pred) :-
	functor(Goal, Name, Arity),
	functor(Pred, Name, Arity).


predspec(Mod:Goal, _, Pred) :-
	!,
	predspec(Goal, Mod, Pred).
predspec(Goal, Mod, Mod:Name/Arity) :-
	functor(Goal, Name, Arity).


show_position(Start, End, Alternate, Port, DEBUG) :-
	'$Quintus: query_debugger'(depth(Depth), DEBUG),
	'$Quintus: query_debugger'(predicate(Pred), DEBUG),
	Pred = Module0:Name/Arity,
	(   Module0 == user -> Module = ''
	;   Module = Module0
	),
	functor(Goal, Name, Arity),
	choose_extras(Module0, Goal, DEBUG, Extra1, Extra2),
	show_source(Start, End, Alternate, Depth, Port, Module, Name,
		Arity, Extra1, Extra2).

choose_extras(Module, Goal, DEBUG, Extra1, Extra2) :-
	Mgoal = Module:Goal,
	(   proper_extra(Extra1),
	    '$Quintus: query_debugger'(
			predicate_property(Mgoal, Extra1), DEBUG) ->
		true
	;   \+ '$Quintus: query_debugger'(
			current_predicate(_,Mgoal), DEBUG) ->
		Extra1 = undefined
	;   Extra1 = ''
	),
	(   '$Quintus: query_debugger'(skipped_invocation, DEBUG) ->
		Extra2 = skipped
	;   '$Quintus: query_debugger'(
			predicate_property(Mgoal, spied), DEBUG) ->
		Extra2 = spied
	;   Extra2 = ''
	).

figure_port('Head', Firstinfile, File, Caller, DEBUG, Port, Alternate) :-
	!,
	'$Quintus: query_debugger'(next_clause(Altclause), DEBUG),
	(   Altclause == none ->
		Port = 'LastHead',
		Alternate = -1
	;   Altclause == fail ->
		Port = 'Head',
		Alternate = -1
	;   '$Quintus: query_debugger'(
			source_file(Caller, Altclause, Altfile), DEBUG),
	    Altfile == File ->
		Fileclause is Altclause-Firstinfile+1,
		call_source_position(File, Caller, Fileclause, Alternate, _),
		Port = 'Head'
	;   % alternate clause is in a different file !
	    % don't show an alternate arrow (what else can we do?)
		Port = 'Head',
		Alternate = -1
	).
figure_port(Port, _, _, _, _, Port, -1).

update_source_window(TOPDEBUG, DEBUG, Aux) :-
	get_chosen_frame(TOPDEBUG, DEBUG),
	(   '$Quintus: query_debugger'(
			call(M:N/A,Clausenum,Cm:Cn/Ca,Callnum), DEBUG) ->
		functor(Caller, N, A),
		functor(Called, Cn, Ca),
		show_source(M:Caller, Clausenum, Cm:Called, Callnum, DEBUG,
			Clause, Call, Vars),
		Module = Cm
	;   '$Quintus: query_debugger'(caller(M:N/A,Clausenum), DEBUG) ->
		functor(Caller, N, A),
		show_source(M:Caller, Clausenum, head, 0, DEBUG, Clause,
			Call, Vars),
		Module = M
	;   show_no_source(DEBUG),
	    Call = 0, Module = 0		% signify no source linkage
	),
	(   Call == 0 -> Call1 = 0
	;   Call1 = Module:Call
	),
	aux_term(Clause, Call1, Vars, Aux).


aux_term(Clause, Call, Vars, aux(Clause,Call,Vars)).


update_other_windows(DEBUG, TOPDEBUG, Arrival, Aux) :-
	(   currently_open(W),
%	    auto_reshow(W),
	    update_other_window(W, DEBUG, TOPDEBUG, Arrival, Aux),
	    fail
	;   true
	).

update_other_window(source, _, _, _, _).
update_other_window(bindings, DEBUG, _, _, Aux) :-
	aux_term(Clause, Call, Vars, Aux),
	window_format(bindings, Format),
	extra_output_stream(bindings, Stream, Name),
	(   Call == 0 ->			% not source linked
		write(Stream, 'No source linking'),
		nl(Stream)
	;   '$Quintus: query_debugger'(goal(Goal), DEBUG),
	    match_goals(Call, Goal, Clause, DEBUG) ->
		write_bindings(Vars, Stream, Format)
	;   write(Stream, 'Goal and Source don''t unify'),
	    nl(Stream)
	),
	close(Stream),
	load_other_window(bindings, Name, false).
update_other_window(standard, _, TOPDEBUG, Arrival, _) :-
	(   Arrival == first, TOPDEBUG \== 0 ->
		window_format(standard, Format),
		extra_output_stream(standard, Stream, Name),
		show_port(Stream, Format, TOPDEBUG),
		nl(Stream),
		close(Stream),
		load_other_window(standard, Name, true)
	;   true					% nothing for frame up
	).
update_other_window(ancestors, _, TOPDEBUG, Arrival, _) :-
	window_format(ancestors, Format),
	(   Arrival == first ->
		extra_output_stream(ancestors, Stream, Name),
		show_ancestors(Stream, Format, TOPDEBUG),
		close(Stream),
		load_other_window(ancestors, Name, false)
	;   true					% nothing for frame up
	).
update_other_window(choicepoints, _, _TOPDEBUG, _Arrival, _) :-
	true.					  % choicepoints window 
						  % not yet implemented
%	(   Arrival == first ->
%		extra_output_stream(choicepoints, Stream),
%		show_choicepoints(Stream, print, TOPDEBUG),
%		nl(Stream),
%		close(Stream)
%	;   true					% nothing for frame up
%	).


auto_reshow(bindings).
auto_reshow(standard).

write_bindings([], _, _).
write_bindings([Name=Val|Bindings], Stream, Format) :-
	write(Stream, Name), write(Stream, ' = '),
	write_term(Stream, Val, Format),
	nl(Stream),
	write_bindings(Bindings, Stream, Format).


match_goals(Call0, Goal0, Clause0, DEBUG) :-
	Call0 = _:Call,
	(   Goal0 = _:Goal -> true
	;   Goal = Goal0
	),
	functor(Call, _, Arity),
	(   '$Quintus: query_debugger'(port('Head'), DEBUG) ->
		Call = Goal
	;   '$Quintus: query_debugger'(
		predicate_property(Call0,meta_predicate(Spec)), DEBUG) ->
		'$Quintus: query_debugger'(caller(Cm:Cn/Ca,_), DEBUG),
		functor(Caller, Cn, Ca),
		(   '$Quintus: query_debugger'(predicate_property(Cm:Caller,
				meta_predicate(Callerspec)),
			    DEBUG) ->
			clause_head(Clause0, Head),
			functor(Head, _, Callerarity),
			collect_meta_var_args(Callerarity, Callerspec, Head,
				Metas)
		;   Metas = []
		),
		meta_unify_args(Arity, Spec, Call, Goal, Metas)
	;   Call = Goal
	).


clause_head(_:Clause, Head) :-
	!,
	clause_head(Clause, Head).
clause_head((Head:-_), Head) :-
	!.
clause_head(Head, Head).


collect_meta_var_args(N, Spec, Head, L) :-
	(   N =:= 0 -> L = []
	;   (   arg(N, Head, Headarg),
		var(Headarg),
		arg(N, Spec, Specarg),
		arg_to_be_expanded(Specarg) ->
		    L = [Headarg|L1]
	    ;   L = L1
	    ),
	    N1 is N-1,
	    collect_meta_var_args(N1, Spec, Head, L1)
	).

meta_unify_args(N, Spec, Call, Goal, Metas) :-
	(   N =:= 0 -> true
	;   arg(N, Spec, Specarg),
	    arg(N, Call, Callarg),
	    arg(N, Goal, Goalarg),
	    meta_unify_one(Specarg, Callarg, Goalarg, Metas),
	    N1 is N-1,
	    meta_unify_args(N1, Spec, Call, Goal, Metas)
	).

meta_unify_one(Specarg, Callarg, Goalarg, Metas) :-
	(   arg_to_be_expanded(Specarg),
	    \+ already_expanded(Callarg, Metas) ->
		Goalarg = _:Callarg
	;   Callarg = Goalarg
	).

arg_to_be_expanded(:) :- !.
arg_to_be_expanded(I) :- integer(I), I >= 0.

already_expanded(X, Already) :-
	(   var(X) ->
		var_member(X, Already)
	;   functor(X,(:),2)
	).

var_member(X, [Y|_]) :- X == Y, !.
var_member(X, [_|L]) :- var_member(X,L).


window_format(Window, Format) :-
	(   nonvar(Window) -> get_window_format(Window, Format)
	;   debugger_window(Window),
	    (   current_window_format(Window, Format) -> true
	    ;   default_window_format(Format)
	    )
	).

window_format(Window, Old, New) :-
	(   var(Window) ->
		raise_exception(
			instantiation_error(window_format(Window,Old,New), 1))
	;   debugger_window(Window) ->
		(   current_window_format(Window, Old) -> true
		;   default_window_format(Old)
		),
		(   Old == New -> true
		;   format_parts(New, Window, Old, New, 0, Toggles, 0, Depth),
		    build_format(Toggles, Depth, New1),
		    retractall(current_window_format(Window,_)),
		    assert(current_window_format(Window, New1))
		)
	;   atom(Window) ->
		raise_exception(type_error(window_format(Window,Old,New), 1,
			'debugger window', Window))
	;   raise_exception(domain_error(window_format(Window,Old,New), 1,
		    'debugger window', Window))
	).
	

get_window_format(Window, Format) :-
	(   debugger_window(Window) ->
		(   current_window_format(Window, Format) -> true
		;   default_window_format(Format)
		)
	;   raise_exception(domain_error(window_format(Window,Format), 1,
		    'debugger window', Window))
	).

default_window_format([quoted(true), portrayed(true), max_depth(5)]).

format_parts([], _, _, _, Toggles, Toggles, Max, Max).
format_parts([Term|Terms], Window, Old, New, Toggles0, Toggles, Max0, Max) :-
	one_format_part(Term, Window, Old, New, Toggles0, Toggles1,
		Max0, Max1),
	format_parts(Terms, Window, Old, New, Toggles1, Toggles, Max1, Max).

one_format_part(max_depth(Max), Window, Old, New, Toggles, Toggles, _, Max) :-
	(   integer(Max) -> true
	;   raise_exception(domain_error(window_format(Window,Old,New), 3,
		    integer, Max))
	).
one_format_part(Bool, Window, Old, New, Toggles0, Toggles, Max, Max) :-
	(   bool_printmode_bit(Bool, Value, Mask) ->
		(   var(Value) -> raise_exception(instantiation_error(0,3))
		;   Value == true -> Toggles is Toggles0 \/ Mask
		;   Value == false -> Toggles = Toggles0
		;   raise_exception(domain_error(window_format(Window,Old,New),3,
				'on/true or off/false',Value))
		)
	;   raise_exception(domain_error(window_format(Window,Old,New),3,
		    'write_term option',Value))
	).


build_format(Toggles, Max, [max_depth(Max)|Format]) :-
	bagof(Term, printmode_bit_on(Term, Toggles), Format).

printmode_bit_on(Term, Toggles) :-
	bool_printmode_bit(Term, true, Mask),
	0 =\= Toggles /\ Mask.


% Assumes file exists and is readable !!
maybe_load_file(File, DEBUG) :-
	(   loaded_file(File, Date),
	    file_property(File, modify_time, Date) ->
		true
	;   load_source(File),
	    file_property(File, modify_time, Date),
	    show_spypoints(File, DEBUG),
	    retractall(loaded_file(_,_)),
	    assert(loaded_file(File,Date)),
	    retractall(no_source_pos(_,_,_))
	).

load_temp_file(File) :-
	load_no_source(File),
	retractall(loaded_file(_,_)),
	retractall(no_source_pos(_,_,_)).


show_spypoints(_File, _DEBUG) :-
	true.
% 	(   '$Quintus: query_debugger'(spied(Spied), DEBUG),
% 	    spy_place_in_file(Spied, File, DEBUG, Start),
% 	    update_spypoint(Start, 0),
% 	    fail
% 	;   true
% 	).
% 
% spy_place_in_file(call(Caller,Clausenum0,Called,Callnum), File, DEBUG,
% 		Start) :-
% 	'$Quintus: query_debugger'(source_file(Caller,Clausenum0,File), DEBUG),
% 	'$Quintus: query_debugger'(source_file(Caller,FirstInFile,File), DEBUG),
% 	!,				% hack:  source_file/3 returns clauses
% 					% in order
% 	Clausenum is Clausenum0-FirstInFile+1,
% 	call_source_position(File, Caller, Clausenum, Called, Callnum,
% 			     _, _, _, Start, _, _, _).
% spy_place_in_file(predicate(Pred), File, DEBUG, Start) :-
% 	'$Quintus: query_debugger'(source_file(Pred,File), DEBUG),
% 	call_source_position(File, Pred, Start, _).
% 
%show_ancestors(Stream, Style, DEBUG) :-
%	window_scroll_position(ancestors, Offset, Lines),
%%	Offset = 0, Lines = 100000,		% till scrolling works
%	(   '$Quintus: query_debugger'(port('Head'), DEBUG),
%	    '$Quintus: query_debugger'(parent(CALLER), DEBUG) ->
%		show_ancestors(Stream, Style, Offset, Lines, CALLER),
%		'$Quintus: query_debugger'(depth(Depth), CALLER)
%	;   show_ancestors(Stream, Style, Offset, Lines, DEBUG),
%	    '$Quintus: query_debugger'(depth(Depth), DEBUG)
%	),
%	set_window_scroll_range(ancestors, Depth, Lines).
%
%show_ancestors(Stream, Style, Offset, Lines, DEBUG) :-
%	(   Offset =< 0 ->
%		show_ancestors(Stream, Style, Lines, DEBUG)
%	;   '$Quintus: query_debugger'(parent(CALLER), DEBUG) ->
%		Offset1 is Offset-1,
%		show_ancestors(Stream, Style, Offset1, Lines, CALLER)
%	;   true
%	).
%
%show_ancestors(Stream, Style, Lines, DEBUG) :-
%	(   Lines =< 0 -> true
%	;   show_port(Stream, Style, '', DEBUG),
%	    nl(Stream),
%	    (   '$Quintus: query_debugger'(parent(CALLER), DEBUG) ->
%		    Lines1 is Lines-1,
%		    show_ancestors(Stream, Style, Lines1, CALLER)
%	    ;   true
%	    )
%	).

show_ancestors(Stream, Style, DEBUG) :-
	(   '$Quintus: query_debugger'(port('Head'), DEBUG),
	    '$Quintus: query_debugger'(parent(CALLER), DEBUG) ->
		show_ancestors1(Stream, Style, CALLER)
	;   show_ancestors1(Stream, Style, DEBUG)
	).

show_ancestors1(Stream, Style, DEBUG) :-
	show_port(Stream, Style, '', DEBUG),
	nl(Stream),
	(   '$Quintus: query_debugger'(parent(CALLER), DEBUG) ->
		show_ancestors1(Stream, Style, CALLER)
	;   true
	).


show_choicepoints(Stream, _Style, _DEBUG) :-
	write(Stream, 'this is the choicepoints window'),
	nl(Stream).

await_reply(DEBUG, TOPDEBUG, TraceState0, TraceState, Aux) :-
%	frame_depth(FrameDepth),
%	'$Quintus: query_debugger'(depth(InvocDepth), DEBUG),
%	open_window(source),
%	await_buttonpress(InvocDepth, FrameDepth, Commandnum),
%	analyze_command(Commandnum, Command, Window),
	get_emacs_command(Command, Window),
	(   Window == source,
	    translate_command(Command, DEBUG, TraceState) ->
		set_frame_depth(0, DEBUG),
		retractall(selection(_,_,_,_)),
		selection_sensitivity
	;   handle_reshow_command(Command, DEBUG, TOPDEBUG) ->
		emacs_debugger_interaction1(TOPDEBUG, reshow, TraceState0,
			TraceState)
	;   handle_command(Command, Window, DEBUG, TOPDEBUG, Aux) ->
		await_reply(DEBUG, TOPDEBUG, TraceState0, TraceState, Aux)
	;   emacs_error(['Command not understood']),
	    await_reply(DEBUG, TOPDEBUG, TraceState0, TraceState, Aux)
	).



get_emacs_command(Command, Window) :-
	emacs_exec(['(prolog-debug-waiting)']),
	prompt(Old, ''),
	get0(Cmdchar),
	get0(Winchar),
	prompt(_, Old),
	(   kill_line,
	    char_window(Winchar, Window),
	    char_command(Cmdchar, Command) ->
		true
	;   emacs_error(['invalid debugger command']),
	    get_emacs_command(Command, Window)
	).

char_window(0'!, source).
char_window(0'b, bindings).
char_window(0's, standard).
char_window(0'a, ancestors).
char_window(0'c, choicepoints).

char_command(0'a, abort).
char_command(0'b, break).
char_command(0'c, creep).
char_command(0'f, fail).
char_command(0'l, leap).
char_command(0'n, nonstop).
char_command(0'q, quasi_skip).
char_command(0'r, retry).
char_command(0's, skip).
char_command(0'w, open_window).
char_command(0'x, close_window).
char_command(0'z, zip).
% char_command(0'., edit_source).
char_command(0'[, frame_up).
char_command(0'], frame_down).
char_command(0'|, frame_back).
char_command(0'+, spy_here).
char_command(0'-, nospy_here).
char_command(0'=, debugging).
char_command(0' , creep).
char_command(10 , creep).
char_command(13 , creep).

kill_line :-
	get0(Ch),
	(   Ch =:= 10 ->
		true
	;   kill_line
	).


%  ENTRY POINT FROM C:
%  This proc handles debugger commands when not debugging.  Of course,
%  some commands (e.g., creep) won't work then, but this handles the
%  ones that will.
% 
% :- extern(debugger_command(+integer)).
% 
% debugger_command(Commandnum) :-
% 	analyze_command(Commandnum, Command, Window),
% 	handle_command(Command, Window, 0, 0, 0).
% 
% 
% analyze_command(Num, Command, Window) :-
% 	Windownum is Num>>8,			% NB:  this must be kept 
% 	Commandnum is Num/\255,			% consistant with
% 	window_name(Windownum, Window),		% NUM_POSSIBLE_COMMANDS in
% 	command_name(Commandnum, Command).	% qdebug.c


translate_command(skip, DEBUG, skip(I)) :-
	'$Quintus: query_debugger'(invocation(I), DEBUG).
translate_command(fail, DEBUG, fail(I)) :-
	'$Quintus: query_debugger'(invocation(I), DEBUG).
translate_command(retry, DEBUG, retry(I)) :-
	'$Quintus: query_debugger'(invocation(I), DEBUG).
translate_command(quasi_skip, DEBUG, quasi_skip(I)) :-
	'$Quintus: query_debugger'(invocation(I), DEBUG).
translate_command(creep, _, creep).
translate_command(leap, _, leap).
translate_command(zip, _, zip).
translate_command(backup, _, backup).
translate_command(nonstop, _, nonstop).
translate_command(abort, _, abort).
% translate_command(quit_debugger, _, nonstop) :-
% 	prolog_flag(debugging, _Old, off).
% translate_command(closed, _, nonstop) :-	% user closed source window
% 	prolog_flag(debugging, _Old, off).


handle_reshow_command(frame_back, _, TOPDEBUG) :-
	set_frame_depth(0, TOPDEBUG).
handle_reshow_command(frame_up, _, TOPDEBUG) :-
	increment_frame_depth(1, TOPDEBUG).
handle_reshow_command(frame_down, _, TOPDEBUG) :-
	increment_frame_depth(-1, TOPDEBUG).


handle_command(open_window, Window, DEBUG, TOPDEBUG, Aux) :-
	open_window(Window, DEBUG, TOPDEBUG, Aux).
handle_command(close_window, Window, _, _, _) :-
	close_window(Window).
% handle_command(open, _, _, _, _) :-
% 	viewable_source_files(Choices),
% 	initiate_file_selection(Choices).
% handle_command(load_file, _, DEBUG, _, _) :-
% 	get_selected_file(File),
% 	on_exception(_,
% 		absolute_file_name(File, [access(read)], _),
% 		fail),
% 	maybe_load_file(File, DEBUG).
% handle_command(edit_source, _, _, _, _) :-
% 	loaded_file(File, _),
% 	edit_file(File).
handle_command(break, _, _, _, _) :-
	break.
% handle_command(leashing_window, _, DEBUG, _, _) :-
% 	'$Quintus: query_debugger'(leashing(Old), DEBUG),
% 	leashing_to_number(Old, 0, Oldint),
% 	await_leashing(Oldint, Newint),
% 	number_to_leashing(Newint, New),
% 	'$Quintus: command_debugger'(leashing(New), DEBUG).
% handle_command(spypoints_window, _, _, _, _) :-
% 	fail.
% handle_command(top_creep, _, _, _, _) :-
% 	prolog_flag(debugging, _, creep).
% handle_command(top_leap, _, _, _, _) :-
% 	prolog_flag(debugging, _, leap).
% handle_command(top_zip, _, _, _, _) :-
% 	prolog_flag(debugging, _, zip).
handle_command(spy_here, _Window, DEBUG, _TOPDEBUG, _Aux) :-
	handle_spy_nospy(spy(Where), Where, spy, DEBUG).
handle_command(nospy_here, _Window, DEBUG, _TOPDEBUG, _Aux) :-
	handle_spy_nospy(nospy(Where), Where, nospy, DEBUG).
handle_command(debugging, _Window, _DEBUG, _TOPDEBUG, _Aux) :-
	debugging.				  % this should probably use
						  % command_debugger somehow
% handle_command(spy_goal, _, DEBUG, _, _) :-
% 	selection(Pred,Clausenum,Called,Callnum),
% 	Callnum > 0,			% must not be head
% 	'$Quintus: command_debugger'(
% 		spy(call(Pred,Clausenum,Called,Callnum)), DEBUG).
% handle_command(nospy_goal, _, DEBUG, _, _) :-
% 	selection(Pred,Clausenum,Called,Callnum),
% 	Callnum > 0,			% must not be head
% 	'$Quintus: command_debugger'(
% 		nospy(call(Pred,Clausenum,Called,Callnum)), DEBUG).
% handle_command(spy_predicate, _, DEBUG, _, _) :-
% 	(   selection(Pred, _, _, 0) -> true
% 	;   selection(_, _, Pred, _)
% 	),
% 	'$Quintus: command_debugger'(spy(predicate(Pred)), DEBUG).
% handle_command(nospy_predicate, _, DEBUG, _, _) :-
% 	(   selection(Pred, _, _, 0) -> true
% 	;   selection(_, _, Pred, _)
% 	),
% 	'$Quintus: command_debugger'(nospy(predicate(Pred)), DEBUG).
% handle_command(debugger_main_window, _, DEBUG, TOPDEBUG, Aux) :-
% 	open_window(source, DEBUG, TOPDEBUG, Aux).
% handle_command(bindings_window, _, DEBUG, TOPDEBUG, Aux) :-
% 	open_window(bindings, DEBUG, TOPDEBUG, Aux).
% handle_command(standard_debugger_window, _, DEBUG, TOPDEBUG, Aux) :-
% 	open_window(standard, DEBUG, TOPDEBUG, Aux).
% handle_command(ancestors_window, _, DEBUG, TOPDEBUG, Aux) :-
% 	open_window(ancestors, DEBUG, TOPDEBUG, Aux).
% handle_command(choicepoints_window, _, DEBUG, TOPDEBUG, Aux) :-
% 	open_window(choicepoints, DEBUG, TOPDEBUG, Aux).
handle_command(close, Window, _, _, _) :-
	close_window(Window).
% handle_command(print_format, Window, DEBUG, TOPDEBUG, Aux) :-
% 	window_format(Window, Format0),
% 	format_parts(Format0, Window, Format0, _, 0, Toggles0, 0, Max0),
% 	await_printmode(Window, Toggles0, Max0, Toggles, Max),
% 	build_format(Toggles, Max, Format),
% 	window_format(Window, _, Format),
% 	(   Window == source -> update_source_window(TOPDEBUG, _, _)
% 	;   update_other_window(Window, DEBUG, TOPDEBUG, first, Aux)
% 	).
% handle_command(redisplay, Window, DEBUG, TOPDEBUG, Aux) :-
% 	update_other_window(Window, DEBUG, TOPDEBUG, first, Aux).
% handle_command(closed, Window, _, _, _) :-
% 	(   prolog_flag(debugging, off) -> true	% don't update if debugger off
% 	;   retractall(currently_open(Window))
% 	).
% handle_command(scrolled, Window, DEBUG, TOPDEBUG, Aux) :-
% 	update_other_window(Window, DEBUG, TOPDEBUG, first, Aux).
% handle_command(begin_selection, _, _, _, _) :-
% 	(   loaded_file(File, _) -> true
% 	;   File = ''
% 	),
% 	selection_loop(File, -2, -2),
% 	selection_sensitivity.
% handle_command(move_selection, _, _, _, _) :-
% 	(   loaded_file(File, _) -> true
% 	;   File = ''
% 	),
% 	selection_loop(File, -2, -2),
% 	selection_sensitivity.
% handle_command(quit_debugger, _, _, _, _) :-
% 	prolog_flag(debugging, _, off).

handle_spy_nospy(Command, Where, Action, DEBUG) :-
	(   '$Quintus: query_debugger'(
		  call(Pm:Pn/Pa,Clausenum,Cm:Cn/Ca,Callnum), DEBUG) ->
	      functor(Ps, Pn, Pa),
	      functor(Cs, Cn, Ca),
	      Where = call(Pm:Ps,Clausenum,Cm:Cs,Callnum),
	      '$Quintus: command_debugger'(Command, DEBUG)
	;   '$Quintus: query_debugger'(caller(Pm:Pn/Pa,_), DEBUG) ->
	      functor(Ps, Pn, Pa),
	      Where = predicate(Pm:Ps),
	      '$Quintus: command_debugger'(Command, DEBUG)
	;   emacs_error(['Nothing to ', Action, '!'])
	).


increment_frame_depth(Count, DEBUG) :-
	frame_depth(N0),
	N is N0+Count,
	set_frame_depth(N, DEBUG).

set_frame_depth(N, DEBUG) :-
	'$Quintus: query_debugger'(depth(D), DEBUG),
	(   N < 0 -> N1 = 0
	;   N > D -> N1 = D
	;   N1 = N
	),
	retractall(frame_depth(_)),
	assert(frame_depth(N1)).

get_chosen_frame(TOPDEBUG, DEBUG) :-
	frame_depth(N),
	get_chosen_frame(N, TOPDEBUG, DEBUG).

get_chosen_frame(N, TOPDEBUG, DEBUG) :-
	(   N =:= 0 ->
		DEBUG = TOPDEBUG
	;   '$Quintus: query_debugger'(parent(DEBUG1), TOPDEBUG) ->
	    N1 is N-1,
	    get_chosen_frame(N1, DEBUG1, DEBUG)
	;   DEBUG = TOPDEBUG
	).

frame_depth(0).

leashing_to_number([], N, N).
leashing_to_number([L|Ls], N0, N) :-
	leashing_port_mask(L, N1),
	N2 is N0 \/ N1,
	leashing_to_number(Ls, N2, N).

number_to_leashing(N, L) :-
	findall(Port, port_bit_on(Port, N), L).

port_bit_on(Port, N) :-
	leashing_port_mask(Port, N1),
	N1 =:= N /\ N1.

% this version is inefficient because we don't have indexing on file to
% find preds in that file, so it searches the proc chain for each file.
%viewable_source_files(Choices) :-
%	(   setof(File, viewable_source_file(File), Choices) -> true
%						% should query_debugger
%	;   Choices = []
%	).
%viewable_source_file(F) :-
%	source_file(F),
%	F \== user,
%	file_exists(F, read),
%	\+ locked_file(F).
%
%locked_file(F) :-
%	source_file(Mod:Pred, F),
%	!,				% only check one pred in file
%	predicate_property(Mod:Pred, locked).

viewable_source_files(Choices) :-
	(   setof(File, possible_source_file(File), Candidates) ->
						% should query_debugger
		viewable_source_files(Candidates, Choices)
	;   Choices = []
	).

possible_source_file(F) :-
	current_predicate(_, M:P),
	\+ predicate_property(M:P, locked),
	source_file(M:P, F).

viewable_source_files([], []).
viewable_source_files([File|Files], L) :-
	(   File \== user,
	    file_exists(File, read) ->
		L = [File|Rest]
	;   L = Rest
	),
	viewable_source_files(Files, Rest).


open_temp_stream(Stream, Name) :-
	mktemp('QDXXXXXX', Name, Stream).


extra_output_stream(Window, Stream, File) :-
	ensure_debugger_window(Window,
			       extra_output_stream(Window,Stream,File), 1),
	open_temp_stream(Stream, File).

extra_append_stream(Window, Stream) :-
	ensure_debugger_window(Window, extra_append_stream(Window, Stream), 2),
	open_extra_stream(Window, 1, Code),
	stream_code(Stream, Code).
%	Stream = user_output.

open_window(W, DEBUG, TOPDEBUG, Aux) :-
	open_window(W),
	(   currently_open(W) -> true
	;   assert(currently_open(W)),
	    update_other_window(W, DEBUG, TOPDEBUG, first, Aux)
	).

open_window(W) :-
	ensure_debugger_window(W, open_window(W), 1),
	emacs_exec(['(prolog-debug-open ''', W, ')']).

close_window(W) :-
	ensure_debugger_window(W, close_window(W), 1),
	emacs_exec(['(prolog-debug-close ''', W, ')']),
	retractall(currently_open(W)).


/* ----------------------------------------------------------------------
			Selecting a goal in source window
   ---------------------------------------------------------------------- */

selection_loop('', Start0, End0) :-
	!,
	await_selection(Start0, End0, 0, Pos, Commandnum),
	command_name(Commandnum, Command),
	(   Command == end_selection ->
		retractall(selection(_,_,_,_))		% no selection
	;   no_source_pos(Start, End, Pred),
	    select_non_clause(Start, End, Pred, Pos)
	).
selection_loop(File, Start0, End0) :-
	await_selection(Start0, End0, 0, Pos, Commandnum),
	command_name(Commandnum, Command),
	(   Command == end_selection ->
		retractall(selection(_,_,_,_))		% no selection
	;   select_new_clause(File, Pos)
	).

select_non_clause(Start, End, Pred, Pos0) :-
	(   Pos0 >= Start, Pos0 =< End ->
		Start1 = Start,
		End1 = End
	;   Start1 = -1,
	    End1 = -1
	),
	await_selection(Start1, End1, 0, Pos, Commandnum),
	command_name(Commandnum, Command),
	(   Command == end_selection ->
		retractall(selection(_,_,_,_)),
		(   Start1 >= 0 ->
			assert(selection(Pred,1,head,0))
		;   true
		)
	;   select_non_clause(Start, End, Pred, Pos)
	).

select_new_clause(File, Pos) :-
	(   call_source_position(File, M:Pred, Clausenum, Cstart, Cend),
	    Pos >= Cstart,
	    Pos =< Cend ->
		bagof(pos(M:Pred,Clausenum,Called,Callnum,Start,End),
			(Cl,Ct,V,Fs,Fe)^selectable_pos(File,M:Pred,Clausenum,
				Called,Callnum,Cl,Ct,V,Start,End,Fs,Fe),
			Poses),
		select_within_clause(File, Pos, Poses, Cstart, Cend)
	;   selection_loop(File, -1, -1)
	).

select_within_clause(File, Pos0, Poses, Cstart, Cend) :-
	(   member(pos(Pred,Clausenum,Called,Callnum,Start,End), Poses),
	    Pos0 >= Start,
	    Pos0 =< End ->
		await_selection(Start, End, Callnum, Pos, Commandnum)
	;   await_selection(-1, -1, 0, Pos, Commandnum)
	),
	command_name(Commandnum, Command),
	(   Command == end_selection ->
		retractall(selection(_,_,_,_)),
		assert(selection(Pred,Clausenum,Called,Callnum))
	;   Pos >= Cstart, Pos =< Cend ->
		select_within_clause(File, Pos, Poses, Cstart, Cend)
	;   select_new_clause(File, Pos)
	).


selectable_pos(File,M1:Pred,Clnum,M2:Called,Callnum,Cl,Ct,V,Start,End,Fs,Fe) :-
	call_source_position(File,M1:Pred,Clnum,M2:Called,Callnum,Cl,Ct,V,
			Start,End,Fs,Fe),
	(   var(Ct) -> true
	;   \+ unselectable_goal(Ct)
	).

unselectable_goal(!).
unselectable_goal(fail).
unselectable_goal(false).
unselectable_goal(true).
unselectable_goal(otherwise).
unselectable_goal(_=_).


selection_sensitivity :-
	true.
% 	(   selection(Pred, _, _, 0) ->
% 		SC = 0, NC = 0,
% 		(   predicate_property(Pred, built_in) -> SP = 0, NP = 0
% 		;   current_spypoint(predicate(Pred)) -> SP = 0, NP = 1
% 		;   SP = 1, NP = 0
% 		)
% 	;   selection(Pred, Clnum, Call, Callnum) ->
% 		(   current_spypoint(call(Pred,Clnum,Call,Callnum)) ->
% 			SC = 0, NC = 1
% 		;   SC = 1, NC = 0
% 		),
% 		(   predicate_property(Call, built_in) -> SP = 0, NP = 0
% 		;   current_spypoint(predicate(Call)) -> SP = 0, NP = 1
% 		;   SP = 1, NP = 0
% 		)
% 	;   SC = 0, NC = 0, SP = 0, NP = 0
% 	),
% 	set_selection_sensitivity(SC, NC, SP, NP).

% call_source_position/[4,5,12] calls source_position/[4,5,12] and fails if
% it signals an error
call_source_position(A, B, C, D) :-
	on_exception(_Err,
		     source_position(A, B, C, D),
		     fail).
call_source_position(A, B, C, D, E) :-
	on_exception(_Err,
		     source_position(A, B, C, D, E),
		     fail).
call_source_position(A, B, C, D, E, F, G, H, I, J, K, L) :-
	on_exception(_Err,
		     source_position(A, B, C, D, E, F, G, H, I, J, K, L),
		     fail).

/* ----------------------------------------------------------------------
			Our message hook
   ---------------------------------------------------------------------- */

user:message_hook(X,Y,Z) :-
	'$Quintus: debugger'(X, X),		% ignore hook unless using 
	X = emacs_debug:emacs_debugger,		% emacs debugger.
	message_hook(X,Y,Z),
	!.

% message_hook(X, _, _) :-
% 	write('==> '),
% 	write(X),
% 	nl,
% 	fail.
message_hook(debug_message(_Tracestate), _, _).  % eat this one
message_hook(spy(Status,_,Spyspec), _, _) :-	% eat this one
	spy_status_description(Status, Addrem),
	spypoint_description(Spyspec, Spydesc),
	emacs_msg(['Spypoint ',Addrem|Spydesc]).
message_hook(spy(nospyall), _, _) :-		% eat this one
	emacs_msg(['All spypoints removed']).
message_hook(top_level_goal, _, _) :-		  % clear standard debugger
	clear_window(standard),			  % window if it's open
	fail.
message_hook(execution_aborted, _, _) :-
	clear_transient_info,
	fail.
message_hook(debugger(retrying), _, _).		% eat this one


spy_status_description(spypoint_placed, 'added to ').	  % ignore messages other
spy_status_description(spypoint_removed, 'removed from '). % than these

spypoint_description(predicate(Skel), ['predicate ',Pred]) :-
	predspec(Skel, user, Pred).
spypoint_description(call(Caller,_Clausenum,Call,_Callnum),
		     ['call from ', Callerspec, ' to ', Callspec]) :-
	predspec(Caller, user, Callerspec),
	predspec(Call, user, Callspec).


clear_transient_info :-
	clear_window(source),
	clear_window(bindings),
	clear_window(ancestors),
	clear_window(choicepoints).

clear_window(Window) :-
	(   currently_open(Window) ->		  % debugger window
		extra_output_stream(Window, Stream, Name),
						  % if it's open
		close(Stream),
		load_other_window(Window, Name, false)
	;   true
	).
	

new_trace_state(_Tracestate) :-
	true.					  % for now, do nothing


% :- extern(reopen_windows).
% 
% reopen_windows :-
% 	true.
% 	(   currently_open(W),
% 	    open_window(W),
% 	    fail
% 	;   true
% 	).

ensure_debugger_is_open :-
	true.
%	(   currently_open(source) -> true
%	;   open_window(source),
%	    reopen_windows
%	).

% TODO: spypoint window for both kinds of spypoints.

% NB: no DEBUG term avail. here, so we can't call '$Quintus: query_debugger'/2.
% There must be some way around this problem.
% changed_spypoint(predicate(Pred), Removed) :-
% 	(   source_file(user:Pred, File),		% user is default mod
% 	    loaded_file(File, _),
% 	    call_source_position(File, Pred, 1, head, 0, _, _, _, Pos,
% 				 _, _, _) ->
% 		update_spypoint(Pos, Removed)
% 	;   true					% nothing to do
% 	),
% 	selection_sensitivity.
% changed_spypoint(call(Caller,Clausenum0,Call,Callnum), Removed) :-
% 	(   source_file(Caller, Clausenum0, File),
% 	    source_file(Caller, FirstInFile, File),
% 					% hack:  source_file/3 returns clauses
% 					% in order
% 	    Clausenum is Clausenum0-FirstInFile+1,
% 	    loaded_file(File, _),
% 	    call_source_position(File, Caller, Clausenum, Call, Callnum, _, _,
% 				 _, Pos, _, _, _) ->
% 		update_spypoint(Pos, Removed)
% 	;   true					% nothing to do
% 	),
% 	selection_sensitivity.


debugger_window(source).
debugger_window(bindings).
debugger_window(ancestors).
debugger_window(standard).
debugger_window(choicepoints).

ensure_debugger_window(W, Goal, Argnum) :-
	(   var(W) ->
		raise_exception(instantiation_error(Goal,Argnum))
	;   debugger_window(W) -> true
	;   raise_exception(domain_error(Goal,Argnum,0,W,''))
	).

%/* ----------------------------------------------------------------
%			Encoding things for/from C
%   ---------------------------------------------------------------- */
%
%%  NB:  THE FOLLOWING TABLES MUST ALL BE KEPT CONSISTANT WITH THE
%%	CORRESPONDING TABLES IN QDEBUG.C
%
%port_number( 'Ancestor', 0).
%port_number( 'Call', 1).
%port_number( 'Fail', 2).
%port_number( 'Exception', 3).
%port_number( 'LastHead', 4).
%port_number( 'Head', 5).
%port_number( 'Done', 6).
%port_number( 'Exit', 7).
%port_number( 'Redo', 8).
%
%leashing_port_mask( call, 2).
%leashing_port_mask( fail, 4).
%leashing_port_mask( exception, 8).
%leashing_port_mask( head, 32).
%leashing_port_mask( done, 64).
%leashing_port_mask( exit, 128).
%leashing_port_mask( redo, 256).
%
%
%window_name(0, source).
%window_name(1, bindings).
%window_name(2, ancestors).
%window_name(3, standard).
%window_name(4, choicepoints).
%
%bool_printmode_bit(quoted(X), X, 1).
%bool_printmode_bit(portrayed(X), X, 2).
%bool_printmode_bit(ignore_ops(X), X, 4).
%bool_printmode_bit(character_escapes(X), X, 8).
%bool_printmode_bit(numbervars(X), X, 16).
%
%trace_state_number(creep, 6).		% NB:  these must be the same
%trace_state_number(leap, 7).		%      as the values in
%trace_state_number(zip, 12).		%      <quintus.h> for calls
%trace_state_number(nonstop, 13).	%      to QP_action.
%
%command_name(0,  creep).
%command_name(1,  skip).
%command_name(2,  leap).
%command_name(3,  zip).
%command_name(4,  quasi_skip).
%command_name(5,  retry).
%command_name(6,  fail).
%command_name(7,  frame_up).
%command_name(8,  frame_down).
%command_name(9,  frame_back).
%command_name(10, nonstop).
%command_name(11, abort).
%command_name(12, break).
%command_name(13, spy_goal).
%command_name(14, nospy_goal).
%command_name(15, spy_predicate).
%command_name(16, nospy_predicate).
%command_name(17, edit_source).
%command_name(18, open).
%command_name(19, quit_debugger).
%command_name(20, leashing_window).
%command_name(21, spypoints_window).
%
%command_name(22, debugger_main_window).
%command_name(23, bindings_window).
%command_name(24, standard_debugger_window).
%command_name(25, ancestors_window).
%command_name(26, choicepoints_window).
%command_name(27, leashing_ok).
%command_name(28, leashing_cancel).
%command_name(29, printmode_ok).
%command_name(30, printmode_cancel).
%command_name(31, close).
%command_name(32, print_format).
%command_name(33, help_on_window).
%command_name(34, redisplay).
%
%command_name(35, closed).
%command_name(36, scrolled).
%command_name(37, begin_selection).
%command_name(38, move_selection).
%command_name(39, end_selection).
%command_name(40, load_file).
%
%
%
%
%
%/* ----------------------------------------------------------------
%			The foreign interface part
%   ---------------------------------------------------------------- */
%
%
%foreign(show_source, c,
%	 show_source(+integer, +integer, +integer, +integer, +integer,
%                +string, +string, +integer, +string, +string)).
%foreign(await_buttonpress, c, await_buttonpress(+integer, +integer,
%		[-integer])).
%foreign(await_leashing, c, await_leashing(+integer, [-integer])).
%foreign(await_printmode, c, await_printmode(+integer, +integer, +integer,
%		-integer, -integer)).
%foreign(await_selection, c, await_selection(+integer, +integer, +integer,
%		-integer, [-integer])).
%foreign(window_management, c, window_management(+integer, +integer)).
%foreign(load_source, c, load_source(+string)).
%foreign(update_spypoint, c, update_spypoint(+integer, +integer)).
%foreign(open_widget_stream, c,
%		open_widget_stream(+integer, +integer, [-address])).
%foreign(debugger_state_changed, c, debugger_state_changed(+integer)).
%foreign('QuiSetSignal', c, 'QuiSetSignal'(+integer, +integer, [-integer])).
%foreign(initial_trace_state, c, initial_trace_state([-string])).
%foreign(edit_file, c, edit_file(+string)).
%foreign(initiate_file_selection, c, initiate_file_selection(+term)).
%foreign(get_selected_file, c, get_selected_file([-string])).
%foreign(clear_transient_info, c, clear_transient_info).
%foreign(set_selection_sensitivity, c,
%		set_selection_sensitivity(+integer, +integer, +integer,
%			+integer)).
%%foreign(window_scroll_pos, c,
%%	window_scroll_pos(+integer, [-integer], -integer)).
%%foreign(set_window_range, c,
%%	set_window_range(+integer, +integer, +integer)).
%
%foreign_file(system('qui.o'), [
%	show_source,
%	await_buttonpress,
%	await_leashing,
%	await_printmode,
%	await_selection,
%	window_management,
%	load_source,
%	update_spypoint,
%	open_widget_stream,
%	debugger_state_changed,
%	'QuiSetSignal',
%	initial_trace_state,
%%	window_scroll_pos,
%%	set_window_range
%	initiate_file_selection,
%	get_selected_file,
%	edit_file,
%	clear_transient_info,
%	set_selection_sensitivity
%]).
%
%:- load_foreign_files([system('qui.o')], []).
