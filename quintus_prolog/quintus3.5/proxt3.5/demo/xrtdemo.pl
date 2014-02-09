%  SCCS: @(#)xrtdemo.pl	20.2 08/03/94
%  Purpose: A demo of the proxrt extension to proxt
%
%  This program demonstrates the use of the 'proxrt' interface to Xrt/graph
%  widget which in turn shows how proxt can be extended to support additional
%  motif widgets.
%  In order to run this needs the Xrt/graph library, libxrtm.a,
%  supplied by KLGroup Inc., Toronto, Canada

:- use_module(proxrt).
:- use_module(library(proxt)).
:- use_module(library(basics), [memberchk/2]).

runtime_entry(start) :- main.

main :-
	xrtMakeDataFromFile('xrtdemo.dat', Data),
	xtAppInitialize(App, panel, [], Top),
	xtCreateManagedWidget(form, xmFormWidgetClass, Top, [], Form),

	xmCreateRadioBox(Form, rbox,
			 [xmNentryClass(xmToggleButtonWidgetClass),
			  xmNorientation(xmHORIZONTAL),
			  xmNtopAttachment(xmATTACH_FORM),
			  xmNleftAttachment(xmATTACH_FORM)], Rbox),
	xtManageChild(Rbox),
	xmCreateToggleButton(Rbox, bar, [xmNset(true)], Bar),
	xtManageChild(Bar),
	xmCreateToggleButton(Rbox, plot, [], Plot),
	xtManageChild(Plot),
	xmCreateToggleButton(Form, invert,
			     [xmNleftAttachment(xmATTACH_WIDGET),
			      xmNleftWidget(Rbox),
			      xmNtopAttachment(xmATTACH_FORM)], Invert),
	xtManageChild(Invert),
	xmCreateToggleButton(Form, transpose,
			     [xmNleftAttachment(xmATTACH_WIDGET),
			      xmNleftWidget(Invert),
			      xmNtopAttachment(xmATTACH_FORM)], Transpose),
	xtManageChild(Transpose),

	xtCreateManagedWidget(graph, xtXrtGraphWidgetClass, Form,
			      [xmNtopAttachment(xmATTACH_WIDGET),
			       xmNtopWidget(Rbox),
			       xmNleftAttachment(xmATTACH_FORM),
			       xmNrightAttachment(xmATTACH_FORM),
			       xmNbottomAttachment(xmATTACH_FORM),
			       xmNwidth(500),

			       xtNxrtData(Data),
			       xtNxrtType(xrtTYPE_BAR),
			       xtNxrtXAnnotationMethod(xrtXMETHOD_POINT_LABELS),
			       xtNxrtHeaderStrings(['Oft Micros Inc']),
			       xtNxrtHeaderForegroundColor(purple),
			       xtNxrtFooterStrings(['1995 Quarterly Results']),
			       xtNxrtSetLabels(['Expenses','Revenues']),
			       xtNxrtPointLabels(['Q1','Q2','Q3','Q4'])
			      ], Graph),

	xtAddCallback(Bar, xmNvalueChangedCallback, bar, Graph),
	xtAddCallback(Plot, xmNvalueChangedCallback, plot, Graph),
	xtAddCallback(Invert, xmNvalueChangedCallback, invert, Graph),
	xtAddCallback(Transpose, xmNvalueChangedCallback, transpose, Graph),
	xtRealizeWidget(Top),
	xtAppMainLoop(App).


% callbacks

bar(_Wid, Graph, CallData) :-
	proxtGetCallbackFields(CallData, Fields),
	memberchk(set(true), Fields),

	% change the second data style
	xtGetValues(Graph, [xtNxrtDataStyles(Styles)]),
	( Styles = [S1,_|Rest] ->
	  proxrtMakeDataStyle(xrtLPAT_SOLID,xrtFPAT_CROSS_HATCHED,black,1,
			      xrtPOINT_CIRCLE,blue,10,S2),
	  NewStyles = [S1,S2|Rest]
	; NewStyles = Styles
	),
	xtSetValues(Graph, [xtNxrtDataStyles(NewStyles),
			    xtNxrtType(xrtTYPE_BAR)]).

plot(_Wid, Graph, CallData) :-
	proxtGetCallbackFields(CallData, Fields),
	memberchk(set(true), Fields),
	xtSetValues(Graph, [xtNxrtType(xrtTYPE_PLOT)]).

invert(_Wid, Graph, CallData) :-
	proxtGetCallbackFields(CallData, Fields),
	( memberchk(set(true), Fields) ->
	  xtSetValues(Graph, [xtNxrtInvertOrientation(true)])
	; xtSetValues(Graph, [xtNxrtInvertOrientation(false)])
	).

transpose(_Wid, Graph, CallData) :-
	proxtGetCallbackFields(CallData, Fields),
	( memberchk(set(true), Fields) ->
	  xtSetValues(Graph, [xtNxrtTransposeData(true)])
	; xtSetValues(Graph, [xtNxrtTransposeData(false)])
	).
