%   Package: menu
%   Author : David Znidarsic
%   Updated: 04 Sep 1990
%   Purpose: Choose items from a menu using the Emacs interface.
%   SeeAlso: menu.ml

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(menu, [
	menu_choice/2,
	menu_choice/3,
	menu_number/3,
	send_editor/1
   ]).
:- use_module(library(lists), [
	nth1/3
   ]),
   use_module(library(critical), [
	begin_critical/0,
	end_critical/0
   ]).
:- mode
	menu_choice(+, ?),
	menu_choice(+, +, ?),
	menu_number(+, +, ?),
	send_editor(+),
	    write_list(+),
		write_suffixed_list(+).

sccs_id('"@(#)90/09/04 menu.pl	56.1"').


/*  The predicate menu_choice/2 uses a database of facts menu/3.
    The following is a description of this database.

    menu/3 is a database of facts, each fact representing one menu.
    The format of each fact is

	menu(MenuKey, MenuTitle, ListOfMenuEntries)

    MenuKey is the term used by Prolog to identify this menu (it may be
    ANY Prolog term, even a variable).  Common uses find MenuKey to be
    an atom or an integer.

    MenuTitle is the term which will be printed at the top of the menu
    when it is printed (it may be any Prolog term).  Common uses find
    MenuTitle to be an atom (including the atom '').

    ListOfMenuEntries is a list of terms which will be printed, in
    order, as the entries of the menu (it may be a list of ANY Prolog
    terms).  Common uses find ListOfMenuEntries to be a list of atoms.
    It may be a list which is not terminated by [] (nil).

    For example:

	menu(pitchers, 'Choose a Pitcher:', [
		'Walter Johnson',
		'Christy Mathewson',
		'Cy Young'
	    ]).

    This predicate chooses a menu from the database of menus (menu/3)
    based upon the value of MenuKey.  The menu is shown to the user in
    an editor buffer and MenuChoice is unified with the choice that the
    user made.  This predicate fails if MenuKey matches no menus, the
    MenuEntries list for the current menu is [], or if the user quits
    the menu without making a choice.

    MenuKey is used to specify which menu, from the database of menus
    menu/3, will be displayed.  It may be unbound, in order to choose
    all menus defined.  Depending upon the database menu/3, a ground or
    partially instantiated MenuKey will choose some, all, or no menus
    from the database.

    MenuChoice is the menu entry chosen by the user.  It is an element
    from the list, MenuEntries, specified in the menu/3 fact for the
    current menu viewed.  If there is only one element in the
    MenuEntries list it is returned as the MenuChoice without showing
    the menu to the user.

    WARNING: This predicate must only be called when running Prolog
    under the editor interface.

	================ RELEASE 2.0 NOTE ================

    Release 2.0 includes a module system.  This library file, like most
    of the others, has been made into a module.  But where is the menu/3
    predicate to come from?  If you had any programs which used this
    package, and you have not changed them, menu/3 was and will still be
    in user:. But you cannot use :-use_module/2 on user:, so there is a
    user: prefix on this call.

	menu/3 IS IMPORTED FROM THE MODULE 'user'.

    This package should be redesigned so that the menu is a data
    structure.  To make life a bit easier, I [R.A.O'K] have added the
    new predicate menu_choice/3, which doesn't depend on menu/3.
    Note the use of length/2 to check that MenuEntries is in fact
    a list, as well as enabling the efficient use of if-then-else.

    When there is only one entry, menu_choice/3 pretends you chose it.
    But if there is more than one entry, you can refuse to choose any
    of them by typing 'q', '^G', or '^C'.  This inconsistency has not
    yet been resolved.  Instead yet a third predicate has been
    defined, which returns the number of the entry, or 0 for refusal
    to choose.
*/

menu_choice(MenuKey, MenuChoice) :-
	user:menu(MenuKey, MenuTitle, MenuEntries),
	menu_choice(MenuTitle, MenuEntries, MenuChoice).


menu_choice(MenuTitle, MenuEntries, MenuChoice) :-
	length(MenuEntries, N),		% must be a list!
	(   N =:= 1 -> MenuEntries = [MenuChoice]
	|   N  >  1 ->
	    send_editor(['(menu-choice "', MenuTitle, '" "',
			 suffix(MenuEntries), '")']),
	    read(menu_choice(MenuEntryNumber)),
	    nth1(MenuEntryNumber, MenuEntries, MenuChoice)
	).


menu_number(MenuTitle, MenuEntries, Index) :-
	length(MenuEntries, _),		% must be a list!
	send_editor(['(menu-choice "', MenuTitle, '" "',
		     suffix(MenuEntries), '")']),
	(   read(menu_choice(X)) -> Index = X
	;   /* refused the choices */ Index = 0
	).


/*  This predicate writes its arguments to standard output, delimited by
    the Prolog --> Editor packet delimiters (ASCII 30 and ASCII 29).  A
    critical region is put around the sending of the packet since
    sending only a partial packet will cause havoc (subsequent output
    being treated as part of the unfinished packet).  For a similar
    reason, the code in the critical region should not be debugged (the
    output of the debugger will erroneously be part of the packet
    started by the ASCII 30).
*/
send_editor(X) :-
	telling(OldFileOrStream),
	tell(user_output),
	begin_critical,
	put(30),
	write_list(X),
	put(29),
	flush_output(user_output),
	end_critical,
	tell(OldFileOrStream).


/*  This predicate writes each member of its list argument to the
    current output stream.  The argument may also be a non-list or a
    non-nil-terminated list to catch odd cases.  If an element of the
    list is the term "suffix(X)", each element of the list X is written
    to the current output stream followed by a sentinel ASCII character.
*/
write_list([]) :- !.
write_list([suffix(F)|R]) :- !,
	write_suffixed_list(F),
	write_list(R).
write_list([F|R]) :- !,
	write(F),
	write_list(R).
write_list(X) :-
	write(X).


/*  This predicate writes each member of its list argument followed by a
    sentinel ASCII character (ASCII 1, ^A) to the current output stream.
    This sentinel is specific solely to this example.  The Mock Lisp
    code that interprets this string must also use the same sentinel.
    This weird string is necessary since Mock Lisp does not have an
    array or list structure for anything other than ASCII codes.  The
    argument may also be a non-list or a non-nil-terminated list to
    catch odd cases.
*/
write_suffixed_list([]) :- !.
write_suffixed_list([F|R]) :- !,
	write(F),
	put(1),
	write_suffixed_list(R).
write_suffixed_list(X) :-		% this case should never happen
	write(X),			% unless you call send_editor/1
	put(1).				% with a strange argument.


/*  Load the Mock Lisp code for the menu library package.
*/
:- initialization
	(absolute_file_name(library('menu.ml'), Path),
	 send_editor(['(load "',Path,'")
			(&qp-message "Mlisp menu code loaded")'])).

