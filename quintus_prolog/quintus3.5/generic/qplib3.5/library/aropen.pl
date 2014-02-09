%   Package: aropen
%   Author : Richard A. O'Keefe
%   Updated: 12/10/98
%   Purpose: Reading UNIX archive entries.
%   SeeAlso: library(ar.c) /usr/include/ar.h /usr/man/man5/ar.5

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This module defines one command:

	ar_open(+Archive, +Member, -Stream)

    Archive should be the name of a file which exists, can be
    opened for input, and is in UNIX ar(5) format.
    Member should be the name of a member of the archive.
    Note that UNIX archives, like the UNIX file system
    generally, are case-sensitive.  The name of an archive
    member can only be 16 characters long; this is not our
    fault, that's just the way UNIX archives are.

    ar_open/3 returns a Stream which can be used for reading
    the specified archive member, and no others.  There is a
    general restriction in user-defined streams: you cannot
    use stream_position/3 on them.

    Rewriting or appending to archive members would be possible,
    but it would require copying in general.  UNIX does not
    provide function-level tools for manipulating archives,
    only the program ar(1) {and make(1) knows about arch(memb).}

    We do not claim that this is a complete solution for people
    who want to manipulate archives from Prolog.  You should
    regard it as an example of how *YOU* can use the user-
    defined streams and C interface to provide what you really
    need.  Please let us know what you find most useful.  For
    example, do you need to be able to compile/consult out of
    archives?
*/

:- module(ar_open, [
	ar_open/3
   ]).
:- use_module(library(errno), [
	errno/2
   ]),
   use_module(library(strings), [
	string_size/2
   ]),
   use_module(library(types), [
	must_be_symbol/3,
	must_be_var/3
   ]).

sccs_id('"@(#)98/12/10 aropen.pl	76.1"').


%   ar_open(+Archive, +Member, -Stream)
%   opens a Member of a UNIX archive (see ar(1)) file Archive
%   for input, returning a Prolog Stream.

ar_open(Archive, Member, Stream) :-
	var(Stream),
	atom(Archive),
	atom(Member),
	string_size(Member, Size),
	Size > 0, Size =< 16,
	!,
	'QARopen'(Archive, Member, StreamCode, Errno),
	(   Errno =:= 0 ->
	    stream_code(Stream, StreamCode)
	;   errno(Errno, ar_open(Archive,Member,Stream))
	).
ar_open(Archive, Member, Stream) :-
	Goal = ar_open(Archive, Member, Stream),
	must_be_symbol(Archive, 1, Goal),
	must_be_symbol(Member,  2, Goal),
	must_be_var(Stream,     3, Goal),
	format(user_error,
	    '~N! Member name must be at most 16 characters~n! Goal: ~q~n',
	    [Goal]),
	fail.


foreign_file(library(system(libpl)), ['QARopen']).
foreign('QARopen', 'QARopen'(+string,+string,-address('QP_stream'),[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

