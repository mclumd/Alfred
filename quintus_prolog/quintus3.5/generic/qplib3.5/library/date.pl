%   Module : date
%   Author : Richard A. O'Keefe
%   Updated: 16 Aug 1994
%   Purpose: time-stamp routines
%   SeeAlso: library(directory), {obsolete}library(time_date)

/*  WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 

    Most date-related predicates in this package returns months in the
    range 0..11 instead of the more conventional 1..12.

    The nearest thing we could find to a standard for time-stamps is
    the "struct tm" format used by the C function localtime().  This is
    part of the draft ANSI standard for C, and as such is part of POSIX
    (that is the IEEE 1003.1 standard for operating system interfaces),
    and of even greater importance, we could obtain timestamps like
    that on all of the systems Quintus Prolog runs on.   We did not
    want to invent yet another representation of dates; there are
    already more than enough.  However, there is one consequence of
    this choice which can be surprising:

	Month numbers run from January=ZERO to December=ELEVEN, not
	from 1 to 12.

    This should not be a problem to you because if you want to print
    one of our date/3 or date/6 records, you should call
    time_stamp/[2,3] to get a printable version, and time_stamp/[2,3]
    understand this coding.

    Some of the predicates in this package are for compatibility with
    an earlier library(time_date) package or for compatibility with
    another Prolog system. Those predicates use the expected 1-12 month
    numbers.  The rule is simple:

	if a month number is inside a date/3 or date/6 record,
	it is encoded in standard fashion as ZERO to ELEVEN

	if a month number is returned as a separate argument,
	it is encoded as 1 to 12.
*/

%   Copyright (C) 1987-1994 Quintus Corporation.  All rights reserved.

:- module(date, [
	date/1,		% date(-DateNow)
	date/2,		% date(?When, ?DateThen)
	date/3,		% LPA and library(time_date) compatibility
	now/1,		% now(-When)
	time/1,		% time(-TimeNow)
	time/2,		% time(?When, ?TimeThen)
	time/3,		% LPA and library(time_date) compatibility
	datime/1,	% datime(-DatimeNow)
	datime/2,	% datime(?When, ?DatimeThen)
	datime/3,	% datime(?Datime, ?Date, ?Time)
	datime/6,	% For LPA compatibility package
	date_and_time/2,% date_and_time(-DateNow, -TimeNow)
	date_and_time/3,% date_and_time(?When, ?DateThen, ?TimeThen)
	time_stamp/2,	% time_stamp(+Format, -TimeStamp)
	time_stamp/3,	% time_stamp(+When, +Format, -TimeStamp)
	portray_date/1	% portray_date(+Date)
   ]).
:- use_module(library(errno), [
	errno/2
   ]).

/*  In these operations,
	When is a UNIX time-stamp (a number of seconds since the
	beginning of 1 Jan 1970) represented by an integer.

	Dates are records date(Year,Month,Day).

	Times are records time(Hour,Minute,Second).

	Datimes are records date(Year,Month,Day,Hour,Minute,Second).

    All times are LOCAL times, not GMT.  The reason for this is
    portability:  UNIX can supply GMT but VMS will not.  The C
    support code for this package will work with GMT if you ask nicely.

    The parameter ranges are
	Year	: year-1900 (e.g. 1987 -> 87)
	Month	: 0..11	    (e.g. January -> 0, September -> 8)
	Day	: 1..31	    (e.g. 27 -> 27)
	Hour	: 0..23	    (e.g. midnight -> 0, noon -> 12)
	Minute  : 0..59
	Second  : 0..59
    These particular ranges were chosen because that is what the standard
    C library function localtime(3) gives you.

    You will normally supply the When parameter, but in this release
	date/2			(assumes midnight is intended)
	time/2			(assumes today is intended)
	datime/2		(no assumptions needed)
	date_and_time/3		(no assumptions needed)
    can solve for When provided the other arguments are ground.  That
    means that now/1 isn't really necessary (see its comment).
    time_stamp/3 can NOT solve for either of its first two arguments.

    Note that if you want both the current date and time, you should call
    either datime/[1,2] or date_and_time/[2,3].  IT IS AN ERROR to obtain
    the date and time in separate calls, because midnight could intervene
    and put you nearly 24 hours out.

    The date/3 and date/6 records are consistent with the time-stamps
    that library(directory) returns.  date/3 records can be compared
    with each other using term comparison.  So can date/6 records be
    compared with each other and time/3 records be compared with each
    other, so it is straightforward to sort with such keys.  datime/3
    converts between the date/6 and {date,time}/3 representations.

    The predicates date/3 and time/3 are for backwards compatibility
    with library(time_date), which is obsolete.  New code should not
    use these predicates, but should use date_and_time/2 or whatever
    instead.

    time_stamp([+When, ]+Format, -TimeStamp)

	When, if present, is a 32-bit UNIX time-stamp.  If it is not
	present, the current time is used.
	It can also be a date/3 (midnight), date/6, or time/3 (today)
	record.  This argument is a strict input.

	TimeStamp is unified with a time-stamp string, represented
	as a Prolog atom.

	Format is an atom (some day a string or list of character
	codes might be accepted, but not in this release) which
	specifies what the time stamp is to look like.  It looks
	rather like a C printf() format string.  We use '%' here
	instead of '~' to avoid confusion: Format is NOT a Prolog
	format/2 control string.  The following escapes exist:

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
		on the case of the format letter.

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

    Examples:
    1.	To find out which day of the week a particular day fell on, call
	time_stamp(date(Y,M,D), '%w', Day).	% M has range 0..11

    2.	To obtain a "DEC-style" date dd-MON-yy, call
	time_stamp(When, '%d-%3M-%02y', Stamp).

    3.	To obtain an ISO numeric date yyyymmdd (suitable for sorting), call
	time_stamp(When, '%y%02n%02d', Stamp).

*/

sccs_id('"@(#)94/08/16 date.pl	73.2"').


%   date(?Year, ?Month, ?Day)
%   returns the current date.  For example, 19 May 1989 would yield
%   Year=1989, Month=5, Day=19.  Note that this is for backwards
%   compatibility with library(time_date) only.  Use date/1 instead.

date(Y, M, D) :-
	date(3, 0, Y, M0, D, _, _, _),
	M is M0+1.


%   date(?Date)
%   returns the current date as a date/3 record.  For example,
%   19 May 1989 would yield Date=date(1989,4,19).  Yes, 4.  For good reason.

date(date(Y,M,D)) :-
	date(3, 0, Y, M, D, _, _, _).

%   date(?When, ?Date)
%   given a Unix timestamp When, returns the corresponding Date as a
%   date record.  Given a date record, returns the Unix timestamp
%   corresponding to the very beginning of that day.

date(When, date(Y,M,D)) :-
	(   nonvar(When) ->
	    date(1, When, Y, M, D, _, _, _)
	;   when(Y, M, D, 0, 0, 0, When)
	).


%   time(?Hour, ?Minute, ?Second)
%   returns the current time (24-hour clock, local time).  For example,
%   10 to 7 in the evening would Hour=18, Minute=50, Second=0.
%   This is for backwards compatibility with library(time_date); use time/1.

time(H, I, S) :-
	date(3, 0, _, _, _, H, I, S).

%   time(?Time)
%   returns the current time as a time/3 record.  For example, ten to
%   seven in the evening would yield Time=time(18,50,0).

time(time(H,I,S)) :-
	date(3, 0, _, _, _, H, I, S).

%   time(?When, ?Time)
%   given a Unix timestamp When, returns the corresponding Time of day
%   as a time record.  Given a time record, returns the Unix timestamp
%   corresponding to that time today.

time(When, time(H,I,S)) :-
	(   nonvar(When) ->
	    date(1, When, _, _, _, H, I, S)
	;   date(3, 0, Y, M, D, _, _, _),
	    when(Y, M, D, H, I, S, When)
	).


%   datime(?Datime)
%   returns the current date and time together as a datime/6 record.
%   For example, 10 to 7 pm on 19 May 1989 would yield
%   Datime=datime(1989,4,19,18,60,0).  You can sort with these as keys.

datime(date(Y,M,D,H,I,S)) :-
	date(3, 0, Y, M, D, H, I, S).

%   datime(?When, ?Datime)
%   given a Unix timestamp When, returns the corresponding date and time
%   as a datime/6 record.  The resolution of Unix timestamps is whole
%   seconds, so there is no loss of information.  Given a date and time
%   as a Datime record, returns the corresponding Unix timestamp When.

datime(When, date(Y,M,D,H,I,S)) :-
	(   nonvar(When) ->
	    date(1, When, Y, M, D, H, I, S)
	;   when(Y, M, D, H, I, S, When)
	).

datime(date(Y,M,D,H,I,S), date(Y,M,D), time(H,I,S)).


%   datime(Y, M, D, H, I, S)
%   is here for the benefit of the LPA compatibility files; we'd rather you
%   used datime/1, and you'll have less trouble with 1 argument than 6...
%   Note that this returns month numbers 1..12; the general pattern in this
%   package is 0..11 because that's the C/Unix interface.

datime(Y, M, D, H, I, S) :-
	date(3, 0, Y, M0, D, H, I, S),
	M is M0+1.


%   date_and_time(?Date, ?Time)
%   returns the current date and time as separate date/3 and time/3 records.
%   For example, 10 to 7 pm on 19 May 1989 would yield
%   Date=date(1989,4,19), Time=time(18,50,0).

date_and_time(date(Y,M,D), time(H,I,S)) :-
	date(3, 0, Y, M, D, H, I, S).

%   date_and_time(?When, ?Date, ?Time)
%   given a Unix timestamp When, returns the corresponding Date and Time
%   separately.  Given a Date and Time, returns the corresponding Unix
%   timestamp When.

date_and_time(When, date(Y,M,D), time(H,I,S)) :-
	(   nonvar(When) ->
	    date(1, When, Y, M, D, H, I, S)
	;   when(Y, M, D, H, I, S, When)
	).


%   now(?When)
%   returns the current date and time as a Unix timestamp When.

now(When) :-
	'QDnow'(0, When).


when(Year, Month, Day, Hour, Minute, Second, When) :-
	'QDwhen'(/* localtime: */ 1,
		 Year, Month, Day, Hour, Minute, Second, When, Errno),
	errno(Errno, when).


date(Which, When, Year, Month, Day, Hour, Minute, Second) :-
	'QDdate'(Which, When, Year, Month, Day, _/*OfWeek*/,
		Hour, Minute, Second, Errno),
	errno(Errno, date).


%   time_stamp(+Format, ?Stamp)
%   returns the current date and time as an atom, Stamp, formatted
%   according to the given Format.  See the source code for details.

time_stamp(Format, Stamp) :-
	'QDdate'(3, 0, Year, Month, Day, DayOfWeek,
		Hour, Minute, Second, Errno),
	errno(Errno, time_stamp(Format,Stamp)),
	'QD4mat'(Format, Year, Month, Day, DayOfWeek,
		Hour, Minute, Second, Stamp).


%   time_stamp(+When, +Format, ?Stamp)
%   returns the given date and time as an atom, Stamp, formatted
%   according to the given format.  See the source code for details.
%   When may be given as a date/3 record, a time/3 record, a datime/6
%   record, or a Unix timestamp.

time_stamp(date(Year,Month,Day), Format, Stamp) :-
	'QD4mat'(Format, Year, Month, Day, -1, 0, 0, 0, Stamp).
time_stamp(date(Year,Month,Day,Hour,Minute,Second), Format, Stamp) :-
	'QD4mat'(Format, Year, Month, Day, -1,
		Hour, Minute, Second, Stamp).
time_stamp(time(Hour,Minute,Second), Format, Stamp) :-
	'QDdate'(3, 0, Year, Month, Day, DayOfWeek, _, _, _, Errno),
	errno(Errno, time_stamp),
	'QD4mat'(Format, Year, Month, Day, DayOfWeek,
		Hour, Minute, Second, Stamp).
time_stamp(When, Format, Stamp) :-
	integer(When),
	'QDdate'(1, When, Year, Month, Day, DayOfWeek,
		Hour, Minute, Second, Errno),
	errno(Errno, time_stamp),
	'QD4mat'(Format, Year, Month, Day, DayOfWeek,
		Hour, Minute, Second, Stamp).


%   portray_date(+TimeStamp)
%   is a hook for printing date- and time-stamps nicely.
%   You hook it in with add_portray(portray_date).

portray_date(TimeStamp) :-
	portray_date(TimeStamp, Format),
	time_stamp(TimeStamp, Format, TimeStampAtom),
	write(TimeStampAtom).

portray_date(date(_,_,_),	'%d-%3M-%02y').
portray_date(time(_,_,_),	'%h:%02i:%02s %1AM').
portray_date(date(_,_,_,_,_,_), '%h:%02i:%02s %1AM %d-%3M-%02y').



foreign_file(library(system(libpl)),
    [
	'QDdate', 'QD4mat', 'QDwhen', time
    ]).

foreign('QDdate', 'QDdate'(+integer,+integer,-integer,-integer,
			   -integer,-integer,-integer,-integer,
			   -integer,[-integer])).
foreign('QD4mat', 'QD4mat'(+string,+integer,+integer,+integer,
			   +integer,+integer,+integer,+integer,[-atom])).
foreign('QDwhen', 'QDwhen'(+integer,+integer,+integer,	    % Which Y M
			   +integer,+integer,+integer,	    % D H M
			   +integer,-integer,[-integer])).  % S When Flag
foreign(time, 'QDnow'(+integer, [-integer])).	% time is in the C library


:- load_foreign_executable(library(system(libpl))),
   abolish(foreign_file, 2),
   abolish(foreign, 2).
