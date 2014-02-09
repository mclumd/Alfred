%   Module : directory
%   Author : Richard A. O'Keefe
%   Updated: 18 Aug 1994
%   Defines: directory scanning routines
%   SeeAlso: directory.c, unix.{c,pl}

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  file_member_of_directory([Directory, [Pattern, ]]Name, Full)
    enumerates file Names in the given Directory which match the
    given Pattern.  The Directory defaults to '.', the current
    directory.  The Pattern defaults to '*', which matches anything.
    It is impossible to supply a Pattern without also supplying a
    Directory.  The Name argument will be unified with a simple
    file name, and the Full argument will be unified with a full
    path name, including the Directory and the Name both.  As a
    special case, a leading ./ will be stripped.  Note that Full
    will be absolute if Directory is absolute, relative if relative.
    This routine only matches visible *file* names.  Even names
    which start with a dot are considered to be visible.

    directory_member_of_directory([Directory, [Pattern, ]]Name, Full)
    is exactly like file_member_of_directory except that it only
    matches visible *directory* names.  Even names which start with
    a dot a considered to be visible, but as a special case to stop
    looping, the names '.' and '..' are NOT matched.
*/

:- module(directory, [
	current_directory/1,
	directory_member_of_directory/2,
	directory_member_of_directory/3,
	directory_member_of_directory/4,
	directory_members_of_directory/1,
	directory_members_of_directory/2,
	directory_members_of_directory/3,
	directory_property/2,
	directory_property/3,
	file_member_of_directory/2,
	file_member_of_directory/3,
	file_member_of_directory/4,
	file_members_of_directory/1,
	file_members_of_directory/2,
	file_members_of_directory/3,
	file_property/2,
	file_property/3
   ]).
:- use_module(library(basics), [
	member/2
   ]).
:- use_module(library(date), [
	date/2,
	datime/2
   ]).
:- use_module(library(errno), [
        file_error/3
   ]).
:- use_module(library(types), [
	must_be_nonneg/3,
	must_be_oneof/4,
	must_be_symbol/3
   ]).
:- mode
	directory_member_of_directory(?, ?),
	directory_member_of_directory(+, ?, ?),
	directory_member_of_directory(+, +, ?, ?),
	directory_members_of_directory(?),
	directory_members_of_directory(+, ?),
	directory_members_of_directory(+, +, ?),
	file_member_of_directory(?, ?),
	file_member_of_directory(+, ?, ?),
	file_member_of_directory(+, +, ?, ?),
	file_members_of_directory(?),
	file_members_of_directory(+, ?),
	file_members_of_directory(+, +, ?),
	'QD'(+, +, +, +, ?, ?),
	'QD'(+, +, +, +, ?),
	'QD'(-),
	directory_property(+, ?),
	directory_property(+, ?, ?),
	file_property(+, ?),
	file_property(+, ?, ?),
	'UNIX decode'(+, +, ?),
	'UNIX property'(+, ?, +, ?, ?, +),
	'UNIX property'(?, +, ?, -),
	'UNIX permission bit'(+, +, +, ?, ?).

sccs_id('"@(#)94/08/18 directory.pl    73.1"').



%   directory_member_of_directory(?ShortName, ?FullName)
%   is true when ShortName is the name of a subdirectory of the current
%   directory (other than '.' or '..') and FullName is its absolute name.

directory_member_of_directory(FileName, FullName) :-
	current_directory(Directory),
	'QD'(Directory, '*', 8'40000, 8'100000, FileName, FullName).


%   directory_member_of_directory(+Directory, ?ShortName, ?FullName)
%   is true when Directory is a name (not necessarily the absolute name)
%   of a directory, ShortName is the name of a subdirectory of that
%   directory (other than '.' or '..') and FullName is its absolute name.

directory_member_of_directory(Directory, FileName, FullName) :-
	'QD'(Directory, '*', 8'40000, 8'100000, FileName, FullName).


%   directory_member_of_directory(+Directory, +Pattern, ?ShortName, ?FullName)
%   is true when Directory is a name (not necessarily the absolute name)
%   of a directory, ShortName is the name of a directory of that
%   directory (other than '.' or '..') which matches the given Pattern,
%   and FullName is the absolute name of the subdirectory.

directory_member_of_directory(Directory, Pattern, FileName, FullName) :-
	'QD'(Directory, Pattern, 8'40000, 8'100000, FileName, FullName).



%   directory_members_of_directory(-Set)
%   is true when Set is a set of ShortName-FullName pairs being the
%   relative and absolute names of subdirectories of the current directory.

directory_members_of_directory(Set) :-
	current_directory(Directory),
	'QD'(Directory, '*', 8'40000, 8'100000, Set).


%   directory_members_of_directory(+Directory, -Set)
%   is true when Set is a set of ShortName-FullName pairs being the
%   relative and absolute names of subdirectories of the given Directory.
%   Directory need not be absolute; the FullNames will be regardless.

directory_members_of_directory(Directory, Set) :-
	'QD'(Directory, '*', 8'40000, 8'100000, Set).


%   directory_members_of_directory(+Directory, +Pattern, -Set)
%   is true when Set is a set of ShortName-FullName pairs being the
%   relative and absolute names of subdirectories of the given Directory,
%   such that each ShortName matches the given Pattern.

directory_members_of_directory(Directory, Pattern, Set) :-
	'QD'(Directory, Pattern, 8'40000, 8'100000, Set).



%   file_member_of_directory(?ShortName, ?FullName)
%   is true when ShortName is the name of a file in the current
%   directory and FullName is its absolute name.

file_member_of_directory(FileName, FullName) :-
	current_directory(Directory),
	'QD'(Directory, '*', 8'100000, 8'40000, FileName, FullName).


%   file_member_of_directory(+Directory, ?ShortName, ?FullName)
%   is true when Directory is a name (not necessarily the absolute name)
%   of a directory, ShortName is the name of a file in that directory,
%   and FullName is its absolute name.

file_member_of_directory(Directory, FileName, FullName) :-
	'QD'(Directory, '*', 8'100000, 8'40000, FileName, FullName).


%   file_member_of_directory(+Directory, +Pattern, ?ShortName, ?FullName)
%   is true when Directory is a name (not necessarily the absolute name)
%   of a directory, ShortName is the name of a file in that directory
%   which matches the given Pattern, and FullName is the absolute name
%   of the subdirectory.

file_member_of_directory(Directory, Pattern, FileName, FullName) :-
	'QD'(Directory, Pattern, 8'100000, 8'40000, FileName, FullName).



%   file_members_of_directory(-Set)
%   is true when Set is a set of ShortName-FullName pairs being the
%   relative and absolute names of the files in the current directory.

file_members_of_directory(Set) :-
	current_directory(Directory),
	'QD'(Directory, '*', 8'100000, 8'40000, Set).


%   file_members_of_directory(+Directory, -Set)
%   is true when Set is a set of ShortName-FullName pairs being the
%   relative and absolute names of the files in the given Directory.
%   Directory need not be absolute; the FullNames will be regardless.

file_members_of_directory(Directory, Set) :-
	'QD'(Directory, '*', 8'100000, 8'40000, Set).


%   file_members_of_directory(+Directory, +Pattern, -Set)
%   is true when Set is a set of ShortName-FullName pairs being the
%   relative and absolute names of subdirectories of the given Directory,
%   such that each ShortName matches the given Pattern.

file_members_of_directory(Directory, Pattern, Set) :-
	'QD'(Directory, Pattern, 8'100000, 8'40000, Set).



'QD'(Directory, '*', Must, Mustnt, FileName, FullName) :-
	nonvar(FullName),
	!,
	Goal = 'QD'(Directory, '*', Must, Mustnt, FileName, FullName),
	must_be_nonneg(Must,      3, Goal),
	must_be_nonneg(Mustnt,	  4, Goal),
	must_be_symbol(FullName,  6, Goal),
	'QDpart'(Directory, Must, Mustnt, FileName, FullName, 0).
'QD'(Directory, Pattern, Must, Mustnt, FileName, FullName) :-
	nonvar(FileName),
	!,
	Goal = 'QD'(Directory, Pattern, Must, Mustnt, FileName, FullName),
	must_be_symbol(Directory, 1, Goal),
	must_be_symbol(Pattern,   2, Goal),
	must_be_nonneg(Must,      3, Goal),
	must_be_nonneg(Mustnt,	  4, Goal),
	must_be_symbol(FileName,  5, Goal),
	'QDtest'(Directory, Pattern, Must, Mustnt, FileName, FullName, 0).
'QD'(Directory, Pattern, Must, Mustnt, FileName, FullName) :-
	Goal = 'QD'(Directory, Pattern, Must, Mustnt, FileName, FullName),
	must_be_symbol(Directory, 1, Goal),
	must_be_symbol(Pattern,   2, Goal),
	must_be_nonneg(Must,      3, Goal),
	must_be_nonneg(Mustnt,	  4, Goal),
	'QDinit'(Directory, Pattern, Must, Mustnt, ErrorCode),
	file_error(ErrorCode, Directory, Goal),
	'QD'(Raw),
	sort(Raw, Set),
	member(FileName-FullName, Set).


'QD'(Directory, Pattern, Must, Mustnt, Set) :-
	Goal = 'QD'(Directory, Pattern, Must, Mustnt, Set),
	must_be_symbol(Directory, 1, Goal),
	must_be_symbol(Pattern,   2, Goal),
	must_be_nonneg(Must,      3, Goal),
	must_be_nonneg(Mustnt,	  4, Goal),
	'QDinit'(Directory, Pattern, Must, Mustnt, ErrorCode),
	file_error(ErrorCode, Directory, Goal),
	'QD'(Raw),
	sort(Raw, Set).


'QD'([File-Full|Raw]) :-
	'QDnext'(File, Full, 0),
	!,
	'QD'(Raw).
'QD'([]).



%   directory_property(+Directory, ?Property)
%   is true when Directory is a name of a directory, and Property is
%   a boolean property which that directory possesses, e.g.
%	directory_property(., searchable).

directory_property(Directory, Property) :-
    	Goal = directory_property(Directory, Property),
	'UNIX property'(Directory, Property, directory, boolean, true, Goal).


%   directory_property(+Directory, ?Property, ?Value)
%   is true when Directory is a name of a directory, Property is a
%   property of directories, and Value is Directory's Property Value.

directory_property(Directory, Property, Value) :-
    	Goal = directory_property(Directory, Property, Value),
	'UNIX property'(Directory, Property, directory, _, Value, Goal).



%   file_property(+File, ?Property)
%   is true when File is a name of a file, and Property is
%   a boolean property which that file possesses, e.g.
%       file_property(., readable).

file_property(File, Property) :-
    	Goal = file_property(File, Property),
	'UNIX property'(File, Property, file, boolean, true, Goal).

%   file_property(+File, ?Property, ?Value)
%   is true when File is a name of a file, Property is a
%   property of files, and Value is File's Property Value.

file_property(File, Property, Value) :-
    	Goal = file_property(File, Property, Value),
	'UNIX property'(File, Property, file, _, Value, Goal).

/*  'UNIX property'(NameOfFileOrDirectory
	    ,Property
	    ,FileOrDirectory
	    ,PropertyType
	    ,TheValueDesiredOrReturned,
	    Goal)
    checks whether there is an entity in the file system named by
    NameOfFileOrDirectory.  If the third parameter is 'file', it insists
    that the thing must be a file, if it is 'directory', it insists that
    the thing must be a directory.  The Property and PropertyType
    arguments say what we want to know: the two-argument queries pass
    PropertyType in as boolean to ensure that only boolean properties
    are considered, otherwise a variable is passed.
*/

'UNIX property'(Thing, Property, ThingType, PropertyType, Value, Goal) :-
	must_be_symbol(Thing, 1, Goal),
	must_be_oneof(ThingType, [file,directory], 3, Goal),
	(   var(Property) -> true
	;   'UNIX property'(Property, ThingType, PropertyType, Index) -> true
	;   ( PropertyType = known -> true ; true ),
	    raise_exception(
                domain_error(Goal,2,property,Property,0))
	),
	'UNIX property'(Property, ThingType, PropertyType, Index),
	'QDprop'(Thing, ThingType, Index, Val, ErrorCode),
	file_error(ErrorCode, Thing, Goal),
	'UNIX decode'(PropertyType, Val, Value).

:- multifile 'QU_messages':typename/3.
'QU_messages':typename(property) --> ['file or directory property'-[]].


'UNIX decode'(boolean, L, Value) :-
	( L/\1 =:= 0 -> Value = false ; Value = true ).
'UNIX decode'(integer, N, N).
'UNIX decode'(who, B, L0) :-
	'UNIX permission bit'(8'100, B, user,  L0, L1),
	'UNIX permission bit'(8'010, B, group, L1, L2),
	'UNIX permission bit'(8'001, B, other, L2, []).
'UNIX decode'(user, Id, Name) :-
	'QDname'(Id, 0, Name, 0).
'UNIX decode'(group, Id, Name) :-
	'QDname'(Id, 1, Name, 0).
'UNIX decode'(date, When, Date) :-
	date(When, Date).
'UNIX decode'(time, When, Datime) :-
	datime(When, Datime).


'UNIX permission bit'(Bit, Mask, Word, [Word|L], L) :-
	Mask/\Bit =\= 0,
	!.
'UNIX permission bit'(_, _, _, L, L).


/*  The indices chosen for the following four properties
    are the parameters R_OK=4, W_OK=2, X_OK=1 given to the
    UNIX routine access(2).  This is a bit of a hack, but
    at least you know about it.  Indices 0..9 are reserved
    for calls to access(2).  The rest use stat(2).
*/

'UNIX property'(readable,	_,		boolean, 4).
'UNIX property'(writable,	_,		boolean, 2).
'UNIX property'(executable,	file,		boolean, 1).
'UNIX property'(searchable,	directory,	boolean, 1).


/*  The "date" and "time" indices are the same; we get the
    same number back from QDprop.  The difference is in what
    we do with it afterwards.  Indices 10..15 are reserved
    timestamps returned from stat(2).
*/

'UNIX property'(access_time,	_,		time, 10).
'UNIX property'(access_date,	_,		date, 10).
'UNIX property'(modify_time,	_,		time, 11).
'UNIX property'(modify_date,	_,		date, 11).
'UNIX property'(create_time,	_,		time, 12).
'UNIX property'(create_date,	_,		date, 12).


/*  Indices 16..31 are reserved for properties obtained by
    shifting the mode right index-16 bits.  Generally, only
    the bottom bit is of interest, but for the who_can_xxx
    properties the bits are 8'111.
*/

'UNIX property'(set_user_id,	 file,		boolean, 27).	% 8'4000
'UNIX property'(set_group_id,	 file,		boolean, 26).	% 8'2000
'UNIX property'(save_text,	 file,		boolean, 25).	% 8'1000
'UNIX property'(who_can_read,	 _,		who,	 18).	% 8'0444
'UNIX property'(who_can_write,	 _,		who,	 17).	% 8'0222
'UNIX property'(who_can_execute, file,		who,	 16).	% 8'0111
'UNIX property'(who_can_search,  directory,	who,	 16).	% 8'0111

/*  The remaining indices, 40..., are miscellaneous.
    Like things are grouped together, but that is all.
*/

'UNIX property'(owner_user_id,	 _,		integer, 40).
'UNIX property'(owner_user_name, _,		user,	 40).
'UNIX property'(owner_group_id,  _,		integer, 41).
'UNIX property'(owner_group_name, _,		group,   41).
'UNIX property'(only_one_link,	 file,		boolean, 42).
'UNIX property'(number_of_links, file,		integer, 43).
'UNIX property'(size_in_bytes,   file,		integer, 44).
'UNIX property'(size_in_blocks,  file,		integer, 45).
'UNIX property'(block_size,	 file,		integer, 46).


/*  ---------------- C routines ----------------  */


foreign_file(library(system(libpl)), [
	'QDinit', 'QDnext', 'QDpart',
	'QDtest', 'QDname', 'QDprop',
	'QDhere'
    ]).

foreign('QDinit', 'QDinit'(+string,+string,+integer,+integer,[-integer])).
foreign('QDnext', 'QDnext'(-string,-string,[-integer])).
foreign('QDpart', 'QDpart'(-string,        +integer,+integer,
			   -string,+string,[-integer])).
foreign('QDtest', 'QDtest'(+string,+string,+integer,+integer,
			   +string,-string,[-integer])).
foreign('QDname', 'QDname'(+integer,+integer,-string,[-integer])).
foreign('QDprop', 'QDprop'(+string,+string,+integer,
			   -integer,[-integer])).
foreign('QDhere', current_directory([-string])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).


