% pcal @(#)pcal.pl	19.2 01/21/94 
%   Program: pcal
%   Author : Jim Crammond
%   Created: Sep 90
%   Purpose: X(m) Calendar Program
%   SCCS   :  @(#)pcal.pl	19.2 01/21/94
%   History: month strip is based on xcal by Peter Collinson, Hillside Systems
%	   : dayeditor is based on xcalendar extension by Jim Crammond
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
%  Preliminaries:
%	1. Before running, ensure that the directory ~/Calendar exists
%	   data files of the form xp<month><year> are saved in here.
%	2. add the resources in the file Pcal into the X resources database
%	   i.e. run the command 'xrdb -merge Pcal'
%
%  To run:
%	From a develop system: type the query "main.". This creates the current
%	month strip. "main([Month,Year])" brings up a specific month strip.
%
%	To pop up a dayeditor, just click on the entry (text) for that day.
%

:- use_module(library(proxt)).
:- use_module(library(date)).
:- use_module(library(environ)).
:- use_module(library(files)).
:- use_module(library(strings)).

:- dynamic pcal/4, strip/5, editor/5, editnote/2.
:- dynamic topwidget/1, monthwidget/4, daywidget/5, free_daywidget/5.
:- dynamic modified/1.

%%%%%%%%%%  top level  %%%%%%%%%%

runtime_entry(start) :-
	unix(argv(Args)),
	main(Args).

main :- main([]).


main([-r,First,Last|Rest]) :- !,
	asserta(get_hour_range(First,Last)),
	main(Rest).
main([]) :- !,
	date(date(Year,Month,_)),
	main(Year, Month).
main([M]) :- !,
	Month is M - 1,
	date(date(Year,_,_)),
	main(Year, Month).
main([M,Year]) :- !,
	Month is M - 1,
	main(Year, Month).


main(Year, Month) :-
	xtInitialize('Pcal','Pcal',Top),
	asserta(topwidget(Top)),
	popup_month_strip(Year,Month),
	highlight_current_day,
	highlight_current_hour,
	xtMainLoop.


reinit :-
	retractall(pcal(_,_,_,_)),
	retractall(strip(_,_,_,_,_)),
	retractall(editor(_,_,_,_,_)),
	retractall(editnote(_,_)),
	retractall(topwidget(_)),
	retractall(monthwidget(_,_,_,_)),
	retractall(daywidget(_,_,_,_,_)),
	retractall(modified(_)).


%%%%%%%%%%  month strip  %%%%%%%%%%

%
%  create current month strip
%
popup_month_strip(Yr, Mth) :-
	D = date(Yr,Mth,1),
	YM is Yr * 12 + Mth,
	get_month_entries(D, YM),
	get_date_label(D, '%M %y', _, LabStr),
	get_date_label(D, '%3M %2y', IconPtr, _),

	topwidget(Top),
	xtCreatePopupShell(calendar, topLevelShellWidgetClass, Top, [], Shell),
	xtSetValues(Shell, [xmNiconName(IconPtr)]),	% set this after to keep
							% titlebar as 'calendar'
	xmCreatePanedWindow(Shell, frame, [xmNallowResize(true)], Frame),
	xtManageChild(Frame),

% label			--  note: this widget determines the width of the strip
	xmCreateLabel(Frame, month,
			[xmNlabelType(xmSTRING), xmNlabelString(LabStr)],
		      Label),
	xtManageChild(Label),
% buttons
	xmCreateRowColumn(Frame, actions,
				[xmNorientation(xmHORIZONTAL)],
			  Actions),
	xtManageChild(Actions),
	xmCreatePushButton(Actions, prev, [], PrevB),
	xtManageChild(PrevB),
	xtAddCallback(PrevB, xmNactivateCallback, prev_month_button, YM),
	xmCreatePushButton(Actions, done, [], DoneB),
	xtManageChild(DoneB),
	xtAddCallback(DoneB, xmNactivateCallback, done_month_button, YM),
	xmCreatePushButton(Actions, next, [], NextB),
	xtManageChild(NextB),
	xtAddCallback(NextB, xmNactivateCallback, next_month_button, YM),
	sensitize_buttons(YM, PrevB, NextB),
% days
	xmCreateForm(Frame,days,[xmNresizable(false)],DayFrame),
	xtManageChild(DayFrame),
	no_of_days_in(Mth,Yr,Ndays),
	create_days(Ndays,Yr,Mth,YM,DayFrame),
	asserta(monthwidget(YM,Shell,PrevB,NextB)),
	xtPopup(Shell, xtGrabNone).


create_days(Ndays,Yr,Mth,YM,Frame) :-
	%
	%  create day 1
	%
	D = date(Yr,Mth,1),
	YMD is YM * 32 + 1,
	time_stamp(D, '%3w', Name),
	get_date_label(D, '%3W %2d', _, LabelStr),
	get_day_entries(YM, YMD, TextStr),
	xmCreateLabel(Frame, Name,
			[xmNlabelType(xmSTRING), xmNlabelString(LabelStr),
			 xmNleftAttachment(xmATTACH_FORM),
			 xmNtopAttachment(xmATTACH_FORM),
			 xmNborderWidth(1)],
		      Lab),
	xtManageChild(Lab),
	xmCreatePushButton(Frame, Name,
			[xmNalignment(xmALIGNMENT_BEGINNING),
			 xmNlabelType(xmSTRING), xmNlabelString(TextStr),
			 xmNleftAttachment(xmATTACH_WIDGET),
			 xmNtopAttachment(xmATTACH_FORM),
			 xmNrightAttachment(xmATTACH_FORM),
			 xmNleftWidget(Lab),
			 xmNshadowThickness(0),
			 xmNborderWidth(1)],
			   Info),
	xtManageChild(Info),
	xtAddCallback(Info,xmNactivateCallback,start_dayeditor,date(Yr,Mth,1)),
	xtGetValues(Info, [xmNheight(H)]),
	xtSetValues(Lab,  [xmNheight(H)]),
	xtGetValues(Lab,  [xmNforeground(Fg),xmNbackground(Bg)]),
	asserta(strip(YMD, Lab, Info, Fg, Bg)),
	create_days(1,Ndays,Yr,Mth,YM,Frame,Lab,Info).


create_days(N,N,_,_,_,_,LastLab,LastInfo) :- !,
	%
	%  attach last day to bottom of form
	%
	xtSetValues(LastLab, [xmNbottomAttachment(xmATTACH_FORM)]),
	xtSetValues(LastInfo, [xmNbottomAttachment(xmATTACH_FORM)]).

create_days(M,Ndays,Yr,Mth,YM,Frame,LastLab,LastInfo) :-
	N is M + 1,
	%
	%  create day N
	%
	D = date(Yr,Mth,N),
	YMD is YM * 32 + N,
	time_stamp(D, '%3w', Name),
	get_date_label(D, '%3W %2d', _, LabelStr),
	get_day_entries(YM, YMD, TextStr),
	xmCreateLabel(Frame, Name,
			[xmNlabelType(xmSTRING), xmNlabelString(LabelStr),
			 xmNleftAttachment(xmATTACH_FORM),
			 xmNtopAttachment(xmATTACH_WIDGET),
			 xmNtopWidget(LastLab),
			 xmNborderWidth(1)],
		      Lab),
	xtManageChild(Lab),
	xmCreatePushButton(Frame, Name,
			[xmNalignment(xmALIGNMENT_BEGINNING),
			 xmNlabelType(xmSTRING), xmNlabelString(TextStr),
			 xmNleftAttachment(xmATTACH_WIDGET),
			 xmNtopAttachment(xmATTACH_WIDGET),
			 xmNrightAttachment(xmATTACH_FORM),
			 xmNtopWidget(LastInfo),
			 xmNleftWidget(Lab),
			 xmNshadowThickness(0),
			 xmNborderWidth(1)],
			   Info),
	xtManageChild(Info),
	xtAddCallback(Info,xmNactivateCallback,start_dayeditor,date(Yr,Mth,N)),
	xtGetValues(Info, [xmNheight(H)]),
	xtSetValues(Lab,  [xmNheight(H)]),
	xtGetValues(Lab,  [xmNforeground(Fg),xmNbackground(Bg)]),
	asserta(strip(YMD, Lab, Info, Fg, Bg)),
	create_days(N,Ndays,Yr,Mth,YM,Frame,Lab,Info).


%
%  buttons
%
prev_month_button(Wid, YM, _) :-
	xtSetSensitive(Wid, false),
	PYM is YM - 1,
	ym(PYM,Y,M),
	popup_month_strip(Y,M).

next_month_button(Wid, YM, _) :-
	xtSetSensitive(Wid, false),
	NYM is YM + 1,
	ym(NYM,Y,M),
	popup_month_strip(Y,M).

done_month_button(_, YM, _) :-
	( daywidget(Sh, YMD, _, _, _),
	  YM =:= YMD // 32,
	  done_day_button(_, Sh, _),	% n.b. this writes file out for every
					%      modified day!! maybe fix later..
	  fail
	  ;
	  true
	), !,
	retractall(pcal(YM, _, _, _)),

	monthwidget(YM, Shell,_, _),
	retract(monthwidget(YM, Shell, _, _)),
	xtPopdown(Shell),		% close down monthstrip
	xtDestroyWidget(Shell),		% bye, bye..

	( PYM is YM - 1,
	  monthwidget(PYM,_,_,NextB) ->
	  xtSetSensitive(NextB, true)
	  ;
	  NYM is YM + 1,
	  monthwidget(NYM,_,PrevB,_) ->
	  xtSetSensitive(PrevB, true)
	  ;
	  monthwidget(_,_,_,_)
	  ;
	  halt				% if last month entry, exit
	).


sensitize_buttons(YM,PrevB,NextB) :-
	PYM is YM - 1,
	( monthwidget(PYM,_,_,_) -> 		% prev_month exists
	  xtSetSensitive(PrevB,false)		% so desensitize button
	  ;
	  true
	),
	NYM is YM + 1,
	( monthwidget(NYM,_,_,_) ->		% next_month exists
	  xtSetSensitive(NextB,false)		% so desensitize button
	  ;
	  true
	), !.


start_dayeditor(Wid, date(Y,M,D), _) :-
	xtSetSensitive(Wid, false),
	popup_day_editor(Y,M,D).


%%%%%%%%%%  day editor  %%%%%%%%%%

%
%  create day editor
%
popup_day_editor(Yr, Mth, Day) :-
	free_daywidget(Shell, OYMD, Label, _, _),
	!,
	%
	%  recycle a previous day editor
	%
	D = date(Yr,Mth,Day),
	YMD is (Yr * 12 + Mth) * 32 + Day,
	get_date_label(D, '%W %d %M', _, LabStr),
	get_date_label(D, '%3W %t', IconPtr, _),
	xtSetValues(Shell, [xmNiconName(IconPtr)]),
% label
	xtSetValues(Label, [xmNlabelType(xmSTRING), xmNlabelString(LabStr)]),
% hours
	recycle_hours(OYMD, YMD),
	maybe_highlight_hour(YMD),
% notes
	recycle_notes(OYMD, YMD),

	retract(free_daywidget(Shell, OYMD, Label, SaveB, ClearB)),
	asserta(daywidget(Shell, YMD, Label, SaveB, ClearB)),
	xtSetSensitive(SaveB,false),
	( pcal(_, YMD, _, _) -> B = true ; B = false ),
	xtSetSensitive(ClearB, B),
	xtPopup(Shell, xtGrabNone).

popup_day_editor(Yr, Mth, Day) :-
	%
	%  create a new day editor
	%
	D = date(Yr,Mth,Day),
	YMD is (Yr * 12 + Mth) * 32 + Day,
	get_date_label(D, '%W %d %M', _, LabStr),
	get_date_label(D, '%3W %t', IconPtr, _),

	topwidget(Top),
	xtCreatePopupShell(dayeditor, topLevelShellWidgetClass, Top, [], Shell),
	xtSetValues(Shell, [xmNiconName(IconPtr)]),	% set this after to keep
							% titlebar as 'dyeditor'
	xmCreatePanedWindow(Shell, frame, [],Frame),
	xtManageChild(Frame),

% label		    --  note: this widget determines the width of the editor
	xmCreateLabel(Frame, day,
			[xmNlabelType(xmSTRING), xmNlabelString(LabStr)],
		      Label),
	xtManageChild(Label),
% buttons
	xmCreateRowColumn(Frame, actions,
				[xmNorientation(xmHORIZONTAL)],
			  Actions),
	xtManageChild(Actions),
	xmCreatePushButton(Actions, done, [], DoneB),
	xtManageChild(DoneB),
	xtAddCallback(DoneB, xmNactivateCallback, done_day_button, Shell),
	xmCreatePushButton(Actions, save, [], SaveB),
	xtManageChild(SaveB),
	xtAddCallback(SaveB, xmNactivateCallback, save_day_button, Shell),
	xmCreatePushButton(Actions, clear, [], ClearB),
	xtManageChild(ClearB),
	xtAddCallback(ClearB, xmNactivateCallback, clear_day_button, Shell),
% hours
	xmCreateForm(Frame, hours,
			[xmNverticalSpacing(1),
			 xmNhorizontalSpacing(1)],
		     DayFrame),
	get_hour_range(First, Last),
	create_hours(First, Last, Shell, YMD, DayFrame),
	xtManageChild(DayFrame),
	maybe_highlight_hour(YMD),
% notes
	xmCreateForm(Frame, notes,
			[xmNverticalSpacing(1),
			 xmNhorizontalSpacing(1)],
		     NoteFrame),
	xtManageChild(NoteFrame),
	create_notes(Shell, YMD, NoteFrame),

	asserta(daywidget(Shell, YMD, Label, SaveB, ClearB)),
	xtSetSensitive(SaveB,false),
	( pcal(_, YMD, _, _) ; xtSetSensitive(ClearB,false) ),
	xtPopup(Shell, xtGrabNone).


create_hours(M, N, _, _, _) :- M > N, !.
create_hours(M, N, Shell, YMD, Frame) :-
	%
	%  create first hour slot
	%
	T = time(M,0,0),
	concat_atom([M],Name),
	get_date_label(T, ' %2c:00', _, LabStr),
	xmCreateLabel(Frame, Name,
			[xmNlabelType(xmSTRING), xmNlabelString(LabStr),
			 xmNleftAttachment(xmATTACH_FORM),
			 xmNtopAttachment(xmATTACH_FORM),
			 xmNborderWidth(1)],
		      Lab),
	xtManageChild(Lab),
	get_hour_entry(YMD, M, TxtPtr),
	xmCreateText(Frame, text,
			[xmNleftAttachment(xmATTACH_WIDGET),
			 xmNrightAttachment(xmATTACH_FORM),
			 xmNtopAttachment(xmATTACH_FORM),
			 xmNleftWidget(Lab),
			 xmNvalue(TxtPtr),
			 xmNeditMode(xmSINGLE_LINE_EDIT),
			 xmNshadowThickness(0),
			 xmNborderWidth(1)],
		     Text),
	xtManageChild(Text),
	xtAddCallback(Text, xmNmodifyVerifyCallback, text_modified, Shell),
	xtGetValues(Text,[xmNheight(H)]),
	xtSetValues(Lab, [xmNheight(H)]),
	xtGetValues(Lab, [xmNforeground(Fg), xmNbackground(Bg)]),
	xtSetValues(Text,[xmNforeground(Fg), xmNbackground(Bg)]),
	YMDH is YMD * 24 + M,
	asserta(editor(YMDH, Lab, Text, Fg, Bg)),
	M1 is M + 1,
	create_hours(M1, N, Shell, YMD, Frame, Lab, Text).

create_hours(M, N, _, _, _, _, _) :- M > N, !.
create_hours(M, N, Shell, YMD, Frame, LastLab, LastText) :-
	%
	%  create next hour slot
	%
	T = time(M,0,0),
	concat_atom([M],Name),
	get_date_label(T, ' %2c:00', _, LabStr),
	xmCreateLabel(Frame, Name,
			[xmNlabelType(xmSTRING), xmNlabelString(LabStr),
			 xmNleftAttachment(xmATTACH_FORM),
			 xmNtopAttachment(xmATTACH_WIDGET),
			 xmNtopWidget(LastLab),
			 xmNborderWidth(1)],
		      Lab),
	xtManageChild(Lab),
	get_hour_entry(YMD, M, TxtPtr),
	xmCreateText(Frame, text,
			[xmNleftAttachment(xmATTACH_WIDGET),
			 xmNrightAttachment(xmATTACH_FORM),
			 xmNtopAttachment(xmATTACH_WIDGET),
			 xmNleftWidget(Lab),
			 xmNtopWidget(LastText),
			 xmNvalue(TxtPtr),
			 xmNeditMode(xmSINGLE_LINE_EDIT),
			 xmNshadowThickness(0),
			 xmNborderWidth(1)],
		     Text),
	xtManageChild(Text),
	xtAddCallback(Text, xmNmodifyVerifyCallback, text_modified, Shell),
	xtGetValues(Text,[xmNheight(H)]),
	xtSetValues(Lab, [xmNheight(H)]),
	xtGetValues(Lab, [xmNforeground(Fg), xmNbackground(Bg)]),
	xtSetValues(Text,[xmNforeground(Fg), xmNbackground(Bg)]),
	YMDH is YMD * 24 + M,
	asserta(editor(YMDH, Lab, Text, Fg, Bg)),
	M1 is M + 1,
	create_hours(M1, N, Shell, YMD, Frame, Lab, Text).

create_notes(Shell, YMD, Frame) :-
	%
	%  create notes slot
	%
	xmCreateLabel(Frame, ' Notes',
		       [xmNleftAttachment(xmATTACH_FORM),
			xmNborderWidth(1)],
		      Lab),
	xtManageChild(Lab),
	get_note_entry(YMD, TxtPtr),
	xmCreateText(Frame, text,
			[xmNleftAttachment(xmATTACH_WIDGET),
			 xmNrightAttachment(xmATTACH_FORM),
			 xmNleftWidget(Lab),
			 xmNvalue(TxtPtr),
			 xmNeditMode(xmMULTI_LINE_EDIT),
			 xmNshadowThickness(0),
			 xmNborderWidth(1)],
		     Text),
	xtManageChild(Text),
	xtAddCallback(Text, xmNmodifyVerifyCallback, text_modified, Shell),
	xtGetValues(Text,[xmNheight(H)]),
	xtSetValues(Lab, [xmNheight(H)]),
	xtGetValues(Lab, [xmNforeground(Fg), xmNbackground(Bg)]),
	xtSetValues(Text,[xmNforeground(Fg), xmNbackground(Bg)]),
	asserta(editnote(YMD, Text)).


recycle_hours(YMD, YMD) :- !.
recycle_hours(OYMD, YMD) :-
	( editor(OYMDH, _, _, _, _),
	  OYMD =:= OYMDH // 24,
	  Hr is OYMDH mod 24,
	  YMDH is YMD * 24 + Hr,
	  retract(editor(OYMDH, Lab, Text, Bg, Fg)),
	  get_hour_entry(YMD, Hr, TxtPtr),
	  xmTextSetString(Text, TxtPtr),
	  asserta(editor(YMDH, Lab, Text, Bg, Fg)),
	  fail
	  ;
	  true
	), !.

recycle_notes(YMD, YMD) :- !.
recycle_notes(OYMD, YMD) :-
	retract(editnote(OYMD, Text)),
	get_note_entry(YMD, TxtPtr),
	xmTextSetString(Text, TxtPtr),
	asserta(editnote(YMD, Text)).


%
%  buttons
%
done_day_button(_, Shell, _) :-
	daywidget(Shell, YMD, _, SaveB, _),
	( modified(Shell) ->		% update cal file
	  save_day_button1(SaveB, YMD),
	  retract(modified(Shell))
	  ;
	  true
	), !,
	maybe_highlight_hour(YMD),	% unhighlight current hour label
	retract(daywidget(Shell, YMD, Label, SaveB, ClearB)),
	asserta(free_daywidget(Shell, YMD, Label, SaveB, ClearB)),

	strip(YMD, _, Info, _, _),	% info button in month strip
	xtSetSensitive(Info, true),
	xtPopdown(Shell).		% popdown down dayeditor


save_day_button(SaveB, Shell, _) :-
	daywidget(Shell, YMD, _, SaveB, _), !,
	save_day_button1(SaveB, YMD),
	retract(modified(Shell)).

save_day_button1(SaveB, YMD) :-
	YM is YMD // 32,
	ym(YM,Yr,Mth),
	D = date(Yr,Mth,1),
	update_day_entries(YM, YMD),
	put_month_entries(D, YM),
	xtSetSensitive(SaveB, false),
	update_month_strip(YM, YMD).


clear_day_button(ClearB, Shell, _) :-
	daywidget(Shell, YMD, _, _, ClearB), !,
	YM is YMD // 32,
	clear_day_entries(YM, YMD),
	xtSetSensitive(ClearB, false).


%
% other callbacks:
% this gets called when typing into a text widget and by xmTextSetString/2
%
text_modified(_, Shell, _) :-
	( modified(Shell) ->
	  true
	  ;
	  daywidget(Shell, _, _, SaveB, ClearB) ->
	  xtSetSensitive(SaveB, true),
	  xtSetSensitive(ClearB, true),
	  assert(modified(Shell))
	).

%
% highlighting
%
highlight_current_day :-
	date_and_time(date(Y,M,D),time(H,I,S)),
	YMD is (Y * 12 + M) * 32 + D,
	change_day_highlight(YMD),
	NextDay is 86400000 - ((H * 60 + I) * 60 + S) * 1000,
	xtAddTimeOut(NextDay, highlight_next_day, YMD, _).

highlight_next_day(YMD, _) :-			% a new day has begun...
	change_day_highlight(YMD),
	highlight_current_day.

change_day_highlight(YMD) :-
	strip(YMD, Lab, Info, Fg, Bg), !,
	xtSetValues(Lab, [xmNforeground(Bg), xmNbackground(Fg)]),
	retract(strip(YMD, Lab, Info, Fg, Bg)),
	asserta(strip(YMD, Lab, Info, Bg, Fg)).
change_day_highlight(_).


highlight_current_hour :-
	date_and_time(date(Y,M,D), time(H,I,S)),
	YMDH is ((Y * 12 + M) * 32 + D) * 24 + H,
	change_hour_highlight(YMDH),
	NextHour is 3600000 - (I * 60 + S) * 1000,
	xtAddTimeOut(NextHour, highlight_next_hour, YMDH, _).

highlight_next_hour(YMDH, _) :-			% a new hour has started...
	change_hour_highlight(YMDH),
	highlight_current_hour,
						% if text exists, do alert
	date_and_time(date(Y,M,D), time(H,_,_)),
	YM is Y * 12 + M,
	YMD is YM * 32 + D,
	( pcal(YM, YMD, H, Txt) ->
	  alert(H, Txt, pcal(YM, YMD, H, Txt))
	; true
	).

maybe_highlight_hour(YMD) :-
	date_and_time(date(Y,M,D), time(H,_,_)),
	YMD =:= (Y * 12 + M) * 32 + D, !,
	YMDH is YMD * 24 + H,
	change_hour_highlight(YMDH).
maybe_highlight_hour(_).

change_hour_highlight(YMDH) :-
	editor(YMDH, Lab, Text, Fg, Bg), !,
	xtSetValues(Lab, [xmNforeground(Bg), xmNbackground(Fg)]),
	retract(editor(YMDH, Lab, Text, Fg, Bg)),
	asserta(editor(YMDH, Lab, Text, Bg, Fg)).
change_hour_highlight(_).


%%%%%%%%%%  alert box  %%%%%%%%%%

%  alert - create dialog box when an appointment time is reached

alert(Hour, Msg, Pcal) :-
	topwidget(Shell), !,
	get_date_label(time(Hour,0,0), '%2c:00', _, LabStr),
	xmStringCreateLtoR(Msg, xmFONTLIST_DEFAULT_TAG, MsgStr),
	xmCreateInformationDialog(Shell, alert,
			[xmNdialogStyle(xmDIALOG_APPLICATION_MODAL),
			 xmNdialogTitle(LabStr),
			 xmNmessageString(MsgStr)],
				  Alert),
	xtAddCallback(Alert, xmNokCallback, alert_ok_button, _),
	xtAddCallback(Alert, xmNcancelCallback, alert_cancel_button, Pcal),
	xmMessageBoxGetChild(Alert, xmDIALOG_HELP_BUTTON, Help),
	xtUnmanageChild(Help),
	xtManageChild(Alert).

%
%  popdown message box
%
alert_ok_button(Wid, _, _) :-
	xtUnmanageChild(Wid),
	xtDestroyWidget(Wid).

%
%  remove calendar entry
%
alert_cancel_button(Wid, pcal(YM,YMD,H,Txt), _) :-
	( daywidget(_, YMD, _, _, _) ->		% update day editor...
	  clear_hr_entries(YMD, H, H)
	;
	  retract(pcal(YM, YMD, H, Txt)),
	  update_month_strip(YM, YMD) 		% .. or update month strip
	;
	  true
	), !,
	alert_ok_button(Wid, _, _).


%%%%%%%%%%  utils etc.  %%%%%%%%%%

%
%  text manipulation
%
get_date_label(Date, Fmt, Label, AsxmStr) :-
	time_stamp(Date, Fmt, Label),
	xmStringCreateLtoR(Label, xmFONTLIST_DEFAULT_TAG, AsxmStr).

get_day_entries(YM, YMD, Str) :-
	( pcal(YM, YMD, Slot, Txt),
	  combine_hrtxt(Slot, Txt, T1),
	  recorda(txt,T1,_),
	  fail
	  ;
	  gather_txt(Text)
	), !,
	xmStringCreateLtoR(Text, xmFONTLIST_DEFAULT_TAG, Str).


get_hour_entry(YMD, Hr, Txt) :-
	YM is YMD // 32,
	( pcal(YM, YMD, Hr, Txt)
	  ;
	  Txt = ''
	), !.

get_note_entry(YMD, Txt) :-
	YM is YMD // 32,
	( pcal(YM, YMD, notes, Txt)
	  ;
	  Txt = ''
	), !.


update_month_strip(YM, YMD) :-
	monthwidget(YM, Shell, _, _), !,
	get_day_entries(YM, YMD, TextStr),
	strip(YMD, Lab, Info, _, _), !,
	xtGetValues(Shell, [xmNheight(OldSH)]),
	xtGetValues(Info, [xmNheight(OldH)]),
	xtSetValues(Info, [xmNlabelType(xmSTRING), xmNlabelString(TextStr)]),
	xtGetValues(Info, [xmNheight(NewH)]),
	xtSetValues(Lab,  [xmNheight(NewH)]),
	NewSH is OldSH + (NewH - OldH),
	xtSetValues(Shell, [xmNheight(NewSH)]).		% correct strip size



update_day_entries(YM, YMD) :-
	retractall(pcal(YM, YMD, _, _)),	% delete old entries
	get_hour_range(First, Last),
	update_hr_entries(YM, YMD, First, Last),
	update_notes_entry(YM, YMD).

update_hr_entries(_, _, M, N) :- M > N, !.
update_hr_entries(YM, YMD, M, N) :-
	YMDH is YMD * 24 + M,
	editor(YMDH, _, Text, _, _), !,
	xmTextGetString(Text, Str),
	( Str \== '' ->
	  assertz(pcal(YM, YMD, M, Str))	% new text
	  ;
	  true					% no new text
	), !,
	M1 is M + 1,
	update_hr_entries(YM, YMD, M1, N).

update_notes_entry(YM, YMD) :-
	editnote(YMD, Text),
	xmTextGetString(Text, Str),
	( Str \== '' ->
	  assertz(pcal(YM, YMD, notes, Str))	% new text
	  ;
	  true					% no new text
	), !.


clear_day_entries(YM, YMD) :-
	retractall(pcal(YM, YMD, _, _)),	
	get_hour_range(First, Last),
	clear_hr_entries(YMD, First, Last),
	clear_notes_entry(YMD).

clear_hr_entries(_, M, N) :- M > N, !.
clear_hr_entries(YMD, M, N) :-
	YMDH is YMD * 24 + M,
	editor(YMDH, _, Text, _, _), !,
	xmTextSetString(Text, ''),
	M1 is M + 1,
	clear_hr_entries(YMD, M1, N).

clear_notes_entry(YMD) :-
	editnote(YMD, Text), !,
	xmTextSetString(Text, '').


combine_hrtxt(Hr, Ti, To) :-
	( Hr == notes ->
	  To = Ti
	  ;
	  Hr < 10 ->
	  concat_atom([' ', Hr, ': ', Ti], To)
	  ;
	  concat_atom([Hr, ': ', Ti], To)
	).

gather_txt(Text) :-
	recorded(txt, Txt, Rec),
	!,
	erase(Rec),
	gather_txt1([Txt], Text).
gather_txt(' ').			% no data

gather_txt1(SoFar, Text) :-
	recorded(txt, Mtxt, Rec),
	!,
	erase(Rec),
	name(NL,[10]),
	gather_txt1([Mtxt,NL|SoFar], Text).
gather_txt1(SoFar, Text) :-
	concat_atom(SoFar, Text).


%
%  file I/O
%
get_month_entries(D, YM) :-
	time_stamp(D, '$HOME/Calendar/xp%3M%y', Pat),
	expanded_file_name(Pat, File), !,
	( file_exists(File, [read,write]) ->
	  read_cal_file(File, YM)
	  ;
	  true
	).

read_cal_file(File, YM) :-
	open(File, read, S),
	repeat,
	read(S,T),
	( T = cal(Day, Slot, Text) ->
	  YMD is YM * 32 + Day,
	  assertz(pcal(YM, YMD, Slot, Text)),
	  fail
	  ;
	  close(S)
	), !.


put_month_entries(D, YM) :-
	time_stamp(D, '$HOME/Calendar/xp%3M%y', Pat),
	expanded_file_name(Pat,File), !,
	write_cal_file(File, YM).

write_cal_file(File, YM) :-
	open(File, write, S),
	( pcal(YM, YMD, Slot, Text),
	  Day is YMD mod 32,
	  writeq(S, cal(Day, Slot, Text)), put(S, 0'.), nl(S),
	  fail
	  ;
	  close(S)
	), !.


%
%  date utils
%
no_of_days_in( 0, _, 31).
no_of_days_in( 1, Y, D) :-
	( Y mod 4 > 0 -> D = 28 ; Y == 0 -> D = 29 ; D = 28).
no_of_days_in( 2, _, 31).
no_of_days_in( 3, _, 30).
no_of_days_in( 4, _, 31).
no_of_days_in( 5, _, 30).
no_of_days_in( 6, _, 31).
no_of_days_in( 7, _, 31).
no_of_days_in( 8, _, 30).
no_of_days_in( 9, _, 31).
no_of_days_in(10, _, 30).
no_of_days_in(11, _, 31).


ym(YM,Y,M) :-
	( var(YM) ->
	  YM is Y * 12 + M
	  ;
	  Y is YM // 12,
	  M is YM mod 12
	).


%  should get this from resources...
get_hour_range(9, 18).
