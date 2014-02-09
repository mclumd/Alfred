%   File   : portraydate.pl
%   Author : Richard A. O'Keefe
%   SCCS   : @(#)90/09/14 portraydate.pl	57.2
%   Purpose: Install portray_date/1 from library(date).

:- use_module(library(date), []),
   use_module(library(addportray), []).

:- initialization add_portray:add_portray(date:portray_date).

