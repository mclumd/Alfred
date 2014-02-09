/* @(#)chat.pl	24.1 02/23/88 */

/* 
	Copyright 1986, Fernando C.N. Pereira and David H.D. Warren,

			   All Rights Reserved
*/

% This file compiles all of Chat-80

:- no_style_check(single_var).
:- no_style_check(discontiguous).

:- ensure_loaded(chatops).

:- ensure_loaded(readin).		% sentence input, ASCII VERSION
:- ensure_loaded(ptree).		% print trees
:- ensure_loaded(xgrun).		% XG runtimes
:- ensure_loaded(newg).			% clone + lex
:- ensure_loaded(clotab).		% attachment tables
:- ensure_loaded(newdic).		% syntactic dictionary
:- ensure_loaded(slots).		% fits arguments into predicates
:- ensure_loaded(scopes).		% quantification and scoping
:- ensure_loaded(templa).		% semantic dictionary
:- ensure_loaded(qplan).		% query planning
:- ensure_loaded(talkr).		% query evaluation
:- ensure_loaded(ndtabl).		% relation info.
:- ensure_loaded(aggreg).		% aggregation operators
:- ensure_loaded(world0).     		% geographic data base
:- ensure_loaded(rivers).
:- ensure_loaded(cities).
:- ensure_loaded(countr).
:- ensure_loaded(contai).
:- ensure_loaded(border).
:- ensure_loaded(chattop).		% top level control


save_chat :-
   save(chat),
   display('Hi, Chat here ...'), ttynl,
   hi.
