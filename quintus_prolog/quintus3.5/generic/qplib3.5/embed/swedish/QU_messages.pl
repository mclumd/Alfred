/* SCCS   : @(#)QU_messages.swedish.pl	76.4 09/22/98
   File   : QU_messages.pl
   Author : Jonas Almgren (translated from QU_messages.pl)
   Origin : Dec. 1990
   Purpose: Parse of Quintus message terms, Swedish version
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
    ['Systemfel'-[],nl],
    message(M).

generate_message(resource_error(Goal,Resource,Spec)) -->
    ['Resursbrist'-[]],
    resource(Resource),
    [nl],
    message(Spec),
    goal(Goal).

generate_message(representation_error(Goal,ArgNo,Message)) -->
    ['Representationsbegraensning'-[]],
    head(Goal,ArgNo),
    message(Message),
    goal(Goal).

generate_message(instantiation_error(Goal,ArgNo)) -->
    ['Instansieringsfel'-[]],
    head(Goal,ArgNo),
    goal(Goal).

generate_message(type_error(Goal,ArgNo,TypeName,Culprit)) -->
    ['Typbrott'-[]],
    head(Goal,ArgNo),
    type(TypeName,Culprit),
    goal(Goal).

generate_message(domain_error(Goal,ArgNo,DomainName,Culprit,Message)) -->
    ['Domaenbrott'-[]],
    head(Goal,ArgNo),
    type(DomainName,Culprit),
    message(Message),
    goal(Goal).

generate_message(existence_error(Goal,ArgNo,ObjectType,Culprit,Message)) -->
    ['Existensfel'-[]],
    existence_message(Goal,ArgNo,ObjectType,Culprit,Message).

generate_message(permission_error(Goal,Operation,ObjectType,Culprit,Message)) -->
    (	{Operation=(dynamic)}
    ->	['Regelbrott:  ~q aer '-[Culprit]],
	typename(ObjectType),
	[', men maaste vara dynamisk.'-[], nl]
    ;	['Regelbrott:  kan inte '-[]],
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
    ;	['Motstridighetsfel: ~q och ~q aer ofoerenliga'-[Culprit1,Culprit2],nl]
    ),
    message(Message),
    goal(Goal).

generate_message(context_error(Goal,ContextType,CommandType)) -->
    ['Kontextfel: '-[]],
    commandtype(CommandType),
    (	{ContextType = not(C)} -> [' hittades inte '-[]]
    ;   {ContextType = when(C)} -> [' naer '-[]]
    ;	{ContextType = C}, [' hittades '-[]]
    ),
    contexttype(C),
    [nl],
    goal(Goal).

generate_message(range_error(Goal,ArgNo,TypeName,Culprit)) -->
    ['Omfaangsfel'-[]],
    head( Goal, ArgNo),
    type(TypeName, Culprit),
    goal(Goal).

generate_message(syntax_error(Goal,Position,Message,Left,Right,File))-->
    ['Syntaxfel'-[]],
    head(Goal, 0),
    message(Message),
    position(Position, File),
    bad_tokens(Left),
    ['<<haer>>'-[],nl],
    bad_tokens(Right),
    goal(Goal).

/********** the parse of system messages ***********************/

generate_message(usage(Utility)) -->
	['~Nanvaendning: ~w [-cv] [-o output] [-i opsfil] [-L bibliotekskatalog] filnamn...'-[Utility],nl].

generate_message(contradictory_flags(Utility, Flag1, Flag2)) -->
	['~N~w: ~w flagga kan inte anges tillsammans med ~w'-[Utility,
		Flag1,Flag2],nl].

generate_message(multiple_flags(Utility, Flag)) -->
	['~N~w: multipla ~w flaggor'-[Utility,Flag],nl].

generate_message(missing_argument(Utility, Flag)) -->
	['~N~w: argument saknas foer -~a flagga'-[Utility,Flag],nl].
	
generate_message(debugger(standard_help)) -->
	[nl, 'Avlusnings val:'-[], nl, nl,
' <cr>   kryp       p      "print"       r [i]  omgoer i     @    kommando'-[],nl,
'  c     kryp       w      "write"       f [i]  misslyckas i b    bryt'-[],nl,
'  l     skutta     d      "display"                         a    avbryt'-[],nl,
'  s [i] skippa i                                            h    hjaelp'-[],nl,
'  z     rusa       g [n]  n foerfaeder  +     spionera pred ?    hjaelp'-[],nl,
'  n     nonstopp   < [n]  saett djup    -    ospionera pred =    avlusning'-[],nl,
'  q   kvasi-skippa .      hitta defn    e    signalera undantag'-[],nl].


generate_message(debugger(retrying)) -->
	[nl, 'Omgoer maal'-[], nl, nl].

generate_message(debugger(leashing,Type,[])) -->
	!,
	['Inget ~wskuttande'-[Type], nl].
generate_message(debugger(leashing,Type,Ports)) -->
	!,
	['~wskuttande, stannar vid ~w portar'-[Type,Ports], nl].

generate_message(debugger(ancestors)) -->
	[nl, '[Foerfaeder:]'-[], nl].
generate_message(debugger(no_ancestors)) -->
	[nl, '[Inga foerfaeder]'-[], nl].

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
	[nl, 'Det finns inga spionpunkter'-[], nl].
generate_message(debugger(spypoints,L1,L2)) -->
	!,
	(   {L1 \== []} ->
		[nl, 'Predikatspionpunkt:'-[], nl, nl],
		spyspec_lines(L1)
	;   []
	),
	(   {L2 \== []} ->
		[nl, 'Maalspionpunkt:'-[], nl, nl],
		spyspec_lines(L2)
	;   []
	).

generate_message(debugger_error(Error, _TraceState)) -->
	['Anvaendaravlusare signalerade ett fel'-[], nl],
	generate_message(Error).

generate_message(debugger_print_depth(D)) -->
	( {D =:= 0} ->
	      ['Avlusarens utskriftsdjup saknar nu graens'-[],nl]
	; ['Avlusarens utskriftsdjup satt till ~w'-[D],nl]
	).

generate_message(undefined_message(Severity,Message)) -->
    ['Odefinierat '-[]],
    severity(Severity),
    [' meddelande:  ~q'-[Message],nl].

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
    ['Alla spionpunkter borttagna'-[],nl].

generate_message(advice(checking_enabled)) -->
    ['Parasitcheckning paaslagen foer alla parasiterade procedurer'-[],nl].

generate_message(advice(checking_disabled)) -->
    ['All parasitcheckning avstaengd'-[],nl].

generate_message(modules(not_current(M))) -->
    ['~q aer inte en aktuell modul.'-[M],nl].

generate_message(modules(name_mismatch,X,Y))-->
    ['felande modulenamnsmatch: ~q'-[X],nl,'riktigt modulnamn aer ~q'-[Y],nl].

generate_message(modules(import_not_exported,Name/Arity,Importer,DefMod)) -->
    ['Predikatet ~q importerat av modul ~q'-[Name/Arity,Importer],nl,
    'aer inte exporterat av modul ~q'-[DefMod],nl].

generate_message(modules(name_clash,Module,Name,Arity,DefMod,NewMod)) -->
    name_clash(Module,Name,Arity,DefMod),
    [nl],
    ignore_name_clash(Module,NewMod),
    [nl].

generate_message(module_already_loaded(Module,OldFile,File)) -->
    ['Foersoek att omdefiniera modul ~q i en annan fil.'-[Module],nl,
    old_file_new_file(OldFile,File),
     'Omdefiniering ignorerad'-[],nl].

generate_message(non_module_qof_file(AbsQofFile,RelFile)) -->
    ['Kaellkod saknas foer ickemodulfil: ~w'-[AbsQofFile],nl],
    ['~q registrerad som behoevd.'-[RelFile],nl].

generate_message(name_clash(Module,Name,Arity,DefMod)) -->
    name_clash(Module,Name,Arity,DefMod),
    [nl].

generate_message(name_clash(Module,Name,Arity,DefMod,NewMod)) -->
    generate_message(name_clash(Module,Name,Arity,DefMod)),
    ['vill du skriva oever denna definition med den i ~q?'-[NewMod],
	nl].

generate_message(modules(undefined_export,Name,Arity,Module)) -->
    ['predikatet ~q/~q exporterat av ~q aer inte definierat'-[Name,Arity,Module],
    nl].

generate_message(modules(undefined_meta,Pred,Module)) -->
    ['metapredikat ~q deklarerat i modul ~q aer inte definierat'-[Pred,Module],
    nl].

generate_message(modules(cannot_match,I,Head)) -->
    ['argument ~d i metapredikatklausulen:'-[I],nl,'~q :- ...'-[Head],nl,
    'kan inte matcha Modul:Term'-[],nl].

generate_message(reload_failed) -->
    ['Omladdning av fraemmande fil MISSLYCKADES.'-[]].

generate_message(loading_proc(Verb,Message,Name,Arity,Module)) -->
    load_gerund(Verb),
    [' '-[]],
    load_message(Message),
    ['procedur ~q/~q i modul ~q'-[Name,Arity,Module],nl].

generate_message(loading_file(Margin,Verb,File))-->
    ['~*c'-[Margin,0' ]],
    load_gerund(Verb),
    [' fil ~w'-[File],nl].

generate_message(emacs_loading(Area,Verb))-->
    load_gerund(Verb),
    [' '-[]],
    load_area(Area),
    [nl].

generate_message(load_completed(Margin,FileName,Verb,Module,Time,Space))-->
    ['~*c~w '-[Margin,0' ,FileName]],
    load_past(Verb),
    [' i modul ~q, ~3d s ~D oktetter'-[Module,Time,Space],nl].

generate_message(load_completed(Margin,FileName,Verb,SrcMod,Module,Time,Space))-->
    ['~*c~w '-[Margin,0' ,FileName]],
    load_past(Verb),
    [', ~3d s ~D oktetter'-[Time,Space],nl],
    ['~*cmodul ~q importerad till ~q'-[Margin,0' ,Module,SrcMod],nl].

generate_message(emacs_load_completed(Area,FileName,Verb,Module,Time,Space))-->
    load_area(Area),
    load_preposition(Area),
    ['~w '-[FileName]],
    load_past(Verb),
    [' i modul ~q, ~3d s ~D oktetter'-[Module,Time,Space],nl].

generate_message(emacs_load_completed(Area,FileName,Verb,SrcMod,Module,
			           Time,Space))-->
    load_area(Area),
    load_preposition(Area),
    ['~w '-[FileName]],
    load_past(Verb),
    [', ~3d s ~D oktetter'-[Time,Space],nl],
    ['modul ~q importerad till ~q'-[Module,SrcMod],nl].

generate_message(load_not_completed(Margin,FileName,Verb))-->
    ['~*c~w INTE '-[Margin,0' ,FileName]],
    load_past(Verb),
    [nl].

generate_message(emacs_load_not_completed(Area,FileName,Verb))-->
    load_area(Area),
    load_preposition(Area),
    ['~w '-[FileName]],
    [' INTE '-[]],
    load_past(Verb),
    [nl].

generate_message(saving_file(File))-->
    ['Sparar QOF-fil ~w'-[File],nl].

generate_message(saved_file(File, Time))-->
    ['~w sparad pa ~3d s'-[File,Time],nl].

generate_message(load_into_module(Module)) -->
    ['Ladda in i modul ~q? (j/n) '-[Module],nl].

generate_message(undefined_in_module(Name,Arity,Module))-->
    ['~q/~d aer odefinierad i modul ~p~n'-[Name,Arity,Module],nl].

generate_message(built_in(Name,Arity))-->
    ['~q/~d aer ett inbyggt predikat'-[Name,Arity],nl].

generate_message(no_source(Name,Arity))-->
    ['Det finns ingen kaellkodsfil foer ~q/~d'-[Name,Arity],nl].

generate_message(undefined(Name,Arity))-->
    ['~q/~d aer odefinierad'-[Name,Arity],nl].

generate_message(is_defined_in_file(Pred,FileName))-->
    ['~q aer odefinierad i filen ~a'-[Pred,FileName],nl].

generate_message(undefined_procedure_exception)-->
    ['Odefinierade procedurer kommer att signalera undantag (''fel''-valet)'-[],nl].

generate_message(undefined_procedure_fail)-->
    ['Odefinierade procedurer kommer att misslyckas (''misslyckas''-valet)'-[],nl].

generate_message(foreign_load_failed(Margin))-->
    ['~*cLaddning av fraemmande filer MISSLYCKADES.'-[Margin,0' ],nl].
generate_message(foreign_load_failed(Files,Margin))-->
    ['~*cLaddning av fraemmande filer MISSLYCKADES: ~q'-[Margin,0' ,Files],nl].

generate_message(load_shared_failed(Margin))-->
    ['~*cLaddning av fraemmande delad fil MISSLYCKADES.'-[Margin,0' ],nl].

generate_message(help)-->
    ['^C    avbryter Prolog, varefter du kan boerja spaara,'-[],nl,
     '      avsluta ett program, eller laemna Prolog.'-[],nl,
     '^X^D  saender filslutstecken till Prolog (endast under Emacs).'-[],nl,
     nl,
     'Markoeren | ?-  framtraeder naer du aer paa Prolog''s toppnivaa.'-[],nl,
     'Prolog vaentar daa paa en fraaga eller kommando.  Foer att ladda klausuler,'-[],
     nl,
     'anvaend "[filnamn]."  (eller ESC-i under Emacs foer att ladda klausuler fraan'-[],nl,
     'editorns buffert).'-[],nl,nl,
     'Foer att faa hjaelp med ett visst omraade, skriv "help(Omraade)." daer Omraade'-[],nl,
     'aer en atom.  Detta ger dig en meny med all tillgaenglig hjaelp'-[],nl,
     'inom omraaden som boerjar med bokstaeverna i atomen Omraade.  T.ex.'-[],nl,
     '"help(a)." hittar all information om omraaden som boerjar med'-[],nl,
     'bokstaven "a".'-[],nl,
     nl,
     'Skriv "manual(manual)." foer att faa information om den inbyggda manualen.'-[],nl].

generate_message(toplevel) -->	% see query_abbreviation(toplevel), below
    ['Val (";" foer fler loesningar, annars <retur>): '-[],nl].

generate_message(warn_about_reloading(File, OldMod, Module, Goal))-->
    ['~q aer redan laddad i modul ~q.'-[File, OldMod],nl,
     'Den omladdas nu i modul ~q.'-[Module],nl],
    goal(Goal).

generate_message(old_version_of_module_exists(Module))-->
    ['Gammal version av modul ~a existerar'-[Module],nl].

generate_message(needs_reloading(Module))-->
    ['modul ''~w'' behoever omladdas'-[Module],nl].

generate_message(recover_load_clause(Error, File, Clause))-->
    generate_message(Error),
    ['Klausulen som behandlades i ~w var ~w'-[File,Clause],nl].

generate_message(recover_load_clause(Error, File, Clause,
                                   '$stream_position'(_,L,_,_,_))) -->
    generate_message(Error),
    ['Klausulen som behandlades paa rad ~d i ~w var ~w'-[L,File,Clause],nl].

generate_message(misplaced_meta(Term))-->
    ['metapredikatdeklaration inte omedelbart efter moduldeklaration:'-[],
    nl],
    goal((:-meta_predicate(Term))).

generate_message(command_exception(Error,Command))-->
    generate_message(Error),
    generate_message(command_failed(Command)).

generate_message(command_exception(Error,File,Command))-->
    generate_message(Error),
    generate_message(command_failed(File,Command)).

generate_message(multifile_not_declared(Name,Arity))-->
    ['multifildeklaration saknas foer predikat ~q/~d'-[Name,Arity],nl].

generate_message(dynamic_not_declared(Name,Arity))-->
    ['dynamiskdeklaration saknas foer predikat ~q/~d'-[Name,Arity],nl].

generate_message(wrong_multifile_load(Name,Arity,NewCompFlag,CompFlag))-->
    ['klausulre foer multifilpredikat ~q/~d aer '-[Name,Arity]],
    load_past(NewCompFlag),
    [', inte '-[]],
    load_past(CompFlag),
    ['.'-[],nl].

generate_message(multifile_predicate_active(Name,Arity))-->
    ['multifilpredikatet ~q/~d aer aktivt,'-[Name,Arity],nl,
    'inga klausuler kommer att laddas'-[],nl].

generate_message(dynamic_in_static_multifile(Name,Arity))-->
    ['statiskt multifilpredikat ~q/~d deklarerat dynamiskt'-[Name,Arity],nl].

generate_message(cannot_open(AbsFile))-->
    ['Kan inte oeppna filen ~q'-[AbsFile],nl].

generate_message(foreign_undef(Symbol))-->
    ['Oloest fraemmande funktion: ~w'-[Symbol],nl].

generate_message(no_load_to_active_multifile(Name,Arity))-->
    ['Kan inte ladda klausuler foer aktivt multifilpredikat ~q/~d'-[Name,Arity],
    nl].

generate_message(foreign_file_loaded(Margin,File))-->
    ['~*cfraemmande fil ~a laddad'-[Margin,0' ,File],nl].

generate_message(what)-->['What?'-[],nl].

generate_message(sorry_no_help(SearchString))-->
    ['Ledsen, det finns ingen information om ~s.'-[SearchString],nl].

generate_message(variable_not_allowed)-->
    ['Variabler aer inte tillaatna som argument (anvaend endast gemena)'-[],nl].

generate_message(invalid_for_qpc(Atom)) -->
    ['~a aer otillaaten foer qpc'-[Atom],nl].

generate_message(foreign_fn_linkage_failed) -->
    ['~NLaenkning till en fraemmande funktion misslyckades~n'-[], nl].

generate_message(error_at(Pos)) -->
    position(Pos).

generate_message(qpc_error_at(Pos)) -->
    position(Pos).

generate_message(internal(Term)) -->
    ['Internt fel: ~q'-[Term],nl].

generate_message(internal(Term, Pos)) -->
    ['Internt fel: ~q'-[Term],nl],
    position(Pos).

generate_message(invalid_for_qpc(Goal, Atom, Pos)) -->
    ['~a aer otillaaten foer qpc'-[Atom],nl],
    goal(Goal),
    position(Pos).

generate_message(wrong_command_line_file_type(AbsFile, RelFile)) -->
    ['Ej kaellkods- elle QOF-fil: ~q'-[AbsFile],nl],
    ['~q aer inte kompilerad'-[RelFile],nl].

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
    ['inga klausuler foer ~q/~d i ~q'-[Name,Arity,Module],nl].

generate_message(ill_formed_handlers(EH))-->
    ['Felformulerade felhanterare:  ~q'-[EH],nl].

generate_message(non_callable_goal(Goal))-->
    ['icke anropningsbart maal:  ~q'-[Goal],nl].

generate_message(invalid_arithmetic_expression(Goal))-->
    ['Otillaatet aritmetiskt uttryck i maal:  ~q'-[Goal],nl].

generate_message(invalid_arithmetic_goal(Goal))-->
    ['Otillaatet aritmetiskt maal:  ~q'-[Goal],nl].

generate_message(bad_operand(Expression))-->
    ['Felaktig operand:  ~q'-[Expression],nl].

generate_message(unbound_variable_in_arithmetic)-->
    ['Obunden variabel i aritmetiskt uttryck'-[],nl].

generate_message(cutting_to_unbound_variable)-->
    ['Skaer till obunden variabel'-[],nl].

generate_message(unbound_variable_type_tested)-->
    ['Obunden variabel typtestad'-[],nl].

generate_message(command_failed(Command))-->
    ['kommando misslyckades'-[],nl,'maal:  ~q'-[Command],nl].

generate_message(command_failed(File,Command))-->
    ['kommando i ~w misslyckades'-[File],nl,'maal:  ~q'-[Command],nl].

generate_message(compiling(Margin,AbsFile))-->
    ['~*ckompilerar ~w...'-[Margin,0' ,AbsFile],nl].

generate_message(dependency_recorded(Margin,RelFile))-->
    ['~*cberoende paa fraemmande fil ~w registrerat'-[Margin,0' ,RelFile],nl].

generate_message(concise_qof(Margin,AbsFile,QofFileName))-->
    ['~*c~w: ~w'-[Margin,0' ,AbsFile,QofFileName],nl].

generate_message(compiled_into(Margin,AbsFileName,QofFileName, Module, Time))-->
    ['~*c~w kompilerad till ~w i modul ~q, ~3d sekunder'-
	[Margin,0' ,AbsFileName,QofFileName,Module,Time],nl].

generate_message(singleton_variables(N,Name,Arity,Vars))-->
    ['Singelvariabler, klausul ~d i ~q/~d: ~s'-[N,Name,Arity,Vars],nl].

generate_message(clauses_not_together(Pred))-->
    ['Klausuler foer ~q aer inte tillsammans i kaellkodsfil'-[Pred],nl].

generate_message(dups_in_exports(X, Goal)) -->
    ['Duplicerad export ~w in ~w'-[X, Goal], nl].

generate_message(procedure_being_redefined(Name,Arity,PrevFile))-->
    ['Proceduren ~q/~d aer omdefinierad'-[Name,Arity], nl],
    old_file(PrevFile).

generate_message(procedure_redefined(Name,Arity,PrevFile,SourceFile))-->
    ['Procedur ~q/~d omdefinieras i annan fil - '-[Name,Arity],
    nl],
    old_file_new_file(PrevFile,SourceFile),
    ['Vill du verkligen omdefiniera den?'-[],nl].

generate_message(redefine_procedure_help)-->

% see query_abbreviation(yes_no_proceed)

    ['    j    omdefiniera denna procedur.'-[],nl,
     '    n    omdefiniera INTE denna procedur, fortsaett laddning.'-[],nl,
     '    f    fortsaett omdefiniera och tysta kommande varningar.'-[],nl,
     '    a    avbryt.'-[], nl].


generate_message(module_redefined(Module,OldFile,NewFile)) -->
    ['Modul ~q omdefinieras i en annan fil.'-[Module],nl],
    old_file_new_file(OldFile,NewFile),
    ['Vill du verkligen omdefiniera den?'-[],nl].

generate_message(execution_aborted)-->
    ['Koerning avbruten'-[],nl].

generate_message(break_level(BreakLevel))-->
    ['Boerjar brytnivaa ~d'-[BreakLevel],nl].

generate_message(end_break_level(BreakLevel))-->
    ['Avslutar brytnivaa ~d'-[BreakLevel],nl].

generate_message(yes)-->[ja-[],nl].
generate_message(no)-->[nej-[],nl].

generate_message(bindings(vars(Vars), binding(Term),punct(Punct))) -->
    print_vars(Vars),
    [write_term(Term, [portrayed(true), quoted(true), numbervars(true),
	               max_depth(16'7fffff), priority(699)])],
    ['~s'-[Punct], nl].

generate_message(term_expansion_ineffectual(Clause, Pos)) -->
    ['Klausuler foer termexpansion har ingen effekt i qpc-tid'-[], nl],
    culp_clause(Clause),
    position(Pos).

generate_message(profile_message(X)) -->
        ['Profileraren '-[]], profile_message(X), [nl].
generate_message(debug_message(X))-->['Avlusaren '-[]], debug_message(X), [nl].
generate_message(debug_status(X))-->['Avlusaren '-[]], debug_message(X), [nl].

generate_message(import_module(Module,SrcMod))-->
    ['Importera modul ~q till modul ~q?'-[Module,SrcMod],nl].

generate_message(blame_on(Exception,Ancestor)) --> 
	( generate_message(Exception) ->
	      ['maal: ~q'-[Ancestor],nl]
	; ['~w'-[Exception],nl],
	  ['maal: ~q'-[Ancestor],nl]
	).

generate_message(no_qof_generated(NoErrors, OutFile))-->
    ['Antal fel: ~d'-[NoErrors],nl],
    ['QOF-fil ej genererad: ~w'-[OutFile],nl].

generate_message(qof_version(File)) -->
    ['Fel qof-version: ~w'-[File],nl].

generate_message(restarting(Engine))-->['Aaterstaeller ~w'-[Engine],nl].

generate_message(statistic(MemoryInuse, MemoryFree,  GlobalTotal, LocalTotal,
			GlobalInuse, GlobalFree,  TrailInuse,  LocalInuse,
			LocalFree,   CodeInuse,   Overflow,    Repartition,
			Trim,	     GlobalOver,  LocalOver,   Gcs,
			GcFreed,     GcTime,      Time)) -->
	{TotalMemory is MemoryInuse + MemoryFree},
	[nl],
	['minne (totalt)~t~d~29| oktetter:~t~d~47| anvaenda, ~t~d~66| lediga'-
		[TotalMemory, MemoryInuse, MemoryFree], nl],
	['   programminne~t~d~29| oktetter'-[CodeInuse], nl],
	{Global is GlobalTotal - GlobalFree},
	['   globalt minne~t~d~29| oktetter:~t~d~47| anvaenda, ~t~d~66| lediga'-
		[GlobalTotal, Global, GlobalFree], nl],
	['      global stack~t~d~47| oktetter'-[GlobalInuse], nl],
	['      spaar (trail)~t~d~47| oktetter'-[TrailInuse], nl],
	{SystemGlobal is GlobalTotal - GlobalInuse - GlobalFree - TrailInuse},
	['      system~t~d~47| oktetter'-
		[SystemGlobal],nl],
	{Local is LocalTotal - LocalFree},
	['   lokal stack~t~d~29| oktetter: ~t~d~47| anvaenda, ~t~d~66| lediga'-
		[LocalTotal, Local, LocalFree], nl],
	['      lokal stack~t~d~47| oktetter'-[LocalInuse], nl],
	{SystemLocal is LocalTotal - LocalInuse - LocalFree},	
	['      system~t~d~47| oktetter'-
		[SystemLocal], nl, nl],
	{ShiftTime is (Overflow + Repartition + Trim) / 1000.0},
	[' ~3f s foer ~d globala och ~d lokala minnesflyttningar'-
		[ShiftTime, GlobalOver, LocalOver], nl],
	{Gc is GcTime/1000.0},	
	[' ~3f s foer ~d skraepsammlingar '-[Gc, Gcs]],
	['som samlade ~d oktetter'-[GcFreed], nl],
	{Runtime is Time/1000.0},
	[' ~3f s koertid'-[Runtime], nl].

generate_message('') --> []. % a silent message

% Code for compatibility with message system names in Release 3.0.  This
% is useful for anybody who customized the message system prior to 3.1,
% and also for people who want to use ProWindows 1.2 with Release 3.1.

generate_message(Message) --> parse_message(Message).

user:(:- multifile generate_message_hook/3).
user:(generate_message_hook(Message) --> parse_message_hook(Message)).


/************* fragments ***************************************************/

print_vars([]) --> [].
print_vars([H|T]) -->
	['~w = '-[H]],
	print_vars(T).

bad_tokens([])-->!.
bad_tokens(Tokens)-->['~s'-[Tokens],nl].

culprit(Culprit) --> {Culprit == 0}, !, [].
culprit(Culprit) --> [' ~q'-[Culprit],nl].

old_file_new_file(PrevFile,NewFile)-->
    ['    Gammal fil:   ~w'-[PrevFile],nl,
     '    Ny file:      ~w'-[NewFile],nl].

old_file(PrevFile)-->
    ['    Gammal fil:   ~w'-[PrevFile],nl].

profile_message(off) --> ['aer avstaengd'-[]].
profile_message(on) --> ['aer paaslagen'-[]].

debug_message(nonstop) --> ['avstaengd'-[]].
debug_message(nodebug) --> ['avstaengd'-[]].	% unnecessary?
debug_message(creep) --> ['boerjar krypa -- visar allt (spaarning)'-[]].
debug_message(leap) --> ['boerjar skutta -- visar spionpunkter (avlusning)'-[]].
debug_message(skip) --> ['ignorerar allt under en skippning'-[]].
debug_message(error) --> ['visar var ett fel signalerades'-[]].
debug_message(zip) --> ['boerjar rusa -- visar spionpunkter'-[]].

position(between('$stream_position'(_,Line,_,_,_),Stream), File)-->
    {line_count(Stream,Current)},
    ['mellan rad ~d och ~d'-[Line,Current]],
    syntax_err_file(File).
position(at(Char,Line,_Stream), File)-->
    ['paa rad ~d, kolumn ~d'-[Line,Char]],
    syntax_err_file(File).
position(line_and_file(Line, File)) -->
	( {File == user; File == 0; File == '-'} -> 
	      []
	; {Line == 0} ->
	      ['Fil: ~q'-[File],nl]
	; ['Ungefaer rad: ~d, fil: ~q'-[Line, File],nl]
	).
position(pos_and_file('$stream_position'(_,Line,_,_,_), File)) -->
	( {File == user; File == 0; File == '-'} -> 
	      []
	; {Line == 0} ->
	      ['Fil: ~q'-[File],nl]
	; ['Ungefaer rad: ~d, fil: ~q'-[Line, File],nl]
	).

syntax_err_file(user) -->
	!,
	[nl].
syntax_err_file(File) -->
	[' i fil ~w'-[File], nl].


type(TypeName,Culprit)-->
    typename(TypeName),
    [' foervaentades'-[]],
    (  {Culprit == 0}
    -> []
    ;  {nonvar(Culprit), Culprit = '$culprit'(ComplexCulprit)}
    -> [','-[],nl,'men '-[]],
       cookie_culprit(ComplexCulprit),
       [' hittades'-[]]
    ;  [', men ~q hittades'-[Culprit]]
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

existence_culprit(0) --> !, [' existerar inte'-[],nl].
existence_culprit(Culprit) --> !, [' ~q existerar inte'-[Culprit],nl].

message(0) --> !, [].
message('') --> !, [].
message(X) --> msg(X), [nl].

msg(errno(E)) -->
    {	integer(E),
	error_message(E, Etype, ErrorMsg, 0),	% this is a built-in
	errno_heading(Etype, ErrorHead)
    },
    ['~a : ~a'-[ErrorHead, ErrorMsg]].
msg('End of File found:  unclosed if-endif sequence')-->
    ['Filslut: oavslutad if-endif sekvens'-[]].
msg('Foreign interface, call to Unix "ld" failed')-->
    ['Fraemmande spraaks laddning, anrop till Unix "ld" misslyckades'-[]].
msg('Foreign interface, intermediate use of Unix "cc" failed')-->
    ['Fraemmande spraaks laddning, anrop till Unix "cc" misslyckades'-[]].
msg('File has incorrect header')-->
    ['Fil har felaktigt huvud'-[]].
msg('File has wrong version of _DYNAMIC')-->
    ['Fil har fel version av _DYNAMIC'-[]].
msg('Cannot read header of object file') -->
    ['Kan inte laesa objektfilshuvud'-[]].
msg('Cannot expand relative filename') -->
    ['Kan inte expandera relativt filnamn'-[]].
msg('Prolog not started yet') --> ['Prolog inte startad aennu'-[]].
msg('Restore failed') --> ['Aaterstaellning misslyckades'-[]].
msg('File not loaded') --> ['Fil ej laddad'-[]].
msg(cannot_read(File)) --> ['Laesning av ~w misslyckades'-[File]].
msg('file search path too long') --> ['Filsoekningsstig kunde inte haerledas - cirkulaer defintion'-[]].
msg(cannot_read(File)) --> ['Laesning misslyckades paa ~w'-[File]].
msg('float overflow') --> ['flyttalsspill'-[]].
msg('integer overflow') --> ['heltalsspill'-[]].
msg('non-zero number') --> ['tal skilt fraan noll'-[]].
msg(end_of_file) --> ['filslut'-[]].
msg('incompatible argument type') --> ['ej matchande argumenttyp'-[]].
msg('application terminates') --> ['tillaempning avslutas'-[]].
msg('Not a current module') --> ['Ej en aktuell modul'-[]].
msg('Circular file_search_path definition') --> 
    ['Circulaer definition av filsoekningsstig'-[]].
msg('too many free variables'(Limit)) --> 
    ['foer maanga fria variabler, begraensat till ~d'-[Limit]].
msg(length>N) --> ['laengd av lista oeverstiger ~w'-[N]].
msg('Arithmetic error') --> ['Aritmetiskt fel'-[]].
msg('wrong number of arguments') --> ['fel antal argument'-[]].
msg(X>255) --> ['~q'-[X>255]].
msg('prefix operator used improperly'(Op)) -->
    ['prefixoperator ~w felaktigt anvaend'-[Op]].
msg('term has arity greater than 255') -->
    ['term har aritet stoerre aen 255'-[]].
msg('invalid database reference') -->
    ['felaktig databasreferens'-[]].
msg('missing ]') --> ['saknad ]'-[]].
msg(wrong_format_option_type(Type,Option)) -->
    ['argumentet foer formatkontrollvalet "~w" maaste vara av typ "'-
	[Option]],
    typename(Type),
    ['".'-[]].
msg(however_one_is_defined(One))--> ['emellertid, ~w aer definierad'-[One]].
msg(however_list_are_defined(List))--> ['emellertid, ~w aer definierade'-[List]].
msg('Internal error for multifile') --> ['Internt fel foer multifil'-[]].
msg('string too long') --> ['straeng foer laang'-[]].
msg(bound(compiled_clause_size,S,Unit)) -->
	['Kompilerad representation av klausul oeverskrider ~d ~w'-[S,Unit]].
msg(bound(compiled_clause_perms,S)) -->
 ['Kompilerad representation av klausul har mer aen ~d permanenta variabler'-[S]].
msg(bound(compiled_clause_temps,S)) -->
 ['Kompilerad representation av klausul har mer aen ~d temporaera variabler'-[S]].

%   Tokenizer error messages
msg('atom too long') -->
    ['atom foer laang'-[]].
msg('floating point number too large') -->
    ['flyttal foer stort'-[]].
msg('ill-formed floating-point number') -->
    ['felaktigt uttryckt flyttal'-[]].
msg('floating point number too long') -->
    ['flyttal foer stort'-[]].
msg('end of file in 0''character') -->
    ['filslut i 0''tecken'-[]].
msg('integer too large') -->
    ['heltal foer stort'-[]].
msg('ill-formed integer') -->
    ['felaktigt uttryckt heltal'-[]].
msg('integer too long') -->
    ['heltal foer laangt'-[]].
msg('radix not 0 or 2..36') -->
    ['talbas ej 0 eller 2..36'-[]].
msg('string too long') -->
    ['straeng foer laang'-[]].
msg('end of file in ''atom') -->
    ['filslut i ''atom'-[]].
msg('end of file in "/*" comment') -->
    ['filslut i "/*" kommentar'-[]].


errno_heading(0, 'Unix fel').
errno_heading(1, 'QP fel').

goal(Goal) --> goal_aux(Goal), !.
goal(Goal) --> ['maal:  ~q'-[Goal],nl].

goal_aux(Goal) --> {var(Goal), !, fail}.
goal_aux(0) --> [].
goal_aux(user:Goal) --> goal(Goal).

culp_clause(Clause) --> clause_aux(Clause), !.
culp_clause(Clause) --> ['klausul:  ~q'-[Clause],nl].

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
    ->  X = ' i argument ~d i ~q'-[ArgNo,Spec]
    ;   X = ' i ~q'-[Spec]
    ).

commandtype(0) --> [].
commandtype(cut) --> [cut-[]].
commandtype(clause) --> [klausul-[]].
commandtype(declaration) --> [deklaration-[]].
commandtype('meta_predicate declaration') --> ['metapredikatdeklaration'-[]].
commandtype(use_module) --> [use_module-[]].
commandtype('multifile assert') --> ['multifilsassert'-[]].
commandtype('module declaration') --> ['moduldeklaration'-[]].
commandtype('dynamic declaration') --> ['dynamisk deklaration'-[]].
commandtype(meta_predicate(M)) --> ['metapredikatdeklaration foer ~q'-[M]].
commandtype(argspec(A)) --> ['Felaktig argument specifikation ~q'-[A]].
commandtype(foreign_file(File)) -->
    ['foreign_file/2 deklaration foer ~w'-[File]].
commandtype(foreign(F)) --> ['foreign/3 deklaration foer ~w'-[F]].
commandtype((initialization)) --> ['initialization/1'-[]].
commandtype(abort) --> ['anrop till abort/0'-[]].
commandtype(debug) --> ['Kan ej saetta paa avlusning'-[]].
commandtype(foreign_returned) --> ['fraemmande funktion returnerad'-[]].

contexttype('pseudo-file ''user''') --> ['foer pseudo-fil ''user'''-[]].
contexttype(if) --> ['inuti en if'-[]].
contexttype(bof) --> ['i boerjan av fil'-[]].
contexttype(bom) --> ['i boerjan av modul'-[]].
contexttype(before) --> ['foere'-[]].
contexttype('after clauses') --> ['efter klausuler'-[]].
contexttype('not multifile and defined') -->
    ['foer definierad, icke multifilprocedur'-[]].
contexttype('static multifile') --> ['foer statisk multifilprocedur.'-[]].
contexttype(language(L)) --> ['for spraak ~w.'-[L]].
contexttype(file_load) --> ['under laddning av fil(er).'-[]].
contexttype(notoplevel) --> ['naer toppnivaa saknas'-[]].
contexttype(open_query) --> ['en prologfraaga var oeppen'-[]].
contexttype(profiling) --> ['profilering'-[]].
contexttype(query) --> ['i fraaga'-[]].
contexttype(started) --> ['uppstartad'-[]].

typename(Type-value) --> ['riktigt ~w vaerde'-[Type]].
typename(':- module header for') --> [':- modulhuvud foer'-[]].
typename('File containing module') --> ['Fil med modul'-[]].
typename('Name/Arity') --> ['Namn/Aritet'-[]].
typename('O/S interface for') --> ['O/S-graenssnitt foer'-[]].
typename('Symbol table in') --> ['Symboltabell i'-[]].
typename('QP_qid') --> ['QP_qid'-[]].
typename('arithmetic expression') --> ['aritmetiskt uttryck'-[]].
typename('built-in predicate') --> ['inbyggt predikat'-[]].
typename('clause or record') --> ['klausul eller record'-[]].
typename('control string') --> ['kontrollstraeng'-[]].
typename('definition for') --> ['definition av'-[]].
typename('final object file') --> ['slutlig objektkodsfile'-[]].
typename('file (not opened by see/1 or tell/1)') -->
    ['fil (ej oeppnad med see/1 eller tell/1)'-[]].
typename('file or stream') --> ['fil eller stroem'-[]].
typename('file specification') --> ['filspecifikation'-[]].
typename('file_search_path') --> ['kaenda filsoekningsstigar'-[]].
typename('foreign file') --> ['fraemmande fil'-[]].
typename('foreign files') --> ['fraemmande filer'-[]].
typename('foreign function') --> ['fraemmande funktion'-[]].
typename('foreign parameter specification') -->
    ['fraemmande funktions parameterspecifikation'-[]].
typename('foreign parameter type') --> ['fraemmande funktions parametertyp'-[]].
typename('foreign procedure') --> ['fraemmande funktion'-[]].
typename('format specification') --> ['formatspecifikation'-[]].
typename('header for file') --> ['huvud foer fil'-[]].
typename('help directory') --> ['hjaelpkatalog'-[]].
typename('help index file') --> ['hjaelpindexfil'-[]].
typename('interface predicate') --> ['graensnittspredikat'-[]].
typename('leash specifications') --> ['skuttspecifikationer'-[]].
typename('lhs term') --> ['vaenstersidoterm'-[]].
typename('list of predicate specifications') -->
    ['lista av predikatspecifikationer'-[]].
typename('list or all') -->
	['lista av importerade predikat eller ''all'''-[]].
typename('load option')-->['laddningsval'-[]].
typename('manuals file') --> ['manualfil'-[]].
typename('next character of') --> ['naesta tecken av'-[]].
typename('non-zero number') --> ['tal skilt fraan noll'-[]].
typename('open file') --> ['oeppen fil'-[]].
typename('predicate interface specification') -->
    ['graenssnittsdefinition foer predikat'-[]].
typename('proper_file') --> ['en riktig fil'-[]].
typename('qof_file') --> ['en Quintus Object File ("QOF")'-[]].
typename('qof_version') --> ['en Quintus Object File ("QOF")'-[]].
typename(qof_ver(Ver)) --> ['QOF-version ~w'-[Ver]].
typename(qof_rev(Rev)) --> ['QOF-revision mindre aen eller lika med ~w'-[Rev]].
typename('really_qof_version') --> ['en aeldre QOF-version'-[]].
typename('read_term option') --> ['termlaesningsval'-[]].
typename('seek method') --> ['soekmetod'-[]].
typename('seek offset') --> ['soekoffset'-[]].
typename('shared object') --> ['delat objekt'-[]].
typename('spypoint specification') --> ['spionpunktsdefintion'-[]].
typename('stream position') --> ['stroemposition'-[]].
typename('symbols referenced in') --> ['symbol(er) refererade i'-[]].
typename('temp file for help menu') --> ['temp-fil foer hjaelpmeny'-[]].
typename('text_file') --> ['textfil'-[]].
typename('true or false') --> ['true eller false'-[]].
typename('valid file') -->  ['riktig file'-[]].
typename('valid file or list of files') -->  ['riktig fil eller lista av filer'-[]].
typename('valid message term')-->['riktig meddelandeterm'-[]].
typename('valid option') --> ['riktigt val'-[]].
typename('valid radix') --> ['riktig talbas'-[]].
typename(0) --> [].
typename(atom) --> [atom-[]].
typename('atom or list') --> ['atom eller lista'-[]].
typename('atom or number') --> ['atom eller nummer'-[]].
typename(atom_or_variable) --> ['atom eller variabel'-[]].
typename(atomic) --> ['atomisk'-[]].
typename(between(L,H)) --> ['naagot mellam ~w och ~w'-[L,H]].
typename(built_in) --> ['inbyggt predikat'-[]].
typename(callable) --> [anropningsbar-[]].
typename(char) --> ['char'-[]].
typename(chars) --> ['lista av teckenkoder'-[]].
typename(character) --> ['tecken'-[]].
typename(clause) --> ['klausul'-[]].
typename(constant)-->[konstant-[]].
typename(compiled)-->[kompilerad-[]].
typename(compound)-->[sammansatt-[]].
typename(control_arg_pair) --> ['kontrolargumentpar'-[]].
typename(constant) --> ['konstant'-[]].
typename(db_reference) --> ['databasreferens'-[]].
typename(declaration) --> [deklaration-[]].
typename(directory) --> [katalog-[]].
typename(foreign)-->[fraemmande-[]].
typename(file) --> [fil-[]].
typename(filename) --> ['filnamn'-[]].
typename(file_or_stream) --> ['fil eller stroem'-[]].
typename(file_option) --> ['filval'-[]].
typename(file_specification) --> ['filspecifikation'-[]].
typename(flag) --> [flagga-[]].
typename(float) --> [flyttal-[]].
typename(ground) --> [grund-[]].
typename(imported_predicate) --> ['importerat predikat'-[]].
typename(interface_argument_specification) -->
    ['graenssnitts argumentspecifikation'-[]].
typename(integer) --> [heltal-[]].
typename(interpreted)-->[interpreterad-[]].
typename(list) --> [lista-[]].
typename(list_or_all) --> ['lista eller ''all'''-[]].
typename(meta_predicate_argument_specifier) -->
    ['metapredikatsspecifikation'-[]].
typename(module) --> [modul-[]].
typename(nl_ended_list) --> ['lista avslutad med atomen nl'-[]].
typename(nonvar) --> [ickevariabel-[]].
typename(not_user) --> ['godtycklig atom utom ''user'''-[]].
typename(nonneg) --> ['icke-negativt heltal'-[]].
typename(number) --> ['nummer'-[]].
typename(one_of(List)) --> ['ett element ur maengden ~q'-[List]].
typename(oneof(List))  --> ['ett element ur maengden ~q'-[List]].
typename(pair) --> [par-[]].
typename(predicate_specification) --> ['predikatspecifikation'-[]].
typename(procedure) --> [procedur-[]].
typename(proper_list) --> ['riktig lista'-[]].
typename(read_term_option) --> ['terminlaesningsval (read_term)'-[]].
typename(stream) --> ['stroem'-[]].
typename(symbol) --> ['symbol'-[]].
typename(term) --> [term-[]].
typename(text) --> [text-[]].
typename(valid_file) -->  ['korrekt file'-[]].
typename(valid_file_or_list_of_files) -->  ['korrekt fil eller lista av filer'-[]].
typename(value(X)) --> ['vaerdet ~q'-[X]].
typename(var) --> [variabel-[]].
typename(write_term_option) -->  ['termutskriftsval (write_term)'-[]].

operation(0) --> [].
operation('find absolute path of') --> ['finn absolut stig foer'-[]].
operation('get the time stamp of') --> ['finn tidsstaempel foer'-[]].
operation('set prompt on') --> ['saett prompt foer'-[]].
operation('use close(filename) on') --> ['anvaend close(filnamn) foer'-[]].
operation(abolish) --> [avskaffa-[]].
operation(add_advice) --> ['saetta parasit paa'-[]].
operation(change) --> [aendra-[]].
operation(check_advice) --> ['parasitchecka'-[]].
operation(clauses) --> ['laes klausul foer'-[]].
operation(close) --> [staeng-[]].
operation(create) --> [skapa-[]].
operation(export) --> [exportera-[]].
operation(flush) --> [flusha-[]].
operation(import) --> [importera-[]].
operation(load) --> [ladda-[]].
operation(nocheck_advice) --> ['parasitchecka'-[]].
operation(nospy) --> [(spionera)-[]].
operation(open) --> [oeppna-[]].
operation(position) --> [positionera-[]].
operation(read) --> [laes-[]].
operation(redefine) --> [omdefiniera-[]].
operation(save) --> [spara-[]].
operation(spy) --> [(spionera)-[]].
operation(write) --> [skriv-[]].

resource(0) --> [].
resource(memory) --> [': mimnne slut'-[]].
resource('too many open files') --> [': foer maanga oeppnade filer'-[]].
resource(Goal) --> [': maal ~q'-[Goal]].

/*********    Warning and informational message fragments     ****************/

advice(no_preds, _Kind, predicate_family(Module:Atom)) -->
	['Det finns inga predikat med namnet ~q i modul ~q'-[Atom,Module]].
advice(no_clauses, Kind, Spyspec) -->
	['Du har inga klausuler foer '-[]],
	spyspec(Spyspec, Kind).
advice(not_on_dynamic, Kind, Spyspec) -->
	spyspec(Spyspec, Kind),
	['aer dynamisk'-[]].
advice(not_enough_clauses, Kind, Spyspec) -->
	['Ej tillraeckligt med klausuler foer '-[]],
	spyspec(Spyspec, Kind).
advice(not_enough_calls_to, Kind,
		call(Callerspec,Clausenum,Predspec,_Callnum)) -->
	['Ej tillraeckligt med anrop till '-[]],
	predspec(Predspec, user, Kind),
	['i klausul ~w of '-[Clausenum]],
	predspec(Callerspec, user, '').
advice(already_spied, Kind, Spyspec) -->
	['Det finns redan en spionpunkt paa '-[]],
	spyspec(Spyspec, Kind).
advice(spypoint_placed, Kind, Spyspec) -->
	['Spionpunkt placerad paa '-[]],
	spyspec(Spyspec, Kind).
advice(spypoint_removed, Kind, Spyspec) -->
	['Spionpunkt borttagen fraan '-[]],
	spyspec(Spyspec, Kind).
advice(no_spypoint, Kind, Spyspec) -->
	['Det finns ingen spionpunkt paa '-[]],
	spyspec(Spyspec, Kind).
advice(checking_already_enabled, Kind, Spyspec) -->
	['Parasitcheckning redan paaslagen foer '-[]],
	spyspec(Spyspec, Kind).
advice(checking_enabled, Kind, Spyspec) -->
	['Parasitcheckning paaslagen foer '-[]],
	spyspec(Spyspec, Kind).
advice(checking_disabled, Kind, Spyspec) -->
	['Parasitcheckning avslagen foer '-[]],
	spyspec(Spyspec, Kind).
advice(checking_not_enabled, Kind, Spyspec) -->
	['Parasitcheckning aer inte paaslagen foer '-[]],
	spyspec(Spyspec, Kind).

spyspec_lines([]) --> [].
spyspec_lines([Spec|Specs]) -->
	['	'-[]],
	spyspec(Spec, ''),		% should we get Kind right?
	[nl],
	spyspec_lines(Specs).

spyspec(predicate(Predspec), Kind) --> predspec(Predspec, user, Kind).
spyspec(call(Callerspec,Clausenum,Predspec,Callnum), Kind) -->
	['anrop ~w till '-[Callnum]],
	predspec(Predspec, user, Kind),
	['i klausul ~w av '-[Clausenum]],
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
debug_extra(undefined) --> [' (odefinierad): '-[]].
debug_extra(built_in) --> [' (inbyggd): '-[]].
debug_extra(locked) --> [' (laast): '-[]].
debug_extra(foreign) --> [' (fraemmande): '-[]].
debug_extra((dynamic)) --> [' (dynamisk): '-[]].
debug_extra((multifile)) --> [' (multifil): '-[]].
debug_extra(head(This)) --> [' [~d]: '-[This]].
debug_extra(head(This,Next)) --> [' [~d->~w]: '-[This,Next]].

debug_port('') --> [].
debug_port('Call') --> ['Anrop'-[]].
debug_port('Exit') --> ['Utgaang'-[]].
debug_port('Redo') --> ['Omproeva'-[]].
debug_port('Fail') --> ['Misslyckas'-[]].
debug_port('Done') --> ['Gjord'-[]].
debug_port('Head') --> ['Huvud'-[]].
debug_port('Exception') --> ['Undantag'-[]].

advice_kind('')-->[].
advice_kind((dynamic))-->['dynamiskt predikat '-[]].
advice_kind(builtin)-->['inbyggt predikat '-[]].
advice_kind(compiled)-->['kompilerat predikat '-[]].

% optional_info(Info, Info0, Before0, Before1, Before) -->
% The idea of this is Info should be printed iff Info \== Info0.  If
% it IS printed, it should be preceded by Before0.  Before is what should
% precede the NEXT optional thing:  Before0 if we didn't print anything,
% and Before1 if we did.

optional_info(Info, Info, X, _, X) --> [], !.
optional_info(Info, _, Before0, Before, Before) -->
    ['~w~w'-[Before0,Info]].

severity(informational) --> [information-[]].
severity(warning) --> [varning-[]].
severity(error) --> [fel-[]].

load_area(procedure) --> [procedur-[]].
load_area(region) --> [region-[]].
load_area(buffer) --> [buffert-[]].

load_preposition(procedure) --> [' fraan '-[]].
load_preposition(region) --> [' fraan '-[]].
load_preposition(buffer) --> [' med '-[]].

load_past(compile) --> [kompilerad-[]].
load_past(load) --> [laddad-[]].
load_past(qof) --> [laddad-[]].
load_past((dynamic)) --> [(dynamisk)-[]].

load_noun(compile) --> [kompilering-[]].
load_noun(qof) --> [laddning-[]].
load_noun(load) --> [laddning-[]].

load_message('')-->[].
load_message('more clauses for multifile ') -->
    ['mer klausuler foer multifil '-[]].

load_gerund(compile)-->[kompilerar-[]].
load_gerund(load)-->[laddar-[]].
load_gerund(qof)-->[laddar-[]].

name_clash(Module,Name,Arity,Module) --> !,
    ['NAMNKROCK: ~q/~q aer redan definerad i modul ~q'-[Name,Arity,Module]].
name_clash(Module,Name,Arity,DefMod) -->
    ['NAMNKROCK: ~q/~q aer redan importerat till modul ~q fraan ~q'-
	[Name,Arity,Module,DefMod]].

ignore_name_clash(Module,Module) --> !,
    ['ett foersoek att definiera det i modul ~q ignoreras.'-[Module]].
ignore_name_clash(_,NewMod) -->
    ['et foersoek att importera det fraan modul ~q ignoreras.'-[NewMod]].

% query_abbreviation/3.  The idea here is to list the valid abreviations
% for a given key word.  For example, a french translator might decide
% that the letters 'O' and 'o' are reasonable abreviations for 'oui'
% (yes), and therefore write 'yes-"oO"'.

query_abbreviation(yes_or_no,'(j/n)',[yes-"jJ",no-"nN",abort-"aA"]).

query_abbreviation(toplevel,'',[yes-[10],no-";"]).  % see toplevel, above

query_abbreviation(yes_no_proceed,'(j,n,f, eller ? foer hjaelp)',
    [yes-"jJ",
     no-"nN",
     proceed-"fF",
     abort-"aA"]).

query_abbreviation(debugger,'',
    [abort-"aA",
     ancestors-"gG",
     backup-"xX",
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
     quasi_skip-"qQ",
     print-"pP",
     raise-"eE",
     retry-"rR",
     skip-"sS",
     (spy)-"+",
     unlock-"uU",
     write-"wW",
     zip-"zZ"]).

foreign('QU_error_message', c, error_message(+integer, -integer, -string,
					   [-integer])).
foreign_file(messages(system('QU_messages')), ['QU_error_message']).
:- load_foreign_files([messages(system('QU_messages'))], []),
	abolish([foreign/3, foreign_file/2]).
