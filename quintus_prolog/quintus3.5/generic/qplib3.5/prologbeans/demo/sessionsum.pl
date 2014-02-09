%%% Copyright (c) 2003 SICS AB. All rights reserved.
%%% -----------------------------------------------------------------
%%%
%%% Sessionsum
%%%
%%% Author  : Joakim Eriksson, Niclas Finne, Sverker Janson
%%% Created : 03-5-22
%%% Updated : $Date: 2004/01/13 14:02:18 $
%%%	      $Revision: 1.3 $
%%% Purpose : Example configuration file for the prolog server
%%%
%%% Shows how to use sessions from application servers (servlet sessions)
%%% See also sessionsum.jsp for the jsp file.
%%%

:- module(sessionsum,[main/0,sum/5]).
:- use_module(library(prologbeans)).
%:- use_module(library(charsio),[read_from_chars/2]).

%% Register the acceptable querys (session based)
main:-
    register_query(sum(C,Sum,Average,Count),
		   sum(C,Session,Sum,Average,Count),
		   Session),
    start.

%% The sum predicate which gets the information from a session database,
%% makes some updates and then stores it back in to the session store
%% (and returns the information back to the application server)
sum(ExprChars, Session, Sum, Average, Count) :-
    session_get(Session, sum, 0, OldSum),
    session_get(Session, count, 0, OldCount),
%    read_from_chars(ExprChars, Expr),
    prologbeans:pb_read_term_from_chars(ExprChars, Expr, []),
    Val is Expr,
    Sum is OldSum + Val,
    Count is OldCount + 1,
    Average is Sum / Count,
    session_put(Session, sum, Sum),
    session_put(Session, count, Count).
