:-dynamic newVVal/2.
:-discontiguous alfred_action/2.
:-ensure_loaded(library(listparts)).

alfred_action([equil, Item1, Item2], _) :-
    (equate(Item1,Item2); equate(Item2,Item1)),!,
    format('I already know that ~p is ~p', [Item1, Item2]),
    nl.


alfred_action([equil, Item1, Item2], _) :-
    af(equil(Item1,Item2)),
    format(' Ok. ~p is ~p', [Item1, Item2]),
    nl. 

alfred_action([what, time], T) :-
    format('Current Alfred time is Step ~p', [T]),
    nl.

alfred_action([undo, [equil, Item1, Item2]]) :-
    df(equil(Item1,Item2)),
    format(' Ok. I no longer believe ~p is ~p', [Item1, Item2]),
    nl. 

/*change Item1 to Item2 in Item*/
alfred_action([update, Item, Item1,Item2]):-
    matchwords(Item2,_,_),!,
    structure(Item,_,_, Struct),
    change_struct(Struct, Item1, Item2, 1, PartL, PartT, PartS),
    df(structure(Item,_,_,Struct)),
    af(structure(Item, PartL, [[v0, verb]|PartT], PartS)),
    format(' Ok. ~p in ~p is ~p', [Item1, Item, Item2]),
    nl.

    /*compose Item of commands Item1 and Item2*/
alfred_action([compose, Item, Item1, Item2], _) :-
    matchwords(Item1,Word1,command),
    matchwords(Item2,Word2,command),
    af(isa(ccommand, Item)),
    addstruct([Word1, Word2], 1, PartL, PartT, PartS),
    af(structure(Item, PartL, [[v0, verb]|PartT], PartS)),
    format(' Ok. ~p is ~p and ~p', [Item, Item1, Item2]),
    nl.

    /*compose Item of commands Item1 and Item2*/
alfred_action([compose, Item, Item1, Item2], _) :-
    matchwords(Item1,Word1,command),
    af(isa(ccommand, Item)),
    addstruct([Word1, Item2], 1, PartL, PartT, PartS),
    af(structure(Item, PartL, [[v0, verb]|PartT], PartS)),!,
    create_desires(Item, PartS),
    format(' Ok. ~p is ~p and ~p', [Item, Item1, Item2]),
    nl.

alfred_action([compose, Item, Item1, Item2], _) :-
    matchwords(Item2,Word2,command),
    af(isa(ccommand, Item)),
    addstruct([Item1, Word2], 1, PartL, PartT, PartS),
    af(structure(Item, PartL, [[v0, verb]|PartT], PartS)),!,
    create_desires(Item, PartS),
    format(' Ok. ~p is ~p and ~p', [Item, Item1, Item2]),
    nl.

alfred_action([compose, Item, Item1, Item2], _) :-
    matchwords(Item1,Word1,_),
    matchwords(Item2,Word2,_),
    af(isa(Item, Word1)),
    af(isa(Item, Word2)),
    format(' Ok. ~p is ~p and ~p', [Item, Item1, Item2]),
    nl.

alfred_action([compose, Item, Item1, Item2], _) :-
    matchwords(Item1,Word1,_),
    af(isa(Item, Word1)),
    af(isa(Item, Item2)),
    format(' Ok. ~p is ~p and ~p', [Item, Item1, Item2]),
    nl.

alfred_action([compose, Item, Item1, Item2], _) :-
    matchwords(Item2,Word2,_),
    af(isa(Item, Item1)),
    af(isa(Item, Word2)),
    format(' Ok. ~p is ~p and ~p', [Item, Item1, Item2]),
    nl.

alfred_action([compose, Item, Item1, Item2], _) :-
    af(isa(Item, Item1)),
    af(isa(Item, Item2)),
    format(' Ok. ~p is ~p and ~p', [Item, Item1, Item2]),
    nl.

/* Construct each component command I. 
Remember to change the names of the new variables; 
for each component name the variables are from vC to vOutC*/

addstruct([I|IList], C, PartL, PartT, PartS) :-
    create_struct_part(I, PartL1, PartT1, PartS1, C, OutC),
    addstruct(IList, OutC, PartL2,  PartT2, PartS2),
    append(PartL1, PartL2, PartL),
    append(PartT1, PartT2, PartT),
    append(PartS1, PartS2, PartS).

addstruct([],_,[],[],[]).


change_struct([[unknown, Item]|IList], Item, Replace, C, PartL, PartT, PartS) :-
    create_struct_part(Replace, PartL1, PartT1, PartS1, C, OutC),!,
    change_struct(IList, Item, Replace, OutC, PartL2,  PartT2, PartS2),
    append(PartL1, PartL2, PartL),
    append(PartT1, PartT2, PartT),
    append(PartS1, PartS2, PartS).

change_struct([[_,[Item|_]]|IList], I, R, C, PartL, PartT, PartS) :-
    create_struct_part(Item, PartL1, PartT1, PartS1, C, OutC),!,
    change_struct(IList, I, R, OutC, PartL2,  PartT2, PartS2),
    append(PartL1, PartL2, PartL),
    append(PartT1, PartT2, PartT),
    append(PartS1, PartS2, PartS).

change_struct([],_,_,_,[],[],[]).

/* Find the structure, type and link that needs to go into the complex command. */
create_struct_part(I, PartL, PartT, [[dcommand, PartS1]], InC, OutC) :-
    isa(dcommand, I),
    structure(I, Links, Type, Struct),
    construct_struct_type(I, Type, Struct, PartT, PartS1, InC, OutC),
    construct_link(Links, Type, PartL),
    retractall(newVVal(_,_)),!.

create_struct_part(I, PartL, PartT, [[acommand, PartS1]], InC, OutC) :-
    isa(acommand, I),
    structure(I, Links, Type, Struct),
    construct_struct_type(I, Type, Struct, PartT, PartS1, InC, OutC),
    construct_link(Links, Type, PartL),
    retractall(newVVal(_,_)),!.

create_struct_part(I, PartL, PartT, [[ccommand, PartS1]], InC, OutC) :-
    isa(ccommand, I),
    structure(I, Links, Type, Struct),
    construct_struct_type(I, Type, Struct, PartT, PartS1, InC, OutC),
    construct_link(Links, Type, PartL),
    retractall(newVVal(_,_)),!.

create_struct_part(I, [], [], [[unknown, I]], _, _).

create_desires(Item, [[unknown,C]|S]) :-
    af(desire(update, Item, C)),
    create_desires(Item, S).
create_desires(Item, [_|S]) :-
    create_desires(Item, S).
create_desires(_, _).

construct_link([[V0,V1,L]|Links],T, PL):-
    type_of_var(V0, T, verb),
    clause(newVVal(V1, NewV), true),!,
    construct_link(Links, T, PL1),
    append([[v0, NewV, L]], PL1, PL).

construct_link([[V0,V1,L]|Links],T, PL):-
    type_of_var(V1, T, verb),
    clause(newVVal(V0, NewV), true), !,
    construct_link(Links, T, PL1),
    append([[v0, NewV, L]], PL1, PL).

construct_link([[V0,V1,L]|Links],T, PL):-
    clause(newVVal(V0, NewV0), true),
    clause(newVVal(V1, NewV1), true), !,
    construct_link(Links, T, PL1),
    append([[NewV0, NewV1, L]], PL1, PL).

construct_link([_|Links],T, PL):-
    construct_link(Links, T, PL).

construct_link([],_,[]).

construct_struct_type(_, _, [], [], [], C, C).


construct_struct_type(I, T, [V,VList], PT, PS, C, C1) :-
    isa(domain, V), !,
    construct_struct_type(I, T, VList, PT, PS1, C, C1),!,
    append([V], [PS1], PS).

construct_struct_type(I, T, [V|VList], PT, PS, C, C1) :-
    type_of_var(V, T, verb),
    construct_struct_type(I, T, VList, PT, PS1, C, C1),!,
    append([I], PS1, PS).

construct_struct_type(I, T, [V|VList], PT, PS, C, C1) :-
    NewC is C + 1,
    construct_struct_type(I, T, VList, PT1, PS1, NewC, C1),
    string_append(v, _, V),
    concat(v, C, NewV),
    assert(newVVal(V,NewV)),
    append([NewV], PS1, PS),
    ((type_of_var(V, T, Type),
      append([[NewV, Type]], PT1, PT));
     PT = PT1).


/*get the Type of V from the List of types*/
type_of_var(V, [[V,Type]|_], Type).

type_of_var(V, [_|TList], Type) :-
    type_of_var(V, TList, Type).

