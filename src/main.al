/* Darsana P Josyula */

expect_list([]).
utt_list([]).
domain_list([]).

expected_pause(130).
currUtt(0,0).
prompt_step(0).
max_violations(3).
global_violations(0,0,0).
local_violations(0).
prev_utt_time(0).
prev_prompt_time(0).
curr_wait_time(0).
violation_density(0).
utt_on_time(0).

fif(and(idling(Step),
		and(expected_pause(PauseTime),
				and(currUtt(CurrUtt,CurrUttStep),
					and(prompt_step(PromptStep),
						and(curr_wait_time(CurrWait),
							and(local_violations(LocalViol),
						eval_bound(update_wait_time(Step, CurrUttStep, PromptStep, PauseTime, CurrWait, LocalViol),[Step,CurrUttStep,PromptStep,PauseTime,CurrWait,LocalViol]))))))),
conclusion(call(ac_prompt(Step,PromptStep),Step))).

fif(and(idling(Step),
		and(expected_pause(ExpPause),
			and(max_violations(MaxViolations),
				and(currUtt(CurrUtt,CurrUttStep),
					and(global_violations(GlobViol,LocalViol,CurrUttStep),
					eval_bound(revise_expectation(MaxViolations,ExpPause,LocalViol,GlobViol,CurrUttStep),[MaxViolations,ExpPause,LocalViol,GlobViol,CurrUttStep])))))),
conclusion(exp_revised(Step))).


/*PROCESS OBSERVATIONS FROM THE DOMAIN*/
fif(and(observation(O,A),
	and(eval_bound(pos_int_u(now(T)), []),
	    eval_bound(df(observation(O,A)), [O,A]))),
conclusion(observation(O,A,T))).

fif(and(observation(O, A, T),
	and(domain_expect(Utt, [observation,O]),
	    eval_bound(\+ pos_int_u(satisfied(Utt, [observation,O])), [Utt,O]))),
conclusion(satisfied(Utt, [observation,O]))).

fif(and(desire(Utt,[inform,O,Type]),
	and(observation(O,_,_),
	    and(eval_bound(\+ pos_int_u(satisfied(Utt, [inform,O, Type])), 
			   [Utt,O,Type]),
		eval_bound(mult_gather_all([observation(O,_,_), 
					    isa(_,_),
					    equil(_,_)],
					    Asserts), [O])))),
conclusion(call(ac_report_observation(Utt, O, Type),Asserts,Utt))).

fif(and(done(ac_report_observation(Utt, O, _),_,Utt),
	desire(Utt,[inform,O,Type])),
conclusion(satisfied(Utt,[inform,O,Type]))).

/*BEGIN****************Maintaining utterance structure**************************/
/* if Utt is an utterance and utterance list is Ulist and Utt in Ulist: update_utt_list */
fif(and(utterance(Utt), 
        and(utt_list(Ulist),
			and(eval_bound(pos_int_u(now(T)), []),
				eval_bound(\+ member(Utt,Ulist),[Utt, Ulist])))),
conclusion(update_utt_list(Utt,Ulist))).

fif(and(update_utt_list(Utt,Ulist),
        and(eval_bound(df(utt_list(Ulist)),[Ulist]),
			and(eval_bound(pos_int_u(now(T)), []),
				and(eval_bound(update_global_violations(T),[T]),
					eval_bound(update_current_utterance(Utt,T),[Utt,T]))))),
conclusion(utt_list([Utt|Ulist]))).

fif(and(utterance(Utt),
        and(expect(U,Need),
	    and(eval_bound(compare(>,Utt,U), [Utt,U]),
	    eval_bound(\+ pos_int_u(response(U,Need,_)), [U,Need])))),
conclusion(response(U,Need,Utt))).

fif(and(end_of_parse(Utt),
	and(eval_bound(mult_gather_all([links(Utt,_,_,_,_), 
				   value_of(Utt,_,_)],
				   Asserts), [Utt]),
		eval_bound(add_user_to_utt(Utt), [Utt]))),
conclusion(call(ac_find_links(Utt), Asserts, Utt))).    


/*use context to parse*/
fif(and(done(ac_find_links(Utt),_,Utt),
	and(eval_bound(\+ pos_int_u(link(Utt,_,_,_)), [Utt]),
	    and(response(U,Need,Utt),
		eval_bound(mult_gather_all([value_of(Utt,_,_), 
					    isa(_,_),
					    equil(_,_)],
					    Asserts), [Utt])))),
conclusion(call(ac_parse_phrase(Utt, Need), Asserts, Utt))).

fif(and(done(ac_find_links(Utt),_,Utt),
        and(eval_bound(\+ pos_int_u(link(Utt,_,_,_)), [Utt]),
            and(eval_bound(\+ pos_int_u(response(_,_,Utt)), [Utt]),
                eval_bound(mult_gather_all([value_of(Utt,_,_),
					    isa(_,_),
					    equil(_,_)],
					    Asserts), [Utt])))),
conclusion(call(ac_parse_phrase(Utt, []), Asserts, Utt))).

fif(failed(ac_parse_phrase(Utt,_),_,Utt),
conclusion(fix_link_length(Utt,2))).

fif(and(done(ac_find_links(U),_,U),
	and(unused_cost(U,_,Cost), 
	    and(eval_bound(Cost \== 0, [Cost]),
		and(link(U,_,_,_),
		    eval_bound(\+ pos_int_u(fix_link_length(U,_)), [U]))))),
conclusion(fix_link_length(U,2))).

fif(and(fix_link_length(U,L),
	and(eval_bound(\+ pos_int_u(doing(ac_fix_linkage(U,L),_,U)),[U, L]),
	    and(eval_bound(\+ pos_int_u(done(ac_fix_linkage(U,L),_,U)),[U, L]),
				    eval_bound(mult_gather_all(
						       [value_of(U,_,_),
							verb(U,_),
							isa(_,_),
							structure(_,_,_,_),
							link(U,_,_,_)], 
							       Asserts), [U])))),
conclusion(call(ac_fix_linkage(U, L), Asserts, U))).

fif(and(failed(ac_fix_linkage(Utt, L),_,Utt),
	and(fix_link_length(Utt, L),
	    and(eval_bound(L \== 5, [L]),
		and(eval_bound(NL is L + 1, [L]),
		    eval_bound(df(fix_link_length(Utt, L)), [Utt, L]))))),
conclusion(fix_link_length(Utt, NL))).

fif(failed(ac_fix_linkage(Utt, 5),_,Utt),
conclusion(call(ac_report_fail(Utt,[fix_linkage]),[], Utt))).

fif(and(done(ac_fix_linkage(Utt,_),_,Utt),
	eval_bound(mult_gather_all([value_of(Utt,_,_), 
				    link(Utt,_,_,_),
				    unused_cost(Utt, _,_)], Asserts), [Utt])),
conclusion(call(ac_find_unused_cost(Utt), Asserts, Utt))).

fif(unused_cost(U,_,0),  
conclusion(parsed(U))).

fif(and(parsed(U),
	and(verb(U,_),
	        eval_bound(mult_gather_all([verb(U,_), value_of(U,_,_)], 
				Asserts), [U]))),
conclusion(call(ac_main_verb(U), Asserts, U))).

fif(failed(ac_main_verb(Utt),_,Utt),
conclusion(call(ac_report_fail(Utt,[main_verb]),[], Utt))).

/*Once we have the main_verb, look for the corresponding command in the data 
dictionary.*/

fif(and(or(satisfiedallneeds(Utt),
	   main_verb(Utt,Verb)),
        and(eval_bound(\+ pos_int_u(domain_command(Utt,_,_)), [Utt]),
	    and(eval_bound(\+ pos_int_u(alfred_command(Utt,_,_)), [Utt]),
		and(eval_bound(\+ pos_int_u(complex_command(Utt,_,_)), [Utt]),
		    and(eval_bound(\+ pos_int_u(doing(ac_think(Utt,_),_, Utt)), [Utt]),
			eval_bound(mult_gather_all([isa(_,_),
						    value_of(Utt,_,_),
						    equil(_,_),
						    main_verb(Utt,_)],
						   Asserts),[Utt])))))),
conclusion(call(ac_find_command(Utt), Asserts,Utt))).


fif(done(ac_find_command(Utt),_,Utt),
conclusion(satisfiedallneeds(Utt))).


fif(failed(ac_find_command(Utt),_,Utt),
conclusion(call(ac_report_fail(Utt,[find_command]),[], Utt))).


/* Now, get the user intention using the translator and dd*/

fif(and(satisfiedallneeds(Utt),
        and(eval_bound(\+ pos_int_u(intention(Utt, _,_)), [Utt]),
	    and(domain_command(Utt,Verb,Command),
		and(eval_bound(\+ pos_int_u(doing(ac_think(Utt,_),_, Utt)), [Utt]),
        	    eval_bound(mult_gather_all([isa(_,_),
						domain_list(_),
						structure(Command,_,_,_),
						link(Utt,_,_,_), 
						value_of(Utt,_,_),
						verb(Utt,_)], 
				Asserts),[Utt,Command]))))),
conclusion(call(ac_find_intention(Utt,domain,Command),Asserts,Utt))).

fif(and(satisfiedallneeds(Utt),
        and(eval_bound(\+ pos_int_u(intention(Utt, _,_)), [Utt]),
	    and(alfred_command(Utt,Verb,Command),
		and(eval_bound(\+ pos_int_u(doing(ac_think(Utt,_),_, Utt)), [Utt]),
        	    eval_bound(mult_gather_all([isa(_,_),
						structure(Command,_,_,_),
						link(Utt,_,_,_),
						value_of(Utt,_,_),
						verb(Utt,_)], 
				Asserts),[Utt, Command]))))),
conclusion(call(ac_find_intention(Utt,alfred,Command),Asserts,Utt))).

fif(and(satisfiedallneeds(Utt),
        and(eval_bound(\+ pos_int_u(intention(Utt, _,_)), [Utt]),
	    and(complex_command(Utt,Verb,Command),
		and(eval_bound(\+ pos_int_u(doing(ac_think(Utt,_),_, Utt)), [Utt]),
        	    eval_bound(mult_gather_all([isa(_,_),
						structure(Command,_,_,_),
						link(Utt,_,_,_), 
						value_of(Utt,_,_)], 
				Asserts),[Utt, Command]))))),
conclusion(call(ac_find_intention(Utt,complex,Command),Asserts,Utt))).


fif(failed(ac_find_intention(Utt,_,_),_,Utt),
conclusion(call(ac_report_fail(Utt,[find_intention]),[], Utt))).

fif(error(Utt, 'Verb_NF_in_DD', [Verb]),
conclusion(need(Utt,[equil, Verb,dcommand]))).

fif(error(Utt, 'Item_NF', [ItemType, Item]),
conclusion(need(Utt,[disambiguate, Item,ItemType]))).

/*missing link - use context to get missing info*/
fif(error(Utt,'LINK_NF', [Link]),
conclusion(need(Utt,[fix_mlink, Link]))).

/*xtra link*/
fif(error(Utt,'EXTRA_LINK', [Var1, Var2, Link]),
conclusion(need(Utt,[fix_xlink, Var1, Var2, Link]))).

fif(and(or(satisfied(Utt, Need),
	   done(ac_think(Utt,_),_,Utt)),
        and(eval_bound(\+ pos_int_u(doing(ac_think(Utt,_),_, Utt)), [Utt]),        
            and(eval_bound(pos_int_u(done(ac_think(Utt,_),_, Utt)), [Utt]),
	        eval_bound(satisfied_needs(Utt), [Utt])))),
conclusion(satisfiedallneeds(Utt))).

fif(and(need(Utt, Need),
	and(satisfiedallneeds(Utt),
            eval_bound(\+ pos_int_u(satisfied(Utt, Need)), [Utt,Need]))),
conclusion(not(satisfiedallneeds(Utt)))).

fif(intention(Utt,Type,List), 
conclusion(belief(Type,List))).

fif(not(intention(Utt, Type, List)),
conclusion(not(belief(Type,List)))).

fif(and(intention(Utt, alfred, [undo]),
	and(utt_list([Utt|[ULast|_]]),
	    and(eval_bound(pos_int_u(intention(ULast, alfred, List)), [ULast]),
		eval_bound(pos_int_u(belief(alfred, List)), [List])))),
conclusion(call(ac_action(Utt,alfred,[undo,List]), [], Utt))).

fif(and(intention(Utt, alfred, [undo]),
	and(utt_list([Utt|[ULast|_]]),
	    and(eval_bound(pos_int_u(intention(ULast, domain, List)), [ULast]),
		and(eval_bound(pos_int_u(belief(domain, List)), [List]),
                    eval_bound(domain_tag(Tag), []))))),
conclusion(call(ac_action(Utt,domain,[Tag, undo,List]), [], Utt))).

fif(and(intention(Utt, alfred, List),
	and(eval_bound(clause(step_number(CurNow),true), []),
	    and(eval_bound(List \== [undo], [List]),
		eval_bound(mult_gather_all([equil(_,_),
					    isa(_,_),
					    structure(_,_,_,_)], Asserts), [])))),
conclusion(call(ac_action(Utt, alfred, List, CurNow),Asserts,Utt))).

fif(and(intention(Utt, domain, List),
        eval_bound(domain_tag(Tag), [])),
conclusion(call(ac_action(Utt, domain, [Tag, List]), [], Utt))).

fif(and(equil(Item1,Item2),
	and(desire(update, I, Item1),
	    eval_bound(mult_gather_all([equil(_,_),
					isa(_,_),
					structure(_,_,_,_)], Asserts), []))),
conclusion(call(ac_action(a, alfred, [update, I, Item1, Item2]), Asserts, a))).

fif(and(equil(Item1,Item2),
	and(desire(update, I, Item2),
	    eval_bound(mult_gather_all([equil(_,_),
					isa(_,_),
					structure(_,_,_,_)], Asserts), []))),
conclusion(call(ac_action(a, alfred, [update, I, Item2, Item1]), Asserts, a))).

fif(and(equil(name,CurrUser),
	and(curr_user(PrevUser),
		eval_bound(switch_user(PrevUser,CurrUser),[PrevUser,CurrUser]))),
conclusion(curr_user(CurrUser))).

fif(and(equil(user,Item2),
	eval_bound(df(equil(user,Item2)), [Item2])),
conclusion(curr_user(Item2))).

fif(and(equil(Item1,user),
	eval_bound(df(equil(Item1,user)), [Item1])),
conclusion(curr_user(Item1))).

fif(and(equil(name,Item2),
	eval_bound(df(equil(name,Item2)), [Item2])),
conclusion(curr_user(Item2))).

fif(failed(ac_action(Utt,_,List),_,Utt),
conclusion(call(ac_report_fail(Utt,[action,List]),[], Utt))).

fif(and(send_to_domain(Utt, Tag, List),
        eval_bound(sending_to_domain(Tag,List),[Tag,List])),
conclusion(sent_to_domain(Utt, Tag, List))).  

fif(and(sent_to_domain(Utt, Tag, List),
	eval_bound(mult_gather_all([result(_,_),
				    isa(_,_),
				    domain_list(_)], Asserts), [])),
conclusion(call(ac_post_process(Utt, List), Asserts, Utt))).

fif(sent_to_domain(Utt, Tag, List),
conclusion(call(ac_report_action(List), [],Utt))).

fif(and(or(or(equil(_, _),isa(_,_)),
	   done(ac_think(U, _), _,U)),
	and(need(U, Need),
	    and(eval_bound(\+ pos_int_u(satisfied(U,Need)), [U,Need]),
                and(eval_bound(mult_gather_all([equil(_,_),
						isa(_,_),
						structure(_,_,_,_),
						value_of(U,_,_),
						verb(U,_),
						val(U,_,_),
						link(U,_,_,_),
						type(U,_,_)], Forms), [U]),
		    and(eval_bound(sort(Forms, Asserts), [Forms]),
			and(eval_bound(\+ thinking(U,Need,Asserts), [U, Need, Asserts]),
			    eval_bound(\+ thought(U,Need,Asserts), [U, Need, Asserts]))))))), 
conclusion(call(ac_think(U,Need), Asserts, U))).
    
fif(failed(ac_think(Utt,Need),_,Utt),
conclusion(call(ac_report_fail(Utt,[think,Need]),[], Utt))).

/* if the need to disambiguate could not be satisfied by merely looking at the KB, create a new need to find an equivalent word 
(possibly by asking the user*/

fif(and(done(ac_think(Utt,Need),_, Utt),
	and(eval_bound((Need = [disambiguate, Item, ItemType]), [Need]),
            eval_bound(\+ pos_int(satisfied(Utt,Need)), [Utt,Need]))),
conclusion(need(Utt,[equil, Item, ItemType]))).

/*don't ask if already asked and expecting an answer*/
fif(and(done(ac_think(Utt,Need),_, Utt),
        and(eval_bound(\+ asking(Utt, Need,[]), [Utt, Need]),
	    and(eval_bound((Need = [equil| _]), [Need]),
                and(eval_bound(\+ pos_int_u(expect(_,Need)), [Need]), 
	            eval_bound(\+ pos_int_u(satisfied(_,Need)), [Need]))))),
conclusion(call(ac_ask(Utt,Need),[], Utt))).

/*it is not the case that the user uttered something after the system last asked*/
fif(and(idling(Step),
	and(eval_bound(idling_for_steps(100),[]),
	    and(expect_list([[Utt, Need]|List]),
		eval_bound(\+ asking(Utt, Need,[]), [Utt, Need])))),
conclusion(call(ac_ask(Utt, Need), [], Utt))).

fif(failed(ac_ask(Utt,Need),_,_),
conclusion(call(ac_report_fail(Utt,[ask,Need]),[], Utt))).

fif(done(ac_ask(Utt, Need),_,_),
conclusion(expect(Utt, Need))).

/*BEGIN**********Maintaining expectation strucure *******************/

fif(and(expect(Utt, Need),
	and(eval_bound(\+ pos_int_u(satisfied(Utt,Need)), [Utt, Need]),
	    and(eval_bound(\+ pos_int_u(update_expect_list(_,_)), []),	
		and(expect_list(List),
	            eval_bound(\+ member([Utt,Need],List), [Utt, Need, List]))))),
conclusion(update_expect_list([List], [[Utt,Need]|List]))).

fif(and(satisfied(Utt, Need),
	and(expect(Utt, Need),
	    and(expect_list(List),
	        and(eval_bound(member([Utt,Need],List), [Utt, Need, List]),
		    eval_bound(delete(List, [Utt, Need], NList), [Utt, Need, List]))))),
conclusion(update_expect_list([List], NList))).

fif(and(expect_list(List1),
	and(expect_list(List2),
	    and(eval_bound(List1 \== List2, [List1, List2]),
		eval_bound(union(List1,List2,List3), [List1,List2])))),
conclusion(update_expect_lists([List1,List2], List3))).

fif(and(update_expect_list(List, NList),
        and(eval_bound(delete_expect_lists(List),[List]),
	    eval_bound(df(update_expect_list(List, NList)), [List, NList]))),
conclusion(expect_list(NList))).


/*END************Maintaining expectation strucure ************************/

/* didnot satisfy the current need  completely, but got an alternative. Also, this alternative was not meant to satisfy another need.*/

fif(and(done(ac_think(U,Need),Asserts,U),
	and(eval_bound((Need = [equil, Word, Type]), [Need]),
            and(eval_bound(\+ pos_int(satisfied(U,Need)), [U,Need]),
		and(equil(Word,Item),
                    and(eval_bound(\+ matchwords(Item,_,_), [Item]),
 		        eval_bound(member(equil(Word,Item), Asserts), [Asserts,Word,Item])))))),
conclusion(need(U,[equil, Item, Type]))).

fif(and(done(ac_think(U,Need),Asserts,U),
	and(eval_bound((Need = [equil, Word, Type]), [Need]),
	    and(eval_bound(\+ pos_int(satisfied(U,Need)), [U,Need]),
		and(equil(Item, Word),
                    and(eval_bound(\+ matchwords(Item,_,_), [Item]),
		        eval_bound(member(equil(Item, Word), Asserts), [Asserts,Word,Item])))))),
conclusion(need(U,[equil, Item, Type]))).

/* Contradiction Handling */
fif(and(contra(F1,F2,T),
        and(eval_bound(name_to_time(F1,T1),[F1]),
            and(eval_bound(name_to_time(F2,T2),[F2]),
                eval_bound((T2 > T1 -> Form=F1; Form=F2), [T1,T2,F1,F2])))),  
conclusion(reinstate(Form))).

