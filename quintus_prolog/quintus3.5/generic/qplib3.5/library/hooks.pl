%   Module : hooks
%   Author : Jonas Almgren
%   Updated: 30 Apr 1990
%   Purpose: implementing hooks using messages

%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

:- module(hooks,
	[ assertz_hook/2,
	  asserta_hook/2,
	  assertz_hook/3,
	  asserta_hook/3,
	  retract_hook/2,
	  current_hook/2
	]).

:- meta_predicate
	assertz_hook(+, :),
	asserta_hook(+, :),
	assertz_hook(+, :, -),
	asserta_hook(+, :, -),
	retract_hook(+, :),
	current_hook(+, :).

sccs_id('"@(#)90/04/30 hooks.pl    41.1"').

/* ----------------------------------------------------------------------
  This library defines support predicates for asserting, retracting
  and inspecting hooks for a limited set of well defined system "events".
  Currently the available events are: before_save, after_save and
  before_exit. This set may be extended in the future. All goals that
  are hooked to an event are run when the event happens.

  The predicates defined are:
  assertz_hook(+Event, +Goal)
    Goal is called whenever the system event Event happens. It's called
    after all other goals that are attached to Event at assert time. Goal
    is encapsulated in a call, so cuts in Goal has no effect outside of
    Goal. Goal can either fail or succeed, this has no effect on the
    subsequent computation. If Goal is indeterminate, all but the first
    solution are discarded.
  asserta_hook(+Event, +Goal)
    Goal is called whenever the system event Event happens. It's called
    before all other goals that at assert time are attached to Event.
    See assertz_hook/2 about Goal.
  assertz_hook(+Event, +Goal, -Ref)
    Goal is called whenever the system event Event happens. It's called
    after all other goals that are attached to Event at assert time. Ref
    is instantiated to a reference to the hook. The hook can be deleted
    with erase(Ref). See assertz_hook/2 about Goal.
  asserta_hook(+Event, +Goal, -Ref)
    Goal is called whenever the system event Event happens. It's called
    before all other goals that are attached to Event at assert time. Ref
    is instantiated to a reference to the hook. The hook can be deleted
    with erase(Ref). See assertz_hook/2 about Goal.
  retract_hook(+Event, ?Goal)
    Goal is removed from Event. If Goal is unbound, retract_hook/2 is
    indeterministic and backtracks through all goals that are hooked
    to Event.
  current_hook(+Event, ?Goal)
    current_hook/2 backtracks through all goals hooked to Event.

  ---------------------------------------------------------------------- */

assertz_hook(Event, Goal) :-
	( var(Event) ->
	  raise_exception(instantiation_fault(assertz_hook(Event,Goal),1))
	; proper_event(Event),
	  callable(Goal),
	  assertz(user:(message_hook(Event,_,_):-hooks:do_hook(Goal)))
	).

asserta_hook(Event, Goal) :-
	( var(Event) ->
	  raise_exception(instantiation_fault(asserta_hook(Event,Goal),1))
	; proper_event(Event),
	  callable(Goal),
	  asserta(user:(message_hook(Event,_,_):-hooks:do_hook(Goal)))
	).

assertz_hook(Event, Goal, Ref) :-
	( var(Event) ->
	  raise_exception(instantiation_fault(assertz_hook(Event,Goal,Ref),1))
	; proper_event(Event),
	  callable(Goal),
	  assertz(user:(message_hook(Event,_,_):-
		        hooks:do_hook(Goal)), Ref1),
	  Ref = Ref1
	).

asserta_hook(Event, Goal, Ref) :-
	( var(Event) ->
	  raise_exception(instantiation_fault(asserta_hook(Event,Goal,Ref),1))
	; proper_event(Event),
	  callable(Goal),
	  asserta(user:(message_hook(Event,_,_):-
		        hooks:do_hook(Goal)), Ref1),
	  Ref = Ref1
	).

retract_hook(Event, Goal) :-
	( var(Event) ->
	  raise_exception(instantiation_fault(retract_hook(Event,Goal),1))
	; proper_event(Event),
	  retract(user:(message_hook(Event,_,_):-hooks:do_hook(Goal)))
	).

current_hook(Event, Goal) :-
	proper_event(Event),
	user:(message_hook(Event,_,_):-hooks:do_hook(Goal)).

do_hook(Goal) :-
	call(Goal),
	!,
	fail.

proper_event(before_save).
proper_event(after_save).
proper_event(before_exit).

user:(parse_message(before_save) --> []).
user:(parse_message(after_save) --> []).
user:(parse_message(before_exit) --> []).
