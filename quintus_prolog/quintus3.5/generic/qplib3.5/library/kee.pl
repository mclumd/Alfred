%   File   : kee.pl
%   Author : Richard A. O'Keefe
%   Updated: 02 Nov 1988
%   Purpose: Read "KEE"-style rules.

/*  The syntax this file accepts is a variant of S-expressions.

    End-of-line comments must be terminated by an actual new-line.
    There are two varieties:
	; ..... <end of line>
	% ..... <end of line>

    Lists are written in the usual S-expression form:
	(<elem>...<elem> . <elem>)
	[<elem>...<elem> | <elem>]
    The pairs "(","[", ".","|", and ")","]" are completely interchangeable.
    (a] and [b) are perfectly acceptable.  If there is not exactly one
    s-expression following a ".", an error is reported, but the input is
    still accepted.  Note that () and [] are read as '[]', which is NOT
    the same as 'nil'.

    Strings are written in double quotes, as in Dec-10 Prolog.
	"....."
    is read as the term string(".....").  "" inside the quotes stands
    for one quote.  Character escapes of any kind are NOT supported.
   
    The KEE rules include forms #[....].  I do not know what this is,
    as #[ is explicitly left undefined in Common Lisp.  I have chosen
    to over-generalise, so that
	# <sexpr>
    is read as the term #(<sexpr>).  Note that this means that the
    other sharp-sign forms, such as #xA = #o12 = 10 are not supported.
    This may need attending to.

    The form ?identifier appears in many of the rules.  This appears
    to be some kind of variable.  Again, I have over-generalised, so
	? <sexpr>
    is read as the term ?(<sexpr>).  Note that the "?" and "#"
    characters are special only at the beginning of an s-expression.
    VALVE-#-2-IS-STUCK? is a perfectly good atom.  Also, AVG has the
    convention of changing ? to _ when converting to lower case, so
    an initial _ acts like ?.

    Almost any other sequence of non-layout characters is a constant.
    Anything that looks like an integer or a float is a number, the
    rest are atoms.   Thus 123 is an integer, 123Q is an atom,
    -1 is an integer, 1- is an atom.

    The module exports five predicates.

	eof_kee(EofMarker)
	    returns the atom which KEE uses to mark the end of a file.

	load_kee(File, Goal)
	    reads S-expressions from File, calling Goal(Term) for each
	    term it reads, until the end of the file is encountered.
	    {Actually, an early EofMarker will stop it too.}
	    The Goal does NOT see File as the current input.

	read_kee(Term)
	    reads one S-expression from the current input stream and
	    unifies Term with it.

	vars_kee(OldTerm, NewTerm, OldVars, NewVars)
	    each term ?(OldVar) in OldTerm is replaced by
	    the corresponding NewVar giving NewTerm.  This
	    will normally generate the last three arguments from
	    the first.  OldTerm should be ground, and should be
	    the result of a call to read_kee/1.
	
	write_kee(Term)
	    writes Term out.  Note that this really should be the
	    result of a call to read_kee/1, and it should NOT contain
	    any variables.  The output is not attractive.  This is
	    mainly intended for debugging.

*/

:- module(kee, [
	eof_kee/1,
	load_kee/2,
	read_kee/1,
	vars_kee/4,
	write_kee/1
   ]).

:- meta_predicate
	load_kee(+, 1).
:- mode
	eof_kee(?),
	vars_kee(+, -, -, -),
	    var_kee(?, ?, ?, ?).

sccs_id('"@(#)88/11/02 kee.pl	27.1"').


:- use_module(library(call), [
	call/2
   ]).



%   vars_kee(+OldTerm, -NewTerm, -OldVars, -NewVars)
%   replaces the ?(Old) subterms of OldTerm by New variables,
%   yielding NewTerm.  OldVars and NewVars are parallel lists
%   of the Old variable names and New variables.

vars_kee([], [], _, _) :- !.
vars_kee([OldHead|OldTail], [NewHead|NewTail], OldVars, NewVars) :- !,
	vars_kee(OldHead, NewHead, OldVars, NewVars),
	vars_kee(OldTail, NewTail, OldVars, NewVars).
vars_kee(#(Old), #(New), OldVars, NewVars) :- !,
	vars_kee(Old, New, OldVars, NewVars).
vars_kee(?(Old), New, OldVars, NewVars) :- !,
	var_kee(OldVars, NewVars, Old, New).
vars_kee(Old, Old, _, _).

var_kee([Old|_], [New|_], Old, New) :- !.
var_kee([_|OldVars], [_|NewVars], Old, New) :-
	var_kee(OldVars, NewVars, Old, New).



%   eof_kee(?EofMarker)
%   is when EofMarker is the atom which is used to mark the end of
%   a KEE file.

eof_kee(kbend).


%   read_kee(?Sexpr)
%   reads a single S-expression from the current input stream and
%   unifies it with Sexpr.  If the stream is exhausted, it yields
%   the EofMarker.  If the stream runs out in the middle of an
%   S-expression, it should abort, but instead it fails.  At least
%   it produces an error message in that case.

read_kee(Sexpr) :-
	get_token(0' , Token, D),
	(   Token = end_of_file ->
	    eof_kee(Sexpr)
	;   read_kee(Token, Sexp, D, Next),
	    check_finished(Next),
	    Sexpr = Sexp
	).

check_finished(-1) :- !.
check_finished(10) :- !.
check_finished(0';) :- !,
	skip(10).
check_finished(0'%) :- !,
	skip(10).
check_finished(C) :-
	C =< 0' ,
	!.
check_finished(_) :-
	kee_error('non-layout character lost').


read_kee(C, Sexpr, Next) :-
	get_token(C, Token, D),
	read_kee(Token, Sexpr, D, Next).

read_kee('(', List, C, Next) :-
	read_kee_tail(C, List, Next).
read_kee('#', #(Sexpr), C, Next) :- 
	read_kee(C, Sexpr, Next).
read_kee('?', ?(Sexpr), C, Next) :- 
	read_kee(C, Sexpr, Next).
read_kee('='(X), X, Next, Next).
read_kee(')', _, _, _) :-
	kee_error('unexpected ")" or "]"'),
	fail.
read_kee('.', _, _, _) :-
	kee_error('unexpected "." or "|"'),
	fail.
read_kee(end_of_file, _, _, _) :-
	kee_error('unexpected end of file'),
	fail.


read_kee_tail(C, List, Next) :-
	get_token(C, Token, D),
	read_kee_tail(Token, List, D, Next).

read_kee_tail('(', [List|Sexprs], C, Next) :-
	read_kee_tail(C, List, D),
	read_kee_tail(D, Sexprs, Next).
read_kee_tail('#', [#(Sexpr)|Sexprs], C, Next) :-
	read_kee(C, Sexpr, D),
	read_kee_tail(D, Sexprs, Next).
read_kee_tail('?', [?(Sexpr)|Sexprs], C, Next) :-
	read_kee(C, Sexpr, D),
	read_kee_tail(D, Sexprs, Next).
read_kee_tail('='(X), [X|Sexprs], C, Next) :-
	read_kee_tail(C, Sexprs, Next).
read_kee_tail(')', [], Next, Next).
read_kee_tail('.', Sexpr, C, Next) :-
	read_kee_tail(C, Sexprs, Next),
	check_single_element(Sexprs, Sexpr).
read_kee_tail(end_of_file, _, _, _) :-
	kee_error('unexpected end of file'),
	fail.


check_single_element([Sexpr], Sexpr) :- !.
check_single_element([Sexpr|_], Sexpr) :- !,
	kee_error('exactly one s-expr should follow "." or "|"').
check_single_element(Sexpr, Sexpr) :-
	kee_error('exactly one s-expr should follow "." or "|"').


kee_error(Message) :-
	current_input(Stream),
	line_count(Stream, Line),
	(   current_stream(File,_,Stream) -> true
	;   File = Stream
	),
	format('~N** Near line ~w of ~w~n** ~w~n', [Line,File,Message]).


%   get_token(+C0, -Token, -C1)
%   reads and returns a Token, where C0 is a character which has
%   already been read, and C1 returns the next character after the
%   Token.  If no character has been read yet, C0 is conventionally
%   set to blank.  If the token is read without any need for lookahead,
%   C1 is conventionally set to blank.  The tokens returned are
%	'('	')'	'.'	'#',	'?'
%	and =(Term), the latter standing for a term which has already
%	been completely parsed.
%   Note that the magic number is the only ASCII dependency in the
%   whole file.  I suppose I should really use 0'\n.

get_token(-1, end_of_file, -1) :- !.		% end of file
get_token(C, Token, Next) :-			% layout
	C =< " ",
	!,
	get0(D),
	get_token(D, Token, Next).
get_token(0';, Token, Next) :- !,		% ;comment
	skip(10),				% skip to \n
	get_token(10, Token, Next).
get_token(0'%, Token, Next) :- !,		% %comment
	skip(10),				% skip to \n
	get_token(10, Token, Next).
get_token(0'(, '(', 0' ) :- !.			% (
get_token(0'), ')', 0' ) :- !.			% )
get_token(0'[, '(', 0' ) :- !.			% [
get_token(0'], ')', 0' ) :- !.			% ]
get_token(0'., '.', 0' ) :- !.			% .
get_token(0'|, '.', 0' ) :- !.			% |
get_token(0'#, '#', 0' ) :- !.			% #
get_token(0'?, '?', 0' ) :- !.			% ?
get_token(0'_, '?', 0' ) :- !.			% _
get_token(0'", '='(string(Chars)), Next) :- !,	% "..."
	get0(C),
	get_string(C, Chars, Next).
get_token(C, '='(X), Next) :-			% atom or number
	get_constant(C, Chars, Next),
	kee_name(X, Chars).

get_string(0'", Chars, Next) :- !,
	get0(C),
	get_string_quote(C, Chars, Next).
get_string(Char, [Char|Chars], Next) :-
	get0(C),
	get_string(C, Chars, Next).

get_string_quote(0'", [0'"|Chars], Next) :- !,
	get0(C),
	get_string(C, Chars, Next).
get_string_quote(Next, [], Next).

get_constant(Next, [], Next) :-
	Next =< 0' ,
	!.
get_constant(Next, [], Next) :-
	special_character(Next),
	!.
get_constant(Char, [Char|Chars], Next) :-
	get0(C),
	get_constant(C, Chars, Next).


%   "." is omitted from this table so that 1.2 can be read.
%   "#" and "_" are omitted, so that these characters are
%   only special at the beginning of an s-expr.

special_character(0';).
special_character(0'%).
special_character(0'().
special_character(0'[).
special_character(0')).
special_character(0']).
special_character(0'|).
special_character(0'").


%   kee_name(-Constant, +Chars)
%   takes a list of characters and converts it to a number (if possible)
%   or to an atom (if not).  In the latter case, upper case letters are
%   are folded to lower case, and '.' is mapped to '_'.

kee_name(Number, Chars) :-
	number_chars(Number, Chars),
	!.
kee_name(Atom, Chars) :-
	case_convert(Chars, Lower),	% take Lower=Chars to prevent
	atom_chars(Atom, Lower).	% case folding.


case_convert([], []).
case_convert([Char|Chars], [Lower|Lowers]) :-
	(   Char >= "A", Char =< "Z" ->
	    Lower is "a"-"A"+Char
	;   Char =:= "." ->
	    Lower is "_"
	;   Lower is Char
	),
	case_convert(Chars, Lowers).


%   load_kee(+File, +Filter)
%   processes S-expressions in File.

load_kee(File, Filter) :-
	current_input(OldInput),
	open(File, read, KeeInput),
	repeat,
	    set_input(KeeInput),
	    read_kee(Term),
	    set_input(OldInput),
	    (   eof_kee(Term) -> true
	    ;   call(Filter, Term) -> fail
	    ),
	!,
	close(KeeInput).


%   write_kee(Sexpression)
%   writes the Sexpression to the current output stream,
%   beginning the the first column of a line, and ending with a new-line.
%   (It is thus like portray_clause.)  It is meant to be unambiguous
%   and rigorously indented rather than beautiful.

write_kee(Sexpr) :-
	format('~N', []),
	write_kee(Sexpr, 0),
	nl.

write_kee(#(X), Depth) :- !,
	write('# '),
	write_kee(X, Depth).
write_kee(?(X), _) :- !,
	write('? '), write(X).
write_kee(string(X), _) :- !,
	put(0'"), write_chars(X), put(0'").
write_kee([], _) :- !,
	write('( )').
write_kee([Head|Tail], Depth) :- !,
	Depth1 is Depth+2,
	write('( '),
	write_kee(Head, Depth1),
	write_kee(Tail, Depth, Depth1).
write_kee(X, _) :-
	writeq(X).

write_kee([], Depth0, _) :- !,
	nl, tab(Depth0), write(')').
write_kee([Head|Tail], Depth0, Depth) :- !,
	nl, tab(Depth),
	write_kee(Head, Depth),
	write_kee(Tail, Depth0, Depth).
write_kee(Last, Depth0, Depth) :-
	nl, tab(Depth), write('. '),
	write_kee(Last, Depth),
	write_kee([], Depth0, Depth).


write_chars([]).
write_chars([Char|Chars]) :-
	(   Char =:= 0'" ->	put(0'"), put(0'")
	;   Char  <  " " ->	put(0'^), put(Char+64)
	;   Char =:= 127 ->	put(0'^), put(0'?)
	;   /* printing char */	put(Char)
	),
	write_chars(Chars).


