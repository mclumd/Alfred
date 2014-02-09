/*  File   : ibm2iso.c
    Author : Richard O'Keefe
    Updated: 18 Dec 1989
    Purpose: Map IBM-PC characters to ISO 8859/1

    Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)89/12/18 ibm2iso.c	36.1";
#endif/*lint*/

/*  The IBM-PC 8-bit character set is not an international standard,
    and is not in use on any other class of machines.
    The Macintosh 8-bit character set is not an international standard,
    and is not in use on any other class of machines.

    There is, however, an international standard character set which
    contains most of the letters in the IBM-PC and Macintosh character
    sets.  Naturally Quintus support that international standard, and
    have done so since before it was ratified.  That standard is ISO
    8859/1.  In fact ISO 8859, just like the ISO 646 standard which
    preceded it, is a family of character sets (ASCII was one particular
    national variant of ISO 646).  All the members of the 8859 family
    have their lower half identical to ASCII.  The upper half depends on
    which national languages you are interested in.

 Part Name                     Status*    Language/Region/Script
 
  1   Latin Alphabet No 1     IS Feb 87   "Western European" 
  2   Latin Alphabet No 2     IS Feb 87   "Eastern European" 
  3   Latin Alphabet No 3     IS Mar 88   "Southern European" + S. Africa
  4   Latin Alphabet No 4     IS Mar 88   Majority Scandinavian
  5   Latin-Cyrillic Alphabet tbp IS 88   ASCII + Cyrillic characters
  6   Latin-Arabic Alphabet   IS Aug 87   ASCII + Arabic characters*
  7   Latin-Greek Alphabet    IS Nov 87   ASCII + Greek characters              
  8   Latin-Hebrew Alphabet   tbp IS 88   ASCII + Hebrew characters
  9   Latin Alphabet No 5     proposed    modification of pt. 3 by Turkey
 
 * Status key:   IS - approved international standard published at indicated date
             tbp IS - standard is approved, but not yet published
           proposed - draft text hasn't yet entered ISO ballot cycle

    ISO 8859/1 covers the repertoires for the following languages:
    Danish, Dutch, English, Faeroese, Flemish, Finnish, French, German,
    Icelandic, Irish, Italian, Norwegian, Portuguese, Spanish, and
    Swedish, but not Catalan or Welsh.


    This file defines two tables:
	ibm2iso[IbmCode] -> IsoCode
	mac2iso[MacCode] -> IsoCode
    These tables map each IBM PC or Macintosh code to the corresponding
    ISO 8859/1 code if there is one, or to 0 is there is none.

    The PC character with
    code 170 is actually a box-forming character, but it looks enough like
    a negation hook that I have deemed it useful to map it to the hook.
    The Mac's "bullet" has been mapped to centre-dot.

    Note that characters like TAB, CR, LF, and so on often have their
    proper significance on PCs and PC-clowns, but we are concerned here
    with the *graphic* signifiance given to them.
*/

unsigned char ibm2iso[256] =
    {
	0,			/* 000 unassigned? */
	0,			/* 001 White Face */
	0,			/* 002 Black Face */
	0,			/* 003 Heart */
	0,			/* 004 Diamond */
	0,			/* 005 Club */
	0,			/* 006 Spade */
	0,			/* 007 blotch */
	0,			/* 010 anti blotch */
	0,			/* 011 ringed blotch */
	0,			/* 012 anti ringed blotch */
	0,			/* 013 spear and shield of Mars (male, iron) */
	0,			/* 014 mirror of Venus (female, copper) */
	0,			/* 015 quaver */
	0,			/* 016 tied semi-quavers */
	164,			/* 017 general currency sign? */

	0,			/* 020 right filled triangle */
	0,			/* 021 left  filled triangle */
	0,			/* 022 up-down arrow */
	0,			/* 023 double exclamation mark */
	182,			/* 024 pilcrow = paragraph sign */
	167,			/* 025 section sign */
	0,			/* 026 small filled square */
	0,			/* 027 underlined up-down arrow */
	0,			/* 030 up    arrow */
	0,			/* 031 down  arrow */
	0,			/* 032 right arrow */
	0,			/* 033 left  arrow */
	0,			/* 034 thick bottom left corner */
	0,			/* 035 left-right arrow */
	0,			/* 036 up    filled triangle */
	0,			/* 037 down  filled triangle */

	 32,  33,  34,  35,  36,  37,  38,  39,	/* _!"#$%&' */
	 40,  41,  42,  43,  44,  45,  46,  47,	/* ()*+,-./ */
	 48,  49,  50,  51,  52,  53,  54,  55,	/* 01234567 */
	 56,  57,  58,  59,  60,  61,  62,  63,	/* 89:;<=>? */
	 64,  65,  66,  67,  68,  69,  70,  71,	/* @ABCDEFG */
	 72,  73,  74,  75,  76,  77,  78,  79,	/* HIJKLMNO */
	 80,  81,  82,  83,  84,  85,  86,  87,	/* PQSRTUVW */
	 88,  89,  90,  91,  92,  93,  94,  95,	/* XYZ[\]^_ */
	 96,  97,  98,  99, 100, 101, 102, 103,	/* `abcdefg */
	104, 105, 106, 107, 108, 109, 110, 111,	/* hijklmno */
	112, 113, 114, 115, 116, 117, 118, 119, /* pqrstuvw */
	120, 121, 122, 123, 124, 125, 126,      /* xyz{|}~  */
		/* Strictly speaking, 125 being a broken bar in the IBM PC
		   character set should probably be mapped to 166 in the
		   ISO 8859/1 character set, but most programming languages
		   are likely to require the solid bar at 125.
		*/
	0,			/* 177 heavy delta */

	199,			/* 200 C-cedilla */
	252,			/* 201 u-umlaut */
	233,			/* 202 e-acute */
	226,			/* 203 a-circumflex */
	228,			/* 204 a-umlaut */
	224,			/* 205 a-grave */
	229,			/* 206 a-ring */
	231,			/* 207 c-cedilla */
	234,			/* 210 e-circumflex */
	235,			/* 211 e-umlaut */
	232,			/* 212 e-grave */
	239,			/* 213 i-umlaut */
	238,			/* 214 i-circumflex */
	236,			/* 215 i-grave */
	196,			/* 216 A-umlaut */
	197,			/* 217 A-ring */

	201,			/* 220 E-acute */
	230,			/* 221 ae ligature */
	198,			/* 222 AE ligature */
	244,			/* 223 o-circumflex */
	246,			/* 224 o-umlaut */
	242,			/* 225 o-grave */
	251,			/* 226 u-circumflex */
	249,			/* 227 u-grave */
	253,			/* 230 y-umlaut */
	214,			/* 231 O-umlaut */
	220,			/* 232 U-umlaut */
	162,			/* 233 cent (currency) sign */
	163,			/* 234 pound (currency) sign */
	165,			/* 235 yen (currency) sign */
	0,			/* 236 Pt -- what's that? */
	0,			/* 237 Schilling (currency) sign? */

	225,			/* 240 a-acute */
	237,			/* 241 i-acute */
	243,			/* 242 o-acute */
	250,			/* 243 u-acute */
	241,			/* 244 n-tilde */
	209,			/* 245 N-tilde */
	170,			/* 246 a-ordinal */
	186,			/* 247 o-ordinal */
	191,			/* 250 inverted question mark */
	0,			/* 251 top left corner */
	172,			/* 252 negation hook ('not' sign) */
	189,			/* 253 one/half */
	188,			/* 254 one/quarter */
	161,			/* 255 inverted exclamation mark */
	171,			/* 256 left  << quote */
	187,			/* 257 right >> quote */

	0,  0,  0,  0,  0,  0,  0,  0, 	/* 260-267	box characters */
	0,  0,  0,  0,  0,  0,  0,  0, 	/* 270-277	box characters */
	0,  0,  0,  0,  0,  0,  0,  0,	/* 300-307	box characters */
	0,  0,  0,  0,  0,  0,  0,  0, 	/* 310-317	box characters */
	0,  0,  0,  0,  0,  0,  0,  0, 	/* 320-327	box characters */
	0,  0,  0,  0,  0,  0,  0,  0, 	/* 330-337	box characters */

	0,			/* 340 lower-case alpha */
	0,			/* 341 lower-case beta */
	0,			/* 342 Upper-Case Gamma */
	0,			/* 343 Upper-Case Pi */
	0,			/* 344 Upper-Case Sigma */
	0,			/* 345 lower-case sigma */
	181,			/* 346 lower-case mu (micro/micron sign) */
	0,			/* 347 lower-case gamma 
	0,			/* 350 Upper-Case Phi */
	0,			/* 351 Upper-Case Theta */
	0,			/* 352 Upper-Case Omega */
	0,			/* 353 lower-case delta */
	0,			/* 354 lower-case omega? */
	0,			/* 355 lower-case omega, crossed */
	0,			/* 356 element-of */
	0,			/* 357 cap (intersection) */

	0,			/* 360 equivalence */
	177,			/* 361 plus-minus */
	0,			/* 362 greater-than-or-equal-to */
	0,			/* 363 less-than-or-equal-to */
	0,			/* 364 integral sign, upper half */
	0,			/* 365 integral sign, lower half */
	247,			/* 366 division sign -:- */
	0,			/* 367 approximate equality */
	176,			/* 370 degrees? */
	185,			/* 371 superscript 1? */
	183,			/* 372 centred dot (bullet) */
	0,			/* 373 radical */
	0,			/* 374 lower-case eta */
	178,			/* 375 superscript 2 */
	0,			/* 376 small filled box */
	0			/* 377 unassigned */
    };

unsigned char mac2iso[256] =
    {
	  0,   0,   0,   0,   0,   0,   0,   0,  /* 000-007  control chars */
	  0,   0,   0,   0,   0,   0,   0,   0,  /* 010-017  control chars */
	  0,   0,   0,   0,   0,   0,   0,   0,  /* 020-027  control chars */
	  0,   0,   0,   0,   0,   0,   0,   0,  /* 030-037  control chars */
	 32,  33,  34,  35,  36,  37,  38,  39,	/* _!"#$%&' */
	 40,  41,  42,  43,  44,  45,  46,  47,	/* ()*+,-./ */
	 48,  49,  50,  51,  52,  53,  54,  55,	/* 01234567 */
	 56,  57,  58,  59,  60,  61,  62,  63,	/* 89:;<=>? */
	 64,  65,  66,  67,  68,  69,  70,  71,	/* @ABCDEFG */
	 72,  73,  74,  75,  76,  77,  78,  79,	/* HIJKLMNO */
	 80,  81,  82,  83,  84,  85,  86,  87,	/* PQSRTUVW */
	 88,  89,  90,  91,  92,  93,  94,  95,	/* XYZ[\]^_ */
	 96,  97,  98,  99, 100, 101, 102, 103,	/* `abcdefg */
	104, 105, 106, 107, 108, 109, 110, 111,	/* hijklmno */
	112, 113, 114, 115, 116, 117, 118, 119, /* pqrstuvw */
	120, 121, 122, 123, 124, 125, 126, 127, /* xyz{|}~  */


	196,			/* 200 A-umlaut */
	197,			/* 201 A-ring */
	199,			/* 202 C-cedilla */
	201,			/* 203 E-acute */
	209,			/* 204 N-tilde */
	214,			/* 205 O-umlaut */
	220,			/* 206 U-umlaut */
	225,			/* 207 a-acute */
	224,			/* 210 a-grave */
	226,			/* 211 a-circumflex */
	228,			/* 212 a-umlaut */
	227,			/* 213 a-tilde */
	229,			/* 214 a-ring */
	231,			/* 215 c-cedilla */
	233,			/* 216 e-acute */
	232,			/* 217 e-grave */

	234,			/* 220 e-circumflex */
	235,			/* 221 e-umlaut */
	237,			/* 222 i-acute */
	236,			/* 223 i-grave */
	238,			/* 224 i-circumflex */
	239,			/* 225 i-umlaut */
	241,			/* 226 n-tilde */
	243,			/* 227 o-acute */
	242,			/* 230 o-grave */
	244,			/* 231 o-circumflex */
	246,			/* 232 o-umlaut */
	245,			/* 233 o-tilde */
	250,			/* 234 u-acute */
	249,			/* 235 u-grave */
	251,    		/* 236 u-circumflex */
	252,    		/* 237 u-umlaut */

	  0,			/* 240 obelus */
	176,			/* 241 degrees */
	162,			/* 242 cents */
	163,			/* 243 pounds */
	167,			/* 244 section */
	183,			/* 245 bullet */
	182,			/* 246 pilcrow */
	223,			/* 247 ess-tset */
	174,            	/* 250 (R)egistered */
	169,    		/* 251 (C)opyright */
	  0,			/* 252 [TM] -- trademark */
	180,			/* 253 prime */
	168,			/* 254 diaeresis */
	  0,			/* 255 not-equal */
	198,			/* 256 AE ligature */
	216,			/* 257 crossed-O */

	  0,			/* 260 infinity */
	177,			/* 261 plusminus */
	  0,			/* 262 less-equal */
	  0,			/* 263 greater-equal */
	165,			/* 264 Yen */
	181,			/* 265 micron */
	  0,			/* 266 delta */
	  0,			/* 267 Sigma */
	  0,            	/* 270 Pi */
	  0,    		/* 271 pi */
	  0,			/* 272 long s (integral) */
	170,			/* 273 a-ordinal */
	186,			/* 274 o-ordinal */
	  0,			/* 275 Omega */
	230,			/* 276 ae ligature */
	248,			/* 277 crossed-o */

	191,    		/* 340 inverted ? */
	161,			/* 341 inverted ! */
	172,			/* 342 negation hook */
	  0,			/* 343 square root */
	  0,			/* 344 florins f */
	  0,			/* 345 approx equal */
	181,			/* 346 Delta */
	171,    		/* 347 << left quote */
	187,    		/* 350 >> right quote */
	0,			/* 351 ... ellipsis */

	0, 0, 0, 0, 0, 0, 	/* 352-357 Unassigned */
	0, 0, 0, 0, 0, 0, 0, 0, /* 360-367 Unassigned */
	0, 0, 0, 0, 0, 0, 0, 0, /* 370-377 Unassigned */
    };

#ifdef	TEST

unsigned char assigned[256];

main()
    {
	int i;

	for (i = 256; --i >= 0; ) assigned[i] = 0;
	for (i = 256; --i >= 0; ) if (ibm2iso[i]) assigned[i]++;
	for (i = 256; --i >= 0; )
	    if (assigned[i] > 1)
		printf("IBM %3d = %#03o is assigned %d times.\n",
		    i, i, assigned[i]);
	for (i = 256; --i >= 0; ) assigned[i] = 0;
	for (i = 256; --i >= 0; ) if (ibm2iso[i]) assigned[i]++;
	for (i = 256; --i >= 0; )
	    if (assigned[i] > 1)
		printf("MAC %3d = %#03o is assigned %d times.\n",
		    i, i, assigned[i]);
	exit(0);
    }

#endif

