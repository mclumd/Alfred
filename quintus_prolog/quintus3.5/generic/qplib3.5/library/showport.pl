/*  SCCS   : @(#)showport.pl	14.1 09/04/90
    File   : showport.pl
    Authors: Lawrence Byrd & Peter Schachte
    Purpose: Quintus Prolog debugger -- fifth attempt (QUI version)
    Origin : 5th July 1984.

	+--------------------------------------------------------+
	|							 |
	| WARNING: This material is CONFIDENTIAL and proprietary |
	|	   to Quintus Computer Systems Inc.		 |
	|							 |
	|  Copyright (C) 1984, 1985, 1986, 1987, 1988, 1989,	 |
        |                1990                                    |
	|  Quintus Computer Systems Inc.  All rights reserved.	 |
	|							 |
	+--------------------------------------------------------+
*/

:- module(show_port, [
	show_port/3,
	show_port/4,
	proper_extra/1
   ]).

/* ----------------------------------------------------------------------
    DEBUGGING THE DEBUGGER:
    this code implements a crude Byrd box debugger for debugging the
    debugger itself.  The idea is you put '***' at the beginning of any
    goal you want traced.  When the goal is executed, it will be printed
    following a '>'; when it exits, the goal is again printed after a '<';
    when the goal is retried, after a ')'; on failure, a '('.  There is
    no leashing.  Good luck.
   ----------------------------------------------------------------------*/

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

/* ----------------------------------------------------------------------
	How to show the information for this port
	  show_port/2  is the general entry for showing a DEBUG structure
	  show_one_port/5  is used for one off showings (eg by fast_backup)
   ---------------------------------------------------------------------- */

show_port(Stream,Style,DEBUG) :-
	'$Quintus: query_debugger'(port(Port), DEBUG),
	show_port(Stream, Style, Port, DEBUG).


/* ----------------------------------------------------------------------
	Support code for showing information
   ---------------------------------------------------------------------- */

show_port(Stream, Style, Port, DEBUG) :-
	(   '$Quintus: query_debugger'(invocation(Invoc), DEBUG),
	    '$Quintus: query_debugger'(goal(Goal), DEBUG),
	    '$Quintus: query_debugger'(depth(Depth), DEBUG),
	    (   Port == 'Exception' ->
		    '$Quintus: query_debugger'(exception_term(Term), DEBUG),
		    write(Stream, '! '),
		    write_term(Stream, Term, Style),
		    nl(Stream)
	    ;   true
	    ),
	    decide_prefix(Goal, DEBUG, Prefix),
	    format(Stream, '~w (~w) ~w ~w', [Prefix, Invoc, Depth, Port]),
	    display_extra(Port, Stream, Goal, DEBUG),
	    write(Stream, ': '),
	    write_term(Stream, Goal, Style),
	    fail				% clean up heap usage
	;   true
	).


decide_prefix(Goal, DEBUG, Chars) :-
	(   '$Quintus: query_debugger'(skipped_invocation, DEBUG) ->
	    (   '$Quintus: query_debugger'(
			predicate_property(Goal,spied), DEBUG) ->
		Chars = '*>'
	    ;   Chars = ' >'
	    )
	;   (   '$Quintus: query_debugger'(
			predicate_property(Goal,spied), DEBUG) ->
		Chars = '**'
	    ;   Chars = '  '
	    )
	).


display_extra('Head', Stream, _, DEBUG) :-
	!,
	'$Quintus: query_debugger'(caller(_,This), DEBUG),
	'$Quintus: query_debugger'(next_clause(Next), DEBUG),
	(   Next == none ->
		format(Stream, ' [~w]', [This])
	;   format(Stream, ' [~w->~w]', [This,Next])
	).
display_extra(_, Stream, Goal, DEBUG) :-
	(   '$Quintus: query_debugger'(predicate_property(Goal,Extra), DEBUG),
	    proper_extra(Extra) ->
		format(Stream, ' (~w)', [Extra])
	;   '$Quintus: query_debugger'(current_predicate(_,Goal), DEBUG) ->
		true
	;   write(Stream, ' (undefined)')
	).


proper_extra(built_in).
proper_extra(locked).
proper_extra(foreign).
proper_extra((dynamic)).
proper_extra((multifile)).
