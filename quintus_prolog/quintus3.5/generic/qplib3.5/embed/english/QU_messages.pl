/* SCCS   : %W% %G%
   File   : QU_messages.pl
   Author : Tom Howland
   Origin : 1990
   Purpose: standard parse of Quintus message terms.
*/

:- module('QU_messages', [
	generate_message/3,
	query_abbreviation/3
   ]).

:- multifile 
	generate_message/3,
	msg/3,
	commandtype/3,
	contexttype/3,
	typename/3,
	operation/3,
	resource/3,
	query_abbreviation/3.

/* first, the parse of standard error terms */

generate_message(system_error(M))-->
    ['System error'-[],nl],
    message(M).

generate_message(resource_error(Goal,Resource,Spec)) -->
    ['Resource error'-[]],
    resource(Resource),
    [nl],
    message(Spec),
    goal(Goal).

generate_message(representation_error(Goal,ArgNo,Message)) -->
    ['Representation error'-[]],
    head(Goal,ArgNo),
    message(Message),
    goal(Goal).

generate_message(instantiation_error(Goal,ArgNo)) -->
    ['Instantiation error'-[]],
    head(Goal,ArgNo),
    goal(Goal).

generate_message(type_error(Goal,ArgNo,TypeName,Culprit)) -->
    ['Type error'-[]],
    head(Goal,ArgNo),
    type(TypeName,Culprit),
    goal(Goal).

generate_message(domain_error(Goal,ArgNo,DomainName,Culprit,Message)) -->
    ['Domain error'-[]],
    head(Goal,ArgNo),
    type(DomainName,Culprit),
    message(Message),
    goal(Goal).

generate_message(existence_error(Goal,ArgNo,ObjectType,Culprit,Message)) -->
    ['Existence error'-[]],
    existence_message(Goal,ArgNo,ObjectType,Culprit,Message).

generate_message(permission_error(Goal,Operation,ObjectType,Culprit,Message)) -->
    (	{Operation=(dynamic)}
    ->	['Permission error: ~q is '-[Culprit]],
	typename(ObjectType),
	[', but must be dynamic.'-[], nl]
    ;	['Permission error: cannot '-[]],
        operation(Operation),
	[' '-[]],
        typename(ObjectType),
	culprit(Culprit)
    ),
    message(Message),
    goal(Goal).

generate_message(consistency_error(Goal,Culprit1,Culprit2,Message)) -->
    (	{Culprit1 == 0, Culprit2 == 0}
    ->	[]
    ;	['Consistency error: ~q and ~q are inconsistent'-[Culprit1,Culprit2],nl]
    ),
    message(Message),
    goal(Goal).

generate_message(context_error(Goal,ContextType,CommandType)) -->
    ['Context error: '-[]],
    commandtype(CommandType),
    (	{ContextType = not(C)} -> [' did not appear '-[]]
    ;   {ContextType = when(C)} -> [' when '-[]]
    ;	{ContextType = C}, [' appeared '-[]]
    ),
    contexttype(C),
    [nl],
    goal(Goal).

generate_message(range_error(Goal,ArgNo,TypeName,Culprit)) -->
    ['Range error'-[]],
    head( Goal, ArgNo),
    type(TypeName, Culprit),
    goal(Goal).

generate_message(syntax_error(Goal,Position,Message,Left,Right,File))-->
    ['Syntax error'-[]],
    head(Goal, 0),
    message(Message),
    position(Position, File),
    bad_tokens(Left),
    ['<<here>>'-[],nl],
    bad_tokens(Right),
    goal(Goal).

/********** the parse of system messages ***********************/

generate_message(usage(Utility)) -->
	['~Nusage: ~w [-cvhDHMN] [-o output] [-i initfile]'-[Utility],nl,
	 '       [-L library-directory]'-[],nl,
	 '       [-a quintus-product]'-[],nl,
	 '       [-f path-name:path-spec]'-[],nl,
	 '       [-F path-name:path-spec]'-[],nl,
	 '       [-p path-name]'-[],nl,
	 '       filename... [ -QLD qld-options]'-[],nl].

generate_message(contradictory_flags(Utility, Flag1, Flag2)) -->
	['~N~w: ~w flag may not be used in conjunction with ~w'-[Utility,
		Flag1,Flag2],nl].

generate_message(multiple_flags(Utility, Flag)) -->
	['~N~w: multiple ~w flags'-[Utility,Flag],nl].

generate_message(missing_argument(Utility, Flag)) -->
	['~N~w: argument missing for -~a flag'-[Utility,Flag],nl].
	
generate_message(debugger(standard_help)) -->
	[nl, 'Debugging options:'-[], nl, nl,
' <cr>   creep      p      print         r [i]  retry i      @    command'-[],nl,
'  c     creep      w      write         f [i]  fail i       b    break'-[],nl,
'  l     leap       d      display                           a    abort'-[],nl,
'  s [i] skip i                                              h    help'-[],nl,
'  z     zip        g [n]  n ancestors   +      spy pred     ?    help'-[],nl,
'  n     nonstop    < [n]  set depth     -      nospy pred   =    debugging'-[],nl,
'  q     quasi-skip .      find defn     e      raise_exception'-[],nl].


generate_message(debugger(retrying)) -->
	[nl, 'Retrying goal'-[], nl, nl].

generate_message(debugger(leashing,Type,[])) -->
	!,
	['No ~wleashing'-[Type], nl].
generate_message(debugger(leashing,Type,Ports)) -->
	!,
	['Using ~wleashing stopping at ~w ports'-[Type,Ports], nl].

generate_message(debugger(ancestors)) -->
	[nl, '[Ancestors:]'-[], nl].
generate_message(debugger(no_ancestors)) -->
	[nl, '[No ancestors]'-[], nl].

generate_message(debugger(Style,Err,Prefix,Invoc,Depth,Extra,Port,
		       Goal,PDep,Flag)) -->
	debug_term(Err, Style, PDep),
	debug_prefix(Prefix),
	debug_invocation(Invoc),
	debug_depth(Depth),
	debug_port(Port),
	debug_extra(Extra),
	debug_term(Goal, Style, PDep),
	(   {Flag \== prompt} ->
		[nl]
	;   [' ?'-[], nl]
	).

generate_message(debugger(spypoints,[],[])) -->
	!,
	[nl, 'There are no spypoints'-[], nl].
generate_message(debugger(spypoints,L1,L2)) -->
	!,
	(   {L1 \== []} ->
		[nl, 'Predicate spypoints:'-[], nl, nl],
		spyspec_lines(L1)
	;   []
	),
	(   {L2 \== []} ->
		[nl, 'Call spypoints:'-[], nl, nl],
		spyspec_lines(L2)
	;   []
	).

generate_message(debugger_error(Error, _TraceState)) -->
	['User debugger signalled error'-[], nl],
	generate_message(Error).

generate_message(debugger_print_depth(D)) -->
	( {D =:= 0} ->
	      ['Debugger print depth now has no limit'-[],nl]
	; ['Debugger print depth set to ~w'-[D],nl]
	).

generate_message(undefined_message(Severity,Message)) -->
    ['Undefined '-[]],
    severity(Severity),
    [' message: ~q'-[Message],nl].

generate_message(top_level(user,0,nodebug)) -->
    !,
    [].
generate_message(top_level(Module,Level,Dstate)) -->
    optional_info(Module, user, '[', ' ', Before1),
    optional_info(Level, 0, Before1, ' ', Before2),
    optional_info(Dstate, nodebug, Before2, ' ', _),
    [']'-[], nl].

generate_message(advice(X, Kind, Spyspec)) -->
    advice(X, Kind, Spyspec),
    [nl].

generate_message(spy(X, Kind, Spyspec)) -->
    advice(X, Kind, Spyspec),
    [nl].

generate_message(spy(nospyall)) -->
    ['All spypoints removed'-[],nl].

generate_message(advice(checking_enabled)) -->
    ['Advice checking enabled for all advised procedures'-[],nl].

generate_message(advice(checking_disabled)) -->
    ['All advice checking disabled'-[],nl].

generate_message(modules(not_current(M))) -->
    ['~q is not a current module.'-[M],nl].

generate_message(modules(name_mismatch,X,Y))-->
    ['module name mismatch: ~q'-[X],nl,'real module name is ~q'-[Y],nl].

generate_message(modules(import_not_exported,Name/Arity,Importer,DefMod)) -->
    ['the predicate ~q imported by module ~q'-[Name/Arity,Importer],nl,
    'is not exported by module ~q'-[DefMod],nl].

generate_message(modules(name_clash,Module,Name,Arity,DefMod,NewMod)) -->
    name_clash(Module,Name,Arity,DefMod),
    [nl],
    ignore_name_clash(Module,NewMod),
    [nl].

generate_message(module_already_loaded(Module,OldFile,File)) -->
    ['Module ''~w'' is defined in two different files:'-[Module],nl],
    old_file_new_file(OldFile,File).

generate_message(non_module_qof_file(AbsQofFile,RelFile)) -->
    ['No source file for non-module file: ~w'-[AbsQofFile],nl],
    ['~q recorded as dependency.'-[RelFile],nl].

generate_message(name_clash(Module,Name,Arity,DefMod)) -->
    name_clash(Module,Name,Arity,DefMod),
    [nl].

generate_message(name_clash(Module,Name,Arity,DefMod,NewMod)) -->
    generate_message(name_clash(Module,Name,Arity,DefMod)),
    ['override this definition with the one in ~q?'-[NewMod],
	nl].

generate_message(modules(undefined_export,Name,Arity,Module)) -->
    ['the predicate ~q/~q exported by ~q is not defined'-[Name,Arity,Module],
    nl].

generate_message(modules(undefined_meta,Pred,Module)) -->
    ['meta-predicate ~q declared in module ~q is not defined'-[Pred,Module],
    nl].

generate_message(modules(cannot_match,I,Head)) -->
    ['argument ~d of the meta_predicate clause:'-[I],nl,'~q :- ...'-[Head],nl,
    'cannot match Module:Term'-[],nl].

generate_message(reload_failed) -->
    ['Re-Loading of foreign files FAILED.'-[]].

generate_message(loading_proc(Verb,Message,Name,Arity,Module)) -->
    load_gerund(Verb),
    [' '-[]],
    load_message(Message),
    ['procedure ~q/~q in module ~q'-[Name,Arity,Module],nl].

generate_message(loading_file(Margin,Verb,File))-->
    ['~*c'-[Margin,0' ]],
    load_gerund(Verb),
    [' file ~w'-[File],nl].

generate_message(emacs_loading(Area,Verb))-->
    load_gerund(Verb),
    [' '-[]],
    load_area(Area),
    [nl].

generate_message(load_completed(Margin,FileName,Verb,Module,Time,Space))-->
    ['~*c~w '-[Margin,0' ,FileName]],
    load_past(Verb),
    [' in module ~q, ~3d sec ~D bytes'-[Module,Time,Space],nl].

generate_message(load_completed(Margin,FileName,Verb,SrcMod,Module,Time,Space))-->
    ['~*c~w '-[Margin,0' ,FileName]],
    load_past(Verb),
    [', ~3d sec ~D bytes'-[Time,Space],nl],
    ['~*cmodule ~q imported into ~q'-[Margin,0' ,Module,SrcMod],nl].

generate_message(emacs_load_completed(Area,FileName,Verb,Module,Time,Space))-->
    load_area(Area),
    load_preposition(Area),
    ['~w '-[FileName]],
    load_past(Verb),
    [' in module ~q, ~3d sec ~D bytes'-[Module,Time,Space],nl].

generate_message(emacs_load_completed(Area,FileName,Verb,SrcMod,Module,
			           Time,Space))-->
    load_area(Area),
    load_preposition(Area),
    ['~w '-[FileName]],
    load_past(Verb),
    [', ~3d sec ~D bytes'-[Time,Space],nl],
    ['module ~q imported into ~q'-[Module,SrcMod],nl].

generate_message(load_not_completed(Margin,FileName,Verb))-->
    ['~*c~w NOT '-[Margin,0' ,FileName]],
    load_past(Verb),
    [nl].

generate_message(emacs_load_not_completed(Area,FileName,Verb))-->
    load_area(Area),
    load_preposition(Area),
    ['~w '-[FileName]],
    [' NOT '-[]],
    load_past(Verb),
    [nl].

generate_message(saving_file(File))-->
    ['Saving QOF file ~w'-[File],nl].

generate_message(saved_file(File, Time))-->
    ['~w saved in ~3d sec'-[File,Time],nl].

generate_message(load_into_module(Module)) -->
    ['Load into module ~q? (y/n) '-[Module],nl].

generate_message(undefined_in_module(Name,Arity,Module))-->
    ['~q/~d is undefined in module ~p~n'-[Name,Arity,Module],nl].

generate_message(built_in(Name,Arity))-->
    ['~q/~d is a built-in predicate'-[Name,Arity],nl].

generate_message(no_source(Name,Arity))-->
    ['There is no source file for ~q/~d'-[Name,Arity],nl].

generate_message(undefined(Name,Arity))-->
    ['~q/~d is undefined'-[Name,Arity],nl].

generate_message(is_defined_in_file(Pred,FileName))-->
    ['~q is defined in the file ~a'-[Pred,FileName],nl].

generate_message(undefined_procedure_exception)-->
    ['Undefined procedures will raise an exception (''error'' option)'-[],nl].

generate_message(undefined_procedure_fail)-->
    ['Undefined procedures will just fail (''fail'' option)'-[],nl].

generate_message(foreign_load_failed(Margin))-->
    ['~*cLoading of foreign files FAILED.'-[Margin,0' ],nl].
generate_message(foreign_load_failed(Files,Margin))-->
    ['~*cLoading of foreign files FAILED: ~q'-[Margin,0' ,Files],nl].

generate_message(load_shared_failed(Margin))-->
    ['~*cLoading of foreign shared files FAILED.'-[Margin,0' ],nl].

generate_message(help)-->
    ['^C    interrupts Prolog, after which you can start tracing,'-[],nl,
     '      abort a program, or exit Prolog. (^C^C if under GNU Emacs)'-[],nl,
     '^D    sends an end-of-file to Prolog.'-[],nl,
     '      (^C^D if under GNU Emacs)'-[],nl,
     nl,
     'The prompt | ?-  appears when you are at Prolog''s top-level.'-[],nl,
     'Prolog is then waiting for a question or command.  To load clauses,'-[],
     nl,
     'use "[filename]."  (or ESC-k under Emacs to load clauses from the'-[],nl,
     'edit buffer).'-[],nl,nl,
     'To get help on a particular topic type "help(Topic)." where Topic'-[],nl,
     'is an atom.  This will give you a menu for all the help available'-[],nl,
     'on topics containing the characters in the atom Topic.  E.g.'-[],nl,
     '"help(append)." will find all information on topics to do with'-[],nl,
     'appending.'-[],nl,
     nl,
     'Type "manual(manual)." to find out about the on-line manual.'-[],nl].

generate_message(toplevel) -->	% see query_abbreviation(toplevel), below
    ['Action (";" for more choices, otherwise <return>): '-[],nl].

generate_message(warn_about_reloading(File, OldMod, Module, Goal))-->
    ['~q is already loaded into module ~q.'-[File, OldMod],nl,
     'It is now being reloaded into module ~q.'-[Module],nl],
    goal(Goal).

generate_message(old_version_of_module_exists(Module))-->
    ['Old version of module ~a exists'-[Module],nl].

generate_message(needs_reloading(Module))-->
    ['module ''~w'' needs reloading'-[Module],nl].

generate_message(recover_load_clause(Error, File, Clause))-->
    generate_message(Error),
    ['The clause being processed in ~w was ~w'-[File,Clause],nl].

generate_message(recover_load_clause(Error, File, Clause,
				     '$stream_position'(_,L,_,_,_))) -->
    generate_message(Error),
    ['The clause being processed at line ~d in ~w was ~w'-[L,File,Clause],nl].

generate_message(misplaced_meta(Term))-->
    ['meta_predicate declaration not immediately after module declaration:'-[],
    nl],
    goal((:-meta_predicate(Term))).

generate_message(command_exception(Error,Command))-->
    generate_message(Error),
    generate_message(command_failed(Command)).

generate_message(command_exception(Error,File,Command))-->
    generate_message(Error),
    generate_message(command_failed(File,Command)).

generate_message(multifile_not_declared(Name,Arity))-->
    ['multifile declaration missing for predicate ~q/~d'-[Name,Arity],nl].

generate_message(dynamic_not_declared(Name,Arity))-->
    ['dynamic declaration missing for predicate ~q/~d'-[Name,Arity],nl].

generate_message(wrong_multifile_load(Name,Arity,NewCompFlag,CompFlag))-->
    ['clauses for multifile predicate ~q/~d are being '-[Name,Arity]],
    load_past(NewCompFlag),
    [', not '-[]],
    load_past(CompFlag),
    ['.'-[],nl].

generate_message(multifile_predicate_active(Name,Arity))-->
    ['multifile predicate ~q/~d is currently active'-[Name,Arity],nl,
    'no clauses will be loaded'-[],nl].

generate_message(dynamic_in_static_multifile(Name,Arity))-->
    ['static multifile predicate ~q/~d declared dynamic'-[Name,Arity], nl].

generate_message(cannot_open(AbsFile))-->
    ['Cannot open the file ~q'-[AbsFile],nl].

generate_message(foreign_undef(Symbol))-->
    ['Unresolved foreign function: ~w'-[Symbol],nl].

generate_message(no_load_to_active_multifile(Name,Arity))-->
    ['Cannot load clauses for active multifile predicate ~q/~d'-[Name,Arity],
    nl].

generate_message(foreign_file_loaded(Margin,File))-->
    ['~*cforeign file ~a loaded'-[Margin,0' ,File],nl].

generate_message(what)-->['What?'-[],nl].

generate_message(sorry_no_help(SearchString))-->
    ['Sorry, there is no help information on ~s.'-[SearchString],nl].

generate_message(variable_not_allowed)-->
    ['Variable not allowed as argument (use lower case only)'-[],nl].

generate_message(invalid_for_qpc(Atom)) -->
    ['~a is invalid for qpc'-[Atom],nl].

generate_message(foreign_fn_linkage_failed) -->
    ['~NLinking with foreign functions failed~n'-[], nl].

generate_message(error_at(Pos)) -->
    position(Pos).

generate_message(qpc_error_at(Pos)) -->
    position(Pos).

generate_message(internal(Term)) -->
    ['Internal error: ~q'-[Term],nl].

generate_message(internal(Term, Pos)) -->
    ['Internal error: ~q'-[Term],nl],
    position(Pos).

generate_message(invalid_for_qpc(Goal, Atom, Pos)) -->
    ['~a is invalid for qpc'-[Atom],nl],
    goal(Goal),
    position(Pos).

generate_message(wrong_command_line_file_type(AbsFile, RelFile)) -->
    ['Not source or QOF file: ~q'-[AbsFile],nl],
    ['~q is not compiled'-[RelFile],nl].

generate_message(version(Release,Banner))-->
    ['Quintus Prolog Release ~a (~a)'-[Release,Banner],nl,
    'Originally developed by Quintus Corporation, USA.'-[],nl,
    'Copyright (C) 1998, Swedish Institute of Computer Science.  All rights reserved.'-[],nl,
    'PO Box 1263, SE-164 29  Kista, Sweden. +46 8 633 1500'-[],nl,
    'Email: qpsupport@sics.se    WWW: http://www.sics.se/'-[],
    nl].

generate_message(version(Release,Banner,Site))-->
    !,
    ['Quintus Prolog Release ~a (~a)'-[Release,Banner],nl,
    'Originally developed by Quintus Corporation, USA.'-[],nl,
    'Copyright (C) 1998, Swedish Institute of Computer Science.  All rights reserved.'-[],nl,
    'PO Box 1263, SE-164 29  Kista, Sweden. +46 8 633 1500'-[],nl,
    'Email: qpsupport@sics.se    WWW: http://www.sics.se/quintus/'-[],
    nl],
    license_site(Site).

generate_message(version_addon(String)) -->
    [String-[],nl].

generate_message(no_clauses(Name,Arity,Module))-->
    ['no clauses for ~q/~d in ~q'-[Name,Arity,Module],nl].

generate_message(ill_formed_handlers(EH))-->
    ['Ill-formed error handlers:  ~q'-[EH],nl].

generate_message(non_callable_goal(Goal))-->
    ['non-callable goal:  ~q'-[Goal],nl].

generate_message(invalid_arithmetic_expression(Goal))-->
    ['Invalid arithmetic expression in goal:  ~q'-[Goal],nl].

generate_message(invalid_arithmetic_goal(Goal))-->
    ['Invalid arithmetic goal:  ~q'-[Goal],nl].

generate_message(bad_operand(Expression))-->
    ['Bad operand:  ~q'-[Expression],nl].

generate_message(unbound_variable_in_arithmetic)-->
    ['Unbound variable in arithmetic expression'-[],nl].

generate_message(cutting_to_unbound_variable)-->
    ['Cutting to unbound variable'-[],nl].

generate_message(unbound_variable_type_tested)-->
    ['Unbound variable being type-tested'-[],nl].

generate_message(command_failed(Command))-->
    ['command failed'-[],nl,'goal:  ~q'-[Command],nl].

generate_message(command_failed(File,Command))-->
    ['command in ~w failed'-[File],nl,'goal:  ~q'-[Command],nl].

generate_message(compiling(Margin,AbsFile))-->
    ['~*ccompiling ~w...'-[Margin,0' ,AbsFile],nl].

generate_message(dependency_recorded(Margin,RelFile))-->
    ['~*cdependency on foreign file ~w recorded'-[Margin,0' ,RelFile],nl].

generate_message(concise_qof(Margin,AbsFile,QofFileName))-->
    ['~*c~w: ~w'-[Margin,0' ,AbsFile,QofFileName],nl].

generate_message(compiled_into(Margin,AbsFileName,QofFileName, Module, Time))-->
    ['~*c~w compiled into ~w in module ~q, ~3d seconds'-
	[Margin,0' ,AbsFileName,QofFileName,Module,Time],nl].

generate_message(singleton_variables(N,Name,Arity,Vars))-->
    ['Singleton variables, clause ~d of ~q/~d: ~s'-[N,Name,Arity,Vars],nl].

generate_message(clauses_not_together(Pred))-->
    ['Clauses for ~q are not together in the source file'-[Pred],nl].

generate_message(dups_in_exports(X, Goal)) -->
    ['Duplicate export ~w in ~w'-[X, Goal], nl].

generate_message(procedure_being_redefined(Name,Arity,PrevFile))-->
    ['Procedure ~q/~d is being redefined'-[Name,Arity], nl],
    old_file(PrevFile).

generate_message(procedure_redefined(Name,Arity,PrevFile,SourceFile))-->
    ['Procedure ~q/~d is being redefined in a different file - '-[Name,Arity],
    nl],
    old_file_new_file(PrevFile,SourceFile),
    ['Do you really want to redefine it?'-[],nl].

generate_message(redefine_procedure_help)-->

% see query_abbreviation(yes_no_proceed)

    ['    y    redefine this particular procedure.'-[],nl,
     '    n    don''t redefine this procedure, but continue loading.'-[],nl,
     '    p    proceed redefining and suppress further warnings.'-[],nl,
     '    s    proceed NOT redefining and suppress further warnings.'-[],nl,
     '    a    abort.'-[], nl].

generate_message(module_redefined(Module,OldFile,NewFile)) -->
    ['Module ~q is being redefined in a different file.'-[Module],nl],
    old_file_new_file(OldFile,NewFile),
    ['Do you really want to redefine it?'-[],nl].

generate_message(execution_aborted)-->
    ['Execution aborted'-[],nl].

generate_message(break_level(BreakLevel))-->
    ['Beginning break level ~d'-[BreakLevel],nl].

generate_message(end_break_level(BreakLevel))-->
    ['Ending break level ~d'-[BreakLevel],nl].

generate_message(yes)-->[yes-[],nl].
generate_message(no)-->[no-[],nl].

generate_message(bindings(vars(Vars), binding(Term),punct(Punct))) -->
    print_vars(Vars),
    [write_term(Term, [portrayed(true), quoted(true), numbervars(true),
	               max_depth(16'7fffff), priority(699)])],
    ['~s'-[Punct], nl].

generate_message(term_expansion_ineffectual(Clause, Pos)) -->
    ['Clauses for term expansion have no effect at qpc time'-[], nl],
    culp_clause(Clause),
    position(Pos).

generate_message(profile_message(X))-->['The profiler '-[]], profile_message(X), [nl].
generate_message(debug_message(X))-->['The debugger '-[]], debug_message(X), [nl].
generate_message(debug_status(X))-->['The debugger '-[]], debug_message(X), [nl].

generate_message(import_module(Module,SrcMod))-->
    ['Import module ~q into module ~q?'-[Module,SrcMod],nl].

generate_message(blame_on(Exception,Ancestor)) --> 
	( generate_message(Exception) ->
	      ['goal: ~q'-[Ancestor],nl]
	; ['~w'-[Exception],nl],
	  ['goal: ~q'-[Ancestor],nl]
	).

generate_message(no_qof_generated(NoErrors, OutFile))-->
    ['Number of errors: ~d'-[NoErrors],nl],
    ['QOF file not generated: ~w'-[OutFile],nl].

generate_message(could_not_write_license_file(E)) -->
    { goalless_error_term(E, E1) },
    ['Could not write license file'-[],nl],
    generate_message(E1).
generate_message(could_not_read_license_file(E)) -->
    { goalless_error_term(E, E1) },
    ['Could not read license file'-[],nl],
    generate_message(E1).
generate_message(could_not_write_users_file(E)) -->
    { goalless_error_term(E, E1) },
    ['Could not write users file'-[],nl],
    generate_message(E1).
generate_message(could_not_read_users_file(E)) -->
    { goalless_error_term(E, E1) },
    ['Could not read users file'-[],nl],
    generate_message(E1).

generate_message(no_license_fact(Product)) -->
    ['There is no license for ~a in the license file~n'-[Product],nl].
generate_message(exceeded_users(Product, N)) -->
    ['The number of users for this product has exceeded'-[], nl,
     'the number for which it was licensed.'-[], nl,
     'Product: ~a, Number of licenses: ~w'-[Product, N], nl,
     'Please contact SICS at +46 8 633 1500 to get a new license'-[],nl,
     'Email: qpadmin@sics.se    WWW: http://www.sics.se/'-[],nl].
generate_message(expired_license(Product, D)) -->
    ['The license for this product has expired.'-[], nl,
     'Product: ~a, Expiry Date: ~w'-[Product, D], nl,
     'Please contact SICS at +46 8 633 1500 to get a new license'-[],nl,
     'Email: qpadmin@sics.se    WWW: http://www.sics.se/'-[],nl].
generate_message(bad_code(Product,Site,Users,Date,Code)) -->
    ['The code for the license is incorrect.'-[],nl,
     'Please contact SICS at +46 8 633 1500 to get a new license'-[],nl,
     'Email: qpadmin@sics.se    WWW: http://www.sics.se/'-[],nl,
     '~a ~30+~w ~10+~w ~10+~a~20+~a'-[Product,Users,Date,Code,Site],nl].

generate_message(qof_version(File)) -->
    ['Wrong QOF version: ~w'-[File],nl].

generate_message(restarting(Engine))-->['Restarting ~w'-[Engine],nl].

generate_message(statistic(MemoryInuse, MemoryFree,  
			AtomNumber,  AtomInuse,   AtomFree,    GlobalTotal,
			LocalTotal,  GlobalInuse, GlobalFree,  TrailInuse,
			LocalInuse,  LocalFree,   CodeInuse,   Overflow,
			Repartition, Trim,	  GlobalOver,  LocalOver,
			Gcs,	     GcFreed,     GcTime,      AtomGcs,
			AtomGcFreed, AtomGcTime,  Time)) -->
	{TotalMemory is MemoryInuse + MemoryFree},
	[nl],
	['memory (total)~t~d~29| bytes:~t~d~47| in use, ~t~d~66| free'-
		[TotalMemory, MemoryInuse, MemoryFree], nl],
	['   program space~t~d~29| bytes:'-[CodeInuse], nl],
	['      atom space~t(~d~29| atoms)~t~d~47| in use, ~t~d~66| free'-
		[AtomNumber, AtomInuse, AtomFree], nl],
	{Global is GlobalTotal - GlobalFree},
	['   global space~t~d~29| bytes:~t~d~47| in use, ~t~d~66| free'-
		[GlobalTotal, Global, GlobalFree], nl],
	['      global stack~t~d~47| bytes'-[GlobalInuse], nl],
	['      trail~t~d~47| bytes'-[TrailInuse], nl],
	{SystemGlobal is GlobalTotal - GlobalInuse - GlobalFree - TrailInuse},
	['      system~t~d~47| bytes'-
		[SystemGlobal],nl],
	{Local is LocalTotal - LocalFree},
	['   local stack~t~d~29| bytes: ~t~d~47| in use, ~t~d~66| free'-
		[LocalTotal, Local, LocalFree], nl],
	['      local stack~t~d~47| bytes'-[LocalInuse], nl],
	{SystemLocal is LocalTotal - LocalInuse - LocalFree},	
	['      system~t~d~47| bytes'-
		[SystemLocal], nl, nl],
	{ShiftTime is (Overflow + Repartition + Trim) / 1000.0},
	[' ~3f sec. for ~d global and ~d local space shifts'-
		[ShiftTime, GlobalOver, LocalOver], nl],
	{Gc is GcTime/1000.0},	
	{ ( Gcs = 1 -> S1 = "" ; S1 = "s" ) },
	[' ~3f sec. for ~d garbage collection~s '-[Gc, Gcs, S1]],
	['which collected ~d bytes'-[GcFreed], nl],
	{AtomGc is AtomGcTime/1000.0},	
	{ ( AtomGcs = 1 -> S2 = "" ; S2 = "s" ) },
	[' ~3f sec. for ~d atom garbage collection~s '-[AtomGc, AtomGcs, S2]],
	['which collected ~d bytes'-[AtomGcFreed], nl],
	{Runtime is Time/1000.0},
	[' ~3f sec. runtime'-[Runtime], nl].

generate_message('') --> []. % a silent message

% Code for compatibility with message system names in Release 3.0.  This
% is useful for anybody who customized the message system prior to 3.1,
% and also for people who want to use ProWindows 1.2 with Release 3.1.

generate_message(Message) --> parse_message(Message).

user:(:- multifile generate_message_hook/3).
user:(generate_message_hook(Message) --> parse_message_hook(Message)).


/************* fragments ***************************************************/

/*
  DO NOT CHANGE THE DEFINITION OF THE FOLLOWING CLAUSES EXCEPT TO
  TRANSLATE IT TO OTHER LANGUAGES
*/
license_site('No site') -->
    !,
    ['This copy of Quintus Prolog is not legally licensed'-[],nl].
license_site(Site) -->
    ['Licensed to ~a'-[Site], nl].

% Easy way out using =..
goalless_error_term(EI, EO) :- EI =.. [F,_G|T], EO =.. [F,0|T].

print_vars([]) --> [].
print_vars([H|T]) -->
	['~w = '-[H]],
	print_vars(T).

bad_tokens([])-->!.
bad_tokens(Tokens)-->['~s'-[Tokens],nl].

culprit(Culprit) --> {Culprit == 0}, !, [].
culprit(Culprit) --> [' ~q'-[Culprit],nl].

old_file_new_file(PrevFile,NewFile)-->
    ['    Previous file: ~w'-[PrevFile],nl,
     '    New file:      ~w'-[NewFile],nl].

old_file(PrevFile)-->
    ['    Previous file: ~w'-[PrevFile],nl].

profile_message(off) --> ['is switched off'-[]].
profile_message(on) --> ['is switched on'-[]].

debug_message(nonstop) --> ['is switched off'-[]].
debug_message(nodebug) --> ['is switched off'-[]].	% unnecessary?
debug_message(creep) --> ['will first creep -- showing everything (trace)'-[]].
debug_message(leap) --> ['will first leap -- showing spypoints (debug)'-[]].
debug_message(skip) --> ['is ignoring everything during a "skip"'-[]].
debug_message(error) --> ['is showing where an error occured'-[]].
debug_message(zip) --> ['will first zip -- showing spypoints'-[]].

position(between('$stream_position'(_,Line,_,_,_),Stream), File)-->
    {line_count(Stream,Current)},
    ['between lines ~d and ~d'-[Line,Current]],
    syntax_err_file(File).
position(at(Char,Line,_Stream), File)-->
    ['at line ~d, column ~d'-[Line,Char]],
    syntax_err_file(File).

position(line_and_file(Line, File)) -->
	( {File == user; File == 0; File == '-'} -> 
	      []
	; {Line == 0} ->
	      ['File: ~q'-[File],nl]
	; ['Approximate line: ~d, file: ~q'-[Line, File],nl]
	).
position(pos_and_file('$stream_position'(_,Line,_,_,_), File)) -->
	( {File == user; File == 0; File == '-'} -> 
	      []
	; {Line == 0} ->
	      ['File: ~q'-[File],nl]
	; ['Approximate line: ~d, file: ~q'-[Line, File],nl]
	).

syntax_err_file(user) -->
	!,
	[nl].
syntax_err_file(File) -->
	[' in file ~w'-[File], nl].

type(TypeName,Culprit)-->
    typename(TypeName),
    [' expected'-[]],
    (  {Culprit == 0}
    -> []
    ;  {nonvar(Culprit), Culprit = '$culprit'(ComplexCulprit)}
    -> [','-[],nl,'but '-[]],
       cookie_culprit(ComplexCulprit),
       [' found'-[]]
    ;  [', but ~q found'-[Culprit]]
    ),
    [nl].

cookie_culprit(ver(Ver,File)) -->
	['~q (version ~w)'-[File,Ver]].
cookie_culprit(rev(Rev,File)) -->
	['~q (revision ~w)'-[File,Rev]].

existence_message(Goal,ArgNo,ObjectType,Culprit,Message) -->
    head(Goal, ArgNo),
    typename(ObjectType),
    existence_culprit(Culprit),
    message(Message),
    goal(Goal).

existence_culprit(0) --> !, [nl].
existence_culprit(Culprit) --> !, [' ~q does not exist'-[Culprit],nl].

message(0) --> !, [].
message('') --> !, [].
message(X) --> msg(X), [nl].

msg(errno(E)) -->
    {	integer(E),
	error_message(E, Etype, ErrorMsg, 0),
	errno_heading(Etype, ErrorHead)
    },
    ['~a : ~a'-[ErrorHead, ErrorMsg]].
msg('End of File found:  unclosed if-endif sequence')-->
    ['End of File found:  unclosed if-endif sequence'-[]].
msg('Foreign interface, call to Unix "ld" failed')-->
    ['Foreign interface, call to Unix "ld" failed'-[]].
msg('Foreign interface, intermediate use of Unix "cc" failed')-->
    ['Foreign interface, intermediate use of Unix "cc" failed'-[]].
msg('File has incorrect header')-->
    ['File has incorrect header'-[]].
msg('File has wrong version of _DYNAMIC')-->
    ['File has wrong version of _DYNAMIC'-[]].
msg('Cannot read header of object file') -->
    ['Cannot read header of object file'-[]].
msg('Cannot expand relative filename') -->
    ['Cannot expand relative filename'-[]].
msg('Prolog not started yet') --> ['Prolog not started yet'-[]].
msg('Restore failed') --> ['Restore failed'-[]].
msg('File not loaded') --> ['File not loaded'-[]].
msg(cannot_read(File)) --> ['Read failed on ~w'-[File]].
msg('file search path too long') --> ['File search path could not be resolved - circular definition'-[]].
msg('float overflow') --> ['float overflow'-[]].
msg('integer overflow') --> ['integer overflow'-[]].
msg('non-zero number') --> ['non-zero number'-[]].
msg(end_of_file) --> ['end of file'-[]].
msg('incompatible argument type') --> ['incompatible argument type'-[]].
msg('application terminates') --> ['application terminates'-[]].
msg('Not a current module') --> ['Not a current module'-[]].
msg('Circular file_search_path definition') --> 
    ['Circular file_search_path definition'-[]].
msg('too many free variables'(Limit)) --> 
    ['too many free variables, limit is ~d'-[Limit]].
msg(length>N) --> ['length of list exceeds ~w'-[N]].
msg('Arithmetic error') --> ['Arithmetic error'-[]].
msg('wrong number of arguments') --> ['wrong number of arguments'-[]].
msg(X>255) --> ['~q'-[X>255]].
msg('prefix operator used improperly'(Op)) -->
    ['prefix operator ~w used improperly'-[Op]].
msg('term has arity greater than 255') -->
    ['term has arity greater than 255'-[]].
msg('invalid database reference') -->
    ['invalid database reference'-[]].
msg('missing ]') --> ['missing ]'-[]].
msg(wrong_format_option_type(Type,Option)) -->
    ['the argument for the format control option "~w" must be of type "'-
	[Option]],
    typename(Type),
    ['".'-[]].
msg(however_one_is_defined(One))--> ['however, ~w is defined'-[One]].
msg(however_list_are_defined(List))--> ['however, ~w are defined'-[List]].
msg('Internal error for multifile') --> ['Internal error for multifile'-[]].
msg('string too long') --> ['string too long'-[]].
msg(bound(compiled_clause_size,S,Unit)) -->
	['Compiled representation of clause exceeds ~d ~w'-[S,Unit]].
msg(bound(compiled_clause_perms,S)) -->
 ['Compiled representation of clause has more than ~d permanent variables'-[S]].
msg(bound(compiled_clause_temps,S)) -->
 ['Compiled representation of clause has more than ~d temporary variables'-[S]].

%   Tokenizer error messages
msg('atom too long') -->
    ['atom too long'-[]].
msg('floating point number too large') -->
    ['floating point number too large'-[]].
msg('ill-formed floating-point number') -->
    ['ill-formed floating-point number'-[]].
msg('floating point number too long') -->
    ['floating point number too long'-[]].
msg('end of file in 0''character') -->
    ['end of file in 0''character'-[]].
msg('integer too large') -->
    ['integer too large'-[]].
msg('ill-formed integer') -->
    ['ill-formed integer'-[]].
msg('integer too long') -->
    ['integer too long'-[]].
msg('radix not 0 or 2..36') -->
    ['radix not 0 or 2..36'-[]].
msg('string too long') -->
    ['string too long'-[]].
msg('end of file in ''atom') -->
    ['end of file in ''atom'-[]].
msg('end of file in "/*" comment') -->
    ['end of file in "/*" comment'-[]].
msg('end of file in "character list') -->
    ['end of file in "character list'-[]].


errno_heading(0, 'O/S error').
errno_heading(1, 'QP error').

goal(Goal) --> goal_aux(Goal), !.
goal(Goal) --> ['goal:  ~q'-[Goal],nl].

goal_aux(Goal) --> {var(Goal), !, fail}.
goal_aux(0) --> [].
goal_aux(user:Goal) --> goal(Goal).

culp_clause(Clause) --> clause_aux(Clause), !.
culp_clause(Clause) --> ['clause:  ~q'-[Clause],nl].

clause_aux(Clause) --> {var(Clause), !, fail}.
clause_aux(0) --> [].
clause_aux(user:Clause) --> culp_clause(Clause).


head(Goal, ArgNo) --> head(Goal, user, ArgNo).

head(0, _, _) --> [nl], !.
head((:-Directive), Module, ArgNo) --> head(Directive, Module, ArgNo), !.
head(Module:Goal, _, ArgNo) --> {atom(Module)}, head(Goal, Module, ArgNo), !.
head(Goal, Module, ArgNo, [X,nl|S], S) :-
    functor(Goal, Name, Arity),
    (   (Module = user ; predicate_property(Goal,built_in))
    ->  Spec = Name/Arity
    ;   Spec = Module:Name/Arity
    ),
    (   integer(ArgNo), 0 < ArgNo, ArgNo =< Arity
    ->  X = ' in argument ~d of ~q'-[ArgNo,Spec]
    ;   X = ' in ~q'-[Spec]
    ).


commandtype(0) --> [].
commandtype(cut) --> [cut-[]].
commandtype(clause) --> [clause-[]].
commandtype(declaration) --> [declaration-[]].
commandtype('meta_predicate declaration') --> ['meta_predicate declaration'-[]].
commandtype(use_module) --> [use_module-[]].
commandtype('multifile assert') --> ['multifile assert'-[]].
commandtype('module declaration') --> ['module declaration'-[]].
commandtype('dynamic declaration') --> ['dynamic declaration'-[]].
commandtype(meta_predicate(M)) --> ['meta_predicate declaration for ~q'-[M]].
commandtype(argspec(A)) --> ['Invalid argument specification ~q'-[A]].
commandtype(foreign_file(File)) -->
    ['foreign_file/2 declaration for ~w'-[File]].
commandtype(foreign(F)) --> ['foreign/3 declaration for ~w'-[F]].
commandtype((initialization)) --> ['initialization hook'-[]].
commandtype(abort) --> ['call to abort/0'-[]].
commandtype(debug) --> ['Cannot turn debugger on/off'-[]].
commandtype(foreign_returned) --> ['foreign function returned'-[]].


contexttype('pseudo-file ''user''') --> ['for pseudo-file ''user'''-[]].
contexttype(if) --> ['inside an if'-[]].
contexttype(bof) --> ['at beginning of file'-[]].
contexttype(bom) --> ['at beginning of module'-[]].
contexttype(before) --> ['before'-[]].
contexttype('after clauses') --> ['after clauses'-[]].
contexttype('not multifile and defined') -->
    ['for defined, non-multifile procedure'-[]].
contexttype('static multifile') --> ['for static multifile procedure'-[]].
contexttype(file_load) --> ['during load of file(s)'-[]].
contexttype(language(L)) --> ['for language ~w'-[L]].
contexttype(notoplevel) --> ['when no top level'-[]].
contexttype(open_query) --> ['a Prolog query was open'-[]].
contexttype(profiling) --> ['profiling'-[]].
contexttype(query) --> ['in query'-[]].
contexttype(started) --> ['started up'-[]].


%%%      This predicate should probably be split up into separate type
%%%      and domain name predicates, even if a few entries have to be
%%%      duplicated.

typename(Type-value) --> ['valid ~w value'-[Type]].
typename(':- module header for') --> [':- module header for'-[]].
typename('File containing module') --> ['File containing module'-[]].
typename('O/S interface for') --> ['O/S interface for'-[]].
typename('Symbol table in') --> ['Symbol table in'-[]].
typename('QP_qid') --> ['QP_qid'-[]].
typename('arithmetic expression') --> ['arithmetic expression'-[]].
typename('built-in predicate') --> ['built-in predicate'-[]].
typename('clause or record') --> ['clause or record'-[]].
typename('control string') --> ['control string'-[]].
typename('definition for') --> ['definition for'-[]].
typename('final object file') --> ['final object file'-[]].
typename('file (not opened by see/1 or tell/1)') -->
    ['file (not opened by see/1 or tell/1)'-[]].
typename('file or stream') --> ['file or stream'-[]].
typename('file specification') --> ['file specification'-[]].
typename('file_search_path') --> ['known file search path'-[]].
typename('foreign file') --> ['foreign file'-[]].
typename('foreign files') --> ['foreign files'-[]].
typename('foreign function') --> ['foreign function'-[]].
typename('foreign parameter specification') -->
    ['foreign parameter specification'-[]].
typename('foreign parameter type') --> ['foreign parameter type'-[]].
typename('foreign procedure') --> ['foreign procedure'-[]].
typename('format specification') --> ['format specification'-[]].
typename('header for file') --> ['header for file'-[]].
typename('help directory') --> ['help directory'-[]].
typename('help index file') --> ['help index file'-[]].
typename('interface predicate') --> ['interface predicate'-[]].
typename('leash specifications') --> ['leash specifications'-[]].
typename('lhs term') --> ['lhs term'-[]].
typename('list of predicate specifications') -->
    ['list of predicate specifications'-[]].
typename(list_or_all) -->
    ['list of imported predicates or "all"'-[]].
typename('load option')-->['load option'-[]].
typename('manuals file') --> ['manuals file'-[]].
typename('next character of') --> ['next character of'-[]].
typename('non-zero number') --> ['non-zero number'-[]].
typename('open file') --> ['open file'-[]].
typename('predicate interface specification') -->
    ['predicate interface specification'-[]].
typename('proper_file') --> ['a proper file'-[]].
typename('qof_file') --> ['a Quintus Object File ("QOF")'-[]].
typename('qof_version') --> ['a Quintus Object File ("QOF")'-[]].
typename(qof_ver(Ver)) --> ['QOF version ~w'-[Ver]].
typename(qof_rev(Rev)) --> ['QOF revision less or equal to ~w'-[Rev]].
typename('really_qof_version') --> ['an old QOF-version file'-[]].
typename('seek offset') --> ['seek offset'-[]].
typename('shared object') --> ['shared object'-[]].
typename('spypoint specification') --> ['spypoint specification'-[]].
typename('stream position') --> ['stream position'-[]].
typename('symbols referenced in') --> ['symbol(s) referenced in'-[]].
typename('temp file for help menu') --> ['temp file for help menu'-[]].
typename('text_file') --> ['text file'-[]].
typename('valid message term')-->['valid message term'-[]].
typename('valid option') --> ['valid option'-[]].
typename('valid radix') --> ['valid radix'-[]].
typename(0) --> [].
typename(atom) --> [atom-[]].
typename(atom_or_list) --> ['atom or list'-[]].
typename(atom_or_variable) --> ['atom or variable'-[]].
typename('atom or number') --> ['atom or number'-[]].
typename(atomic) --> ['atomic'-[]].
typename(between(L,H)) --> ['something between ~w and ~w'-[L,H]].
typename(built_in) --> ['built-in predicate'-[]].
typename(callable) --> [callable-[]].
typename(char) --> ['char'-[]].
typename(chars) --> ['list of character code'-[]].
typename(character) --> ['character'-[]].
typename(clause) --> ['clause'-[]].
typename(constant)-->[constant-[]].
typename(compiled)-->[compiled-[]].
typename(compound)-->[compound-[]].
typename(control_arg_pair) --> ['control-arglist pair'-[]].
typename(db_reference) --> ['database reference'-[]].
typename(declaration) --> [declaration-[]].
typename(directory) --> [directory-[]].
typename(foreign)-->[foreign-[]].
typename(file) --> [file-[]].
typename(filename) --> ['file name'-[]].
typename(file_or_stream) --> ['file or stream'-[]].
typename(file_option) --> ['file option'-[]].
typename(file_specification) --> ['file specification'-[]].
typename(flag) --> [flag-[]].
typename(float) --> [float-[]].
typename(ground) --> [ground-[]].
typename(imported_predicate) --> ['imported predicate'-[]].
typename(integer) --> [integer-[]].
typename(interface_argument_specification) -->
    ['interface argument specification'-[]].
typename(interpreted)-->[interpreted-[]].
typename(list) --> [list-[]].
typename(list_or_all) --> ['list or ''all'''-[]].
typename(meta_predicate_argument_specifier) -->
    ['meta predicate specifier'-[]].
typename(module) --> [module-[]].
typename(nl_ended_list) --> ['list terminated with atom nl'-[]].
typename(nonvar) --> [nonvar-[]].
typename(not_user) --> ['any atom besides ''user'''-[]].
typename(nonneg) --> ['non-negative integer'-[]].
typename(number) --> ['number'-[]].
typename(one_of(List)) --> ['a member of the set ~q'-[List]].
typename(oneof(List))  --> ['a member of the set ~q'-[List]].
typename(pair) --> [pair-[]].
typename(predicate_specification) --> ['predicate specification'-[]].
typename(procedure) --> [procedure-[]].
typename(proper_list) --> ['proper list'-[]].
typename(read_term_option) --> ['read_term option'-[]].
typename(stream) --> ['stream'-[]].
typename(symbol) --> ['symbol'-[]].
typename(term) --> [term-[]].
typename(text) --> [text-[]].
typename(valid_file) -->  ['valid file'-[]].
typename(valid_file_or_list_of_files) -->  ['valid file or list of files'-[]].
typename(value(X)) --> ['the value ~q'-[X]].
typename(var) --> [variable-[]].
typename(write_term_option) --> [write_term_option-[]].

operation(0) --> [].
operation('find absolute path of') --> ['find absolute path of'-[]].
operation('get the time stamp of') --> ['get the time stamp of'-[]].
operation('set prompt on') --> ['set prompt on'-[]].
operation('use close(filename) on') --> ['use close(filename) on'-[]].
operation(abolish) --> [abolish-[]].
operation(add_advice) --> ['add advice to'-[]].
operation(change) --> [change-[]].
operation(check_advice) --> ['check advice on'-[]].
operation(clauses) --> ['access clauses of'-[]].
operation(close) --> [close-[]].
operation(create) --> [create-[]].
operation(export) --> [export-[]].
operation(flush) --> [flush-[]].
operation(import) --> [import-[]].
operation(load) --> [load-[]].
operation(nocheck_advice) --> ['check advice on'-[]].
operation(nospy) --> [(spy)-[]].
operation(open) --> [open-[]].
operation(position) --> [position-[]].
operation(read) --> [read-[]].
operation(redefine) --> [redefine-[]].
operation(save) --> [save-[]].
operation(spy) --> [(spy)-[]].
operation(write) --> [write-[]].


resource(0) --> [].
resource(memory) --> [': out of memory'-[]].
resource('too many open files') --> [': too many open files'-[]].
resource(Goal) --> [': goal ~q'-[Goal]].


/*********    Warning and informational message fragments     ****************/

advice(no_preds, _Kind, predicate_family(Module,Name,Arity)) -->
	['There are no predicates named ~q of '-[Name]],
	(   {nonvar(Arity)} ->
		['arity ~w '-[Arity]]
	;   ['any arity '-[]]
	),
	(   {nonvar(Module)} ->
		['in module ~q'-[Module]]
	;   ['in any module'-[]]
	).
advice(no_clauses, Kind, Spyspec) -->
	['You have no clauses for '-[]],
	spyspec(Spyspec, Kind).
advice(not_on_dynamic, Kind, Spyspec) -->
	spyspec(Spyspec, Kind),
	['is dynamic'-[]].
advice(not_enough_clauses, Kind, Spyspec) -->
	['Not enough clauses for '-[]],
	spyspec(Spyspec, Kind).
advice(not_enough_calls_to, Kind,
		call(Callerspec,Clausenum,Predspec,_Callnum)) -->
	['Not enough calls to '-[]],
	predspec(Predspec, user, Kind),
	['in clause ~w of '-[Clausenum]],
	predspec(Callerspec, user, '').
advice(already_spied, Kind, Spyspec) -->
	['There already is a spypoint on '-[]],
	spyspec(Spyspec, Kind).
advice(spypoint_placed, Kind, Spyspec) -->
	['Spypoint placed on '-[]],
	spyspec(Spyspec, Kind).
advice(spypoint_removed, Kind, Spyspec) -->
	['Spypoint removed from '-[]],
	spyspec(Spyspec, Kind).
advice(no_spypoint, Kind, Spyspec) -->
	['There is no spypoint on '-[]],
	spyspec(Spyspec, Kind).
advice(checking_already_enabled, Kind, Spyspec) -->
	['Advice checking is already enabled on '-[]],
	spyspec(Spyspec, Kind).
advice(checking_enabled, Kind, Spyspec) -->
	['Advice checking enabled on '-[]],
	spyspec(Spyspec, Kind).
advice(checking_disabled, Kind, Spyspec) -->
	['Advice checking disabled for '-[]],
	spyspec(Spyspec, Kind).
advice(checking_not_enabled, Kind, Spyspec) -->
	['Advice checking is not enabled for '-[]],
	spyspec(Spyspec, Kind).

spyspec_lines([]) --> [].
spyspec_lines([Spec|Specs]) -->
	['	'-[]],
	spyspec(Spec, ''),
	[nl],
	spyspec_lines(Specs).

spyspec(predicate(Predspec), Kind) --> predspec(Predspec, user, Kind).
spyspec(call(Callerspec,Clausenum,Predspec,Callnum), Kind) -->
	['call ~w to '-[Callnum]],
	predspec(Predspec, user, Kind),
	['in clause ~w of '-[Clausenum]],
	predspec(Callerspec, user, '').

predspec(Module:Predspec, _, Kind) -->
	!,
	predspec(Predspec, Module, Kind).
predspec(Predspec, Module, Kind) -->
	prim_predspec(Predspec, Module, Kind).

prim_predspec(Predspec, Module, Kind) -->
	advice_kind(Kind),
	{functor(Predspec, Name, Arity)},
	['~q:~q/~w '-[Module,Name,Arity]].

debug_term(0, _, _) --> !, [].
debug_term(Term, write, _) -->
	!,
	['~q'-[Term]].
debug_term(Term, display, _) -->
	!,
	['~k'-[Term]].
debug_term(Term, print, Depth) -->
	[write_term(Term, [quoted(true),portrayed(true),numbervars(true),
			   max_depth(Depth), priority(999)])].

debug_prefix('*>') --> ['*> '-[]].
debug_prefix('**') --> ['** '-[]].
debug_prefix(' >') --> [' > '-[]].
debug_prefix('  ') --> ['   '-[]].

debug_invocation(Invoc) --> ['(~d) '-[Invoc]].

debug_depth(Depth) --> ['~d '-[Depth]].

debug_extra(none)    --> [': '-[]].
debug_extra(undefined) --> [' (undefined): '-[]].
debug_extra(built_in) --> [' (built_in): '-[]].
debug_extra(locked) --> [' (locked): '-[]].
debug_extra(foreign) --> [' (foreign): '-[]].
debug_extra((dynamic)) --> [' (dynamic): '-[]].
debug_extra((multifile)) --> [' (multifile): '-[]].
debug_extra(head(This)) --> [' [~d]: '-[This]].
debug_extra(head(This,Next)) --> [' [~d->~w]: '-[This,Next]].

debug_port('') --> [].
debug_port('Call') --> ['Call'-[]].
debug_port('Exit') --> ['Exit'-[]].
debug_port('Redo') --> ['Redo'-[]].
debug_port('Fail') --> ['Fail'-[]].
debug_port('Done') --> ['Done'-[]].
debug_port('Head') --> ['Head'-[]].
debug_port('Exception') --> ['Exception'-[]].

advice_kind('')-->[].
advice_kind((dynamic))-->['dynamic predicate '-[]].
advice_kind(builtin)-->['builtin predicate '-[]].
advice_kind(compiled)-->['compiled predicate '-[]].

% optional_info(Info, Info0, Before0, Before1, Before) -->
% The idea of this is Info should be printed iff Info \== Info0.  If
% it IS printed, it should be preceded by Before0.  Before is what should
% precede the NEXT optional thing:  Before0 if we didn't print anything,
% and Before1 if we did.

optional_info(Info, Info, X, _, X) --> [], !.
optional_info(Info, _, Before0, Before, Before) -->
    ['~w~w'-[Before0,Info]].

severity(informational) --> [informational-[]].
severity(warning) --> [warning-[]].
severity(error) --> [error-[]].
severity(silent) --> [silent-[]].

load_area(procedure) --> [procedure-[]].
load_area(region) --> [region-[]].
load_area(buffer) --> [buffer-[]].

load_preposition(procedure) --> [' from '-[]].
load_preposition(region) --> [' from '-[]].
load_preposition(buffer) --> [' with '-[]].

load_past(compile) --> [compiled-[]].
load_past(load) --> [loaded-[]].
load_past(qof) --> [loaded-[]].
load_past((dynamic)) --> [(dynamic)-[]].

load_noun(compile) --> [compilation-[]].
load_noun(qof) --> [load-[]].
load_noun(load) --> [load-[]].

load_message('')-->[].
load_message('more clauses for multifile ') -->
    ['more clauses for multifile '-[]].

load_gerund(compile)-->[compiling-[]].
load_gerund(load)-->[loading-[]].
load_gerund(qof)-->[loading-[]].

name_clash(Module,Name,Arity,Module) --> !,
    ['NAME CLASH: ~q/~q is already defined in module ~q'-[Name,Arity,Module]].
name_clash(Module,Name,Arity,DefMod) -->
    ['NAME CLASH: ~q/~q is already imported into module ~q from ~q'-
	[Name,Arity,Module,DefMod]].

ignore_name_clash(Module,Module) --> !,
    ['an attempt to define it in module ~q is being ignored.'-[Module]].
ignore_name_clash(_,NewMod) -->
    ['an attempt to import it from module ~q is being ignored.'-[NewMod]].

% query_abbreviation/3.  The idea here is to list the valid abreviations
% for a given key word.  For example, a french translator might decide
% that the letters 'O' and 'o' are reasonable abreviations for 'oui'
% (yes), and therefore write 'yes-"oO"'.

query_abbreviation(yes_or_no,'(y/n/a)',[yes-"yY",no-"nN",abort-"aA"]).

query_abbreviation(toplevel,'',[yes-[10],no-";"]).  % see toplevel, above

query_abbreviation(yes_no_proceed,'(y,n,p,s,a, or ? for help)',
    [yes-"yY",
     no-"nN",
     proceed-"pP",
     suppress-"sS",
     abort-"aA"]).

query_abbreviation(debugger,'',
    [abort-"aA",
     ancestors-"gG",
     break-"bB",
     command-"@",
     creep-[10,0'c,0'C],
     debugging-"=",
     depth-"<",
     display-"dD",
     fail-"fF",
     find-".",
     help-"hH?",
     leap-"lL",
     nonstop-"nN",
     (nospy)-"-",
     print-"pP",
     quasi_skip-"qQ",
     raise-"eE",
     retry-"rR",
     skip-"sS",
     (spy)-"+",
     unlock-"uU",
     write-"wW",
     zip-"zZ"
     ]).

foreign('QU_error_message', c, error_message(+integer, -integer, -string,
					   [-integer])).
foreign_file(messages(system('QU_messages')), ['QU_error_message']).
:- load_foreign_files([messages(system('QU_messages'))], []),
	abolish([foreign/3, foreign_file/2]).
