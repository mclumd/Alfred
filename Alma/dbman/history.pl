/*
File dbman/history.pl
By: kpurang
What: code here concerns the history
      essentially dumps it to a file

Todo: code to retrieve history
      send the history to an external process that can do that
      define the sorts of manipulation alma will need
*/


%
% feb 01
% kp turns bacl on the feature to save the history in memory.
% there are 2 new predicates: hist_add(Time, List) and hist_del(Time, List)
% the List should be ordered.
% List is a list of formulas

% historicize(+List)
% Adds the list of new nodes to the history, at the current step.
% dumps into file if need be.
historicize(List):- !,
    (verbose(true)-> (print('historicize '), print(List), nl); true),
    retract(to_add_to_hist(TT)),
    assert(to_add_to_hist([])),
    append(TT, List, ListP),
    step_number(S), 
    dump_history(ListP),
    add_to_memory(S, ListP).
% removed the following line coz this just eats up memory for no reason
%    assert(history(S, List)).
%

% add just the formulas to memory. lose information, in particular
% info about whether the formula is if, bif or fif. Well, fif we do
% know coz of the "conclusino"

add_to_memory(S, List):- !,
    nodelist_to_formulalist(List, FL),
    assert(hist_add(S, FL)).

nodelist_to_formulalist(In, Out):-
    get_the_formulas(In, [], Mid),
    sort(Mid, Out).

%% Looks liek the formulas are NOT sorted??!!
%% KP feb01

get_the_formulas([], X, X):- !.
get_the_formulas([X|R], In, Out):- !,
    get_formula(X, F),
    sort(F, Fsorted),
    get_the_formulas(R, [Fsorted|In], Out).


dump_history(_):-
    history_dump(false), !.
dump_history(List):- !,
    step_number(XX),
    history_stream(S),
    put(S, 10), write_term(S, step(XX), [max_depth(0)]), put(S, 10) ,
    dump_each_hist(S, List).

dump_each_hist(S, []):- !, flush_output(S).
dump_each_hist(S, [X|Y]):- !,
    get_formula(X, F),
    get_junk(X, [FIB|_]),
    get_nodename(X, XName),
    get_parents(X, Xparents),
    sprint_one([F, FIB], SX),
    name(SS, SX),
    name(SPC, "  "),
    write_term(S, add(SS), [max_depth(0)]),
    write(S, SPC),
    write_term(S, XName, [max_depth(0)]),
    write(S, SPC),
    write_term(S, Xparents, [max_depth(0)]),
    put(S, 10),
    dump_each_hist(S, Y).

his_deletes:-
    retract(deleted_forms(F)),
    assert(deleted_forms([])),
    retract(distrusted_forms(SF)),
    assert(distrusted_forms([])),
    append(SF, F, FSF),
    step_number(XX),
    del_to_memory(XX, FSF),
    deadel(F).


del_to_memory(S, List):- !,
    nodelist_to_formulalist(List, FL),
    assert(hist_del(S, FL)).


deadel(_):-
    history_dump(false), !.
deadel(F):-
    history_stream(S),
    wedel(S, F).

wedel(S, []):-  
    write(S, 'End of Step----------------------------------'), put(S, 10),
    flush_output(S), !.
wedel(S, [X|Y]):-
    (verbose(true)-> (print('dumping '), print(X), nl); true),
    get_formula(X, F),
    get_junk(X, [FIB|_]),
    get_nodename(X, XName),
    get_parents(X, Xparents),
%    write_term(S, delete(F), [max_depth(0)]),
    sprint_one([F, FIB], SX),
    name(SS, SX),
    name(SPC, "  "),
    write_term(S, delete(SS), [max_depth(0)]),
    write(S, SPC),
    write_term(S, XName, [max_depth(0)]),
    write(S, SPC),
    write_term(S, Xparents, [max_depth(0)]),
    put(S, 10),
    wedel(S, Y).

