:-dynamic fix_link_val/3.
:-dynamic pverb/2. /*possible command*/
:-dynamic link/4. /*specify this here, since we might not have any links sometimes..*/



/* We have the correct verb/command, but the other links are messed up*/

fix_linkage(Utt, Length) :-
    retractall(fix_link_val(Utt,_,_)),
    retractall(pverb(Utt,_)),
    clause(verb(Utt, Verb),true),
    assert(pverb(Utt, Verb)),
    value_of(Utt, Verb, VerbVal), 
    (debug(true) -> (debug_stream(DS), 
		     print(DS, 'Trying to fix the links when the given verb '),
		     print(DS, VerbVal),
		     print(DS, ' is a valid command'),
		     nl(DS),
		     print(DS, 'Length of fix_linkage is :'),
		     print(DS, Length),
		     nl(DS),
		     print_time(DS)); true),
    (matchwords(VerbVal,Item,acommand);
     matchwords(VerbVal,Item,dcommand);
     matchwords(VerbVal,Item,ccommand)),
    structure(Item, Links, Types, _),
    check_length(Utt, Types, Length),
    findall(Link, link(Utt, _, _, Link), LinkList),
    fix_linkage_help(Utt, LinkList, Links, Types),!,
    delete_extra_verbs(Utt),
    retractall(pverb(Utt,_)).
    
/*Don't have a valid command. so, check whether any word in the utterance matches a command in the commandbase*/

fix_linkage(Utt, Length):-
    retractall(fix_link_val(Utt,_,_)),
    retractall(pverb(Utt,_)),
    value_of(Utt, Val, Word),
    (matchwords(Word,Item,acommand);
     matchwords(Word,Item,dcommand);
     matchwords(Word,Item,ccommand)),
    ((clause(verb(Utt, Verb),true),
      Verb \== Val);
     true),!,
    structure(Item, Links, Types, _),
    check_length(Utt, Types, Length),
    findall(Link, link(Utt, _, _, Link), LinkList),
    assert(pverb(Utt, Val)),
    (debug(true) -> (debug_stream(DS), 
		     print(DS, 'Trying to fix the links when a word in the utterance - '),
		     print(DS, Word),
		     print(DS, 'is a valid command'),
		     nl(DS),
                     print(DS, 'Length of fix_linkage is :'),
		     print(DS, Length),
                     nl(DS),
		     print_time(DS)); true),
    fix_linkage_help(Utt, LinkList, Links, Types),!,
    delete_extra_verbs(Utt),
    af(verb(Utt, Val)),
    retractall(pverb(Utt, _)).
    
/*Don't know the command at all. So try to match the other links with the links for the commands 
in the commandbase for a perfect match*/

fix_linkage(Utt, Length) :-
    retractall(fix_link_val(Utt,_,_)),
    retractall(pverb(Utt,_)),
    structure(_, Links, Types, _),
    check_length(Utt, Types, Length),
    findall(Link, link(Utt, _, _, Link), LinkList),
    compare_links(Utt,LinkList,Links,true),
    clause(verb(Utt, Verb),true),
    (debug(true) -> (debug_stream(DS), 
		     print(DS, 'Trying to fix the links when there is an unknown command - '),
		     value_of(Utt, Verb, VerbVal),
		     print(DS, VerbVal),
		     nl(DS), print_time(DS)); true),
    assert(pverb(Utt, Verb)),
    fix_linkage_help(Utt, LinkList, Links, Types),!,
    delete_extra_verbs(Utt),
    retractall(pverb(Utt, _)).

/*HELPER*/
fix_linkage_help(Utt, LinkList, Links, Types):-
    check_types(Utt, Types),
    (match_links(Utt,LinkList,Links);
      retractall(fix_link_val(Utt,_,_))),!,
    (debug(true) -> (debug_stream(DS), 
		     findall([X1,Y1], fix_link_val(Utt,X1,Y1), XYList1),
		     print(DS, 'Values for fix_link_val after matching links'), 
		     print(DS, XYList1), nl(DS), print_time(DS)); true),

    (check_types(Utt, Types);
     (retractall(fix_link_val(Utt,_,_)),
      check_types(Utt, Types));
     retractandfail(Utt)),!,
    (debug(true) -> (debug_stream(DS), 
		     findall([X2,Y2], fix_link_val(Utt,X2,Y2), XYList2),
		     print(DS, 'Values for fix_link_val after checking types'), 
		     print(DS, XYList2), nl(DS), print_time(DS)); true),
    (bind_remlinks(Utt, Links);
     retractandfail(Utt)),!,
    (debug(true) -> (debug_stream(DS), 
		     findall([X,Y], fix_link_val(Utt,X,Y), XYList),
		     print(DS, 'Values for fix_link_val after binding remaining links'), 
		     print(DS, XYList), nl(DS), print_time(DS)); true),

    fix_links(Utt,Links),
    fix_Xlinks(Utt, Links),
    retractall(fix_link_val(Utt,_,_)).


check_length(Utt, Types, Length) :-
    findall([V,Val], value_of(Utt, V, Val), Values),
    length(Types, TL),
    length(Values, VL),!,
    L is VL - Length,
    TL = L.

remaining_links([[_,_,DLink]|Links],DLink,Input,Result) :-
    append(Input, Links, Result).

remaining_links([Head|Links],DLink,Input,Result):-
    remaining_links(Links,DLink,[Head|Input], Result).

compare_links(Utt, Links,[[_,_,Link]|LinkList],Result) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),
    remaining_links(Links,DLink,[],RemLinks),!,
    compare_links(Utt, RemLinks,LinkList,Result).

/* matching failed and atleast 1 item in the second list*/
compare_links(Utt, Links,[[_,_,Link]|LinkList],Result) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),
    (((DLink == 'RW'; DLink == 'W'),
      compare_links(Utt, Links, LinkList,Result)); 
     Result = false).

compare_links(_, [_|_],[], false).

compare_links(_,[],[], true).
    
compare_links(_,[],[], false).

match_links(Utt,[Link|LinkList],Links) :-
        stripchars(Link, 'abcdefghijklmnopqrstuvwxyz*',DLink),
	check_and_bind(DLink,Link,Links),!,
	match_links(Utt,LinkList,Links).

match_links(_,[],_).

check_and_bind('W',_,_).
check_and_bind('RW',_,_).
check_and_bind('LW',_,_).

check_and_bind(DLink, Link, [[V1,V2,DLink]|_]):-
	clause(link(Utt,Val1,Val2,Link), true),
	clause(fix_link_val(Utt, V1, Val1), true),
	clause(fix_link_val(Utt, V2, Val2), true),!.

check_and_bind(DLink, Link, [[V1,V2,DLink]|_]):-
	clause(link(Utt,Val1,Val2,Link), true),
	clause(fix_link_val(Utt, V1, Val1), true),!,
	(clause(fix_link_val(Utt, V2, _), true);
	 assert(fix_link_val(Utt, V2, Val2))).

check_and_bind(DLink, Link, [[V1,V2,DLink]|_]):-
	clause(link(Utt,Val1,Val2,Link), true),
	clause(fix_link_val(Utt, V2, Val2), true),!,
	(clause(fix_link_val(Utt, V1, _), true);
	 assert(fix_link_val(Utt, V1, Val1))).
	  		
check_and_bind(DLink, Link, [[V1,V2,DLink]|_]):-
	clause(link(Utt,Val1,Val2,Link), true),
	(clause(fix_link_val(Utt, V1, _), true);
	 clause(fix_link_val(Utt, V2, _), true);
	 (assert(fix_link_val(Utt, V1, Val1)),
	  assert(fix_link_val(Utt, V2, Val2)))).
	  		
check_and_bind(DLink, Link, [_|Links]):-
	check_and_bind(DLink, Link, Links).
	
check_and_bind(_,_,[]).

bind_remlinks(Utt, [[V1,V2,_]|Links]) :- 
	clause(fix_link_val(Utt,V1,_),true),
	clause(fix_link_val(Utt,V2,_),true), !,
	bind_remlinks(Utt, Links).

bind_remlinks(Utt, [[V1,V2,_]|Links]) :- 
	clause(fix_link_val(Utt,V1,_),true),
	value_of(Utt, Val2, Item),
	Item \== 'LEFT-WALL',
	Item \== 'RIGHT-WALL',
	\+ clause(fix_link_val(Utt,_,Val2), true),
	assert(fix_link_val(Utt,V2, Val2)),
	bind_remlinks(Utt, Links).

bind_remlinks(Utt, [[V1,V2,_]|Links]) :- 
	clause(fix_link_val(Utt,V2,_),true),
	value_of(Utt, Val1, Item),
	Item \== 'LEFT-WALL',
	Item \== 'RIGHT-WALL',
	\+ clause(fix_link_val(Utt,_,Val1), true),
	assert(fix_link_val(Utt, V1, Val1)),
	bind_remlinks(Utt, Links).

bind_remlinks(_, []).

fix_links(Utt,[[V1,V2,DLink]|Links]):-
	clause(fix_link_val(Utt,V1,Val1),true),
	clause(fix_link_val(Utt,V2,Val2),true),
	clause(link(Utt,Val1,Val2,Link), true),
        stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),!,
	fix_links(Utt,Links).

fix_links(Utt,[[V1,V2,Link]|Links]):-
	clause(fix_link_val(Utt,V1,Val1),true),
	clause(fix_link_val(Utt,V2,Val2),true),
	((clause(link(Utt,Val1,Val2, L), true),
	  dfAC(link(Utt, Val1, Val2, L))); 
	 true),
	afAC(link(Utt,Val1,Val2,Link)),!,
	fix_links(Utt,Links).
	
fix_links(_,[]).


fix_Xlinks(Utt,Links) :-
    findall([Var1,Var2,Link], link(Utt, Var1, Var2, Link), LinkList),
    del_Xlinks(Utt, LinkList, Links).

del_Xlinks(Utt, [[Val1,Val2,Link]|LinkList], Links) :-
    clause(link(Utt,Val1,Val2,Link), true),
    clause(fix_link_val(Utt,V1,Val1),true),
    clause(fix_link_val(Utt,V2,Val2),true),
    check_link(V1,V2, Link, Links),!,
    del_Xlinks(Utt, LinkList, Links).

del_Xlinks(Utt, [[Val1,Val2,Link]|LinkList], Links) :-
    clause(link(Utt,Val1,Val2,Link), true),
    dfAC(link(Utt,Val1,Val2,Link)),
    del_Xlinks(Utt, LinkList, Links).
    
del_Xlinks(_,[],_).
    


check_link(V1,V2, Link, [[V1,V2,Link1]|_]) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),
    stripchars(Link1,'abcdefghijklmnopqrstuvwxyz*',DLink), !.

check_link(V1,V2, Link, [_|Links]) :-
    check_link(V1,V2, Link, Links).

retractandfail(Utt) :-
    retractall(fix_link_val(Utt,_,_)),
    retractall(pverb(Utt, _)),
    fail.
 
check_types(Utt, [[V,Type]|Types]) :-
    clause(fix_link_val(Utt,V,Val),true),!,
    /* Check whether the current binding is valid, i.e, if v1 is bound to val1, check whether val1 and v1 are of the same type*/
    value_of(Utt,Val,Item),
    (matchwords(Item, _, Type1);
     Type1 = Type),!,
    Type1 == Type,
    check_types(Utt, Types).

check_types(Utt, [[V,verb]|Types]) :-
    pverb(Utt, Val),
    \+clause(fix_link_val(Utt,_,Val), true),
    assert(fix_link_val(Utt, V,Val)),!,
    check_types(Utt,Types).

check_types(Utt, [[V,Type]|Types]) :-
    value_of(Utt,Val,Item),
    \+clause(fix_link_val(Utt,_,Val), true),
    matchwords(Item, _ , Type),
    assert(fix_link_val(Utt, V,Val)),!,
    check_types(Utt,Types).

check_types(Utt, [[V,verb]|Types]) :-
    value_of(Utt,Val,Item),
    \+clause(fix_link_val(Utt,_,Val), true),
    (matchwords(Word,Item,acommand);
     matchwords(Word,Item,dcommand);
     matchwords(Word,Item,ccommand)),
    assert(fix_link_val(Utt, V,Val)),!,
    check_types(Utt,Types).

/*CHECK WHETHER THERE IS NO VALUE_OF THAT CAN SATISFY */

check_types(Utt, [_|Types]) :-
    check_types(Utt,Types).

check_types(_,[]).


delete_extra_verbs(Utt):-
    clause(verb(Utt, Verb),true),
    \+ clause(pverb(Utt, Verb), true),
    df(verb(Utt,Verb)),
    fail.

delete_extra_verbs(_).
		
	
