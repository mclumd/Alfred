%   Package: errno
%   Author : Dave Bowen
%   Updated: @(#)errno.pl	71.1 31 Jan 1994
%   Purpose: Reporting file errors

/*
    Previously this file used to be generated from errno.ed which is now
    obsolete.  See errno/2 and fileerrno/2 below for backwards compatibility
    issues.
*/

:- module(errno, [
	file_error/3,
	errno/2,                        % obsolete
	fileerrno/2			% obsolete
   ]).

sccs_id('"@(#)94/01/31 errno.pl	71.1"').

%   file_error(+ErrNo, +File, +Goal)
%   Checks for non-zero Errno and raises an appropriate exception

file_error(Errno, File, Goal) :-
	(   Errno =:= 0 ->
		true
	;   errno_class(Errno, Class) ->
		exception(Class, Errno, File, Goal, Exception),
		raise_exception(Exception)
	;   otherwise ->
		raise_exception(system_error(errno(Errno)))
	).

errno_class(2,	existence).      % ENOENT,	No such file or directory
errno_class(6,	existence).      % ENXIO,	No such device or address
errno_class(9,	existence).      % EBADF,	Bad file number
errno_class(1,	permission).     % EPERM,	Not owner
errno_class(13,	permission).     % EACCES,	Permission denied
errno_class(17,	permission).     % EEXIST,	File exists
errno_class(20,	permission).     % ENOTDIR,	Not a directory
errno_class(21,	permission).     % EISDIR,	Is a directory
errno_class(25,	permission).     % ENOTTY,	Not a typewriter
errno_class(30,	permission).     % EROFS,	Read-only file system
errno_class(26,	permission).     % ETXTBSY,	Text file busy
errno_class(22,	permission).     % EINVAL,	Invalid argument
errno_class(62,	permission).     % ELOOP,	Too many levels of symbolic links
errno_class(63,	permission).     % ENAMETOOLONG,File name too long
errno_class(12,	resource).       % ENOMEM,	Not enough core
errno_class(23,	resource).       % ENFILE,	File table overflow
errno_class(24,	resource).       % EMFILE,	Too many open files
errno_class(28,	resource).       % ENOSPC,	No space left on device
errno_class(11,	resource).       % EAGAIN,	No more processes


exception(permission, Errno, File, Goal,
          permission_error(Goal,access,file,File,errno(Errno))).
exception(existence, Errno, File, Goal,
          existence_error(Goal,0,file,File,errno(Errno))).
exception(resource, Errno, _File, Goal,
          resource_error(Goal,0,errno(Errno))).


/*
    The following predicates are retained for (approximate) backwards
    compatibility only.  Since QP 3.0 introduced exception handling, it
    makes more sense to raise exceptions than to just print messages and
    then (somewhat arbitrarily) either fail or abort.  fileerrno used to
    abort but now raises an exception.  errno still just prints the
    message and fails, in case anyone relies on that behavior.

    errno/3 was documented as not for general use, and it has been 
    deleted.
*/

%   fileerrno(+Error, +Goal) -- obsolete
%
%   checks for a non-zero error code.  If the error code is non-zero,
%   the predicate fails or raises an exception depending on the fileerrors
%   flag.

fileerrno(Errno, Goal) :-
	(   Errno =:= 0 ->
	        true
	;   prolog_flag(fileerrors, off) ->
		fail
	;   otherwise ->
		file_error(Errno, ??, Goal) % ?? - don't know the file name
	).


%   errno(+Errno, +Goal) -- obsolete
%
%   checks for a non-zero error code.  If the error code is non-zero,
%   a message is printed to user_error and the predicate fails.

errno(Errno, Goal) :-
	(   Errno =:= 0 ->
	        true
	;   errno_class(Errno, Class) ->
		exception(Class, Errno, ??, Goal, Exception),
		print_message(error, Exception),
		fail
	;   otherwise ->
		print_message(error, system_error(errno(Errno))),
		fail
	).

