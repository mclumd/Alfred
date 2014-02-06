parse_phrase(Utt, [equil, Item,_]) :-
    value_of(Utt, val0, 'LEFT-WALL'),
    value_of(Utt, val2, 'RIGHT-WALL'),
    value_of(Utt, val1, Val),
    af(intention(Utt, alfred, [equil, Item, Val])).
    
parse_phrase(Utt, _) :-
    value_of(Utt, val0, 'LEFT-WALL'),
    value_of(Utt, val2, 'RIGHT-WALL'),
    value_of(Utt, val1, Val),
    matchwords(Val, LVal, _),
    ((((isa(dcommand, LVal),
	/*      structure(LVal, _,_,_), */
	af(domain_command(Utt, Val, LVal)));
       (isa(acommand, LVal),
	/*      structure(LVal, _,_,_), */
	af(alfred_command(Utt, Val, LVal)));
       (isa(ccommand, LVal),
	/*      structure(LVal, _,_,_), */
	af(complex_command(Utt, Val, LVal)))),
      af(verb(Utt, val1)),
      df(value_of(Utt, val1, Val)),
      af(value_of(Utt, val1, LVal)),
      af(satisfiedallneeds(Utt))); true).


    
