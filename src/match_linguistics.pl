%match linguistics file

:- consult('readdata.pl').
:-read_data('linguistics.pl').    

find_linguistic_verb(Utt, Verb) :-
	pos_int_u(isa(L_Verb, Verb)),
	pos_int_u(isa(C_Verb, L_Verb)),
	af(main_linguistic_verb(Utt, C_Verb)).

