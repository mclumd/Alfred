/*
File: ds.pl
By: kpurang
What:  data structures.
Todo: say what some of these are. obscure
*/

% node(nodename, formula, type, assumptions, target, time, priority,
%      parents, children, junk)
% type: bc or fc
% junk: for miscellaneous things that I can't think of now.
% 1st thing is junk is: fif or if or bif bepending on the type of if


:- dynamic node/10.
:- dynamic new_node/10.

% func_node(functor, [set], [set])
% a mapping from functor names to sets of nodenames for the nodes that
% contain these functors. one set of positive literals, one for negative.
:- dynamic func_node/3.
:- dynamic func_new_node/3.

% node_index(H, L1, L2)
% H is a hash value
% L1 is a list of nodes where the term correspomding to H occurs +vely
% L2 is a list of nodes where the term correspomding to H occurs -vely
% one of the hashvalues will be the predname itself fro the case that 
% the arg is a var
:- dynamic node_index/3.
:- dynamic new_node_index/3.

% pred2hash(P, H)
% P is a predicate name
% H is a list of hash values as above that P occurs in
:- dynamic pred2hash/2.
:- dynamic newpred2hash/2.

% REMEMBER TO INITIALIZE THESE IN TOPLEVEL!!!

% conn_node(connective, [set of nodenames])
% a mapping from the main connective of a formula to the formula (except if
% the main connective is not
:- dynamic conn_node/2.

% agenda is a list of [task, priority]
% task is [rulename, formula] where formula is a formula on which the rule
% is to be applied.
:- dynamic agenda/1.

:- dynamic node_count/1.
:- dynamic new_node_count/1.
:- dynamic step_number/1.

% history is a relation step_number X new_nodes at that step
:- dynamic history/2.

% step_time is the (real) time allocated to a step
:- dynamic agenda_time/1.

% step_number is the number of tasks to do in one step.
:- dynamic agenda_number/1.

% fc_rules is the list of rules to be used for fc
:- dynamic fc_rules/1.

% bc_rules is the list of rules to be used for bc
:- dynamic bc_rules/1.

% set of trees to delete
:- dynamic tree_to_delete/1.

:- dynamic statistics/1.

:- dynamic verbose/1.

:- dynamic number_of_nodes/1.

:- dynamic show_step/1.

:- dynamic cpu_time/1.

:- dynamic done_new/1.

:- dynamic delete_trees/1.

:- dynamic draw_graph/1.

:- dynamic g_del_node/1.

:- dynamic g_add_node/5.

:- dynamic do_tasks_time/2.

:- dynamic slave_tag/1.

:- dynamic action_list/1.

:- dynamic failed_call/1.

:- dynamic delay/1.

:- dynamic keyboard/1.

:- dynamic run/1.

:- dynamic history_stream/1.

:- dynamic history_dump/1.

:- dynamic deleted_forms/1.

:- dynamic debug_level/1.

:- dynamic debug_stream/1.

:- dynamic timelimit/1.

:- dynamic memlimit/1.

:- dynamic almagenda/1.

:- dynamic al_files_to_load/1.

:- dynamic contra_distrust_descendants/1.

:- dynamic abort_it/1.

:- dynamic pending_contra/4.

:- dynamic alma_prompt/1.

:- dynamic hist_add/2.

:- dynamic hist_del/2.

:- dynamic to_add_to_hist/1.

:- dynamic distrusted_forms/1.

% args: functor name, arity, name of formula, name of forall
:- dynamic functionalist/4.			  % is not a list.


