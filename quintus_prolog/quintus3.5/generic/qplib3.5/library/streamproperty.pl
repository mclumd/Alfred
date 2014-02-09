%   Package: stream_property
%   Author : Richard A. O'Keefe
%   Updated: 29 Nov 1989
%   Defines: stream_property/3 (replaces character_count/2 &c)

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  CHANGE : In 1989, for the 2.5 final release, the order of arguments in
    stream_property/3 was changed to be compatible with the general
    "selector then 'collection' then element" paradigm, followed for example
    in library(filename).
*/
:- module(stream_property, [
	stream_property/3,
	valid_stream/1
   ]).

sccs_id('"@(#)89/11/29 streamproperty.pl	36.1"').


%   valid_stream(?Stream)
%   is true when Stream is either a current stream or one of the
%   standard streams.  If valid_stream(Stream) is true, you can be
%   sure that Stream is still open.  This is a state function: the
%   set of valid streams changes from time to time, but you can
%   use valid_stream/1 to check or enumerate its argument.

valid_stream(Stream) :-
	var(Stream),
	!,
	(   standard_stream(Stream)
	;   current_stream(Stream)
	).
valid_stream(Stream) :-
	atom(Stream),
	!,
	standard_stream(Stream).
valid_stream(Stream) :-
	current_stream(Stream).


standard_stream(user_input).
standard_stream(user_output).
standard_stream(user_error).


current_stream(Stream) :-
	current_stream(_, _, Stream).




%   stream_property(?Property, ?Stream, ?Value)
%   is true when Stream is a valid stream, Property is one of the
%   currently implemented stream properties, and Value is the value
%   of that property of that stream.  All of this information can
%   be obtained other ways, but this reduces the conceptual clutter.
%   Note that some properties may be undefined on some streams; for
%   example 'user_input' and streams opened by QP_make_stream() do
%   not have an absolute_file_name.

stream_property(Property, Stream, Value) :-
	valid_stream(Stream),
	stream_property(Property),
	obtain_value(Property, Stream, Value).


stream_property(character_count).	% integer
stream_property(line_count).		% integer
stream_property(line_position).		% integer
stream_property(direction).		% read|write|append|both
stream_property(absolute_file_name).	% atom


obtain_value(character_count, Stream, Count) :-
	character_count(Stream, Count).
obtain_value(line_count, Stream, Count) :-
	line_count(Stream, Count).
obtain_value(line_position, Stream, Count) :-
	line_position(Stream, Count).
obtain_value(direction, Stream, Direction) :-
	(   standard_stream(Stream) ->
	    standard_direction(Stream, Direction)
	;   current_stream(_, Direction, Stream)
	).
obtain_value(absolute_file_name, Stream, AbsFile) :-
	(   standard_stream(Stream) -> fail
	;   current_stream(AbsFile, _, Stream),
	    atom(AbsFile),
	    AbsFile \== 'null stream'	% hack
	).


standard_direction(user_input,  read).
standard_direction(user_output, write).
standard_direction(user_error,  write).




