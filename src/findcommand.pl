/*
This module should assert dd_command, alfred_command or
error(``Verb\_NF\_in\_DD'', Verb, Utt)
 */

find_command(Utt) :-
    main_verb(Utt, Verb),
    matchwords(Verb,Match,acommand),
    af(alfred_command(Utt,Verb,Match)),
    change_main_verb(Utt, Verb, Match).

find_command(Utt) :- 
    main_verb(Utt, Verb),
    matchwords(Verb,Match,dcommand),
    af(domain_command(Utt,Verb,Match)),
    change_main_verb(Utt, Verb, Match).

find_command(Utt) :- 
    main_verb(Utt, Verb),
    matchwords(Verb,Match,ccommand),
    af(complex_command(Utt,Verb,Match)),
    change_main_verb(Utt, Verb, Match).
    
find_command(Utt) :-
    main_verb(Utt, Verb),
    af(error(Utt, 'Item_NF', [command, Verb])).


change_main_verb(_,V,V).

change_main_verb(Utt, Old, New) :-
    clause(value_of(Utt, Var, Old), true),
    df(value_of(Utt, Var, Old)),
    df(main_verb(Utt, Old)),
    af(value_of(Utt, Var, New)),
    af(main_verb(Utt, New)).







