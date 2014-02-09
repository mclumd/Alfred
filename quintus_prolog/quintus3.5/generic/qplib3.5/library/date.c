/*  File   : date.c
    Author : Richard A. O'Keefe
    Updated: 02/19/99
    Defines: the time-stamp function QDdate.
    SeeAlso: directory.pl, man directory(3), stat(2)

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    QDdate(+Which, +When, -Year, -Month, -Day, -DayOfWeek,
			  -Hour, -Minute, -Second)

    returns, as 7 separate arguments, one of four times:
    Which = 0 -- the GMT for When
    Which = 1 -- the local time for When
    Which = 2 -- the GMT for right now (When is ignored)
    Which = 3 -- the local time for right now (When is ignored)

    In the first two cases, When is the number of seconds since 1 Jan 1970,
    which is the standard UNIX representation for time-stamps.

    In the second two cases, When is completely ignored.  Pass zeroes.

    If you want both the date and time, it is important to obtain them
    from a single system call, rather than first obtaining one and then
    the other, because the two events could be separated by midnight,
    in which case you'd be nearly 24 hours out.

*/

#ifndef	lint
static  char SCCSid[] = "@(#)99/02/19 date.c     76.2";
#endif/*lint*/

#include <errno.h>
#include <time.h>

#include "qerrno.h"
#include "quintus.h"

long QDdate(Which, When,
	   Year, Month, Day, WeekDay, Hour, Minute, Second)
    long Which;
    time_t When;
    long *Year, *Month, *Day, *WeekDay;
    long *Hour, *Minute, *Second;
    {
	register struct tm *timestamp;

	if (Which&2)
		When = time((time_t*)0);
	timestamp = Which&1 ? localtime(&When) : gmtime(&When);
	if (!timestamp)
		return errno;
	*Year	= timestamp->tm_year;		/* -1900 */
	*Month	= timestamp->tm_mon;		/* 0..11 */
	*Day	= timestamp->tm_mday;		/* 1..31 */
	*WeekDay= timestamp->tm_wday;		/* 0.. 6 */
	*Hour	= timestamp->tm_hour;		/* 0..23 */
	*Minute	= timestamp->tm_min;		/* 0..59 */
	*Second	= timestamp->tm_sec;		/* 0..59 */
	return 0;
    }


/*  QDofwk(Year, Month, Day) -> WeekDay
    takes a date (as returned by QDdate) and yields the day of week.
    This is currently used by QD4mat only, not by Prolog.
*/

static int julday(Year, Month, Day)
    int Year;
    int Month;
    int Day;
    {
	int jy, jm, jd, ja;

	Year += 1900;
	if (Year <= 0) Year++;
	if (Month > 1) jy = Year,   jm = Month+2;
	else           jy = Year-1, jm = Month+14;
	jd = (int)(365.25*jy) + (int)(30.6001*jm) + Day + 1720995;
	if ((Year*12 + Month)*31 + Day >= (1582*12 + 9)*31 + 15) {
	    ja = jy / 100;
	    jd = jd + 2 - ja + ja/4;
	}
	return jd;
    }

#define JD_1_jan_1970	2440588


int QDofwk(Year, Month, Day)
    int Year;
    int Month;
    int Day;
    {
	return (julday(Year, Month, Day) + 1) % 7;
    }


/*  QDwhen(Year, Month, Day, Hour, Minute, Second, When, Which)
    calculates the 32-bit UNIX time-stamp corresponding to
    the given date and returns it in When. If the arguments are
    well-formed it returns 0, otherwise it returns -1 and When is
    not set.

    Which determines whether the given date is in GMT or local time.
    Note that UNIX time-stamps are expressed in terms of GMT.

    DO NOT CHANGE THIS FUNCTION UNTIL YOU UNDERSTAND THE LOCALTIME CORRECTION!
*/
time_t QDwhen(Which, Year, Month, Day, Hour, Minute, Second, When)
    int Which;		/* 0 for GMT, 1 for local time */
    int Year, Month, Day, Hour, Minute, Second;
    long *When;
    {
	int d;
	time_t t;
	register struct tm *timestamp;

	if (Year < 0 || Year > 200 ||
	    Month < 0 || Month > 11 ||
	    Day < 1 || Day > 31 ||
	    Hour < 0 || Hour > 23 ||
	    Minute < 0 || Minute > 59 ||
	    Second < 0 || Second > 59) return EINVAL;

	d = julday(Year, Month, Day) - JD_1_jan_1970;
	t = ((d * 24 + Hour)*60 + Minute)*60 + Second;
	if (Which) {		/* local time correction needed */
	    timestamp = localtime(&t);
	    if (!timestamp) return errno;
	    d = Day - timestamp->tm_mday;
	    if (d > 1) d = -1; else
	    if (d < -1) d = 1;
	    t = ((d * 24 + Hour - timestamp->tm_hour)*60
		+ Minute - timestamp->tm_min)*60
		+ Second - timestamp->tm_sec + t;
	}			/* End local time correction */
	*When = t;
	return 0;
    }


/*  QD4mat(Format, Year, Month, Day, WeekDay, Hour, Minute, Second)
    takes a format (described below) and a time-stamp as returned by
    QDdate(), and returns a string which contains the time-stamp in
    the given format.  To avoid memory allocation problems, QD4mat
    returns the string as a Prolog atom.

    The Format is a string, which like a C printf() format string,
    stands for itself except for special substitution marks which
    are introduced by a percent sign.

	%<w>y	Prints the Year modulo <w> as a decimal integer.
		If <w> begins with 0, leading zeros are written.
		Thus, if the year is 2007, %2y will write "7"
		but %02y will write "07".  If <w> is absent (or 0)
		all significant digits will be written (like %d).

		All the numeric formats act like this: the least
		significant <w> digits are printed, with 0 padding
		on the left if <w> begins with 0, and with the
		default for <w> being "enough".

	%<w>n	Prints the month Number modulo <w> in decimal.

	%<w>d	Prints the Day of the month modulo <w> in decimal.

		So to print a date in British form, use %d/%n/%2y
		and for USA form, use %n/%d/%2y.

	%<w>m	Prints the English *name* of the Month in lower case.
		The first <w> letters of the name are written, with
		blank padding on the right if necessary.  If <w> is
		omitted, no truncation or padding is done.
	%<w>M	Prints the English name of the Month in Mixed Case.
		That is, the first letter is in upper case, and the
		remaining letters are in lower case.

		All the string formats act like this: the first <w>
		characters are printed with truncation or padding
		on the right, no truncation or padding if <w> is
		omitted, and either lower or Mixed case depending
		on the case of the format letter.  There is no way
		of generating UPPER case; generate lower case and
		then change the case using caseconv.

	%<w>w	Prints the day of the Week in lower case.
	%<w>W	Prints the day of the Week in Mixed Case.

	%<w>t	Prints the day of the month in %<w>d form, then
		prints "st", "nd", "rd", or "th" as appropriate.

	%<w>h	Prints the Hour (12-hour clock) as an integer.

	%<w>c	Prints the hour (24-hour clock) as an integer.
		"c" stands for Continental (or railway) style.

	%<w>i	Prints the minute as an integer.  "i" is used
		rather than "m" because "m" stands for "month".

	%<w>s	Prints the Second as an integer.

	%<w>a	Prints "am" or "pm".

	%<w>A	Prints "Am" or "Pm".  To get AM or PM, write %1AM.

	%<w>p	Prints "ante meridiem" or "post meridiem".

	%<w>P	Prints "Ante Meridiem" or "Post Meridiem".

	%x	If, after skipping digits, the next character is not
		one of the letters above, x is written.  Thus to get
		a percent sign, write %%.

    If Format is empty "", the string
	"%3W %3M %2d %02c:%02i:%02s %4y"
    is used, which is what the UNIX ctime(3) function uses, except
    that ctime(3) adds a new-line at the end.

    The result is truncated to QP_MAX_ATOM characters, which should
    be ample.  My favourite format is
	"%W the %t of %M, %y, %h:%02i:%02s %a"
*/


static char *day[] =
    {
	"Sunday",	"Monday",	"Tuesday",	"Wednesday",
	"Thursday",	"Friday",	"Saturday"
    };
static char *mon[] =
    {
	"January",	"February",	"March",	"April",
	"May",		"June",		"July",		"August",
	"September",	"October",	"November",	"December"
    };
static char *apm[] =
    {
	"ante meridiem",	"post meridiem",
	"Ante Meridiem",	"Post Meridiem",
	"am",	"pm"
    };


static char *dostr(source, width, mixed, dest)
    register char *source;
    int width;
    int mixed;
    register char *dest;
    {
	*dest++ = *source++ + mixed;
	width--;
	while (*source && width) *dest++ = *source++, width--;
	while (--width >= 0) *dest++ = ' ';
	return dest;
    }


static char *donth(number, dest)
    int number;		/* known to be non-negative */
    register char *dest;
    {
	int d0 = number%10;
	int d1 = (number%100)/10;
	register char *src =
	    d1 == 1 || d0 == 0 || d0 > 3 ? "th" :
	    d0 == 1 ? "st" : d0 == 2 ? "nd" : "rd";
	*dest++ = *src++;
	*dest++ = *src++;
	return dest;
    }


static char *dodec(number, width, pad, dest)
    int number;		/* known to be non-negative */
    int width;		/* also known to be non-negative */
    int pad;		/* is '0' or something else */
    register char *dest;
    {
	char *result;
	if (width == 0) {
	    int temp = number;
	    for (width = 1; temp >= 10; temp /= 10, width++) ;
	}
	dest += width;
	result = dest;
	do *--dest = number%10 + '0', width--;
	while ((number /= 10) != 0 && width != 0);
	if (pad != '0') pad = ' ';
	while (--width >= 0) *--dest = pad;
	return result;
    }


QP_atom QD4mat(Format, Year, Month, Day, DayOfWeek, Hour, Minute, Second)
    char *Format;
    int Year, Month, Day, DayOfWeek, Hour, Minute, Second;
    {
	char buffer[QP_MAX_ATOM+100];
	char *pmax;
	register char *p;
	register char *f;
	int w;
	register int c;
	char *x;
	int afternoon;

	p = buffer;
	pmax = buffer+QP_MAX_ATOM;
	f = Format && *Format ? Format : "%3W %3M %2d %02c:%02i:%02s %4y";
	afternoon = Hour >= 12; /* Hour > 12 || Hour == 12 && (Minute != 0 || Second != 0); */

	while ((p < pmax) && (c = *f++)) {
	    if (c != '%') {
		*p++ = c;
	    } else {
		x = f;
		w = 0;
		while ((unsigned)((c = *f++) - '0') < 10) w = w*10-'0'+c;
		if (w > 99) w = 99;
		switch (c) {
		    case 'y':	p = dodec(Year+1900, w, *x, p);
				break;
		    case 'n':	p = dodec(Month+1, w, *x, p);
				break;
		    case 'd':	p = dodec(Day, w, *x, p);
		    		break;
		    case 't':	p = dodec(Day, w, *x, p);
				p = donth(Day, p);
				break;
		    case 'M':
		    case 'm':	p = dostr(mon[Month], w, c-'M', p);
		    		break;
		    case 'W':
		    case 'w':	if (DayOfWeek < 0)
				    DayOfWeek = QDofwk(Year, Month, Day);
				p = dostr(day[DayOfWeek], w, c-'W', p);
				break;
		    case 'h':	p = dodec((Hour+11)%12+1, w, *x, p);
		    		break;
		    case 'c':	p = dodec(Hour, w, *x, p);
				break;
		    case 'i':	p = dodec(Minute, w, *x, p);
				break;
		    case 's':	p = dodec(Second, w, *x, p);
				break;
		    case 'a':
		    case 'A':	p = dostr(apm[4+afternoon], w, c-'a', p);
				break;
		    case 'p':	p = dostr(apm[0+afternoon], w, 0, p);
				break;
		    case 'P':	p = dostr(apm[2+afternoon], w, 0, p);
				break;
		    default:	*p++ = c;
		    		break;
		}
	    }
	}
	*p = '\0';
	*pmax = '\0';
	return QP_atom_from_string(buffer);
    }
