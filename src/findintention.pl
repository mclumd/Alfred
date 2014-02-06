/*
This module should assert the interpreted user intention in the ALFRED
database. It should assert intention(), error() depending on whether the 
intention was found or not
 */

:-dynamic val/3.
:-dynamic type/3.

/*structure if a complex instruction consists of a list of simple TOS instructions and the associated temporal ordering.
These complex instructions are all alfred commands. Therefore, for alfred type of commands check for this structure*/
	

/* First check if the current intention applies to the domain that has the current focus*/

find_intention(Utt, Type, Command) :-
    structure(Command, Links, Types, Struct),
    Struct = [Domain|_],
    isa(domain,Domain),
    clause(domain_list([Domain|_]), true),
    checklinksmatch(Utt, Links),
    check_links(Utt, Links, Types),
    check_struct(Utt, Struct, Types),
    create_intentions(Utt, Struct, Type, Intentions),!,
    addformulas(val(Utt,_,_)), 
    addformulas(type(Utt,_,_)),
    assert_intentions(Utt, Intentions).


/* then check whether it applies to some domain that does not have the current focus*/
find_intention(Utt, Type, Command) :-
    structure(Command, Links, Types, Struct),
    checklinksmatch(Utt, Links),
    check_links(Utt, Links, Types),
    check_struct(Utt, Struct, Types),
    create_intentions(Utt, Struct, Type, Intentions),!,
    addformulas(val(Utt,_,_)), 
    addformulas(type(Utt,_,_)),
    assert_intentions(Utt, Intentions).

/* if a perfect match is not found, note the errors for disambiguating. Again test the domain that has the current focus first*/
find_intention(Utt, _, Command) :-
    structure(Command, Links, Types, Struct),
    Struct = [Domain|_],
    isa(domain, Domain),
    clause(domain_list([Domain|_]), true),
    checklinksmatch(Utt, Links),!,
%print(fi2),nl,
    find_errors(Utt, Links, Types),
    find_struct_errors(Utt,Struct,Types),
    addformulas(val(Utt,_,_)), 
    addformulas(type(Utt,_,_)).

/* if not test the other domains and then assert errors*/
find_intention(Utt, _, Command) :-
    structure(Command, Links, Types, Struct),
    checklinksmatch(Utt, Links),!,
%print(fi2),nl,
    find_errors(Utt, Links, Types),
    find_struct_errors(Utt,Struct,Types),
    addformulas(val(Utt,_,_)), 
    addformulas(type(Utt,_,_)).

find_intention(Utt,_, Command):-
/*do match links, if links do not match then, needs disambiguation*/
    structure(Command, Links, _, _),
    deleteformulas(val(Utt,_,_)), 
    deleteformulas(type(Utt,_,_)),
    retractall(val(Utt,_,_)),
    retractall(type(Utt,_,_)),
%print(fi3),nl,    
    extra_links(Utt,Links),!.

assert_intentions(Utt, [[Type, Intention]|Intentions]) :-
    af(intention(Utt, Type, Intention)),
    assert_intentions(Utt, Intentions).

assert_intentions(_,[]).


extra_links(Utt,Links) :-
    findall([Var1,Var2,Link], link(Utt, Var1, Var2, Link), LinkList),
    find_extra_links(Utt, Links,LinkList,Result),!,
    Result == false.
    
checklinksmatch(Utt, Links):-
    findall([Var1,Var2,Link], link(Utt, Var1, Var2, Link), LinkList),
    match_links(Utt, Links,LinkList,Result),
    Result == true.

delete_link([[_,_,DLink]|Links],DLink,Input,Result) :-
    append(Input, Links, Result).

delete_link([[_,_,Link]|Links],DLink,Input,Result) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*', DLink),
    append(Input, Links, Result).

delete_link([Head|Links],DLink,Input,Result):-
    delete_link(Links,DLink,[Head|Input], Result).

find_extra_links(Utt, Links,[[_,_,Link]|LinkList],Result) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),
    delete_link(Links,DLink,[],RemLinks),!,
    find_extra_links(Utt, RemLinks,LinkList,Result).

/* matching failed and atleast 1 item in the second list*/
find_extra_links(Utt, Links,[[Var1,Var2,Link]|LinkList],Result) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),
    (DLink == 'RW'; 
     DLink == 'W'; 
     (Result = false,
      af(error(Utt, 'EXTRA_LINK', [Var1,Var2,Link])))),!,
    find_extra_links(Utt, Links, LinkList,Result).

find_extra_links(Utt, [[_,_,Link]|Links],[], Result) :-
    af(error('LINK_NF',Utt,[Link])),
    Result = false,!,
    find_extra_links(Utt, Links,[],Result). 

find_extra_links(_,[],[], true).
    
find_extra_links(_,[],[], false).


match_links(Utt, Links,[[_,_,Link]|LinkList],Result) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),
    delete_link(Links,DLink,[],RemLinks),!,
    match_links(Utt, RemLinks,LinkList,Result).

match_links(Utt, Links,[[_,_,Link]|LinkList],Result) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),
    (DLink == 'RW'; DLink == 'W'),!,
    match_links(Utt, Links, LinkList,Result).

match_links(_,[],[], true).
match_links(_,[],[], false).


construct_intention(_, [], []).

construct_intention(Utt, [V|Struct], Intention) :-
    val(Utt,V,Var),
    value_of(Utt, Var, Val),!,
    construct_intention(Utt, Struct, Intent1),
    append([Val], Intent1, Intention).

construct_intention(Utt, [V,Struct], Intention) :-
%print(V),nl,
    isa(domain, V),!,
    construct_intention(Utt, Struct, Intent1),
    append([V], [Intent1], Intention).

construct_intention(Utt, [V|Struct], Intention) :-
    construct_intention(Utt, Struct, Intent1),
    append([V], Intent1, Intention).

create_intentions(Utt, [[dcommand,S]|Struct], complex, Intentions) :-
    construct_intention(Utt, S, Intent1),
    create_intentions(Utt, Struct, complex, Intents),
    append([[domain,Intent1]], Intents, Intentions).

create_intentions(Utt, [[acommand,S]|Struct], complex, Intentions) :-
    construct_intention(Utt, S, Intent1),
    create_intentions(Utt, Struct, complex, Intents),
    append([[alfred,Intent1]], Intents, Intentions).

create_intentions(Utt, [S|Struct], Type, Intentions) :-
    construct_intention(Utt,[S|Struct], Intention),
    Intentions = [[Type, Intention]].

create_intentions(_,[],_,[]).

check_item(Utt, Var, Link, Var1) :-
    link(Utt, Var, Var1, Link),!.
    
/*Check whether the links match after stripping all lower case flag indicators*/
check_item(Utt, Var, DLink, Var1) :-
        link(Utt, Var, Var1, Link),
        stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink).

find_type(V, [[V,Type]|_], Type) :-!.

find_type(_, [], unknown) :- !.

find_type(Find, [_|Types], Result) :-
	 find_type(Find, Types, Result).

check_links(_, [],_).

check_links(Utt,[[V1,V2,Link]|MoreLinks], Types) :-
	clause(val(Utt, V1, Item1), true),
	clause(val(Utt, V2, Item2), true), !,
%    print(V1), print(V2), print(Item1), print(Item2), nl,
	check_item(Utt, Item1, Link, Item2),
	check_links(Utt, MoreLinks, Types).

check_links(Utt,[[V1,V2,Link]|MoreLinks], Types) :-
	clause(val(Utt, V1, Item1), true),!,
	check_item(Utt, Item1, Link, Item2),
        value_of(Utt, Item2, Val2),

	find_type(V2, Types, Type2),
	(Type2 == unknown;
	 Type2 == verb;
	 isa(Type2, Val2)),
 %   print(V1), print(V2), print(Item1), print(Item2), nl,	
	assert(val(Utt, V2, Item2)),
        assert(type(Utt, V2, Type2)),
	check_links(Utt, MoreLinks, Types).

check_links(Utt,[[V1,V2,Link]|MoreLinks], Types) :-

	clause(val(Utt, V2, Item2), true),!,
	check_item(Utt, Item1, Link, Item2),
	value_of(Utt, Item1, Val1),

	find_type(V1, Types, Type1),
	(Type1 == unknown;
	 Type1 == verb;
	 isa(Type1, Val1)),
%	    print(V1), print(V2), print(Item1), print(Item2), nl,
	assert(val(Utt, V1, Item1)),
        assert(type(Utt, V1, Type1)),
	check_links(Utt, MoreLinks, Types).

check_links(Utt,[[V1,V2,Link]|MoreLinks], Types) :-

    find_type(V1, Types, Type1),
    find_type(V2, Types, Type2),
    check_item(Utt, Item1, Link, Item2),
    value_of(Utt, Item1, Val1),
    value_of(Utt, Item2, Val2),
    
    (Type1 == unknown;
     Type1 == verb;
     isa(Type1, Val1)),
    
    (Type2 == unknown;
     Type2 == verb;
     isa(Type2, Val2)),

%    print(V1), print(V2), print(Item1), print(Item2), nl,  
    assert(val(Utt, V1, Item1)),
    assert(val(Utt, V2, Item2)),
    assert(type(Utt, V1, Type1)),
    assert(type(Utt, V2, Type2)),
    check_links(Utt, MoreLinks, Types).

check_links(_,_,_) :-
    fail.

/* check whether all variables in the struct are bound */

check_struct(_, [[unknown|_]|_], _):- 
    !,fail.

check_struct(Utt, [[dcommand|_]|Struct], Types):- /*ignore complex commands*/
    check_struct(Utt, Struct, Types).

check_struct(Utt, [[acommand|_]|Struct], Types):- /*ignore complex commands*/
    check_struct(Utt, Struct, Types).

check_struct(Utt, [[ccommand|_]|Struct], Types):- /*ignore complex commands*/
    check_struct(Utt, Struct, Types).

check_struct(Utt, [Dom,Struct], Types) :-
    isa(domain, Dom),!,
% print(dom), print(Dom),nl,
% print(struct), print(Struct),nl,
    check_struct(Utt, Struct, Types).	

check_struct(Utt, [V|Struct], Types) :-
    clause(val(Utt, V, _), true),!,    
% print(valclause),print(V),nl,
    check_struct(Utt, Struct, Types).

check_struct(Utt, [V|Struct], Types) :-
    find_type(V, Types, verb),
    clause(verb(Utt, Item), true),
    assert(val(Utt, V, Item)),!,
% print(assertval), print(V), print(Item),nl,
    check_struct(Utt, Struct, Types).

check_struct(Utt, [_|Struct], Types) :-
% print(unknown),nl,
    check_struct(Utt, Struct, Types).

check_struct(_,[],_).

find_errors(_, [],_).

find_errors(Utt,[[V1,V2,Link]|MoreLinks], Types) :-

	find_type(V1, Types, Type1),
	find_type(V2, Types, Type2),!,

	((check_item(Utt, Item1, Link, Item2),
	  value_of(Utt, Item1, Val1),
	  value_of(Utt, Item2, Val2),

	  (Type1 == unknown;
	   Type1 == verb;
	   isa(Type1, Val1);
           (af(error(Utt, 'Item_NF', [Type1, Val1])),
	    assert(val(Utt, V1, Item1)),
	    assert(type(Utt, V1, Type1)))),

	  (Type2 == unknown;
	   Type2 == verb;
	   isa(Type2, Val2);
           (af(error(Utt, 'Item_NF', [Type2, Val2])),
	    assert(val(Utt, V2, Item2)),
	    assert(type(Utt, V2, Type2))))); 
	  af(error(Utt, 'Link_NF',[Link]))),
         find_errors(Utt, MoreLinks, Types).


find_struct_errors(Utt, [[dcommand|_]|Struct], Types):- 
    find_struct_errors(Utt, Struct, Types).

find_struct_errors(Utt, [[acommand|_]|Struct], Types):-
    find_struct_errors(Utt, Struct, Types).

find_struct_errors(Utt, [[ccommand|_]|Struct], Types):- 
    find_struct_errors(Utt, Struct, Types).

find_struct_errors(Utt, [[unknown, C]|Struct], Types):- 
    af(error(Utt, 'Item_NF', [command,C])), 
    find_struct_errors(Utt, Struct, Types).

find_struct_errors(Utt, [V|Struct], Types) :-
    clause(val(Utt, V, _), true),!,    
    find_struct_errors(Utt, Struct, Types).

find_struct_errors(Utt, [V|Struct], Types) :-
    find_type(V, Types, verb),
    clause(verb(Utt, Item), true),
    assert(val(Utt, V, Item)),!,
    find_struct_errors(Utt, Struct, Types).

find_struct_errors(Utt, [_|Struct], Types) :-
    find_struct_errors(Utt, Struct, Types).

find_struct_errors(_,[],_).


