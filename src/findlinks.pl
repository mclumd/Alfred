find_links(U) :-
    clause(links(U, _, V1, V2, L), true),
    \+ check_wall(U, V1),
    \+ check_wall(U, V2),
    af(link(U,V1,V2,L)),
    fail.

find_links(_).

check_wall(U, V) :-
    value_of(U, V, Val),
    iswall(Val).

%iswall('LEFT-WALL').
iswall('RIGHT-WALL').


