%   Package: benchmark
%   Author : Peter Schachte
%   Updated: 02 Jan 1992
%   Purpose: benchmark a goal

%   Copyright (C) 1988, Quintus Computer Systems, Inc.  All rights reserved.

:- module(benchmark, [
	time/1,
	time/2,
	time/3,
	time/15
   ]).

:- meta_predicate
	time(0),
	time(0,+),
	time(0,+,+),
	time(0,+,+,-,-,-,-,-,-,-,-,-,-,-,-).

sccs_id('"@(#)92/01/02 benchmark.pl	66.1"').


:- dynamic
	last_timing/2.

/*****************************************************************
The timing procedures in this module allow users easily to obtain 
information about the performance of goals.  time/1, 2, and 3,
described in greater detail below, execute the goal you specify the
number of times you specify, printing out information about the time
taken by and memory usage of the goal.  The format of the printout is
as follows:

Time   : 5.451 milliseconds / iteration
Time   : 11.4 milliseconds / iteration (counting gc and shift time)
Time   : 11550 msec total (5451 compute + 150 overhead + 5949 gc + 0 shift)
Global : 3720 bytes / iteration
Global : 3964116 bytes total (3720000 actual + 244116 overhead)
Local  : 0 bytes / iteration
Local  : 0 total (0 actual + 0 overhead)
Gc     : 5949 milliseconds for 2 gcs freeing 3703432 bytes
Shift  : 0 milliseconds for 0 global and 10 local shifts

The first two lines tell you how long your goal takes, first excluding
garbage collection and stack shifting time, and then including it.  The
third line provides the details for the multiple executions of the
goal, including the measured total time, the measured overhead inherent
in timing the total (this is obtained by timing a call to a dummy
procedure that does nothing), and the measured garbage collection and
stack shifting time.

The next line describes the number of bytes of global stack consumed by
each iteration of the test goal.  This is followed by a line detailing
global stack usage for the entire benchmark run, including the
total memory consumed by benchmark run and the overhead memory consumed
by the dummy goal.  Next follow two lines showing the same information
about local stack usage.

Note that in this example local stack usage is 0.  The only reason for
local stack usage not to be 0 is if choicepoints are left behind by the
test goal.  Often this meanst that a cut or if-then-else is needed to
make the program deterministic.  Don't worry if this number is large:
often a single cut or if-then-else can save a large amount of local stack.

The next line documents garbage collection during the course of the
entire benchmark run, detailing how much time was spent collecting
garbage, how many times it was done, and how much memory was reclaimed
in total.  The final line documents how much time was spent in stack
shifting, and how many times the global and local stacks were shifted.

*****************************************************************/


%  time(+Goal)
%  time(+Goal, +Count)
%  Execute Goal Count times (default 1), keeping track of how long it
%  takes, how much local and global stack it consumes, and other such
%  information, printing out a summary on completion.  In order to
%  make the results as accurate as possible, these procedures generate
%  and compile some timing procedures (though if you time the same goal
%  multiple times in a row, it won't recompile the timing procedures).

time(Goal) :-
	time(Goal, 1, 1).

time(Goal, Count) :-
	time(Goal, Count, 1).


%  time(+Goal, +Count, +Internalcount)
%  Like time/1 and 2, but more suitable for timing very fast goals.  Goal
%  is actually executed Count*Internalcount times, but the loop overhead
%  is only proportional to Count.  The testing procedure generated actually
%  calls Goal Internalcount times for each iteration, thus keeping down
%  overhead in order to get better results.

time(Goal, Count, Internalcount) :-
	(   var(Goal) ->
		error('must supply nonvar goal')
	;   (   Goal = (_,_)
	    ;   Goal = (_;_)
	    ;   Goal = (_->_)
	    ;   Goal = \+(_)
	    ) ->
		error('must supply single goal')
	;   \+ integer(Count) ->
		error('count must be an integer')
	;   \+ integer(Internalcount) ->
		error('internal count must be an integer')
	;   (   last_timing(Goal, Internalcount) ->
		    true
	    ;   construct_benchmark(Goal, Internalcount)
	    ),
	    benchmark(Count, Internalcount)
	).


%  time(+Goal, +Count, +Internalcount, -GCcount, -GCfreed, -GCtime,
%  		-Localtotal, -Localoverhead, -Globaltotal, -Globaloverhead,
%  		-Gshifts, -Lshifts, -Shifttime, -Actualtime, -Overheadtime)
%  Like time/3, but rather than printing the benchmark results, they
%  are returned.  Count is the number of times to run the benchmark,
%  and Internalcount is the number of times Goal is actually executed
%  each time we run the benchmark.  So Goal is actually run
%  Count*Internalcount times.  GCcount is the number of gcs performed
%  during the benchmarking, freeing GCfreed bytes and taking GCtime
%  milliseconds.  Localtotal and Globaltotal are the number of bytes of local
%  and global stacks, respectively, consumed by the benchmark.  Localoverhead
%  and Globaloverhead are the number of bytes of local and global stack
%  consumed by the dummy test, indicating the memory cost of the testing
%  procedure itself.  Note that GCfreed, the amount of memory reclaimed by
%  garbage collection, is included in in Globaltotal.  Gshifts and Lshifts
%  indicate how many global and local stack shifts were performed during the
%  benchmark, and Shifttime is the number of milliseconds spent doing these
%  shifts.  Actualtime is the number of milliseconds taken by the benchmark,
%  and Overheadtime is the number of milliseconds taken by the dummy test
%  indicating the time cost of the testing procedure itself.

time(Goal, Count, Internalcount, GCcount, GCfreed, GCtime,
		Localtotal, Localoverhead, Globaltotal, Globaloverhead,
		Gshifts, Lshifts, Shifttime, Actualtime, Overheadtime) :-
	(   var(Goal) ->
		error('must supply nonvar goal')
	;   (   Goal = (_,_)
	    ;   Goal = (_;_)
	    ;   Goal = (_->_)
	    ;   Goal = \+(_)
	    ) ->
		error('must supply single goal')
	;   \+ integer(Count) ->
		error('count must be an integer')
	;   \+ integer(Internalcount) ->
		error('internal count must be an integer')
	;   (   last_timing(Goal, Internalcount) ->
		    true
	    ;   construct_benchmark(Goal, Internalcount)
	    ),
	    benchmark(Count, GCcount, GCfreed, GCtime,
		    Localtotal, Localoverhead, Globaltotal, Globaloverhead,
		    Gshifts, Lshifts, Shifttime, Actualtime, Overheadtime)
	).


%  error(+Msg)
%  Print Msg as an error message and fail.

error(X) :-
	write(user_error, X),
	nl,
	fail.


%  benchmark(+Count, -GCcount, -GCfreed, -GCtime,
%  		-Localtotal, -Localoverhead, -Globaltotal, -Globaloverhead,
%  		-Gshifts, -Lshifts, -Shifttime, -Actualtime, -Overheadtime)
%  Do the actual benchmarking.  Count is the number of times to run the
%  benchmark, and Internalcount is the number of times the test is actually
%  run each time we run the benchmark.  So our test goal is actually run
%  Count*Internalcount times.  GCcount is the number of gcs performed
%  during the benchmarking, freeing GCfreed bytes and taking GCtime
%  milliseconds.  Localtotal and Globaltotal are the number of bytes of local
%  and global stacks, respectively, consumed by the benchmark.  Localoverhead
%  and Globaloverhead are the number of bytes of local and global stack
%  consumed by the dummy test, indicating the memory cost of the testing
%  procedure itself.  Gshifts and Lshifts indicate how many global and local
%  stack shifts were performed during the benchmark, and Shifttime is the
%  number of milliseconds spent doing these shifts.  Actualtime is the
%  number of milliseconds taken by the benchmark, and Overheadtime is the
%  number of milliseconds taken by the dummy test, indicating the time cost of
%  the testing procedure itself.

benchmark(Count, GCcount, GCfreed, GCtime, Localtotal, Localoverhead,
		Globaltotal, Globaloverhead, Gshifts, Lshifts, Shifttime,
		Actualtime, Overheadtime) :-
	statistics(local_stack, [Local0|_]),
	statistics(global_stack, [Global0|_]),
	statistics(garbage_collection, [GCcount0, GCfreed0, GCtime0]),
	statistics(stack_shifts, [Gshifts0, Lshifts0, Shifttime0]),
	statistics(runtime, [R0|_]),
	actual_benchmark(Count),
	statistics(runtime, [R1|_]),
	statistics(local_stack, [Local1|_]),
	statistics(global_stack, [Global1|_]),
	statistics(garbage_collection, [GCcount1, GCfreed1, GCtime1]),
	statistics(stack_shifts, [Gshifts1, Lshifts1, Shifttime1]),
	statistics(runtime, [R2|_]),
	dummy_benchmark(Count),
	statistics(runtime, [R3|_]),
	statistics(local_stack, [Local2|_]),
	statistics(global_stack, [Global2|_]),
	GCcount is GCcount1 - GCcount0,
	GCfreed is GCfreed1 - GCfreed0,
	GCtime is GCtime1 - GCtime0,
	Localtotal is Local1 - Local0,
	Localoverhead is Local2 - Local1,
	Globaltotal is Global1 - Global0 + GCfreed,
	Globaloverhead is Global2 - Global1,
	Gshifts is Gshifts1 - Gshifts0,
	Lshifts is Lshifts1 - Lshifts0,
	Shifttime is Shifttime1 - Shifttime0,
	Actualtime is R1-R0,
	Overheadtime is R3-R2,
	Count =:= Count.		% thwart environment trimming


%  benchmark(+Count, +Internalcount)
%  Do the actual benchmarking.

benchmark(Count, Internalcount) :-
	benchmark(Count, GCcount, GCfreed, GCtime, Localtotal, Localoverhead,
			Globaltotal, Globaloverhead, Gshifts, Lshifts,
			Shifttime, Actualtime, Overheadtime),
	Actualcount is Count*Internalcount,
	Local is Localtotal - Localoverhead,
	Localper is Local / Actualcount,
	Global is Globaltotal - Globaloverhead,
	Globalper is Global / Actualcount,
	Compute is Actualtime - Overheadtime - GCtime - Shifttime,
	Per is Compute / Actualcount,
	Perincluding is (Actualtime - Overheadtime) / Actualcount,
	(   Per > 1000 ->
		Scaledper is Per/1000,
		Scaledperincluding is Perincluding/1000,
		Unit = seconds
	;   Per < 1 ->
		Scaledper is Per*1000,
		Scaledperincluding is Perincluding*1000,
		Unit = microseconds
	;   Scaledper is Per,
	    Scaledperincluding is Perincluding,
	    Unit = milliseconds
	),
	format('~2nTime   : ~w ~w / iteration~n', [Scaledper,Unit]),
	format('Time   : ~w ~w / iteration (counting gc and shift time)~n',
		[Scaledperincluding,Unit]),
	format('Time   : ~w msec total (~w compute + ~w overhead + ~w gc + ~w shift)~n',
		[Actualtime,Compute,Overheadtime,GCtime,Shifttime]),
	format('Global : ~0f bytes / iteration~n', [Globalper]),
	format('Global : ~w bytes total (~w actual + ~w overhead)~n',
		[Globaltotal, Global, Globaloverhead]),
	format('Local  : ~0f bytes / iteration ~n', [Localper]),
	format('Local  : ~w total (~w actual + ~w overhead)~n',
		[Localtotal, Local, Localoverhead]),
	format('Gc     : ~w milliseconds for ~w gcs freeing ~w bytes~n',
		[GCtime,GCcount,GCfreed]),
	format('Shift  : ~w milliseconds for ~w global and ~w local shifts~n',
		[Shifttime,Gshifts,Lshifts]).



%  construct_benchmark(+Goal, +Internalcount)
%  Build actual benchmark loop and dummy loop, write them into a file,
%  and compile and delete the file.

construct_benchmark(Module:Goal, Internalcount) :-
	retractall(last_timing(_,_)),
	assert(last_timing(Module:Goal, Internalcount)),
	build_actual(Module:Goal, Internalcount, Actual),
	build_dummy(Goal, Internalcount, Dummyloop, Dummy),
	abolish(actual_benchmark/1),
	multifile_assertz(Actual),
	functor(Dummy,_,A),
	abolish(dummy/A),
	multifile_assertz(Dummy),
	abolish(dummy_benchmark/1),
	multifile_assertz(Dummyloop).

%  build_actual(+Goal, +Internalcount, +Actual)
%  Actual is the actual benchmark loop procedure, actual_benchmark/1,
%  in a single clause.  It will execute Goal Internalcount times for
%  each iteration.

build_actual(Goal, Internalcount, Actual) :-
	repeat_goal(Internalcount,Goal,Repeated),
	Actual = 
	    (actual_benchmark(N) :-
		    (   N =:= 0 -> true
		    ;   Repeated,
			N1 is N-1,
			actual_benchmark(N1)
		    )
	    ).

%  build_dummy(+Goal, +Internalcount, -Dummyloop, -Dummy)
%  Dummyloop is the dummy benchmark loop procedure, dummy_benchmark/1,
%  in a single clause.  It will execute the dummy procedure with the
%  same arguments as Goal Internalcount times for each iteration.
%  Dummy is single clause for the dummy procedure, which is a unit
%  clause with all anonymous variables.

build_dummy(Goal, Internalcount, Dummyloop, Dummy) :-
	functor(Goal, _, Arity),
	functor(Dummy, dummy, Arity),
	functor(Dummygoal, dummy, Arity),
	same_args(Arity, Goal, Dummygoal),
	repeat_goal(Internalcount,Dummygoal,Repeated),
	Dummyloop =
	    (dummy_benchmark(N) :-
		    (   N =:= 0 -> true
		    ;   Repeated,
			N1 is N-1,
			dummy_benchmark(N1)
		    )
	    ).

%  repeat_goal(+N, +Goal, -Repeated)
%  Repeated is a conjunction of N calls to Goal.  N must be >= 1.

repeat_goal(N, Goal, Repeated) :-
	(   N =:= 1 ->
		Repeated = Goal
	;   Repeated = (Goal,Repeated1),
	    N1 is N-1,
	    repeat_goal(N1, Goal, Repeated1)
	).


%  same_args(+N, +Term1, +Term2)
%  The first N arguments of Term1 are the same as the first N argument
%  of Term2.

same_args(N, Term1, Term2) :-
	(   N =:= 0 -> true
	;   arg(N, Term1, Arg),
	    arg(N, Term2, Arg),
	    N1 is N-1,
	    same_args(N1, Term1, Term2)
	).
