%   Package: environment
%   Author : Richard A. O'Keefe
%   Updated: 04/07/99
%   Purpose: 

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(environment, [
	environment/1
   ]).

sccs_id('"@(#)99/04/07 environment.pl	76.1"').

/*  This is the "environment" table which has been developed to try to
    improve portability of Quintus Prolog source code between the
    following operating systems:

	Unix (BSD)
	Unix (System V)
	VMS
	VM/SP (CMS)
	MVS
	MS-DOS
	Macintosh

    For a description of the parameters, look after the first 'end_of_file.'
*/

%   environment(Feature)
%   UNIX/Windows version of the environment table.

environment(os(OS))		:-
	prolog_flag(host_type, Host),
	(   Host==ix86 -> OS = msdos
	;   OS = unix
	).
environment(dialect(quintus)).
environment(version(VerL))	:-
	prolog_flag(version, Ver),
	atom_chars(Ver, List),
	'env version'(VerL, List, []).
environment(atom(X))		:- 'env atom'(X).
environment(string(_))		:- fail.
environment(integer(X))		:- 'env integer'(X).
environment(float(X))		:- 'env float'(X).
environment(float(single,X))	:- 'env float'(X).
environment(arity(X))		:- 'env arity'(X).
environment(stream(X))		:- 'env stream'(X).
environment(file_name(X))	:- 'env file'(X).
environment(file_type(T,W))	:- 'env type'(T, W).

'env version'([A,B,C]) --> [Maj], ".", [Min], ".", [Sub], !,
	{A is Maj-0'0, 
	 B is Min-0'0, 
	 C is Sub-0'0}.
'env version'([A,B]) --> [Maj], ".", [Min],
	{A is Maj-0'0, 
	 B is Min-0'0}.

'env atom'(size(65532)).
'env atom'(min(1)).
'env atom'(max(255)).
'env atom'(width(X))		:- X is 65532*4 + 2.
'env atom'(number(X))		:- X is 1 << 21.

'env integer'(size(32)).
'env integer'(small(X))		:- X is -1 << 31.
'env integer'(large(X))		:- X is -1 - (-1 << 31).
'env integer'(width(11)).
'env integer'(too_big(error)).
'env integer'(overflow(error)).

'env float'(size(64)).   
'env float'(too_big(infinity)).
'env float'(overflow(infinity)).
'env float'(confounded)		:- fail.
'env float'(b(2)).
'env float'(p(53)).
'env float'(emin(-1021)).
'env float'(emax( 1024)). 
'env float'(sigma(X))		:- scale(-1022, 1.0, X).
'env float'(lambda(X))		:- scale(52, 1.0, Y), Z is (Y-1)+Y,
                                   scale(971, Z, X).  % (2**53-1)*2**(1024-53)
'env float'(epsilon(X))		:- scale(-18, 1.0, X).
'env float'(max_integer(X))	:- scale(52, 1.0, Y), X is (Y-1)+Y.
'env float'(min_integer(X))	:- scale(52, 1.0, Y), X is (1-Y)-Y.
'env float'(pi(3.141592653589793238462643)).	% ROUNDED BY COMPILER!
'env float'(digits(16)).
'env float'(width(22)).
'env float'(mark(0'E)).
'env float'(radix(2)).
'env float'(mantissa(53)).
'env float'(small(X))		:- scale(-1022, 1.0, X).
'env float'(large(X))		:- scale(52, 1.0, Y), Z is (Y-1)+Y,
				   scale(971, Z, X).  % (2**53-1)*2**(1024-53)
'env float'(machine(X))		:- 'env mac'(X).

scale(N, X0, X) :-
    (	N >= 4 -> X1 is X0 * 16.0,   N1 is N-4, scale(N1, X1, X)
    ;   N=< -4 -> X1 is X0 * 0.0625, N1 is N+4, scale(N1, X1, X)
    ;	N >  0 -> X1 is X0 * 2.0,    N1 is N-1, scale(N1, X1, X)
    ;   N <  0 -> X1 is X0 * 0.5,    N1 is N+1, scale(N1, X1, X)
    ;   X is X0
    ).

'env mac'(b(2)).
'env mac'(radix(2)).
'env mac'(rounds).
'env mac'(overflows)		:- fail.
'env mac'(format(ieee(double))).

'env arity'(functor(255)).
'env arity'(call(255)).
'env arity'(foreign(255)).

'env stream'(read( user_input)).
'env stream'(write(user_output)).
'env stream'(error(user_error)).
'env stream'(trace(user_error)).

'env file'(size(1023)).		% pick up from PATH_MAX
'env file'(host(_)) :- fail.
'env file'(device(_)) :- fail.
'env file'(directory(255)).	% use 14 on System V
'env file'(depth(128)).
'env file'(name(255)).		% use 14 on System V
'env file'(type(253)).		% use 12 on System V
'env file'(base(255)).		% use 14 on System V
'env file'(version(_)) :- fail.

'env type'(source,	'pl').		% Use ".pl" extension for source code
'env type'(object,	'qof').		% Use ".qof" extension for compiled
'env type'(log,		'log').		% use for log files
'env type'(options,	'ini').		% Not the real BSD convention...

end_of_file.

		Description of features.

os(OsName)

	OsName is an atom which identifies the "operating system".
	Really what it identifies is the file system.  Current
	values are
	    unix	BSD, SysV, POSIX, Ultrix, any of them.
	    vms		VAX/VMS 3.x, 4.x, 5.x
	    cms		IBM VM/CMS Release 4, 5, 6
	    mvs		IBM MVS
	    mac		Macintosh 128k (117) ROM or later
	    msdos	MS-DOS 3.x
	There are major differences between releases of some of
	these operating systems.  For example, an extension can
	be 39 characters in VMS 4.x, but only 3 in 3.x, and the
	CMS operating system didn't get directories until R6.
	Such differences are supposed to be covered by other
	environment parameters.

	Currently this parameter also serves to identify the
	character set:
	    unix	ISO 8859/1
	    vms		DEC MNCS (like ISO 8859 but has OE ligatures)
	    cms		EBCDIC
	    mvs		EBCDIC
	    mac		Mac extension of ASCII
	    msdos	PC extension of ASCII
	It is possible to discriminate these another way:

	(   " " =:= 64 -> ebcdic
	;   is_space(160) ->		% unbreakable space
	    (   is_alpha(215) -> mncs	% OE ligature in DEC MNCS
	    ;   iso_8859_1		% x (multiply) in ISO 8859/1
	    )
	;   is_alpha(160) -> pc		% a-acute
	;   mac				% obelus
	)

	Neither of these ways of discovering the character set is
	satisfactory.  In a networked system, each different stream
	may be associated with a different character set.  Some better
	method of determining the character set must be found; for the
	moment environment(os(_)) is all we have.  (Note also that
	Quintus support Kanji under both UNIX and VMS.)

	We really ought to have some way of entering accented characters,
	\'e would be nice (Yay, TeX!) but we already want \' and \" for
	another reason.  \:<char><accent> might not be too bad, and use
	\:<sym><sym> for other things, then we might have ISO 8859/1:

	\:sp	\:!!	\:c/	\:##	\:$$	\:Y=	\:||	\:se
	\:""	\:co	\:a_	\:<<	\:~~	\:--	\:tm	\:__
	\:oo	\:++	\:2_	\:3_	\:''	\:mi	\:pp	\:..	
	\:,,	\:1_	\:o_	\:>>	\:14	\:12	\:34	\:??

	\:A`	\:A'	\:A^	\:A~	\:A"	\:Ao	\:AE	\:C,
	\:E`	\:E'	\:E^	\:E"	\:I`	\:I'	\:I^	\:I"
	\:D/	\:N~	\:O`	\:O'	\:O^	\:O~	\:O"	\:OE
	\:O/	\:U`	\:U'	\:U^	\:U"	\:Y'	\:TH	\:ss

	\:a`	\:a'	\:a^	\:a~	\:a"	\:ao	\:ae	\:c,
	\:e`	\:e'	\:e^	\:e"	\:i`	\:i'	\:i^	\:i"
	\:d/	\:n~	\:o`	\:o'	\:o^	\:o~	\:o"	\:oe
	\:o/	\:u`	\:u'	\:u^	\:u"	\:y'	\:th	\:y"

	(\:OE and \:oe are DEC MNCS; the ISO characters are the
	times (x) \:** and divide (-:-) \:// symbols.)  I'm not crazy
	about this, but at least it would give us a way of writing a
	string like "Base de donn\:e'es" in a way which would port
	between VMS, Mac, and PC, despite the incompatible character sets.
	(It would even make English words like "re\:i"nforce" portable...)

dialect(Dialect)

	This is a ground term naming the dialect of Prolog you are
	using.  If two Prolog systems have different syntax, or have
	different sets of built in predicates (where one is not a
	subset of the other), they should be regarded as different
	dialects.  Note that the presence or absence of some major
	feature is not enough to warrant classification as different
	dialects:  I classify lpa(pc) and lpa(mac) as different
	dialects not because one has a module system and the other
	has none but because of differences in things like length/2,
	is/2, :- dynamic declarations, input-output, ...  The values
	currently defined for this enquiry are

	quintus		Quintus Prolog (including Xerox Quintus Prolog)
	sicstus		SICStus Prolog
	lpa(pc)		LPA Prolog Professional
	lpa(mac)	LPA MacProlog
	arity		Arity/Prolog

version(Version)

	This is a list of constants saying which release of the dialect
	you have.  It will be a proper list if and only if the release
	is a full "customer" release; Alpha, Beta, ... releases will
	end with 'Alpha', 'Beta', ... instead of [] (nil).  The list is
	such that later releases are @> than earlier ones.

atom(_)

	Ideally, there is a one to one correspondence between atoms
	and character strings.  An implementation may impose limits
	on atoms.  These are the limits I have thought of:

    atom(size(LengthInBytes))

	How long may an atom be?  In any reasonable Prolog, we will
	have
	    environment(file(size(FS))) & environment(atom(size(AS)))
	    => AS >= FS
	Note that this limit applies separately to each atom; if an
	implementation imposes some limit on the number of atoms it
	is possible that a smaller number of atoms each of them the
	maximum length may exhaust some other resource.

    atom(min(CharCode))

	I assume that the set of character codes which may appear in
	an atom is a consecutive sequence of integers.  This is the
	smallest character code which may reliably be used.  There's
	some point to it because Quintus Prolog rejects NUL codes in
	atom names (but not lists of character codes) but others may
	not have this restriction.  Some versions of LPA Prolog will
	let you include NUL bytes in atoms, but do not handle them
	correctly in C.  Such implementations should set the lower
	limit to 1.  The point of this parameter is to tell programs
	"you can _rely_ on putting this character in an atom".

    atom(max(CharCode))

	This is the greatest character code which may reliably be
	used in an atom name.  Although one normally expects that
	the limit will be 255 in eight-bit character sets, it may
	be that some non-ISO-8859 system has a reason to keep the
	limit lower.  (Is the "EO" value really legal in MVS?)

	Armed with these two numbers, we can define

	char_atom(Char, Atom) :-
	    (	atom(Atom) ->
		atom_chars(Atom, [Char])
	    ;   var(Atom) ->
		environment(atom(min(Min))),
		environment(atom(max(Max))),
		between(Min, Max, Char),
		atom_chars(Atom, [Char])
	    ).

    atom(number(MaxAtoms))

	If an implementation has a limit on the total number of atoms
	current at any one time other than storage limits, this is the
	number.  It should be guaranteed that a Prolog program which
	creates the atoms [min]..[max], [min,min]..[min,max]..[max,max]
	and so on can reach this limit before exhausting any other
	limit.  It may be possible for a program to exceed this limit.
	The main reason for making this limit available is so that a
	portable program can refuse _early_ to do something that is
	obviously not going to fit.  For example, producing a list of
	all the Kanji as atoms is not going to work if you can only
	have a couple of thousand atoms.

	If there is no such limit, this enquiry just fails quietly.
	It is not clear to me whether Quintus Prolog ought to define
	environment(atom(number(16'200000))) or leave it undefined;
	I cannot imagine a program actually running into that limit
	(because the symbol table would have the system thrashing a
	lot sooner than that...)

	In LPA Prolog Professional on the PC, a term which is an atom
	has an 8-bit tag and a 16-bit "segment address" pointing to the
	information about the atom.  That means that there is an
	architectural limit of 2**16 atoms.  Also, all atoms are stored
	in "text space", which the implementation limits to 128k, and
	an atom takes a minimum of 16 bytes (more than Quintus Prolog...)
	so the implementation limit is ((128/16)*1024) = 8192.  Later
	versions may perhaps raise that limit.


    atom(width(LengthInChars))

	The greatest number of characters that can be required to
	write out an atom with full quoting, assuming a sufficiently
	large output line.  In Quintus Prolog this is currently
	2 + 4*size, because each character might be \ooo for some
	octal digits ooo.

	To determine the width required for any particular atom, use
	print_length(writeq(TheAtom), ItsWidth).

string(_)

	These limits apply to a string data type which a Prolog program
	can distinguish from both atoms and lists of character codes,
	such as Xerox Quintus Prolog and Arity Prolog provide.  In a
	Prolog system without them, they all fail.

    string(size(LengthInBytes))
    string(min(CharCode))
    string(max(CharCode))
    string(width(LengthInChars))

	These have the same meaning as the corresponding limits for atoms.
	If strings are provided, these limits should be no more restrictive
	than the atom limits.  There is no string(number(_)) limit; the
	only limit should be the amount of storage needed for all the
	strings retained at any one time.

integer(_)

	These enquiries define the properties of integer arithmetic.

    integer(size(SizeInBits))

	How many bits there are in an integer.  It is likely that a
	future version of Quintus Prolog will support "bignums", but
	they will be limited in size to 64kbytes, so we might then
	define environment(integer(size(5000000))) or so.  Even on
	the Xerox D-machines, the practical limit is well below
	10,000,000 bits (if all of a D-machine's memory were one
	bignum, it would be about 80 million bits).  This is a rather
	large limit, but 300,000! is comparable to our future limit.

	If you know the ELEFUNT subroutine 'i1mach', this is similar
	to IMACH(5).

    integer(small(MinInt))

	If a Prolog system has a foreign interface, this is the most
	negative integer which can both be held as a Prolog integer
	and passed directly to the foreign languages as a "plain"
	integer.  In a Prolog/Lisp system, this would correspond to
	most-negative-fixnum.  In a Prolog/C system this would
	correspond to MINLONG.  In a Prolog/Fortran system, this
	would be either -IMACH(9) or -1-IMACH(9).  If a Prolog
	system has no foreign interface, then it may be any integer
	such that arithmetic operations all of whose operands and
	results are in the closed interval [MinInt,MaxInt] are
	correct.

    integer(large(MaxInt))

	The largest plain foreign integer; most-positive-fixnum,
	MAXLONG, or IMACH(9).

    integer(width(LengthInChars))

	How many characters may be required to write a Prolog integer
	(not necessarily a foreign "plain" integer), assuming a
	sufficiently long output line.  At present this is pretty small,
	but if/when we provide bignums, it could be over 150,000.
	To determine the width of any particular integer, do
	print_length(writeq(TheInteger), ItsWidth)

    integer(too_big(Action))

	What happens if you try to read an integer which is too big
	to be represented as an integer, or if you call number_chars/2
	with a list of character codes which represent an integer
	which is too big to be so represented?  (name/2 should do the
	same as number_chars/2; oversize integer names should not be
	converted to atoms.)  Some possibilities are

	too_big(truncate)
		Map the number into the representable range by
		taking the bottom size() bits.  The tokeniser might
		or might not print a warning, number_chars/2 will not.

	too_big(limit)
		Map the number into the representable range by
		taking large() or small() as appropriate.  The
		tokeniser might or might not print a warning,
		number_chars/2 and name/2 will not.

	too_big(float)
		Use the floating-point number nearest in value instead.
		The tokeniser might or might not print a warning.
		number_chars/2 and name/2 will not.
		If the number is too big for floating-point representation
		as well, see environment(float(too_big(_))).

	too_big(error)
		When reading, report a syntax failure.
		number_chars/2 and name/2 report a representation fault.
		This is the preferred method.

    integer(overflow(Action))

	If a program tries to compute an integral value, whether by
	using arithmetic expressions or by using special predicates
	(succ/2, plus/3, or similar), and that value is too big to
	be represented as a Prolog integer, what happens?

	overflow(truncate)
	overflow(limit)
	overflow(float)
	overflow(error)

		These are the same as the corresponding actions for
		too_big(_).  It is possible that they might be different.
		'error' is the preferred method.

float(_)

	These parameters describe the properties of floating-point
	arithmetic.  Most of them are described in my document on
	standardising Prolog floating-point arithmetic.

    float(size(X))

	The size of a floating-point number in bits.  This ought to
	be recoverable from environment(float(machine(format(_)))),
	but is included for cuteness.

    float(width(LengthInChars))

	How many characters may be required to write a floating-point
	number with enough digits to read it back correctly?  (Assume
	sufficiently long output lines.)  To determine the width of
	any particular floating-point number, do
	print_length(writeq(TheFloat), ItsWidth)
	Note that write/1 may round floating-point numbers off to a
	small number of digits (perhaps under the programmer's control),
	but writeq/1 is supposed to identify the number completely.

    float(too_big(Action))

	This is like integer(too_big(Action)), except that (a) 'float'
	is not a possible action, and (b) 'infinity' means that numbers
	which are too large are converted to IEEE 754 (or IEEE-like)
	infinities of the appropriate sign, while 'limit' means that
	numbers are converted to the large finite float with the
	appropriate sign.  'infinity' should never be claimed on machines
	like the VAX or /370 which do not have IEEE-like infinities.

	'truncate' _is_ a possible value; it means that the number
	wraps around in some way (typically the binary exponent is
	truncated to N bits for some N).  The preference order is
	error (best) > infinity > limit > truncate (worst).

    float(overflow(Action))

	This is like integer(overflow(Action)) with the same differences
	as float(too_big(_)).

    NOTE.
	There are other things one might test, e.g.
	float(too_small(truncate | zero | error))
	float(underflow(truncate | zero | error))
	If underflow is forced to 0.0 and float(confounded), the result
	of an underflow might be an integer 0 (strongly disapproved of).
	In fact, the IEEE 754 standard distinguishes between five kinds
	of exceptional condition.  Before doing anything about that, we
	should settle the "elementary transcendental function" question.

arity(_)

	These are the limits on compound terms.

    arity(functor(N))

	A compound term may have any function symbol and may have as
	many as N arguments.  That is, for any atom S and for any
	integer 0 =< A =< N, the goal functor(_, S, A) must either
	succeed or report a storage overflow, and in the initial
	state of the system it should succeed.  N is not necessarily
	the largest value for which functor/3 will ever work; the
	main property is that you can keep constructing as many terms
	of this size as you want until you run out of storage, without
	crashing the system.

    arity(call(N))

	A compound term used as a goal may have this many arguments;
	which is to say that a Prolog predicate may have this many
	arguments.

    arity(foreign(N))

	If a foreign interface is provided, a foreign function called
	as a Prolog predicate may have this many arguments.  This can
	never be larger than the 'call' limit, but may be smaller.  A
	Prolog system with no foreign interface would fail this query.

stream(X)

	These environment enquiries yield stream identifiers (things
	that can be given as first argument to read/2 or write/2).

    stream(read(X))

	X names the stream that read/1 gets its input from if you have
	not redirected it using see/1, set_input/1, stdin/2, stdinout/3,
	with_input_from_stream/2, or any other such method.
	A common name for this is "the standard input stream"
	Note that LPA MacProlog is exceptional in not accepting this
	stream as an argument for get0/2.
    
	The equivalent of *standard-input* in Common Lisp.

    stream(write(X))

	X names the stream that write/1 sends its output to if you
	have not redirected it using tell/1, set_output1, stdout/2,
	stdinout/3, with_output_to_stream/2, or any such method.
	A common name for this is "the standard output stream".

	The equivalent of *standard-output* in Common Lisp.

    stream(error(X))

	X names the stream that the system sends error messages to.
	A common name for this is "the standard error stream".
	There might be something special about this stream; it is
	always a good idea to send error messages there, even if the
	dialect you are using makes it the same as write(_).
	Note that if it is possible to redirect error output, there
	should be a current_error/1 predicate or some such method
	of determining the current binding; _this_ enquiry tells you
	the _initial_ binding.

	The equivalent of *error-output* in Common Lisp.

    stream(trace(X))

	X names the stream that the debugger sends tracing output to.
	A common name for this is "the standard debugger stream".
	There might be something special about this stream.
	Tracing messages should be sent to it.
	Note that if it is possible to redirect debugger output, there
	should be a current_debug/1 predicate or some such method
	of determining the current binding; _this_ enquiry tells you
	the _initial_ binding.

	The equivalent of *trace-output* in Common Lisp.

    NOTE.
	An earlier draft used the names "input, output, error, debug"
	where I now have "read, write, error, trace".  Input and output
	have been renamed (a) to avoid introducing new atoms, and (b)
	to make it clearer exactly what they do.  stream(read(X)) _is_
	valid for read/2 in LPA MacProlog but is _not_ generally valid
	for other sorts of input.  Debug has been renamed (a) to fit
	the Common Lisp model better, and (b) because the debugger
	needs an INPUT stream as well as an OUTPUT stream, and the
	value currently assigned to stream(trace(X)) is not usable as
	an input stream in Quintus Prolog, LPA Prolog Professional, or
	LPA Mac Prolog ('Sigma Error Log').

	Common Lisp has three other standard streams:
	*query-io*		for asking questions of the user
	*debug-io*		for interactive debugging
	*terminal-io*		the user's console.
	We can't model those directly.  For example, LPA Prolog
	Professional can do I/O in program-controlled windows, but
	it uses the same input stream for all such windows.  We would
	have to model these things as pairs, perhaps
	stream(query(Input,Output))
	stream(debug(Input,Output))
	stream(terminal(Input,Output))	\ these two pairs are not
	stream(standard(Input,Output))	/ necessarily identical!
	But that is definitely for the future.

file_name(X)

    These options are described in filename.txt.
    They give limits on the sizes of parts of file names, and if some
    system does not support a particular part, indicate that by not having
    a limit.

file_type(Category, Atom)

    This table maps ``abstract'' file types to the extensions or types which
    are used on the particular operating system.  The types currently listed
    are
	source		-- Prolog source code
	object		-- Prolog object code
	log		-- log/transcript file
	options		-- "init", "profile", or "options" file
    This table is definitely likely to be revised.  In particular, CMS
    uses the back-to-front convention of
	PROFILE.program
    instead of the usual
	program.INI
    or equivalent.  There is also the ambiguity on the Macintosh that we
    really want this to be a four-letter magic code, but LPA actually use
    a .extension for one of these cases.  On the Mac, this environment
    feature just quietly fails, which is a reasonable way of indicating that
    the distinction must be drawn by changing the name.


%   environment(Feature)
%   VAX/VMS version of the environment table.

environment(os(vms)).
environment(dialect(quintus)).
environment(version([2,4])).
environment(atom(X))		:- 'env atom'(X).
environment(string(_))		:- fail.
environment(integer(X))		:- 'env integer'(X).
environment(float(X))		:- 'env float'(X).
environment(float(single,X))	:- 'env float'(X).
environment(arity(X))		:- 'env arity'(X).
environment(stream(X))		:- 'env stream'(X).
environment(file_name(X))	:- 'env file'(X).
environment(file_type(T,W))	:- 'env type'(T, W).

%   The numbers for 'env float' should be changed, but I haven't worked
%   out what they are for the VAX.  My present belief is that the VAX
%   double floats are just about as good as IEEE except for the exponent
%   range.  Note that there is no need for an environment feature to tell
%   whether -0.0 is distinguished from +0.0, just check whether
%	-0.0 == 0.0		-- they are not distinguished
%	-0.0 \==0.0		-- they are distinguished
%   Note that IBM 370s allow -0.0 in storage and in a register, but the
%   floating-point operations do not distinguish them.

'env file'(size(255)).
'env file'(host(15)).		% (not including "access control")
'env file'(device(253)).	% logical device names can be this long
'env file'(directory(39)).
'env file'(depth(8)).
'env file'(name(39)).
'env file'(type(39)).
'env file'(base(79)).
'env file'(version(6)).		% -#####

'env type'(source,	'PL').
'env type'(object,	'QOF').
'env type'(log,		'LST').
'env type'(options,	'INI').


%   environment(Feature)
%   VM[370]/CMS version of the environment table.

environment(os(cms)).
environment(dialect(quintus)).
environment(version([1,5])).
environment(atom(X))		:- 'env atom'(X).
environment(string(_))		:- fail.
environment(integer(X))		:- 'env integer'(X).
environment(float(X))		:- 'env float'(X).
environment(float(single,X))	:- 'env float'(X).
environment(arity(X))		:- 'env arity'(X).
environment(stream(X))		:- 'env stream'(X).
environment(file_name(Feature)) :- 'env file'(Feature).
environment(file_type(T, W))	:- 'env type'(T, W).

'env file'(size(171)).
'env file'(host(8)).
'env file'(device(1)).
'env file'(directory(16)).
'env file'(depth(8)).
'env file'(name(8)).
'env file'(type(8)).
'env file'(base(17)).
'env file'(version(_)) :- fail.	% mode number NOT counted here!

'env type'(source,	'PROLOG').
'env type'(object,	'QOF').
'env type'(log,		'LISTING').
'env type'(options,	'PROFILE').

%   environment(Feature)
%   MS-DOS 3.x version of the environment table.
%   This version is written for LPA Prolog Professional 2.6,
%   which does not do full first argument indexing, and does have
%   "function-symbol meta-variables".

environment(file_type(T, W))	:- 'env type'(T, W).
environment(C(V)) :- !,
	environment(C, V).

environment(os,		msdos).
environment(dialect,	lpa(pc)).
environment(version,	[2,6]).
environment(atom,	C(V))	:- 'env atom'(C, V).
environment(string,	C(V))	:- fail.
environment(integer,	C(V))	:- 'env integer'(C, V).
environment(float,	X)	:- 'env float'(X).
environment(arity,	C(V))	:- 'env arity'(C, V).
environment(stream,	C(V))	:- 'env stream'(C, V).
environment(file_name,	C(V))	:- 'env file'(C, V).

'env atom'(size,    122).
'env atom'(min,       0).	% Maybe it is really 1
'env atom'(max,     255).
'env atom'(width,     X)	:- X is 122*2 + 2.
'env atom'(number, 8192).

'env integer'(small,        X)	:- X is -16384*2.
'env integer'(large,        X)	:- X is 32767.
'env integer'(size,        16).
'env integer'(too_big,  float).
'env integer'(overflow, float).
'env integer'(width,        6).

'env float'(confounded).
'env float'(C(V)) :- !,
	'env float'(C, V).

'env float'(size,      64).
'env float'(too_big,  error).	% NOT a syntax error, internal routine bombs
'env float'(overflow, error).
'env float'(b,          2).
'env float'(p,         52).	% AS MEASURED BY "PARANOIA"
'env float'(pi, 3.141592653589793238462643).	% ROUNDED BY COMPILER!
'env float'(width,     22).	% measured, may not be right
'env float'(mark, 69 /* E */).
'env float'(radix,      2).
'env float'(mantissa,  52).	% AS MEASURED BY "PARANOIA"

'env stream'(input,  'BUF:').
'env stream'(output, 'WND:').
'env stream'(error,  '&:').
'env stream'(trace,  'DEBUG:').

'env file'(size,	65).	% 63 + "x:"
'env file'(host,	 _) :- fail.
'env file'(device,	 1).
'env file'(directory,	12).	% 8.3 format is possible
'env file'(depth,	 8).	% another document says 7
'env file'(name,	 8).
'env file'(type,	 3).
'env file'(base,	12).
'env file'(version,	 _) :- fail.

'env type'(source,	'DEC').
'env type'(object,	'PRO').
'env type'(log,		'LOG').
'env type'(options,	'INI').


%   environment(Feature)
%   Macintosh HFS version of the environment table.
%   This version is written for LPA MacProlog 2.5,
%   which does not do full first argument indexing, and does have
%   "function-symbol meta-variables".

environment(file_type(T, W))	:- 'env type'(T, W).
environment(C(V)) :- !,
	environment(C, V).

environment(os,		mac).
environment(dialect,	lpa(mac)).
environment(version,	[2,5]).
environment(atom,	C(V))	:- 'env atom'(C, V).
environment(string,	C(V))	:- fail.
environment(integer,	C(V))	:- 'env integer'(C, V).
environment(float,	X)	:- 'env float'(X).
environment(arity,	C(V))	:- 'env arity'(C, V).
environment(stream,	C(V))	:- 'env stream'(C, V).
environment(file_name,	C(V))	:- 'env file'(C, V).

'env atom'(size,   255).
'env atom'(min,      0).	% Maybe it is really 1
'env atom'(max,    255).
'env atom'(width,    X)		:- X is 255*2 + 2.
'env atom'(number, 32768).	% May be too large.

'env integer'(small,        X) :- X is (-1) << 23.
'env integer'(large,        X) :- X is (-1) - ((-1) << 23).
'env integer'(size,        24).
'env integer'(too_big,  float).
'env integer'(overflow, float).
'env integer'(width,        6).

'env float'(confounded).
'env float'(C(V)) :- !,
	'env float'(C, V).

'env float'(size,        80).
'env float'(too_big,  error).
'env float'(overflow, error).
'env float'(b,            2).
'env float'(p,           64).	% NOT MEASURED
'env float'(pi, 3.141592653589793238462643).	% ROUNDED BY COMPILER!
'env float'(width,  	  _) :- fail.	% It's *BROKEN*
'env float'(mark,        69).	% character code of `E`
'env float'(radix,        2).
'env float'(mantissa,    64).	% NOT MEASURED

'env file'(size,	255).
'env file'(host,	  _) :- fail.
'env file'(device,	 27).
'env file'(directory,	 31).
'env file'(depth,	126).		% supposedly no limit
'env file'(name,	 31).
'env file'(type,	  _) :- fail.
'env file'(base,	 31).
'env file'(version,	  _) :- fail.

%   environment(Feature)
%   SICStus Prolog BSD Unix version of the environment table.

/*  Note: most of these facts have been checked against SICStus 0.6 (Feb '89).
    The behaviour of floating-point arithmetic is machine-dependent.
    The figures quoted below have been checked (if at all) ONLY on a Sun-3.
    IEEE denormalised numbers are NOT ``model numbers'', so don't be
    surprised by the value of sigma.
*/
environment(os(unix)).
environment(dialect(sicstus)).
environment(version([0,6])).
environment(atom(X))		:- 'env atom'(X).
environment(string(_))		:- fail.
environment(integer(X))		:- 'env integer'(X).
environment(float(X))		:- 'env float'(X).
environment(float(single,X))	:- 'env float'(X).
environment(arity(X))		:- 'env arity'(X).
environment(stream(X))		:- 'env stream'(X).
environment(file_name(X))	:- 'env file'(X).
environment(file_type(T,W))	:- 'env type'(T, W).

'env atom'(size(512)).
'env atom'(min(1)).
'env atom'(max(255)).
'env atom'(width(X))		:- X is 512*4 + 2.
'env atom'(number(X))		:- X is 1 << 21.	% BOGUS.

'env integer'(size(32)).
'env integer'(small(X))		:- X is -1 << 31.
'env integer'(large(X))		:- X is -1 - (-1 << 31).
'env integer'(width(11)).
'env integer'(too_big(truncate)).
'env integer'(overflow(truncate)).

'env float'(size(64)).
'env float'(too_big(infinity)).		% prints as 1.0e1000, NASTY.
'env float'(overflow(infinity)).
'env float'(confounded)		:- fail.
'env float'(b(2)).
'env float'(p(53)).
'env float'(emin(-1021)).
'env float'(emax( 1024)).
'env float'(sigma(X))		:- scale(-1022, 1.0, X).
'env float'(lambda(X))		:- scale(52, 1.0, Y), Z is (Y-1)+Y,
				   scale(971, Z, X).  % (2**53-1)*2**(1024-53)
'env float'(epsilon(X))		:- scale(-18, 1.0, X).
'env float'(max_integer(X))	:- scale(52, 1.0, Y), X is (Y-1)+Y.
'env float'(min_integer(X))	:- scale(52, 1.0, Y), X is (1-Y)-Y.
'env float'(pi(3.141592653589793238462643)).	% ROUNDED BY COMPILER!
'env float'(digits(16)).
'env float'(width(22)).
'env float'(mark(0'e)).
'env float'(radix(2)).
'env float'(mantissa(53)).
'env float'(small(X))		:- scale(-1022, 1.0, X).
'env float'(large(X))		:- scale(52, 1.0, Y), Z is (Y-1)+Y,
				   scale(971, Z, X).  % (2**53-1)*2**(1024-53)
'env float'(machine(X))		:- 'env mac'(X).

scale(N, X0, X) :-
    (	N >= 4 -> X1 is X0 * 16.0,   N1 is N-4, scale(N1, X1, X)
    ;   N=< -4 -> X1 is X0 * 0.0625, N1 is N+4, scale(N1, X1, X)
    ;	N >  0 -> X1 is X0 * 2.0,    N1 is N-1, scale(N1, X1, X)
    ;   N <  0 -> X1 is X0 * 0.5,    N1 is N+1, scale(N1, X1, X)
    ;   X is X0
    ).

'env mac'(b(2)).
'env mac'(radix(2)).
'env mac'(rounds).
'env mac'(overflows)		:- fail.
'env mac'(format(ieee(double))).

'env arity'(functor(255)).
'env arity'(call(255)).
'env arity'(foreign(255)).		% copied

'env stream'(read( user_input)).
'env stream'(write(user_output)).
'env stream'(error(user_error)).
'env stream'(trace(user_error)).

'env file'(size(1023)).		% pick up from PATH_MAX
'env file'(host(_)) :- fail.
'env file'(device(_)) :- fail.
'env file'(directory(255)).	% use 14 on System V
'env file'(depth(128)).
'env file'(name(255)).		% use 14 on System V
'env file'(type(253)).		% use 12 on System V
'env file'(base(255)).		% use 14 on System V
'env file'(version(_)) :- fail.

'env type'(source,	'pl').		% Use ".pl" extension for source code
'env type'(object,	'ql').		% Use ".ql" extension for compiled
'env type'(log,		'log').		% use for log files
'env type'(options,	'ini').		% Not the real BSD convention...

end_of_file.

