think(_,[]) .
/*If the types have been assigned already use them to get 
the correct Val. e.g., send b to b replace first b with a 
train name not city name */


think(Utt,[disambiguate, Word1, Type]) :-
    matchwords(Word1, Word2, Type),
    value_of(Utt, Var, Word1),
    clause(val(Utt,V,Var),true),
    clause(type(Utt, V, Type), true),
    af(value_of(Utt, Var, Word2)),
    df(value_of(Utt, Var, Word1)),!,
    af(satisfied(Utt, [disambiguate, Word1, Type])). 
 
/* if the vals are not assigned then use any match*/
think(Utt,[disambiguate, Word1, Type]) :-
    matchwords(Word1, Word2, Type),
    value_of(Utt, Var, Word1),
    af(value_of(Utt, Var, Word2)),
    df(value_of(Utt, Var, Word1)),!,
    af(satisfied(Utt, [disambiguate, Word1, Type])). 
   
think(Utt,[disambiguate, Word1, Type]) :-
    matchwords(Word1, _, Type),
    af(satisfied(Utt, [disambiguate, Word1, Type])). 
    
think(Utt,[equil, Word1, Type]) :-
    matchwords(Word1, _, Type), /* needs to call this here, because only 
    grounded items should be associated with 
    satisfied needs otherwise metro is m, what is 
    m? cannot be prcoessed since there is an item equivalent to m viz metro*/
    af(satisfied(Utt, [equil, Word1, Type])).


/* For extra links,*/
think(Utt,[fix_xlink,Var1, Var2, Link]) :-
    \+clause(link(Utt, Var1, Var2, Link), true), 
    \+clause(link(Utt, Var2, Var1, Link), true), 
    af(satisfied(Utt, [fix_xlink,Var1, Var2,Link])).

think(Utt,[fix_xlink,Var1, Var2, Link]) :-
    stripchars(Link,'abcdefghijklmnopqrstuvwxyz*',DLink),
    try_ignore_link(Utt, Var1, Var2, Link, DLink),!.

think(Utt,[fix_xlink,_, _, _]) :-
    fix_linkage(Utt,2),!.

think(Utt,[fix_xlink,_, _, _]) :-
    fix_linkage(Utt,3),!.

think(Utt,[fix_xlink,_, _, _]) :-
    fix_linkage(Utt,4),!.

think(Utt,[fix_xlink,_, _, _]) :-
    fix_linkage(Utt,5),!.

think(_,[fix_xlink,_, _, _]) :-
    print(idonotknowhowtofixtheselinks),nl.

think(Utt,[fix_mlink,Var1, Var2, Link]) :-
    \+clause(link(Utt, Var1, Var2, Link), true), 
    \+clause(link(Utt, Var2, Var1, Link), true), 
    af(satisfied(Utt, [fix_mlink,Var1, Var2,Link])).

think(Utt,[fix_mlink,_, _, _]) :-
    fix_linkage(Utt,2),!.

think(Utt,[fix_mlink,_, _, _]) :-
    fix_linkage(Utt,3),!.

think(Utt,[fix_mlink,_, _, _]) :-
    fix_linkage(Utt,4),!.

think(Utt,[fix_mlink,_, _, _]) :-
    fix_linkage(Utt,5),!.

think(_,[fix_mlink,_, _, _]) :-
    print(idonotknowhowtofixtheselinks),nl.
	
think(_,_).

/* Links that can be ignored include:
the words a, an, the, 
category words e.g. train */

try_ignore_link(Utt, Var1, Var2, Link, 'DG') :-
    ignore_link(Utt, Var1, Var2, Link).

try_ignore_link(Utt, Var1, Var2, Link, 'D') :-
    ignore_link(Utt, Var1, Var2, Link).

try_ignore_link(Utt, Var1, Var2, Link, 'DD') :-
    ignore_link(Utt, Var1, Var2, Link).

try_ignore_link(Utt, Var1, Var2, Link, 'D*') :-
    ignore_link(Utt, Var1, Var2, Link).

try_ignore_link(Utt, Var1, Var2, Link, 'O') :-
    ignore_category_word(Utt, Var1, Var2, Link).

try_ignore_link(Utt, Var1, Var2, Link, 'AN') :-
    ignore_category_word(Utt, Var1, Var2, Link).

try_ignore_link(Utt, Var1, Var2, Link, 'GN') :-
    ignore_category_word(Utt, Var1, Var2, Link).

try_ignore_link(_,_,_,_).


ignore_category_word(Utt, Var1, Var2, Link) :- 
    value_of(Utt, Var1, Val),
    isa(Type, _),
    equate_simple(Val, Type),
    ignore_link(Utt, Var1, Var2, Link).

ignore_category_word(Utt, Var1, Var2, Link) :- 
    value_of(Utt, Var2, Val),
    isa(Type, _),
    equate_simple(Val, Type),
    ignore_link(Utt, Var1, Var2, Link).

ignore_link(Utt, Var1, Var2, Link) :- 
    ((clause(link(Utt, Var1, Var2, Link), true), 
      df(link(Utt,Var1, Var2, Link)));
     (clause(link(Utt, Var2, Var1, Link), true), 
      df(link(Utt,Var2, Var1, Link)));
     true),
    af(satisfied(Utt, [fix_xlink,Var1, Var2,Link])).




