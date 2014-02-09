%   Package: crypt
%   Author : Richard A. O'Keefe
%   Updated: 12/10/98
%   Purpose: encrypted I/O for Prolog.
%   SeeAlso: crypt.c

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This package defines a pair of predicates:

	crypt_open(+FileName[, +Password], +Mode, -Stream)

    similar to the Quintus Prolog built in routine open/3
    The point of the exercise is that as far as Prolog is
    concerned the file is plain text, but as far as the
    file store is concerned the file is encrypted.  There
    is never a plain text version of the file held in the
    file store.

    Note that if crypt_open/[3,4] cannot open a file, it will
    print an error message and fail in the usual manner, but
    '-' will appear in place of the Password.

    A separate C program is provided for {en,de,re}crypting
    files using the same method.  Unfortunately, unlike the
    UNIX crypt(1) method, this encryption method is not
    built into any of the available editors (emacs, vi, &c).
    You can of course read the encrypted file into emacs,
    then filter the whole buffer through {en,de}crypt.
*/

:- module(crypt, [
	crypt_open/3,
	crypt_open/4
   ]).
:- use_module(library(errno), [
	errno/2
   ]),
   use_module(library(prompt), [
	prompted_line/2
   ]).

sccs_id('"@(#)98/12/10 crypt.pl	76.1"').


%   crypt_open(+FileName, +Mode, -Stream)
%   prompts at the terminal for a password, and then
%   opens an encrypted file named FileName in read, write, or append Mode,
%   and returns an I/O Stream.

crypt_open(FileName, Mode, Stream) :-
	prompted_line(['Enter the encryption key for ',FileName,': '],
		PasswordChars),
	atom_chars(Password, PasswordChars),
	crypt_open(FileName, Password, Mode, Stream).


%   crypt_open(+FileName, +Password, +Mode, -Stream)
%   opens an encrypted file named FileName in read, write, or append Mode,
%   and returns an I/O Stream.  Password (an atom) is the encryption key.

crypt_open(RelFileName, Password, Mode, Stream) :-
	absolute_file_name(RelFileName, AbsFileName),
	'QPCRSO'(AbsFileName, Password, Mode, StreamCode, Errno),
	(   Errno =:= 0 ->
	    stream_code(Stream, StreamCode)
	;   errno(Errno, crypt_open(RelFileName,-,Mode,Stream))
	).


foreign_file(library(system(libpl)), ['QPCRSO']).
foreign('QPCRSO', 'QPCRSO'(+string,+string,+string,-address('QP_stream'),[-integer])).

:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).


end_of_file.

%   TEST CODE

test :-
	crypt_open(foo, voici_mon_clef, write, OutputStream),
	set_output(OutputStream),
	listing(library_directory/1),
	close(OutputStream),
	crypt_open(foo, voici_mon_clef, read, InputStream),
	set_input(InputStream),
	repeat,
	    get0(C), (C < 0 -> true | put(C), fail),
	!,
	close(InputStream).

