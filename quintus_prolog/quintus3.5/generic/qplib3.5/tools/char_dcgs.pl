% @(#)char_dcgs.pl	73.2 08/22/94

:- module(char_dcgs,[

/* This is a collection of dcgs defined for char lists that may be
generally useful. */

% backtracking

    any/2,
    any/3,
    any/4,
    graph/2,
    graphs/3,

% determinate

    alnums/3,
    digit/2,
    digits/3,
    layout/2,
    maybe_layout/2,
    natural/3,
    nl/2,
    symbol/3,

% some other (determinate) operations on char lists that are not dcg's:

    lower/2,
    pchars/1,
    read_as_chars/2,
    read_stream_as_chars/2]).

:- use_module(library(ctypes)).

% library(printchars) is crucial for debugging

% :- use_module(library(printchars)).

% read in a file, Fn, as a character list, Chars

read_as_chars(Fn, Chars) :-
    open(Fn, read, [binary], Stream),
    read_stream_as_chars(Stream, Chars),
    close(Stream).

read_stream_as_chars(Stream, Chars) :-
    current_input(CI),
    set_input(Stream),
    rac(Chars),
    set_input(CI).

rac(L) :-
    get0(C),
    (   C =:= -1
    ->  L = []
    ;   L = [C|T], rac(T)
    ).

pchars([]).
pchars([H|T]) :- put(H), pchars(T).

lower([], []).
lower([U|R], [L|T]) :- to_lower(U, L), lower(R, T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% backtracking predicates %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

any(S, S).					% any --> "".
any([_|S0], S) :- any(S0, S).			% any --> [_], any.

any(A, B, C) :- append(A, C, B).

	% any(S, S) --> "".
	% any([C|S0], S) --> [C], any(S0, S).

any(A, A, B, B). 
any([A|B], C, [A|D], E) :- any(B, C, D, E). 

graph --> "".
graph --> [C], {is_graph(C)}, graph.

graphs("") --> "".
graphs([H|T]) --> [H], {is_graph(H)}, graphs(T).

%%%%%%%%%%%%%%%%%%%%%%%%%%
% determinate predicates %
%%%%%%%%%%%%%%%%%%%%%%%%%%

nl --> [10].

alnums(A) --> [C], {is_alnum(C)}, ({A = [C|R]}, alnums(R) | {A = [C]}, ""), !.

layout --> [C], {is_layout(C)}, (layout | ""), !.

maybe_layout --> layout, !.
maybe_layout --> "".

symbol([H|T]) --> [H], {is_csymf(H)}, csym(T).

csym([H|T]) --> [H], {is_csym(H)}, !, csym(T).
csym("") --> "".

digit --> [C], {is_digit(C)}, (digit | ""), !.

natural(N) --> digits(Chars), {number_chars(N, Chars)}.

digits(D) --> [C], {is_digit(C)}, ({D = [C|R]}, digits(R) | {D = [C]}, ""), !.
