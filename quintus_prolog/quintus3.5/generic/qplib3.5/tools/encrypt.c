/*  File   : encrypt.c
    Author : Richard A. O'Keefe
    Updated: 02 Nov 1988
    Created: 16 February 1984
    Purpose: encrypt and decrypt a file for security.
    Compile: cc -n -s -o encrypt -O encrypt.c
	     ln -s encrypt decrypt
	     ln -s encrypt recrypt

    Adapted from published code written by the same author; all changes
    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This program is described in an Edinburgh DAI working paper.
    The three cases are
	encrypt EncryptionKey <cleartext >ciphertext
	recrypt DecryptionKey EncryptionKey <cipher1text >cipher2text
	decrypt DecryptionKey <ciphertext >cleartext
    This program goes with the Quintus Prolog library(crypt) package.
    NOTE: no claim is made that this program is a generally satisfactory
	  encryption method; on the contrary it is known not to be.
	  (I don't know what the problems are; please let me know.)
	  The program was designed and published in Scotland; it is
	  provided to get around the "don't export crypt(1)" problem.
*/

#ifndef	lint
static	char SCCSid[] = "@(#)88/11/02 encrypt.c	27.1";
#endif/*lint*/

#define	mod0 30269
#define mod1 30307
#define mod2 30323

#define mul0 171
#define mul1 172
#define mul2 170

#define	BlockSize 4096

char	inbuff[BlockSize];
char	exbuff[BlockSize];
short	perm[BlockSize];

int	drand0, drand1, drand2;		/* random state for dePerm */
int	erand0, erand1, erand2;		/* random state for enPerm */

/*  We can actually generate these random numbers without using floating
    point, so the method is suitable for use on 16-bit machines with a
    (16)*(16)->32 multiply and a (32)/(16)->16 divide instruction.  Here
    is the code for those machines
*/

void dePerm(length)
    int length;
    {
	register int N, I, t;

	for (N = length; --N >= 0; perm[N] = N) ;
	for (N = length; N > 0; ) {
	    I = (((((drand0 = ((long)drand0 * mul0) % mod0) << 15)/mod0
	      +	   ((drand1 = ((long)drand1 * mul1) % mod1) << 15)/mod1
	      +	   ((drand2 = ((long)drand2 * mul2) % mod2) << 15)/mod2
	      ) & 077777) * N) >> 15;
	    N--;
	    t = perm[N], perm[N] = perm[I], perm[I] = t;
	}
    }


void enPerm(length)
    int length;
    {
	register int N, I, t;

	for (N = length; --N >= 0; perm[N] = N) ;
	for (N = length; N > 0; ) {
	    I = (((((erand0 = ((long)erand0 * mul0) % mod0) << 15)/mod0
	      +	   ((erand1 = ((long)erand1 * mul1) % mod1) << 15)/mod1
	      +	   ((erand2 = ((long)erand2 * mul2) % mod2) << 15)/mod2
	      ) & 077777) * N) >> 15;
	    N--;
	    t = perm[N], perm[N] = perm[I], perm[I] = t;
	}
    }


/*  gripe(s) writes s on the standard output and exits with failure  */

void gripe(s)
    char *s;
    {
	write(2, s, strlen(s));
	exit(1);
    }


/*  We want to derive 3 15-bit numbers and one 8-bit number from the key.
    Since a key is likely to mainly consist of letters, and since we are
    to ignore alphabetic case, we can only get 5 bits per character.  To
    get a 15-bit number we could take 3 letters but this would produce a
    bias in the remainders, so we take 4 letters.  So the key has to be
    at least 14 characters long, and we ignore all but the first 14.  As
    the "ps" command will display argument strings, we have to smash the
    string as soon as we have looked at it.
*/

int getkey(s, k0, k1, k2)
    register char *s;
    int *k0, *k1, *k2;
    {
	register int t;

	if (s == 0 || strlen(s) < 14) return -1;
	t = ((s[ 0]&31)<<15) | ((s[ 1]&31)<<10) | ((s[ 2]&31)<<5) | (s[ 3]&31);
	*k0 = t%mod0;
	t = ((s[ 4]&31)<<15) | ((s[ 5]&31)<<10) | ((s[ 6]&31)<<5) | (s[ 7]&31);
	*k1 = t%mod1;
	t = ((s[ 8]&31)<<15) | ((s[ 9]&31)<<10) | ((s[10]&31)<<5) | (s[11]&31);
	*k2 = t%mod2;
	t =					  ((s[12]&15)<<4) | (s[13]&15);
	strcpy(s, "not now a key.");
	return t;
    }


void main(argc, argv)
    char **argv;
    int argc;
    {
	int decrypt, encrypt;
	register int N, dmask, emask;
	int length;
	
	/*  Decode the arguments  */
	/*  Argument 0 is the command name, {de|en|re}recrypt  */
	/*  We only examine the first letter, and that ignoring case  */
	/* We have to skip over leading directory/ components to find */
	/* the initial.						      */
	{
	    register char *s = *argv;
	    register int initial = *s;
	    register int c;
#ifdef	unix
	    while (c = *s++) if (c == '/') initial = *s;
#else
#ifdef	vms
	    while (c = *s++) if (c == '/' || c == ']') initial = *s;
#else	/*neither*/
	    while (c = *s++) if (c == '/' || c == '\\') initial = *s;
#endif/*vms*/
#endif/*unix*/
	    switch (initial|32) {
		case 'd': decrypt = 1, encrypt = 0; break;
		case 'e': decrypt = 0, encrypt = 1; break;
		case 'r': decrypt = 1, encrypt = 1; break;
		default : gripe("command must be {de,en,re}crypt\n");
	    }
	}

	if (decrypt) {		/* Decryption key */
	    argv++, argc--;
	    if (argc <= 0) gripe("missing decryption key\n");
	    dmask = getkey(*argv, &drand0, &drand1, &drand2);
	    if (dmask < 0) gripe("decryption key shorter than 14 characters\n");
	}

	if (encrypt) {		/* Encryption key */
	    argv++, argc--;
	    if (argc <= 0) gripe("missing encryption key\n");
	    emask = getkey(*argv, &erand0, &erand1, &erand2);
	    if (emask < 0) gripe("encryption key shorter than 14 characters\n");
	}

	if (argc > 1) {		/* There should be no more arguments */
	    gripe("file name arguments are not accepted\n");
	}

	while ((length = read(0, inbuff, BlockSize)) != 0) {

	    if (decrypt) {
		dePerm(length);
		for (N = length; --N >= 0; )
		    exbuff[N] = dmask ^= inbuff[perm[N]];
		if (encrypt)
		    for (N = length; --N >= 0; inbuff[N] = exbuff[N]) ;
	    }

	    if (encrypt) {
		enPerm(length);
		for (N = length; --N >= 0; )
		    exbuff[perm[N]] = emask ^ inbuff[N], emask = inbuff[N];
	    }

	    write(1, exbuff, length);
	}
    }

