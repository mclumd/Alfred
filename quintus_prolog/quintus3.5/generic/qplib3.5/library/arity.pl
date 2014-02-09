%   File   : arity.pl
%   Author : Richard A. O'Keefe
%   Updated: 04/20/99
%   Purpose: Support for Arity code translated by arity2quintus
%	     (see <quintus-dir>/generic/tools/aq.pl for more details on the
%	     arity2quintus translator)

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(arity, [
	arity_argrep/4,
	arity_apology/1,
	arity_command/2,
	arity_date/1,
	arity_date_day/2,
	arity_keys/1,
	arity_open/3,
	arity_randomise/1,
	arity_random/1,
	arity_ref/1,
	arity_seek/4,
	arity_system/1,
	arity_time/1,
	inc/2,			% inc(X, Y) <=> Y = X+1
	dec/2,			% dec(X, Y) <=> Y = X-1
	current_predicate/1,	% current_predicate(F/N) DO NOT IMITATE!
	reset_op/0
   ]).

sccs_id('"@(#)99/04/20 arity.pl	76.1"').


:- use_module(library(date), [
	date/3,
	time/3,
	time_stamp/3
   ]).


/*  inc/2 and dec/2, as described in the Arity/Prolog manual, only
    work one way around.  If that's all you want, your program would
    be more portable and easier for other people to read if you used
    is/2, and that's exactly what the Arity->Quintus translator turns
    them into (arithmetic expressions in Quintus Prolog generate
    in-line code, there is nothing to gain by trying to avoid them).

    To give these operations some point, I have made them
    bidirectional: inc(X, Y) will solve for either argument given the
    other.  You are strongly advised NOT to use these operations in
    new programs, and to remove them from old ones.
*/

inc(M, N) :-
    (	integer(M) -> N is M+1
    ;	integer(N) -> M is N-1
    ).


dec(M, N) :-
    (	integer(M) -> N is M-1
    ;	integer(N) -> M is N+1
    ).


/*  Run-time apology when an Arity-specific predicate we can't or shouldn't
    emulator is called.  When integrated with the new error system, this
    will be an IMPLEMENTATION FAULT.
*/

arity_apology(Goal) :-
	functor(Goal, F, N),
	format(user_error,
	       '~N! Unsupported Arity/Prolog predicate ~q~n! Goal: ~q~n',
	       [F/N, Goal]),
	fail.


/*  Data base references.
    Arity/Prolog includes C Prolog's db_reference/1 type test, but calls it
    ref/1.  Note that Quintus expect to change the format of these terms soon.
    BEWARE!  Quintus Prolog agrees with DEC-10 Prolog that data base
    references are ***NOT*** atomic!
*/

arity_ref('$dbref'(X,Y)) :-
	integer(X), integer(Y).


/*  arity_keys(F/N)
    is true when F/N is the name of the functor of a key of something
    in the recorded data base.  This is rather confusing, because the
    name suggests that it returns a list or set of things, which it
    does not do.
*/
arity_keys(F/N) :-
	(   nonvar(F), nonvar(N) ->
	    functor(T, F, N),
	    current_key(F, T)
	;   /* at least one is a variable */
	    current_key(F, T),
	    functor(T, F, N)
	).



/*  arity_command(Cmd, File)
    supports mkdir/1, rmdir/1, and edit/1.  (It could have been used to
    support delete/1, but we already had that in the library.)
*/

arity_command(Cmd, File) :-
	atom_chars(Cmd, CmdChars),
	atom_chars(File, FileChars),
	append(CmdChars, [0' |FileChars], SysChars),
	atom_chars(Sys, SysChars),
	unix(system(Sys)).


/*  Dates and times
*/
arity_date(date(Y,M,D)) :-
	date(Y, M0, D),
	M is M0+1.		% Unix convention clashes with MS-DOS

arity_time(time(H,M,S,0)) :-
	time(H, M, S).

arity_date_day(date(Y,M,D), W) :-
	M0 is M-1,
	time_stamp(date(Y,M0,D), '%w', Day),
	day_number(Day, W).

day_number(sunday,	0).	% Weeks BEGIN on Sunday and have for millenia.
day_number(monday,	1).
day_number(tuesday,	2).
day_number(wednesday,	3).
day_number(thursday,	4).
day_number(friday,	5).
day_number(saturday,	6).	% Weeks END on Saturday and have for millenia.



/*  current_predicate(Name/Arity)
    recognises or enumerates predicates which  are visible in the
    current module.  ***BEWARE***  Many of the Arity/Prolog predicates
    will ***NOT*** be visible.

    This is a useful operation to have.  The trouble with it is that
    it doesn't follow the Edinburgh "style" for predicates about
    predicates, which makes it rather inconvenient to use.  The rule
    in the Edinburgh Prolog famil is that
    --	commands (operations with side effects) take the Name/Arity
	form.  Anything which takes Name/Arity form must also accept
	a list of such forms.  (E.g. spy/1, listing/1.)  Every built-
	in operation which takes Name/Arity form must insist that the
	specification (or list of specifications) be ground, no such
	command may bind any variables.
    --	state functions (operations which have no side effect, but
	whose set of answers can be altered by commands) take a single
	Name(_1,...,_N) form and will test or enumerate it.
    In DEC-10 Prolog, abolish/2 and revive/2 (which undoes abolish/2)
    were exceptions to this, but they were recognised as anomalies and
    abolish/1 substituted.  (Quintus Prolog retains abolish/2 for
    backwards compatibility with DEC-10 Prolog.)

    Now current_predicate/1 is supposed to enumerate the visible
    predicates, and doesn't change anything.  Therefore, it *ought*
    to have solutions like current_predicate(read(_)) rather than
    solutions like current_predicate(read/1).  The Quintus Prolog
    predicates current_predicate/2 (inherited from DEC-10 Prolog)
    and predicate_property/2 (our invention) *do* follow this
    interface rule.  You are advised to use current_predicate/2
    in new code, or perhaps predicate_property/2.
*/

current_predicate(Spec) :-
	currpred(Spec, user).

currpred(Module:Spec, _) :- nonvar(Module), !,
	currpred(Spec, Module).
currpred(Name/Arity, Module) :-
	(   atom(Name), integer(Arity) -> functor(Skel, Name, Arity)
	;   true
	),
	predicate_property(Module:Skel, Property),
	defining_property(Property),
	functor(Skel, Name, Arity).

defining_property(built_in).
defining_property(compiled).
defining_property(interpreted).
defining_property(foreign).


/*  Having urged you to use the more portable and more principled
    current_predicate/2 rather than Arity's current_predicate/1,
    it's up to us to show you how to do that in Arity programs.
    This should work, but hasn't been tested yet.

current_predicate(Name, Skel) :-
	nonvar(Skel),
	!,
	functor(Skel, Name, Arity),
	current_predicate(Name/Arity).
current_predicate(Name, Skel) :-
	current_predicate(Name/Arity),
	functor(Skel, Name, Arity).
*/

/*  arity_system(X)
    is supposed to enumerate built-in predicates.  Its interface is
    even further from the Edinburgh style than current_predicate/1.
    For example, arity_system(true) will succeed, but arity_system(X)
    will *never* bind X = true!  The analogue in Quintus Prolog is
	predicate_property(Skel, built_in)
    or in some versions of C Prolog it is
	system(Skel)
    where Skel is a variable or callable term.
*/
arity_system(X) :-
	(   atom(X) ->
	    predicate_property(user:Skel, built_in),
	    functor(Skel, X, _),
	    !
	;   X = F/N,
	    (	atom(F), integer(N), N >= 0 ->
		functor(T, F, N),
		predicate_property(user:T, built_in)
	    ;	/* variable(s) or wrong type(s) */
		predicate_property(user:Skel, built_in),
		functor(Skel, F, N)
	    )
	).

/*  Term-hacking.
    Arity's argrep(Term, N, NewArg, NewTerm) is the same as our
    change_arg(N, Term, NewTerm, NewArg) except that its argument
    order is unpredictable.  Why have Arity no argrep0 to match
    their (incompatible) arg0/3?

    Note that arg0/3 does not appear in this file; it is handled
    by the translator.  There has been an arg0/3 in the library
    for a long time which does something else.
*/
arity_argrep(Term, K, NewArg, NewTerm) :- 
	(   nonvar(Term) ->
	    functor(Term, F, N),
	    functor(NewTerm, F, N)
	;   nonvar(NewTerm) ->
	    functor(NewTerm, F, N),
	    functor(Term, F, N)
	;   format(user_error, '~N! Instantiation fault~n! Goal: ~q~n',
		[argrep(Term,N,NewArg,NewTerm)]),
	    fail
	),
	(   integer(K) -> K > 0, K =< N
	;   var(K) ->
	    format(user_error, '~N! Instantiation fault~n! Goal: ~q~n',
		[argrep(Term,N,NewArg,NewTerm)]), fail
	;   format(user_error, '~N! Type error~n! Goal: ~q~n',
		[argrep(Term,N,NewArg,NewTerm)]), fail
	),
	arg(K, NewTerm, NewArg),
	KM is K-1, copy_args(1, Term, KM, NewTerm),
	KP is K+1, copy_args(KP, Term, N, NewTerm).

copy_args(L, Old, U, New) :-
    (	L > U -> true
    ;   arg(L, Old, Arg),
	arg(L, New, Arg),
	M is L+1,
	copy_args(M, Old, U, New)
    ).



/*  Files.
    Arity/Prolog let some rather machine-specific stuff show through.
    I have decided to make no attempt to catch and handle the MS-DOS
    "special" file names AUX, COM1, COM2, PRN, LPT1, LPT2, LPT3, NUL.
    Those are so hopelessly O/S dependent that they need manual attention.
    I do, however, catch the modes.

    Arity's seek/4 does not preserve line counts or column positions,
    and cannot be done to every type of file.  
*/

/*  The command open(Handle, FileName, Access) appearing in source code
    is converted to arity_open(Access, FileName, Handle) by the Arity
    to Quintus translator if it cannot be translated to open/3.  Note
    that access modes X+ are not supported.
*/
arity_open(r, F, S) :- !, open(F, read, S).
arity_open(w, F, S) :- !, open(F, write, S).
arity_open(a, F, S) :- !, open(F, append, S).
arity_open(M, F, S) :-
	format(user_error,
	    '~N! Access mode ~w not supported.~n~! Goal: ~q~n',
	    [M, open(S,F,M)]),
	fail.


/*  The command seek(Handle,Offset,Whence,NewLoc)
    is rather like a call to the C function lseek(2).  Unfortunately,
    that isn't a very portable operation, and we carefully avoided
    building anything quite as UNIX or MS-DOS specific as that into
    Quintus Prolog.  Note in particular that some operating systems
    do not let you seek to arbitrary bytes, and that in systems which
    support non-European character sets (e.g. IBM's 16-bit "DBCS"
    coding, Xerox's XNS coding, ...) it may be necessary to associate
    font/state information with a position in a file.  Also note that
    our line_count/2 predicate will be completely messed up by a wild
    seek, so only use this if you don't care about line counts.

    The Arity to Quintus translator maps a seek command to
	arity_seek(Whence, Offset, Stream, NewLoc)
    This does not report errors as well as it should, but then you
    should convert your program to use stream_position/[2,3] instead.
*/
arity_seek(bof, Offset, Stream, NewPlace) :-
	stream_position(Stream, _, '$stream_position'(Offset,1,0)),
	NewPlace is Offset.
arity_seek(current, Offset, Stream, NewPlace) :-
	character_count(Stream, Old),
	(   Offset =:= 0 -> NewPlace is Offset
	;   New is Old+Offset,
	    stream_position(Stream, _, '$stream_position'(New,1,0)),
	    NewPlace is New
	).
arity_seek(eof, Offset, Stream, NewPlace) :-
	current_stream(FileName, _, Stream),
	arity_file_length(FileName, Old),
	New is Old+Offset,
	Offset =< 0, New >= 0,
	stream_position(Stream, _, '$stream_position'(New,1,0)),
	NewPlace is New.


/*  It's one thing to say that you should use stream_position/[2,3]
    instead of seek/4, but how do you _do_ it?  This comes close:

stream_position(Handle, CharacterCount) :-
	seek(Handle, 0, current, CharacterCount).

stream_position(Handle, OldPosition, NewPosition) :-
	seek(Handle, 0, current, OldPosition),
	seek(Handle, NewPosition, bof, _).
*/


/*  reset_op
    cancels all the current operator declarations and restores the
    original ones.  The question is, _which_ original ones.  There
    are two choices:  we could restore the operator declarations of
    Quintus Prolog -- which, except for the addition of (dynamic),
    (multifile), and (meta_predicate) are exactly compatible with
    those of C Prolog *AND*WITH*OLDER*VERSIONS*OF*ARITY*PROLOG -- or
    we could install the operation declarations of the current
    version of Arity Prolog -- which have been considerably warped
    to make them look like C, without, however, succeeding in that aim.

    There really is no choice:  we _cannot_ use Arity's operator
    declarations if we are to have any hope of compatibility with
    our own library files, or, for that matter, with any other Prolog.

    If the ability to read data written with Arity syntax turns out to
    be important, tell us, and we'll make arity_read/1 a new library
    package, with reset_op/0 being part of that.  But then you'll need
    arity_write/1 as well, and so on.

	YOUR PROGRAMS WILL BE MUCH MORE PORTABLE IF YOU FORGET ABOUT
	"EMBEDDED C" AND USE THE "EDINBURGH STANDARD" OPERATORS.

    That means more portable to other Prologs than ours too!
*/

reset_op :-
	current_op(_, Type, Operator),	% for each current operator
	    op(0, Type, Operator),	% remove its definition
	    fail
    ;					% now install standard definitions.
	op(1200, xfx, (:-)),
	op(1200, xfx, -->),
	op(1200,  fx, (:-)),
	op(1200,  fx, (?-)),
	op(1150,  fx, (mode)),
	op(1150,  fx, (public)),
	op(1150,  fx, (dynamic)),
	op(1150,  fx, (multifile)),
	op(1150,  fx, (meta_predicate)),
	op(1100, xfy, ;),
    	op(1050, xfy, ->),		% Arity CHANGED this, we can't
	op(1000, xfy, ','),
	op( 900,  fx, case),		% Arity ADDITION
	op( 900,  fy, \+),
	op( 900,  fy, spy),
	op( 900,  fy, nospy),
    %%%	op( 800, xfy, ->),		% Arity CHANGE
	op( 750, yfx, or),		% Arity ADDITION
	op( 740, yfx, and),		% Arity ADDITION
	op( 700, xfx, =),
	op( 700, xfx, is),
	op( 700, xfx, =..),
	op( 700, xfx, ==),
	op( 700, xfx, \==),
	op( 700, xfx, @<),
	op( 700, xfx, @>),
	op( 700, xfx, @=<),
	op( 700, xfx, @>=),
	op( 700, xfx, =:=),
	op( 700, xfx, =\=),
	op( 700, xfx, <),
	op( 700, xfx, >),
	op( 700, xfx, =<),
	op( 700, xfx, >=),
	op( 600, xfy, :),
    %%%	op( 600, xfy, .),		% Some people like that
	op( 500, yfx, +),
	op( 500, yfx, -),
	op( 500, yfx, \/),
	op( 500, yfx, /\),
	op( 500,  fx, +),
	op( 500,  fx, -),
	op( 400, yfx, /),
	op( 400, yfx, //),
	op( 400, yfx, *),
	op( 400, yfx, <<),
	op( 400, yfx, >>),
	op( 300, xfx, mod),
	op( 200, xfy, ^).


/*  Random numbers.  Arity/Prolog provides two operations:
	random		-> returns a random float [0.0,1.0).
	randomize(Seed)	-> resets the generator from your Seed.
    The manual nowhere explains what the random number generator is.
    Accordingly, I have chosen to provide a rather poor random number
    generator which is never-the-less in common use:  the rand()
    function from System V, modified to produce a float in that range.
    If you want better random numbers, use library(random).
*/

foreign(arity_randomise,
	arity_randomise(+integer)).
foreign(arity_random,
	arity_random([-double])).
foreign(arity_file_length,
	arity_file_length(+string, [-integer])).

foreign_file(library(system(libpl)),
    [
	arity_randomise,
	arity_random,
	arity_file_length
    ]).


:- load_foreign_executable(library(system(libpl))),
   abolish([foreign/2, foreign_file/2]).


