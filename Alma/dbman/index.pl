/*
File: dbman/index.pl
By: kpurang
What: code to do with indexing and getting nodes.

Todo: index first arg too
      make this into an external c function that will be more efficient
      tna the prolog indexing

*/

%% Done (M.C.):
%%   Found that replacing the name-append-name sequence with concat_atom is no speedup
%%   Found that changing hash_it to do 2nd-arg indexing instead of 1st-arg is a big speedup


%% Comments:
%%   This file implements the indexing system, including a form of first-argument indexing.
%%	 The coding style here involves a lot of code repeated with very small variations.
%%   I have reworked the indentation on clauses that use nested '->' operators.
    

%% Covington comments begin with %%

%% Indentation reworked by M. Covington 2011/1/9 to improve readability of '->' notation.

%:- ensure_loaded(library(arg)).
%:- ensure_loaded(library(sets)).

%% The purpose of these predicates is to create and use the indexing system,
%% which consists of clauses like these:
%%
%% node_index(Hash, PositiveNodes, NegativeNodes)
%% %% for example:
%% node_index(1788,[52,50],[]).
%% node_index('end$$',[],[53,52,51]).
%% node_index(1943,[55],[58]).
%% ...
%% pred2hash(functor, list of hashes)
%% %% for example:
%% pred2hash(done_token_utt_comma,[2446,'done_token_utt_comma$$']).
%% pred2hash(pop_off_utt_queue,[2256,'pop_off_utt_queue$$']).
%% pred2hash(deleted,[2191,2276,2357]).
%% ...
%% new_node_index(1788,[],[]).
%% new_node_index('end$$',[],[]).
%% ...
%% newpred2hash(has,[]).
%% newpred2hash(isa,[1024,1147,1124,1126,1127,1120,1125,1122,1121,1111]).
%% newpred2hash(begin,[]).

%% Predicates in which the information is stored:

%% new_node_index is used in:  index.pl (ds.pl to declare it, ui.pl and toplevel.pl only for retractall)
%% node_index:    same
%% pred2hash:     same
%% newpred2hash:  same

% node_index(H, L1, L2)
% H is a hash value
% L1 is a list of nodes where the term correspomding to H occurs +vely
% L2 is a list of nodes where the term correspomding to H occurs -vely
% one of the hashvalues will be the predname itself fro the case that 
% the arg is a var
% :- dynamic node_index/3.
% :- dynamic new_node_index/3.

% pred2hash(P, H)
% P is a predicate name
% H is a list of hash values as above that P occurs in
% :- dynamic pred2hash/2.


%% Predicates that perform storage operations:
%%
%% index_nodes:    used in cleaning.pl, handle_contra.pl, and index.pl
%%
%% index_new_node: used in index.pl, makenodes.pl, 
%%                         loop.pl, loop_old.pl, xint.pl, xint_old.pl, bcres.pl, 
%%                         eval.pl, misc.pl, process_lits.pl
%%
%% unindex:  called from cleaning.pl, delete.pl, index.pl, misc.pl, handle_contra.pl, loop.pl, perhaps others
%%
%% unindex_new_done: called from loop.pl, loop_old.pl
%% unindexnewone: called from cleaning.pl, handle_contra.pl

%% Predicates that perform retrieval operations:

%% match_form: called (a lot) from process_lits.pl, handle_contra.pl, ui.pl, misc.pl, production.pl
%%    (this is the main place the lookup is performed)
%%
%% match_new_form:  called from production.pl
%%
%% intersectnodes:  called from index.pl, addndel.pl, access.pl, cleaning.pl, delete.pl
%% intersectnewnodes:  called from index.pl, cleaning.pl
%% variant_nodes: called from cleaning.pl
%% get_variant: called from access.pl, delete.pl, addndel.pl, and index.pl
%% get_subsumers: called from addndel.pl and index.pl

%% Critique:
%%
%%    This file is not the work of an adept Prolog programmer.
%%    Lots of code is repeated; append is used instead of concat_atom;
%%    However, the search appears to be being done in a relatively efficient way.
%%
%%    There may be appreciable time to be saved in the set operations (add_element
%%    and union), which are probably searching each list more times than needed.  Here
%%    are the profiler results on union:
%%
%%     user:union/3 calls:384960 choicepts:0 redos:0 time:20
%%        calledby(100,142613,user:match_form/3,1,1)
%%        calledby(0,141688,user:match_new_form/3,1,1)
%%        calledby(0,84995,user:unionallofem/4,2,1)
%%        calledby(0,14958,user:match_form/3,1,2)
%%        calledby(0,706,user:unionallofemnew/4,2,1)
%%     sets:union/3 calls:384960 choicepts:17768803 redos:17768266 time:45740
%%        calledby(100,384960,user:union/3,1,1)
%%
%%    Given the overall level of uncertainty evinced by the programmer,
%%    there is ground for concern about *correctness* here.


% node_index(H, L1, L2)
% H is a hash value
% L1 is a list of nodes where the term correspomding to H occurs +vely
% L2 is a list of nodes where the term correspomding to H occurs -vely
% one of the hashvalues will be the predname itself fro the case that 
% the arg is a var
% :- dynamic node_index/3.
% :- dynamic new_node_index/3.

% pred2hash(P, H)
% P is a predicate name
% H is a list of hash values as above that P occurs in
% :- dynamic pred2hash/2.









%
%  feb 01
% kp tries to make one general version that can use differnetn indices
%   selected by a parameter to the predicate.
% do that so that we can also index the old nodes instead of deleting them
%   this will hopefully make it easier to find if \phi was in the kb at t
%

% first, given a term, append _index to it and return. Use that as a name 
% for the new index.
%
%  effort abandoned: too much work, not enough benefits.

%% This is never called.
get_index_name(In, Out):- !,
    name(In, DIn),
    append(DIn, [95,105,110,100,101,120], Dllk),
    name(Out, Dllk).



%XXX says that the above has been modified for 1starg indexing

% index_nodes(+List of nodes)
% given a list of nodes, find the predicates they contain and their 
% polarities and insert in the func_node table

%% Performs insert_one on each of the literals in each of the nodes.

%
% NEED TO USE THE STANDARD NODE ACCESS HERE
%    done feb 01 kp
%
% index_nodes([]):- !.
% index_nodes([node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9)|Y]):- !,
%     get_formula(node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9), F),
%     insert_node_table(A0, F),
%     index_nodes(Y).

index_nodes([]):- !.
index_nodes([Node1|Y]):- !,
    get_formula(Node1, F),
    get_name(Node1, A0),
    insert_node_table(A0, F),
    index_nodes(Y).



% index_new_node(+a node)
% given a node, find the literals it contains and their 
% polarities and insert in the func_new_node table
% index_new_node(new_node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9)):- !,
%     get_formula(new_node(A0, A1, A2, A3, A4, A5, A6, A7, A8, A9), F),
%     insert_new_node_table(A0, F).

index_new_node(Node1):- !,
    get_formula(Node1, F),
    get_name(Node1, A0),
    debug_stream(DBGS), print(DBGS, 'insert new node table'), nl(DBGS),
    insert_new_node_table(A0, F).

%% Performs insert_new_node on the node and all its literals.    
    

% given a node name and its formulas, insert the name in the appropriate
% indices

insert_node_table(_, []):- !.
insert_node_table(N, [F1|Fn]):- !,
    insert_one(N, F1),
    insert_node_table(N, Fn).

% just the above for one literal

%% If no more literals (formulas), stop.
insert_one(_, []):- !.
%% Why [] ?  Is this clause ever used? 
%% This would apply only if there were a literal of the form [] inside the list of literals.
%% I think this is confused programming and he meant to look for the end of the list,
%% which he did elsewhere.

insert_one(Name, not(N)):- %% For NEGATIVE literals
    !,
    hash_it(N, H),
    (debug_level(3) -> 
        (
            debug_stream(DBGS), print(DBGS, 'Inserting not: '), print(DBGS, not(N)), print(DBGS, H), nl(DBGS)
        )
    ; 
        true
    ),    
    (var(H) -> %% it could not be hashed, so we will add '$$' to end of principal functor and use that
        (
            functor(N, Fu, _),
            name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(F, FVAR),  %% should be concat_atom
            (retract(node_index(F, PL, MI)) ->
                (
                    append([Name], MI, MII),
                    assert(node_index(F, PL, MII))   %% node_index for this hash exists, so add the nodename to the SECOND list
                    %% Was a step left out?  Should we also be doing pred2hash in this situation, like below?
                )
            ;
                (
                    assert(node_index(F, [], [Name])),   %% node_index for this hash does not exist, so create a new node_index clause
                    (retract(pred2hash(Fu, P2H)) ->      %% and also see if a pred2hash clause is needed
                        (
                            append([F], P2H, PP2H),
                            assert(pred2hash(Fu, PP2H))
                        )
                    ;
                        (
                            assert(pred2hash(Fu, [F]))
                        )
                    )
                )
            )
        )
    ; %% it was successfully hashed giving H as its hash code
        (
            (retract(node_index(H, PH, MH)) ->   %% Like the above, but using the hash code rather than the functor with $$
                (
                    append([Name], MH, MMH),
                    assert(node_index(H, PH, MMH)),
                    functor(N, F, _),
                    (retract(pred2hash(F, F2H)) ->
                        (
                           append([H], F2H, FFH),
                            assert(pred2hash(F, FFH))
                        )
                    ;
                        (
                            assert(pred2hash(F, [H]))
                        )
                    )
                )
            ;
                (
                    assert(node_index(H, [], [Name])),
                    functor(N, F, _),
                    (retract(pred2hash(F, F2H)) ->
                        (
                            append([H], F2H, FFH),
                            assert(pred2hash(F, FFH))
                        )
                    ;
                        (
                            assert(pred2hash(F, [H]))
                        )
                    )
                )
            )
        )
    ).

    %% This is the most involute use of -> notation I've ever seen. -- MC
      
insert_one(Name, N):-  %% for POSITIVE literals.  N is not of the form not(...).
    %% This is like the preceding clause except that it works on the FIRST of the lists in node_index.
    %% All of the same comments apply.
    !,
    (debug_level(3) -> 
        (
            debug_stream(DBGS), print(DBGS, 'Inserting: '), print(DBGS, N), print(DBGS, H), nl(DBGS)
        )
    ; 
        true
    ),    
    hash_it(N, H),
    (var(H) -> 
        (
            functor(N, Fu, _),
            name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(F, FVAR),
            (retract(node_index(F, PL, MI)) ->
                (
                    append([Name], PL, PLL),
                    assert(node_index(F, PLL, MI))
                )
            ;
                (
                    assert(node_index(F, [Name], [])),
                    (retract(pred2hash(Fu, P2H)) ->
                        (
                            append([F], P2H, PP2H),
                            assert(pred2hash(Fu, PP2H))
                        )
                    ;
                        (
                            assert(pred2hash(Fu, [F]))
                        )
                    )
                )
            )
        )
    ;  %% not var(H)...
        (
            (retract(node_index(H, PH, MH)) ->
                (
                    append([Name], PH, PPH),
                    assert(node_index(H, PPH, MH)),
                    functor(N, F, _),
                    %
                    % must be a bug here. added this then it does not even start 
                    %
                    (retract(pred2hash(F, Fh)) -> 
                        (
                            append([H], Fh, Fhh),
                            assert(pred2hash(F, Fhh))
                        )
                    ;
                        assert(pred2hash(F, [H]))
                    )
                )
            ;
            (
                assert(node_index(H, [Name], [])),
                functor(N, F, _),
                (retract(pred2hash(F, F2H)) ->
                    (
                        append([H], F2H, FFH),
                        assert(pred2hash(F, FFH))
                    )
                ;
                    (   
                        assert(pred2hash(F, [H]))
                    )
                )
            )
        )
    )
).
    

% given a node name and its formulas, insert the name in the appropriate
% indices

insert_new_node_table(_, []):- !.
%% Why [] ?  Is this clause ever used?   See similar comments above.


insert_new_node_table(N, [F1|Fn]):- !,
    insert_new_one(N, F1),
    debug_stream(DBGS), print(DBGS, 'insert new one'),nl(DBGS),print(DBGS, 'N = '),print(DBGS,N),nl(DBGS),print(DBGS, 'F1 = '),print(DBGS,F1),nl(DBGS),print(DBGS, 'Fn = '),print(DBGS, Fn),nl(DBGS),
    insert_new_node_table(N, Fn).

% just the above for one literal


%% insert_new_one is just like insert_one but it operates on new_node_index and newpred2hash.
%% See extensive comments on insert_one clauses above.

insert_new_one(_, []):- !.
%% Why [] ?  Is this clause ever used?  See similar comments above.

insert_new_one(Name, not(N)):- !,
    hash_it(N, H),
    ( debug_level(3) -> 
        (
            debug_stream(DBGS), print(DBGS, 'Inserting new not: '), print(DBGS, not(N)), 
            print(DBGS, H), nl(DBGS)
        )
    ; 
        true
    ),    
    (var(H) -> 
        (
            functor(N, Fu, _),
            name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(F, FVAR),
            (retract(new_node_index(F, PL, MI)) ->
                (
                    append([Name], MI, MII),
                    assert(new_node_index(F, PL, MII))
                )
            ;
                (
                    assert(new_node_index(F, [], [Name])),
                    (retract(newpred2hash(Fu, P2H)) ->
                        (   
                            append([F], P2H, PP2H),
                            assert(newpred2hash(Fu, PP2H))
                        )
                    ;
                        (
                            assert(newpred2hash(Fu, [F]))
                        )
                    )
                )
            )
        )
    ;  %% not var(H)...
        (
            (retract(new_node_index(H, PH, MH)) ->
            (
                append([Name], MH, MMH),
                assert(new_node_index(H, PH, MMH)),
                functor(N, F, _),
                (retract(newpred2hash(F, F2H)) ->
                    (
                        append([H], F2H, FFH),
                        assert(newpred2hash(F, FFH))
                    )
                ;
                    (
                        assert(newpred2hash(F, [H]))
                    )
                )
            )
            ;
            (
                assert(new_node_index(H, [], [Name])),
                functor(N, F, _),
                (
                    retract(newpred2hash(F, F2H)) ->
                    (
                        append([H], F2H, FFH),
                        assert(newpred2hash(F, FFH))
                    )
                ;
                    (
                        assert(newpred2hash(F, [H]))
                    )
                )
            )
        )
    )
).

insert_new_one(Name, N):- !,
    hash_it(N, H),
    (debug_level(3) -> 
        (
            debug_stream(DBGS), print(DBGS, 'Inserting new: '), print(DBGS, N),
            print(DBGS, H), nl(DBGS)
        )
    ; 
        true
    ),    
    (var(H) -> 
        (
        	debug_stream(DBGS), print(DBGS, 'variable'),nl(DBGS),
            functor(N, Fu, _),
            name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(F, FVAR),
            (retract(new_node_index(F, PL, MI)) ->
                (
                    append([Name], PL, PLL),
                    assert(new_node_index(F, PLL, MI))
                )
            ;
                (
                    assert(new_node_index(F, [Name], [])),
                    (retract(newpred2hash(Fu, P2H)) ->
                        (
                            append([F], P2H, PP2H),
                            assert(newpred2hash(Fu, PP2H))
                        )
                    ;
                        (
                            assert(newpred2hash(Fu, [F]))
                        )
                    )
                )
            )
        )
    ;  %% not var(H)...
        (
        	debug_stream(DBGS), print(DBGS,'not variable'),nl(DBGS),
            (retract(new_node_index(H, PH, MH)) ->
            (
            	debug_stream(DBGS), print(DBGS, 'after retract new node'),nl(DBGS),
                append([Name], PH, PPH),
                assert(new_node_index(H, PPH, MH)),
                functor(N, F, _),
                (retract(newpred2hash(F, Fh)) -> 
                    (
                    	debug_stream(DBGS), print(DBGS,'retract newpred2hash'),nl(DBGS),
                        append([H], Fh, Fhh),
                        assert(newpred2hash(F, Fhh))
                    )
                ; (
                debug_stream(DBGS), print(DBGS,'not retract hash'),nl(DBGS),
                    assert(newpred2hash(F, [H]))
                    )
                )
            )
            ;
            (
            	debug_stream(DBGS), print(DBGS, 'no new nodes to retract'),nl(DBGS),
                assert(new_node_index(H, [Name], [])),
                functor(N, F, _),
                (retract(newpred2hash(F, F2H)) ->
                    (
                        debug_stream(DBGS), print(DBGS,'retract newpred2hash'),nl(DBGS),
                        append([H], F2H, FFH),
                        assert(newpred2hash(F, FFH))
                    )
                ;
                    (
                        debug_stream(DBGS), print(DBGS,'not retract hash'),nl(DBGS),
                		assert(newpred2hash(F, [H]))
                    )
                )
            )
        )
    )
).
    

% if first arg is constant, OK
% if is var, return var
% if dont exist, return functorname
% so the things with var go where?? stick it in functorname$$

%% hash_it takes a literal and returns a hash code, as follows:
%% if it is atomic, return it unchanged;
%% if it is a structure with first arg nonvar, use hash_term on it, generating an integer;
%% if it is a structure with first arg unknown, return an uninstantiated variable.
%%    (Later code, in many separate places, then concatenates '$$' to the original functor and uses that.)
%% This strikes me as strange in many ways.  But they key idea is that an uninstantiated hash means unindexable.

%% hash_it is called only from within this file, index.pl.

%%hash_it(C, H):- !,
%%    functor(C, F, N),
%%    (N >= 1 ->
%%        (
%%            %% It is a structure with arguments
%%            arg(1, C, A),
%%            (var(A) ->
%%                (
%%                    %% First arg is uninstantiated, so don't instantiate the hash code
%%                    true
%%                )
%%            ;
%%                (
%%                    %% Get the principal functor of first argument; hash_term on F and FF.
%%                    functor(A, FF, _),
%%                    hash_term([F, FF], H)
%%                )
%%            )
%%        )
%%    ;
%%        (
%%            %% It's atomic
%%            H = F
%%        )
%%    ),
%%    (debug_level(3) -> 
%%          (debug_stream(DBGS), print(DBGS, 'Hash: '), print(DBGS, H), 
%%           nl(DBGS)); true).


%% The following version whimsically implements 2nd-arg indexing instead of 1st-arg indexing
%
%hash_it(C, H):- !,
%    functor(C, F, N),
%    (N >= 2 ->
%        (
%            %% It is a structure with arguments
%            arg(2, C, A),
%            (var(A) ->
%                (
%                    %% %% Second arg is uninstantiated, so don't instantiate the hash code
%                    %% This is strange, but apparently required for correctness.
%                    true
%                )
%            ;
%                (
%                    %% Get the principal functor of second argument; hash_term on F and FF.
%                    functor(A, FF, _),
%                    hash_term([F, FF], H)
%                )
%            )
%        )
%    ;
%        (
%            %% It's atomic or has 1 argument; use its principal functor
%            functor(C, H, _)
%        )
%    ),
%    (debug_level(3) -> 
%          (debug_stream(DBGS), print(DBGS, 'Hash: '), print(DBGS, H), 
%           nl(DBGS)); true).





%% Covington's rewrite of hash_it into more conventional Prolog code
%% This version does second-argument indexing

hash_it(Term, Hash) :-
  functor(Term, Functor, Arity),
  hash_aux(Term, Functor, Arity, Hash),
  (debug_level(3) -> (debug_stream(DBGS), print(DBGS, 'Hash: '), print(DBGS, H), nl(DBGS)); true).

%hash_aux(Term, Functor, Arity, Hash) :-
%  % It's a candidate for third-argument indexing
%  Arity >= 3,
%  !,
%  arg(3, Term, Arg3),
%  hash_with_arg(Functor, Arg3, Hash).
 
%hash_aux(Term, Functor, Arity, Hash) :-
%  % It's a candidate for second-and-third-argument indexing
%  Arity >= 3,
%  !,
%  arg(2, Term, Arg2),
%  arg(3, Term, Arg3),
%  hash23(Functor, Arg2, Arg3, Hash).
 
hash_aux(Term, Functor, Arity, Hash) :-
  % It's a candidate for 2nd argument indexing
  %(Functor == 'has' ; Functor == 'isa'),
  Arity >= 2,
  !,
  arg(2, Term, Arg2),
  hash_with_arg(Functor, Arg2, Hash).

%hash_aux(Term, Functor, Arity, Hash) :-
%  % It's a candidate for 1st argument indexing
%  Arity >= 1,
%  !,
%  arg(1, Term, Arg1),
%  hash_with_arg(Functor, Arg1, Hash).

hash_aux(Term, _, _, Hash) :-
  % It's none of those, so use its principal functor
  functor(Term, Hash, _).


%% Performs hashing for second-and-third-argument indexing

hash23(Functor, Arg2, Arg3, _) :-
  % Unindexable because Arg2 or Arg3 is uninstantiated, so return Hash uninstantiated
  (var(Arg2) ; var(Arg3)),
  !.

hash23(Functor, Arg2, Hash) :-
  functor(Arg2, Arg2Functor, _),
  functor(Arg3, Arg3Functor, _),
  hash_term((Functor,Arg2Functor,Arg3Functor), Hash).




%% Performs hashing for one-argument indexing

hash_with_arg(Functor, Arg, _) :-
  % Unindexable because arg2 is uninstantiated, so return Hash uninstantiated
  var(Arg), 
  !.

hash_with_arg(Functor, Arg, Hash) :-
  functor(Arg, ArgFunctor, _),
  hash_term((Functor,ArgFunctor), Hash).



%XXX


% TODO THIS ONE LATER
% looks like this is used to delete formulas given only the clause. we need 
% to find the nodes that contains all the literals we are interestef in, in
% the appropriate polarity
% intersect_nodes(+[Predicate, Pol] list, -Intersection)
% given a predicate list, find all the sets of nodes that contain all 
% these predicates and intersect all the sets, keeping track of polarities
% intersection is a set of names of nodes.
/*
can't work with the pred/pol thing.
need to get the actual clause.

DO NOT USE THIS 

intersect_nodes(P, I):- 
    get_all_sets(P, [], SP), !,
    intersection(SP, I).
intersect_nodes(_, []).

intersect_new_nodes(P, I):- 
    get_all_new_sets(P, [], SP), !,
    intersection(SP, I).
intersect_new_nodes(_, []).

*/

/* dumping quintus source here for now */
%   intersection(+ListOfSets, ?Intersection)
%   is true when Intersection is the intersection of all the sets in
%   ListOfSets.  The order of elements in Intersection is taken from
%   the first set in ListOfSets.  This has been turned inside out to
%   minimise the storage turnover.

intersection([Set|Sets], Intersection) :-
	intersection1(Set, Sets, Intersection).

intersection1([], _, []).
intersection1([Element|Elements], Sets, Intersection) :-
	memberchk_all(Sets, Element),
	!,
	Intersection = [Element|Rest],
	intersection1(Elements, Sets, Rest).
intersection1([_|Elements], Sets, Intersection) :-
	intersection1(Elements, Sets, Intersection).

memberchk_all([], _).
memberchk_all([Set|Sets], Element) :-
	memberchk(Element, Set),
	memberchk_all(Sets, Element).
/* end dumping quintus source here for now */

%% intersectnodes:  called from index.pl, addndel.pl, access.pl, cleaning.pl, delete.pl

intersectnodes(Form, Intersect):- 
    getallsets(Form, [], SP), !,
    intersection(SP, Intersect). % SP is set of sets; /3's are same
intersectnodes(_, []).

%% intersectnewnodes:  called from index.pl, cleaning.pl

intersectnewnodes(Form, Intersect):- 
    getallnewsets(Form, [], SP), !,
    intersection(SP, Intersect). %
intersectnewnodes(_, []).


% given a formula, make a list of the nodes that could be that formula
% for each clause.

%% Called only within index.pl.

getallsets([], X, X):- !.

getallsets([not(F)|FR], In, Out):- !,
    hash_it(F, H),
    (var(H) ->
       (
          functor(F, Fu, _),
          name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR), 
          node_index(Ff, _, S1), 
          getallsets(FR, [S1|In], Out)
       )
    ;
       (
          node_index(H, _, S1),
          getallsets(FR, [S1|In], Out)
       )
    ).

getallsets([F|FR], In, Out):- !,
    hash_it(F, H),
    (var(H) ->
       (
          functor(F, Fu, _),
          name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),  
          node_index(Ff, S1, _), 
          getallsets(FR, [S1|In], Out)
       )
    ;
       (
          node_index(H, S1, _),
          getallsets(FR, [S1|In], Out)
       )
    ).

%% getallnewsets: called only within index.pl

getallnewsets([], X, X):- !.

getallnewsets([not(F)|FR], In, Out):- !,
    hash_it(F, H),
    (var(H) ->
       (
          functor(F, Fu, _),
          name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),
          new_node_index(Ff, _, S1), 
          getallnewsets(FR, [S1|In], Out)
       )
    ;
       (
          new_node_index(H, _, S1),
          getallnewsets(FR, [S1|In], Out)
       )
    ).

getallnewsets([F|FR], In, Out):- !,
    hash_it(F, H),
    (var(H) ->
       (
          functor(F, Fu, _),
          name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),
          new_node_index(Ff, S1, _), 
          getallnewsets(FR, [S1|In], Out)
       )
    ;
       (
          new_node_index(H, S1, _),
          getallnewsets(FR, [S1|In], Out)
       )
    ).


    


%
% WHAT IS THIS FOR
% AND WHAT IS IT DOING HERE???
%% You asked that, I didn't!  But I would have!

% variant_nodes(+Node, +Node list)
% if there is a node in Node list that is similar to Node, succeed.
% A and B are similar if E A subssubsumes B and B subsumes A
% nov 24: i now return the list of similar guys.

%% variant_nodes: called from cleaning.pl

variant_nodes(_, [], []):- !.
variant_nodes(N, [X|Y], [X|Z]):-
    get_form(N, NF),
    get_form(X, XF),
    variant_lits(NF, XF), !,
    variant_nodes(N, Y, Z). 
variant_nodes(N, [X|Y], Z):-
    variant_nodes(N, Y, Z).

% nov 24. new variant lits. sort the formulas then find if they are
% variants. the previous version was finding too many variants
% i should not be doing this list to ord set business so many times.
% make sure all forms are always ord_sets.

%% variant_lits: called only within index.pl

variant_lits(X, Y):- !,
    list_to_ord_set(X, Xo),
    list_to_ord_set(Y, Yo),
    variant(Xo, Yo).

/* 
variant_lits([], []):- !.
variant_lits([X|Y], [Q|W]):-
    variant(X, Q), !,
    variant_lits(Y, W).
variant_lits([X|Y], [Q|W]):-
    find_variant(X, W, WW), !,
    variant_lits(Y, [Q|WW]).
*/

%% find_variant: called only within index.pl

find_variant(_, [], _):- !, fail.
find_variant(X, [Z|Y], Y):-
    variant(X, Z), !.
find_variant(X, [Z|Y], [Z|QQ]):-
    find_variant(X, Y, QQ), !.

% get_variant(+Form, +List of nodes, -Variant)
% return the node whose formula is form, else fail

%% get_variant: called from access.pl, delete.pl, addndel.pl, and index.pl

get_variant(_, [], _):- fail.
get_variant(NF, [X|Y], X):-
    get_form(X, XF),
    variant_lits(NF, XF), !.
get_variant(N, [X|Y], V):-
    get_variant(N, Y, V).

% get_unifiers(+Form, +List of nodes, Unifiers, -FInalUnifiers)
% return the nodes that unify with Form

%% get_unifiers: called only within index.pl

get_unifiers(_, [], X, X):- !.
get_unifiers(NF, [X|Y], IZ, FZ):-
    get_form(X, XF),
    XF = NF, !,
    get_unifiers(NF, Y, [X|IZ], FZ).
get_unifiers(NF, [X|Y], IZ, FZ):-
    get_form(X, XF), !,
    get_unifiers(NF, Y, IZ, FZ).

% get_subsumers(+Form, +List of nodes, Subs, -FInalSuba)
% return the nodes that Form subsumes

%% get_subsumers: called from addndel.pl and index.pl

get_subsumers(_, [], X, X):- !.
get_subsumers(NF, [X|Y], IZ, FZ):-
    get_form(X, XF),
%    XF = NF, !,
    subsumes_chk(NF, XF), !,
    get_subsumers(NF, Y, [X|IZ], FZ).
get_subsumers(NF, [X|Y], IZ, FZ):-
    get_subsumers(NF, Y, IZ, FZ).





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ok things look good down below.

%
% THIS TO BE CHANGED TO UNINDEX(NODE, FORMULA)
%




%% unindex:  called from cleaning.pl, delete.pl, index.pl, misc.pl, handle_contra.pl, loop.pl, perhaps others

% IS OK this interface
% unindex(+Node, +Name)
% remove indices for Name in lists of form predicates.
unindex(Node, Name):- !,
    get_formula(Node, Form),
    unindexone(Form, Name).
% Form is a list of literals

unindexone([], _):- !.

unindexone([not(F)|FR], Name):- !,
    hash_it(F, H),
    ( debug_level(3) -> (debug_stream(DBGS), print(DBGS, 'Unindexing: '), print(DBGS, not(F)), print(DBGS, H), nl(DBGS)); true),    
    (var(H) ->
       (
          functor(F, Fu, _),
          name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR), 
          retract(node_index(Ff, Sp, S1)), 
          %del_element(Name, S1, S2),
          delete(S1, Name, S1),
          ((Sp = [], S2 = []) -> 
              (
                   retract(pred2hash(Fu, P2h1)),
                   %del_element(Ff, P2h1, P2h2),
                   delete(P2h1, Ff, P2h2),
                   assert(node_index(Ff, Sp, S2)),
                   assert(pred2hash(Fu, P2h2))
              )
          ;
              assert(node_index(Ff, Sp, S2))
          )
       )
    ;
       (
          retract(node_index(H, Sp, S1)),
          %del_element(Name, S1, S2),
          delete(S1, Name, S2),
          ((Sp = [], S2 = []) -> 
             (
                functor(F, Fun, _),
                retract(pred2hash(Fun, P2h1)),
                %del_element(H, P2h1, P2h2),
                delete(P2h1, H, P2h2),
                assert(node_index(H, Sp, S2)),
                assert(pred2hash(Fun, P2h2))
             )
          ;
             assert(node_index(H, Sp, S2))
          )
       )
    ),
    unindexone(FR, Name).
    
unindexone([F|FR], Name):- 
    !,
    hash_it(F, H),
    ( debug_level(3) -> (debug_stream(DBGS), print(DBGS, 'Unindexing: '), print(DBGS, F), print(DBGS, H), nl(DBGS)); true),    
    (var(H) ->
        (
            functor(F, Fu, _),
            name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR), 
            retract(node_index(Ff, S1, Sm)), 
            %del_element(Name, S1, S2),
            delete(S1, Name, S2),
            ((Sm = [], S2 = []) -> 
                (
                    retract(pred2hash(Fu, P2h1)),
                    %del_element(Ff, P2h1, P2h2),
                    delete(P2h1, Ff, P2h2),
                    assert(node_index(Ff, S2, Sm)),
                    assert(pred2hash(Fu, P2h2))
                )
            ;
                assert(node_index(Ff, S2, Sm))
            )
        )
    ;
        (
            retract(node_index(H, S1, Sm)),
            %del_element(Name, S1, S2),
            delete(S1, Name, S2),
            ((Sm = [], S2 = []) -> 
                (
                    functor(F, Fun, _),
                    retract(pred2hash(Fun, P2h1)),
                    delete(P2h1, H, P2h2),
                    assert(node_index(H, S2, Sm)),
                    assert(pred2hash(Fun, P2h2))
                )
            ;
                assert(node_index(H, S2, Sm))
            )
        )
    ),
    unindexone(FR, Name).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% called from loop.pl, loop_old.pl
unindex_new_done:- 
    retract(done_new(X)), 
    get_formula(X, Forms),
    get_name(X, Name),
    unindexnewone(Forms, Name),
    retract(X),
    fail.
    
unindex_new_done:- !.

%% called from cleaning.pl, handle_contra.pl
unindexnewone([], _):- !.

unindexnewone([not(F)|FR], Name):- !,
    hash_it(F, H),
    ( debug_level(3) -> (debug_stream(DBGS), print(DBGS, 'Unindexing: '), print(DBGS, not(F)), print(DBGS, H), nl(DBGS)); true),    
    (var(H) ->
        (
            functor(F, Fu, _),
            name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),
            retract(new_node_index(Ff, Sp, S1)), 
            delete(S1, Name, S2),
            ((Sp = [] , S2 = []) -> 
                (
                    retract(newpred2hash(Fu, P2h1)),
                    delete(P2h1, Ff, P2h2),
                    assert(newpred2hash(Fu, P2h2)),
                    assert(new_node_index(Ff, Sp, S2))
                    % we need to have this above coz there can be many occurrences of the same
                    % pred in one formula. later we can test for teh existence of the new_node_
                    % index before doing the retraction.
                )
            ;
                assert(new_node_index(Ff, Sp, S2))
            )
        )
    ;
        (
            retract(new_node_index(H, Sp, S1)),
            delete(S1, Name, S2),
            ((Sp = [] , S2 = []) -> 
                (
                    functor(F, Fun, _),
                    retract(newpred2hash(Fun, P2h1)),
                    delete(P2h1, H, P2h2),
                    assert(new_node_index(H, Sp, S2)),
                    assert(newpred2hash(Fun, P2h2))
                )
            ; 
                assert(new_node_index(H, Sp, S2))
            )
        )
    ),
    unindexnewone(FR, Name).
    
unindexnewone([F|FR], Name):- !,
    hash_it(F, H),
    ( debug_level(3) -> (debug_stream(DBGS), print(DBGS, 'Unindexing: '), print(DBGS, F), print(DBGS, H), nl(DBGS)); true),    
    (var(H) ->
        (
            functor(F, Fu, _),
            name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),
            retract(new_node_index(Ff, S1, Sm)), 
            delete(S1, Name, S2),
            ((Sm = [] , S2 = []) -> 
                (
                    retract(newpred2hash(Fu, P2h1)),
                    delete(P2h1, Ff, P2h2),
                    assert(new_node_index(Ff, S2, Sm)),
                    assert(newpred2hash(Fu, P2h2))
                )
            ;
                assert(new_node_index(Ff, S2, Sm))
            )
        )
    ;
        (
            retract(new_node_index(H, S1, Sm)),
            delete(S1, Name, S2),
            ((Sm = [] , S2 = []) -> 
                (
                    functor(F, Fun, _),
                    retract(newpred2hash(Fun, P2h1)),
                    delete(P2h1, H, P2h2),
                    assert(new_node_index(H, S2, Sm)),
                    assert(newpred2hash(Fun, P2h2))
                )
            ; 
                assert(new_node_index(H, S2, Sm))
            )
        )
    ),
    unindexnewone(FR, Name).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% % 

% here we try to
% isolate all accesses to the table mapping predicates to nodes.

% given a node and a polarity, return the clauses in which this clause
% appears with that polarity

% this will be changed to do the new style indexing.

% REPLACE THESE BY MATCH_FORM(FORM, POL, SET)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% match_form(F, Pol, Set)
% F is a literal
% Pol is plus or minus
% Set is the set of nodes that contain things that match the literal and are 
% of the opposite polarity
% SHOULD IT BE SAME POL? MIGHT GET CONFUSING MEBBE 2 VERSINOS

/*
get the functor
find the hash value
if it is a variable, union all the guys in the pred2hash for this functor
if it is a constant, get the guys in the corresponding thing and union
  the ones inthe variable ones.

*/

% SAME POLARITY HERE!!!!!!! so can substitute in predtonode BUT at pred2node,
% need to give the OPPOSITE polarity.

% should really take care of cases where there is no match. do not want
% thisto just die. on the other habd, don't want backtracking. :( Maybe best
% to have a "clean_node_index" etc that does the right thing
%

%% match_form: called (a lot) from process_lits.pl, handle_contra.pl, ui.pl, misc.pl, production.pl

match_form(F, Pol, S):- 
    !,
    hash_it(F, H),
    (debug_level(3) -> (debug_stream(DBGS), print(DBGS, 'Matching: '), print(DBGS, F), print(DBGS, H), nl(DBGS)) ; true ),    
    (var(H) ->					  % arg1 var
          (
             functor(F, Fu, _),
             cpred2hash(Fu, Flist),
             unionallofem(Flist, Pol, [], S)
          )
    ;
        (Pol = plus ->				  % positive
             (
                  cnode_index(H, S1, _),
                  functor(F, Fu, _),
                  (Fu = H -> 
                      S = S1			  % no arg
                  ;
                      (
                         name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),
                         cnode_index(Ff, S2, _),
                         union(S1, S2, S)
                      )
                  )
             )
        ; % Pol is not plus
             (
                  cnode_index(H, _, S1),
                  functor(F, Fu, _),
                  (Fu = H -> 
                      S = S1
                  ;
                      (
                         name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),
                         cnode_index(Ff, _, S2),
                         union(S1, S2, S)
                      )
                  )
             )
        )
    ).

%% match_new_form:  called from production.pl

match_new_form(F, Pol, S):- 
    !,
    hash_it(F, H),
    ( debug_level(3) -> (debug_stream(DBGS), print(DBGS, 'Matching new: '), print(DBGS, F), print(DBGS, H), nl(DBGS)); true),    
    (var(H)->					  % arg1 var
        (
           functor(F, Fu, _),
           cnewpred2hash(Fu, Flist),
           unionallofemnew(Flist, Pol, [], S)
        )
    ;
        (Pol = plus ->				  % positive
           (
              cnew_node_index(H, S1, _),
              functor(F, Fu, _),
              (Fu = H -> 
                  S = S1			  % no arg
              ;
                 (
                     name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),
                     cnew_node_index(Ff, S2, _),
                     union(S1, S2, S)
                 )
              )
           )
        ;  % Pol is not plus
           (
              cnew_node_index(H, _, S1),
              functor(F, Fu, _),
              (Fu = H -> 
                   S = S1
              ;
                   (
                       name(Fu, FUNC), append(FUNC, [36, 36], FVAR), name(Ff, FVAR),
                       cnew_node_index(Ff, _, S2),
                       union(S1, S2, S)
                   )
              )
            )
        )
    ).

cnode_index(F, P, M):-
    node_index(F, P, M), !.
cnode_index(_, [], []):- !.
cnew_node_index(F, P, M):-
    new_node_index(F, P, M), !.
cnew_node_index(_, [], []):- !.
cpred2hash(X, Y):-
    pred2hash(X, Y), !.
cpred2hash(_, []):- !.
cnewpred2hash(X, Y):-
    newpred2hash(X, Y), !.
cnewpred2hash(_, []):- !.


%% I think this is a time sink.  Surely the list should be checked for duplicates only once.
unionallofem([], _, X, X):- !.
unionallofem([X|XR], plus, In, Out):- !,
    node_index(X, P, _),
    union(P, In, Int),
    unionallofem(XR, plus, Int, Out).
unionallofem([X|XR], minus, In, Out):- !,
    node_index(X, _, P),
    union(P, In, Int),
    unionallofem(XR, minus, Int, Out).

%% Same comment applies.
unionallofemnew([], _, X, X):- !.
unionallofemnew([X|XR], plus, In, Out):- !,
    new_node_index(X, P, _),
    union(P, In, Int),
    unionallofem(XR, plus, Int, Out).
unionallofemnew([X|XR], minus, In, Out):- !,
    new_node_index(X, _, P),
    union(P, In, Int),
    unionallofem(XR, minus, Int, Out).



/*
Test cases:
assert:
*/
insert_test:- 
    insert_one(1, foo(a, 1)),
    insert_one(11, foo(a, 11)),
    insert_one(2, foo(b, 2)),
    insert_one(22, foo(b, 22)),
    insert_one(3, foo(c, 3)),
    insert_one(33, foo(c, 33)),
    insert_one(4, foo(X, 4)),
    insert_one(5, foo(Y, 5)),
    insert_one(6, foo(d(e), 6)),
    insert_one(7, foo(f(g), 7)).

% looks like tings are OK


dump_kb(F):-
    open(F, 'write', S),
    tell(S),
    listing(node),
    listing(node_index),
    listing(pred2hash),
    listing(new_node),
    listing(new_node_index),
    listing(newpred2hash),
    close(S).


% node_index(H, L1, L2)
% H is a hash value
% L1 is a list of nodes where the term correspomding to H occurs +vely
% L2 is a list of nodes where the term correspomding to H occurs -vely
% one of the hashvalues will be the predname itself fro the case that 
% the arg is a var
% :- dynamic node_index/3.
% :- dynamic new_node_index/3.

% pred2hash(P, H)
% P is a predicate name
% H is a list of hash values as above that P occurs in
% :- dynamic pred2hash/2.

