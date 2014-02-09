%
% Package: ras2pix
% Author : Luis Jenkins
% Updated: Mon Jun  5 10:12:04 PDT 1989
% Purpose: Create a ProXL Pixmap from a Sun rasterfile
%

:- module(ras2pix, [
	create_pixmap_from_rasterfile/2,
	create_pixmap_from_rasterfile/3
    ]).

:- use_module(library(proxl), [
        ensure_valid_screenable/3,
	default_screen/2,
	screen_xscreen/2,
	proxl_xlib/3
   ]).

sccs_id('"@(#)91/01/30 ras2pix.pl    4.2"').

%  create_pixmap_from_rasterfile(+Filename, -Pixmap)
%  create_pixmap_from_rasterfile(+Filename, +Screenable, -Pixmap)
%  Pixmap is a newly created pixmap from the given Sun rasterfile
%  Filename, stored on the Screenable's Screen. If the Screenable
%  is ommitted, the default Screen is used.
%
create_pixmap_from_rasterfile(Filename, Pixmap) :-
    Goal = create_pixmap_from_rasterfile(Filename, Pixmap),
    default_screen(Screen, Screen),
    create_pixmap_raster0(Filename, Screen, Pixmap, Goal).

create_pixmap_from_rasterfile(Filename, Screenable, Pixmap) :-
    Goal = create_pixmap_from_rasterfile(Filename, Screenable, Pixmap),
    create_pixmap_raster0(Filename, Screenable, Pixmap, Goal).


%  create_pixmap_raster0(+Filename, +Screenable, -Pixmap, +Goal)
%  Do the bulk of the work in creating a pixmap.  Pixmap is the newly
%  created pixmap from Filename.  Goal is the user goal
%  that got us here.

create_pixmap_raster0(Filename, Screenable, Pixmap, Goal) :-
    ensure_valid_screenable(Screenable, Screen, Goal),
    screen_xscreen(Screen, XScreen),     % Get the X Screen XID
    new_pixmap_from_rasterfile(Filename, XScreen, XPixmap),
    proxl_xlib(Pixmap, pixmap, XPixmap).   % Convert to a ProXL Pixmap




%
% Foreign code interface
%
foreign(new_pixmap_from_rasterfile, c,
	new_pixmap_from_rasterfile(+string, +address(xscreen),
				   [-address(xpixmap)])).


foreign_file(library(system(proxllib)), [
        new_pixmap_from_rasterfile
    ]).

:- load_foreign_executable(library(system(proxllib))).
