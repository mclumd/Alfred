/* SCCS   : @(#)chartype.c	75.1 05/25/95
   File   : chartype.c
   Author : Bill Kornfeld (ASCII) + Richard A. O'Keefe (EBCDIC)
   Purpose: Character type table

   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.
*/

#include <stdlib.h>
#include <string.h>             /* [PM] 3.5 strcmp */
#include "quintus.h"

#ifdef	EBCDIC

#define	QP_UNASSIGNED	QP_WHITE_SPACE

#endif

char QP_CharArray[] =
    {
	QP_END_OF_STREAM,	/* -1 EOF */
#ifdef	EBCDIC
	/*  The EBCDIC table is based on the table in "System/370
	    Reference Summary, IBM Technical Publication GX20-1850-4,
	    Fifth Edition (October 1981); specifically on the column
	    labelled "EBCDIC" on pp12-15.  This corresponds well to the
	    translation done by the UNIX utility dd(1) with the option
	    conv=ibm (NOT! conv=ebcdic).  The tables here have been
	    extracted and tested as the program ebctest.c.  There is
	    some residual uncertainty: there are two mappings for the
	    curly braces -- I suggest we follow the first subcolumn of
	    GX20-1850-4 with regard to output but allow either on input.
	    How do we allow both forms of braces?

	    This table should be reviewed with great care in the light
	    of whichever C compiler we finally go with.
	    Note that the SAS/Lattice C compiler's mapping for newline
	    (character 16'15) is NOT the same as its mapping for ^J (LF)
	    (character 16'25).
	*/
	QP_WHITE_SPACE,		/* 00 NUL */
	QP_WHITE_SPACE,		/* 01 SOH */
	QP_WHITE_SPACE,		/* 02 STX */
	QP_WHITE_SPACE,		/* 03 ETX */
	QP_WHITE_SPACE,		/* 04 SEL */
	QP_WHITE_SPACE,		/* 05 HT  '\t' */
	QP_WHITE_SPACE,		/* 06 RNL */
	QP_WHITE_SPACE,		/* 07 DEL */
	QP_WHITE_SPACE,		/* 08 GE  */
	QP_WHITE_SPACE,		/* 09 SPS */
	QP_WHITE_SPACE,		/* 0A RPT */
	QP_WHITE_SPACE,		/* 0B VT  */
	QP_WHITE_SPACE,		/* 0C FF  '\f' */
	QP_WHITE_SPACE,		/* 0D CR  '\r' */
	QP_WHITE_SPACE,		/* 0E SO  */
	QP_WHITE_SPACE,		/* 0F SI  */

	QP_WHITE_SPACE,		/* 10 DLE */
	QP_WHITE_SPACE,		/* 11 DC1 */
	QP_WHITE_SPACE,		/* 12 DC2 */
	QP_WHITE_SPACE,		/* 13 DC3 */
	QP_WHITE_SPACE,		/* 14 RES */
	QP_WHITE_SPACE,		/* 15 NL  -- '\n' */
	QP_WHITE_SPACE,		/* 16 BS  ^H */
	QP_WHITE_SPACE,		/* 17 POC */
	QP_WHITE_SPACE,		/* 18 CAN */
	QP_WHITE_SPACE,		/* 19 EM  */
	QP_WHITE_SPACE,		/* 1A UBS */
	QP_WHITE_SPACE,		/* 1B CU1 */
	QP_WHITE_SPACE,		/* 1C IFS */
	QP_ESCAPE,		/* 1D IGS */
	QP_WHITE_SPACE,		/* 1E IRS */
	QP_WHITE_SPACE,		/* 1F IUS */

	QP_WHITE_SPACE,		/* 20 DS  */
	QP_WHITE_SPACE,		/* 21 SOS */
	QP_WHITE_SPACE,		/* 22 FS  */
	QP_WHITE_SPACE,		/* 23 WUS */
	QP_WHITE_SPACE,		/* 24 BYP */
	QP_WHITE_SPACE,		/* 25 LF  ^J */
	QP_WHITE_SPACE,		/* 26 ETB */
	QP_WHITE_SPACE,		/* 27 ESC */
	QP_WHITE_SPACE,		/* 28 SA  */
	QP_WHITE_SPACE,		/* 29 SFE */
	QP_WHITE_SPACE,		/* 2A SM  */
	QP_WHITE_SPACE,		/* 2B CSP */
	QP_WHITE_SPACE,		/* 2C MFA */
	QP_WHITE_SPACE,		/* 2D ENQ */
	QP_WHITE_SPACE,		/* 2E ACK */
	QP_WHITE_SPACE,		/* 2F BEL */

	QP_WHITE_SPACE,		/* 30     */
	QP_WHITE_SPACE,		/* 31     */
	QP_WHITE_SPACE,		/* 32 SYN */
	QP_WHITE_SPACE,		/* 33 IR  */
	QP_WHITE_SPACE,		/* 34 PP  */
	QP_WHITE_SPACE,		/* 35 TRN */
	QP_WHITE_SPACE,		/* 36 NBS */
	QP_WHITE_SPACE,		/* 37 EOT */
	QP_WHITE_SPACE,		/* 38 SBS */
	QP_WHITE_SPACE,		/* 39 IT  */
	QP_WHITE_SPACE,		/* 3A RFF */
	QP_WHITE_SPACE,		/* 3B CU3 */
	QP_WHITE_SPACE,		/* 3C DC4 */
	QP_WHITE_SPACE,		/* 3D NAK */
	QP_WHITE_SPACE,		/* 3E     */
	QP_WHITE_SPACE,		/* 3F SUB */

	QP_WHITE_SPACE,		/* 40 sp  */
	QP_UNASSIGNED,		/* 41     */
	QP_UNASSIGNED,		/* 42     */
	QP_UNASSIGNED,		/* 43     */
	QP_UNASSIGNED,		/* 44     */
	QP_UNASSIGNED,		/* 45     */
	QP_UNASSIGNED,		/* 46     */
	QP_UNASSIGNED,		/* 47     */
	QP_UNASSIGNED,		/* 48     */
	QP_UNASSIGNED,		/* 49     */
	QP_AGGLUTINATING,	/* 4A cent*/
	QP_AGGLUTINATING,	/* 4B '.' */
	QP_AGGLUTINATING,	/* 4C '<' */
	QP_INDIV_CHAR,		/* 4D '(' */
	QP_AGGLUTINATING,	/* 4E '+' */
	QP_INDIV_CHAR,		/* 4F '|' -- vertical bar */

	QP_AGGLUTINATING,	/* 50 '&' */
	QP_UNASSIGNED,		/* 51     */
	QP_UNASSIGNED,		/* 52     */
	QP_UNASSIGNED,		/* 53     */
	QP_UNASSIGNED,		/* 54     */
	QP_UNASSIGNED,		/* 55     */
	QP_UNASSIGNED,		/* 56     */
	QP_UNASSIGNED,		/* 57     */
	QP_UNASSIGNED,		/* 58     */
	QP_UNASSIGNED,		/* 59     */
	QP_INDIV_ATOM,		/* 5A '!' */
	QP_AGGLUTINATING,	/* 5B '$' */
	QP_AGGLUTINATING,	/* 5C '*' */
	QP_INDIV_CHAR,		/* 5D ')' */
	QP_INDIV_ATOM,		/* 5E ';' */
	QP_AGGLUTINATING,	/* 5F not */

	QP_AGGLUTINATING,	/* 60 '-' */
	QP_AGGLUTINATING,	/* 61 '/' */
	QP_UNASSIGNED,		/* 62     */
	QP_UNASSIGNED,		/* 63     */
	QP_UNASSIGNED,		/* 64     */
	QP_UNASSIGNED,		/* 65     */
	QP_UNASSIGNED,		/* 66     */
	QP_UNASSIGNED,		/* 67     */
	QP_UNASSIGNED,		/* 68     */
	QP_UNASSIGNED,		/* 69     */
	QP_INDIV_CHAR,		/* 6A '|' -- CHECK THIS, broken bar */
	QP_INDIV_CHAR,		/* 6B ',' */
	QP_PERCENT,		/* 6C '%' */
	QP_UNDERBAR,		/* 6D '_' */
	QP_AGGLUTINATING,	/* 6E '>' */
	QP_AGGLUTINATING,	/* 6F '?' */

	QP_UNASSIGNED,		/* 70     */
	QP_UNASSIGNED,		/* 71     */
	QP_UNASSIGNED,		/* 72     */
	QP_UNASSIGNED,		/* 73     */
	QP_UNASSIGNED,		/* 74     */
	QP_UNASSIGNED,		/* 75     */
	QP_UNASSIGNED,		/* 76     */
	QP_UNASSIGNED,		/* 77     */
	QP_UNASSIGNED,		/* 78     */
	QP_AGGLUTINATING,	/* 79 '`' */
	QP_AGGLUTINATING,	/* 7A ':' */
	QP_AGGLUTINATING,	/* 7B '#' */
	QP_AGGLUTINATING,	/* 7C '@' */
	QP_SINGLE_QUOTE,	/* 7D "'" */
	QP_AGGLUTINATING,	/* 7E '=' */
	QP_DOUBLE_QUOTE,	/* 7F '"' */

	QP_UNASSIGNED,		/* 80     */
	QP_SMALL_LETTER,	/* 81 'a' */
	QP_SMALL_LETTER,	/* 82 'b' */
	QP_SMALL_LETTER,	/* 83 'c' */
	QP_SMALL_LETTER,	/* 84 'd' */
	QP_SMALL_LETTER,	/* 85 'e' */
	QP_SMALL_LETTER,	/* 86 'f' */
	QP_SMALL_LETTER,	/* 87 'g' */
	QP_SMALL_LETTER,	/* 88 'h' */
	QP_SMALL_LETTER,	/* 89 'i' */
	QP_UNASSIGNED,		/* 8A     */
	QP_INDIV_CHAR,		/* 8B '{' -- alternative form */
	QP_UNASSIGNED,		/* 8C     */
	QP_UNASSIGNED,		/* 8D     */
	QP_UNASSIGNED,		/* 8E     */
	QP_UNASSIGNED,		/* 8F     */

	QP_UNASSIGNED,		/* 90     */
	QP_SMALL_LETTER,	/* 91 'j' */
	QP_SMALL_LETTER,	/* 92 'k' */
	QP_SMALL_LETTER,	/* 93 'l' */
	QP_SMALL_LETTER,	/* 94 'm' */
	QP_SMALL_LETTER,	/* 95 'n' */
	QP_SMALL_LETTER,	/* 96 'o' */
	QP_SMALL_LETTER,	/* 97 'p' */
	QP_SMALL_LETTER,	/* 98 'q' */
	QP_SMALL_LETTER,	/* 99 'r' */
	QP_UNASSIGNED,		/* 9A '^' -- caret */
	QP_INDIV_CHAR,		/* 9B '}' -- alternative form */
	QP_UNASSIGNED,		/* 9C     */
	QP_UNASSIGNED,		/* 9D     */
	QP_UNASSIGNED,		/* 9E     */
	QP_UNASSIGNED,		/* 9F     */

	QP_UNASSIGNED,  	/* A0     */
	QP_AGGLUTINATING,  	/* A1 '~' */
	QP_SMALL_LETTER,	/* A2 's' */
	QP_SMALL_LETTER,	/* A3 't' */
	QP_SMALL_LETTER,	/* A4 'u' */
	QP_SMALL_LETTER,	/* A5 'v' */
	QP_SMALL_LETTER,	/* A6 'w' */
	QP_SMALL_LETTER,	/* A7 'x' */
	QP_SMALL_LETTER,	/* A8 'y' */
	QP_SMALL_LETTER,	/* A9 'z' */
	QP_UNASSIGNED,		/* AA     */
	QP_UNASSIGNED,		/* AB     */
	QP_UNASSIGNED,		/* AC     */
	QP_INDIV_CHAR,		/* AD '[' */
	QP_UNASSIGNED,		/* AE     */
	QP_UNASSIGNED,		/* AF     */

	QP_UNASSIGNED,		/* B0     */ /* B0-B9 are lower-case digits */
	QP_UNASSIGNED,		/* B1     */ /* should map them to digits? */
	QP_UNASSIGNED,		/* B2     */
	QP_UNASSIGNED,		/* B3     */
	QP_UNASSIGNED,		/* B4     */
	QP_UNASSIGNED,		/* B5     */
	QP_UNASSIGNED,		/* B6     */
	QP_UNASSIGNED,		/* B7     */
	QP_UNASSIGNED,		/* B8     */
	QP_UNASSIGNED,		/* B9     */
	QP_UNASSIGNED,		/* BA     */
	QP_UNASSIGNED,		/* BB     */
	QP_UNASSIGNED,		/* BC     */
	QP_INDIV_CHAR,		/* BD ']' */
	QP_UNASSIGNED,		/* BE     */
	QP_UNASSIGNED,		/* BF     */

	QP_INDIV_CHAR,		/* C0 '{' */
	QP_CAPITAL_LETTER,	/* C1 'A' */
	QP_CAPITAL_LETTER,	/* C2 'B' */
	QP_CAPITAL_LETTER,	/* C3 'C' */
	QP_CAPITAL_LETTER,	/* C4 'D' */
	QP_CAPITAL_LETTER,	/* C5 'E' */
	QP_CAPITAL_LETTER,	/* C6 'F' */
	QP_CAPITAL_LETTER,	/* C7 'G' */
	QP_CAPITAL_LETTER,	/* C8 'H' */
	QP_CAPITAL_LETTER,	/* C9 'I' */
	QP_UNASSIGNED,		/* CA     */
	QP_UNASSIGNED,		/* CB     */
	QP_UNASSIGNED,		/* CC     */
	QP_UNASSIGNED,		/* CD     */
	QP_UNASSIGNED,		/* CE     */
	QP_UNASSIGNED,		/* CF     */

	QP_INDIV_CHAR,		/* D0 '}' */
	QP_CAPITAL_LETTER,	/* D1 'J' */
	QP_CAPITAL_LETTER,	/* D2 'K' */
	QP_CAPITAL_LETTER,	/* D3 'L' */
	QP_CAPITAL_LETTER,	/* D4 'M' */
	QP_CAPITAL_LETTER,	/* D5 'N' */
	QP_CAPITAL_LETTER,	/* D6 'O' */
	QP_CAPITAL_LETTER,	/* D7 'P' */
	QP_CAPITAL_LETTER,	/* D8 'Q' */
	QP_CAPITAL_LETTER,	/* D9 'R' */
	QP_UNASSIGNED,		/* DA     */
	QP_UNASSIGNED,		/* DB     */
	QP_UNASSIGNED,		/* DC     */
	QP_UNASSIGNED,		/* DD     */
	QP_UNASSIGNED,		/* DE     */
	QP_UNASSIGNED,		/* DF     */

	QP_AGGLUTINATING,	/* E0 '\' */
	QP_UNASSIGNED,    	/* E1     */
	QP_CAPITAL_LETTER,	/* E2 'S' */
	QP_CAPITAL_LETTER,	/* E3 'T' */
	QP_CAPITAL_LETTER,	/* E4 'U' */
	QP_CAPITAL_LETTER,	/* E5 'V' */
	QP_CAPITAL_LETTER,	/* E6 'W' */
	QP_CAPITAL_LETTER,	/* E7 'X' */
	QP_CAPITAL_LETTER,	/* E8 'Y' */
	QP_CAPITAL_LETTER,	/* E9 'Z' */
	QP_UNASSIGNED,		/* EA     */
	QP_UNASSIGNED,		/* EB     */
	QP_UNASSIGNED,		/* EC     */
	QP_UNASSIGNED,		/* ED     */
	QP_UNASSIGNED,		/* EE     */
	QP_UNASSIGNED,		/* EF     */

	QP_DIGIT,		/* F0 '0' */
	QP_DIGIT,		/* F1 '1' */
	QP_DIGIT,		/* F2 '2' */
	QP_DIGIT,		/* F3 '3' */
	QP_DIGIT,		/* F4 '4' */
	QP_DIGIT,		/* F5 '5' */
	QP_DIGIT,		/* F6 '6' */
	QP_DIGIT,		/* F7 '7' */
	QP_DIGIT,		/* F8 '8' */
	QP_DIGIT,		/* F9 '9' */
	QP_UNASSIGNED,		/* FA     */
	QP_UNASSIGNED,		/* FB     */
	QP_UNASSIGNED,		/* FC     */
	QP_UNASSIGNED,		/* FD     */
	QP_UNASSIGNED,		/* FE     */
	QP_UNASSIGNED 		/* FF     */

#else
	/* ISO 8859/1 (ISO Latin 1; includes ASCII) */

	QP_WHITE_SPACE,     	/* 00 NUL */
	QP_WHITE_SPACE,     	/* 01 SOH */
	QP_WHITE_SPACE,     	/* 02 STX */
	QP_WHITE_SPACE,     	/* 03 ETX */
	QP_WHITE_SPACE,     	/* 04 EOT */
	QP_WHITE_SPACE,     	/* 05 ENQ */
	QP_WHITE_SPACE,     	/* 06 ACK */
	QP_WHITE_SPACE,     	/* 07 BEL */
	QP_WHITE_SPACE,     	/* 08 BS  */
	QP_WHITE_SPACE,     	/* 09 HT  */

	QP_WHITE_SPACE,     	/* 10 LF  */
	QP_WHITE_SPACE,     	/* 11 VT  */
	QP_WHITE_SPACE,     	/* 12 FF  */
	QP_WHITE_SPACE,     	/* 13 CR  */
	QP_WHITE_SPACE,     	/* 14 SO  */
	QP_WHITE_SPACE,     	/* 15 SI  */
	QP_WHITE_SPACE,     	/* 16 DLE */
	QP_WHITE_SPACE,     	/* 17 DC1 */
	QP_WHITE_SPACE,     	/* 18 DC2 */
	QP_WHITE_SPACE,     	/* 19 DC3 */

	QP_WHITE_SPACE,     	/* 20 DC4 */
	QP_WHITE_SPACE,     	/* 21 NAK */
	QP_WHITE_SPACE,     	/* 22 SYN */
	QP_WHITE_SPACE,     	/* 23 ETB */
	QP_WHITE_SPACE,     	/* 24 CAN */
	QP_WHITE_SPACE,     	/* 25 EM  */
	QP_WHITE_SPACE,     	/* 26 SUB */
	QP_WHITE_SPACE,     	/* 27 ESC */
	QP_WHITE_SPACE,     	/* 28 FS  */
	QP_WHITE_SPACE,	 	/* 29 GS  */
/*	QP_ESCAPE,	    29 GS  I am taking this out and making this a
			    QP_WHITE_SPACE. Otherwise read fails when it
			    reads one of these characters. If anybody
			    knows better, please fix this.		*/

	QP_WHITE_SPACE,     	/* 30 RS  */
	QP_WHITE_SPACE,     	/* 31 US  */
	QP_WHITE_SPACE,     	/* 32 SP  */
	QP_INDIV_ATOM,      	/* 33 '!' */
	QP_DOUBLE_QUOTE,    	/* 34 '"' */
	QP_AGGLUTINATING,   	/* 35 '#' */
	QP_AGGLUTINATING,   	/* 36 '$' */
	QP_PERCENT,         	/* 37 '%' */
	QP_AGGLUTINATING,   	/* 38 '&' */
	QP_SINGLE_QUOTE,    	/* 39 ''' */

	QP_INDIV_CHAR,      	/* 40 ' (' */
	QP_INDIV_CHAR,      	/* 41 ' )' */
	QP_AGGLUTINATING,   	/* 42 '*' */
	QP_AGGLUTINATING,   	/* 43 '+' */
	QP_INDIV_CHAR,      	/* 44 ',' */
	QP_AGGLUTINATING,   	/* 45 '-' */
	QP_AGGLUTINATING,   	/* 46 '.' */
	QP_AGGLUTINATING,   	/* 47 '/' */
	QP_DIGIT,           	/* 48 '0' */
	QP_DIGIT,           	/* 49 '1' */

	QP_DIGIT,           	/* 50 '2' */
	QP_DIGIT,           	/* 51 '3' */
	QP_DIGIT,           	/* 52 '4' */
	QP_DIGIT,           	/* 53 '5' */
	QP_DIGIT,           	/* 54 '6' */
	QP_DIGIT,           	/* 55 '7' */
	QP_DIGIT,           	/* 56 '8' */
	QP_DIGIT,           	/* 57 '9' */
	QP_AGGLUTINATING,   	/* 58 ':' */
	QP_INDIV_ATOM,      	/* 59 ';' */

	QP_AGGLUTINATING,   	/* 60 '<' */
	QP_AGGLUTINATING,   	/* 61 '=' */
	QP_AGGLUTINATING,   	/* 62 '>' */
	QP_AGGLUTINATING,   	/* 63 '?' */
	QP_AGGLUTINATING,   	/* 64 '@' */
	QP_CAPITAL_LETTER,  	/* 65 'A' */
	QP_CAPITAL_LETTER,  	/* 66 'B' */
	QP_CAPITAL_LETTER,  	/* 67 'C' */
	QP_CAPITAL_LETTER,  	/* 68 'D' */
	QP_CAPITAL_LETTER,  	/* 69 'E' */

	QP_CAPITAL_LETTER,  	/* 70 'F' */
	QP_CAPITAL_LETTER,  	/* 71 'G' */
	QP_CAPITAL_LETTER,  	/* 72 'H' */
	QP_CAPITAL_LETTER,  	/* 73 'I' */
	QP_CAPITAL_LETTER,  	/* 74 'J' */
	QP_CAPITAL_LETTER,  	/* 75 'K' */
	QP_CAPITAL_LETTER,  	/* 76 'L' */
	QP_CAPITAL_LETTER,  	/* 77 'M' */
	QP_CAPITAL_LETTER,  	/* 78 'N' */
	QP_CAPITAL_LETTER,  	/* 79 'O' */

	QP_CAPITAL_LETTER,  	/* 80 'P' */
	QP_CAPITAL_LETTER,  	/* 81 'Q' */
	QP_CAPITAL_LETTER,  	/* 82 'R' */
	QP_CAPITAL_LETTER,  	/* 83 'S' */
	QP_CAPITAL_LETTER,  	/* 84 'T' */
	QP_CAPITAL_LETTER,  	/* 85 'U' */
	QP_CAPITAL_LETTER,  	/* 86 'V' */
	QP_CAPITAL_LETTER,  	/* 87 'W' */
	QP_CAPITAL_LETTER,  	/* 88 'X' */
	QP_CAPITAL_LETTER,  	/* 89 'Y' */

	QP_CAPITAL_LETTER,  	/* 90 'Z' */
	QP_INDIV_CHAR,      	/* 91 '[' */
	QP_AGGLUTINATING,   	/* 92 '\' */
	QP_INDIV_CHAR,      	/* 93 ']' */
	QP_AGGLUTINATING,   	/* 94 '^' */
	QP_UNDERBAR,        	/* 95 '_' */
	QP_AGGLUTINATING,   	/* 96 '`' */
	QP_SMALL_LETTER,    	/* 97 'a' */
	QP_SMALL_LETTER,    	/* 98 'b' */
	QP_SMALL_LETTER,    	/* 99 'c' */

	QP_SMALL_LETTER,    	/* 100 'd' */
	QP_SMALL_LETTER,    	/* 101 'e' */
	QP_SMALL_LETTER,    	/* 102 'f' */
	QP_SMALL_LETTER,    	/* 103 'g' */
	QP_SMALL_LETTER,    	/* 104 'h' */
	QP_SMALL_LETTER,    	/* 105 'i' */
	QP_SMALL_LETTER,    	/* 106 'j' */
	QP_SMALL_LETTER,    	/* 107 'k' */
	QP_SMALL_LETTER,    	/* 108 'l' */
	QP_SMALL_LETTER,    	/* 109 'm' */

	QP_SMALL_LETTER,    	/* 110 'n' */
	QP_SMALL_LETTER,    	/* 111 'o' */
	QP_SMALL_LETTER,    	/* 112 'p' */
	QP_SMALL_LETTER,    	/* 113 'q' */
	QP_SMALL_LETTER,    	/* 114 'r' */
	QP_SMALL_LETTER,    	/* 115 's' */
	QP_SMALL_LETTER,    	/* 116 't' */
	QP_SMALL_LETTER,    	/* 117 'u' */
	QP_SMALL_LETTER,    	/* 118 'v' */
	QP_SMALL_LETTER,    	/* 119 'w' */

	QP_SMALL_LETTER,    	/* 120 'x' */
	QP_SMALL_LETTER,    	/* 121 'y' */
	QP_SMALL_LETTER,    	/* 122 'z' */
	QP_INDIV_CHAR,      	/* 123 '{' */
	QP_INDIV_CHAR,      	/* 124 '|' */
	QP_INDIV_CHAR,      	/* 125 '}' */
	QP_AGGLUTINATING,   	/* 126 '~' */
	QP_WHITE_SPACE,     	/* 127 '<rubout>' */ 
	/* Begin the international character set */
	QP_WHITE_SPACE,	 	/* 128 undefined */
	QP_WHITE_SPACE,	 	/* 129 undefined */

	QP_WHITE_SPACE,	 	/* 130 undefined */
	QP_WHITE_SPACE,	 	/* 131 undefined */
	QP_WHITE_SPACE,	 	/* 132 IND  */
	QP_WHITE_SPACE,	 	/* 133 NEL  */
	QP_WHITE_SPACE,	 	/* 134 SSA  */
	QP_WHITE_SPACE,	 	/* 135 ESA  */
	QP_WHITE_SPACE,	 	/* 136 HTS  */
	QP_WHITE_SPACE,	 	/* 137 HTJ  */
	QP_WHITE_SPACE,	 	/* 138 VTS  */
	QP_WHITE_SPACE,	 	/* 139 PLD  */

	QP_WHITE_SPACE,	 	/* 140 PLU  */
	QP_WHITE_SPACE,	 	/* 141 RI   */
	QP_WHITE_SPACE,	 	/* 142 SS2  */
	QP_WHITE_SPACE,	 	/* 143 SS3  */
	QP_WHITE_SPACE,	 	/* 144 DCS  */
	QP_WHITE_SPACE,	 	/* 145 PU1  */
	QP_WHITE_SPACE,	 	/* 146 PU2  */
	QP_WHITE_SPACE,	 	/* 147 STS  */
	QP_WHITE_SPACE,	 	/* 148 CCH  */
	QP_WHITE_SPACE,	 	/* 149 MW   */

	QP_WHITE_SPACE,	 	/* 150 SPA  */
	QP_WHITE_SPACE,	 	/* 151 EPA  */
	QP_WHITE_SPACE,	 	/* 152 undefined */
	QP_WHITE_SPACE,	 	/* 153 undefined */
	QP_WHITE_SPACE,	 	/* 154 undefined */
	QP_WHITE_SPACE,	 	/* 155 CSI  */
	QP_WHITE_SPACE,	 	/* 156 ST   */
	QP_WHITE_SPACE,	 	/* 157 OSC  */
	QP_WHITE_SPACE,	 	/* 158 PM   */
	QP_WHITE_SPACE,	 	/* 159 APC  */

	QP_WHITE_SPACE,	 	/* 160 NBSP <non-breaking space> */
	QP_INDIV_ATOM,	 	/* 161 <inverted exclamation mark>  */
	QP_AGGLUTINATING,	/* 162 <cent sign> */
	QP_AGGLUTINATING,	/* 163 <pounds sterling sign> */
	QP_AGGLUTINATING,   	/* 164 <general currency sign> */
	QP_AGGLUTINATING,	/* 165 <yen sign> */
	QP_INDIV_ATOM, 	 	/* 166 <broken vertical bar> */
	QP_AGGLUTINATING,	/* 167 <section sign> */
	QP_AGGLUTINATING,	/* 168 <diaresis> */
	QP_AGGLUTINATING,	/* 169 <copyright sign> */

	QP_SMALL_LETTER,	/* 170 <feminine ordinal indicator> */
	QP_INDIV_ATOM,	 	/* 171 <angle quotation mark left> */
	QP_AGGLUTINATING,   	/* 172 <logical not sign> (hook) */
	QP_UNDERBAR,	 	/* 173 SHY <soft hyphen> */
	QP_AGGLUTINATING,	/* 174 <registered trademark sign> */
	QP_AGGLUTINATING,	/* 175 <macron> */
	QP_AGGLUTINATING,	/* 176 <degree sign> */
	QP_AGGLUTINATING,	/* 177 <plus/minus sign> */
	QP_AGGLUTINATING,	/* 178 <superscript 2> */
	QP_AGGLUTINATING,	/* 179 <superscript 3> */

	QP_AGGLUTINATING,	/* 180 <acute accent> */
	QP_AGGLUTINATING,	/* 181 <micro sign> */
	QP_AGGLUTINATING,	/* 182 <paragraph sign, pilcrow> */
	QP_AGGLUTINATING,	/* 183 <middle dot> */
	QP_AGGLUTINATING,	/* 184 <cedilla> */
	QP_AGGLUTINATING, 	/* 185 <superscript 1> */
	QP_SMALL_LETTER,	/* 186 <masculine ordinal indicator> */
	QP_INDIV_ATOM,	 	/* 187 <angle quotation mark right> */
	QP_INDIV_ATOM,	 	/* 188 <fraction one quarter> */
	QP_INDIV_ATOM,	 	/* 189 <fraction one half> */

	QP_INDIV_ATOM,	 	/* 190 <fraction three quarters> */
	QP_INDIV_ATOM,	 	/* 191 <inverted question mark> */
	QP_CAPITAL_LETTER,	/* 192 <A_Grave> */
	QP_CAPITAL_LETTER,	/* 193 <A_Accute> */
	QP_CAPITAL_LETTER,	/* 194 <A_Circumflex> */
	QP_CAPITAL_LETTER,	/* 195 <A_Tilde> */
	QP_CAPITAL_LETTER,	/* 196 <A_umlaut> */
	QP_CAPITAL_LETTER,	/* 197 <A_With_Ring> */
	QP_CAPITAL_LETTER,	/* 198 <AE_diphthong */
	QP_CAPITAL_LETTER,	/* 199 <C_cedilla> */

	QP_CAPITAL_LETTER,	/* 200 <E_Grave> */
	QP_CAPITAL_LETTER,	/* 201 <E_Accute> */
	QP_CAPITAL_LETTER,	/* 202 <E_Circumflex> */
	QP_CAPITAL_LETTER,	/* 203 <E_Umlaut> */
	QP_CAPITAL_LETTER,	/* 204 <I_Grave> */
	QP_CAPITAL_LETTER,	/* 205 <I_Accute> */
	QP_CAPITAL_LETTER,	/* 206 <I_Circumflex> */
	QP_CAPITAL_LETTER,	/* 207 <I_Umlaut> */
	QP_CAPITAL_LETTER,  	/* 208 <ETH> */
	QP_CAPITAL_LETTER,	/* 209 <N_Tilde> */

	QP_CAPITAL_LETTER,	/* 210 <O_Grave> */
	QP_CAPITAL_LETTER,	/* 211 <O_Acute> */
	QP_CAPITAL_LETTER,	/* 212 <O_Circumflex> */
	QP_CAPITAL_LETTER,	/* 213 <O_Tilde> */
	QP_CAPITAL_LETTER,	/* 214 <O_Umlaut> */
	QP_AGGLUTINATING,	/* 215 <times sign> */
	QP_CAPITAL_LETTER,	/* 216 <O_Slash> */
	QP_CAPITAL_LETTER,	/* 217 <U_Grave> */
	QP_CAPITAL_LETTER,	/* 218 <U_Acute> */
	QP_CAPITAL_LETTER,	/* 219 <U_Circumflex> */

	QP_CAPITAL_LETTER,	/* 220 <U_Umlaut> */
	QP_CAPITAL_LETTER,	/* 221 <Y_Acute> */
	QP_CAPITAL_LETTER,  	/* 222 <Thorn> */
	QP_SMALL_LETTER,	/* 223 <German lowercase sharp s> */
	QP_SMALL_LETTER,	/* 224 <a_grave> */
	QP_SMALL_LETTER,	/* 225 <a_acute> */
	QP_SMALL_LETTER,	/* 226 <a_circumflex> */
	QP_SMALL_LETTER,	/* 227 <a_tilde> */
	QP_SMALL_LETTER,	/* 228 <a_umlaut> */
	QP_SMALL_LETTER,	/* 229 <a_with_ring> */

	QP_SMALL_LETTER,	/* 230 <ae_diphthong> */
	QP_SMALL_LETTER,	/* 231 <c_cedilla> */
	QP_SMALL_LETTER,	/* 232 <e_grave> */
	QP_SMALL_LETTER,	/* 233 <e_accute> */
	QP_SMALL_LETTER,	/* 234 <e_circumflex> */
	QP_SMALL_LETTER,	/* 235 <e_umlaut> */
	QP_SMALL_LETTER,	/* 236 <i_grave> */
	QP_SMALL_LETTER,	/* 237 <i_acute> */
	QP_SMALL_LETTER,	/* 238 <i_circumflex> */
	QP_SMALL_LETTER,	/* 239 <i_umlaut> */

	QP_SMALL_LETTER,    	/* 240 <eth> */
	QP_SMALL_LETTER,	/* 241 <n_tilde> */
	QP_SMALL_LETTER,	/* 242 <o_grave> */
	QP_SMALL_LETTER,	/* 243 <o_acute> */
	QP_SMALL_LETTER,	/* 244 <o_circumflex> */
	QP_SMALL_LETTER,	/* 245 <o_tilde> */
	QP_SMALL_LETTER,	/* 246 <o_umlaut> */
	QP_AGGLUTINATING,	/* 247 <division sign> */
	QP_SMALL_LETTER,	/* 248 <o_with_slash> */
	QP_SMALL_LETTER,	/* 249 <u_grave> */

	QP_SMALL_LETTER,	/* 250 <u_acute> */
	QP_SMALL_LETTER,	/* 251 <u_circumflex> */
	QP_SMALL_LETTER,	/* 252 <u_umlaut> */
	QP_SMALL_LETTER,	/* 253 <y_acute> */
	QP_SMALL_LETTER,    	/* 254 <thorn> */
	QP_WHITE_SPACE,	 	/* 255 <y_umlaut> */
#endif
    };

char * QP_CharType = QP_CharArray + 1;

/*  QP_Xlate[char]->translation
    translates character constants 0'x and character "lists" to some
    other character set.  It is set up by default for ASCII->ASCII
    translation, with our special new-line code (128) mapped to (10),
    and all other codes untouched.  The table is visible to foreign
    code so that cross-compilers can obtain ASCII->EBCDIC.  The name
    is ugly, but fits into 8 characters.
*/

unsigned char QP_Xlate[] =
    {
	  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
	 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
	 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
	 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
	 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
	 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
	 96, 97, 98, 99,100,101,102,103,104,105,106,107,108,109,110,111,
	112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,
	128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,
	144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,
	160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,
	176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,
	192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,
	208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,
	224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,
	240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,
	10
    };


/* ----------------------------------------------------------------------
    QU_set_chartype()

    This routine enables Kanji processing if the environment variable

	QUINTUS_KANJI_FLAG

    is set, otherwise it disables it.  If Kanji processing is set,
    the QP_chartype[] array is modified to handle the specified Kanji
    representation.  A global variable specifying the current Kanji
    mode (by default ASCII, non-Kanji) is also set.

    Character sets handled:

	ASCII:			One character <= 127
	ISO8859:		One character <= 255
	DEC: 			Two characters, both >= 128, <= 255
	Shift-JIS (Kanji):	Two characters
				    first  >= 129, <= 159 OR
				           >= 224, <= 252
				    second >=  64, <= 126 OR
					   >= 128, <= 252
	Shift-JIS (Kana):	One character, >= 161, <= 223
	JLE 1.0 (CS1):		Two characters, both >= 128, <= 255
	        (CS2):		Two characters, the first 0x8E and 
				    second >= 128, <= 255
		(CS3):		Three characters, the first 0x8F, the
				    second and third >= 128, <= 255

    Note: we are not currently checking everywhere whether subsequent
    bytes of multi-byte extended characters are valid.
   ---------------------------------------------------------------------- */

void QU_set_chartype(void)
    {
	register int i;
	char *kanji_mode;

	if (!(kanji_mode = getenv("QUINTUS_KANJI_FLAG"))) {
	    /* Normal ASCII */
	} else if (strcmp(kanji_mode,"EUC")) {
	    /* Until we learn whether there is a portable system  */
	    /* call that will tell us about character length in   */
	    /* EUC, it doesn't make sense to try to support the   */
	    /* general EUC.  This is the JLE 1.0 EUC format:      */
	    for (i = 128; i <= 255; i++) QP_CharType[i] = QP_SMALL_LETTER2;
	    QP_CharType[0x8E] = QP_SMALL_LETTER2;
	    QP_CharType[0x8F] = QP_SMALL_LETTER3;
	} else if (strcmp(kanji_mode,"SHIFT_JIS")) {
	    /* Set first character of Kanji extended characters:  */
	    for (i = 129; i <= 159; i++) QP_CharType[i] = QP_SMALL_LETTER2;
	    for (i = 224; i <= 252; i++) QP_CharType[i] = QP_SMALL_LETTER2;
	    /* I think that we should just leave the second Kanji */
	    /* character alone for Shift-JIS.  Conceivably, we    */
	    /* could check it for validity, but that would mean   */
	    /* checking for shift-JIS "mode" all over the place.  */
	    /* Set Kana characters: */
	    for (i = 161; i <= 223; i++) QP_CharType[i] = QP_SMALL_LETTER;
	} else { /* anything else taken as "DEC" Kanji */
	    /* Anything with the top bit set can start a Kanji char: */
	    for (i = 128; i <= 255; i++) QP_CharType[i] = QP_SMALL_LETTER2;
	}
    }
