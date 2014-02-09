/*
  SCCS: @(#)ls.pl	70.1 01/26/94
  File: ls.pl

    ls0.pl, ls1.pl and ls2.pl provide three alternative implementations
    of a routine to print information about files, analogous to the ls
    command in Unix.  The point of these programs is to demonstrate
    different facets of the Quintus Prolog Foreign Language Interface.

    This file, ls.pl, supplies pattern matching routines that are used
    in both ls1.pl and ls2.pl.
*/

:- module(ls, [
      parse_target/3,
      match_target/3,
      mode_text/3
   ]).

:- use_module(library(basics), [
       nonmember/2
   ]).

/*
    parse_target(+Arg, -Path, -Target)

    Parses the atom Arg into the form <path><pattern>.  These are
    combined in the target/2 term to be used later by match_target.
*/
    
parse_target(Arg, Path, target(PathChars,Pattern)) :-
	atom_chars(Arg, ArgChars),
	parse_target_chars(PathChars, Pattern, ArgChars, []),
	!,
	atom_chars(Path, PathChars).

parse_target_chars(".", Pattern) -->
        chars_excluding("/", Pattern).
parse_target_chars(Path, Pattern) -->
	chars_excluding("*?", Path),
	"/",
	chars_excluding("/", Pattern).

chars_excluding(_, []) --> 
	"".
chars_excluding(L, [H|T]) -->
	[H],
	{ nonmember(H, L) },
	chars_excluding(L, T).

/*
    match_target(+Chars, +Target, -PathFile)

    Test whether Chars match Pattern.  If they do, build the path
    to the file identified by Chars.  Otherwise, fail.
*/
match_target(Chars, target(Path,Pattern), PathFile) :-
	match_target_chars(Pattern, Chars, []),
	!,
	append(Path, [0'/|Chars], PathFileChars),
	atom_chars(PathFile, PathFileChars).

match_target_chars([]) -->
	"".
match_target_chars([0'*|T]) -->
	match_target_chars(T).
match_target_chars([0'*|T]) -->
	[_],
	match_target_chars([0'*|T]).
match_target_chars([0'?|T]) -->
	[_],
	match_target_chars(T).
match_target_chars([C|T]) -->
	[C],
	match_target_chars(T).

/*
    mode_text(+ModeBits, -Chars, [])

    Generates the list of chars Chars which represents the modes of the file.
    E.g. "drwxrwxrwx" or "-rw-rw-rw-".
*/
mode_text(ModeBits) -->
	special_mode_bit(ModeBits),
	mode_bit(8'400, 0'r, ModeBits),
	mode_bit(8'200, 0'w, ModeBits),
	mode_bit(8'100, 0'x, ModeBits),
	mode_bit(8'040, 0'r, ModeBits),
	mode_bit(8'020, 0'w, ModeBits),
	mode_bit(8'010, 0'x, ModeBits),
	mode_bit(8'004, 0'r, ModeBits),
	mode_bit(8'002, 0'w, ModeBits),
	mode_bit(8'001, 0'x, ModeBits).

special_mode_bit(ModeBits) -->
	(  { 8'170000 /\ ModeBits =:= 8'040000 } -> "d"
	;  { 8'170000 /\ ModeBits =:= 8'120000 } -> "l"
	;  { otherwise }                         -> "-"
	).
	
mode_bit(Mask, C, ModeBits) -->
	(  { Mask /\ ModeBits =:= Mask } -> [C]
	;  { otherwise }                 -> "-"
	).
