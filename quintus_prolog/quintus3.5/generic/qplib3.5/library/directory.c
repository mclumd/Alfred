/*  File   : directory.c
    Author : Richard A. O'Keefe
    Updated: 03/12/99
    Purpose: Directory scanning code for Prolog.
    SeeAlso: directory.pl, man directory(3), stat(2)

    Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

    This file uses the Berkeley directory reading routines.
    It includes fakes for System 5; use cc -DSYS5 to get them.
    There is a public-domain implementation of them for V7
    and System V which we should locate and use on System V.
    I suspect that making the directory scanning routines
    work on the VMS or 1108 operating systems will require
    some major rethinking.

    Some of the routines accessed from Prolog are

	QDtest(Directory, Pattern, Must, Mustnt, Name, Full)

	    This is used when the first five parameters are
	    known.  It checks that the Name matches the given
	    pattern, that there is a file of that Name in that
	    Directory, that it has the mode bits it Must have,
	    lacks those it Mustnt have, and constructs the
	    Full pathname of the file.  It just returns a 0/1
	    code, and doesn't report errno properly (yet).
	    It also has to check that Name has no / in it.

	QDinit(Directory, Pattern, Must, Mustnt)

	    Directory is the UNIX pathn of a directory.
	    If the opendir() call fails, the UNIX error
	    code is returned, otherwise 0 is returned.
	    The Prolog end will report an error if the
	    argument doesn't name a valid directory.
	    We rely on the fact that the string isn't
	    going to move; in the released version we
	    shouldn't do that.

	    Pattern is a pattern.  I don't know quite what
	    to do about patterns.  For the moment it accepts
	    * and ? and nothing else.  Eventually, we should
	    use the public-domain regcmp() and regexp()
	    code by Stallman, and provide the source code to
	    comply with his requirements.  It is of course a
	    Prolog atom, passed as a string.  We rely on the
	    fact that the string isn't going to move.

	    Must is a set of bits which must be set in the
	    mode of the files we find.  Mustnt is a set of
	    bits which must not be set in those modes.

	    If "dirp" was non-NULL when QDinit was called,
	    it is assumed that it was left open when an
	    earlier directory scan was aborted by ^C, and
	    it is closed.

	    QDinit returns 0 if it is successful, otherwise
	    it returns an errno code.

	QDnext(Name, FullName)

	    We return the file name that we found, and also
	    the full name.  In UNIX that is easy, we take
	    Directory/Name as FullName.

	    When there are no more (stat-able) names in the
	    directory, QDnext closes the directory and returns
	    1, otherwise it returns 0.  This is so that 0 is
	    "all went well" for both routines.

	QDhere(-Name)

	    Returns the absolute path-name of the current directory.
*/

#include <errno.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>             /* [PM] 3.5 strcmp */
#if WIN32
/* [PM] 3.5 FIXME: where is getcwd */
#else  /* !WIN32 */
#include <unistd.h>             /* [PM] 3.5 getcwd */
#endif /* !WIN32 */

#include "quintus.h"
#include "eaccess.h"

#ifndef	lint
static	char SCCSid[] = "@(#)99/03/12 directory.c	76.2";
#endif/*lint*/

#if SUNOS4

#include <sys/dir.h>
#define dirent direct

#elif WIN32

#include <direct.h>
#include <io.h>
#include <string.h>
#include "wdirent.h"

#define NO_ST_BLKSIZE

#else

#include <dirent.h>

#endif

static	DIR*	dirp = NULL;	/* currently open directory */
static	char*	pattern = NULL;	/* what to match against */
static	char	dname[1028];	/* directory name */
static	char*	dtail;		/* points just after / in dname */
static	unsigned short must, mustnt;	/* mode masks */
static	char	star[] = "*";	/* the most general pattern */
static	char	dot[] = ".";	/* "self" directory name */
static	char 	dotdot[] = "..";/* "parent" directory name */


char *QDhere()
    {
#if SUNOS4
	return getwd(dname) ? dname : ".";
#else  /* !SUNOS4 */
	QP_UNIXPATH(getcwd(dname, sizeof dname));
	return dname;
#endif /* !SUNOS4 */
    }


int QDinit(Directory, Pattern, Must, Mustnt)
    char *Directory, *Pattern;
    int Must, Mustnt;
    {
	register char *src, *dst;

	if (dirp) closedir(dirp);
	dirp = opendir(Directory);
	if (!dirp) return errno;
	for (src = Directory, dst = dname; (*dst++ = *src++); ) ;
	dst--;		/* now points to NUL */
	if (dst != dname && dst[-1] != '/') {
	    /* add a trailing / if required */
	    *dst++ = '/'; *dst = 0;
	}
	dtail = strcmp(dname, "./") ? dst : dname;
	pattern = Pattern && strcmp(Pattern, star) ? Pattern : NULL;
	must = Must;
	mustnt = Mustnt;
	return 0;
    }


static int QDmatch(Name, Pattern)
    register char *Name, *Pattern;
    {
	register int c;

	while ((c = *Pattern++))
	    if (c == '*') {
		/* match an arbitrary string */
		/* skip over any following '*' or '?' */
		for (; (c = *Pattern); Pattern++)
		    if (c == '*') continue; else
		    if (c != '?') break; else
		    if (!*Name++) return 0;
		/* if the pattern is now empty, it must match */
		if (!c) return 1;
		for (; *Name; Name++)
		    if (QDmatch(Name, Pattern)) return 1;
		return 0;
	    } else
	    if (c == '?') {
		if (!*Name++) return 0;
	    } else {
		if (*Name++ != c) return 0;
	    }
	return !*Name;
    }


int QDnext(Name, FullName)
    char **Name, **FullName;
    {
	register char *src, *dst;
	register struct dirent *dp;
	struct stat buf;

	*Name = *FullName = dot;
	while ((dp = readdir(dirp)))
	    if (dp->d_ino != 0
	    && strcmp(dp->d_name, dot)
	    && strcmp(dp->d_name, dotdot)
	    && (pattern == NULL || QDmatch(dp->d_name, pattern))) {
		for (src = dp->d_name, dst = dtail; (*dst++ = *src++); ) ;
		if (!stat(dname, &buf)
		&&  (buf.st_mode & must) == must
		&&  (buf.st_mode & mustnt) == 0) {
		    *Name = dtail, *FullName = dname;
		    return 0;
		}
	    }
	closedir(dirp);
	dirp = NULL;
	return 1;
    }


int QDpart(Directory, Must, Mustnt, Name, FullName)
    char **Directory;
    int Must, Mustnt;
    char **Name;
    char *FullName;
    {
	char *svs, *svd;
	register char *src, *dst;
	register int c;
	struct stat buf;

	*Directory = *Name = dot;
	if (stat(FullName, &buf)
	||  (buf.st_mode & Must) != Must
	||  (buf.st_mode & Mustnt) != 0)
	    return 1;
	for (svs = src = FullName, svd = NULL, dst = dname;
	/* while */ (c = *src++);
	/* doing */ *dst++ = c) /* do */
	    if (c == '/') svd = dst, svs = src;
	if (!strcmp(svs, dot) || !strcmp(svs, dotdot))
	    return 1;
	if (svd) *svd = 0, *Directory = dname;
	*Name = svs;
	return 0;	/* it worked */
    }


int QDtest(Directory, Pattern, Must, Mustnt, Name, FullName)
    char *Directory, *Pattern;
    int Must, Mustnt;
    char *Name;
    char **FullName;
    {
	register char *src, *dst;
	register int c;
	struct stat buf;

	*FullName = dot;
	if (Pattern && strcmp(Pattern, star) && !QDmatch(Name, Pattern))
	    return 1;	/* not ok */
	if (!strcmp(Name, dot) || !strcmp(Name, dotdot))
	    return 1;	/* not supposed to exist */
	/* this cannot be called while a scan is in progress */
	/* so it is safe to smash dname */
	for (src = Directory, dst = dname; (*dst++ = *src++); ) ;
	dst--;		/* now points to NUL */
	if (dst != dname && dst[-1] != '/') {
	    /* add a leading / if required */
	    *dst++ = '/'; *dst = 0;
	}
	if (!strcmp(dname, "./")) dst = dname;
	for (src = Name; (c = *src++); *dst++ = c)
	    if (c == '/') return 1;
	*dst = 0;
	if (!stat(dname, &buf)
	&&  (buf.st_mode & Must) == Must
	&&  (buf.st_mode & Mustnt) == 0) {
	    *FullName = dname;
	    return 0;
	}
	return 1;
    }

/*  The following code implements the {file,directory}_property stuff.
    uid/gid are mapped to atoms.  Note that it is important to use the
    section 3 routines getgrgid() and getpwuid() rather than scanning
    /etc/group or /etc/passwd ourselves, as NFS systems use the "Yellow
    Pages" mechanism instead, and the /etc files are not to be relied
    on.  Elsewhere, it is possible that these routines may be simulated,
    without the files existing.
*/

#ifndef WIN32
#include <pwd.h>
#include <grp.h>
#endif

int QDname(Id, GroupWanted, Name)
    int Id;		/* the uid or gid */
    int GroupWanted;	/* true/false for gid/uid */
    char **Name;	/* the name to return */
    {
#if WIN32
	*Name = "";
#else
	*Name = dot;	/* parepare to fail */
	if (GroupWanted) {
	    struct group *entp = getgrgid(Id);

	    if (!entp) return errno;
	    *Name = entp->gr_name;
	} else {
	    struct passwd *entp = getpwuid(Id);

	    if (!entp) return errno;
	    *Name = entp->pw_name;
	}
#endif
	return 0;
    }


int QDprop(Thing, ThingType, Index, Result)
    char *Thing;	/* what to look at */
    char *ThingType;	/* "file" or "directory" */
    int   Index;	/* which property is wanted */
    long *Result;	/* result */
    {
	struct stat buf;
	long ans;

	*Result = 0;	/* default */
	if (stat(Thing, &buf)) return errno;
	if (*ThingType == 'd') {
	    if (!(buf.st_mode & S_IFDIR)) return ENOTDIR;
	} else
	if (*ThingType == 'f') {
	    if (!(buf.st_mode & S_IFREG)) return EISDIR;
	} else {
	    return EINVAL;
	}

	if (Index < 10) {
	    /*  This is an access() case  */
	    ans = saccess(&buf, Index) == 0;
	} else
	if (Index < 16) {
	    /*  This is a timestamp, may take 32 bits  */
	    switch (Index) {
		case 10: ans = buf.st_atime; break;
		case 11: ans = buf.st_mtime; break;
		case 12: ans = buf.st_ctime; break;
		default: return EINVAL;
	    }
	} else
	if (Index < 32) {
	    /*  These are mode bit tests  */
	    ans = (buf.st_mode >> (Index-16)) & 0111;
	} else {
	    /*  The remainder are miscellaneous  */
	    switch (Index) {
		case 40: ans = buf.st_uid;	break;
		case 41: ans = buf.st_gid;	break;
		case 42: ans = buf.st_nlink==1;	break;
		case 43: ans = buf.st_nlink;	break;
		case 44: ans = buf.st_size;	break;
#ifdef NO_ST_BLKSIZE
		case 45: ans = ((buf.st_size|511)+1) >> 9; break;
		case 46: ans = 512;		break;
#else
		case 45: ans = buf.st_blocks;	break;
		case 46: ans = buf.st_blksize;	break;
#endif
		default: return EINVAL;
	    }
	}
	*Result = ans;
	return 0;
    }


#if WIN32

/* UNIX-compatible dirent(5) functions for Windows/NT */

DIR *
opendir(const char *dirname)
{
	static char path[_MAX_PATH+2];
	struct stat sbuf;
	struct _finddata_t data;
	DIR *dirp;
	int handle;

	if (stat(dirname, &sbuf) != 0 || sbuf.st_mode & S_IFDIR == 0)
		return NULL;

	if (_fullpath(path, dirname, _MAX_PATH) == NULL)
		return NULL;

	if ((handle = _findfirst(strcat(path, "/*.*"), &data)) == -1)
		return NULL;
	
	if ((dirp = (DIR *) QP_malloc(sizeof(DIR))) == NULL)
		return NULL;

	(void) strcpy(dirp->name, data.name);
	dirp->handle = handle;
	return dirp;
}

struct dirent *
readdir(DIR *dirp)
{
	static struct dirent dirent;
	struct _finddata_t data;

	if (dirp->name[0] == '\0')
		return NULL;

	(void) strcpy(dirent.d_name, dirp->name);
	dirent.d_ino  = 1;
	if (_findnext(dirp->handle, &data) == -1)
		dirp->name[0] = '\0';
	else
		strcpy(dirp->name, data.name);

	return &dirent;
}

int
closedir(DIR *dirp)
{
	(void) _findclose(dirp->handle);
	QP_free(dirp);
	return 0;
}

#endif /* WIN32 */
