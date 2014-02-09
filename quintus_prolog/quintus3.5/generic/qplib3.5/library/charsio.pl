%   Package: charsio
%   Author : Fernando Pereira
%   Updated: 06/17/02
%   Defines: with_input_from_chars/2, with_output_to_chars/2
%   SeeAlso: charsio.c, library(fromonto).

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  The point of this file is to let you read from and write to
    "chars" objects, that is, to lists of character codes.  You
    may wonder why we haven't called this "stringio". and used
    names with "string" in them.  Well, the reason is that the
    name "string" is reserved for implementations of character
    sequences as packed arrays of bytes, and there IS a version
    of Quintus Prolog which supports such objects.  (The file
    strings.pl implements operations which accept either kind
    of text object, strings or atoms, and return the same kind
    of object that they are given.)  Every part of the Quintus
    Prolog library uses the name "chars" for "list of ASCII",
    and if by some oversight there is any use of "string" for
    this purpose, please tell us and we'll fix it.

    There are three things you can currently do with "chars" I/O.
    1)  You can open an input stream reading from a list of chars.
    2)  You can run a particular goal with input coming from a
	list of chars.
    3)  You can run a particular goal with output going to a list
	of chars.
    But you cannot (yet) open an output stream whose characters
    will be unified with a list of characters, because we haven't
    yet thought up a tidy way of handling the "close".

    Note that when you start reading from chars, the chars list
    must be completely instantiated; it is NOT enough to ensure
    that each character will be available before it is read, but
    you must have ALL the characters available to start with.

    Conversely, NO unification is done until after the Goal has
    finished in the case of output diversion.  For example,
	with_output_to_chars((write(a),p), [120 /+ x +/|L])
    will certainly call p, even though the character code for
    97 /+ a +/ does not unify with 120.  ALL the unifications
    are done AFTER the goal has finished.  Note too, alas, that
    if the unification fails the goal will NOT be retried.

    These definitions are not, perhaps, the best that could be
    done.  But they are at least simple enough to be understood.

    BEWARE!  Just because you're reading from a chars list does
    not mean that you don't need the full stop
    after a term!  So
	with_input_from_chars(read(Term), "fred")
    will NOT work; what you want is
	with_input_from_chars(read(Term), "fred.")
    Note that you must have the full stop there, end of list isn't enough.
    Similarly, write(Term) will never put a full stop after a
    term, so
	with_output_to_chars(write(fred), "fred")
    and if you want the full stop and layout, you'll have to call
	with_output_to_chars((write(fred),write(.),nl), Chars)
    or better still
	with_output_to_chars(format('~w.~n',[Term]), Chars)

    Because trying to read a term from a list of character codes which
    lacks the terminal full stop character is likely to be
    the commonest attempted use of with_input_from_chars/2, there is a
    predicate chars_to_term(+Chars, -Term) which does this, e.g.
    chars_to_term("fred", X) unifies X with 'fred'.
    term_to_chars(+Term, -Chars) is the converse of chars_to_term/2.

    Error detecting and reporting in this is pretty pathetic.  Sorry.
*/

:- module(charsio, [
	chars_to_stream/2,
	chars_to_term/2,
	term_to_chars/2,
	with_input_from_chars/2,
	with_input_from_chars/3,
	with_output_to_chars/3,
	with_output_to_chars/2
   ]).
:- meta_predicate
	with_input_from_chars(0, +),
	with_input_from_chars(0, -, +),
	with_output_to_chars(0, ?),
	with_output_to_chars(0, -, ?).

:- use_module(library(types), [
        must_be/3
   ]).

sccs_id('"@(#)02/06/17 charsio.pl	76.2"').


%-----------------------------------------------------------------------

%   with_input_from_chars(+Goal, -Stream, +Chars)
%   executes Goal with Stream bound to an input stream consisting of
%   the characters in Chars, which must be a ground list of characters.
%   Stream is made the current input stream while Goal is running.
%   Note the peculiar use of Stream: it is NOT for communicating a
%   value to with_input_from_chars's caller nor for receiving one,
%   but for passing a value to Goal (Jensen's device, or nearly).
%   This routine is determinate, but will fail if Goal fails.

with_input_from_chars(Goal, Stream, Chars) :-
	chars_to_stream(Chars, Stream),
	current_input(OldStream),
	set_input(Stream),
	(   call(Goal) -> Flag = 1  ;  Flag = 0   ),
	set_input(OldStream),
	close(Stream),
	Flag =:= 1.

%   with_input_from_chars(+Goal, +Chars)
%   is for the common case where Goal uses the current input stream
%   and doesn't need the Stream parameter.

with_input_from_chars(Goal, Chars) :-
	chars_to_stream(Chars, Stream),
	current_input(OldStream),
	set_input(Stream),
	(   call(Goal) -> Flag = 1  ;  Flag = 0   ),
	set_input(OldStream),
	close(Stream),
	Flag =:= 1.


%   chars_to_term(+Chars, ?Term)
%   takes a list of characters such as "f(a,b)", lacking a terminal
%   full stop, and reads a term from it, such
%   as f(a,b).  It fails if there is anything left over.

chars_to_term(Chars, Term) :-
	chars_to_stream(Chars, 3, Stream),
	current_input(OldStream),
	set_input(Stream),
	(   read(X), get0(-1) -> Flag = 1 ; Flag = 0   ),
	set_input(OldStream),
	close(Stream),
	Flag =:= 1,
	Term = X.

%   chars_to_stream(+Chars, -Stream)
%   creates a new input stream Stream, the characters of which are
%   the elements of Chars, which must be a list of character codes.
%   Note that a copy of these characters is made: it is perfectly
%   possible for the Stream handle to be stored in the data base,
%   and retrieved and used safely at a time when backtracking has
%   completely dissolved Chars.  This is why Chars must be ground.

chars_to_stream(Chars, Stream) :-
	chars_to_stream(Chars, 0, Stream).


chars_to_stream(Chars, Dotp, Stream) :-
	chars(Chars, 0, Length),		% check Chars, find Length
	!,
	new_byte_vector(Length, Dotp, Vector),	% make a byte Vector
	Vector =\= 0,				% it was made
	chars_to_byte_vector(Chars, Vector, Length),	% fill it
	DottedLength is Length+Dotp,
	stream_from_byte_vector(Vector, DottedLength, StreamCode, 0),
	stream_code(Stream, StreamCode).
chars_to_stream(Chars, Dotp, Stream) :-
	Goal = chars_to_stream(Chars,Dotp,Stream),
	must_be(chars, 1, Goal).                 % raise exception


%%  chars(+Chars, +L0, -L)
%   succeeds when Chars is a proper list of character codes,
%   and L-L0 is its length.

chars(-, _, _) :- !, fail.
chars([], L, L).
chars([Char|Chars], L0, L) :-
	integer(Char), 0 =< Char, Char =< 255,
	L1 is L0+1,
	chars(Chars, L1, L).


%   Store the characters of Chars into the byte vector Vector.
%   The current length Length is checked for overflow.

chars_to_byte_vector([], _, _).
chars_to_byte_vector([Char|Chars], Vector, Length) :-
	Length > 0,
	store_byte(Char, Vector, Next),
	Left is Length-1,
	chars_to_byte_vector(Chars, Next, Left).



%-----------------------------------------------------------------------

%   with_output_to_chars(+Goal, -Stream, ?Chars)
%   executes Goal with Stream bound to a new output stream, which is also
%   made the current output stream which Goal is running.  After the Goal
%   succeeds, the characters which were written to Stream are formed into
%   a list, and the result unified with Chars.
%   Note the peculiar use of Stream: it is NOT for communicating a
%   value to with_output_to_chars's caller nor for receiving one,
%   but for passing a value to Goal (Jensen's device, or nearly).
%   This routine is determinate, but will fail if Goal fails, or if the
%   sequence of characters written to Stream doesn't unify with Chars.

with_output_to_chars(Goal, Stream, Chars) :-
	start_output_to_handle(Handle, Stream),
	current_output(OldStream),
	set_output(Stream),
	(   call(Goal) -> Flag = 1  ;  Flag = 0   ),
	set_output(OldStream),
	close(Stream),
	byte_stream_to_chars(Handle, Chars0),
	free_byte_stream(Handle),		% this had better be done!
	Flag = 1,
	Chars = Chars0.


%   with_output_to_chars(+Goal, ?Chars)
%   executes Goal with current output redirected to a temporary
%   stream, and after Goal has finished, unifies Chars with the
%   characters written to that stream.  For example, you might do
%   with_output_to_chars(format('%w%w', [X,Y]), Concat_X_Y).

with_output_to_chars(Goal, Chars) :-
	start_output_to_handle(Handle, Stream),
	current_output(OldStream),
	set_output(Stream),
	(   call(Goal) -> Flag = 1  ;  Flag = 0   ),
	set_output(OldStream),
	close(Stream),
	byte_stream_to_chars(Handle, Chars0),
	free_byte_stream(Handle),		% this had better be done!
	Flag = 1,
	Chars = Chars0.


%   term_to_chars(+Term, ?Chars)
%   unifies Chars with a printed representation of Term.  It is not at all
%   clear what representation should be used.  On the grounds that it is
%   supposed to be re-readable, I have chosen to use write_canonical.
%   Giving Chars to chars_to_term/2 will yield a *copy* of Term.

term_to_chars(Term, Chars) :-
	start_output_to_handle(Handle, Stream),
	write_canonical(Stream, Term),
	close(Stream),
	byte_stream_to_chars(Handle, Chars0),
	free_byte_stream(Handle),
	Chars = Chars0.


%   Make an output byte stream Stream whose data are accessible
%   through the handle Handle.

start_output_to_handle(Handle, Stream) :-
	stream_to_byte_vector(Handle, StreamCode, 0),
	stream_code(Stream, StreamCode).


%   Read the data stored at the stream handle Handle into Chars.

byte_stream_to_chars(Handle, Chars) :-
	byte_stream_contents(Handle, Vector, Length),
	byte_vector_to_chars(Vector, Length, Chars).


%   Turn a byte vector into a character list.

byte_vector_to_chars(Vector, Length, Chars) :-
	(   Length =:= 0 -> 
	    Chars = []
	;   Length > 0,
	    Chars = [Char|Rest],
	    fetch_byte(Char, Vector, Next),
	    Left is Length-1,
	    byte_vector_to_chars(Next, Left, Rest)
	).


%-----------------------------------------------------------------------

%   Primitives implemented in charsio.c.

foreign_file(library(system(libpl)),
    [
	new_byte_vector,
	free_byte_vector,
	store_byte,
	fetch_byte,
	byte_stream_contents,
	stream_from_byte_vector,
	stream_to_byte_vector,
	free_byte_stream
    ]).


foreign(new_byte_vector,
	new_byte_vector(+integer,+integer,[-address(byte)])).
foreign(free_byte_vector,
	free_byte_vector(+address(byte))).
foreign(store_byte,
	store_byte(+integer,+address(byte),[-address(byte)])).
foreign(fetch_byte,
	fetch_byte(-integer,+address(byte),[-address(byte)])).
foreign(byte_stream_contents,
	byte_stream_contents(+address('struct byte_stream'),
			     -address(byte),[-integer])).
foreign(stream_from_byte_vector,
	stream_from_byte_vector(+address(byte),+integer,-address('QP_stream'),[-integer])).
foreign(stream_to_byte_vector,
	stream_to_byte_vector(-address('struct byte_stream'),
			      -address('QP_stream'),[-integer])).
foreign(free_byte_stream,
	free_byte_stream(+address('struct byte_stream'))).


:-  load_foreign_executable(library(system(libpl))),
    abolish(foreign_file,2),
    abolish(foreign,2).

