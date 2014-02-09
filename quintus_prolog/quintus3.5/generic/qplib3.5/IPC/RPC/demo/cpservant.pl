%   SCCS   : @(#)cpservant.pl	24.2 4/14/88
%   Author : David S. Warren
%   Purpose: Demonstration of Prolog called from C using IPC library.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- ensure_loaded(library(ccallqp)).

external(addints,	xdr,
	addints(+integer,+integer,-integer)).
external(table,		xdr,
	 table(-integer,-string,-float,-atom)).
external(table1,	xdr,
	table1(-string,-integer)).
external(dupl,		xdr,
	 dupl(-integer,-string,-float,-atom,+integer,+string,+float,+atom)).
external(dupldupl,	xdr,
	 dupldupl(-integer,+integer,-string,+string,-float,+float,-atom,+atom)).

external(true,		xdr,
	 true).
external(false,		xdr,
	 fail).
external(settrace,	xdr,
	 settrace(+string)).
external(gettrace,	xdr,
	 gettrace(-string)).


addints(X, Y, Res) :-
	Res is X+Y.

table(5, abcd, 7.44, efgh).
table(6, abce, 7.45, efgi).
table(7, abcf, 7.46, efgj).
table(8, abcg, 7.47, efgk).

dupl(A, B, C, D, A, B, C, D).

dupldupl(A, A, B, B, C, C, D, D).


settrace(X) :-
	msg_trace(_, X).

gettrace(X) :-
	msg_trace(X, X).

table1(abc, 0).
table1(def, 1).
table1(ghi, 2).
table1(jkl, 3).
table1(mno, 4).
table1(pqr, 5).
table1(stu, 6).
table1(vwx, 7).


go :-
	save_ipc_servant(cpservant),
	halt.

