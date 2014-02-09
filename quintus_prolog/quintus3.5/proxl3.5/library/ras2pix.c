/*
 * This file defines the ProXL utility 
 *
 *    new_pixmap_from_rasterfile(file, screen)
 *
 * Where file is a string and screen is an X11 Screen *. It
 * creates and returns an X11 Pixmap out of a Sun rasterfile 
 *
 * Author: Luis Jenkins
 * (C) Copyright 1989, Quintus Computer Systems, Inc.
 *
 * This code is partially based on the code supplied with the
 * X11 puzzle demo.
 */


/* Puzzle - (C) Copyright 1987, 1988 Don Bennett.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose and without fee is hereby granted,
 * provided that the above copyright notice appear in all copies and that
 * both that copyright notice and this permission notice appear in
 * supporting documentation.
 */

#ifndef lint
static  char SCCSid[] = "@(#)94/06/08 ras2pix.c    20.1";
#endif  /* lint */


#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>          /* [PM] 3.5 XDestroyImage */
#include <X11/Xos.h>
#ifdef sun
#ifdef SYSV
#include <pixrect/rasterfile.h>
#else
#include <rasterfile.h>
#endif
#else
#include "rasterfile.h"
#endif
#include <errno.h>              /* [PM] 3.5 */

#define round(x,s) ((((x)-1) & ~((s)-1)) + (s))
#define BITMAP_PAD 16   /* Ok for Sun rasterfiles */

int getColormapEntries(display, screen, colorMap, numColors)
Display *display;
Screen *screen;
XColor *colorMap;
int numColors;
{
  int i;
#if 0                           /* [PM] 3.5 unused */
  XColor color;
#endif /* unused */

  Colormap cmap = DefaultColormapOfScreen(screen);
  int not_enough = 0;
  
  for (i = 0; i < numColors; i++) {
    /* Need a read-only color for this value */
    if (!XAllocColor(display,
		     cmap,
		     &colorMap[i])) {
      fprintf(stderr, "Can't allocate color entry %d (asked for %d)\n",
	      i, numColors);
      not_enough = 1;
    }
  }
  return(not_enough);
}

Pixmap new_pixmap_from_rasterfile(fname, screen)
char *fname;
Screen *screen;
{
  /* [PM] 3.5 errno is often a macro these days: extern int errno; */
  void swap_long();

  int readcount;
  struct rasterfile header;
  
  int fd, i, cmapSize;
#if 0                           /* [PM] 3.5 */
  u_char cmapSizeByte;
#endif /* unused */
  u_char colormapData[3][256];
  u_char *data;
  int length;
  int width, height, depth;

  Display *display;
  Pixmap pix;
  XImage *image;
  XColor colorMap[256];

  display = DisplayOfScreen(screen);
    
  fd = open(fname, O_RDONLY);
  if (fd == -1) {
    fprintf(stderr,"could not open picture file '%s', errno = %d\n",
	    fname, errno);
    return 0;
  }

  read(fd, &header, sizeof(struct rasterfile));

#if (i386 || vax || __alpha)
  swap_long((char *) &header.ras_magic, sizeof(int));
  swap_long((char *) &header.ras_width, sizeof(int));
  swap_long((char *) &header.ras_height, sizeof(int));
  swap_long((char *) &header.ras_depth, sizeof(int));
  swap_long((char *) &header.ras_length, sizeof(int));
  swap_long((char *) &header.ras_type, sizeof(int));
  swap_long((char *) &header.ras_maptype, sizeof(int));
  swap_long((char *) &header.ras_maplength, sizeof(int));
#endif

  if (header.ras_magic != RAS_MAGIC) {
    fprintf(stderr, "%s is not a Sun rasterfile\n", fname);
    fprintf(stderr, "Bad magic: 0x%lx\n", (long)header.ras_magic);
    close(fd);
    return 0;
  }
  width = header.ras_width;
  height = header.ras_height;
  depth = header.ras_depth;

  if (!(depth == 1 || depth == 8)) {
    fprintf(stderr, "can not handle a rasterfile of depth %d\n", depth);
    close(fd);
    return 0;
  }

  if (header.ras_type == RT_OLD)
    length = width*height*(8/depth);
  else if (header.ras_type == RT_STANDARD)
    length = header.ras_length;
  else {
    fprintf(stderr, "%s is not an old, or new standard rasterfile\n", fname);
    close(fd);
    return 0;
  }

  if (header.ras_maptype == RMT_NONE) {
    if (header.ras_maplength != 0) {
      fprintf(stderr, "corrupted rasterfile %s. Should not have a colormap\n",
	      fname);
      close(fd);
      return 0;
    }
    cmapSize = 0;
  } else if (header.ras_maptype == RMT_EQUAL_RGB) {
    if (header.ras_maplength % 3 != 0) {
      fprintf(stderr, "Color map length of %d is not divisible by 3\n",
	      header.ras_maplength);
      close(fd);
      return 0;
    } else
      cmapSize = header.ras_maplength/3;     
  } else {
    fprintf(stderr, "can't handle maptype of rasterfile %s\n", fname);
    close(fd);
    return 0;
  }

  if (cmapSize != 0)
    for (i = 0; i < 3; i++)
      read(fd, &colormapData[i][0], cmapSize);

  data = (u_char *) malloc(length);
  if (!data) {
    fprintf(stderr, "could not allocate enough memory for rasterfile %s\n",
	    fname);
    close(fd);
    return 0;
  }
  readcount = read(fd, data, length);

  /***********************************/
  /** allocate the colormap entries **/
  /***********************************/

  for (i = 0; i < cmapSize; i++) {
    colorMap[i].red   = colormapData[0][i];
    colorMap[i].green = colormapData[1][i];
    colorMap[i].blue  = colormapData[2][i];
    colorMap[i].red   |= colorMap[i].red   << 8;
    colorMap[i].green |= colorMap[i].green << 8;
    colorMap[i].blue  |= colorMap[i].blue  << 8;
  }
  (void) getColormapEntries(display, screen, colorMap, cmapSize);

  /******************************************************/
  /** convert the data to the appropriate pixel value, **/
  /** cache the data as a pixmap on the server         **/
  /******************************************************/
      
  if (cmapSize != 0)
    for (i = 0; i < length ; i++)
      data[i] = colorMap[data[i]].pixel;

  image = XCreateImage(display,
		       DefaultVisualOfScreen(screen), 
		       DefaultDepthOfScreen(screen),
		       (depth == 1)? XYBitmap: ZPixmap, 
		       0,                  /* HARDWIRED offset */
		       data,
		       width,
		       height,
		       BITMAP_PAD,        /* HARDWIRED bitmap_pad */
	               round(width*depth, BITMAP_PAD) / 8);
		                          /* HARDWIRED bytes_per_line */

#if (i386 || vax || __alpha)
  image->bitmap_bit_order = MSBFirst;
  image->byte_order = MSBFirst;
#endif

  pix = XCreatePixmap(display,
		      RootWindowOfScreen(screen),
		      width,
		      height,
		      DefaultDepthOfScreen(screen));
  
  XPutImage(display,
	    pix,
	    DefaultGCOfScreen(screen),
	    image,
	    0,    /* HARDWIRED src_x */
	    0,    /* HARDWIRED src_y */
	    0,    /* HARDWIRED dst_x */
	    0,    /* HARDWIRED dst_y */
	    width,
	    height);
  XDestroyImage(image);
  
  return(pix);
}





void swap_long (bp, n)
    register char *bp;
    register unsigned n;
{
    
    register char c;
    register char *ep = bp + n;
    register char *sp;

    while (bp < ep) {
	
      sp = bp + 3;
      c = *sp;
      *sp = *bp;
      *bp++ = c;
      sp = bp + 1;
      c = *sp;
      *sp = *bp;
      *bp++ = c;
      bp += 2;
    }
}


