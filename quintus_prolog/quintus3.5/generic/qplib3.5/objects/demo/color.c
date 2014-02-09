/*
  SCCS   : @(#)color.c	1.4 10/16/93
  File   : color.c
  Authors: Georges Saab
  Purpose: C definitions for allocating colormap entries
  Origin : 20 Apr 1993

*/

#include <X11/Intrinsic.h>
#include <X11/Xlib.h>
#include <string.h>

/*
	get_color() returns the color map entry for the color combination
specified by red, green, and blue for the display for widget widget.
Scaling is done so that this can be called multiple times with any 
combination of red green and blue in the range 0-100 without filling the
colormap entries for the display.
*/

int get_color(widget,red,green,blue)
    Widget *widget;
    int red, green, blue;
{
  XColor color;
  Display *display = XtDisplay(widget);
  int scr = DefaultScreen(display);
  Colormap cmap = DefaultColormap(display, scr);

  color.red   = ((int) red/17  )*13107;
  color.green = ((int) green/17)*13107;
  color.blue  = ((int) blue/17 )*13107;

  if (XAllocColor(display, cmap, &color))
      return (color.pixel);
  else {
      printf("Warning: Couldn't allocate requested color\n");
      return (BlackPixel(display, scr));
    }
}

