matchwords(Word, Match, number) :-
    clause(equil(Word, TWord), true),
    atom(TWord),
    atom_chars(TWord,S),
    number_chars(Match,S),
    integer(Match).

matchwords(Word, Match, Type) :-
    isa(Type, TWord),
    equate(Word, TWord),!,
    Match = TWord.
    
matchwords(Word, Match, Type) :-
    isa(Type, TWord),
    equate(TWord, Word),!,
    Match = TWord.

matchwords(Word, Match, command) :-
    isa(dcommand, TWord),
    equate(Word, TWord),!,
    Match = TWord.

matchwords(Word, Match, command) :-
    isa(dcommand, TWord),
    equate(TWord, Word),!,
    Match = TWord.

matchwords(Word, Match, command) :-
    isa(acommand, TWord),
    equate(Word, TWord),!,
    Match = TWord.

matchwords(Word, Match, command) :-
    isa(acommand, TWord),
    equate(TWord, Word),!,
    Match = TWord.

matchwords(Word, Match, command) :-
    isa(ccommand, TWord),
    equate(Word, TWord),!,
    Match = TWord.

matchwords(Word, Match, command) :-
    isa(ccommand, TWord),
    equate(TWord, Word),!,
    Match = TWord.

equate(Word1, Word2) :-
    equate_simple(Word1, Word2),!.

equate(Word1, Word2) :-
    equate_equil(Word1, Word2),!.

equate(Word1, Word2) :-
    equate_equil(Word1,Word3),
    equate(Word3,Word2).

equate_simple(Word1, Word2) :-
    Word1 == Word2,!.

equate_simple(Word1, Word2) :-
    lower(Word1,Worda),
    lower(Word2,Wordb),
    Worda == Wordb,!.

equate_equil(Word1, Word2) :-
    clause(equil(Word1, Word2), true),!.

equate_equil(Word1, Word2) :-
    clause(equil(Worda, Wordb), true),
    lower(Worda, Wordas),
    lower(Wordb, Wordbs),
    lower(Word1, Wordas),
    lower(Word2, Wordbs),!.


isa(number, T) :-
    atom(T),
    atom_chars(T,S),
    number_chars(N,S),
    integer(N).
