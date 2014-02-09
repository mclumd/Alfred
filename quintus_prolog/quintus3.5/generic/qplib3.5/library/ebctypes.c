/*  File   : ebctypes.c
    Author : Richard A. O'Keefe
    Updated: 02 Nov 1988
    Purpose: C support for library(ebctypes).

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/02 ebctypes.c	27.1";
#endif/*lint*/

#define DIGIT(x) x	/* decimal digit */
#define UPPER(x) x	/* upper-case letter */
#define BREAK	 36	/* can be grouped with upper case letters */
#define	LOWER(x) x+64	/* lower-case letter */
#define	GRAPH	 37	/* other character with defined picture */
#define	SPACE	 38	/* the one and only space character */
#define	CONTROL	 39	/* control characters (0..63) */
#define UNASSIGNED 40	/* unassigned character */

/*  digits are mapped to their decimal value.
    upper case letters A..Z are mapped to 10..35.
    lower case letters a..z are mapped to 10..35 + 64.
    the break character (_) is mapped to 36.
    other printing characters are mapped to 37.
    The space character is mapped to 38.
    other control characters (0..63) are mapped to 39.
    Unassigned characters are mapped to 40.
    So the range of mapped values is 0..99, which means that
    we don't care whether characters are signed or not.
*/

static char ctype[256] =
    {
	CONTROL,	/* 00 NUL */
	CONTROL,	/* 01 SOH */
	CONTROL,	/* 02 STX */
	CONTROL,	/* 03 ETX */
	CONTROL,	/* 04 SEL */
	CONTROL,	/* 05 HT  '\t' */
	CONTROL,	/* 06 RNL */
	CONTROL,	/* 07 DEL */
	CONTROL,	/* 08 GE  */
	CONTROL,	/* 09 SPS */
	CONTROL,	/* 0A RPT */
	CONTROL,	/* 0B VT  */
	CONTROL,	/* 0C FF  '\f' */
	CONTROL,	/* 0D CR  '\r' */
	CONTROL,	/* 0E SO  */
	CONTROL,	/* 0F SI  */

	CONTROL,	/* 10 DLE */
	CONTROL,	/* 11 DC1 */
	CONTROL,	/* 12 DC2 */
	CONTROL,	/* 13 DC3 */
	CONTROL,	/* 14 RES */
	CONTROL,	/* 15 NL  -- '\n' */
	CONTROL,	/* 16 BS  ^H */
	CONTROL,	/* 17 POC */
	CONTROL,	/* 18 CAN */
	CONTROL,	/* 19 EM  */
	CONTROL,	/* 1A UBS */
	CONTROL,	/* 1B CU1 */
	CONTROL,	/* 1C IFS */
	CONTROL,	/* 1D IGS */
	CONTROL,	/* 1E IRS */
	CONTROL,	/* 1F IUS */

	CONTROL,	/* 20 DS  */
	CONTROL,	/* 21 SOS */
	CONTROL,	/* 22 FS  */
	CONTROL,	/* 23 WUS */
	CONTROL,	/* 24 BYP */
	CONTROL,	/* 25 LF  ^J */
	CONTROL,	/* 26 ETB */
	CONTROL,	/* 27 ESC */
	CONTROL,	/* 28 SA  */
	CONTROL,	/* 29 SFE */
	CONTROL,	/* 2A SM  */
	CONTROL,	/* 2B CSP */
	CONTROL,	/* 2C MFA */
	CONTROL,	/* 2D ENQ */
	CONTROL,	/* 2E ACK */
	CONTROL,	/* 2F BEL */

																																
	CONTROL,	/* 30     */
	CONTROL,	/* 31     */
	CONTROL,	/* 32 SYN */
	CONTROL,	/* 33 IR  */
	CONTROL,	/* 34 PP  */
	CONTROL,	/* 35 TRN */
	CONTROL,	/* 36 NBS */
	CONTROL,	/* 37 EOT */
	CONTROL,	/* 38 SBS */
	CONTROL,	/* 39 IT  */
	CONTROL,	/* 3A RFF */
	CONTROL,	/* 3B CU3 */
	CONTROL,	/* 3C DC4 */
	CONTROL,	/* 3D NAK */
	CONTROL,	/* 3E     */
	CONTROL,	/* 3F SUB */

	SPACE,		/* 40 sp  */
	UNASSIGNED,	/* 41     */
	UNASSIGNED,	/* 42     */
	UNASSIGNED,	/* 43     */
	UNASSIGNED,	/* 44     */
	UNASSIGNED,	/* 45     */
	UNASSIGNED,	/* 46     */
	UNASSIGNED,	/* 47     */
	UNASSIGNED,	/* 48     */
	UNASSIGNED,	/* 49     */
	GRAPH,		/* 4A cent*/
	GRAPH,		/* 4B '.' */
	GRAPH,		/* 4C '<' */
	GRAPH,		/* 4D '(' */
	GRAPH,		/* 4E '+' */
	GRAPH,		/* 4F '|' -- vertical bar */

	GRAPH,		/* 50 '&' */
	UNASSIGNED,	/* 51     */
	UNASSIGNED,	/* 52     */
	UNASSIGNED,	/* 53     */
	UNASSIGNED,	/* 54     */
	UNASSIGNED,	/* 55     */
	UNASSIGNED,	/* 56     */
	UNASSIGNED,	/* 57     */
	UNASSIGNED,	/* 58     */
	UNASSIGNED,	/* 59     */
	GRAPH,		/* 5A '!' */
	GRAPH,		/* 5B '$' */
	GRAPH,		/* 5C '*' */
	GRAPH,		/* 5D ')' */
	GRAPH,		/* 5E ';' */
	GRAPH,		/* 5F not */

	GRAPH,		/* 60 '-' */
	GRAPH,		/* 61 '/' */
	UNASSIGNED,	/* 62     */
	UNASSIGNED,	/* 63     */
	UNASSIGNED,	/* 64     */
	UNASSIGNED,	/* 65     */
	UNASSIGNED,	/* 66     */
	UNASSIGNED,	/* 67     */
	UNASSIGNED,	/* 68     */
	UNASSIGNED,	/* 69     */
	GRAPH,		/* 6A '|' */
	GRAPH,		/* 6B ',' */
	GRAPH,		/* 6C '%' */
	BREAK,		/* 6D '_' */
	GRAPH,		/* 6E '>' */
	GRAPH,		/* 6F '?' */

	UNASSIGNED,	/* 70     */
	UNASSIGNED,	/* 71     */
	UNASSIGNED,	/* 72     */
	UNASSIGNED,	/* 73     */
	UNASSIGNED,	/* 74     */
	UNASSIGNED,	/* 75     */
	UNASSIGNED,	/* 76     */
	UNASSIGNED,	/* 77     */
	UNASSIGNED,	/* 78     */
	GRAPH,		/* 79 '`' */
	GRAPH,		/* 7A ':' */
	GRAPH,		/* 7B '#' */
	GRAPH,		/* 7C '@' */
	GRAPH,		/* 7D "'" */
	GRAPH,		/* 7E '=' */
	GRAPH,		/* 7F '"' */

	UNASSIGNED,	/* 80     */
	LOWER(10),	/* 81 'a' */
	LOWER(11),	/* 82 'b' */
	LOWER(12),	/* 83 'c' */
	LOWER(13),	/* 84 'd' */
	LOWER(14),	/* 85 'e' */
	LOWER(15),	/* 86 'f' */
	LOWER(16),	/* 87 'g' */
	LOWER(17),	/* 88 'h' */
	LOWER(18),	/* 89 'i' */
	UNASSIGNED,	/* 8A     */
	GRAPH,		/* 8B '{' -- alternative form */
	UNASSIGNED,	/* 8C     */
	UNASSIGNED,	/* 8D     */
	UNASSIGNED,	/* 8E     */
	UNASSIGNED,	/* 8F     */

	UNASSIGNED,	/* 90     */
	LOWER(19),	/* 91 'j' */
	LOWER(20),	/* 92 'k' */
	LOWER(21),	/* 93 'l' */
	LOWER(22),	/* 94 'm' */
	LOWER(23),	/* 95 'n' */
	LOWER(24),	/* 96 'o' */
	LOWER(25),	/* 97 'p' */
	LOWER(26),	/* 98 'q' */
	LOWER(27),	/* 99 'r' */
	UNASSIGNED,	/* 9A '^' -- caret */
	GRAPH,		/* 9B '}' -- alternative form */
	UNASSIGNED,	/* 9C     */
	UNASSIGNED,	/* 9D     */
	UNASSIGNED,	/* 9E     */
	UNASSIGNED,	/* 9F     */

	UNASSIGNED,  	/* A0     */
	GRAPH,		/* A1 '~' */
	LOWER(28),	/* A2 's' */
	LOWER(28),	/* A3 't' */
	LOWER(30),	/* A4 'u' */
	LOWER(31),	/* A5 'v' */
	LOWER(32),	/* A6 'w' */
	LOWER(33),	/* A7 'x' */
	LOWER(34),	/* A8 'y' */
	LOWER(35),	/* A9 'z' */
	UNASSIGNED,	/* AA     */
	UNASSIGNED,	/* AB     */
	UNASSIGNED,	/* AC     */
	GRAPH,		/* AD '[' */
	UNASSIGNED,	/* AE     */
	UNASSIGNED,	/* AF     */

	DIGIT(0),	/* B0     */ /* B0-B9 are small digits */
	DIGIT(1),	/* B1     */ /* the real digits are F0-F9 */
	DIGIT(2),	/* B2     */
	DIGIT(3),	/* B3     */
	DIGIT(4),	/* B4     */
	DIGIT(5),	/* B5     */
	DIGIT(6),	/* B6     */
	DIGIT(7),	/* B7     */
	DIGIT(8),	/* B8     */
	DIGIT(9),	/* B9     */
	UNASSIGNED,	/* BA     */
	UNASSIGNED,	/* BB     */
	UNASSIGNED,	/* BC     */
	GRAPH,		/* BD ']' */
	UNASSIGNED,	/* BE     */
	UNASSIGNED,	/* BF     */

	GRAPH,		/* C0 '{' */
	UPPER(10),	/* C1 'A' */
	UPPER(11),	/* C2 'B' */
	UPPER(12),	/* C3 'C' */
	UPPER(13),	/* C4 'D' */
	UPPER(14),	/* C5 'E' */
	UPPER(15),	/* C6 'F' */
	UPPER(16),	/* C7 'G' */
	UPPER(17),	/* C8 'H' */
	UPPER(18),	/* C9 'I' */
	UNASSIGNED,	/* CA     */
	UNASSIGNED,	/* CB     */
	UNASSIGNED,	/* CC     */
	UNASSIGNED,	/* CD     */
	UNASSIGNED,	/* CE     */
	UNASSIGNED,	/* CF     */

	GRAPH,		/* D0 '}' */
	UPPER(19),	/* D1 'J' */
	UPPER(20),	/* D2 'K' */
	UPPER(21),	/* D3 'L' */
	UPPER(22),	/* D4 'M' */
	UPPER(23),	/* D5 'N' */
	UPPER(24),	/* D6 'O' */
	UPPER(25),	/* D7 'P' */
	UPPER(26),	/* D8 'Q' */
	UPPER(27),	/* D9 'R' */
	UNASSIGNED,	/* DA     */
	UNASSIGNED,	/* DB     */
	UNASSIGNED,	/* DC     */
	UNASSIGNED,	/* DD     */
	UNASSIGNED,	/* DE     */
	UNASSIGNED,	/* DF     */

	GRAPH,		/* E0 '\' */
	UNASSIGNED,    	/* E1     */
	UPPER(28),	/* E2 'S' */
	UPPER(29),	/* E3 'T' */
	UPPER(30),	/* E4 'U' */
	UPPER(31),	/* E5 'V' */
	UPPER(32),	/* E6 'W' */
	UPPER(33),	/* E7 'X' */
	UPPER(34),	/* E8 'Y' */
	UPPER(35),	/* E9 'Z' */
	UNASSIGNED,	/* EA     */
	UNASSIGNED,	/* EB     */
	UNASSIGNED,	/* EC     */
	UNASSIGNED,	/* ED     */
	UNASSIGNED,	/* EE     */
	UNASSIGNED,	/* EF     */

	DIGIT(0),	/* F0 '0' */
	DIGIT(1),	/* F1 '1' */
	DIGIT(2),	/* F2 '2' */
	DIGIT(3),	/* F3 '3' */
	DIGIT(4),	/* F4 '4' */
	DIGIT(5),	/* F5 '5' */
	DIGIT(6),       /* F6 '6' */
	DIGIT(7),       /* F7 '7' */
	DIGIT(8),	/* F8 '8' */
	DIGIT(9),	/* F9 '9' */
	UNASSIGNED,	/* FA     */
	UNASSIGNED,	/* FB     */
	UNASSIGNED,	/* FC     */
	UNASSIGNED,	/* FD     */
	UNASSIGNED,	/* FE     */
	UNASSIGNED 	/* FF     */
    };


int QEtype0(c)
    int c;
    {
	return ctype[c]&63;
    }


int QEtype1(c)
    int c;
    {
	return ctype[c];
    }

