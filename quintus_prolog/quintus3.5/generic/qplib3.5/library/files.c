/*  File   : files.c
    Author : Richard A. O'Keefe
    Updated: 3/25/94
    Purpose: Interface to UNIX file system functions.

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    The only difference between these and the UNIX functions is that
    the UNIX functions return 0 for success, -1 for failure, with
    errno set to the error code, while these functions return 0 for
    success or the error code itself (guaranteed non-zero) for failure.
    The Prolog end of things checks the error code and reports the
    message.

    Alas, rename() does not distinguish between errors pertaining to
    the old file name and errors pertaining to the new file name.  On
    reflection, this is difficult to believe!
*/

#ifndef	lint
static	char SCCSid[] = "@(#)94/03/25 files.c	72.1";
#endif

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifdef WIN32
#include <io.h>
#else  /* !WIN32 */
#include <unistd.h>             /* [PM] 3.5 unlink() */
#endif /* !WIN32 */

#include "eaccess.h"

/*  Qrename(oldname, newname)
    either renames the file oldname to newname, returning 0,
    or returns an "errno" code saying why it can't.
    The return codes possible under UNIX are
	ENOTDIR, ENOENT, EACCES, EXDEV, EROFS, EFAULT, EINVAL,
	ENAMETOOLONG, ENOSPC, EDQUOT, EIO, EPERM, ENOTEMPTY,
	ELOOP, EBUSY.
    See man 2 rename for a description of what these codes mean.
*/
int Qrename(oldname, newname)
    char *oldname, *newname;
    {
	return rename(oldname,newname) ? errno : 0;
    }


int Qdelete(oldname)
    char *oldname;
    {
	return unlink(oldname) ? errno : 0;
    }


/*  the forwhat argument has the following interpretation:
	8 * ('append' access needed)
    +   4 * ('read' access needed)
    +   2 * ('write' or 'append' access needed)
    +   1 * ('execute' access needed)
    On UNIX, there is no difference between 'append' and 'write' access,
    and the lower 3 bits have already been coded for access(2).
    Revised in 1988: now calls our saccess() rather than access(2).
*/
int Qaccess(itsname, forwhat)
    char *itsname;
    int   forwhat;
    {
	struct stat sb;

	return stat(itsname, &sb) ? errno
	     : (sb.st_mode & S_IFDIR) ? EISDIR
	     : saccess(&sb, forwhat&7) ? errno
	     : 0;
    }

int Qdaccess(itsname, forwhat)
    char *itsname;
    int   forwhat;
    {
	struct stat sb;

	return stat(itsname, &sb) ? errno
	     : !(sb.st_mode & S_IFDIR) ? ENOTDIR
	     : saccess(&sb, forwhat&7) ? errno
	     : 0;
    }

int Qcanopen(itsname, mode)
    char *itsname;
    int mode;
    {
	int fd;
	struct stat sb;

	return !stat(itsname, &sb) && (sb.st_mode & S_IFDIR) ? EISDIR
	     : (fd = open(itsname,mode)) >= 0 ? ((void)close(fd), 0)
	     : mode == 0 ? errno
	     : (fd = creat(itsname,0777)) < 0 ? errno
	     : ((void)close(fd), (void)unlink(itsname), 0);
    }


