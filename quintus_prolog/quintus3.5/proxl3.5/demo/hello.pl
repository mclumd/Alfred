%   File   : hello.pl
%   Author : Peter Schachte
%   Updated: Thu Nov  2 17:23:01 PST 1989
%   Purpose: Demonstration of ProXL programming

%   Copyright (C) 1989, Quintus Computer Systems, Inc.
%   All rights reserved.

sccs_id('"@(#)91/01/27 hello.pl    4.2"').


:- use_module(library(proxl)).

%  message_window(+Message, +Fontname, +Bg1, +Bg2, +Letters, +Shadow,
%  	-Window)
%  Window is a window with Message, a Prolog atom, centered in it
%  in Fontname, an atom naming a font.  Bg1, Bg2, Letters and Shadow
%  are atoms naming colors.

message_window(Message, Fontname, Bg1, Bg2, Letters, Shadow, Window) :-
	load_font(Fontname, Font),
	alloc_color(Bg1, Bg1_pix),
	alloc_color(Bg2, Bg2_pix),
	alloc_color(Letters, Letters_pix),
	alloc_color(Shadow, Shadow_pix),
	get_font_attributes(Font, [height(Hei), max_width(Wid)]),
	Xdisplacement is Wid//5,
	Ydisplacement is Hei//5,
	%  X and Y displacement are the distance the shadow should be
	%  displaced from the primary image.
	text_extents(Font, Message, Lbearing, Rbearing, _, Asc, Desc),
	Window_width is Lbearing+Rbearing+Xdisplacement+4,
	Window_height is Asc+Desc+Ydisplacement+4,
	create_pixmap(Bg, [size(4,4)], [foreground(Bg1_pix)]),
	fill_rectangle(Bg, 0, 0, 3, 3),
	put_graphics_attributes(Bg, [foreground(Bg2_pix)]),
	draw_segments(Bg, [segment(0,0,3,3),segment(0,3,3,0)]),
	create_cursor(gumby, Cursor),
	Xoffset is Lbearing-(Lbearing+Rbearing+Xdisplacement)//2,
	Yoffset is Asc-(Asc+Desc+Ydisplacement)//2,
	%  X and Y offset are the offset from the center of the
	%  window at which we want to draw the string.
	create_window(Window,
		[   size(Window_width,Window_height), mapped(true),
		    border_width(2), background(Bg), cursor(Cursor),
		    property('WM_NAME', hello),
		    callback(expose, [count(0)],
			    expose_message(Window,Message,Letters_pix,
				    Shadow_pix,Xoffset,Yoffset,
				    Xdisplacement,Ydisplacement)),
		    callback(button_press, [], hello(Window),
			    destroy_window(Window))
		], [font(Font)]).


%  expose_message(+Window, +Message, +Letters_pix, +Shadow_pix,
%	+Xoffset, +Yoffset, +Xdisplacement, +Ydisplacement)
%  Redisplay the contents of Window.  Window is a window created by
%  message_window/7, and Message is the message displayed in it.
%  Letters_pix and Shadow_pix are the pixel values to draw the
%  letters and shadow in, respectively.  Xoffset and Yoffset are
%  the pixel offset from the center of the window at which Message
%  should be drawn.  And Xdisplacement and Ydisplacement are the
%  pixel offset from the message at which the shadow should be drawn.
 
expose_message(Window, Message, Letters_pix, Shadow_pix, Xoffset, Yoffset,
		Xdisplacement, Ydisplacement) :-
	get_window_attributes(Window, [size(Width,Height)]),
	X is Width//2 + Xoffset,	% compute position for message
	Y is Height//2 + Yoffset,
	Shadow_x is X+Xdisplacement,
	Shadow_y is Y+Ydisplacement,
	clear_window(Window),
	put_graphics_attributes(Window, [foreground(Shadow_pix)]),
	draw_string(Window, Shadow_x, Shadow_y, Message),
	put_graphics_attributes(Window, [foreground(Letters_pix)]),
	draw_string(Window, X, Y, Message).


window_data(font, '*-times-bold-i-*-240-*'). % First choice, for X11R3
window_data(font, 'vgb-25').	             % Second coice, or on X11R2
window_data(font, 'fixed').                  % Last choice ...


%  hello
%  test program for message_window/7.
hello :-
	window_data(font, Fontspec),
	current_font(Fontspec, Fontname),
	!,
	message_window('Hello, world!!', Fontname,
		goldenrod, forestgreen,	cyan, black, Window),
	handle_events(hello(Window)).	% process callbacks till our
					% window is destroyed

user:runtime_entry(start) :-
	hello.
