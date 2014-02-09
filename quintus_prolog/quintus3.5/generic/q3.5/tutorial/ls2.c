/*
   SCCS: @(#)ls2.c	70.1 01/26/94
   File: ls2.c

    Support routines for ls2.pl
*/

#include <dirent.h>
#include <sys/stat.h>
#include <quintus/quintus.h>

int closedir();

/*
    Open the directory specified by path and return a pointer to the 
    DIR structure (or zero in error case).  Also return the address of
    the closedir function for later use with trail hook.
*/
void open_directory(path, dir, closefn)
    char *path;
    DIR **dir;
    int (**closefn)();
{
    *dir = opendir(path);
    *closefn = closedir;
    return;
}


/*
    Get the next file from the specified directory.  Often, iterator
    routines like this one will have two arguments which are a before
    and after value for an index (or cursor) indicating how far through
    the iteration it has got.  In this case, though, all necessary state
    is hidden away in the DIR structure, and only readdir needs to know
    about it.
*/
int next_file(dir, filename)
    DIR *dir;
    unsigned long *filename;
{
    struct dirent *ent;
    char *name;
    int i;

    ent = readdir(dir);
    if (ent == (struct dirent *) 0) 
        return -1; /* reached end of directory; or error occurred */
    
    i = ent->d_namlen; /* convert short to long */
    (void) QP_atom_from_padded_string(filename, ent->d_name, &i);
    return 0; /* successful return */
}


/*
    Get Mode, Uid, Gid and Size of a file.
*/
struct stat statbuf;

int stat_file(path, mode, uid, gid, size)
    char *path;
    int *mode, *uid, *gid, *size;
{
    if (lstat(path,&statbuf) != 0)
        return -1; /* error return */
    *mode = statbuf.st_mode;
    *uid  = statbuf.st_uid;
    *gid  = statbuf.st_gid;
    *size = statbuf.st_size;
    return 0; /* successful return */
}
    
