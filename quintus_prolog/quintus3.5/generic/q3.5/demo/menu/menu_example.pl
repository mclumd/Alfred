
/* @(#)menu_example.pl	24.1 02/23/88 */

%   Package: menu_example.pl
%   Author : David Znidarsic
%   Updated: 03/09/24
%   Purpose: define one_line_info/0
%   SeeAlso: library(menu)


:- ensure_loaded(library(menu)).


/*
   WARNING: Prolog must be running under the editor interface for this demo to
   work.

   This demo is an example of a way to use the library package 'menu'.
   Its goal is to give the user a one-line description for a Quintus Prolog
   predicate which will perform the task required by a user.  This demo only
   presents a small subset of the Quintus Prolog predicate database since it is
   only used for demonstative purposes.
   It tries to achive its goal by starting at the top of the
   Reference Manual, presenting the user with menus.  Each menu gives the user
   a list of choices to narrow down the category in which the sought predicate
   lies.
   If the user chooses a menu entry which is not itself a sub-menu (a leaf node
   of the tree), the menu tree traversal stops and the menu entry chosen (a
   predicate) is looked up in the 'description'/2 database.  If a
   description exists for the predicate, then the predicate and the description
   are written to the current output stream.
*/


/*
   The following is a menu database.  It is organized as a tree.  Each entry
   in each menu is either the MenuKey for another menu (non-leaf nodes) or
   not a MenuKey for another menu (leaf nodes).  This menu represents the tree:

   Reference Manual
       Syntax
           op/3
	   current_op/3
	   Grammar Rules
	       expand_term/2
	       phrase/2
	       'C'/3
       On-line Help
           help/0
	   help/1
	   manual/0
	   manual/1
*/


menu('Reference Manual',
	'Reference Manual',
		['Syntax',
		 'On-line Help']).
menu('Syntax',
	'Syntax',
		[op('P','T','A'),
		 current_op('P','T','A'),
		 'Grammar Rules']).
menu('Grammar Rules',
	'Grammar Rule Predicates',
		[expand_term('T1','T2'),
		 phrase('P','L'),
		 'C'('S1','T','S2')]).
menu('On-line Help',
	'On-line Help Predicates',
		[help,
		 help('T'),
		 manual,
		 manual('S')]).


/*
   The following is a database of predicate description facts, each fact
   representing a predicate and its one line help message.

   Notice that the description for 'current_op'(P,T,A) is missing.
*/


description(op('P','T','A'),'make atom A an operator of type T precedence P').
description(help,'display a help message').
description(help('T'),'give help on topic T').
description(manual,'access top-level of on-line manual').
description(manual('S'),'access specified manual section').
description('C'('S1','T','S2'),'S1 is connected by the terminal T to S2').
description(expand_term('T1','T2'),'term T is a shorthand which expands to term X').
description(phrase('P','L'),'list L can be parsed as a phrase of type P').


/*
   This predicate takes the final (predicate) choice of the user (after
   being presented the Reference Manual hierarchy), looks the choice up in the
   description database, and writes the predicate and its description to the
   current output stream if such a description exists.
*/


one_line_info :-
	traverse_menu('Reference Manual',FinalChoice),
	nl,
	write(FinalChoice),
	(description(FinalChoice,Info) ->
		write(' - '),write(Info)
	|	write(' has no description.')
	),
	nl.


/*
   The following predicate assumes that the menu database ('menu'/3) is
   organized as a tree, where each menu entry is either a key for another menu
   (non-leaf node) or not (leaf node).
   When the user chooses a non-leaf node, the menu associated with the node is
   recursively displayed.
   When the user chooses a leaf node it is unified with FinalChoice and the
   traversal ends.

   Assumption:  It is assumed that if the predicate 'menu_choice'/2 fails, it
   is because there was no menu for the chosen entry, hence the entry is a leaf
   node.  This is an incorrect assumption.  If the user quits the menu without
   making a choice then 'menu_choice'/2 will fail.
*/


traverse_menu(MenuKey, FinalChoice) :-
	menu_choice(MenuKey, MenuChoice),
	!,
	traverse_menu(MenuChoice, FinalChoice).
traverse_menu(FinalChoice, FinalChoice).
