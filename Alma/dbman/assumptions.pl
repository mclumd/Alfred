/*
File: dbman/assumptions.pl
By: kpurang
What: code about assumptions

Todo: maybe this should not be on its owm

*/

% exactly_one_ass(+Node1, +Node2, -Ass, -Node)
% if exactly one of Node1 and Node2 has assumptions Ass and Node is that
% Node
% fail otherwise.
exactly_one_ass(Node1, Node2, A1, Node1):-
    get_assumptions(Node1, A1),
    get_assumptions(Node2, []), !.
exactly_one_ass(Node1, Node2, A2, Node2):-
    get_assumptions(Node2, A2),
    get_assumptions(Node1, []), !.
    

% bigger_ass(+Node1, +Node2, -Node, -Ass)
% Of Node1 and Node2, which has a set of assumptions that includes the
% other;s is Node. the assumptions are Ass
bigger_ass(Node1, Node2, Node1, A1):-
    get_assumptions(Node1, A1),
    get_assumptions(Node2, A2),
    subset(A2, A1), !.
bigger_ass(Node1, Node2, Node2, A2):-
    get_assumptions(Node1, A1),
    get_assumptions(Node2, A2),
    subset(A1, A2), !.


