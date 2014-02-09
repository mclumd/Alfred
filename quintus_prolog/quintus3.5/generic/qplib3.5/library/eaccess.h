/*  File   : eaccess.h
    Author : Richard A. O'Keefe
    SCCS   : @(#)88/11/02 eaccess.h	27.2
    Purpose: Header file for eaccess.c
*/

extern int eaccess(/* char *path, int mode */);
extern int saccess(/* struct stat *stat_buf, int mode */);

