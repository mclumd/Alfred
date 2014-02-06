createIDFromLetNum(Letter, Number, ID) :-
	number_chars(Number, NumberList),
	append([Letter],NumberList, IDList),
	atom_chars(ID, IDList).

