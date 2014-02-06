/*
File: res/resolve.pl
By: kpurang
What: does the resolution

Todo: there has to be a more efficient way
      add strucutre to the clauses to make more efficient      

*/


%% Notes added by M. Covington, 2010
%% My notes have two or more % at the beginning of each comment


%% not used:  :- ensure_loaded(library(sets)).
%% not used:  :- ensure_loaded(library(ordsets)).


% new version mar 01
% kp

/*
  make sure we take care of cases like:
  p(X) -> q(X) and p(a) | p(b)
  Need to resolve multiple times.
  
  how about if the vars and constants are on both sides? :(

  ALSO: what do we expect to return? a _list_ of result clauses i think.
  is a list of [R, T] where R is the cluase, T is the target and is used
  only in bcres. Now, how that target gets in there, i am not sure. ah!
  the target is the third arg. Oh! it has to be inthe resiult cos if i
  have several results, i need several targets! OK. we fix that now.
  BUT not the several results thing for now.
  

  detect tautologies and return 'true'


  TODO:
  1. find multiple resolutions
  2. retrun them in the right way (with the target)
  3. detect tautologies.

*/



%%% test_compare/2 -- M. Covington 2010
%%%  reports if its 2 arguments are different, for testing only
%%
%%test_compare(X,X,_) :- !.
%%test_compare(X,Y,Label) :- write(Label), write(' non-trivial sort: '), nl, write(X), nl, write(Y), nl.



%%
%% This is the critical section of Alma.
%%
%% resolve/4 is called from: bcres.pl fcres.pl production.pl resolve.pl tests.pl
%%   Each of these cuts after it, but first, fcres backtracks if its last arg
%%   is an empty list.
%% separate_lits/4 is called only from here
%% resolve2/4 is called only from here
%% try_each1/8 is called only from here, an extremely large number of times
%% list_to_ord_set/2 in the Quintus Library is called from: access.pl ui.pl resolve.pl
%%

%% The following cut has no effect and I wonder if it was meant to come last.
%% (No, because fcres uses resolve/4 nondeterministically.)
%% Note that CTar is a singleton variable.
resolve(C1, C2, Tar, Res):- %% !,
    %% The most time-consuming operation in all of Alma is the following line (copy_term).
    %% Could it be avoided if the resolution is obviously going to fail?
%%    copy_term([C1, C2, Tar], [CC1, CC2, CTar]),  
    copy_term([C1, C2], [CC1, CC2]),  %% avoid copying Tar since it's not needed
    separate_lits(CC1, [[],[]], CS1),
    separate_lits(CC2, [[],[]], CS2),
    resolve2(CS1, CS2, Tar, Res).   
    %% BY Tar DID YOU MEAN CTar IN LAST LINE? Results seem equally correct either way.

%% separate_lits(Literals, [PosSoFar,NegSoFar], [Positives,Negatives])
%% separates a list of literals into ordered lists of positive and negative literals.
%% Middle argument is a state variable.
separate_lits([], [X,Y], [X,Y]) :- !.  %% Skip the sorting. This change could affect correctness.
%%separate_lits([], [X, Y], [OX, OY]):- !,
%%    sort(X, OX),     %% apparently always already sorted
%%    sort(Y, OY).     %% often called on one-element lists
separate_lits([not(X)|Y], [XX, YY], Z):- !,
    separate_lits(Y, [XX, [X|YY]], Z).
separate_lits([X|Y], [XX, YY], Z):- % !,   % cut with no effect
    separate_lits(Y, [[X|XX], YY], Z).

%resolve2([+1, -1], [+2, -2], Tar, Res)
% for each element in +1, see if htere is anything in -2 that unifies.
% same for -1 and +2
% once that happens, merge the clauses

%%resolve2([P1, N1], [P2, N2], T, R):- 
%%    (try_each1([], P1, [], N2, P2, N1, T, R); 
%%    try_each1([], P2, [], N1, P1, N2, T, R)).

%% This is the source of the nondeterminism in resolve/4.
%% The purpose of resolve2 is to call try_each1 two ways.

resolve2([P1, N1], [P2, N2], T, R):- 
    try_each1([], P1, [], N2, P2, N1, T, R).

resolve2([P1, N1], [P2, N2], T, R):- 
    try_each1([], P2, [], N1, P1, N2, T, R).
    %% = the same thing again with [P2,N2] and [P1,N1] swapped.


%% try_each1(Pos1,Pos2,Neg1,Neg2,Pos3,Neg3,Target,Result)
%%  Performs resolution, deterministically.
%%  Pos1...Pos3 and Neg1...Neg3 are lists of literals.
%%  As best I understand it, we're resolving Pos2 against Neg2.
%%  Pos1 and Neg1 are state variables that are initially empty lists.
%%  Clause 2 "then" clause of -> : 
%%    If first element of Pos2 matches first element of Neg2,
%%    eliminate that element and recurse.
%%  Clause 2 "else" clause of -> :
%%    If not, then move the first element of Pos2 onto Pos1
%%    and try the next element.
%%  Clause 1:
%%    If Neg2 is empty, switch arguments around somehow (I suspect a bug!)
%%    and recurse.


%% Clause 0, unneeded
%% try_each1(X, [], Y, [], _, _, _, _):- !, fail.  % not needed

%% Clause 1
try_each1(X, [Y|Z], Q, [], Xs, Qs, T, R):- !,
    try_each1([Y|X], Z, [], Xs, Qs, Q, T, R).   %% I deeply suspect a typo here.  Let's see!
%%    try_each1([Y|X], Z, [], Q, Xs, Qs, T, R).   %% Covington's hypothetically corrected version of this line
%%     To my astonishment, the change had no effect on run time or results.
%%     To my further astonishment, commenting out Clause 1 entirely did not slow the program down!
%%     I am reverting to the original code in case there's some effect I'm not aware of.

%% Clause 2, effectively 2 clauses due to the -> structure
try_each1(X, [Y|Z], Q, [W|V], Xs, Qs, T, R):- 
    (Y = W -> merge(X, Z, Q, V, Xs, Qs, T, R); 
    try_each1(X, [Y|Z], [W|Q], V, Xs, Qs, T, R)).


/*
  Note that this will have to be changed later when we do the 
  multiple resolutions.
*/
%% The cut appears misplaced here.  merge/8 is called only from here.
%% Combines multiple lists of positive and negative literals.
merge(Pos1, Pos2, Neg1, Neg2, Pos3, Neg3, T, [[R, T]]):-  %% !,
    append(Pos1, Pos2, Pos12), append(Pos12, Pos3, Pos123),
    append(Neg1, Neg2, Neg12), append(Neg12, Neg3, Neg123),
    sort(Pos123, PosSorted),                         %% apparently always already sorted but this sort takes very little time
    sort(Neg123, NegSorted),                         %% often called on one-element lists
    clean_up_res(NegSorted, PosSorted, R).           %% reordered args: clean_up_res(PosSorted, NegSorted, R).

%
% do not detect tautologies for now!!
%

%% clean_up_res(Positives, Negatives, Result)
%% combines the two lists into one list putting not(...) around the negative literals.
%%clean_up_res(Pos, [], Pos):- !.
%%clean_up_res(Pos, [N|Negs], Result):- %% !,
%%    clean_up_res([not(N)|Pos], Negs, Result).

%% Rewritten so the shrinking list comes first and the algorithm is simpler:
%%clean_up_res([N|Neg],Pos,[not(N)|Result]) :- clean_up_res(Neg,Pos,Result).
%%clean_up_res([],Pos,Pos).

%% Rewritten again to build the new list backward, which seems to help overall speed
clean_up_res([], Pos, Pos).
clean_up_res([N|Negs], Pos, Result):- %% !,
    clean_up_res(Negs, [not(N)|Pos], Result).


%% I think this is just making extra work for separate_lits -- are we combining
%% the lists merely so we can take them apart again???



