/* @(#)U5curses.pl	26.3 11/16/88 */

/*

	+--------------------------------------------------------+
	| 							 |
        |  Curses Package Declarations (a C-interface example)   |
        |							 |
        |							 |
	|  Copyright (C) 1988,  Quintus Computer Systems, Inc.   |
	|  All rights reserved.					 |
	|							 |
	+--------------------------------------------------------+ */


/* ----------------------------------------------------------------------
	The foreign_file declaration tells Prolog that each of the listed
	procedures can be found in the file curses.o
   ---------------------------------------------------------------------- */

foreign_file('U5curses.o',[initscr, p_clear, p_refresh, endwin,
	p_addch, p_addstr, p_clearok, p_clrtobot, 
	p_clrtoeol, p_erase, p_move, p_standout, p_standend,
	p_crmode, p_nocrmode, p_echo, p_noecho, p_getch, p_getstr, 
	p_raw, p_noraw, p_getyx, p_inch, p_leaveok, p_nl,
	p_nonl, p_scrollok, p_unctrl, p_savetty, p_resetty,
	waddch, waddstr, box, wclear, wclrtobot, wclrtoeol, p_delch, wdelch, 
	p_deleteln, wdeleteln, werase, p_insch, winsch, p_insertln, 
	winsertln, wmove, overlay, overwrite, wrefresh, wstandout, wstandend,
	wgetch, wgetstr, delwin, longname, mvwin, newwin, touchwin, subwin,
	mvcur, scroll, setterm,
	p_mvwaddch,p_mvwgetch,p_mvwaddstr,p_mvwgetstr,p_mvwinch,p_mvwdelch,
	p_mvwinsch,p_mvaddch,p_mvgetch,p_mvaddstr,p_mvgetstr,p_mvinch,
	p_mvdelch,p_mvinsch, num_lines, num_cols, underline_on, underline_off,
	wunderline_on, wunderline_off ]).


/* ----------------------------------------------------------------------
	There is one foreign/2 assertion for each of the C procedures that
	can be called from Prolog.
   ---------------------------------------------------------------------- */

foreign(box, box(+address, +integer, +integer )).
foreign(delwin, delwin(+address)).   
foreign(endwin, endwin).
foreign(initscr, initscr).
foreign(longname, longname(+string, +string)).
foreign(mvcur, mvcur(+integer, +integer, +integer, +integer)). 
foreign(mvwin, mvwin(+address,+integer,+integer)).  
foreign(newwin, newwin(+integer, +integer,+integer,+integer, [-address])).
foreign(overlay, overlay(+address, +address)).
foreign(overwrite, overwrite(+address, +address)).
foreign(scroll, scroll(+address)).
foreign(setterm, setterm(+string)).
foreign(subwin, subwin(+integer, +integer, +integer, +integer, +integer)).
foreign(touchwin, touchwin(+address)). 

foreign(p_addch, addch(+integer)).
foreign(p_addstr, addstr(+string)).
foreign(p_clear, clear).
foreign(p_clearok, clearok(+address, +integer)).
foreign(p_clrtobot, clrtobot).
foreign(p_clrtoeol, clrtoeol).
foreign(p_crmode, crmode).
foreign(p_delch, delch).
foreign(p_deleteln, deleteln).
foreign(p_echo, echo).
foreign(p_erase, erase).
foreign(p_getch, getch([-integer])). 
foreign(p_getstr, getstr(+string)).
foreign(p_getyx, getyx(+address,+integer,+integer)).
foreign(p_inch, inch).
foreign(p_insch, insch(+integer)). 
foreign(p_insertln, insertln).
foreign(p_leaveok, leaveok(+address, +integer)).
foreign(p_move, move(+integer,+integer)).
foreign(p_nl, nl).
foreign(p_nocrmode, nocrmode).
foreign(p_noecho, noecho).
foreign(p_nonl, nonl).
foreign(p_noraw, noraw).
foreign(p_raw, raw).
foreign(p_refresh, refresh).
foreign(p_resetty, resetty).
foreign(p_savetty, savetty).
foreign(p_scrollok, scrollok(+address, +integer)).
foreign(p_standend, standend).
foreign(p_standout, standout).
foreign(p_unctrl, unctrl(+integer)).  
foreign(p_winch, winch(+address)).   
foreign(waddch, waddch(+address,+integer)).
foreign(waddstr, waddstr(+address,+string)).
foreign(wclear, wclear(+address)).
foreign(wclrtobot, wclrtobot(+address)).  
foreign(wclrtoeol, wclrtoeol(+address)). 
foreign(wdelch, wdelch(+address)).       
foreign(wdeleteln, wdeleteln(+address)).  
foreign(werase, werase(+address)).
foreign(wgetch, wgetch(+address, [-integer])).  
foreign(wgetstr, wgetstr(+address,+string)).   
foreign(winsch, winsch(+address,+integer)).     
foreign(winsertln, winsertln(+address)).        
foreign(wmove, wmove(+address,+integer,+integer)). 
foreign(wrefresh, wrefresh(+address)).
foreign(wstandend, wstandend(+address)).       
foreign(wstandout, wstandout(+address)).      

foreign(p_mvwaddch, mvwaddch(+address,+integer,+integer,+integer)).
foreign(p_mvwgetch, mvwgetch(+address,+integer,+integer,[-integer])). 
foreign(p_mvwaddstr, mvwaddstr(+address,+integer,+integer,+string)). 
foreign(p_mvwgetstr, mvwgetstr(+address,+integer,+integer,-string)).
foreign(p_mvwinch, mvwinch(+address,+integer,+integer,[-integer])).
foreign(p_mvwdelch, mvwdelch(+address,+integer,+integer)).
foreign(p_mvwinsch, mvwinsch(+address,+integer,+integer,+integer)).

foreign(p_mvaddch, mvaddch(+integer,+integer,+integer)).
foreign(p_mvgetch, mvgetch(+integer,+integer,[-integer])).
foreign(p_mvaddstr, mvaddstr(+integer,+integer,+string)).
foreign(p_mvgetstr, mvgetstr(+integer,+integer,-string)).
foreign(p_mvinch, mvinch(+integer,+integer,[-integer])).
foreign(p_mvdelch, mvdelch(+integer,+integer)).
foreign(p_mvinsch, mvinsch(+integer,+integer,+integer)).

foreign(num_lines, num_lines([-integer])).  
foreign(num_cols, num_cols([-integer])).

foreign(underline_on,underline_on).
foreign(underline_off,underline_off).

foreign(wunderline_on,wunderline_on(+address)).
foreign(wunderline_off,wunderline_off(+address)).


/* ----------------------------------------------------------------------
	The following command causes the C procedures defined in curses.c
	to be loaded. This file contains definitions corresponding to the
	above declarations.

	Note that foreign_file and foreign were abolished after the load
	was completed.  This allows one to load additional C routines from
	different prolog files without encountering warnings that "foreign"
	and "foreign_file" are being redeclaired.
   ---------------------------------------------------------------------- */

:- load_foreign_files(['U5curses.o'],['-lg', '-lcurses']),
   abolish(foreign_file,2), abolish(foreign,2).

