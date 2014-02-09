%   File   : read.pl
%   Authors: David H. D. Warren + Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Purpose: library(read) with modifications for Arity Prolog syntax

/*  This code was originally written at the University of Edinburgh.
    David H. D. Warren wrote the first version of the parser.
    Richard A. O'Keefe ripped it out of the Dec-10 Prolog system
    and made it use only user-visible operations.  He also added
    the feature whereby P(X,Y,Z) is read as call(P,X,Y,Z).
    Alan Mycroft reorganised the code to regularise the functor modes.
    This is both easier to understand (there are no more '?'s),
    and also fixes bugs concerning the curious interaction of cut with
    the state of parameter instantiation.
    Richard A. O'Keefe then took it over again and made a number of
    other changes.  There are three intentional differences between
    this and the Dec-10 Prolog parser:

	"predicate variables" as syntactic saccharine for call/N

	when there is a syntax error, DEC-10 Prolog will backtrack
	internally and read the next term.  This fails.  If you
	call arity_read/1 with an uninstantiated argument, 
	failure means a syntax error.  You can rely on it.

	", .." is not accepted in place of "|".  This was always a
	parser feature, not a tokeniser feature:  any amount of
	layout and commentary was allowed between the "," and the
	"..".  It wouldn't be hard to allow again.

    The tokeniser returns a list of the following tokens:

	var(_,Name)		a variable with name Name
	atom(AnAtom)		an atom
	number(Num)		an integer or float
	chars(Chars)		a list of character codes
	string(Atom)		an atom (should be a string)

	'[!' '{' '[' '(' ' ('	punctuation marks
	'!]' '}' ']' ')'	' (' is the usual "(", '(' is "("
	         '|' ','	coming directly after an atom.

*/

%   arity_read(?Answer)
%   reads a term from the current input stream and unifies it with Answer.
%   Dec-10 syntax is used.  If a syntax error is found, the parser FAILS.

arity_read(Answer) :-
	arity_read(Answer, _).


%   arity_read(?Answer, ?Variables)
%   reads a term from the current input stream and unifies it with
%   Answer.  Variables is bound to a list of [Atom=Variable] pairs.
%   The variables are listed in the order in which they appeared, but
%   anonymous variables `_' do not appear at all.

arity_read(Answer, Variables) :-
	read_tokens(Tokens, Variables),
	(   read(Tokens, 1200, Term, LeftOver),
	    all_read(LeftOver),
	    !,
	    Answer = Term
	;   syntax_error(Tokens)
	).


%   bind_named_variables(DesiredBindings, Dictionary)
%   takes a variable Dictionary as returned by read_tokens/2 or
%   arity_read/2 (that is, a list of 'Name'=Variable pairs)
%   and a list of DesiredBindings (again, a list of 'Name'=Value
%   pairs, except that the Values are any terms you like).
%   For each 'Name'=Value pair in DesiredBindings, the
%   corresponding Variable in Dictionary is unified with Value.
%   What is this for?  It lets you read a term and then supply
%   values for variables by name, e.g.
%	| ?- arity_read(Term, Dictionary),
%	|    bind_named_variables(['X'=fred], Dictionary).
%	|: /* input */ f(X,Y,X,Y).
%	Dictionary = ['X'=fred,'Y'=_53],
%	Term = f(fred,_53,fred,_53)

bind_named_variables([], _).
bind_named_variables([Name=Value|Bindings], Dictionary) :-
	bind_named_variable(Dictionary, Name, Value),
	bind_named_variables(Bindings, Dictionary).

bind_named_variable([], _, _).
bind_named_variable([Name=Variable|_], Name, Value) :- !,
	Variable = Value.
bind_named_variable([_|Dictionary], Name, Value) :-
	bind_named_variable(Dictionary, Name, Value).


%   all_read(+Tokens)
%   checks that there are no unparsed tokens left over.

all_read([]) :- !.
all_read(S) :-
	syntax_error([operator,expected,after,expression], S).


%   expect(Token, TokensIn, TokensOut)
%   reads the next token, checking that it is the one expected, and
%   giving an error message if it is not.  It is used to look for
%   right brackets of various sorts, as they're all we can be sure of.

expect(Token, [Token|Rest], Rest) :- !.
expect(Token, S0, _) :-
	syntax_error([Token,or,operator,expected], S0).


%   read(+TokenList, +Precedence, -Term, -LeftOver)
%   parses a Token List in a context of given Precedence,
%   returning a Term and the unread Left Over tokens.

read([Token|RestTokens], Precedence, Term, LeftOver) :-
	read(Token, RestTokens, Precedence, Term, LeftOver).
read([], _, _, _) :-
	syntax_error([expression,expected], []).


%   read(+Token, +RestTokens, +Precedence, -Term, -LeftOver)

read('}', S0, _, _, _) :- re1('}', S0).
read(']', S0, _, _, _) :- re1(']', S0).
read(')', S0, _, _, _) :- re1(')', S0).
read(',', S0, _, _, _) :- re1(',', S0).
read('|', S0, _, _, _) :- re1('|', S0).

read(string(Atom), S0, Precedence, Answer, S) :-
	exprtl0(S0, Atom, Precedence, Answer, S).

read(chars(Chars), S0, Precedence, Answer, S) :-
	exprtl0(S0, Chars, Precedence, Answer, S).

read(number(Number), S0, Precedence, Answer, S) :-
	exprtl0(S0, Number, Precedence, Answer, S).

read('[', [']'|S1], Precedence, Answer, S) :- !,
	read_atom([], S1, Precedence, Answer, S).
read('[', S1, Precedence, Answer, S) :-
	read(S1, 999, Arg1, S2),		/* look for ",", "|", or "]" */
	read_list(S2, RestArgs, S3),
	!,
	exprtl0(S3, [Arg1|RestArgs], Precedence, Answer, S).

read('(', S1, Precedence, Answer, S) :-
	read(S1, 1200, Term, S2),		/* look for ")" */
	expect(')', S2, S3),
	!,
	exprtl0(S3, Term, Precedence, Answer, S).

read(' (', S1, Precedence, Answer, S) :-
	read(S1, 1200, Term, S2),		/* look for ")" */
	expect(')', S2, S3),
	!,
	exprtl0(S3, Term, Precedence, Answer, S).

read('{', ['}'|S1], Precedence, Answer, S) :- !,
	read_atom('{}', S1, Precedence, Answer, S).

read('{', S1, Precedence, Answer, S) :-
	read(S1, 1200, Term, S2),		/* look for "}" */
	expect('}', S2, S3),
	!,
	exprtl0(S3, '{}'(Term), Precedence, Answer, S).

read('[!', S1, Precedence, Answer, S) :-
	read(S1, 1200, Term, S2),		/* look for "!]" */
	expect('!]', S2, S3),
	!,
	exprtl0(S3, once(Term), Precedence, Answer, S).

read(var(Variable,_), ['('|S1], Precedence, Answer, S) :- !,
	read(S1, 999, Arg1, S2),		% look for "," or ")"
	read_args(S2, RestArgs, S3),
	!,
	Term =.. [call,Variable,Arg1|RestArgs],
	exprtl0(S3, Term, Precedence, Answer, S).

read(var(Variable,_), S0, Precedence, Answer, S) :-
	exprtl0(S0, Variable, Precedence, Answer, S).

read(atom(Atom), S0, Precedence, Answer, S) :-
	read_atom(Atom, S0, Precedence, Answer, S).


read_atom(-, [number(Number)|S1], Precedence, Answer, S) :- !,
	Negative is -Number,
	exprtl0(S1, Negative, Precedence, Answer, S).
read_atom(Functor, ['('|S1], Precedence, Answer, S) :- !,
	read(S1, 999, Arg1, S2),		% look for "," or ")"
	read_args(S2, RestArgs, S3),
	!,
	Term =.. [Functor,Arg1|RestArgs],
	exprtl0(S3, Term, Precedence, Answer, S).
read_atom(Functor, S0, Precedence, Answer, S) :-
	prefixop(Functor, Prec, Right),
	!,
	after_prefix_op(Functor, Prec, Right, S0, Precedence, Answer, S).
read_atom(Atom, S0, Precedence, Answer, S) :-
	exprtl0(S0, Atom, Precedence, Answer, S).


re1(Token, S0) :-
	syntax_error([Token,cannot,start,an,expression], S0).


%   read_args(+Tokens, -TermList, -LeftOver)
%   parses {',' expr(999)} ')' and returns a list of terms.

read_args([','|S1], [Term|Rest], S) :- !,
	read(S1, 999, Term, S2),
	!,
	read_args(S2, Rest, S).
read_args([')'|S], [], S) :- !.
read_args(S, _, _) :-
	syntax_error([', or )',expected,in,arguments], S).


%   read_list(+Tokens, -TermList, -LeftOver)
%   parses {',' expr(999)} ['|' expr(999)] ']' and returns a list of terms.

read_list([], _, _) :-
	syntax_error([', | or ]',expected,in,list], []).
read_list([Token|S1], Rest, S) :-
	read_list(Token, S1, Rest, S).

read_list(',', S1, [Term|Rest], S) :- !,
	read(S1, 999, Term, S2),
	!,
	read_list(S2, Rest, S).
read_list('|', S1, Rest, S) :- !,
	read(S1, 999, Rest, S2),
	!,
	expect(']', S2, S).
read_list(']', S1, [], S1) :- !.
read_list(Token, S1, _, _) :-
	syntax_error([', | or ]',expected,in,list], [Token|S1]).


%   after_prefix_op(+Op, +Prec, +ArgPrec, +Rest, +Precedence, -Ans, -LeftOver)

after_prefix_op(Op, _, _, S0, Precedence, Answer, S) :-
	bracket_follows(S0),
	!,
	exprtl0(S0, Op, Precedence, Answer, S).

after_prefix_op(Op, Oprec, _, S0, Precedence, _, _) :-
	Precedence < Oprec,
	!,
	syntax_error([prefix,operator,Op,in,context,with,precedence,Precedence], S0).

after_prefix_op(Op, Oprec, _, S0, Precedence, Answer, S) :-
	peepop(S0, S1),
	prefix_is_atom(S1, Oprec), % can't cut but would like to
	exprtl(S1, Oprec, Op, Precedence, Answer, S).

after_prefix_op(Op, Oprec, Aprec, S1, Precedence, Answer, S) :-
	read(S1, Aprec, Arg, S2),
	Term =.. [Op,Arg],
	!,
	exprtl(S2, Oprec, Term, Precedence, Answer, S).


%   When you had :- op(120, fx, !), op(110, xf, !),
%   the input [! a !] was incorrectly rejected.  The reason for this
%   was that the "]" following the "!" should have told us that the
%   second "!" *couldn't* be a prefix operator, but the postfix
%   interpretation was never tried.

bracket_follows([]).
bracket_follows([X|_]) :- is_right_bracket(X).

is_right_bracket(')').
is_right_bracket(']').
is_right_bracket('}').
is_right_bracket(',').
is_right_bracket('|').
is_right_bracket('!]').


%   The next clause fixes a bug concerning "mop dop(1,2)" where
%   mop is monadic and dop dyadic with higher Prolog priority.

peepop([atom(F),'('|S1], [atom(F),'('|S1]) :- !.
peepop([atom(F)|S1], [infixop(F,L,P,R)|S1]) :- infixop(F, L, P, R).
peepop([atom(F)|S1], [postfixop(F,L,P)|S1]) :- postfixop(F, L, P).
peepop(S0, S0).


%   prefix_is_atom(+TokenList, +Precedence)
%   is true when the right context TokenList of a prefix operator
%   of result precedence Precedence forces it to be treated as an
%   atom, e.g. (- = X), p(-), [+], and so on.

prefix_is_atom([Token|_], Precedence) :-
	prefix_is_atom(Token, Precedence).

prefix_is_atom(infixop(_,L,_,_), P) :- L >= P.
prefix_is_atom(postfixop(_,L,_), P) :- L >= P.
prefix_is_atom(')', _).
prefix_is_atom(']', _).
prefix_is_atom('}', _).
prefix_is_atom('!]', _).
prefix_is_atom('|', P) :- 1100 >= P.
prefix_is_atom(',', P) :- 1000 >= P.
prefix_is_atom([],  _).


%   exprtl0(+Tokens, +Term, +Prec, -Answer, -LeftOver)
%   is called by read/4 after it has read a primary (the Term).
%   It checks for following postfix or infix operators.

exprtl0([atom(F)|S1], Term, Precedence, Answer, S) :-
	ambigop(F, Precedence, L1, O1, R1, L2, O2),
	!,
	(   prefix_is_atom(S1, Precedence),
	    !,
	    exprtl([postfixop(F,L2,O2) |S1], 0, Term, Precedence, Answer, S)
	;   exprtl([infixop(F,L1,O1,R1)|S1], 0, Term, Precedence, Answer, S)
	;   exprtl([postfixop(F,L2,O2) |S1], 0, Term, Precedence, Answer, S)
	).
exprtl0([atom(F)|S1], Term, Precedence, Answer, S) :-
	infixop(F, L1, O1, R1),
	!,
	exprtl([infixop(F,L1,O1,R1)|S1], 0, Term, Precedence, Answer, S).
exprtl0([atom(F)|S1], Term, Precedence, Answer, S) :-
	postfixop(F, L2, O2),
	!,
	exprtl([postfixop(F,L2,O2) |S1], 0, Term, Precedence, Answer, S).

exprtl0([','|S1], Term, Precedence, Answer, S) :-
	Precedence >= 1000,
	!,
	read(S1, 1000, Next, S2),
	!,
	exprtl(S2, 1000, (Term,Next), Precedence, Answer, S).

exprtl0(['|'|S1], Term, Precedence, Answer, S) :-
	Precedence >= 1100,
	!,
	read(S1, 1100, Next, S2),
	!,
	exprtl(S2, 1100, (Term ; Next), Precedence, Answer, S).

exprtl0([atom(X)|S1], _, _, _, _) :- !,
	syntax_error([non-operator,X,follows,expression], [atom(X)|S1]).
exprtl0([Thing|S1], _, _, _, _) :-
	cant_follow_expr(Thing, Culprit),
	!,
	syntax_error([Culprit,follows,expression], [Thing|S1]).

exprtl0(S, Term, _, Term, S).


cant_follow_expr(atom(_),	atom).
cant_follow_expr(var(_,_),	variable).
cant_follow_expr(number(_),	number).
cant_follow_expr(chars(_),	'character list').
cant_follow_expr(string(_),	string).
cant_follow_expr(' (',		bracket).
cant_follow_expr('(',		bracket).
cant_follow_expr('[',		bracket).
cant_follow_expr('{',		bracket).
cant_follow_expr('[!',		bracket).



exprtl([infixop(F,L,O,R)|S1], C, Term, Precedence, Answer, S) :-
	Precedence >= O, C =< L,
	!,
	read(S1, R, Other, S2),
	Expr =.. [F,Term,Other], /*!,*/
	exprtl(S2, O, Expr, Precedence, Answer, S).

exprtl([postfixop(F,L,O)|S1], C, Term, Precedence, Answer, S) :-
	Precedence >= O, C =< L,
	!,
	Expr =.. [F,Term],
	peepop(S1, S2),
	exprtl(S2, O, Expr, Precedence, Answer, S).

exprtl([','|S1], C, Term, Precedence, Answer, S) :-
	Precedence >= 1000, C < 1000,
	!,
	read(S1, 1000, Next, S2), /*!,*/
	exprtl(S2, 1000, (Term,Next), Precedence, Answer, S).

exprtl(['|'|S1], C, Term, Precedence, Answer, S) :-
	Precedence >= 1100, C < 1100,
	!,
	read(S1, 1100, Next, S2), /*!,*/
	exprtl(S2, 1100, (Term ; Next), Precedence, Answer, S).

exprtl(S, _, Term, _, Term, S).


%   This business of syntax errors is tricky.  When an error is detected,
%   we have to write out a message.  We also have to note how far it was
%   to the end of the input, and for this we are obliged to use the data-
%   base.  Then we fail all the way back to read(), and that prints the
%   input list with a marker where the error was noticed.  If subgoal_of
%   were available in compiled code we could use that to find the input
%   list without hacking the data base.  The really hairy thing is that
%   the original code noted a possible error and backtracked on, so that
%   what looked at first sight like an error sometimes turned out to be
%   a wrong decision by the parser.  This version of the parser makes
%   fewer wrong decisions, and my goal was to get it to do no backtracking
%   at all.  This goal has not yet been met, and it will still occasionally
%   report an error message and then decide that it is happy with the input
%   after all.  Sorry about that.


syntax_error(Message, List) :-
	telling(CurrentOutput),
	tell(user),
	nl, write('**'), display_list(Message),
	tell(CurrentOutput),
	length(List, Length),
	recorda(syntax_error, length(Length), _),
	!, fail.

display_list([]) :-
	nl.
display_list([Head|Tail]) :- !,
	put(" "),
	display_token(Head),
	display_list(Tail).

syntax_error(List) :-
	recorded(syntax_error, length(AfterError), Ref),
	erase(Ref),
	length(List, Length),
	BeforeError is Length-AfterError,
	telling(CurrentOutput),
	tell(user),
	display_list(List, BeforeError),
	tell(CurrentOutput),
	!, fail.

display_list(X, 0) :- !,
	write('<<here>> '),
	display_list(X, 99999).
display_list([Head|Tail], BeforeError) :- !,
	display_token(Head),
	put(32),
	Left is BeforeError-1,
	display_list(Tail, Left).
display_list([], _) :-
	nl.

display_token(atom(X))	 :- !,	writeq(X).
display_token(var(_,X))	 :- !,	write(X).
display_token(number(X)) :- !,	write(X).
display_token(chars(X))  :- !,	put(0'"), display_string(X, 0'").
display_token(string(X)) :- !,  name(X, Chars),
				put(0'$), display_string(Chars, 0'$).
display_token(X)	 :-	write(X).

display_string([], Quote) :-
	put(Quote).
display_string([Quote|Chars], Quote) :- !,
	put(Quote), put(Quote),		% later, put(92), put(Quote)
	display_string(Chars, Quote).
display_string([Char|Chars], Quote) :-
	put(Char),
	display_string(Chars, Quote).


/*  The original public-domain parser was written to go with a similarly
    public-domain version of op/3 and current_op/3 which manipulated the
    following three tables.  For this draft of the converter, I have not
    bothered to provide that.

    Operator	Corresponding fact
    N,  fy, F	prefixop(F, N, N)		N is the priority
    N,  fx, F	prefixop(F, N, N-1)		F is the operator symbol
    N, yfx, F	infixop(F, N, N, N-1)
    N, xfx, F	infixop(F, N-1, N, N-1)
    N, xfy, F	infixop(F, N-1, N, N)
    N, xf , F   postfixop(F, N-1, N)
    N, yf , F	postfixop(F, N, N)

    Like Edinburgh-compatible Prologs, Arity/Prolog has no built-in
    postfix operators, but permits them.
*/

postfixop(_, _, _) :- fail.

prefixop((:-),		1200, 1199).
prefixop((?-),		1200, 1199).
prefixop((mode),	1150, 1149).
prefixop((public),	1150, 1149).
prefixop((extrn),	1150, 1149).		% Arity ADDITION
prefixop((visible),	1150, 1149).		% Arity ADDITION
prefixop((module),	1150, 1149).		% Arity ADDITION
prefixop(case,		 900,  899).		% Arity ADDITION
prefixop(spy,		 900,  900).
prefixop(nospy,		 900,  900).
prefixop(not,		 900,  899).		% Arity ADDITION
prefixop(\+,		 900,  899).
prefixop(+,		 500,  499).
prefixop(-,		 500,  499).
prefixop(*,		 300,  300).		% Arity ADDITION
prefixop(&,		 300,  300).		% Arity ADDITION
prefixop(\,		 300,  300).		% Arity ADDITION

infixop((:-),		1199, 1200, 1199).
infixop((-->),		1199, 1200, 1199).
infixop((;),		1199, 1200, 1200).
infixop((','),		 999, 1000, 1000).
infixop((->),		 799,  800,  800).	% Arity ***CHANGE***
infixop(or,		 750,  750,  749).	% Arity ADDITION
infixop(and,		 740,  740,  739).	% Arity ADDITION
infixop(\/,		 730,  730,  729).	% Arity ***CHANGE***
infixop(\+/,		 720,  720,  719).	% Arity ADDITION
infixop(/\,		 710,  710,  709).	% Arity ***CHANGE***
infixop(=,		 699,  700,  700).	% Arity ***CHANGE***
infixop(is,		 699,  700,  699).
infixop(=..,		 699,  700,  699).
infixop(\=,		 699,  700,  699).	% Arity ADDITION
infixop(==,		 699,  700,  699).
infixop(\==,		 699,  700,  699).
infixop(@<,		 650,  650,  649).	% Arity ***CHANGE***
infixop(@>=,		 650,  650,  649).	% Arity ***CHANGE***
infixop(@>,		 650,  650,  649).	% Arity ***CHANGE***
infixop(@=<,		 650,  650,  649).	% Arity ***CHANGE***
infixop(=:=,		 650,  650,  649).	% Arity ***CHANGE***
infixop(=\=,		 650,  650,  649).	% Arity ***CHANGE***
infixop(<,		 600,  600,  599).	% Arity ***CHANGE***
infixop(>=,		 600,  600,  599).	% Arity ***CHANGE***
infixop(>,		 600,  600,  599).	% Arity ***CHANGE***
infixop(=<,		 600,  600,  599).	% Arity ***CHANGE***
infixop(<<,		 550,  550,  549).	% Arity ***CHANGE***
infixop(>>,		 550,  550,  549).	% Arity ***CHANGE***
infixop(+,		 500,  500,  499).
infixop(-,		 500,  500,  499).
infixop(:,		 499,  500,  500).	% Arity DIFFERENCE
infixop(*,		 400,  400,  399).
infixop(/,		 400,  400,  399).
infixop(//,		 400,  400,  399).
infixop(mod,		 400,  400,  399).	% Arity ***CHANGE***
infixop(^,		 299,  300,  300).	% Arity ***CHANGE***
infixop(..,		 200,  200,  199).	% Arity ADDITION

ambigop(_,          _,  _,  _,  _,  _,  _) :- fail.
%mbigop(F, Precedence, L1, O1, R1, L2, O2) :-
%       postfixop(F, L2, O2),
%       O2 =< Precedence,
%       infixop(F, L1, O1, R1),
%       O1 =< Precedence.

/*  It is worth noting that, with the exception of 'extrn', 'visible',
    'module', 'case', 'not', and '->', all the changes and additions
    listed above are incompatible with earlier versions of Arity/
    Prolog, whose operator declarations were (except for '->') quite
    consistent with the Edinburgh standard.  Anyone who had
		X is Y/\1 + 1
    as a goal in his or her program (with the Edinburgh operator
    priorities this parses as is(X, +( /\(Y,1), 1))) got a nasty
    shock when it turned into /\( is(X,Y), +(1,1) ).  Was embedding
    not-quite-C really worth breaking perfectly-good-Prolog?
*/


