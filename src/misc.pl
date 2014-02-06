appendall([Head|Tail], Result) :-
    appendall(Tail, Result1),
    append(Head,Result1, Result).

appendall([],[]).

addformulas(F) :-
    (clause(F, true),
    af(F)); true.

deleteformulas(F) :-
    (clause(F, true),
    df(F));true. 

afAC(F) :-
    assert(F),
    af(F).

dfAC(F) :-
    retract(F),
    df(F).

stripchars(Word, Chars, Result) :-
	atom_chars(Word, WordList),
	atom_chars(Chars, CharsList),
	trimchars(WordList, CharsList, [], ResultList),
	atom_chars(Result,ResultList).

trimchars([W|Ws], Chars, Input, Result) :-
	char_present(W,Chars), !,
	trimchars(Ws, Chars, Input, Result).

trimchars([W|Ws], Chars, Input, Result) :-
	append(Input,[W],NInput),
	trimchars(Ws, Chars, NInput, Result).

trimchars([],_,Input,Input).

char_present(C, [C|_]).

char_present(W, [_|Chars]) :-
	char_present(W, Chars).

/* removes item I from New Lsit NL*/

remove_item_from_list(_, [], []).

remove_item_from_list(I, [I|NL], NL).

remove_item_from_list(I, [H|Rem], NL) :-
    remove_item_from_list(I,Rem,Part1),
    append([H], Part1, NL). 


find_unused_cost(Utt, [[_,'LEFT-WALL']| Values], Unused) :-
    find_unused_cost(Utt, Values, Unused).

find_unused_cost(Utt, [[_,'RIGHT-WALL']| Values], Unused) :-
    find_unused_cost(Utt, Values, Unused).

find_unused_cost(Utt, [[V, _]| Values], Unused) :-
    (clause(link(Utt, V, _, _), true);
     clause(link(Utt, _, V, _), true)),
    find_unused_cost(Utt, Values, Unused).
    
find_unused_cost(Utt, [_| Values], Unused) :-
    find_unused_cost(Utt, Values, CurUnused),
    Unused is CurUnused + 1.

find_unused_cost(_, [], 0).
