/*
 *	File:	wdirent.h
 *	Author: David Connelly
 *	Purpose: Header file for DIR + dirent structures
 *		 used in directory.c
 */

typedef struct {
	int	handle;
	char	name[_MAX_FNAME];
} DIR;

struct dirent {
	int	d_ino;
	char	d_name[_MAX_FNAME];
};

DIR *opendir(const char *dirname);

struct dirent *readdir(DIR *dirp);

int closedir(DIR *dirp);
