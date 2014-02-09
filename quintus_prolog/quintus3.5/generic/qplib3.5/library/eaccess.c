/*  File   : eaccess.c
    Author : Richard A. O'Keefe
    Updated: 3/25/94
    Purpose: a reliable version of access(2)
*/

#ifndef	lint
static	char SCCSid[] = "@(#)94/03/25 eaccess.c	72.1";
#endif/*lint*/

/*  eaccess(char *path, int mode)

    is given a file name (path) and a set of permissions all of which are
    wanted (read and/or write and/or execute/search), and returns 0 if
    the file exists and the program has all the required permissions, or
    -1 if this is not the case.  If -1 is returned, errno is set to
    indicate the nature of the problem.

    Unlike access(2), which uses the current process's *real* user and
    group ids, eaccess(2) uses the *effective* user and group ids, so it
    is the appropriate thing to call if you want to know whether it would
    be ok to open() the file.

    saccess(struct stat *stat_buf, int mode)

    is an "optimised" version of eaccess(), to be used when you already
    have a stat(2) buffer available for the file.

    The "mode" parameter is an inclusive or of
	R_OK = 4 (S_IREAD >> 6)	test for read permission
	W_OK = 2 (S_IWRITE>> 6)	test for write permission
	X_OK = 1 (S_IEXEC >> 6)	test for execute (search) permission
	F_OK = 0		test for presence of file
    ALL of the permissions you ask for must be available for these functions
    to succeed.  Note that saccess(&buf, 0) cannot fail.

    Added in April 1988:
	0040000 (S_IFDIR)	path must identify a directory
	0100000 (S_IFREG)	path must NOT identify a directory
    If neither of these bits is set, either will be acceptable.

    Assumption:

    In order to save issuing several system calls, this function caches
    the effective user and group ids.  However, they can change.  Just
    in case this happens to be useful, we provide a function

	notice_changed_ids()

    which clears the cache.  The assumption is that if any of the system
    calls setuid(), seteuid(), setruid(), setgid(), setegid(), setrgid()
    is issued, notice_changed_ids() will be called before the next call
    to eaccess().

    Note:  getegid() and geteuid() are described in section 2 of the UNIX
    manual, and in the BA_OS section of the System V Interface Document.
    According to the SVID, they return "unsigned short", which agrees with
    the fact that stat(BA_OS) has 'ushort' as the type of st_[ug]id.
    However, 4.2BSD systems appear to use 'int' and 'short' respectively.
    These two functions cannot fail, so we don't have to check the return
    value or look for errno.

    This needs to be rewritten completely for VMS.  The conditionalisation
    here is only intended to get it to compile.

    Added in November 1989:
	Doug Moran pointed out that BSD systems (and some of the newer S5s)
	let you be in several groups at once.  This code was written to the
	SVID, which didn't include that feature.  So we assume that if the
	macro NGROUPS is defined, the system has the multiple-groups feature.
	The variable ngids is initialised to -1, indicating that the cached
	data are not valid yet.
    The code which was shown to me (R.A.O'Keefe) had a comment "should have
    perror here" in one place.  Wrong.  (a) It shouldn't be printing anything
    at all but returning an error code to the caller.  There are two reasons
    for this:  (a.1) that's how this particular file reports _ALL_ errors;
    if saccess() or eaccess() returns -1 the error code is certain to be in
    errno, and (a.2) it is disgusting as well as useless when a program spews
    its guts out all over the screen; what does the end user know about
    saccess()?  (b) If you want to print error messages, use
	QP_fprintf(QP_stderr, "...%m...", errno);
    E.g. here, if one were hell-bent on writing an error message, one would
	QP_fprintf(QP_stderr, "saccess(...): getgroups(%d,...) failed: %m\n",
		NGROUPS, errno);
    %m stands for error Message.
*/

#include <errno.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifdef unix
#include <unistd.h>
#endif

#ifndef WIN32
static int ngids = -1;		/* not set up, will be #entries in gid[]*/

static int euid;		/* effective user id */

#ifdef	NGROUPS_MAX
static gid_t gid[NGROUPS_MAX];	/* [0..ngids-1] are the effective groups */
#else
static int gid[1];		/* the one effective group */
#endif/*NGROUPS*/


void notice_changed_ids()
    {
	ngids = -1;
    }
#endif/*WIN32*/


int saccess(stat_buf, mode)
    register struct stat *stat_buf;
    register int mode;
    {
#ifndef WIN32
	int g;

	if (ngids < 0) {	/* The cache is empty */
	    /*  We update the user id and then the group array in that  */
	    /*  order, so that ^C interrupts won't break the invariant  */
	    /*  ngids >= 0 -> euid and gid[0..ngids-1] are valid.      */
	    euid = geteuid();
#ifdef	NGROUPS_MAX
	    if ((ngids = getgroups(NGROUPS_MAX, gid)) < 0) return -1;
#else
	    gid[0] = getegid();
	    ngids = 1;
#endif
	}
#endif/*WIN32*/

	/*  We check the type of the thing first  */
	if ((stat_buf->st_mode & S_IFMT) == S_IFDIR) {
	    if (mode & S_IFREG) { errno = EISDIR;  return -1; }
	} else {
	    if (mode & S_IFDIR) { errno = ENOTDIR; return -1; }
	}
#ifdef WIN32
	mode <<= 6;
#else
	/*  Then we check the permissions  */
	mode &= 7;
	if (stat_buf->st_uid == euid) {		/* if uid matches */
	    mode <<= 6;				/* use the xxx------ field */
	} else
	for (g = ngids; --g >= 0; )		/* if any gid matches */
	    if (stat_buf->st_gid == gid[g]) {	/* use the ---xxx--- field */
		mode <<= 3;
		break;				/* otherwise */
	    }					/* use the ------xxx field */
#endif
	if ((stat_buf->st_mode & mode) == mode) {
	    return 0;		/* all required permissions available */
	} else {
	    errno = EACCES;	/* some permission not available */
	    return -1;
	}
    }


int eaccess(path, mode)
    char *path;
    int mode;
    {
	struct stat stat_buf;

	return stat(path, &stat_buf) ? -1 : saccess(&stat_buf, mode);
    }

