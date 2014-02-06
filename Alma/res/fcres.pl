/*
File res/fcres.pl
By: kpurang
What:  here we do the forward chainig

Todo: see below

*/

% fcres(+Node1, +Node2)
% Nodes are names of nodes that may resolve.
% apply resolution to the nodes, result is an asserted new_node
% we do not expect to derive the empty clause here since we do the 
% stupid contra filtering thing.
% here both nodes are fc, make the resolvent into a new fc node.


% there is something funny going on witht he make_new_nodes coz the resolution
% returns a funny list of lists. later should clean that lol and use the nrew
% make_new_nodes.

fcres(N1, N2):-
    get_actual_nodes([N1, N2], [AN1, AN2]),
    get_form(AN1, Nf1), get_form(AN2, Nf2),
    resolve(Nf1, Nf2, [], R), 
    (debug_level(3) -> (debug_stream(DS), print(DS, 'Forward '),
			print(DS, resolve(Nf1, Nf2, [], R)), nl(DS)); true),
    \+ R = [], !,
    get_junk(AN1, J1), get_junk(AN2, J2),
    decide_junk_fcres(J1, J2, JJ),
    make_new_nodes_for_res(R, 1, JJ, [[N1, N2]]).
fcres(_, _):- !.


decide_junk_fcres(J1, J2, JJ):-
    (J1 = [if|_] , J2 =[if|_]) -> JJ = [if] ; JJ = [fif].

