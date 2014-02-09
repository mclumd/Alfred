%   Package: open_files
%   Author : Richard A. O'Keefe
%   Updated: 12/10/98
%   Purpose: open a sequence of files for reading as one stream

:- module(open_files, [
	open_files/2,
	open_null_input/1
   ]).

:- use_module(library(errno)).

/*  open_files([F1,...,Fn], Stream)
    creates a new input stream whose contents are the contents
    of F1 followed by ... followed by the contents of Fn.
    This is as if we did
	?- unix(system('cat F1 ... Fn >#temp')),
	   open('#temp', read, Stream),
	   ...
    and then deleted #temp when the stream was closed.  VMS users
    will recognise the F1+...+Fn idiom.
	
    open_files/2 does *not*, however, actually create a temporary
    file.  Instead, it first checks that each file exists and is
    readable, and then opens each file in turn as it is needed,
    checking that the file has not changed since the call to
    open_files/2.  A file may appear more than once in the list.
*/

sccs_id('"@(#)98/12/10 openfiles.pl	76.1"').


%   open_null_input(-Stream)
%   creates a new empty input stream.  It is just the same as
%   calling open_files([], Stream).

open_null_input(Stream) :-
	open_files([], Stream).



%   open_files(+[F1,...,Fn], -Stream)
%   is given a list of file names (atoms) [F1,...,Fn] and creates a
%   new input stream whose contents are the contents of F1 followed
%   by ... followed by the contents of Fn.  This is as if we did
%	popen('cat F1 ... Fn', read, Stream)
%   except that it doesn't fork another process and works in VMS.

open_files(RelFiles, Stream) :-
	Goal = open_files(RelFiles, Stream),
	absolute_file_names(RelFiles, AbsFiles, 0, N),
	(   N =:= 1 ->
	    AbsFiles = [OneFile],
	    open(OneFile, read, Stream)
	;   /* N =:= 0 or N >= 2 */
	    'QMFmake'(N, Handle),
	    'pass file names'(AbsFiles, Handle, Goal),
	    'QMFopen'(Handle, StreamCode, Errno),
	    errno(Errno, Goal),		% fails if Errno =\= 0
	    stream_code(Stream, StreamCode)
	).


absolute_file_names([], [], N, N).
absolute_file_names([RelFile|RelFiles], [AbsFile|AbsFiles], N0, N) :-
	N1 is N0+1,
	absolute_file_name(RelFile, AbsFile),
	absolute_file_names(RelFiles, AbsFiles, N1, N).


'pass file names'([], _, _).
'pass file names'([AbsFile|AbsFiles], Handle, Goal) :-
	'QMFnext'(AbsFile, Handle, Errno),
	(   Errno =:= 0 ->
	    'pass file names'(AbsFiles, Handle, Goal)
	;   format(user_error, '~N! Cannot read file ~w~n', [AbsFile]),
	    errno(Errno, Goal)	% fails
	).

foreign_file(library(system(libpl)), [
	'QMFmake', 'QMFnext', 'QMFopen'
]).

foreign('QMFmake', 'QMFmake'(+integer,[-address('MFrec')])).
foreign('QMFnext', 'QMFnext'(+string,+address('MFrec'),[-integer])).
foreign('QMFopen', 'QMFopen'(+address('MFrec'),-address('QP_stream'),[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).

