%   Package: panel
%   Author : Luis Jenkins
%   Updated: Thu Sep 28 14:16:11 PDT 1989 by lej
%   Purpose: panel window, a cut-rate panel widget

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(panel, [
	create_panel/5,
	create_panel/6
   ]).

:- meta_predicate
	create_panel(-, +, :, +, +),
	create_panel(-, +, :, +, +, +).

:- use_module(library(proxl)).
:- use_module(library(basics)).
:- use_module(library(lists), [delete/3]).
:- use_module(library(pushbutton)).
:- use_module(library(label)).

sccs_id('"@(#)96/10/10 panel.pl    21.1"').

%  create_panel(-Panel, +Items, +Attribs, +MinW, +MinH)
%  create_panel(-Panel, +Items, +Attribs, +GraphicsAttr, +MinW, +MinH)
%  Window is a newly created label window displaying Label.  Label should
%  be either an atom or a pixmap.  Attribs and Graphics_attribs specify
%  attributes for Window.

create_panel(Panel, Items, Attr, MinW, MinH) :-
	create_panel(Panel, Items, Attr, [], MinW, MinH).


create_panel(Panel, Items, Attribs, GAttr, MinW, MinH) :-
	split_meta_variable(Attribs, Mod, Attr),
	delete(Attr, mapped(Bool), PanelAttr),
	create_window(Panel, Mod:[size(MinW, MinH)|PanelAttr], GAttr),
	delete(PanelAttr, parent(_), A1),
	delete(A1, x(_), A2),
	delete(A2, y(_), A3),
	delete(A3, position(_, _), ItemAttr),
	create_panel_items(Items, Mod:[parent(Panel)|ItemAttr], GAttr,
	                   ItemWindows),
        ExtraSep = 10,			   
        place_panel_items(ItemWindows, MinW, MinH, ExtraSep, TotalW, TotalH),
	( nonvar(Bool) -> LastAttr = [size(TotalW, TotalH), mapped(Bool)]
          ; LastAttr = [size(TotalW, TotalH)]
        ),
	put_window_attributes(Panel, LastAttr).


create_panel_items([], _, _, []).
create_panel_items([Item|Is], Attr, GAttr, [item(Win, _W, _H)|Ws]) :-
	create_one_item(Item, Attr, GAttr, Win),
	create_panel_items(Is, Attr, GAttr, Ws).



create_one_item(label(Label), Attr, GAttr, LabelWindow) :-
	create_label(LabelWindow, Label, Attr, GAttr).
create_one_item(button(Label, Action), Mod:Attr, GAttr, Button) :-
	create_pushbutton(Button, Label, Mod:Action, Mod:Attr, GAttr).
create_one_item(button(Label, Action, Hilite, Lolite), Mod:Attr, GAttr,
	        Button) :-
	create_pushbutton(Button, Label, Mod:Action, Mod:Hilite, Mod:Lolite,
	                  Mod:Attr, GAttr).

place_panel_items(ItemWindows, MinW, MinH, ExtraSep, TotalW, TotalH) :-
	collect_sizes(ItemWindows, N, _MaxItemW, MaxItemH, ReqW),
	max(MinW, ReqW, TempW),
	TotalW is TempW + ExtraSep,
	max(MinH, MaxItemH, TempH),
	TotalH is TempH + ExtraSep,
	SpaceX is (TotalW - ReqW) // (N + 1),
	SpaceY is (TotalH - MaxItemH) // 2,
	place_items(ItemWindows, SpaceX, SpaceY, SpaceX, 0).


collect_sizes(Items, N, MaxItemW, MaxItemH, ReqW) :-
	collect_sizes(Items, 0, N, 0, MaxItemW, 0, MaxItemH, 0, ReqW).

collect_sizes([], N, N, MW, MW, MH, MH, RW, RW).
collect_sizes([item(Item, W, H)|Is], N0, N, MaxW0, MaxW, MaxH0, MaxH,
	      ReqW0, ReqW) :-
	get_window_attributes(Item, [size(W, H)]),
	max(MaxW0, W, MaxW1),
	max(MaxH0, H, MaxH1),
	ReqW1 is ReqW0 + W,
	N1 is N0 + 1,
	collect_sizes(Is, N1, N, MaxW1, MaxW, MaxH1, MaxH, ReqW1, ReqW).
	

place_items([], _, _, _, _).
place_items([item(I, W, _H)|Is], X0, Y0, IncX, IncY) :-
	put_window_attributes(I, [position(X0, Y0), mapped(true)]),
	X1 is X0 + W + IncX,
	Y1 is Y0 + IncY,
	place_items(Is, X1, Y1, IncX, IncY).




max(A, B, C) :-
	( A >= B -> C = A ; C = B ).


