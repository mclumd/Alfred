post_process(_, [[Dom, [C|_]]]):-
    isa(domain,Dom),
    \+ clause(result(C,_),true),!,
    %print(Dom),nl,
    rearrangeFocusList(Dom).

post_process(Utt, [[Dom, [C|_]]]):-
    isa(domain,Dom), !,
    clause(result(C,O),true),
    %print(Dom), print('second'),nl,
    af(domain_expect(Utt, [observation, O])),!,
    af(desire(Utt,[inform, O, current])),
    rearrangeFocusList(Dom).

post_process(_, [[C|Rem]]):-
    \+ clause(result(C,_),true),!,
	%print(Rem),nl,
    ((Rem=[Dom], 	
	%print(Dom),nl,
	isa(domain,Dom),	
	  rearrangeFocusList(Dom)); true).	

post_process(Utt, [[C|_]]):-
    clause(result(C,O),true),
    af(domain_expect(Utt, [observation, O])),!,
    af(desire(Utt,[inform, O, current])).


rearrangeFocusList(Dom) :-
    clause(domain_list(DL), true),
    remove_item_from_list(Dom, DL, TempDL),
    append([Dom],TempDL,NDL),
    df(domain_list(DL)),
    af(domain_list(NDL)).













