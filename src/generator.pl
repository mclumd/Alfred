ask([equil, Word, Type]) :-
    format('~NI do not know the ~p ~p. Which ~p is ~p? ~N', [Type, Word, Type, Word]).

ask([help]) :-
    format('~N I do not understand you. Please rephrase ~N',[]).

prompt(Step) :-
    format('~N Please tell me what you want me to do now: ~d ~N',[Step]).

report_observation(O, R) :-
    format('~N The ~p is ~p. ~N', [O, R]).

report_action(List) :-
    format('~N Ok. Command ~p issued to domain ~N', [List]).


report_fail([parse_phrase]) :-
	format('~N The link parser could not parse your utterance correctly. Could you please rephrase? ~N',[]).

report_fail([fix_linkage]) :-
	format('~N The link parser could not parse your utterance completely and I could not parse it either. Could 
you please rephrase? ~N',[]).

report_fail([main_verb]) :-
	format('~N Hmmmm..I did not understand what you said. Could you please rephrase? ~N',[]).

report_fail([find_command]) :-
	format('~N Hmmmm..I did not understand what you want me to do or believe. Could you please rephrase? ~N',[]).

report_fail([find_intention]) :-
	format('~N I am not able to understand what you meant. Could you please rephrase? ~N',[]).

report_fail([action,List]) :-
	format('~N Sorry, I am not able to do ~p right now. You can probably try later. ~N',[List]).

report_fail([link, _]) :-
    	format('~N Sorry that is beyond my grasp. Could you please rephrase? ~N',[]).

report_fail([think,List]) :-
	format('~N Sorry, I am not able to think about ~p right now. You can probably try later. ~N',[List]).

report_fail([ask,List]) :-
	format('~N Sorry, I was not able to ask about ~p. ~N',[List]).
