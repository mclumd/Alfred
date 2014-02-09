%   Package: tokens
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Defines: library(tokens) altered to read Arity/Prolog.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

/*  DIFFERENCES BETWEEN ARITY LEXICAL STRUCTURE AND "STANDARD" PROLOG.

    1)  The manual does not make it clear whether % and / comments are
	allowed.  ("Comment" does not appear in the index.)  I assume
	that both _are_ allowed.

    2)  The "Edinburgh" convention for character constants is 0'c.
	Arity's convention is `c.

    3)	Edinburgh-compatible Prologs let you write integers in bases
	other than 10, e.g. 2'1010 = 9'11 = 10.  Arity/Prolog appears
	to lack this feature.

    4)  Arity/Prolog has strings, written $string$, in addition to the
	usual 'atom' and "chars" notations.  Quintus Prolog does not
	support strings (except in Xerox Quintus Prolog), so we read
	these as atoms.  But they cannot be mistaken for operators.

    5)	Arity introduced a piece of syntax that is wholly redundant.
	That is, their famous "snips".  If you have many snips in your
	program, you are doing something badly wrong.  There are two
	"standard" notations for this construct:  (X->true) and once(X).
	This tokeniser recognises "[!" as a new form of left bracket,
	and "!]" as a new form of right bracket, which is a great pity,
	because [!], [!,!], and (with suitable operator declarations),
	[!a!] are already legal Prolog terms.  (The latter would mean
	[ !(!( a )) ].  The parser will read [! x !] as once( x ).

    6)  Like DEC-10 Prolog, C Prolog, and Quintus Prolog, Arity/Prolog
	has database references.  However, they have chosen to make them
	a special form of constant which can be read as well as written.
	Since Quintus Prolog dbrefs, like DEC-10 Prolog ones, are
	compound terms whose contents are not predictable to us let alone
	you, we do NOT support that syntax in this tokeniser, and the
	input ~00035D18 will be read as atom ~, integer 00035, variable
	D18.
*/


%   read_tokens(TokenList, Dictionary)
%   returns a list of tokens.  It is needed to "prime" read_tokens/2
%   with the initial blank, and to check for end of file.  The
%   Dictionary is a list of AtomName=Variable pairs in no particular order.
%   The way end of file is handled is that everything else FAILS when it
%   hits character -1, sometimes printing a warning.  It might have been
%   an idea to return the atom 'end_of_file' instead of the same token list
%   that you'd have got from reading "end_of_file. ", but (1) this file is
%   for compatibility, and (b) there are good practical reasons for wanting
%   this behaviour.

read_tokens(TokenList, Dictionary) :-
	read_tokens(0' , Dict, ListOfTokens),
	terminate_list(Dict),		%  fill in the "hole" at the end.
	!,				%  we have to unify explicitly so
	Dictionary = Dict,		%  that we'll read and then check
	TokenList = ListOfTokens.	%  even with filled in arguments.
read_tokens([atom(end_of_file)], []).	%  End Of File is only problem.

terminate_list([]).
terminate_list([_|Tail]) :-
	terminate_list(Tail).



read_tokens(-1, _, _) :- !,			%  -1 is the end-of-file code
	fail.					%  it used to be 26
read_tokens(Ch, Dict, Tokens) :-
	Ch =< " ",				%  ignore layout.  CR, LF, and 
	!,					%  the DEC-10 newline (31)
	get0(NextCh),				%  are all skipped here.
	read_tokens(NextCh, Dict, Tokens).
read_tokens(0'%, Dict, Tokens) :- !,		%  %comment
	repeat,					%  skip characters to any
	    get0(Ch),				%  line terminator
	    Ch < " ", Ch =\= 9 /*TAB*/,		%  control char, not tab
	!,					%  stop when we find one
	Ch \== -1,				%  fail on EOF
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(0'/, Dict, Tokens) :- !,		%  /*comment?
	get0(NextCh),
	read_solidus(NextCh, Dict, Tokens).
read_tokens(0'!, Dict, [Token|Tokens]) :- !,
	get0(NextCh),
	(   NextCh =:= 0'] ->
	    Token = '!]',
	    get0(NthrCh),
	    read_tokens(NthrCh, Dict, Tokens)
	;   NextCh =:= 0'. ->
	    Token = atom(!),
	    read_after_atom(NextCh, Dict, Tokens)
	;   /* neither !] nor !.; treat like + */
	    read_symbol(NextCh, Chars, NthrCh),	% might read 0 chars
	    atom_chars(A, [0'!|Chars]),		% so might be "!"
	    Token = atom(A),
	    read_after_atom(NthrCh, Dict, Tokens)
	).
read_tokens(0'!, Dict, [atom(!)|Tokens]) :- !,	%  This is a special case so
	get0(NextCh),				%  that "!." is two tokens
	read_after_atom(NextCh, Dict, Tokens).	%  It could be cleverer.
read_tokens(0'(, Dict, [' ('|Tokens]) :- !,	%  NB!!!  "(" turns into
	get0(NextCh),				%  the token ' ('.
	read_tokens(NextCh, Dict, Tokens).
read_tokens(0'), Dict, [')'|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(0',, Dict, [','|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(0';, Dict, [atom(;)|Tokens]) :- !,	%   ; is not a punctuation
	get0(NextCh),				%   mark but an atom (e.g.
	read_after_atom(NextCh, Dict, Tokens).	%   you can :-op declare it).
read_tokens(0'[, Dict, [Token|Tokens]) :- !,
	get0(NextCh),
	(   NextCh =:= 0'! ->
	    Token = '[!',
	    get0(NthrCh),
	    read_tokens(NthrCh, Dict, Tokens)
	;   /* not [!, must be [ */
	    Token = '[',
	    read_tokens(NextCh, Dict, Tokens)
	).
read_tokens(0'], Dict, [']'|Tokens]) :- !,
	get0(NextCh),
	read_after_atom(NextCh, Dict, Tokens).
read_tokens(0'{, Dict, ['{'|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(0'|, Dict, ['|'|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(0'}, Dict, ['}'|Tokens]) :- !,
	get0(NextCh),
	read_after_atom(NextCh, Dict, Tokens).
read_tokens(0'., Dict, Tokens) :- !,		%  full stop
	get0(NextCh),				%  or possibly .=. &c
	read_fullstop(NextCh, Dict, Tokens).
read_tokens(0'", Dict, [chars(S)|Tokens]) :- !,	%  "chars"
	read_string(S, 0'", NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(0'', Dict, [atom(A)|Tokens]) :- !,	%  'atom'
	read_string(S, 0'', NextCh),
	atom_chars(A, S),			%  name/2 isn't quite right
	read_after_atom(NextCh, Dict, Tokens).
read_tokens(0'$, Dict, [string(A)|Tokens]) :- !,%  $string$
	read_string(S, 0'$, NextCh),
	atom_chars(A, S),			%  name/2 isn't quite right
	read_after_atom(NextCh, Dict, Tokens).
read_tokens(0'`, Dict, [number(I)|Tokens]) :- !,%  `char
	get0(Ch),
	read_char(Ch, 0'`, I, NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(Ch, Dict, [var(Var,Name)|Tokens]) :-
	(   Ch =< "Z", Ch >= "A" -> true	%  A..Z
	;   Ch =:= "_"				%  or _
	),
	!,					%  have to watch out for "_"
	read_name(Ch, S, NextCh),
	(   S = "_" -> Name = '_'		%  anonymous variable
	;   atom_chars(Name, S),		%  construct name
	    read_lookup(Dict, Name=Var)		%  lookup/enter in dictionary
	),
	read_after_atom(NextCh, Dict, Tokens).
read_tokens(Ch, Dict, Tokens) :-
	Ch >= "0", Ch =< "9",
	!,
	read_digits(Ch, Dict, Tokens, Chars, Chars).
read_tokens(Ch, Dict, [atom(A)|Tokens]) :-
	Ch >= "a", Ch =< "z",			%  a..z
	!,					%  no corresponding _ problem
	read_name(Ch, S, NextCh),
	atom_chars(A, S),			%  like name/2, but '0' is ATOM
	read_after_atom(NextCh, Dict, Tokens).
read_tokens(Ch, Dict, [atom(A)|Tokens]) :-	% MUST BE LAST CLAUSE
	% Ch is not layout, A..Z,a..z,0..9,_,(,)[|]{;}!.%/'"$`
	get0(AnotherCh),
	read_symbol(AnotherCh, Chars, NextCh),	% might read 0 chars
	atom_chars(A, [Ch|Chars]),		% so might be [Ch]
	read_after_atom(NextCh, Dict, Tokens).



%   The only difference between read_after_atom(Ch, Dict, Tokens) and
%   read_tokens/3 is what they do when Ch is "(".  read_after_atom
%   finds the token to be '(', while read_tokens finds the token to be
%   ' ('.  This is how the parser can tell whether <atom> <paren> must
%   be an operator application or an ordinary function symbol application.
%   See the public-domain library file READ.PL for details.

read_after_atom(0'(, Dict, ['('|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_after_atom(Ch, Dict, Tokens) :-
	read_tokens(Ch, Dict, Tokens).




%   read_string(Chars, Quote, NextCh)
%   reads the body of a string delimited by Quote characters.
%   The result is a list of ASCII codes.  There are two complications.
%   If we hit the end of the file inside the string this predicate FAILS.
%   It does not return any special structure.  That is the only reason
%   it can ever fail.  The other complication is that when we find a Quote
%   we have to look ahead one character in case it is doubled.  Note that
%   if we find an end-of-file after the quote we *don't* fail, we return
%   a normal string and the end of file character is returned as NextCh.
%   If we were going to accept C-like escape characters, as I think we
%   should, this would need changing (as would the code for 0'x).  But
%   the purpose of this module is not to present my ideal syntax but to
%   present something which will read present-day Prolog programs.

read_string(Chars, Quote, NextCh) :-
	get0(Ch),
	read_char(Ch, Quote, Char, Next),
	rest_string(Char, Next, Chars, Quote, NextCh).


rest_string(-1, NextCh, [], _, NextCh) :- !.		% string ended
rest_string(Char, Next, [Char|Chars], Quote, NextCh) :-
	read_char(Next, Quote, Char2, Next2),
	rest_string(Char2, Next2, Chars, Quote, NextCh).


%   read_char(C1, Quote, Char, C2)
%   reads a single `character' from a string, quoted atom, or character
%   constant.  C1 is the first character it is to look at, and has been
%   read already.  Quote is the surrounding quotation mark, which is "
%   for strings, ' for quoted atoms, and the radix character (also ')
%   for character constants.  A Dec-10 Prolog incompatibility is that
%   it does not allow newline characters in strings unless they are
%   preceded by an escape character.  As reading an extended character
%   would sometimes read one character too many, it is made to do so
%   always, and to return the first character which does not belong in
%   the character as C2.  When we have hit the end of the string, we
%   return Char = -1 (which does not necessarily mean that we have hit
%   the end of the source file, look at C2 for that).

read_char(Char, Quote, Result, Next) :-
    (	Char =:= 92 /* \ */ ->
	get0(C1),
	(   C1 < 0 ->
	    format(user_error, '~N** end of file in ~cquoted~c~n',
		   [Quote,Quote]),
	    Result = -1, Next = C1
	;   C1 =< " " ->
		/* \<layout> is skipped */
		get0(C2),
		read_char(C2, Quote, Result, Next)
	;   C1 =< "7", C1 >= "0" ->
		/* \<1-3 octal digits> */
		/* \<1-3 octal digits> */
		/* hairy bit: \1234 is S4 */
		get0(C2),
		(   C2 =< "7", C2 >= "0" ->
		    get0(C3),
		    (   C3 =< "7", C3 >= "0" ->
			get0(Next),
			Result is (C1*8+C2)*8+C3 - 73*"0"
		    ;   Next = C3,
			Result is (C1*8+C2) - 9*"0"
		    )
		;   Next = C2,
		    Result is C1-"0"
		)
	;   C1 =:= "^" ->
		get0(C2),
		(   C2 < 0 ->
		    format(user_error, '~N** end of file in ~c..~c^..~c~n',
		   	   [Quote,92 /* \ */,Quote]),
		    Result = -1, Next = C2
		;   Result is C2/\31,	% \^X -> control-X
		    get0(Next)
		)
	;   escape_char(C1, Result) ->
		get0(Next)
	;   /* otherwise */
		Result = C1,		% probably "'", '"',  or \ itself
		get0(Next)
	)

    ;	Char =:= Quote, Quote =\= 0'` ->
	get0(Ch),
	(   Ch =:= Quote ->
	    Result = Quote,
	    get0(Next)
	;   Result = -1, Next = Ch
	)

    ;	Char < " ", Char =\= 9 /*TAB */ ->
	Result = -1, Next = Char,
	format(user_error,
	    '~N** Strange character ~d ends ~ctoken~c~n',
	    [Char, Quote, Quote])

    ;
	Result = Char,
	get0(Next)
    ).



%  This table is for ASCII.  On Xerox Lisp systems, \n maps to
%  13 (CR).  The whole table needs replacing in EBCDIC systems,
%  in which the assumption that A..Z and a..z are contiguous
%  blocks also needs correcting.

escape_char(0'n, 10).		% \n = NewLine
escape_char(0'N, 10).		% \N = NewLine
escape_char(0't,  9).		% \t = Tab
escape_char(0'T,  9).		% \T = Tab
escape_char(0'r, 13).		% \r = Return
escape_char(0'R, 13).		% \R = Return
escape_char(0'v, 11).		% \v = Vertical tab
escape_char(0'V, 11).		% \V = Vertical tab
escape_char(0'b,  8).		% \b = Backspace
escape_char(0'B,  8).		% \B = Backspace
escape_char(0'f, 12).		% \f = FormFeed
escape_char(0'F, 12).		% \F = FormFeed
escape_char(0'e, 27).		% \e = Escape
escape_char(0'E, 27).		% \E = Escape
escape_char(0'd,127).		% \d = Delete
escape_char(0'D,127).		% \D = Delete
escape_char(0's, 32).		% \s = visible Space
escape_char(0'S, 32).		% \S = visible Space
escape_char(0'z, -1).		% \z = end of file
escape_char(0'Z, -1).		% \Z = end of file



%   read_solidus(Ch, Dict, Tokens)
%   checks to see whether /Ch is a /* comment or a symbol.  If the
%   former, it skips the comment.  If the latter it just calls read_symbol.
%   We have to take great care with /* comments to handle end of file
%   inside a comment, which is why read_solidus/2 passes back an end of
%   file character or a (forged) blank that we can give to read_tokens.

read_solidus(0'*, Dict, Tokens) :- !,
	get0(Ch),
	read_solidus(Ch, NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_solidus(Ch, Dict, [atom(A)|Tokens]) :-
	read_symbol(Ch, Chars, NextCh),		% might read 0 chars
	atom_chars(A, [0'/|Chars]),
	read_after_atom(NextCh, Dict, Tokens).

read_solidus(-1, -1) :- !,
	format(user_error, '~N** end of file in /*comment~n', []).
read_solidus(0'*, LastCh) :- !,
	get0(NextCh),
	(   NextCh =:= 0'/ ->	%  end of comment*/ found
	    LastCh is " "	% /*comment*/s act like spaces
	;   read_solidus(NextCh, LastCh)
	).
read_solidus(_, LastCh) :-
	get0(NextCh),
	read_solidus(NextCh, LastCh).


%   read_name(Char, String, LastCh)
%   reads a sequence of letters, digits, and underscores, and returns
%   them as String.  The first character which cannot join this sequence
%   is returned as LastCh.

read_name(Char, [Char|Chars], LastCh) :-
	(   Char >= "a", Char =< "z"
	;   Char >= "A", Char =< "Z"
	;   Char >= "0", Char =< "9"
	;   Char=:= "_"			% _
	), !,
	get0(NextCh),
	read_name(NextCh, Chars, LastCh).
read_name(LastCh, [], LastCh).


%   read_symbol(Ch, String, NextCh)
%   reads the other kind of atom which needs no quoting: one which is
%   a string of "symbol" characters.  Note that it may accept 0
%   characters, this happens when called from read_fullstop.

read_symbol(Char, [Char|Chars], LastCh) :-
	symbol_char(Char),
	!,
	get0(NextCh),
	read_symbol(NextCh, Chars, LastCh).
read_symbol(LastCh, [], LastCh).

symbol_char(0'#).
symbol_char(0'&).
symbol_char(0'*).
symbol_char(0'+).
symbol_char(0'-).
symbol_char(0'.).	% yes, +./* is a legal atom
symbol_char(0'/).
symbol_char(0':).
symbol_char(0'<).
symbol_char(0'=).
symbol_char(0'>).
symbol_char(0'?).
symbol_char(0'@).
symbol_char(92 /* \ */).
symbol_char(0'^).
symbol_char(0'~).


%   read_fullstop(Char, Dict, Tokens)
%   looks at the next character after a full stop.  There are
%   three cases:
%	(a) the next character is an end of file.  We treat this
%	    as an unexpected end of file.  The reason for this is
%	    that we HAVE to handle end of file characters in this
%	    module or they are gone forever; if we failed to check
%	    for end of file here and just accepted .<EOF> like .<NL>
%	    the caller would have no way of detecting an end of file
%	    and the next call would abort.
%	(b) the next character is a layout character.  This is a
%	    clause terminator.
%	(c) the next character is anything else.  This is just an
%	    ordinary symbol and we call read_symbol to process it.

read_fullstop(Ch, Dict, Tokens) :-
	(   Ch >= "0", Ch =< "9" ->
	    read_fract(Ch, Chars, NextCh),
	    number_chars(I, [0'0,0'.|Chars]),
	    Tokens = [number(I)|Tokens1],
	    read_tokens(NextCh, Dict, Tokens1)
	;   Ch > " " ->
	    read_symbol(Ch, Chars, NextCh),
	    atom_chars(A, [0'.|Chars]),
	    Tokens = [atom(A)|Tokens1],
	    read_after_atom(NextCh, Dict, Tokens)
	;   Ch < 0 ->
	    format(user_error, '~N** end of file just after full stop~n', []),
	    fail
	;   /* end of clause */
	    Tokens = []
	).


read_digits(Ch, Dict, Tokens, Chars0, Chars) :-
	(   Ch =< "9", Ch >= "0" ->
	    Chars0 = [Ch|Chars1],
	    get0(Ch1),
	    read_digits(Ch1, Dict, Tokens, Chars1, Chars)
	;   Ch =:= "." ->
	    get0(Ch1),
	    (   Ch1 >= "0", Ch1 =< "9" ->
		Chars0 = [Ch|Chars1],
		read_fract(Ch1, Chars1, NextCh),
		number_chars(I, Chars),			% FLOAT
		Tokens = [number(I)|Tokens1],
		read_tokens(NextCh, Dict, Tokens1)
	    ;   /* we have <integer> . */
		Chars0 = [],
		number_chars(I, Chars),			% INTEGER
		Tokens = [number(I)|Tokens1],
		read_fullstop(Ch1, Dict, Tokens1)
	    )
	;   /* not a digit or decimal point */
	    Chars0 = [],
	    number_chars(I, Chars),			% INTEGER
	    Tokens = [number(I)|Tokens1],
	    read_tokens(Ch, Dict, Tokens1)
	).


read_fract(Ch, Chars, NextCh) :-
	(   Ch =< "9", Ch >= "0" ->
	    Chars = [Ch|Chars1],
	    get0(Ch1),
	    read_fract(Ch1, Chars1, NextCh)
	;   Ch =\= "e", Ch =\= "E" ->
	    Chars = [],
	    NextCh = Ch
	;   get0(Ch1),
	    (   Ch1 =:= "-" ->
		Chars = [0'E,0'-|Chars1],
		get0(Ch2)
	    ;	Ch1 =:= "+" ->
		Chars = [0'E|Chars1],
		get0(Ch2)
	    ;   Chars = [0'E|Chars1],
		Ch2 = Ch1
	    ),
	    read_expt(Ch2, Chars1, NextCh)
	).

read_expt(Ch, Chars, NextCh) :-
	(   Ch =< "9", Ch >= "0" ->
	    Chars = [Ch|Chars1],
	    get0(Ch1),
	    read_expt(Ch1, Chars1, NextCh)
	;   /* not a digit */
	    Chars = [],
	    NextCh = Ch
	).


%   read_lookup is identical to memberchk except for argument order and
%   mode declaration.

read_lookup([X|_], X) :- !.
read_lookup([_|T], X) :-
	read_lookup(T, X). 


+(F) :-
	see(F),
	repeat,
	    read_tokens(T, _),
	    (   T = [atom(end_of_file)]
	    ;   write(T), nl, nl, fail
	    ),
	!,
	seen.


