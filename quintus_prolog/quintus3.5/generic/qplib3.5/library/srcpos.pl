/*  SCCS   : @(#)srcpos.pl	63.2 05/20/91
    File   : srcpos.pl
    Authors: Peter Schachte
    Purpose: The QUI debugger: Find procedures, clauses & goals in source code
    Origin : March 1990

        +--------------------------------------------------------+
        | WARNING: This material is CONFIDENTIAL and proprietary |
        |          to Quintus Computer Systems Inc.              |
        |                                                        |
        |  Copyright (C) 1990                                    |
        |  Quintus Computer Systems Inc.  All rights reserved.   |
        |                                                        |
        +--------------------------------------------------------+
*/

:- module(source_position, [
	source_position/4,
	source_position/5,
	source_position/12
]).

:- use_module(library(directory), [file_property/3]).
:- use_module(library(occurs), [contains_var/2]).
:- use_module(library(basics), [member/2]).

:- dynamic
	pre_scanned_file/3,
	source_position_cache/8,
	end_of_this_pred/1,
	highest_old_clause/1.

%   NB:  This code does not properly handle code to be term-expanded,
%	 including grammar rules.  Grammar rules could be handled, but
%	 term_expansion in general cannot, since it is not safe to call
%	 expand_term on-the-fly.  This is because there is no rule
%	 against term_expansion clauses having side-effects which
%	 should not be repeated.  There is also no way to associate
%	 a term in the source with a goal in the result of term_expansion.


% source_position(+File, ?Pred, -Start, -End)
% Can be used to find the start and end position of Pred in File.
% Positions are reported as character positions; line number and
% column are not included.

source_position(File, Pred0, Start, End) :-
	split_pred(Pred0, user, Module, Pred, Name, Arity),
	absfile(File, Absfile),
	on_exception(E,
		pred_at_pos_in_file(Module, Name, Arity, File, Absfile,
			Start, End),
		replace_error_goal(E,
			source_position(File,Pred0,Start,End), 1)),
	functor(Pred, Name, Arity).


% source_position(+File, ?Pred, ?Clausenum, -Start, -End)
% Can be used to find the start and end position of clause number Clausenum
% of Pred in File.  Positions are reported as character positions; line
% number and column are not included.

source_position(File, Pred0, Clausenum, Start, End) :-
	split_pred(Pred0, user, Module, Pred, Name, Arity),
	absfile(File, Absfile),
	on_exception(E,
		clause_at_pos_in_file(Module, Name, Arity, Clausenum, File,
			Absfile, Start, End, _),
		replace_error_goal(E,
			source_position(File,Pred0,Clausenum,Start,End), 1)),
	functor(Pred, Name, Arity).


% source_position(+File, ?Pred, ?Clausenum, ?Calledpred, ?Callnum,
%	-Clause, -Callterm, -Vars, -Start, -End, -Functorstart, -Functorend)
% Start, End, Functorstart, and Functorend are integer character
% positions in File, counting the first character as 0, describing
% the position of the Callnum call to Calledpred in the Clausenum clause
% of predicate Pred.  As a special case, iff Calledpred is 'head' and
% Callnum is 0, then the positions refer to the head of clause.  In
% either case, Start is the first char of the subgoal or clause head,
% End is the first character AFTER the subgoal or clause head, and
% Functorstart and Functorend are the first character of and the first
% character after the principle functor of the subgoal or clause head,
% respectively.  Callterm is the actual goal, Clause is the actual clause,
% and Vars is a list of Varname=Var terms, where Varname is the name of
% the variable as an atom, and Var is the actual variable, as in Callterm.

source_position(File, Pred0, Clausenum, Calledpred0, Callnum, Clause,
		Callterm, Vars, Start, End, Functorstart, Functorend) :-
	split_pred(Pred0, user, Module, Pred, Name, Arity),
	split_pred(Calledpred0, user, Calledmodule, Calledpred,
		Calledname, Calledarity),
	absfile(File, Absfile),
	on_exception(E,
		goal_at_pos_in_file(Module, Name, Arity, Clausenum,
			Calledmodule, Calledname, Calledarity, Callnum, File,
			Absfile, Clause, Callterm, Vars, Start, End,
			Functorstart, Functorend),
		replace_error_goal(E,
			source_position(File,Pred0,Clausenum,Calledpred,
				Callnum,Clause,Callterm,Vars,Start,End,
				Functorstart,Functorend),
			1)),
	functor(Pred, Name, Arity),
	(   Callnum =:= 0 -> Calledpred = head
	;   functor(Calledpred, Calledname, Calledarity)
	).



%  replace_error_goal(+Error_term, +Goal, +Culprit)
%  re-signal Error_term, only with Goal and Culprit in place of Error_term's
%  goal and culprit.

replace_error_goal(Error_term, Goal, Culprit0) :-
	Error_term  =.. [Error, _, Culprit1| Rest],
	(   integer(Culprit1) -> Culprit = Culprit0
	;   Culprit = Culprit1
	),
	Error_term1 =.. [Error, Goal, Culprit| Rest],
	raise_exception(Error_term1).


%  pred_at_pos_in_file(?Module, ?Name, ?Arity, +File, +Absfile, -Start, -End)
%  the predicate Module:Name/Arity is defined in File starting at position
%  Start and ending at End.

pred_at_pos_in_file(Module, Name, Arity, File, Absfile, Start, End) :-
	(   pre_scanned_file(Absfile, Date, _),
	    get_file_time(Absfile, Date) ->
		(   atom(Name), atom(Module), integer(Arity) ->
%			proc(Module,Name,Arity) = Hash
			hash_term(proc(Module,Name,Arity), Hash)
		;   true			% don't care about Hash
		),
		source_position_cache(Hash, Module, Name, Arity, 1,
			Absfile, Start, _),
		(   source_position_cache(Hash, Module, Name, Arity, _,
			    Absfile, _, End0),
		    retractall(end_of_this_pred(_)),
		    assert(end_of_this_pred(End0)),
		    fail
		;   retract(end_of_this_pred(End))
		)
	;   atom(File),
	    get_file_time(Absfile, Date) ->
		retractall(source_position_cache(_,_,_,_,_,Absfile,_,_)),
		retractall(pre_scanned_file(Absfile,_,_)),
		open_file_or_stream(File, Stream),
		module_and_first_clause(Stream, Defmod, Clause1, Pos1),
		collect_positions(Stream, Clause1, Pos1, Defmod, Poses),
		maybe_close_stream(File, Stream),
		cache_source_positions(Poses, 0, 0, 0, 0, 0, Absfile),
		assert(pre_scanned_file(Absfile,Date,Defmod)),
		pred_position(Poses, Module, Name, Arity, Start, End)
	;   open_file_or_stream(File, Stream),
	    module_and_first_clause(Stream, Defmod, Clause1, Pos1),
	    collect_positions(Stream, Clause1, Pos1, Defmod, Poses),
	    maybe_close_stream(File, Stream),
	    pred_position(Poses, Module, Name, Arity, Start, End)
	).


	    
%  clause_at_pos_in_file(?Module, ?Name, ?Arity, ?Clausenum, +File, +Absfile,
%	-Start, -End, -Defmod)
%  Clause Clausenum of predicate Module:Name/Arity is defined in File
%  starting at position Start and ending at End.  Defmod is the module
%  this file is in.

clause_at_pos_in_file(Module, Name, Arity, Clausenum, File, Absfile,
		Start, End, Defmod) :-
	(   pre_scanned_file(Absfile, Date, Defmod),
	    get_file_time(Absfile, Date) ->
		(   atom(Name), atom(Module), integer(Arity) ->
%			proc(Module,Name,Arity) = Hash
			hash_term(proc(Module,Name,Arity), Hash)
		;   true			% don't care about Hash
		),
		source_position_cache(Hash, Module, Name, Arity, Clausenum,
			Absfile, Start, End)
	;   atom(File),
	    get_file_time(Absfile, Date) ->
		retractall(source_position_cache(_,_,_,_,_,Absfile,_,_)),
		retractall(pre_scanned_file(Absfile,_,_)),
		open_file_or_stream(File, Stream),
		module_and_first_clause(Stream, Defmod, Clause1, Pos1),
		collect_positions(Stream, Clause1, Pos1, Defmod, Poses),
		maybe_close_stream(File, Stream),
		cache_source_positions(Poses, 0, 0, 0, 0, 0, Absfile),
		assert(pre_scanned_file(Absfile,Date,Defmod)),
		clause_position(Poses, 0, Module, 0, Name, 0, Arity, 0,
			Clausenum, Start, End)
	;   open_file_or_stream(File, Stream),
	    module_and_first_clause(Stream, Defmod, Clause1, Pos1),
	    collect_positions(Stream, Clause1, Pos1, Defmod, Poses),
	    maybe_close_stream(File, Stream),
	    clause_position(Poses, 0, Module, 0, Name, 0, Arity, 0,
		    Clausenum, Start, End)
	).


%  goal_at_pos_in_file(?Module, ?Name, ?Arity, ?Clausenum, ?Calledmodule,
%	?Calledname, ?Calledarity, ?Callnum, +File, +Absfile, -Callterm,
%	-Vars, -Start, -End, -Functorstart, -Functorend)
%  Clause Clausenum of predicate Module:Name/Arity is defined in File
%  starting at position Start and ending at End.

goal_at_pos_in_file(Module, Name, Arity, Clausenum,
		Calledmodule, Calledname, Calledarity, Callnum,
		File, Absfile, Clause, Callterm, Vars, Start, End,
		Functorstart, Functorend) :-
	clause_at_pos_in_file(Module, Name, Arity, Clausenum, File,
		Absfile, Clausestart, _, Defmod),
	open_file_or_stream(File, Stream),
	seek(Stream, Clausestart, bof, _),
%	stream_position(Stream, _, '$stream_position'(Clausestart,1,1,0,0)),
	my_read_term(Stream, [subterm_positions(Poses),variable_names(Vars0)],
		Clause),
	maybe_close_stream(File, Stream),
	subgoal_position(Clause, Poses, Defmod, Calledmodule, Calledname,
		Calledarity, Callnum, Callterm, Start, End,
		Functorstart, Functorend),
	mentioned_vars(Vars0, Callterm, Vars).


%  pred_position(+Poses, -Module, -Name, -Arity, -Start, -End)
%  the predicate Module:Name/Arity is defined starting at position
%  Start and ending at End, according to Poses, which is a list of
%  clause_pos(Module,Name,Arity,Start,End) terms, one for each clause
%  in a file.

pred_position([clause_pos(M,N,A,S,E0)|Rest0],
		Module, Name, Arity, Start, End) :-
	pred_end(Rest0, M, N, A, E0, E, Rest),
	(   M=Module, N=Name, A=Arity, S=Start, E=End
	;   pred_position(Rest, Module, Name, Arity, Start, End)
	).


%  pred_end(+Poses, +Module, +Name, +Arity, +End0, -End, -Rest)
%  the predicate Module:Name/Arity ends at End, according to Poses.
%  End0 is the end of the previous clause (so the end of Module:Name/Arity
%  if the first element of Poses isn't for that procedure).

pred_end([clause_pos(M,N,A,_,E1)|Rest0], M, N, A, _, E, Rest) :-
	!,
	pred_end(Rest0, M, N, A, E1, E, Rest).
pred_end(L, _, _, _, E, E, L).


%  clause_position(+Poses, +Module0, -Module, +Name0, -Name, +Arity0, -Arity,
%	+Clausenum0, -Clausnum, -Start, -End)
%  Clause Clausenum for predicate Module:Name/Arity starts at position
%  Start and ends at End, according to Poses, which is a list of
%  clause_pos(Module,Name,Arity,Start,End) terms, one for each clause
%  in a file.  Module0, Name0, Arity0, and Clausenum0 are the data
%  for the previous clause.

clause_position([clause_pos(M,N,A,S,E)|Rest0],
		M0, Module, N0, Name, A0, Arity, C0, Clausenum,	Start, End) :-
	(   M0 == M, N0 == N, A0 == A ->	% same pred
		    C1 = C0
	;   C1 = 1				% new pred
	),
	(   Module = M,
	    Name = N,
	    Arity = A,
	    Clausenum = C1,
	    Start = S,
	    End = E
	;   C2 is C1+1,
	    clause_position(Rest0, M, Module, N, Name, A, Arity, C2,
		    Clausenum, Start, End)
	).


%  cache_source_positions(+Poses, +Module, +Name, +Arity, +Hash,
%	+Clausenum, +File)
%  Poses is a list of positions of clauses in File; cache them to make
%  subsequent lookup faster.  Module, Name, Arity, and Clausenum
%  describe the previous clause.

cache_source_positions([], _, _, _, _, _, _).
cache_source_positions([clause_pos(M,N,A,S,E)|Rest],
		M0, N0, A0, Hash0, C0, File) :-
	(   M0 == M, N0 == N, A0 == A ->	% same pred
		    C is C0 + 1,
		    Hash = Hash0
	;   hash_term(proc(M,N,A), Hash),
%	    proc(M,N,A) = Hash
	    retractall(highest_old_clause(_)),
	    (   source_position_cache(Hash,M,N,A,C1,File,_,_),
		retractall(highest_old_clause(_)),
		assert(highest_old_clause(C1)),
		fail
	    ;   highest_old_clause(C1) -> C is C1+1	% discontiguous clause
	    ;   C = 1					% first clause
	    )
	),
	assert(source_position_cache(Hash,M,N,A,C,File,S,E)),
	cache_source_positions(Rest, M, N, A, Hash, C, File).



%  module_and_first_clause(+Stream, -Module, -Clause, -Pos)
%  Clause and Pos are the first possible clause in File, to which
%  Stream is already opened.  Module is the module
%  this file is in.  If the file is not a module file and has
%  not been loaded, Module will be assumed to be user, which
%  may well be wrong.

module_and_first_clause(Stream, Module, Clause, Pos) :-
	my_read_term(Stream, [term_position(Spos0)], Decl),
	stream_char_position(Spos0, Pos0),
	(   Decl = :-(module(Module,_)) ->
		my_read_term(Stream, [term_position(Spos)], Clause),
		stream_char_position(Spos, Pos)
	;   Clause = Decl,
	    Pos = Pos0,
	    Module = user
	).

%  collect_positions(+Stream, +Clause0, +Start0, +Defmod, -Poses)
%  Poses is a list of the clauses read from Stream and their
%  start and end positions.  Clause0 and Start0 are the first clause
%  on this stream and its start position.  Defmod is the module this
%  stream is "in."

collect_positions(Stream, Clause0, Start0, Defmod, Poses) :-
	(   Clause0 == end_of_file ->
		Poses = []
	;   clause_for(Clause0, Defmod, Module, Name, Arity) ->
		Poses = [clause_pos(Module,Name,Arity,Start0,End)|Poses1],
		stream_position(Stream, Send),
		stream_char_position(Send, End),
		my_read_term(Stream, [term_position(Snextpos)], Next),
		stream_char_position(Snextpos, Nextpos),
		collect_positions(Stream, Next, Nextpos, Defmod, Poses1)
	;   my_read_term(Stream, [term_position(Snextpos)], Next),
	    stream_char_position(Snextpos, Nextpos),
	    collect_positions(Stream, Next, Nextpos, Defmod, Poses)
	).


%  clause_for(+Term, +Defmod, -Module, -Name, -Arity)
%  Term is a clause for Module:Name/Arity.  Defmod is the default module.

clause_for(Module0:Term, _, Module, Name, Arity) :-
	!,
	clause_for(Term, Module0, Module, Name, Arity).
clause_for((Head:-_), Defmod, Module, Name, Arity) :-
	!,
	head_for(Head, Defmod, Module, Name, Arity).
clause_for((:- _), _, _, _, _) :- !, fail.
clause_for((?- _), _, _, _, _) :- !, fail.
clause_for(Unit, Defmod, Module, Name, Arity) :-
	!,
	head_for(Unit, Defmod, Module, Name, Arity).


%  head_for(+Term, +Defmod, -Module, -Name, -Arity)
%  Term is the head of a clause for Module:Name/Arity.  Defmod is the
%  default module.

head_for(Module0:Term, _, Module, Name, Arity) :-
	!,
	head_for(Term, Module0, Module, Name, Arity).
head_for(Head, Defmod, Defmod, Name, Arity) :-
	functor(Head, Name, Arity).


clause_pos_parts(_:Cl, term_position(_,_,_,_,Clpos), Head, Headpos,
		Body, Bodypos) :-
	!,
	clause_pos_parts(Cl, Clpos, Head, Headpos, Body, Bodypos).
clause_pos_parts((Head:-Body), term_position(_,_,_,_,[Headpos,Bodypos]),
		Head, Headpos, Body, Bodypos) :-
	!.
clause_pos_parts(Head, Headpos, Head, Headpos, true, 0-0).


split_pred(Pred0, Module0, Module, Pred, Name, Arity) :-
	(   var(Pred0) ->
		Module0 = Module,
		Pred = Pred0
	;   Pred0 = Module1:Pred1 ->
		split_pred(Pred1, Module1, Module, Pred, Name, Arity)
	;   Module0 = Module,
	    Pred = Pred0,
	    functor(Pred, Name, Arity)
	).


pos_term_position(Start-End, Start, End, Start, End).
pos_term_position(term_position(Start,End,Fstart,Fend,_),
		Start, End, Fstart, Fend).


subgoal_position(Clause, Poses, Defmod, Calledmodule, Calledname, Calledarity,
		Callnum, Callterm, Start, End, Functorstart, Functorend) :-
	clause_pos_parts(Clause, Poses, Head, Hpos, Body, Bpos),
	(   atom(Calledmodule), atom(Calledname), integer(Calledarity),
	    integer(Callnum) ->			% special case:  go fast
		(   Callnum =:= 0 ->		% means clause head
			Gpos = Hpos,
			Callterm = Head
		;   find_matching_goal(Body, Bpos, Defmod, Calledmodule,
			    Calledname, Calledarity, Callnum, _, Callterm,
			    Gpos),
		    nonvar(Gpos)
		)
	;   Gpos = Hpos,
	    Callnum = 0,
	    Callterm = Head
	;   Body \== true,
	    subgoal_poses(Body, Bpos, Defmod, [], _, [], Goalposes),
	    member(goalpos(Calledmodule,Calledname,Calledarity,Callnum,
			Callterm,Gpos),
		    Goalposes)
	),
	pos_term_position(Gpos, Start, End, Functorstart, Functorend).


%  find_matching_goal(+Head, +Poses, +Defmod, +Module, +Name, +Arity, +N0,
%	-N, -Callterm, -Gpos)

find_matching_goal(Var, T0, _, Module, Name, Arity, N0, N, Callterm, T) :-
	var(Var),
	!,
	(   Module == user,
	    Name == call,
	    Arity =:= 1 ->
		N is N0-1,
		(   N =:= 0 ->
			T = T0,
			Callterm = call(Var)
		;   true
		)
	;   N = N0
	).
find_matching_goal(Goal, term_position(_,_,_,_,[T1,T2]),
		Defmod, Module, Name, Arity, N0, N, Callterm, T) :-
	functor(Goal, Conj, 2),
	(Conj == ',' ; Conj == ';' ; Conj == '->'),
    	!,
	arg(1, Goal, X),
	find_matching_goal(X, T1, Defmod, Module, Name, Arity, N0, N1,
		Callterm, T),
	(   N1 > 0 ->
		arg(2, Goal, Y),
		find_matching_goal(Y, T2, Defmod, Module, Name, Arity, N1, N,
			Callterm, T)
	;   N = N1
	).
find_matching_goal(\+(X), term_position(_,_,_,_,[T1]),
		Defmod, Module, Name, Arity, N0, N, Callterm, T) :-
	!,
	find_matching_goal(X, T1, Defmod, Module, Name, Arity, N0, N,
		Callterm, T).
find_matching_goal(:(Defmod,X), term_position(_,_,_,_,[_,T1]),
		_, Module, Name, Arity, N0, N, Callterm, T) :-
	atom(Defmod),
	nonvar(X),
	!,
	find_matching_goal(X, T1, Defmod, Module, Name, Arity, N0, N,
		Callterm, T).
find_matching_goal(on_exception(_,X,Y), term_position(_,_,_,_,[_,T1,T2]),
		Defmod, Module, Name, Arity, N0, N, Callterm, T) :-
    	!,
	find_matching_goal(X, T1, Defmod, Module, Name, Arity, N0, N1,
		Callterm, T),
	(   N1 > 0 ->
		find_matching_goal(Y, T2, Defmod, Module, Name, Arity, N1, N,
			Callterm, T)
	;   N = N1
	).
find_matching_goal(Goal, T0, Defmod, Module, Name, Arity, N0, N, Callterm,
		T) :-
	(   functor(Goal, Name, Arity) ->	% might match
		(   (   Defmod == Module -> true
		    ;   Module == 0 -> true	% indicates built_in
		    ;   imported(Goal, Module, Defmod)
		    ) ->
			N is N0-1,
			(   N =:= 0 ->
				T = T0,
				Callterm = Goal
			;   true
			)
		;   N = N0
		)
	;   N = N0
	).


%  subgoal_poses(+Head, +Poses, +Defmod, +Rlist0, Rlist, +List0, -List)

%  subgoal_poses(+Goal, +Poses, +Defmod, +Rlist0, -Rlist, +List0, -List)
%  List is a list of goalpos/6 terms, one for each subgoal in Goal,
%  followed by List0.

subgoal_poses(Var, T0, _, Rlist, [Elt|Rlist], List, [Elt|List]) :-
	var(Var),
	!,
	(   member(goalpos(user,call,1,N0,_,_), Rlist) ->
		N is N0+1
	;   N = 1
	),
	Elt = goalpos(user,call,1,N,call(Var),T0).
subgoal_poses(Goal, term_position(_,_,_,_,[T1,T2]),
		Defmod, Rlist0, Rlist, List0, List) :-
	functor(Goal, Conj, 2),
	(Conj == ',' ; Conj == ';' ; Conj == '->') ->
    	!,
	arg(1, Goal, X),
	subgoal_poses(X, T1, Defmod, Rlist0, Rlist1, List1, List),
	arg(2, Goal, Y),
	subgoal_poses(Y, T2, Defmod, Rlist1, Rlist, List0, List1).
subgoal_poses(\+(X), term_position(_,_,_,_,[T1]),
		Defmod, Rlist0, Rlist, List0, List) :-
	!,
	subgoal_poses(X, T1, Defmod, Rlist0, Rlist, List0, List).
subgoal_poses(:(Defmod,X), term_position(_,_,_,_,[_,T1]),
		_, Rlist0, Rlist, List0, List) :-
	!,
	subgoal_poses(X, T1, Defmod, Rlist0, Rlist, List0, List).
subgoal_poses(on_exception(_,X,Y), term_position(_,_,_,_,[_,T1,T2]),
		Defmod, Rlist0, Rlist, List0, List) :-
	!,
	subgoal_poses(X, T1, Defmod, Rlist0, Rlist1, List1, List),
	subgoal_poses(Y, T2, Defmod, Rlist1, Rlist, List0, List1).
subgoal_poses(Goal, T0, Defmod, Rlist0, [Element|Rlist0],
		List, [Element|List]) :-
	functor(Goal, Name, Arity),
	(   member(goalpos(Defmod,Name,Arity,N0,_,_), Rlist0) ->
		N is N0+1
	;   N = 1
	),
	Element = goalpos(Defmod,Name,Arity,N,Goal,T0).



absfile(File, Absfile) :-
	(   File == user -> fail
	;   current_stream(Absfile,read,Stream), Stream=File -> true
	;   absolute_file_name(File, Absfile)
	).


open_file_or_stream(File, Stream) :-
	(   current_stream(_,read,Stream), Stream=File -> true
	;   open(File, read, [binary, seek(byte)], Stream)
	).


maybe_close_stream(File, Stream) :-
	(   File == Stream -> true
	;   close(Stream)
	).

my_read_term(Stream, Opts, Term) :-
	on_exception(syntax_error(_,_,_,_,_),
		read_term(Stream, [syntax_errors(error)|Opts], Term),
		my_read_term(Stream, Opts, Term)	% keep trying
	).

get_file_time(Absfile, Time) :-
	on_exception(_,
		absolute_file_name(Absfile, [access(read)], _),
		fail),
	file_property(Absfile, modify_time, Time).

stream_char_position('$stream_position'(Pos,_,_,_,_), Pos).

mentioned_vars([], _, []).
mentioned_vars([Bindings|Rest], Term, L) :-
	Bindings = (_=Var),
	(   contains_var(Var, Term) ->
		L = [Bindings|L0]
	;   L = L0
	),
	mentioned_vars(Rest, Term, L0).

imported(Goal, From, Into) :-
	predicate_property(Into:Goal, Prop),
	(   Prop = built_in
	;   Prop = imported_from(From)
	;   Prop = imported_from(Intermed),
	    imported(Goal, From, Intermed)
	),
	!.
