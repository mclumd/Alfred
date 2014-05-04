add_parse_link(U) :-
    clause(link(U, V1, V2, L), true),
	check_parse_link(U,V1,V2,L),
    fail.

add_parse_link(_).

check_parse_link(U,_,V2,L) :-
	verb(U,V2), !,
	value_of(U,V2,Val),
	af(parse_verb(U,Val)).

check_parse_link(U,_,V2,L) :-
	isPrep(L),
	value_of(U,V2,Val),
    af(parse_prep(U,Val)).

check_parse_link(U,V0,V2,L) :-
	isIndirObj(L),
	clause(link(U, V1, V2, 'AN'), true), !,
	value_of(U,V2,Val2),
    af(parse_indirobj(U,Val2)),
	value_of(U,V1,Val1),
	af(parse_indirobjmod(U,Val1)),
	value_of(U,V0,Val0),
	af(parse_indirobjprep(U,Val0,Val2)).

check_parse_link(U,V1,V2,L) :-
	isIndirObj(L),
	value_of(U,V2,Val2),
    af(parse_indirobj(U,Val2)),
	value_of(U,V1,Val1),
	af(parse_indirobjprep(U,Val1,Val2)).

check_parse_link(U,_,V2,L) :-
	isDirObj(L),
	clause(link(U, V1, V2, 'AN'), true), !,
	value_of(U,V2,Val2),
    af(parse_dirobj(U,Val2)),
	value_of(U,V1,Val1),
	af(parse_dirobjmod(U,Val1)).

check_parse_link(U,_,V2,L) :-
	isDirObj(L),
	value_of(U,V2,Val2),
    af(parse_dirobj(U,Val2)).

isIndirObj('Js').
isDirObj('Os').
isPrep('MVp').
isModifier('AN').
isModifier('A').
