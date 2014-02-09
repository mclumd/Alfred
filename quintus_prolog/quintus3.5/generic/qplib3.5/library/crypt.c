/*  File   : crypt.c
    Author : Richard A. O'Keefe (, Jim Crammond)
    Updated: @(#)crypt.c	76.1 12/10/98
    Purpose: encrypted I/O for Prolog.

    Adapted from shared code written by the same author; all changes
    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    The point of this file is to support a library routine

	crypt_open(+FileName[, +Password], +Mode, -Stream)

    similar to the Quintus Prolog built in routine open/3
    which will let you read, write, or append to an encrypted
    file, with your Prolog code seeing only the clear text
    and the file store holding only the encrypted text.

    You might prefer to use some combination of crypt(1) or
    des(1) with popen(3).  In particular, ed, ex, and VIle
    can read and write files encrypted using crypt(1).  But
    the UNIX manuals warn of crypt(1) and des(1) that these
    programs are "not available on software shipped outside
    the U.S."  This source file is being shipped outside the
    U.S. as well as inside, so it was necessary to use an
    encryption method free from this restriction.
         
    The encryption method presented here is my own original
    work: the method and a version of the source code were
    published in a working paper of the Department of AI at
    the University of Edinburgh (which is not in the U.S.).
    I have been advised that this method has defects; I do
    not know what they are, and this file is not offered as
    a trustworthy or accredited encryption method, but as
    an example of how an encryption method may be used by
    Prolog.  If security is really important to you, you
    should substitute a method of your own choice that you
    have good reason to trust.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)98/12/10 crypt.c	76.1";
#endif/*lint*/

#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#if !WIN32
#include <unistd.h>             /* [PM] 3.5 read() etc */
#endif /* !WIN32 */

#ifdef WIN32

#include <io.h>
typedef unsigned char u_char;

#endif /* WIN32 */

#include "quintus.h"
#include "malloc.h"

#define	mod0 30269
#define mod1 30307
#define mod2 30323

#define mul0 171
#define mul1 172
#define mul2 170

/*  Each of the 16-bit random number generators is advanced by doing
	x = (x * mul) % mod
    where the multiplication should deliver a 32-bit (or wider) product.
    Thus we cast (a) to (long) below.  But lint is too dumb to realise
    that (---) % 30323 is not going to overflow (short), and complains
    about these assignments.  So we shut it up specially.
*/
#ifdef	lint
#define	mulmod(a,b,c) ((a)*(b)%(c))
#else
#define mulmod(a,b,c) (((long)(a) * (b)) % (c))
#endif

#define	BlockSize 4096


typedef struct CryptRecord
    {
	QP_stream qpinfo;
	int	fileid;			/* file descriptor */
	u_char	*chars_ptr;		/* position in buffer */
	int	chars_left;		/* space left in buffer */
	short	mask;			/* running Xor of characters */
	short	r0, r1, r2;		/* random state */
	u_char	buffer[BlockSize];	/* buffer */
    }  *CryptHandle;


static int crypt_read(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    u_char	**bufptr;
    size_t	*sizeptr;
    {
	CryptHandle handle = (CryptHandle) qpstream;
	register u_char *p, *q;
	int	ret;

	if (handle->chars_left == 0)
	{
		register int N, I, t, len;
		short perm[BlockSize];
		u_char buff[BlockSize];

		/*  read in buffer  */
		if ((len = read(handle->fileid, (char *)buff, BlockSize)) == 0)
			return QP_EOF;

		if (len < 0)
		  {
			qpstream->errnum = errno ? errno : QP_E_CANT_READ;
			return QP_ERROR;
		  }

		/*  decrypt buffer */
		for (N = len; --N >=0; perm[N] = N) ;
		for (N = len; N > 0; )
		{	handle->r0 = mulmod(handle->r0, mul0, mod0);
			handle->r1 = mulmod(handle->r1, mul1, mod1);
			handle->r2 = mulmod(handle->r2, mul2, mod2);
			I = ((((handle->r0 << 15)/mod0 +
			       (handle->r1 << 15)/mod1 +
			       (handle->r2 << 15)/mod2) & 077777) * N) >> 15;
			N--;
			t = perm[N], perm[N] = perm[I], perm[I] = t;
		}
		t = handle->mask;
		for (N = len; --N >= 0; )
			handle->buffer[N] = t ^= buff[perm[N]];
		handle->mask = t;

		handle->chars_ptr = handle->buffer;
		handle->chars_left = len;
	}

	/*  make next line of data available  */
	p = handle->chars_ptr;
	q = p + handle->chars_left;
	ret = QP_PART;
	while (p < q)
	{	if (*p++ == '\n')
		{	ret = QP_FULL;
			break;
		}
	}

	*bufptr = handle->chars_ptr;
	*sizeptr = p - handle->chars_ptr;
	handle->chars_ptr = p;
	handle->chars_left = q - p;
	return ret;
    }


static int empty_crypt_output_buffer(handle)
    register CryptHandle handle;
    {
	register int N, I, t, len;
	short perm[BlockSize];
	u_char buff[BlockSize];

	len = handle->chars_ptr - handle->buffer;

	for (N = len; --N >= 0; perm[N] = N) ;
	for (N = len; N > 0; )
	{	handle->r0 = mulmod(handle->r0, mul0, mod0);
		handle->r1 = mulmod(handle->r1, mul1, mod1);
		handle->r2 = mulmod(handle->r2, mul2, mod2);
		I = ((((handle->r0 << 15)/mod0 +
		       (handle->r1 << 15)/mod1 +
		       (handle->r2 << 15)/mod2) & 077777) * N) >> 15;
		N--;
		t = perm[N], perm[N] = perm[I], perm[I] = t;
	}
	I = handle->mask;
	for (N = len; --N >= 0; )
	{	t = handle->buffer[N];
		buff[perm[N]] = I ^ t;
		I = t;
	}
	handle->mask = I;

	if (write(handle->fileid, (char *) buff, len) != len)
		return QP_ERROR;

	return QP_SUCCESS;
    }


static int crypt_write(qpstream, bufptr, sizeptr)
    QP_stream	*qpstream;
    u_char	**bufptr;
    size_t	*sizeptr;
    {
    	register CryptHandle handle = (CryptHandle) qpstream;

	handle->chars_ptr  += *sizeptr;
	handle->chars_left -= *sizeptr;

	if (handle->chars_left == 0)
	{	if (empty_crypt_output_buffer(handle) == QP_ERROR)
		  {
			qpstream->errnum = errno ? errno : QP_E_CANT_WRITE;
			return QP_ERROR;
		  }

		handle->chars_ptr = handle->buffer;
		handle->chars_left = BlockSize;
	}

	*bufptr = handle->chars_ptr;
	*sizeptr = handle->chars_left;
	return QP_SUCCESS;
    }


static int crypt_close(qpstream)
    QP_stream *qpstream;
    {
    	register CryptHandle handle = (CryptHandle) qpstream;

	if (qpstream->mode == QP_WRITE && handle->chars_ptr != handle->buffer)
		(void) empty_crypt_output_buffer(handle);

	(void)close(handle->fileid);
	Free(handle);
	return 0;
    }


/*  We want to derive 3 15-bit numbers and one 8-bit number from the key.
    Since a key is likely to mainly consist of letters, and since we are
    to ignore alphabetic case, we can only get 5 bits per character.  To
    get a 15-bit number we could take 3 letters but this would produce a
    bias in the remainders, so we take 4 letters.  So the key has to be
    at least 14 characters long, and we ignore all but the first 14.
*/

static void unpack_crypt_key(s, handle)
    register char *s;
    register CryptHandle handle;
    {
	register int t;
	char fake_key[16];

	if ((int) strlen(s) < 14) {
	    (void)strcpy(fake_key, "USE LONGER KEY");
	    (void)strcpy(fake_key, s);
	    s = fake_key;
	}
	t = ((s[ 0]&31)<<15) | ((s[ 1]&31)<<10) | ((s[ 2]&31)<<5) | (s[ 3]&31);
	handle->r0 = t%mod0;
	t = ((s[ 4]&31)<<15) | ((s[ 5]&31)<<10) | ((s[ 6]&31)<<5) | (s[ 7]&31);
	handle->r1 = t%mod1;
	t = ((s[ 8]&31)<<15) | ((s[ 9]&31)<<10) | ((s[10]&31)<<5) | (s[11]&31);
	handle->r2 = t%mod2;
	t =					  ((s[12]&15)<<4) | (s[13]&15);
	handle->mask = t;
    }


/*  Make a Quintus Prolog stream that reads or writes the encrypted file
*/
long QPCRSO(FileName, Key, Mode, StreamCode)
    char *FileName;
    char *Key;
    char *Mode;
    QP_stream **StreamCode;
    {
	register CryptHandle handle;
	QP_stream *option;
	int fd, mode;

	*StreamCode = QP_NULL_STREAM;

	switch (*Mode) {
	case 'r':
		mode = QP_READ;
		fd = open(FileName, O_RDONLY, 0);
		break;
	case 'w':
		mode = QP_WRITE;
		fd = open(FileName, O_WRONLY|O_CREAT|O_TRUNC, 0666);
		break;
	case 'a':
		mode = QP_WRITE;
		fd = open(FileName, O_WRONLY|O_CREAT, 0666);
		break;
	default:
		return QP_E_BAD_MODE;
	}

	if (fd < 0) return errno;

	handle = Malloc(CryptHandle, sizeof *handle);
	if (!handle)
	{	(void)close(fd);
		return ENOMEM;
	}

	/* fill the crypt structure */
	handle->fileid = fd;
	handle->chars_ptr = handle->buffer;
	unpack_crypt_key(Key, handle);

	/* get default stream options */
	option = &handle->qpinfo;
	QU_stream_param(FileName, mode, QP_DELIM_LF, option);

	option->max_reclen = BlockSize;
	if (mode == QP_READ)
	{	option->read = crypt_read;
		handle->chars_left = 0;
	}
	else
	{	option->write = crypt_write;
		option->flush = crypt_write;
		handle->chars_left = BlockSize;
	}
	option->close = crypt_close;

	/* set Prolog system fields and register the stream */
	QP_prepare_stream(&handle->qpinfo, handle->buffer);
	if (QP_register_stream(&handle->qpinfo) == QP_ERROR)
	{	(void) crypt_close(&handle->qpinfo);
		return EMFILE;
	}

	*StreamCode = &handle->qpinfo;
	return 0;
    }
