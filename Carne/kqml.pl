/* KQML module for converting kqml-compliant message strings into sets of assertions
by Carl Andersen, 10/1998

UNDEFINED:
qcon: Undefined: kqml:get_pars_and_exprs/2
qcon: Undefined: kqml:domain_pred2/1
qcon: Undefined: kqml:domain_pred1/1
qcon: Undefined: kqml:comma/2
 
  change af to user:af

*/

:- ensure_loaded(library(ctypes)).
:- ensure_loaded( library(lineio)).
:- ensure_loaded( library(lists)).
:- ensure_loaded( library(strings)).
:- ensure_loaded(library(caseconv)).
:- dynamic kqml_kv/2,kqml_head/2,kqml_head2/2,kqml_expr/2,kqml_fquote/2,kqml_bquote/2,
    kqml_commaexpr/2,last_perf/1, remove_leading_colon/0,use_kvs/0, domain_pred2/1, 
    domain_pred1/1,gather_asserts/0,gather_asserts/2.
:- assert(gather_asserts).

%if asserted, system removes all leading colons from words
%:- oassert(remove_leading_colon).
%if asserted, system uses kqml_kv/head preds during unparse_kqml_perf
%:- oassert(use_kvs).

/*
test :-
kqml_retract,
get_a_line(user_input,[],In),
expr(ID,In,Return,Out),
print_exprs(Return,Exprs).

test1 :-
kqml_retract,
get_a_line(user_input,[],Out),
parse_kqml_perf(Out,ID),
get_pars_and_exprs(ID,Exprs),
print_exprs(ID,Exprs).

test2 :-
kqml_retract,
get_a_line(user_input,[],Out),
parse_kqml_perf(Out,ID),
get_expr1s(ID,Exprs),
print(Exprs).

test3 :-
kqml_retract,
oassert(domain_pred1('sa-request')),
oassert(domain_pred1('ask-one')),
oassert(domain_pred1(tell)),
oassert(domain_pred2(':description')),
oassert(domain_pred2(':path')),
oassert(domain_pred2(':prop')),
get_a_line(user_input,[],Out),
parse_kqml_perf(Out,ID),
convert_keyvals1(ID),
convert_keyvals2(ID),
get_expr1s(ID,Exprs),
print(Exprs).
*/

%**********************
/*
converting to keyword-value expr assertions
this code takes in a set of expr(ID,[Word,Key1,Val1,Key2,Val2,....]) assertions
and, for those for which domain_pred1(Word),
retracts the original assertion and replaces it with:
expr(ID,[Word,SubExpr1,SubExpr2,SubExpr3,...])
expr(SubExpr1,Key1,Val1)
expr(SubExpr2,Key2,Val2)
.....
*/
convert_keyvals1(ID) :-
    get_exprs(ID,Exprs),
    convert_keyvals1_1(Exprs).

convert_keyvals1_1([[ID,[Pred|Rest]]|Exprs]) :-
    domain_pred1(Pred),
    convert_keyvals1_2(ID,Pred,Rest,NewExprs),
    convert_keyvals1_1(Exprs).

convert_keyvals1_1([Expr|Exprs]) :-
    convert_keyvals1_1(Exprs).
convert_keyvals1_1([]).

convert_keyvals1_2(ID,Pred,KeyVals,Pars) :-
    oassert(kqml_head(ID,Pred)),
    convert_keyvals1_3(ID,Pred,KeyVals,Pars).

convert_keyvals1_3(ID,Pred,[Key,Val|Rest],Pars) :-
    oassert(kqml_kv(ID,[Key,Val])),
    Par = [Pred,Key,Val],
    convert_keyvals1_3(ID,Pred,Rest,Pars1),
    Pars = [Par|Pars1].
convert_keyvals1_3(_,_,[],[]).

%does same as keyvals1 except looks for pairs inside parens
convert_keyvals2(ID) :-
    get_exprs(ID,Exprs),
    convert_keyvals2_1(Exprs).

convert_keyvals2_1([[ID,[Pred|Rest]]|Exprs]) :-
    domain_pred2(Pred),
    convert_keyvals2_2(ID,Pred,Rest),
    convert_keyvals2_1(Exprs).

convert_keyvals2_1([Expr|Exprs]) :-
    convert_keyvals2_1(Exprs).

convert_keyvals2_1([]).

convert_keyvals2_2(ID,Pred,ExprIDs) :-
    oassert(kqml_head(ID,Pred)),
    convert_keyvals2_3(ID,ExprIDs).

convert_keyvals2_3(ID,[ExprID|Rest]) :-
    kqml_expr(ExprID,[Key,Val]),
    (is_kqml_var(Val) ->
	 convert_keyvals2_3(Val,[Val]);
    true),
    oassert(kqml_kv(ID,[Key,Val])),
    convert_keyvals2_3(ID,Rest).

convert_keyvals2_3(ID,[ExprID|Rest]) :-
    kqml_expr(ExprID,[Key|Vals]),
    convert_keyvals2_4(Vals),
    convert_keyvals2_3(ID,Rest).

/*handles additional non kv-pairs in the expr*/
convert_keyvals2_3(ID,[Head2|Rest]) :-
    ((\+ is_kqml_var(Head2),
      \+ is_var(Head2))->
	 oassert(kqml_head2(ID,Head2));
    true),
    convert_keyvals2_3(ID,Rest).

convert_keyvals2_3(_,[]).


convert_keyvals2_4([Val|Vals]) :-
    (is_kqml_var(Val) ->
	 convert_keyvals2_3(Val,[Val]);
    true),
    convert_keyvals2_4(Vals).

convert_keyvals2_4([]).


is_var(Obj) :-
    atom(Obj),
/*(atom_chars(Obj,[63,118,97,114|Rest]); */
    (atom_chars(Obj,[63,118|Rest]);
    atom_chars(Obj,[118|Rest])),
    number_chars(_,Rest).

/* - darsana commented; don't know whether we are using it..
get_expr1s(ID,Exprs) :-
(bagof([kqml_head,ID1,Pred],kqml_kv(ID1,Pred),Exprs1);
Exprs1 = []),
(bagof([kqml_kv,ID2,Subs],kqml_kv(ID2,Subs),Exprs2);
Exprs2 = []),
(bagof([kqml_expr,ID3,Subs3],kqml_expr(ID3,Subs3),Exprs3);
Exprs3 = []),
append([Exprs1,Exprs2,Exprs3],Exprs).
*/
%**********************
%printing assertions

print_exprs(ID,Exprs) :-
get_exprs(ID,Exprs),
print(Exprs), nl.

get_exprs(ID,Exprs) :-
bagof([ID,Subs],kqml_expr(ID,Subs),Exprs1),
bagof(Subs1,kqml_expr(ID,Subs1),AllSubs),
append(AllSubs,SubList),
get_exprs1(SubList,Exprs2),
append(Exprs1,Exprs2,Exprs).

get_exprs1([Sub|Subs],Exprs) :-
(is_kqml_var(Sub) -> get_exprs(Sub,Exprs1);
Exprs1 = []),
get_exprs1(Subs,Exprs2),
append(Exprs1,Exprs2,Exprs).
get_exprs1([],[]).

is_kqml_var(Atom) :-
atom(Atom),
atom_chars(Atom,[107,113,109,108|Rest]),
number_chars(_,Rest).

%**********************
%parser taking input strings and producing assertions

parse_kqml_perf_asserts(In,ID,Asserts) :-
oassert(gather_asserts),
retractall(gathered_asserts(_)),
assert(gathered_asserts([])),
parse_kqml_perf(In,ID),
gathered_asserts(Asserts).

parse_kqml_perf(In,ID) :-
gensym(kqml,ID),
lparen(In,Out1),
word(Out1,Verb,Out2),
kqml_perf1(ID,Out2,Pars,Out3),
rparen(Out3,[]),
oassert(kqml_expr(ID,[Verb|Pars])),
retractall(last_perf(_)),
oassert(last_perf(ID)).

kqml_perf1(ID,In,Pars,Out) :-
white(In,Out1),
colon(Out1,Out2),
word(Out1,Word1,Out3),
white(Out3,Out4),
expr(ID,Out4,Expr,Out5),
Par = [Word1,Expr],
kqml_perf1(ID,Out5,Pars1,Out),
append([Par,Pars1],Pars).

kqml_perf1(ID,Out5,[],Out5).

expr(ID,In,ID1,Out) :-
lparen(In,Out1),
word(Out1,Word1,Out2),
gensym(kqml,ID1),
expr1(ID1,Out2,SubExs,Out3),
rparen(Out3,Out),
oassert(kqml_expr(ID1,[Word1|SubExs])), !.

%non-kqml-compliant
expr(ID,In,ID1,Out) :-
lparen(In,Out1),
%CFA - removed this because we have non-KQML-compliant inputs
%word(In,Word1,Out1),
gensym(kqml,ID1),
expr(ID1,Out1,Expr1,Out2),
expr1(ID1,Out2,SubExprs1,Out3),
SubExprs = [Expr1|SubExprs1],
rparen(Out3,Out),
oassert(kqml_expr(ID1,SubExprs)),!.

%non-kqml-compliant
expr(ID,In,ID1,Out) :-
lparen(In,Out1),
rparen(Out1,Out),
gensym(kqml,ID1),
oassert(kqml_expr(ID1,[])),!.

expr(ID,In,Expr,Out) :-
word(In,Expr,Out).

expr(ID,In,Expr,Out) :-
quote(ID,In,Expr,Out).

expr(ID,In,Expr,Out) :-
str(In,Expr,Out).

%don't think this works
%expr(ID,In,[],In).

expr1(ID,In,Expr,Out) :-
white(In,Out1),
expr(ID,Out1,Expr1,Out2),
expr1(ID,Out2,Expr2,Out),
Expr = [Expr1|Expr2].

expr1(ID,In,[],In).

quote(ID,[96|Rest],Expr,Out) :-
expr(ID,Rest,Expr,Out),
oassert(kqml_fquote(ID,Expr)),!.

quote(ID,[96|Rest],Expr,Out) :-
commaexpr(ID,Rest,Expr,Out),
oassert(kqml_bquote(ID,Expr)),!.

commaexpr(ID,In,Expr,Out) :-
word(In,Expr,Out).

commaexpr(ID,In,Expr,Out) :-
quote(ID,In,Expr,Out).

commaexpr(ID,In,Expr,Out) :-
str(In,Expr,Out).

commaexpr(ID,In,Expr,Out) :-
comma(In,Out1),
commaexpr(ID,Out1,Expr1,Out),
gensym(kqml,ID1),
Expr = [',',Expr1],
oassert(kqml_commaexpr(ID1,Expr)),!,
Expr = ID1.

commaexpr(ID,In,ID1,Out) :-
lparen(In,Out1),
%CFA - removed this because we have non-KQML-compliant inputs
%word(In,Word1,Out1),
gensym(kqml,ID1),
commaexpr1(ID,Out1,SubExs,Out2),
rparen(Out2,Out),
oassert(kqml_commaexpr(ID1,[Word1|SubExs])),!.

commaexpr1(ID,In,Expr,Out) :-
commaexpr(ID,In,Expr1,Out1),
commaexpr1(ID,Out1,Expr2,Out),
Expr = [Expr1|Expr2].

commaexpr1(ID,In,[],In).
comma([44|Rest],Rest).

word(In,Word,Out) :-
((remove_leading_colon,
  In = [58|Rest]) ->
 word1(Rest,Word,Out);
 word1(In,Word,Out)).

word1(In,Word,Out) :-
word1(In,[],Word,Out).
word1([Ch|Rest],I,W,Out) :-
(alphabetic(Ch);
 numeric(Ch);
 special(Ch)),
word2([Ch|Rest],I,W,Out).

word2([Ch|Rest],I,W,Out) :-
(alphabetic(Ch);
 numeric(Ch);
 special(Ch)),
(upper([Ch]) ->
 (to_lower(Ch, Chl),
 append(I, [Chl], II));
 append(I, [Ch], II)),
word2(Rest, II, W, Out).

word2(In, I, W, In) :-
name(W,I).

lparen([40|Out],Out).
rparen([41|Out],Out).

alphabetic(Ch) :- 
((Ch > 64, Ch < 91);
(Ch > 96, Ch < 123)).

special(Ch) :-
(
Ch == 33;
(Ch > 35, Ch < 39);
(Ch > 41, Ch < 44);
(Ch > 44, Ch < 48);
Ch == 58;
(Ch > 59, Ch < 65);
(Ch > 93, Ch < 96);
Ch == 127).

numeric(Ch) :-
Ch > 47,
Ch < 58.

%represents a string as simply a prolog string (lost of chars)
str([34|Rest],Str,Out) :-
stringchars(Rest,Str,Out1),
Out1 = [34|Out].

stringchars(In,Chars,Out) :-
stringchar(In,Chars1,Out1),
stringchars(Out1,Chars2,Out),
append(Chars1,Chars2,Chars).

stringchars([34|In],[],[34|In]).

stringchar(In,[Char],Out) :-
In = [92,Char|Out],
Char \== 92,
Char \== 34.

stringchar(In,[Char],Out) :-
In = [Char|Out],
Char \== 92,
Char \== 34.

white([32|Out1],Out) :-
white1(Out1,Out).
white1([32|Out1],Out) :-
white1(Out1,Out).
white1(In,In).

colon([58|Out],Out).

%*********************

%retracts all assertions
kqml_retract :-
retractall(domain_pred1(_)),
retractall(domain_pred2(_)),
retractall(kqml_expr(_,_)),
retractall(kqml_head(_,_)),
retractall(kqml_kv(_,_)),
retractall(kqml_commaexpr(_,_)),
retractall(kqml_fquote(_,_)),
retractall(kqml_bquote(_,_)),
retractall(last_perf(_)),
retractall(remove_leading_colon),
retractall(use_kvs).

kqml_retract([ID|IDs]) :-
kqml_retract(ID),
kqml_retract(IDs).
kqml_retract([]).

%retracts assertions associated with this ID
kqml_retract(ID) :-
is_kqml_var(ID),
(kqml_expr(ID,IDs1); 
 IDs1 = []),
(findall(ID1,kqml_kv(ID,[_,ID1]),IDs2); 
 IDs2 = []),
((kqml_fquote(ID,ID3),IDs3 = [ID3]);
 IDs3 = []),
((kqml_bquote(ID,ID4),IDs4 = [ID4]); 
 IDs4 = []),
((kqml_commaexpr(ID,[A|B]), IDs5 = B);
 (kqml_commaexpr(ID,ID5), IDs5 = [ID5]); 
 IDs5 = []),
append([IDs1,IDs2,IDs3,IDs4,IDs5],IDs),
retractall(kqml_expr(ID,_)),
retractall(kqml_head(ID,_)),
retractall(kqml_kv(ID,_)),
retractall(kqml_commaexpr(ID,_)),
retractall(kqml_fquote(ID,_)),
retractall(kqml_bquote(ID,_)),
kqml_retract(IDs).
kqml_retract(_).

/*********************
output - predicates for constructing a valid KQML message

Takes an expression ID and recursively constructs a valid KQML
expression from "kqml_expr(ID,[...])" and the other possible kqml
assertions [detailed at the top of this file] already in the KB.  The
input ID must be the top-level "kqml_expr"; the predicate will
recursively construct this expression by first constructing its
subexpressions.  The output expression is represented as a list of
chars.  

Note: proper use of this function requires the user to first assert
the proper set of "kqml_expr" assertions, being careful to gensym new
expr ID's so as not to conflict with other existing expressions.
make_expr will check the resulting Expr for syntactic validity.

If the predicate use_kvs is asserted these output predicates will try
to use kqml_kv/head assertions in the construction before using kqml_expr
assertions.  Otherwise they will ignore kqml_kv/head assertions.
*/

unparse_kqml_perf(ID,Express) :-
is_kqml_var(ID),
use_kvs,
bagof([Expr1,Expr2],kqml_kv(ID,[Expr1,Expr2]),Kvs),
kqml_head(ID,Verb),
make_word(Verb,Express1),
%atom(Verb),
%name(Verb,Express1),
make_perfs_kv(Kvs,Express2),
append([[40],Express1,[32],Express2,[41]],Express).

unparse_kqml_perf(ID,Express) :-
is_kqml_var(ID),
kqml_expr(ID,[Verb|ExprList]),
atom(Verb),
name(Verb,Express1),
make_perfs(ExprList,Express2),
append([[40],Express1,[32],Express2,[41]],Express).

make_perfs([Expr1,Expr2|ExprList],Express) :-
make_word(Expr1,Express1),
Express1 = [58|_],
make_express(Expr2,Express2),
make_perfs(ExprList,Express3),
(ExprList = [] ->
 append([Express1,[32],Express2,Express3],Express);
 append([Express1,[32],Express2,[32],Express3],Express)).
make_perfs([],[]).

make_perfs_kv([[Expr1,Expr2]|ExprList],Express) :-
make_word(Expr1,Express1),
Express1 = [58|_],
make_express(Expr2,Express2),
make_perfs_kv(ExprList,Express3),
(ExprList = [] ->
 append([Express1,[32],Express2,Express3],Express);
 append([Express1,[32],Express2,[32],Express3],Express)).
make_perfs_kv([],[]).

make_kvs([[Expr1,Expr2]|ExprList],Express) :-
make_word(Expr1,Express1),
make_express(Expr2,Express2),
make_kvs(ExprList,Express3),
(ExprList = [] ->
 append([Express1,[32],Express2,Express3],Express);
 append([Express1,[32],Express2,[32],Express3],Express)).
make_kvs([],[]).

make_express([Expr|ExprList],Express) :-
make_express(Expr,Express1),
make_express(ExprList,Express2),
(ExprList = [] ->
 append(Express1,Express2,Express);
 append([Express1,[32],Express2],Express)).
make_express([],[]).

make_express(Expr,Express) :-
is_kqml_var(Expr),
use_kvs,
bagof([Expr1,Expr2],kqml_kv(Expr,[Expr1,Expr2]),Kvs),
kqml_head(Expr,Verb),
make_word(Verb,Express1),
make_kvs(Kvs,Express2),
(Kvs = [] ->
 append([[40],Express1,[41]],Express);
 append([[40],Express1,[32],Express2,[41]],Express)).

%non-kqml-compliant - allows lists without a head word
make_express(Expr,Express) :-
is_kqml_var(Expr),
kqml_expr(Expr,ExprList),
make_express(ExprList,Express1),
append([[40],Express1,[41]],Express).

make_express(Expr,Express) :-
\+ is_kqml_var(Expr),
make_word(Expr,Express).

%translator of kqml constants that are not kqml_vars
%removes the "\" character before them
make_word(Expr,Express2) :-
\+ is_kqml_var(Expr),
atom(Expr),
name(Expr,Express1),
Express1 = [92|Express2],
name(Expr2,Express2),
is_kqml_var(Expr2).

make_word(Expr,Express) :-
\+ is_kqml_var(Expr),
(atom(Expr),
 name(Expr,Express));
(number(Expr),
 number_chars(Expr,Express)).

%**********************
%a routine for printing strings

myprint([]).
myprint([],_).
myprint([A|B]) :-
myprint([A|B],0).
myprint([A|B],N) :-
N < 70,
put(A),
N1 is N+1,
myprint(B,N1).
myprint([A|B],70) :-
put(A),nl,
myprint(B,0).

/*****************************
a predicate for easier assertion and gensymming of assertions





*/

/*****************************

an example:

(ask-one :receiver Dumpty :sender dm 
:aspect (var100) 
:content (and (at-loc var100 atlanta) (type var100 engine)) 
:context (plan142 plan143))

is converted by kqml_perf into the following assertions:

kqml_par(kqml397,['ask-one',receiver,dumpty]).
kqml_par(kqml397,['ask-one',sender,dm]).
kqml_par(kqml397,['ask-one',aspect,kqml398]).
kqml_par(kqml397,['ask-one',content,kqml399]).
kqml_par(kqml397,['ask-one',context,kqml402]).
kqml_expr(kqml398,[var100]).
kqml_expr(kqml400,['at-loc',var100,atlanta]).
kqml_expr(kqml401,[type,var100,engine]).
kqml_expr(kqml399,[and,kqml400,kqml401]).
kqml_expr(kqml402,[plan142,plan143]).
kqml_expr(kqml397,['ask-one',receiver,dumpty,sender,dm,aspect,kqml398,content,kqml399,context,kqml402]).

*/


oassert(Form) :-
 clause(Form,true).
oassert(Form) :-
 gather_asserts,
 assert(Form),
 af(Form),
 gathered_asserts(A),
 append([Form],A,B),
 retractall(gathered_asserts(_)),
 assert(gathered_asserts(B)).
oassert(Form) :-
 \+ gather_asserts,
 af(Form), 
 assert(Form).

%does not remove Form from gathered_asserts....
oretractall(Form) :- 
retractall(Form),
df(Form).

/* kpurang test 

oassert(Form) :-
(clause(Form,true); (print(Form), nl ,assert(Form))).
*/
