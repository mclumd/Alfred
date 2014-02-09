
/* @(#)BSDcurses.c	26.1 11/16/88 */

/*
	+--------------------------------------------------------+
	| 							 |
        |     Curses Package Stubs (a C-interface example)       |
        |							 |
        |							 |
	|  Copyright (C) 1985,  Quintus Computer Systems, Inc.   |
	|  All rights reserved.					 |
	|							 |
	+--------------------------------------------------------+ */


/* ----------------------------------------------------------------------
   The curses package is supplied in 4.2BSD for controlling updates to
   the screen in a simple and efficient manner.  Many of the entry points
   into the package are via macros rather than procedures.  As such,
   procedures have to be created so that they can be attached to and
   called from a Prolog job.  The convention used here is to prefix
   the name of macros we wish to call with a "p_".
   ---------------------------------------------------------------------- */

#include <curses.h>



p_clear()
{
	clear();
}

p_delch()
{
	delch();
}

p_refresh()
{
	refresh();
}

p_addch(ch)
char *ch;
{
	addch(ch);
}

p_addstr(str)
char *str;
{
	addstr(str);
}

p_clearok(scr, boolf)
WINDOW *scr;
bool boolf;
{
	clearok(scr, boolf);
}

p_clrtobot()
{
	clrtobot();
}

p_clrtoeol()
{
	clrtoeol();
}

p_erase()
{
	erase();
}

p_move(y,x)
int y,x;
{
	move(y,x);
}

p_standout()
{
	standout();
}

p_standend()
{
	standend();
}

p_crmode()
{
	crmode();
}

p_nocrmode()
{
	nocrmode();
}

p_echo()
{
	echo();
}

p_noecho()
{
	noecho();
}

p_getch()
{
	return getch();
}

p_getstr(str)
char *str;
{
	getstr(str);
}

p_raw()
{
	raw();
}

p_noraw()
{
	noraw();
}

p_getyx(win,y,x)
WINDOW *win;
int y,x;
{
	getyx(win,y,x);
}

p_deleteln()
{
	deleteln();
}

p_insertln()
{
	insertln();
}

p_inch()
{
	inch();
}

p_insch(c)
char c;
{
	insch(c);
}

p_winsch(win)
WINDOW *win;
{
	winsch(win);
}

p_leaveok(win, boolf)
WINDOW *win;
bool boolf;
{
	leaveok(win, boolf);
}

p_nl()
{
	nl();
}

p_nonl()
{
	nonl();
}

p_scrollok(win, boolf)
WINDOW *win;
bool boolf;
{
	scrollok(win, boolf);
}

p_unctrl(ch)
char ch;
{
	unctrl(ch);
}

p_savetty()
{
	savetty();
}

p_resetty()
{
	resetty();
}


p_mvwaddch(win,y,x,ch)
WINDOW *win;
int y,x;
char ch;
{
	mvwaddch(win,y,x,ch);
}

p_mvwgetch(win,y,x)
WINDOW *win;
int y,x;
{
	mvwgetch(win,y,x);
}

p_mvwaddstr(win,y,x,str)
int y,x;
WINDOW *win;
char *str;
{
	mvwaddstr(win,y,x,str);
}

p_mvwgetstr(win,y,x,str)
int y,x;
WINDOW *win;
char *str;
{
	mvwgetstr(win,y,x,str);
}

p_mvwinch(win,y,x)
WINDOW *win;
int y,x;
{
	mvwinch(win,y,x);
}

p_mvwdelch(win,y,x)
WINDOW *win;
int y,x;
{
	mvwdelch(win,y,x);
}

p_mvwinsch(win,y,x,c)
WINDOW *win;
int y,x;
char c;
{
	mvwinsch(win,y,x,c);
}

p_mvaddch(y,x,ch)
int y,x;
char ch;
{
	mvaddch(y,x,ch);
}

p_mvgetch(y,x)
int y,x;
{
	mvgetch(y,x);
}

p_mvaddstr(y,x,str)
int y,x;
char *str;
{
	mvaddstr(y,x,str);
}

p_mvgetstr(y,x,str)
int y,x;
char *str;
{
	mvgetstr(y,x,str);
}

p_mvinch(y,x)
int y,x;
{
	mvinch(y,x);
}

p_mvdelch(y,x)
int y,x;
{
	mvdelch(y,x);
}

p_mvinsch(y,x,c)
int y,x;
char c;
{
	mvinsch(y,x,c);
}


int num_lines()
{
	return LINES;
}

int num_cols()
{
	return COLS;
}

void underline_on()
{
	addstr(US);
}

void underline_off()
{
	addstr(UE);
}

void wunderline_on(W)
WINDOW *W;
{
	waddstr(W,US);
}

void wunderline_off(W)
WINDOW *W;
{
	waddstr(W,UE);
}
