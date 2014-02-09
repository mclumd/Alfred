/*
  SCCS: @(#)ls1.pl	70.1 01/26/94
  File: ls1.pl

    ls1_print(Arg) prints information about files matching the atom
    argument it is given.  The Arg must be of the form <pattern> or
    <path>/<pattern> where <path> does not contain any wildcard
    characters, and <pattern> does not contain any '/' characters.
    The wildcard characters that may appear in pattern are '?', which
    matches any character, and '*' which matches any sequence of
    characters.  Multiple wildcards are permitted.

    This version of the package uses no C code.  It does it all in
    Prolog except for some calls to Unix library routines.  

    Note: To set up the links to the library routines required a call
    to load_foreign_files which requires the existence of a foreign
    file, so an empty file ls1.c was created (and compiled with cc).

*/

:- module(ls1, [
        ls1_print/1
   ]).

/*
    Imports
*/
:- use_module(ls, [
        parse_target/3,
        match_target/3,
        mode_text/3
   ]).

/*
    This is the standard way to import the structs package.  See the
    reference manual for why its not just use_module(library(structs)).
*/
:- load_files(library(structs_decl), [when(compile_time), if(changed)]).
:- ensure_loaded(library(structs)).

/*
    Struct definitions for Unix data structures.

    In the case of the dir (directory) structure, we simply declare it
    opaque because we don't need to look inside it in this program.
    opendir returns a pointer to a dir, and that pointer is passed to
    readdir and closedir.
*/
:- foreign_type

	dir = opaque,

        dirent = struct([ % derived from /usr/include/sys/dirent.h
            d_off:      integer,
            d_fileno:   unsigned_integer,
            d_reclen:   unsigned_short,
            d_namlen:   unsigned_short,
            d_name:     array(256,char)
        ]),

        stat = struct([  % derived from /usr/include/sys/stat.h
            st_dev:     short,
            st_ino:     unsigned_integer,
            st_mode:    unsigned_short,
            st_nlink:   short,
            st_uid:     unsigned_short,
            st_gid:     unsigned_short,
            st_rdev:    short,
            st_size:    integer,
            st_atime:   integer,
            st_spare1:  integer,
            st_mtime:   integer,
            st_spare2:  integer,
            st_ctime:   integer,
            st_spare3:  integer,
            st_blksize: integer,
            st_blocks:  integer,
            st_spare4:  array(2,integer)
        ]).

foreign(opendir, opendir(+string, [-pointer(dir)])).
foreign(closedir, closedir(+pointer(dir), [-integer])).
foreign(readdir, readdir(+pointer(dir), [-pointer(dirent)])).
foreign(lstat, lstat(+string, +pointer(stat), [-integer])).

foreign_file(ls1, [
    opendir,
    closedir,
    readdir,
    lstat
]).

:- load_foreign_files(ls1, []).

/*
    ls1_print(+Atom)

    Print information about all files matching Arg.  
*/
ls1_print(Arg) :-
	parse_target(Arg, Path, Target),
	opendir(Path, Dir),
	\+ null_foreign_term(Dir, dir),
	new(stat, Stat),
	print_loop(Dir, Target, Stat),
	closedir(Dir, CloseStatus),
	dispose(Stat),
	CloseStatus =:= 0.

print_loop(Dir, Target, Stat) :-
	next_match(Dir, Target, Stat, FileInfo),
	!,
	print_line(FileInfo),
	print_loop(Dir, Target, Stat).
print_loop(_, _, _).

print_line(file_info(Mode,Uid,Gid,Size,Name)) :-
	format('~s ~|~t~d~4+~t~d~4+~t~d~8+ ~s~n',
	       [Mode,Uid,Gid,Size,Name]
	).

/*
    next_match(+Dir, +Target, +Stat, -FileInfo)

    Returns information about the next file in the directory.  On
    backtracking it successively returns information on each file in
    the directory.
*/
next_match(Dir, Target, Stat, FileInfo) :-
	readdir(Dir, DirEnt),
	\+ null_foreign_term(DirEnt, dirent),
	(    match(DirEnt, Target, Stat, FileInfo)
        ->   true
        ;    next_match(Dir, Target, Stat, FileInfo)
        ).

/*
    match(+DirEnt, +Target, +Stat, -FileInfo)

    Gets the name of a file from DirEnt and tests whether it matches
    the target.  If it does, extracts all the needed data from the 
    DirEnt.  Otherwise, fails.
*/
match(DirEnt, Target, Stat, file_info(Mode,Uid,Gid,Size,Name)) :-
	get_address(DirEnt, d_name, CharArray),
	get_contents(DirEnt, d_namlen, Length),
	array_to_chars(Length, CharArray, Name),
	match_target(Name, Target, Path),
	lstat(Path, Stat, 0),
	get_contents(Stat, st_uid, Uid),
	get_contents(Stat, st_gid, Gid),
	get_contents(Stat, st_size, Size),
	get_contents(Stat, st_mode, ModeBits),
	mode_text(ModeBits, Mode, []).

/*
    array_to_chars(+Length, +CharArray, -Chars)

    CharArray is an array of chars of length Length in C space.
    Builds the corresponding list of chars Chars.
*/
array_to_chars(Length, CharArray, Chars) :-
	generate_chars(0, Length, CharArray, Chars, []).

generate_chars(L, L, _) -->
	!,
	"".
generate_chars(I, L, CharArray) -->
	{ I < L, get_contents(CharArray, I, C) },
	[C],
	{ J is I+1 },
	generate_chars(J, L, CharArray).

