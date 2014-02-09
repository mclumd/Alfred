/*
  SCCS: @(#)ls2.pl	70.1 01/26/94
  File: ls2.pl

    This version of the program provides, in addition to a routine to
    print information about matching files, a routine which returns
    info about each matching file, successively on backtracking.
    Also, instead of using the structs package, it pushes the Unix
    interaction down into the C level (see ls2.c).
*/

:- module(ls2, [
        ls2_print/1, 
	ls2/2
   ]).

/*
    Imports
*/
:- use_module(ls, [
      parse_target/3,
      match_target/3,
      mode_text/3
   ]).


foreign(open_directory, open_directory(+string,-address,-address)).
foreign(next_file, next_file(+address,-atom,[-integer])).
foreign(stat_file, stat_file(+string,-integer,-integer,-integer,-integer,
			     [-integer])).

foreign_file(ls2, [
    open_directory,
    next_file,
    stat_file
]).

:- load_foreign_files(ls2, []).

/*
    ls2_print(+Atom)

    Print information about all files matching Arg.  Arg is of the form
    <pattern> or <path>/<pattern> where <path> does not contain any 
    wildcard characters, and <pattern> does not contain any '/' characters.
    The wildcard characters that may appear in pattern are '?', which 
    matches any character, and '*' which matches any sequence of characters.
    Multiple wildcards are permitted.
*/
ls2_print(Arg) :-
	ls2(Arg, FileInfo),
	print_line(FileInfo),
	fail.
ls2_print(_).

print_line(file_info(Mode,Uid,Gid,Size,Name)) :-
	format('~s ~|~t~d~4+~t~d~4+~t~d~8+ ~a~n',
	       [Mode,Uid,Gid,Size,Name]
	).

/*
    ls2(+Arg,*FileInfo)

    Returns, on backtracking, all the files matching Arg.  The undocumented
    built-in '$Quintus: trail'/2 is used to ensure that things are cleaned
    up when the backtracking is terminated by a cut, an exception, an abort,
    or final failure.
*/
ls2(Arg, FileInfo) :-
	parse_target(Arg, Path, Target),
	open_directory(Path, Dir, CloseFunction),
	Dir =\= 0,
	'$Quintus: trail'(CloseFunction, Dir),
	next_match(Dir, Target, FileInfo).

/*
    next_match(+Dir, +Target, -FileInfo)

    Returns information about the next file in the directory.  On
    backtracking it successively returns information on each file in
    the directory.
*/
next_match(Dir, Target, FileInfo) :-
	next_file(Dir, FileName, 0),
	(    match(Target, FileName, FileInfo)
        ;    next_match(Dir, Target, FileInfo)
        ).

/*
    match(+DirEnt, +Target, +Stat, -FileInfo)

    Gets the name of a file from DirEnt and tests whether it matches
    the target.  If it does, extracts all the needed data from the 
    DirEnt.  Otherwise, fails.
*/
match(Target, Name, file_info(ModeChars,Uid,Gid,Size,Name)) :-
	atom_chars(Name, NameChars),
	match_target(NameChars, Target, Path),
	stat_file(Path, ModeBits, Uid, Gid, Size, 0),
	mode_text(ModeBits, ModeChars, []).

