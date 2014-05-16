add_parse_link(U) :-
    clause(link(U, V1, V2, L), true),
	check_parse_link(U,V1,V2,L),
    fail.

add_parse_link(_).

check_parse_link(U,_,V2,L) :-
	verb(U,V2),
	value_of(U,V2,Val),
	af(parse(U,verb,Val)).

check_parse_link(U,_,V2,L) :-
	isPrep(L),
	value_of(U,V2,Val),
    af(parse(U,prep,Val)).

check_parse_link(U,V0,V2,L) :-
	isIndirObj(L),
	clause(link(U, V1, V2, 'AN'), true), !,
	value_of(U,V2,Val2),
    af(parse(U,indirobj,Val2)),
	value_of(U,V1,Val1),
	af(parse(U,indirobjmod,Val1)),
	value_of(U,V0,Val0),
	af(parse(U,indirobjprep,Val0)).

check_parse_link(U,V1,V2,L) :-
	isIndirObj(L),
	value_of(U,V2,Val2),
    af(parse(U,indirobj,Val2)),
	value_of(U,V1,Val1),
	af(parse(U,indirobjprep,Val1)).

check_parse_link(U,_,V2,L) :-
	isDirObjO(L),
	clause(link(U, V1, V2, 'AN'), true), !,
	value_of(U,V2,Val2),
    af(parse(U,dirobj,Val2)),
	value_of(U,V1,Val1),
	af(parse(U,dirobjmod,Val1)).

check_parse_link(U,_,V2,L) :-
	isDirObjO(L),
	value_of(U,V2,Val2),
    af(parse(U,dirobj,Val2)).

check_parse_link(U,V1,_,L) :-
	isDirObjS(L),
	value_of(U,V1,Val1),
    af(parse(U,dirobj,Val1)).

isIndirObj('Ost').
isIndirObj('Js').
isDirObjS('Ss').
isDirObjO('Os').
isPrep('MVp').
isModifier('AN').
isModifier('A').
isWall('Wd').
