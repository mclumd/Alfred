/*
File: res/res.pl
By: kpurang
What: main file for resolution

*/

% formulas are converted to cnf
% node formulas are lists of literals

:- dynamic skolem_count/1.
:- dynamic var_count/1.
%:- ensure_loaded(library(basics)).
:- ensure_loaded(library(ordsets)).
%:- ensure_loaded(library(strings)).
:- compile([process_lits, misc, eval, production, process_tasks, fcres, bcres, resolve]).

res_init:-
    retractall(skolem_count(_)),
    retractall(var_count(_)),
    assert(skolem_count(0)),
    assert(var_count(0)).


% **********************************************************************
% **********************************************************************
% **********************************************************************








