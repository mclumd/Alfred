%   Package: environ
%   Author : Richard A. O'Keefe
%   Updated: 31 Jan 1994
%   Purpose: provide access to UNIX environment variables
%	     and to the command line (argv).
%   SeeAlso: environ.c, man environ(5), man execve(2)

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This module defines three predicates:

  (1)	environ(Name, Value)

    associates UNIX environment variables (Name) with their values
    (Value).  Both arguments are represented by Prolog atoms, NOT
    by chars.  environ/2 is a static predicate which can be used
    to look up a specified environment variable or to enumerate all
    the environment variables and their values.  Prior to 95.1 this
    was a dynamic table which was constructed at load time (so had    
    a static effect), in 95.1 and later it is a static predicate
    which checks the current environment (having a dynamic effect).

  (2)	argv(ArgumentList)

    unifies ArgumentList with a list of the arguments on the command
    line (see sh(1) or csh(1)) or from the exec call (see execve(2)).
    These arguments are represented by Prolog atoms.  In this release,
    you get the whole thing.  The first two arguments are always the
    absolute file name of the Prolog engine and the name of the saved
    state which is being run; remaining arguments are copied from the
    command line.

  (3)	expanded_file_name(NameWithVars, ExpandedVars)

    NameWithVars is an atom containing references to UNIX environment
    variables.  ExpandedVars is an atom obtained by substituting the
    appropriate values for the environment variables in NameWithVars.
    This is modelled on, but not identical to, variable substitution
    in the Bourne and C shells.  The possible cases are

	$<layout>	A dollar sign followed by a space, tab, or newline
			is taken as a literal dollar.  This is copied from
			the C shell.

	$$		A pair of dollar signs is replaced by the process
			identifier (see man 2 getpid) of the Prolog process
			expressed as 1-6 decimal digits.  This is copied
			from the Bourne and C shells both.

	$<alnums>	A sequence of letters, digits, and underscores
			is looked up in the environment, and replaced
			by the value that getenv() finds.

	$(stuff)	These four forms are identical in effect.  They
	$[stuff]	let you use environment variables with arbitrary
	$<stuff>	names, but their main point is that you can put
	${stuff}	a letter, digit, or underscore after them.

	$<other>	The dollar sign is taken literally, and the
			<other> character is processed.  (<layout>
			characters, you will recall, are discarded.)

    For example, suppose
	$HOST		is goonshow
	$USER		is bloodnok
	$HOME		is /usr/bloodnok
	$TERM		is vt100
    Then
	$HOME/thingy	is /usr/bloodnok/thingy
	${HOST}_${USER}	is goonshow_bloodnok
	$HOST_$USER	would look for a variable HOST_
	${TERM}-np	is vt100-np
	$<TERM>2	is vt1002
	$TERM2		would look for a variable TERM2
	/tmp/$USER$$	might be /tmp/bloodnok1234
	$ USER$		would be $USER$

    Bearing in mind that the built-in predicates such as open/3 and
    consult/1 do not understand environment variables (and _must_ not,
    because '$HOME' is a perfectly good UNIX file name as it stands),
    you will realise that the way to use expanded_file_name/2 is

	:- expanded_file_name('$HOME/$TERM.pl', File),
	   consult(File).

    At some future time these predicates might be made available as
	unix(environ(Name,Value))
    and unix(argv(ArgList)) respectively.  Please let us know if they
    would be useful enough to support that way.

    BEWARE: expanded_file_name/2 sees ONLY the environment variables.
    (These are the variables which have been 'export'ed by a Bourne
    shell, or set with 'setenv' in a C shell.  If environ/2 doesn't
    know about a variable, neither does expanded_file_name/2.)

    BEWARE: environ/2 should work on any UNIX system, but argv/1 has
    only been tested on the Sun 3.0 operating system.  It stands a
    good chance of working on other 4.2BSD-derived systems, but may
    not work on AIX or System V.
*/

:- module(environ, [
	argv/1,
	environ/2,
	expanded_file_name/2
   ]).
:- use_module(library(types), [
	must_be_symbol/3
   ]).

sccs_id('"@(#)94/01/31 environ.pl	71.1"').


%   argv(?Argv)
%   is true when Argv is a list of atoms representing *all* the arguments
%   which appeared in the UNIX command line.

argv(Argv) :-
	argc(Argc),
	Argc >= 0,
	pick_up_args(Argc, Argv).


pick_up_args(0, Argv) :- !,
	Argv = [].
pick_up_args(N, [Arg|Args]) :-
	M is N-1,
	pick_up_arg(Arg),
	pick_up_args(M, Args).



%   environ(?EnvVar:atom, ?ItsValue:atom)
%   is true when EnvVar is an atom naming a variable in the UNIX
%   environment (man 3 getenv) and ItsValue is an atom representing
%   the value of that environment variable.

environ(EnvVar, Value) :-
	(   var(EnvVar) ->
	    environ(0, EnvVar, Value)
	;   atom(EnvVar) ->
	    getenv(EnvVar, Value, 0)
	;   must_be_symbol(EnvVar, 1, environ(EnvVar,Value))
	).

environ(I, EnvVar, Value) :-
	getenv(I, Var, Val, 0),
	(   Value = Val, EnvVar = Var
	;   J is I+1,
	    environ(J, EnvVar, Value)
	).


%   expanded_file_name(+NameWithVars:atom, ?ExpandedName:atom)
%   replaces $var, $$, ${var} and so on in NameWithVars, yielding
%   ExpandedName.  E.g. expanded_file_name('$HOME/mytmp/QT$$a', TempName).

expanded_file_name(NameWithVars, ExpandedName) :-
	Goal = expanded_file_name(NameWithVars,ExpandedName),
	(   atom(NameWithVars) ->
	    dollar(NameWithVars, X, E),
	    (   E =:= 0 -> ExpandedName = X
	    ;   raise_exception(
		    domain_error(Goal,1,filename,NameWithVars,
			expanded_file_name(E)))
	    )
	;   must_be_symbol(NameWithVars, 1, Goal)
	).

:- multifile 'QU_messages':msg/3.

'QU_messages':msg(expanded_file_name(E)) --> 
        {expand_error(E, Message)},
	[Message-[]].

expand_error(0'),	'Missing ) after $(').
expand_error(0'],	'Missing ] after $[').
expand_error(0'>,	'Missing > after $<').
expand_error(0'},	'Missing } after ${').
expand_error(0'e,	'Unknown environment variable').
expand_error(0'o,	'Expansion too long').


foreign_file(library(system(libpl)), [
	'QAargc', 'QAnext', 'QAbnge', 'QAbige', 'QAevxn'
]).

foreign('QAargc', argc([-integer])).
foreign('QAnext', pick_up_arg([-string])).
foreign('QAbnge', getenv(+string,-string,[-integer])).
foreign('QAbige', getenv(+integer,-string,-string,[-integer])).
foreign('QAevxn', dollar(+string,-atom,[-integer])).

:-  load_foreign_executable(library(system(libpl))),
    abolish(foreign_file, 2),
    abolish(foreign, 2).

