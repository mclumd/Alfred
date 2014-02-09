/*  File   : strings.c
    Author : Richard A. O'Keefe
    Updated: 04/20/99
    Purpose: C-coded half of the "string" primitives.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    These routines are given string pointers from Prolog.  The
    preceding two bytes are a length field.  So we don't need
    to scan along the name to find out how long it is.

    BEWARE!!!  The structure of Quintus Prolog's symbol table is
    subject to change without notice!  Do NOT assume that this
    file will work in any release of Quintus Prolog other than the
    one it is supplied with!
*/

#ifndef	lint
static	char SCCSid[] = "@(#)99/04/20 strings.c	76.5";
#endif/*lint*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "quintus.h"

typedef char byte;

int Qstrlen(atom)			/* return length of atom */
    QP_atom atom;
    {
	return QP_atomlength(QP_string_from_atom(atom));
    }


int Qstrchr(n, atom)			/* return Nth character of atom */
    register int n;			/* ONE-origin, hence --n below */
    QP_atom atom;
    {
	register byte *s = QP_string_from_atom(atom);

	return (n > (int) QP_atomlength(s) || --n < 0 ? -1 : s[n]);
    }


int Qatomch(atom)			/* return 1st byte of 1-byte atom */
    QP_atom atom;
    {
	register byte *s = QP_string_from_atom(atom);

	return QP_atomlength(s) == 1 ? s[0] : -1;
    }


QP_atom Qchatom(c)			/* return 1-byte atom of given name */
    int c;
    {
	static QP_atom table[256] =	/* byte -> atom */
	    { 0 };			/* has initialisation been done? */

	if (!table[0]) {		/* build the table when first called */
	    register int d;		/* You can rely on 0 NOT being a */
	    byte buff[2];		/* possible atom code. */

	    buff[1] = 0;		/* NUL termination */
	    for (d = (sizeof table)/(sizeof table[0]); --d >= 0; ) {
		buff[0] = d;
		table[d] = QP_atom_from_string(buff);
	    }
	}
	return table[c];		/* alas, Qchatom(0) = '' */
    }


int Qindex(source, target, drop)
    QP_atom source;			/* scan this string */
    QP_atom target;			/* looking for this one */
    int drop;				/* start here+1 */
    {
	byte *src = QP_string_from_atom(source);
	byte *pat = QP_string_from_atom(target);
	register byte *p, *s;
	register int L, k;

	L = QP_atomlength(src)-QP_atomlength(pat)-(drop++);
	if (drop < 0) return -1;
	for (; --L >= 0; drop++) {
	    for (p = pat, s = src+drop, k = QP_atomlength(p); --k >= 0; )
		if (*s++ != *p++) goto Next;
	    return drop;
Next:;	}
	return -1;
    }


/*  Qcmpstr(str1, drop1, take1, pad1,  str2, drop2, take2, pad2)
    compares two substrings.  The strings to be compared are
	take1 .TAKE drop1 .DROP str1
	take2 .TAKE drop2 .DROP str2
    where .TAKE and .DROP are the usual APL operations.
    Unless 0 =< drop1, we return the error indicator '?'.
    If take1 < 0, take1 := length(str1)-drop1.  Then,
    Unless 0 =< take1 and drop1+take1 =< length(str1), return '?'.
    The arguments for str2 are processed similarly.
    Note that this routine is not intended to be called in its
    full generality; this is just me having fun in C.
    If take1 < take2, substring 1 is extended with pad1.
    If take2 > take1, substring 2 is extended with pad2.
    Thus to compare two strings with blank padding,
	Qcmpstr(str1, 0, -1, 32, str2, 0, -1, 32)
    and to compare two strings as the Prolog @< operation would,
	Qcmpstr(str1, 0, -1, -1, str2, 0, -1, -1)
    We return a one-character atom, obtained from Qchatom().
    There are four cases:
	'?'	-- an error occurred
	'<'	-- substring 1 is less than substring 2
	'='	-- the two substrings are equal
	'>'	-- substring 1 is greater than substring 2
*/
QP_atom Qcmpstr(atom1, drop1, take1, pad1, atom2, drop2, take2, pad2)
    QP_atom atom1, atom2;	/* the strings */
    int    drop1, drop2;	/* offset */
    int    take1, take2;	/* length of substring */
    int     pad1,  pad2;	/* padding character */
    {
	register byte *src1 = QP_string_from_atom(atom1);
	register byte *src2 = QP_string_from_atom(atom2);
	int len1 = QP_atomlength(src1);
	int len2 = QP_atomlength(src2);
	register int len;
	register int dif;
	register int pad;

	if (take1 < 0) take1 = len1-drop1;
	if (take2 < 0) take2 = len2-drop2;
	if (drop1 < 0 || take1 < 0 || take1+drop1 > len1
	||  drop2 < 0 || take2 < 0 || take2+drop2 > len2)
	    return Qchatom('?');
	src1 += drop1;
	src2 += drop2;
	if (take1 <= take2) len = take1, take1 = 0, take2 -= len, pad = pad2;
	else		    len = take2, take2 = 0, take1 -= len, pad = pad1;
	while (--len >= 0)
          if ((dif = (*src1++ - *src2++)))
            return Qchatom(dif < 0 ? '<' : '>');
	if (take1 > 0) {
	    if (pad < 0) return Qchatom('>');
	    for (len = take1; --len >= 0; )
              if ((dif = (*src1++ - pad)))
                return Qchatom(dif < 0 ? '<' : '>');
	} else
	if (take2 > 0) {
	    if (pad < 0) return Qchatom('<');
	    for (len = take2; --len >= 0; )
              if ((dif = (pad - *src2++)))
                return Qchatom(dif < 0 ? '<' : '>');
	}
	return Qchatom('=');
    }


/*  The next section of code implements atom_chars and number_chars.
    Basically, there are two groups.

    The Qp group p(uts) things into the byte buffer.
    A routine in this group will return -1 if anything goes wrong,
    or the (new) size of the byte buffer if all went well.  The
    routines are designed so that you can just keep putting things
    into the byte buffer and check at the end that there was room
    for it all.  Note that at all times the byte buffer is valid.

    The Qg group g(ets) things from the byte buffer.
    Routines in this group follow the same drop+take approach to
    substrings that is used throughout this string package.  You
    specify the number of characters from the front of the byte
    buffer that are NOT to be used (the number to DROP) and then
    the number that ARE to be used (the number to TAKE).  If the
    bounds are in range, the desired segment will be returned,if
    not -1 is returned.  Because the C routines expect final NUL
    the get routines will put a NUL in, call a C routine, & then
    put the original character back.
*/

#define DLIMIT	25		/* >= max number chars generated by format %ld */
#define FLIMIT	25		/* >= max number chars generated by format %.15E */
#define BUFSIZ_INCR	512
static	int	buffer_size = 0;
static	byte*	byte_buffer;
static	int	bl;

/*
    grow_byte_buffer ensures the byte buffer is big enough to fit an extra len
    bytes.  Now the atom size limit is 64Kbytes, we grow the byte buffer
    dynamically in 512 byte increments on demand to avoid wasting space.
*/

static byte *grow_byte_buffer(len)
    register int len;
    {
	byte	*bp;

	len += bl;
	if (len < buffer_size)
		return byte_buffer + bl;

	if (len > QP_MAX_ATOM)
		return NULL;

	while (buffer_size < len)
		buffer_size += BUFSIZ_INCR;

	if ((bp = QP_malloc(buffer_size)) == NULL)
		return NULL;
	memcpy(bp, byte_buffer, bl);
	QP_free(byte_buffer);

	byte_buffer = bp;
	bp += bl;

	return bp;
    }

void QpInit()			/* empty the byte buffer */
    {
	if (buffer_size == 0)
	{	buffer_size = BUFSIZ_INCR;
		byte_buffer = QP_malloc(buffer_size);
	}
	bl = 0;
    }


int QpAtom(atom)		/* drop an atom into the byte buffer */
    QP_atom atom;
    {
	register byte *s = QP_string_from_atom(atom);
	register int L = QP_atomlength(s);
	register byte *d;

	if (!(d = grow_byte_buffer(L)))
		return -1;
	bl += L;
	while (--L >= 0) *d++ = *s++;
	return bl;
    }

int QpPart(atom, drop, take)	/* drop a substring into the byte buffer */
    QP_atom atom;
    int drop, take;
    {
	register byte *s = QP_string_from_atom(atom);
	register int L = QP_atomlength(s);
	register byte *d;

	if (drop < 0 || take < 0 || drop+take > L) return -1;
	L = take;
	if (!(d = grow_byte_buffer(L)))
		return -1;
	bl += L;
	for ( s+= drop; --L >= 0; *d++ = *s++) ;
	return bl;
    }


int QpInt(num)			/* drop a integer into the buffer */
    long num;
    {
	register byte *p;
	if (!(p = grow_byte_buffer(DLIMIT)))
		return -1;
	(void)sprintf((char*)p, "%ld", num);
	while (*p) p++;
	bl = p - byte_buffer;
	return bl;
    }


int QpFlt(num)			/* drop a float into the buffer */
    double num;
{
  byte *p, *q;
  byte *buffer = grow_byte_buffer(FLIMIT);

  if (!buffer)
    return -1;

  (void)sprintf((char *)buffer, "%.15E", num);
  if (*buffer == 'I') {
    (void)strcpy((char *)buffer, num >= 0.0 ? "+Infinity" : "-Infinity");
    q = buffer + strlen((char *)buffer);
    goto ret;
  }
  /*  Now, we want to set p to the place in the buffer where the */
  /*  pattern "[eE][+-][0-9][0-9]*$" matches.  This is easy:  we */
  /*  start at the end and work backwards.  */
  p = buffer + strlen((char *)buffer);
  while ((unsigned)(*--p-'0') < 10) ;
  /*  p now points to the character just before a final span of  */
  /*  digits.  We've only to check for [eE][+-]  */
  if (*p != 'E') --p;
  /* now we have to trim intermediate .000000s */
  for (q = p; q >= buffer+2 && q[-1] == '0' && q[-2] != '.'; q--) ;
  while ((*q++ = *p++)) ;
  --q;
ret:
  bl = q - byte_buffer;
  return bl;
}


int QpFour(c1, c2, c3, c4)	/* drop four 8-bit characters */
    int c1, c2, c3, c4;
    {
	register byte *p;
	if (!(p = grow_byte_buffer(4)))
		return -1;
	*p++ = c1, *p++ = c2, *p++ = c3, *p++ = c4;
	bl += 4;
	return 0;
    }

int QpOne(c1)			/* drop one 8-bit character */
    int c1;
    {
	register byte *p;
	if (!(p = grow_byte_buffer(1)))
		return -1;
	*p++ = c1;
	bl += 1;
	return 0;
    }


int QgInit()
    {
	return bl;
    }


int QgAtom(drop, take, atom)	/* extract an atom from the byte buffer */
    int drop, take;
    QP_atom *atom;
    {
	int save;
	register byte *p = byte_buffer+drop;
	register byte *q = byte_buffer+take;

	if (drop < 0 || take < 0 || drop+take > bl) return -1;
	save = *q; *q = 0;
	*atom = QP_atom_from_string(p);
	*q = save;
	return 0;
    }

#define	isdig(x) ((unsigned)((x)-'0') < 10)

int QgNum(drop, take, fix, flt)/* extract a number from the byte buffer */
    int drop, take;
    long *fix;			/* it could be an integer (return 0) */
    double *flt;		/* or it could be a float (return 1) */
    {				/* WE SHOULD CHECK THE RANGE! */
	int save;
	register byte *p = byte_buffer+drop;
	register byte *q = byte_buffer+take;
	register byte *s = p;
	register int state = 0;

	*fix = 0, *flt = 0.0;
	if (drop < 0 || take < 0 || drop+take > bl) return -1;
	save = *q; *q = 0;
	if (*s == '+' || *s == '-') s++;
	if (isdig(*s)) {
	    do s++; while (isdig(*s));
	    if (*s == 0) {
		*fix = atol((char*)p);
		*q = save;
		return 0;
	    }
	    state++;	/* digits seen */
	}
	if (*s == '.') s++; else goto Fail;
	while (isdig(*s)) state++, s++;
	if (state == 0) goto Fail;
	if ((*s|32) == 'e') {
	    s++;
	    if (*s == '+' || *s == '-') s++;
	    if (!isdig(*s)) goto Fail;
	    while (isdig(*s)) s++;
	}
	if (*s != 0) goto Fail;
	*flt = atof((char*)p);
	*q = save;
	return 1;
Fail:	*q = save;
	return -1;
    }


int QgFour(drop, c1, c2, c3, c4)	/* pick up four characters */
    register int drop;
    long *c1, *c2, *c3, *c4;
    {
	register byte *p = byte_buffer+drop;
	if (drop < 0 || drop+4 > bl) return -1;
	*c1 = *p++, *c2 = *p++, *c3 = *p++, *c4 = *p++;
	return 0;
    }

int QgOne(drop, c1)			/* pick up one character */
    register int drop;
    long *c1;
    {
	if (drop < 0 || drop >= bl) return -1;
	*c1 = byte_buffer[drop];
	return 0;
    }


/*  Substring operations.
    Qsubchk(source, drop, take, target)
    is true (returns 0) when target = take .TAKE drop .DROP source
    Qsubstr(source, drop, take, substr)
    assigns substr <- take .TAKE drop .DROP source
    and succeeds (returns 0) when this makes sense,
    otherwise assigns substr <- '' and fails (returns -1).
*/

int Qsubchk(source, drop, take, target)
    QP_atom source;			/* source string */
    int drop, take;			/* identify segment of source */
    QP_atom target;			/* does this equal segment? */
    {
	register byte *s = QP_string_from_atom(source);
	register byte *t = QP_string_from_atom(target);
	register int L = QP_atomlength(t);

	if (drop < 0 || take != L || drop+L > (int) QP_atomlength(s))
	    return -2;			/* segment bounds bad */
	s += drop;			/* skip the first drop characters */
	while (--L >= 0)		/* check "take" characters */
	    if (*s++ != *t++) return -1;/* bounds ok but data unequal */
	return 0;			/* bounds ok, data equal */
    }


int Qsubstr(source, drop, take, substr)
    QP_atom source;			/* source string */
    int drop, take;			/* identify segment of source */
    QP_atom *substr;			/* substring to be created */
    {
	register byte *s = QP_string_from_atom(source);
	register byte *d;		/* substring is built in byte_buffer */
	register int L = take;

	QpInit();
	if (!(d = grow_byte_buffer(L+1))) /* +1 for NUL */
		return -1;
	if (drop < 0 || L < 0 || drop+L > (int) QP_atomlength(s)) {
	    *substr = Qchatom(0);	/* actual value matters not */
	    return -2;			/* segment bounds bad */
	}
	bl = L;				/* substring will be this long */
	s += drop;
	while (--L >= 0) *d++ = *s++;
	*d = 0;				/* NUL terminator for */
	*substr = QP_atom_from_string(byte_buffer);
	return 0;
    }


/*  Qoutchk(source, drop, take, target)
    is true (returns 0) when
	target = (drop .TAKE source) , ((drop+take) .DROP source)
    it returns -2 if the parameters are invalid, -1 for other failure.
    Qoutstr(source, drop, take, substr)
    succeeds (returns 0) and assigns
	substr <- (drop .TAKE source) , ((drop+take) .DROP source)
    when this makes sense, otherwise fails (returns -1) and assigns
	substr <- '' and fails (returns -1).
*/

int Qoutchk(source, drop, take, target)
    QP_atom source;			/* source string */
    int drop, take;			/* identify segment of source */
    QP_atom target;			/* substring to be checked */
    {
	register byte *s = QP_string_from_atom(source);
	register byte *t = QP_string_from_atom(target);
	int back = QP_atomlength(t)-drop;
	register int L;

	if (drop < 0 || take < 0 || back < 0 ||
	    QP_atomlength(s)-QP_atomlength(t) != take) {
	    return -2;			/* segment bounds bad */
	}
	for (L = drop; --L >= 0; )
	    if (*s++ != *t++) return -1;
	s += take;
	for (L = back; --L >= 0; )
	    if (*s++ != *t++) return -1;
	return 0;
    }


int Qoutstr(source, drop, take, substr)
    QP_atom source;			/* source string */
    int drop, take;			/* identify segment of source */
    QP_atom *substr;			/* substring to be created */
    {
	register byte *s = QP_string_from_atom(source);
	register byte *d;		/* substring is built in buffer */
	register int L = QP_atomlength(s)-take;	/* substring will be this long */

	QpInit();
	if (!(d = grow_byte_buffer(L+1))) /* +1 for NUL */
	    return -1;
	if (drop < 0 || take < 0 || L > (int) QP_atomlength(s)) {
	    *substr = Qchatom(0);	/* actual value matters not */
	    return -2;			/* segment bounds bad */
	}
	bl = L;
	for (L = drop; --L >= 0; ) *d++ = *s++;
	s += take;
	for (L = bl-drop; --L >= 0; ) *d++ = *s++;
	*d = 0;				/* NUL terminator for */
	*substr = QP_atom_from_string(byte_buffer);
	return 0;
    }


int Qinsstr(source, where, insert, dest)
    QP_atom source;
    int where;
    QP_atom insert;
    QP_atom *dest;
    {
	register byte *s = QP_string_from_atom(source);
	register byte *r = QP_string_from_atom(insert);
	register byte *d;		/* substring is built in buffer */
	register int L = QP_atomlength(s) + QP_atomlength(r);
	int i;

	QpInit();
	if (!(d = grow_byte_buffer(L+1))) /* +1 for NUL */
	    return -1;

	i = QP_atomlength(s);
	if (where < 0 || where > i) {
	    *dest = Qchatom(0);
	    return -2;
	}
	for (L = where; --L >= 0; ) *d++ = *s++;
	for (L = QP_atomlength(r); --L >= 0; ) *d++ = *r++;
	for (L = i-where; --L >= 0; ) *d++ = *s++;
	*d = 0;
	*dest = QP_atom_from_string(byte_buffer);
	return 0;
    }


/*  The next routine implements the Prolog predicate
	span(String, Set, Before, Length, After).
    The Prolog end verifies that String is an atom and that Set is
    an atom or a non-empty list of characters, and puts Set in the
    byte buffer.  This routine is given String and returns the
    three numbers.  The Length is returned as the function result,
    because that is what we check to see if Mesos is non-empty.
    The Set has already been copied into the byte buffer.
    String is passed as the "atom" parameter.
    Before and After are passed as the "before" and "after" parameters.
    Length is returned as the result (it may be 0).
    Flag codes the operation (and whether to build a new set).
    We currently always build a new set.
*/

static unsigned char set_vec[256]; /* QP #1110 --matsc */
static unsigned int  set_ctr = 256;


int Qspan(atom, flag, before, after)
    QP_atom atom;
    int flag;
    long *before, *after;
    {
	int len;
	register int L;
	register unsigned char *p;
	register byte *s;

	if (!(flag&8)) {		/* new set */
	    if (++set_ctr > 255) {	/* clear set_vec */
		for (p = set_vec, L = sizeof set_vec; --L >= 0; ) *p++ = 0;
		set_ctr = 1;
	    }
	    for (p = (unsigned char *)byte_buffer, L = bl; --L >= 0; )
	      set_vec[*p++] = set_ctr;
	}
	s = QP_string_from_atom(atom);
	len = L = QP_atomlength(s);
	p = (unsigned char *)s;
	switch (flag&7) {
	    case 0: case 1:		/* bogus */
		*before = 0, *after = 0;
		break;

	    case 2:		/* scan from RIGHT, use TRUE set */
		p += L, p--;
		/* skip over characters not in set */
		while (L > 0 && set_vec[*p] != set_ctr) L--, p--;
		*after = len-L;
		/* skip over characters which are in set */
		while (L > 0 && set_vec[*p] == set_ctr) L--, p--;
		*before = L;
		break;

	    case 3:		/* scan from RIGHT, use COMPLEMENT set */
		p += L, p--;
		/* skip over characters which are in set */
		while (L > 0 && set_vec[*p] == set_ctr) L--, p--;
		*after = len-L;
		/* skip over characters not in set */
		while (L > 0 && set_vec[*p] != set_ctr) L--, p--;
		*before = L;
		break;

	    case 4:		/* scan from LEFT, use TRUE set */
		/* skip over characters not in set */
		while (L > 0 && set_vec[*p] != set_ctr) L--, p++;
		*before = len-L;
		/* skip over characters which are in set */
		while (L > 0 && set_vec[*p] == set_ctr) L--, p++;
		*after = L;
		break;

	    case 5:		/* scan from LEFT, use COMPLEMENT set */
		/* skip over characters which are in set */
		while (L > 0 && set_vec[*p] == set_ctr) L--, p++;
		*before = len-L;
		/* skip over characters not in set */
		while (L > 0 && set_vec[*p] != set_ctr) L--, p++;
		*after = L;
		break;

	    case 6:		/* TRIM edges, use TRUE set */
		/* skip over characters not in set */
		while (L > 0 && set_vec[*p] != set_ctr) L--, p++;
		*before = len-L;
		p += L;
		/* skip over characters not in set */
		while (L > 0 && set_vec[*--p] != set_ctr) L--;
		*after = len-*before-L;
		break;

	    case 7:		/* TRIM edges, use COMPLEMENT set */
		/* skip over characters which are in set */
		while (L > 0 && set_vec[*p] == set_ctr) L--, p++;
		*before = len-L;
		p += L;
		/* skip over characters which are in set */
		while (L > 0 && set_vec[*--p] == set_ctr) L--;
		*after = len-*before-L;
		break;
	}
	return len-*before-*after;
    }


int Qsystem()
    {
	byte_buffer[bl] = 0;
	return system((char*)byte_buffer);
    }

