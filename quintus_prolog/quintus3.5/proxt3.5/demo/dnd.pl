% SCCS   :  @(#)dnd.pl	20.1 06/30/94
% Author :  Jim Crammond
% Purpose:  A Drag and Drop demo

%
%  This program demonstrates drag and drop.
%
%  This registers a pushbutton as a drop site for COMPOUND_TEXT and
%  BACKGROUND targets.  Then sets up a scrollbar as a drag source for
%  COMPOUND_TEXT and a set of coloured labels as drag source for BACKGROUND.
%  A textfield is created which is a builtin drag source for COMPOUND_TEXT.
%

:- module(dnd, [main/0]).

:- use_module(library(proxt)).
:- use_module(library(basics)).

:- dynamic xatom/2.

user:runtime_entry(start) :- main.

main :-
	xtAppInitialize(App, dnd, [], Top),

	%
	% create pushbutton
	%
	xmCreateBulletinBoard(Top, bboard, [], BBoard),
	xtManageChild(BBoard),
	xmCreateForm(BBoard, form, [], Form),
	xtManageChild(Form),

	xmStringCreateLtoR('Drop Site/Quit Button', xmFONTLIST_DEFAULT_TAG,
			   String),

	xmCreatePushButton(Form, button, [xmNwidth(150),
					  xmNlabelString(String)], Btn),
	xtManageChild(Btn),
	xmStringFree(String),

	xtDisplay(Top, Display),
	xmInternAtom(Display, 'COMPOUND_TEXT', false, CompoundText),
	xmInternAtom(Display, 'BACKGROUND', false, Background),
	assert(xatom('COMPOUND_TEXT', CompoundText)),
	assert(xatom('BACKGROUND', Background)),
	xmDropSiteRegister(Btn, [xmNimportTargets([CompoundText,Background]),
			         xmNdropSiteOperations(xmDROP_COPY),
			         xmNdropProc(process_drop)]),
	
	xtAddCallback(Btn, xmNactivateCallback, button_pressed, 0),

	xtRealizeWidget(Top),

	%
	% add scrollbar
	%
	xtCreatePopupShell(scrollbar, topLevelShellWidgetClass, Top, [], Popup),
	xmCreateBulletinBoard(Popup, bboard1, [], BBoard1),
	xtManageChild(BBoard1),
	xtParseTranslationTable('#override <Btn2Down>: StartDrag()', TT),
	xmCreateScrollBar(BBoard1, scroll, [xmNorientation(xmHORIZONTAL),
					    xmNtranslations(TT),
					    xmNwidth(200)], SBar),
	xtAppAddActions(App, [action('StartDrag',start_sbar_drag)]),
	xtManageChild(SBar),
	xtPopup(Popup, xtGrabNone),

	%
	% add rowcolumn of labels
	%
	xtCreatePopupShell(labels, topLevelShellWidgetClass, Top,
				   [xmNwidth(100)], Popup2),
	xmCreateRowColumn(Popup2, rowc, [], RowC),
	xtManageChild(RowC),
	xtParseTranslationTable('#override <Btn2Down>: StartDrag2()', TT2),
	LabRes = [xmNtranslations(TT2)],
	xtConvert(RowC, xmRString, red, 5, xmRPixel, Red, _),
	xtConvert(RowC, xmRString, blue, 5, xmRPixel, Blue, _),
	xtConvert(RowC, xmRString, green, 6, xmRPixel, Green, _),
	xtConvert(RowC, xmRString, yellow, 7, xmRPixel, Yellow, _),
	xtConvert(RowC, xmRString, cyan, 5, xmRPixel, Cyan, _),
	xtConvert(RowC, xmRString, orange, 6, xmRPixel, Orange, _),
	xmCreateLabel(RowC, ' ', [xmNbackground(Red)|LabRes], Lab1),
	xmCreateLabel(RowC, ' ', [xmNbackground(Blue)|LabRes], Lab2),
	xmCreateLabel(RowC, ' ', [xmNbackground(Green)|LabRes], Lab3),
	xmCreateLabel(RowC, ' ', [xmNbackground(Yellow)|LabRes], Lab4),
	xmCreateLabel(RowC, ' ', [xmNbackground(Cyan)|LabRes], Lab5),
	xmCreateLabel(RowC, ' ', [xmNbackground(Orange)|LabRes], Lab6),
	xtAppAddActions(App, [action('StartDrag2',start_label_drag)]),
	xtManageChildren([Lab1,Lab2,Lab3,Lab4,Lab5,Lab6]),
	xtPopup(Popup2, xtGrabNone),

	%
	% add textfield
	%
	xtCreatePopupShell(textfield, topLevelShellWidgetClass, Top,[], Popup3),
	xmCreateBulletinBoard(Popup3, bboard, [], BBoard2),
	xtManageChild(BBoard2),
	xLoadQueryFont(Display, '8x13', Font),
	xmFontListCreate(Font, xmFONTLIST_DEFAULT_TAG, FontList),
	xmStringCreate('Text Field Widget', xmFONTLIST_DEFAULT_TAG, TextString),
	xmCreateLabel(BBoard2, label, [xmNlabelString(TextString)], Label),
	xtManageChild(Label),
	xmStringFree(TextString),
	xmCreateTextField(BBoard2, text, [xmNy(30),
					 xmNcolumns(25),
					 xmNvalue('this is some text'),
					 xmNfontList(FontList)], Text),
	xtManageChild(Text),
	xtPopup(Popup3, xtGrabNone),

	%
	% begin draggin' n' droppin' !
	%
	xtAppMainLoop(App).


button_pressed(_, _, _) :-
	raise_exception('end_of_demo').


%
%  drop site
%

process_drop(Wid, _, Call) :-
	proxtGetCallbackFields(Call, CallL),
	memberchk(drag_context(DragW), CallL),
	xatom('COMPOUND_TEXT', Target1),
	xatom('BACKGROUND', Target2),
	DT = [droptransfer(Wid,Target1),droptransfer(Wid,Target2)],
	xmDropTransferStart(DragW,
			    [xmNdropTransfers(DT),
			     xmNtransferProc(transfer_data)], _).

transfer_data(Wid, Btn, _, Type, Value, _, _) :-
	Type =\= 0,			% just fail if called with null type
	xtParent(Wid, Parent),
	xtDisplay(Parent, Dis),
	xmGetAtomName(Dis, Type, TypeName),
	( TypeName = 'COMPOUND_TEXT' ->
	  xmCvtCTToXmString(Value, String),
	  xtSetValues(Btn, [xmNlabelString(String)]),
	  xtSetValues(Btn, [xmNwidth(150)])
	; TypeName = 'BACKGROUND' ->
	  xtSetValues(Btn, [xmNbackground(Value)])
	; TypeName = 'PIXEL' ->		% for default label drag source
	  xtSetValues(Btn, [xmNbackground(Value)])
	; format('Type ~w not supported~n', [TypeName]),
	  xtSetValues(Wid, [xmNtransferStatus(xmTRANSFER_FAILURE),
			    xmNnumDropTransfers(0)])
	).



%
% drag source
%
start_sbar_drag(Wid, Event, _) :-
	xatom('COMPOUND_TEXT',CText),
	xmDragStart(Wid, Event, [xmNexportTargets([CText]),
				 xmNclientData(Wid),
				 xmNdragOperations(xmDROP_COPY),
				 xmNconvertProc(sbar_convert_proc)], _).

sbar_convert_proc(Wid, _, Target, Target, Value, Len, 8) :-
	xatom('COMPOUND_TEXT', Target),
	xtGetValues(Wid, [xmNclientData(SrcWid)]),
	xtGetValues(SrcWid, [xmNvalue(N)]),
	number_chars(N,NL),
	atom_chars(Value,NL),
	length([_|NL], Len).	% Len = strlen + 1


start_label_drag(Wid, Event, _) :-
	xatom('BACKGROUND', Bg),
	xmDragStart(Wid, Event, [xmNexportTargets([Bg]),
				 xmNclientData(Wid),
				 xmNdragOperations(xmDROP_COPY),
				 xmNconvertProc(label_convert_proc)], _).

label_convert_proc(Wid, _, Target, Target, Value, 4, 32) :-
	xatom('BACKGROUND', Target),
	xtGetValues(Wid, [xmNclientData(SrcWid)]),
	xtGetValues(SrcWid, [xmNbackground(Value)]).
