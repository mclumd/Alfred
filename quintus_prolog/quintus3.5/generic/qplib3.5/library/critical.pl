%   Package: critical
%   Authors: Don Ferguson, Richard A. O'Keefe, Tom Howland
%   Updated: 30 Sep 1992
%   Purpose: blocking signals

%   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

/* critical(+Goal) calls +Goal in a critical region.

critical_on_exception(-ExceptionTerm, +Goal, +Handler) is just like
the built-in on_exception/3, except that both +Goal and +Handler are
executed within a critical region.  If you want interrupts to be
delivered to the handler, use the form

    on_exception(ExceptionTerm, critical(Goal), Handler))

Both critical_on_exception/3 and critical/1 are determinate.

Of course, both of these predicates may be nested.

These predicates are documented in the chapter on exceptions in the reference
manual. 

Critical regions should be used with segments of code that must
execute without being interrupted (via ^C).

For the duration of the critical region, ^C interrupts are held.  On
leaving the critical region, any ^C interrupts that were delivered
during the critical region are delivered to the process.  At this point
one of three things will happen:

  (1) if you have specified a signal handler using the system function
signal(), then that will be called.

  (2) otherwise, if your application has a toplevel, then the signal
handler supplied by Quintus will be called.  In the normal development
system environment, Quintus Prolog establishes a SIGINT signal handler
that presents a menu of choices (abort, debug, etc).

  (3) otherwise, the system default handler for ^C will be invoked,
which is typically a call to the system function exit().

^C is propagated through the I/O system, and means, to the I/O system,
clear the input buffer and then call the SIGINT signal handler.
Example:

| ?- critical(read(X)).
|: a.^C
|: a.

Prolog interruption (h for help)? c

X = a

The above illustrates that ^C erases the system input buffer, but is not
delivered to prolog until the critical region is left. */

:- module(critical, [
	critical/1,
	critical_on_exception/3,
	begin_critical/0,   /* don't use this!  supplied for backwards
			       compatibility only. */
	end_critical/0	    /* don't use this!  supplied for backwards
			       compapibility only. */
   ]).

:- meta_predicate
        critical(0),		         % EXPORTED
        critical_on_exception(?, 0, 0).  % EXPORTED

sccs_id('"@(#)92/09/30 critical.pl	66.1"').

critical(Goal) :-
    begin_critical,
    on_exception(E, critical_tail(Goal), raise(E)).

critical_on_exception(ErrorCode, Goal, Handler) :-
    begin_critical,
    on_exception(E, critical_tail(Goal), handler(ErrorCode, E, Handler)).

handler(ErrorCode, E, Handler):-
    (   ErrorCode = E -> on_exception(E1, critical_tail(Handler), raise(E1))
    ;   raise(E)
    ).

raise(E) :- end_critical, raise_exception(E).

critical_tail(Goal) :-
    (   call(Goal) -> end_critical
    ;   end_critical, fail
    ).

foreign_file(library(system(libpl)),
    [
	begin_critical,
	end_critical
    ]).

%   begin_critical
%   enters a "critical region", during which interrupts are postponsed.

foreign(begin_critical, c, begin_critical).

%   end_critical
%   leaves a "critical region".  When all critical regions have been
%   left, pending interrupt requests (if any) are honoured.

foreign(end_critical,   c, end_critical).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).
