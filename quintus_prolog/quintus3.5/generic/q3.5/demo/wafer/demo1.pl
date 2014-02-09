
/* @(#)demo1.pl	28.1 09/05/90 */

/* 						
 	;							 ;
 	;--------------------------------------------------------;
 	;							 ;
 	;  Copyright (C) 1985,  Quintus Computer Systems, Inc.   ;
 	;  All rights reserved.					 ;
 	;							 ;
 	;--------------------------------------------------------;
        ;				Author:  Vincent Pecora	 ;
 
  ---------------------------------------------------------------------------

   ----------------------------------------------------------------------


		   Integrated Circuit Wafer Sorting Program --
		     A Prolog Expert System Demonstration


Introduction:

	In today's marketplace, the words "expert system" have taken on

an almost magical connotation, and seem to be invoked everywhere.  The

purpose of the wafer sorting program is to demystify through example 

some of the central concepts involved in the building of expert systems.

This note contains the source code for the wafer sorting program, as well

as inline comments which describe each major functional block of the 

code.  Before examining the code, a few words about why the features of 

Quintus Prolog are particularly relevant for the building of expert

system software are in order.


   ----------------------------------------------------------------------

Background:

	Even using the simplest definition of an expert system as "any

program which can produce expert level problem solving behavior", it 

is clear expert system software will generally be more complex than

other software.  If the problem to be solved were not more complex than

average, there would be no need for an expert in the field to solve it.  

In addition, because experts by definition are few in number, their time 

is valuable, and the process of producing an expert system using input 

from an expert must proceed as quickly as possible.  This is complicated 

by the fact that the method of solution will typically not be understood 

well enough to be written up as a formal program specification.  Once again,

if the problem lent itself to such a well understood solution method, an 

expert would probably not be needed to solve it.



	The current popularity of rule-based expert systems arises from

their success at solving complex problems in small, understandable units

of IF-THEN rules.  By incrementally building up the set of rules in close

consultation with the expert, a programmer can create very complex software

in small, easily inspectable steps.  As the time of the expert involved is

expensive, there is a great economic incentive to complete the software

building, and to field the system as quickly as possible.  



	It is precisely for these reasons that the selection of Prolog for 

the building of expert system software makes so much sense.  Prolog is 

a very high level language (a so-called 5th generation language) whose

basic constructs are rules and facts.  The rules of Prolog provide a very good 

fit for producing rule based software.  The Prolog fact database can be used 

to store the background facts that are needed for the solution of many 

complex problems.  Quintus Prolog in particular, also provides the ability

to call other programming languages, so that specialized software that 

has already been developed for the particular problem (a large specialized

database program and an already developed problem-specific database for 

example) can be utilized basically as is, without reprogramming.  



	In addition, Quintus Prolog provides a very powerful 

programming environment which is designed to aid the software developer to 

produce software that is easily inspectable and can rapidly be built up 

incrementally as consultation with the expert proceeds.  Quintus Prolog 

features such as the editor interface, the find-definition facility, the 

interactive debugger, the on-line help system, and the style checker all add 

up to powerful support for the rapid construction of complex software.  In 

addition, the Quintus Run Time System package enables the completed software 

to be fielded efficiently and economically.  



	The above observations are merely the tip of the legendary iceberg.

In order to keep this note reasonably short, the above has stressed the 

suitability of Prolog for rule based systems, as the wafer sorting program

is an example of this type of approach.   Keep in mind however that Prolog

is a sufficiently general tool that other software architectures (such

as frames, for example) could also be used.   The special features of 

Quintus Prolog which support expert system construction were only mentioned,

and cannot be done justice in a short note of this type.  For further 

information, contact Quintus.


   ----------------------------------------------------------------------

Source Code and Comments:


	The wafer sorting demonstration below is a very simple example

of the techniques that could be used to build up an expert system directly

in Prolog code.  The example sorts integrated circuit wafers into different

quality control bins by asking the user a series of questions about the

condition of each wafer.  The rules have purposely been kept very simple

so as not to mask the underlying structure of the system.


	The program below has been divided into functional blocks of code.

Each block is preceeded by comments that provide a brief description of

what it does.

*/
% ----------------------------------------------------------------------
%			Initial Control Code
% ----------------------------------------------------------------------
% COMMENTS:
% The code below runs the rules for each wafer, until the user answers
%  "done" to the request for the id of the next wafer to be processed.
%
% Note that get_next_wafer will return a null list ([]) when the session
%  is over, and the repeat loop will then be broken.
%
% The mechanism in "process_answer" which handles user provided wafer ids,
%  also allows for the user to ask for a description using "describe",
%  or to ask for a summary list of the session to be produced.
% ----------------------------------------------------------------------
% CODE:

run :-
   repeat,
      get_next_wafer(Id),
      process_wafer(Id),
      Id = [],			% a null Id will end the session.
   !.			

get_next_wafer(Id) :-
   write('Enter the id of the wafer to be processed: '),
   read(Ans), 			% Remember that 'read' needs an ending '.'
   process_answer(Ans,Id).

process_answer(Answer,[]) :- 
   member(Answer,[none,done,end_of_file]), !.
process_answer(describe(X),_Id) :- 
   print_description(X), !,
   fail.
process_answer(summary,_Id) :-
   produce_summary_list, !,
   fail.
process_answer(Answer,[Answer]).
				
process_wafer([]) :-		% No more wafers to be processed.
   nl,nl,write('done!'),nl.
process_wafer([Wafer_id]) :-
   save_current_wafer(Wafer_id),		   % this first rule is called 
   quality_control_bin(Wafer_id,Answer,[]),!,      % with a NULL calling list.
   write_list([nl,'wafer ', Wafer_id, ' has been sorted as ',Answer,
   		'.',nl,nl]).

save_current_wafer(Wafer) :-
   abolish(current_wafer,1),
   asserta(current_wafer(Wafer)),
   (retract(wafer_list(List)), !; List = [], !),
   add_if_not_member(Wafer,List).

add_if_not_member(Wafer,List) :- 
   member(Wafer,List),!,
   asserta(wafer_list(List)).
add_if_not_member(Wafer,List) :-
   append([Wafer],List,List1),  % see the General Utilities section for
   asserta(wafer_list(List1)).  %  the definition of append/3


% ----------------------------------------------------------------------
%			Rules
% ----------------------------------------------------------------------
% COMMENTS:
% The top level rule (quality_control_bin) is called from "process_wafer" 
%  in the Initial Control Code section.  The first argument of the rule is 
%  the current object that the rule is being applied to, in this case it is
%  the user supplied wafer id.  The second argument is the value of the
%  quality control bin that the wafer will be sorted into.  Note that each
%  rule can be thought of as representing Attribute-Object-Value information.
%  The rule predicate name is the Attribute information in this example.
%  The third argument in each rule is a list of rules that have been 
%  previously called.  This provides the tracing information that is so 
%  valuable for debugging the logic of the system as it is being built.  The
%  "why" command as handled by "process_user_reply" unwinds this list, so
%  that sequential "why" commands will trace back through the entire rule
%  hierarchy structure which was called in order to ask the current question.
%
% Wafers can be sorted into one of 4 quality control bins, "acceptable",
%  "rejected", "recleanable" or "needs_supervisor_assistance".  This is 
%  reflected in the 4 entries for the "quality_control_bin" rule.
%
% The predicate "save_aov" stores the Attribute-Object-Value data
%  in the Prolog database so that the user does not need to answer
%  multiple choice questions more than once.
% ----------------------------------------------------------------------
% CODE:

quality_control_bin(Wafer,acceptable,Calling_list) :-
   condition_perfect(true,[quality_control_bin|Calling_list]),
   save_aov(quality_control_bin,Wafer,acceptable).
quality_control_bin(Wafer,rejected,Calling_list) :-
   reject_feature(Wafer,_Value,[quality_control_bin|Calling_list]),
   save_aov(quality_control_bin,Wafer,rejected).
quality_control_bin(Wafer,recleanable,Calling_list) :-		
   recleanable_feature(Wafer,_Value,[quality_control_bin|Calling_list]),
   save_aov(quality_control_bin,Wafer,recleanable).
quality_control_bin(Wafer,needs_supervisor_assistance,_) :-   % default bin
   save_aov(quality_control_bin,Wafer,needs_supervisor_assistance).    

reject_feature(Wafer,physical_defect,Calling_list) :-
   physical_defect(Wafer,_Value,[reject_feature|Calling_list]),
   save_aov(reject_feature,Wafer,physical_defect).
reject_feature(Wafer,serious_surface_dirt,Calling_list) :-
   serious_surface_dirt(Wafer,_Value,[reject_feature|Calling_list]),
   save_aov(reject_feature,Wafer,serious_surface_dirt).

recleanable_feature(Wafer,dirt_on_surface,Calling_list) :-
   dirt_on_surface(light,[recleanable_feature|Calling_list]),
   save_aov(recleanable_feature,Wafer,dirt_on_surface).
recleanable_feature(Wafer,smudges_on_surface,Calling_list) :-
   smudges_on_surface(true,[recleanable_feature|Calling_list]),
   save_aov(recleanable_feature,Wafer,smudges_on_surface).
recleanable_feature(Wafer,fingerprints_on_surface,Calling_list) :-
   fingerprints_on_surface(true,[recleanable_feature|Calling_list]),
   save_aov(recleanable_feature,Wafer,fingerprints_on_surface).
recleanable_feature(Wafer,light_haze_on_surface,Calling_list) :-
   light_haze_on_surface(true,[recleanable_feature|Calling_list]),
   save_aov(recleanable_feature,Wafer,light_haze_on_surface).

physical_defect(Wafer,cut_off,Calling_list) :-
   cut_off(true,[physical_defect|Calling_list]),
   save_aov(physical_defect,Wafer,cut_off).
physical_defect(Wafer,chipped,Calling_list) :-
   chipped(true,[physical_defect|Calling_list]),
   save_aov(physical_defect,Wafer,chipped).

serious_surface_dirt(Wafer,orange_peel,Calling_list) :-
   orange_peel(true,[serious_surface_dirt|Calling_list]),
   save_aov(serious_surface_dirt,Wafer,orange_peel).
serious_surface_dirt(Wafer,massive_dirt,Calling_list) :-
   dirt_on_surface(heavy,[serious_surface_dirt|Calling_list]),
   save_aov(serious_surface_dirt,Wafer,dirt_on_surface).


% ----------------------------------------------------------------------
%			User Askable Items
% ----------------------------------------------------------------------
% COMMENTS:
% Rules which do not call other rules, simply ask the user for information.
% Note that the "Answer" variable is instantuated by the calling rule.
% ----------------------------------------------------------------------
% CODE:

condition_perfect(Answer,Calling_list) :-
   ask_user(condition_perfect,Answer,Calling_list).

dirt_on_surface(Answer,Calling_list) :-
   ask_user(dirt_on_surface,Answer,Calling_list).

smudges_on_surface(Answer,Calling_list) :-
   ask_user(smudges_on_surface,Answer,Calling_list).

fingerprints_on_surface(Answer,Calling_list) :-
   ask_user(fingerprints_on_surface,Answer,Calling_list).

light_haze_on_surface(Answer,Calling_list) :-
   ask_user(light_haze_on_surface,Answer,Calling_list).

cut_off(Answer,Calling_list) :-
   ask_user(cut_off,Answer,Calling_list).

chipped(Answer,Calling_list) :-
   ask_user(chipped,Answer,Calling_list).

orange_peel(Answer,Calling_list) :-
   ask_user(orange_peel,Answer,Calling_list).


% ----------------------------------------------------------------------
%			Supporting Code for Running the Rules
% ----------------------------------------------------------------------
% COMMENTS:
% "save_aov" stores the Attribute-Object-Value data in the form:
%  value(Attribute,Object,Value).  This way, all attributes can be obtained 
%  for any object using "bagof" or "setof".  Note that value/3 is declared
%  dynamic, as it will be modified as the program is running.
%
% "ask_user" is used in order to obtain information from the user.  Before
%  actually asking the user, the data base is first checked in case the
%  user has already answered the question previously while testing another
%  rule.
%
% "process_user_reply" is called by "ask_user" and will handle "yes"("y") 
%  or "no"("n") answers as well as "why", "describe", or any valid answer 
%  to a multiple choice question, otherwise it repeats the question. 
%  Note that "process_user_reply" does a recursive call to "ask_user" in
%  responding to a "why" answer.  This recursive call uses the tail of 
%  the calling rule list, thus unwinding it with subsequent user responses
%  of "why".
% ----------------------------------------------------------------------
% CODE:

:- dynamic value/3.

save_aov(Attribute,Object,Value) :-   % Just in case there is a previously
   retract(value(Attribute,Object,Value)),     % stored value.
   fail.
save_aov(Attribute,Object,Value) :-
   asserta(value(Attribute,Object,Value)).

ask_user(Rule,Answer,_Calling_list) :-  % Check the data base first.
   current_wafer(Wafer),
   value(Rule,Wafer,Value),!,
   Value = Answer.
ask_user(Rule,Answer,Calling_list) :-   % Ask the user.
   question_list(Rule,Question),	% See Question Text section below.
   ask_question(Question,Raw_answer),!, 
   process_user_reply(Raw_answer,Rule,Answer,Calling_list).

ask_question(Question_list,Answer) :-
   write_list(Question_list),		% See General Utilities below.
   read(Answer).

:- op(100,fx,describe).  % This statement will allow the use of "describe xxx"
%  instead of "describe(xxx)" in responding to "ask_question" above.

process_user_reply(Raw_answer,Rule,true,_) :-   % a true answer was wanted.
   member(Raw_answer,[y,yes]),
   current_wafer(Wafer),
   save_aov(Rule,Wafer,true).
process_user_reply(Raw_answer,Rule,true,_) :-   % Note the cut - if the user 
   member(Raw_answer,[n,no]),			% says no, this fails the
   current_wafer(Wafer),			% proposition.
   save_aov(Rule,Wafer,false),!,fail.  	
process_user_reply(Raw_answer,Rule,false,_) :-  % a false answer was wanted.
   member(Raw_answer,[n,no]),
   current_wafer(Wafer),
   save_aov(Rule,Wafer,false).
process_user_reply(Raw_answer,Rule,false,_) :-  % Note the cut - if the user 
   member(Raw_answer,[y,yes]),			% says yes, this fails the
   current_wafer(Wafer),			% proposition.
   save_aov(Rule,Wafer,true),!,fail. 
%
process_user_reply(why,Rule,Answer,[Calling_rule|Rest]) :-
   rule_number(Calling_rule,Number),	     % See Rule Numbers below.
   write_list([nl,'your response to this question is needed ',
   	       'to answer',nl,'rule number ', Number, ':',nl]),
   print_rule(Calling_rule),		     % See More Supporting Code below
   nl,nl,!,
   ask_user(Rule,Answer,Rest).
process_user_reply(why,Rule,Answer,[]) :-
   write_list(['you have traced to the top of the rule hierarchy.',nl,nl]),!,
   ask_user(Rule,Answer,[]).
%
process_user_reply(describe(X),Rule,Answer,Calling_list) :-
   print_description(X),!,
   ask_user(Rule,Answer,Calling_list).
%
process_user_reply(summary,Rule,Answer,Calling_list) :-
   nl,nl,
   write('Please ask for a summary when next prompted for a wafer id.'),
   nl,nl,
   ask_user(Rule,Answer,Calling_list).
%
process_user_reply(Raw_answer,Rule,Answer,_) :-
   multiple_valued_answers(Rule,Potential_answers), % See Multiple Choice
   member(Raw_answer,Potential_answers),	    %  Valid Answers Section
   current_wafer(Wafer),			    %  below.
   save_aov(Rule,Wafer,Raw_answer),!,
   Answer = Raw_answer.
%
process_user_reply(_,Rule,Answer,Calling_list) :-
   write_list([nl,'I do not understand your response.',nl]),!,
   ask_user(Rule,Answer,Calling_list).


% ----------------------------------------------------------------------
%			Question Text
% ----------------------------------------------------------------------
% COMMENTS:
% Here is the question text that is used by "ask_user".  The text is part of 
%  a list because write_list will be used to display the text.  This is a 
%  very general mechanism (whose full usefulness is not needed in this 
%  simple example) that is capable of including instantiated variables as part
%  of the question list.
% ----------------------------------------------------------------------
% CODE:

question_list(condition_perfect,
   ['Is this wafer in perfect condition ? ']).
question_list(dirt_on_surface,
   ['How much surface dirt* is there on this wafer ',
    '(none, light, or heavy)? ']).
question_list(smudges_on_surface,
   ['Are there any smudges on the surface of the wafer ? ']).
question_list(fingerprints_on_surface,
   ['Are there any fingerprints on the wafer ? ']).
question_list(light_haze_on_surface,
   ['Is there a light haze on the surface of the wafer ? ']).
question_list(cut_off,
   ['Is there a cutoff* greater than 1/4 inch on the chip ? ']).
question_list(chipped,
   ['Are there any chips* on the wafer ? ']).
question_list(orange_peel,
   ['Is there an orange_peel* condition on the surface of the wafer ? ']).


% ----------------------------------------------------------------------
%			     Rule Numbers
% ----------------------------------------------------------------------
% COMMENTS:
%  "process_user_reply" refers to rules by a rule number.  The association
%  of the rule number to the rule predicate name is done below.
% ----------------------------------------------------------------------
% CODE:

rule_number(quality_control_bin,1).
rule_number(reject_feature,2).
rule_number(recleanable_feature,3).
rule_number(physical_defect,4).
rule_number(serious_surface_dirt,5).


% ----------------------------------------------------------------------
%			Multiple Choice Valid Answers
% ----------------------------------------------------------------------
% COMMENTS:
% This entry is needed by "process_user_reply" to support multiple choice 
%  type questions.  In general, there should be one entry per multiple
%  choice type rule.
% ----------------------------------------------------------------------
% CODE:

multiple_valued_answers(dirt_on_surface,[none,light,heavy]).


% ----------------------------------------------------------------------
%			More Supporting Code
% ----------------------------------------------------------------------
% COMMENTS:
% "rule(xxx)." will now print out any rule by number at the top level.
% "describe xxx" will now print out a description of any term xxx that
%  there is a dictionary entry for, using "print_description".  This 
%  will work even if it is not a response to a question.
% "print_description" prints the description of valid wafers (by id), as well
%   as the description of terms.
% "print_wafer_features" uses "bagof" to pick up all of the various 
%  attributes that apply to the object wafer, which is simply refered to by 
%  the wafer id.
% "summary" will summarize all of the wafers sorted in this session.  It is
%  called by answering "summary" to the request for a new wafer id, or by
%  giving the command "summary" at the top level prompt.
% ----------------------------------------------------------------------
% CODE:

rule(Number) :-
   rule_number(Rule,Number),
   print_rule(Rule).

print_rule(Rule) :-
   rule_description(Rule,Description_list),
   write_list(Description_list).

describe(X) :- print_description(X).   

print_description(X) :-
   wafer_list(Wafer_list),
   member(X,Wafer_list), !,
   print_wafer_features(X),nl,nl. 
print_description(X) :-
   dictionary_description(X,Description_list), !, nl,
   write_list(Description_list),nl,nl.
print_description(X) :-
   write_list([nl,'There is no dictionary entry for ',X,
   	       ' - ask your supervisor.',nl,nl]).

print_wafer_features(Wafer) :-
   bagof((Attribute,Value),value(Attribute,Wafer,Value),Bag),
   print_wafer_description(Wafer,Bag).
print_wafer_features(_).	% true even for invalid wafer ids.

print_wafer_description(Wafer,List) :-
   nl, write('Wafer: '), write(Wafer),nl,nl,
   print_description_list(List).

print_description_list([]).
print_description_list([(_,true)|Rest]) :- !,  % trivally true information
   print_description_list(Rest).
print_description_list([(Attribute,Value)|Rest]) :-
   format('~t~5|~a: ~t~30|~a~n',[Attribute,Value]),
   print_description_list(Rest).

summary :- produce_summary_list.

produce_summary_list :-
   format('~2n',[]),
   format('~`-t~62|~nSession Summary:~n',[]),
   wafer_list(List),
   describe_list(List).

describe_list([]) :-
   format('~`-t~62|~n',[]).
describe_list([X|L]) :-
   print_description(X),
   describe_list(L).


% ----------------------------------------------------------------------
%			Rule Description Text
% ----------------------------------------------------------------------
% COMMENTS:
% In order to describe what a rule is doing in simple English (which is 
%  needed when the user asks "why" to a question) a rule description is
%  added to the Prolog database.
% ----------------------------------------------------------------------
% CODE:

rule_description(quality_control_bin,
   ['a wafer can be sorted into one of the following quality control bins: ',
    nl,'acceptable, ','recleanable, rejected or ',
    'needs_supervisor_assistance.',nl]).
rule_description(reject_feature,
   ['a wafer is classified as rejected if it has a physical defect or',
    nl,'serious surface dirt.',nl]).
rule_description(recleanable_feature,
   ['a wafer is classified as recleanable if it has smudges, fingerprints,',
    nl,'a light haze, or a light amount of dirt on its surface.',nl]).
rule_description(physical_defect,
   ['a wafer has a physical defect if it has an excessive cutoff or',
    nl,'is chipped']).
rule_description(serious_surface_dirt,
   ['a wafer has serious surface dirt if it has an orange-peel texture or',
    nl,'has heavy surface dirt']).


% ----------------------------------------------------------------------
%			Dictionary Text
% ----------------------------------------------------------------------
% COMMENTS:
% "dictionary_description" is used by "print_description" to describe 
%  terms that are mentioned in the rules that the user might not know
%  about.  Expanding this dictionary to include other terms would be 
%  as simple as adding additional clauses.
% ----------------------------------------------------------------------
% CODE:

dictionary_description(cutoff,
   ['a cutoff is a straight break somewhere along the edge of the wafer.']).
dictionary_description(chip,
   ['a chip will appear as a small irregular break ',
    'in the edge of the wafer.']).
dictionary_description(chips,Ans) :- dictionary_description(chip,Ans).
dictionary_description(dirt,
   ['the term "dirt", as used for classifying wafers, refers to small ',nl,
    'foreign particles on the surface of the wafer.  A small amount of dirt ',
    nl,'can usually be blown off by the inspector.  A massive amount of ',
    nl,'dirt is not so easily removed.']).
dictionary_description(orange_peel,
   ['the surface of a wafer has orange_peel if it has a crinkly texture,',nl,
    'much like the surface of an orange.']).


% ----------------------------------------------------------------------
%			General Utilities
% ----------------------------------------------------------------------
% COMMENTS:
% These are the very low level utilities used throughout the code.
% ----------------------------------------------------------------------
% CODE:

:- ensure_loaded(library(basics)).

write_list([]).
write_list([nl|L]) :- !,
   nl,
   write_list(L).
write_list([tab(N)|L]) :- !,
   tab(N),
   write_list(L).
write_list([X|L]) :-
   write(X),!,
   write_list(L).
