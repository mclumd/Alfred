/* SCCS   :  @(#)proxrt.c	20.1 08/03/94
   Purpose:  Example of adding a widget class to proxt:
             interface to Xrt/graph widget.
	     Xrt/graph is a trademark of KLGroup Inc, Toronto, Canada

   Copyright (C) 1994, Quintus Corporation. All rights reserved
*/

#include <X11/Intrinsic.h>
#include <Xm/XrtGraph.h>

/*
 *  return address of XrtGraph widget class
 *  needed for xtCreateWidget/xtCreateManagedWidget
 */
WidgetClass xrt_get_widget_class_addr()
{
	return xtXrtGraphWidgetClass;
}
