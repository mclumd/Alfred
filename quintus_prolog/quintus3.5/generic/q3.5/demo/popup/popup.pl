%
% Simple program to demonstrate calling Win32 API functions directly from
% Quintus Prolog using the foreign interface. This program calls a C function
% to calculate the Nth Fibonacci number, then displays the result in a modal
% dialog box.
%

:- use_module(library(charsio)).

runtime_entry(start) :- show_fib(10).

show_fib(N) :-
	fib(N, Answer),
	with_output_to_chars(
	    format(Stream, 'fib(~w) = ~w', [N, Answer]),
	    Stream, MessageChars
	),
	atom_chars(Message, MessageChars),
	window_style([mb_ok, mb_setforeground], Style),
	message_box(0, Message, fib, Style, _).

window_style([], 0) :- !.
window_style([Parm|Parms], Style) :-
	parameter(Parm, Value),
	window_style(Parms, Style1),
	Style is Value \/ Style1.

parameter(mb_ok, 0).
parameter(mb_setforeground, 16'10000).
parameter(mb_taskmodal, 16'2000).

foreign_file(system(fib), [fib]).
foreign_file(syslib(user32), ['MessageBoxA']).

foreign(fib, c, fib(+integer, [-integer])).
foreign('MessageBoxA', win32,
	message_box(+integer, +string, +string, +integer, [-integer])).

:- load_foreign_executable(system(fib)),
   load_foreign_executable(syslib(user32)),
   abolish([foreign_file/2, foreign/3]).
