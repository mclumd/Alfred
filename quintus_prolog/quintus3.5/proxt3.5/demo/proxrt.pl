%
% SCCS   :  @(#)proxrt.pl	20.1 08/03/94
% Purpose:  Example of adding a widget class to proxt:
%	    interface to Xrt/graph widget.
%	    Xrt/graph is a trademark of KLGroup Inc, Toronto, Canada
%
% Copyright (C) 1994, Quintus Corporation. All rights reserved
%

:- module(proxrt, [xrtMakeData/5,
		   xrtMakeDataFromFile/2,
		   xrtDestroyData/2,
		   proxrtMakeDataStyle/8,
		   proxrtMakeXLabel/3]).

% we load proxt at compile time only to make use of some of the structs
% data types defined by proxt.

:- load_files(library(structs_decl), [when(compile_time),if(changed)]).
:- load_files(library(proxt), [when(both),if(changed)]).
:- use_module(library(structs), [get_contents/3,
				 put_contents/3,
				 null_foreign_term/2,
				 cast/3,
				 new/2]).

:- multifile resources:resource/4.
:- multifile resources:array_resource_count/2.
:- multifile resources:callback_struct_type/3.
:- multifile resources:get_widget_class_address/2.

:- multifile resources:from_representation_type/3.
:- multifile resources:to_representation_type/3.

%
%  RESOURCES
%

%
%  resource(+ProxtName, +WidgetClass, -ResourceName, -ResourceType)
%	defines the resource names and types
%	the xmR* types used are defined by proxt
%
%  	Note: for array resources that have a corresponding count resource
%	the type is proxtArray(Type).  This is true of all motif resources
%	but xrt uses null terminated arrays instead, so this doesn't apply
%
resources:resource(xtNxrtAxisBoundingBox, _, xrtAxisBoundingBox, xmRBoolean).
resources:resource(xtNxrtAxisFont, _, xrtAxisFont, xmRFont).
resources:resource(xtNxrtBackgroundColor, _, xrtBackgroundColor, xmRString).
resources:resource(xtNxrtBarClusterOverlap, _, xrtBarClusterOverlap, xmRInt).
resources:resource(xtNxrtBarClusterWidth, _, xrtBarClusterWidth, xmRInt).
resources:resource(xtNxrtData, _, xrtData, xtRxrtData).
resources:resource(xtNxrtData2, _, xrtData2, xtRxrtData).
resources:resource(xtNxrtDataStyles, _, xrtDataStyles, xtRxrtDataStyles).
resources:resource(xtNxrtDataStylesUseDefault, _, xrtDataStylesUseDefault, xmRBoolean).
resources:resource(xtNxrtDataStyles2, _, xrtDataStyles2, xtRxrtDataStyles).
resources:resource(xtNxrtDataStyles2UseDefault, _, xrtDataStyles2UseDefault, xmRBoolean).
resources:resource(xtNxrtDoubleBuffer, _, xrtDoubleBuffer, xmRBoolean).
resources:resource(xtNxrtExposeCallback, _, xrtExposeCallback, xmRCallback).
resources:resource(xtNxrtFooterAdjust, _, xrtFooterAdjust, xtRxrtAdjust).
resources:resource(xtNxrtFooterBackgroundColor, _, xrtFooterBackgroundColor, xmRString).
resources:resource(xtNxrtFooterBorder, _, xrtFooterBorder, xtRxrtBorder).
resources:resource(xtNxrtFooterBorderWidth, _, xrtFooterBorderWidth, xmRInt).
resources:resource(xtNxrtFooterFont, _, xrtFooterFont, xmRFont).
resources:resource(xtNxrtFooterForegroundColor, _, xrtFooterForegroundColor, xmRString).
resources:resource(xtNxrtFooterHeight, _, xrtFooterHeight, xmRInt).
resources:resource(xtNxrtFooterStrings, _, xrtFooterStrings, xtRxrtStrings).
resources:resource(xtNxrtFooterWidth, _, xrtFooterWidth, xmRInt).
resources:resource(xtNxrtFooterX, _, xrtFooterX, xmRInt).
resources:resource(xtNxrtFooterXUseDefault, _, xrtFooterXUseDefault, xmRBoolean).
resources:resource(xtNxrtFooterY, _, xrtFooterY, xmRInt).
resources:resource(xtNxrtFooterYUseDefault, _, xrtFooterYUseDefault, xmRBoolean).
resources:resource(xtNxrtForegroundColor, _, xrtForegroundColor, xmRString).
resources:resource(xtNxrtFrontDataset, _, xrtFrontDataset, xmRInt).
resources:resource(xtNxrtGraphBackgroundColor, _, xrtGraphBackgroundColor, xmRString).
resources:resource(xtNxrtGraphBorder, _, xrtGraphBorder, xtRxrtBorder).
resources:resource(xtNxrtGraphBorderWidth, _, xrtGraphBorderWidth, xmRInt).
resources:resource(xtNxrtGraphDepth, _, xrtGraphDepth, xmRInt).
resources:resource(xtNxrtGraphForegroundColor, _, xrtGraphForegroundColor, xmRString).
resources:resource(xtNxrtGraphHeight, _, xrtGraphHeight, xmRInt).
resources:resource(xtNxrtGraphHeightUseDefault, _, xrtGraphHeightUseDefault, xmRBoolean).
resources:resource(xtNxrtGraphInclination, _, xrtGraphInclination, xmRInt).
resources:resource(xtNxrtGraphRotation, _, xrtGraphRotation, xmRInt).
resources:resource(xtNxrtGraphWidth, _, xrtGraphWidth, xmRInt).
resources:resource(xtNxrtGraphWidthUseDefault, _, xrtGraphWidthUseDefault, xmRBoolean).
resources:resource(xtNxrtGraphX, _, xrtGraphX, xmRInt).
resources:resource(xtNxrtGraphXUseDefault, _, xrtGraphXUseDefault, xmRBoolean).
resources:resource(xtNxrtGraphY, _, xrtGraphY, xmRInt).
resources:resource(xtNxrtGraphYUseDefault, _, xrtGraphYUseDefault, xmRBoolean).
resources:resource(xtNxrtHeaderAdjust, _, xrtHeaderAdjust, xtRxrtAdjust).
resources:resource(xtNxrtHeaderBackgroundColor, _, xrtHeaderBackgroundColor, xmRString).
resources:resource(xtNxrtHeaderBorder, _, xrtHeaderBorder, xtRxrtBorder).
resources:resource(xtNxrtHeaderBorderWidth, _, xrtHeaderBorderWidth, xmRInt).
resources:resource(xtNxrtHeaderFont, _, xrtHeaderFont, xmRFont).
resources:resource(xtNxrtHeaderForegroundColor, _, xrtHeaderForegroundColor, xmRString).
resources:resource(xtNxrtHeaderHeight, _, xrtHeaderHeight, xmRInt).
resources:resource(xtNxrtHeaderStrings, _, xrtHeaderStrings, xtRxrtStrings).
resources:resource(xtNxrtHeaderWidth, _, xrtHeaderWidth, xmRInt).
resources:resource(xtNxrtHeaderX, _, xrtHeaderX, xmRInt).
resources:resource(xtNxrtHeaderXUseDefault, _, xrtHeaderXUseDefault, xmRBoolean).
resources:resource(xtNxrtHeaderY, _, xrtHeaderY, xmRInt).
resources:resource(xtNxrtHeaderYUseDefault, _, xrtHeaderYUseDefault, xmRBoolean).
resources:resource(xtNxrtInvertOrientation, _, xrtInvertOrientation, xmRBoolean).
resources:resource(xtNxrtLegendAnchor, _, xrtLegendAnchor, xtRxrtAnchor).
resources:resource(xtNxrtLegendBackgroundColor, _, xrtLegendBackgroundColor, xmRString).
resources:resource(xtNxrtLegendBorder, _, xrtLegendBorder, xtRxrtBorder).
resources:resource(xtNxrtLegendBorderWidth, _, xrtLegendBorderWidth, xmRInt).
resources:resource(xtNxrtLegendFont, _, xrtLegendFont, xmRFont).
resources:resource(xtNxrtLegendForegroundColor, _, xrtLegendForegroundColor, xmRString).
resources:resource(xtNxrtLegendHeight, _, xrtLegendHeight, xmRInt).
resources:resource(xtNxrtLegendOrientation, _, xrtLegendOrientation, xtRxrtAlign).
resources:resource(xtNxrtLegendShow, _, xrtLegendShow, xmRBoolean).
resources:resource(xtNxrtLegendWidth, _, xrtLegendWidth, xmRInt).
resources:resource(xtNxrtLegendX, _, xrtLegendX, xmRInt).
resources:resource(xtNxrtLegendXUseDefault, _, xrtLegendXUseDefault, xmRBoolean).
resources:resource(xtNxrtLegendY, _, xrtLegendY, xmRInt).
resources:resource(xtNxrtLegendYUseDefault, _, xrtLegendYUseDefault, xmRBoolean).
resources:resource(xtNxrtMarkerDataStyle, _, xrtMarkerDataStyle, xtRxrtDataStyle).
resources:resource(xtNxrtMarkerDataStyleUseDefault, _, xrtMarkerDataStyleUseDefault, xmRBoolean).
resources:resource(xtNxrtMarkerDataset, _, xrtMarkerDataset, xmRInt).
resources:resource(xtNxrtOtherDataStyle, _, xrtOtherDataStyle, xtRxrtDataStyle).
resources:resource(xtNxrtOtherDataStyleUseDefault, _, xrtOtherDataStyleUseDefault, xmRBoolean).
resources:resource(xtNxrtPieMinSlices, _, xrtPieMinSlices, xmRInt).
resources:resource(xtNxrtPieOrder, _, xrtPieOrder, xtRxrtPieOrder).
resources:resource(xtNxrtPieThresholdMethod, _, xrtPieThresholdMethod, xtRxrtPieThresholdMethod).
resources:resource(xtNxrtPieThresholdValue, _, xrtPieThresholdValue, xtRxrtFloat).
resources:resource(xtNxrtPointLabels, _, xrtPointLabels, xtRxrtStrings).
resources:resource(xtNxrtPointLabels2, _, xrtPointLabels2, xtRxrtStrings).
resources:resource(xtNxrtRepaint, _, xrtRepaint, xmRBoolean).
resources:resource(xtNxrtResizeCallback, _, xrtResizeCallback, xmRCallback).
resources:resource(xtNxrtSetLabels, _, xrtSetLabels, xtRxrtStrings).
resources:resource(xtNxrtSetLabels2, _, xrtSetLabels2, xtRxrtStrings).
resources:resource(xtNxrtTimeUnit, _, xrtTimeUnit, xtRxrtTimeUnit).
resources:resource(xtNxrtTimeBase, _, xrtTimeBase, xmRInt).
resources:resource(xtNxrtTimeFormat, _, xrtTimeFormat, xmRString).
resources:resource(xtNxrtTimeFormatUseDefault, _, xrtTimeFormatUseDefault, xmRBoolean).
resources:resource(xtNxrtTransposeData, _, xrtTransposeData, xmRBoolean).
resources:resource(xtNxrtType, _, xrtType, xtRxrtType).
resources:resource(xtNxrtType2, _, xrtType2, xtRxrtType).
resources:resource(xtNxrtXAnnotationMethod, _, xrtXAnnotationMethod, xtRxrtXMethod).
resources:resource(xtNxrtXAnnotationRotation, _, xrtXAnnotationRotation, xtRxrtRotate).
resources:resource(xtNxrtXAxisLogarithmic, _, xrtXAxisLogarithmic, xmRBoolean).
resources:resource(xtNxrtXAxisShow, _, xrtXAxisShow, xmRBoolean).
resources:resource(xtNxrtXGrid, _, xrtXGrid, xtRxrtFloat).
resources:resource(xtNxrtXGridDataStyle, _, xrtXGridDataStyle, xtRxrtDataStyle).
resources:resource(xtNxrtXGridDataStyleUseDefault, _, xrtXGridDataStyleUseDefault, xmRBoolean).
resources:resource(xtNxrtXGridUseDefault, _, xrtXGridUseDefault, xmRBoolean).
resources:resource(xtNxrtXLabels, _, xrtXLabels, xtRxrtXLabels).
resources:resource(xtNxrtXMarker, _, xrtXMarker, xtRxrtFloat).
resources:resource(xtNxrtXMarkerPoint, _, xrtXMarkerPoint, xmRInt).
resources:resource(xtNxrtXMarkerSet, _, xrtXMarkerSet, xmRInt).
resources:resource(xtNxrtXMarkerShow, _, xrtXMarkerShow, xmRBoolean).
resources:resource(xtNxrtXMax, _, xrtXMax, xtRxrtFloat).
resources:resource(xtNxrtXMaxUseDefault, _, xrtXMaxUseDefault, xmRBoolean).
resources:resource(xtNxrtXMin, _, xrtXMin, xtRxrtFloat).
resources:resource(xtNxrtXMinUseDefault, _, xrtXMinUseDefault, xmRBoolean).
resources:resource(xtNxrtXNum, _, xrtXNum, xtRxrtFloat).
resources:resource(xtNxrtXNumUseDefault, _, xrtXNumUseDefault, xmRBoolean).
resources:resource(xtNxrtXOrigin, _, xrtXOrigin, xtRxrtFloat).
resources:resource(xtNxrtXOriginUseDefault, _, xrtXOriginUseDefault, xmRBoolean).
resources:resource(xtNxrtXPrecision, _, xrtXPrecision, xmRInt).
resources:resource(xtNxrtXPrecisionUseDefault, _, xrtXPrecisionUseDefault, xmRBoolean).
resources:resource(xtNxrtXTick, _, xrtXTick, xtRxrtFloat).
resources:resource(xtNxrtXTickUseDefault, _, xrtXTickUseDefault, xmRBoolean).
resources:resource(xtNxrtXTitle, _, xrtXTitle, xmRString).
resources:resource(xtNxrtXTitleRotation, _, xrtXTitleRotation, xtRxrtRotate).
resources:resource(xtNxrtY2AnnotationRotation, _, xrtY2AnnotationRotation, xtRxrtRotate).
resources:resource(xtNxrtY2AxisLogarithmic, _, xrtY2AxisLogarithmic, xmRBoolean).
resources:resource(xtNxrtY2AxisShow, _, xrtY2AxisShow, xmRBoolean).
resources:resource(xtNxrtY2Max, _, xrtY2Max, xtRxrtFloat).
resources:resource(xtNxrtY2MaxUseDefault, _, xrtY2MaxUseDefault, xmRBoolean).
resources:resource(xtNxrtY2Min, _, xrtY2Min, xtRxrtFloat).
resources:resource(xtNxrtY2MinUseDefault, _, xrtY2MinUseDefault, xmRBoolean).
resources:resource(xtNxrtY2Num, _, xrtY2Num, xtRxrtFloat).
resources:resource(xtNxrtY2NumUseDefault, _, xrtY2NumUseDefault, xmRBoolean).
resources:resource(xtNxrtY2Precision, _, xrtY2Precision, xmRInt).
resources:resource(xtNxrtY2PrecisionUseDefault, _, xrtY2PrecisionUseDefault, xmRBoolean).
resources:resource(xtNxrtY2AxisReversed, _, xrtY2AxisReversed, xmRBoolean).
resources:resource(xtNxrtY2Tick, _, xrtY2Tick, xtRxrtFloat).
resources:resource(xtNxrtY2TickUseDefault, _, xrtY2TickUseDefault, xmRBoolean).
resources:resource(xtNxrtY2Title, _, xrtY2Title, xmRString).
resources:resource(xtNxrtY2TitleRotation, _, xrtY2TitleRotation, xtRxrtRotate).
resources:resource(xtNxrtYAnnotationRotation, _, xrtYAnnotationRotation, xtRxrtRotate).
resources:resource(xtNxrtYAxisConst, _, xrtYAxisConst, xtRxrtFloat).
resources:resource(xtNxrtYAxisLogarithmic, _, xrtYAxisLogarithmic, xmRBoolean).
resources:resource(xtNxrtYAxisMult, _, xrtYAxisMult, xtRxrtFloat).
resources:resource(xtNxrtYAxisReversed, _, xrtYAxisReversed, xmRBoolean).
resources:resource(xtNxrtYAxisShow, _, xrtYAxisShow, xmRBoolean).
resources:resource(xtNxrtYGrid, _, xrtYGrid, xtRxrtFloat).
resources:resource(xtNxrtYGridDataStyle, _, xrtYGridDataStyle, xtRxrtDataStyle).
resources:resource(xtNxrtYGridDataStyleUseDefault, _, xrtYGridDataStyleUseDefault, xmRBoolean).
resources:resource(xtNxrtYGridUseDefault, _, xrtYGridUseDefault, xmRBoolean).
resources:resource(xtNxrtYMarker, _, xrtYMarker, xtRxrtFloat).
resources:resource(xtNxrtYMarkerShow, _, xrtYMarkerShow, xmRBoolean).
resources:resource(xtNxrtYMax, _, xrtYMax, xtRxrtFloat).
resources:resource(xtNxrtYMaxUseDefault, _, xrtYMaxUseDefault, xmRBoolean).
resources:resource(xtNxrtYMin, _, xrtYMin, xtRxrtFloat).
resources:resource(xtNxrtYMinUseDefault, _, xrtYMinUseDefault, xmRBoolean).
resources:resource(xtNxrtYNum, _, xrtYNum, xtRxrtFloat).
resources:resource(xtNxrtYNumUseDefault, _, xrtYNumUseDefault, xmRBoolean).
resources:resource(xtNxrtYOrigin, _, xrtYOrigin, xtRxrtFloat).
resources:resource(xtNxrtYOriginUseDefault, _, xrtYOriginUseDefault, xmRBoolean).
resources:resource(xtNxrtYPrecision, _, xrtYPrecision, xmRInt).
resources:resource(xtNxrtYPrecisionUseDefault, _, xrtYPrecisionUseDefault, xmRBoolean).
resources:resource(xtNxrtYTick, _, xrtYTick, xtRxrtFloat).
resources:resource(xtNxrtYTickUseDefault, _, xrtYTickUseDefault, xmRBoolean).
resources:resource(xtNxrtYTitle, _, xrtYTitle, xmRString).
resources:resource(xtNxrtYTitleRotation, _, xrtYTitleRotation, xtRxrtRotate).

%
%  array_resource_count(+ArrayName, -CountName)
%	for an array resource, specifies the resource name that gives the
%	number of items in the array, e.g.
%		array_resource_count(xmNitems, xmNitemCount).
%	There are no facts for Xrt as it uses null terminated arrays instead.
%

%
%  callback_struct_type(+WidgetClassName, +ProxtName, -StructType).
%	defines the calldata type returned given a widgetclass and/or proxt
%	resource name. StructType is defined by a foreign_type decl below.
%
:- multifile resources:callback_struct_type/3.
resources:callback_struct_type(xtXrtGraph, _, xrtCallbackStruct).

%
%  get_widget_class_address(+WidgetClass, -Addr).
%	calls a C function to return the address of the widget class
%
resources:get_widget_class_address(xtXrtGraphWidgetClass, Addr) :-
	xrt_get_widget_class_addr(Addr).


%
%  TYPE CONVERSIONS
%

%
%  from_representation_type(+ResourceType, +UserValue, -XtValue).
%	converts a user specified resource value to an Xt value
%	- to be used for example by xtSetValues.
%	Typically, this maps enumerated type names to integer values.
%

% basic types
resources:from_representation_type(xtRxrtFloat, UserValue, XtValue) :-
	xrtFloatToArgVal(UserValue, XtValue).
resources:from_representation_type(xtRxrtAdjust, UserValue, XtValue) :-
	from_xrtAdjust(UserValue, XtValue).
resources:from_representation_type(xtRxrtAlign, UserValue, XtValue) :-
	from_xrtAlign(UserValue, XtValue).
resources:from_representation_type(xtRxrtAnchor, UserValue, XtValue) :-
	from_xrtAnchor(UserValue, XtValue).
resources:from_representation_type(xtRxrtBorder, UserValue, XtValue) :-
	from_xrtBorder(UserValue, XtValue).
resources:from_representation_type(xtRxrtData, Value, Value).
resources:from_representation_type(xtRxrtDataStyle, Value, Value).
resources:from_representation_type(xtRxrtPieOrder, UserValue, XtValue) :-
	from_xrtPieOrder(UserValue, XtValue).
resources:from_representation_type(xtRxrtPieThresholdMethod, UserValue, XtValue) :-
	from_xrtPieThresholdMethod(UserValue, XtValue).
resources:from_representation_type(xtRxrtRotate, UserValue, XtValue) :-
	from_xrtRotate(UserValue, XtValue).
resources:from_representation_type(xtRxrtTimeUnit, UserValue, XtValue) :-
	from_xrtTimeUnit(UserValue, XtValue).
resources:from_representation_type(xtRxrtType, UserValue, XtValue) :-
	from_xrtType(UserValue, XtValue).
resources:from_representation_type(xtRxrtXMethod, UserValue, XtValue) :-
	from_xrtXMethod(UserValue, XtValue).
resources:from_representation_type(xtRxrtXLabel, Value, Value).

% null terminated array types
% we don't need rules for arrays which have corresponding count facts -
% proxt handles that automatically. However, xrt uses null terminated arrays
% so we do need rules for these.
% We cheat here a little and use some predicates for converting
% arrays to lists that are not exported by module proxt. This relies on
% foreign_type definitions below
resources:from_representation_type(xtRxrtDataStyles, UserValue, XtValue) :-
	null_foreign_term(Null, xrtdatastyle),
	append(UserValue, [Null], NullTermValue),
	length(NullTermValue, Len),
	proxt:list_to_array(xtRxrtDataStyles, NullTermValue, Len, XtValue).
resources:from_representation_type(xtRxrtStrings, UserValue, XtValue) :-
	% the xmRString type treats integer 0 as a special case
	append(UserValue, [0], NullTermValue),
	length(NullTermValue, Len),
	proxt:list_to_array(xtRxrtStrings, NullTermValue, Len, XtValue).
resources:from_representation_type(xtRxrtXLabels, UserValue, XtValue) :-
	null_foreign_term(Null, xrtxlabel),
	append(UserValue, [Null], NullTermValue),
	length(NullTermValue, Len),
	proxt:list_to_array(xtRxrtXLabels, NullTermValue, Len, XtValue).


%
%  to_representation_type(+ResourceType, +XtValue, -UserValue).
%	converts an XtValue - as returned for example by xtGetValues -
%	to a user specified resource value. Typically, this maps integer
%	values to enumerated type names.
%

% basic types
resources:to_representation_type(xtRxrtFloat, XtValue, UserValue) :-
	xrtArgValToFloat(XtValue, UserValue).
resources:to_representation_type(xtRxrtAdjust, XtValue, UserValue) :-
	to_xrtAdjust(XtValue, UserValue).
resources:to_representation_type(xtRxrtAlign, XtValue, UserValue) :-
	to_xrtAlign(XtValue, UserValue).
resources:to_representation_type(xtRxrtAnchor, XtValue, UserValue) :-
	to_xrtAnchor(XtValue, UserValue).
resources:to_representation_type(xtRxrtBorder, XtValue, UserValue) :-
	to_xrtBorder(XtValue, UserValue).
resources:to_representation_type(xtRxrtData, Value, Value).
resources:to_representation_type(xtRxrtDataStyle, Value, Value).
resources:to_representation_type(xtRxrtPieOrder, XtValue, UserValue) :-
	to_xrtPieOrder(XtValue, UserValue).
resources:to_representation_type(xtRxrtPieThresholdMethod, XtValue, UserValue) :-
	to_xrtPieThresholdMethod(XtValue, UserValue).
resources:to_representation_type(xtRxrtRotate, XtValue, UserValue) :-
	to_xrtRotate(XtValue, UserValue).
resources:to_representation_type(xtRxrtTimeUnit, XtValue, UserValue) :-
	to_xrtTimeUnit(XtValue, UserValue).
resources:to_representation_type(xtRxrtType, XtValue, UserValue) :-
	to_xrtType(XtValue, UserValue).
resources:to_representation_type(xtRxrtXMethod, XtValue, UserValue) :-
	to_xrtXMethod(XtValue, UserValue).
resources:to_representation_type(xtRxrtXLabel, Value, Value).

% null terminated array types
resources:to_representation_type(xtRxrtDataStyles, XtValue, UserValue) :-
	cast(XtValue, xtRxrtDataStyles, Array),
	proxt:get_null_term_array_len(Array, Len),
	proxt:array_to_list(xtRxrtDataStyles, Array, Len, UserValue).
resources:to_representation_type(xtRxrtStrings, XtValue, UserValue) :-
	cast(XtValue, xtRxrtStrings, Array),
	proxt:get_null_term_array_len(Array, Len),
	proxt:array_to_list(xtRxrtStrings, Array, Len, UserValue).
resources:to_representation_type(xtRxrtXLabels, XtValue, UserValue) :-
	cast(XtValue, xtRxrtXLabels, Array),
	proxt:get_null_term_array_len(Array, Len),
	proxt:array_to_list(xtRxrtXLabels, Array, Len, UserValue).


% enumerated type values

from_xrtAdjust(xrtADJUST_LEFT,		1).
from_xrtAdjust(xrtADJUST_RIGHT,		2).
from_xrtAdjust(xrtADJUST_CENTER,	3).

to_xrtAdjust(1, xrtADJUST_LEFT).
to_xrtAdjust(2, xrtADJUST_RIGHT).
to_xrtAdjust(3, xrtADJUST_CENTER).

from_xrtAlign(xrtALIGN_VERTICAL,	1).
from_xrtAlign(xrtALIGN_HORIZONTAL,	2).

to_xrtAlign(1, xrtALIGN_VERTICAL).
to_xrtAlign(2, xrtALIGN_HORIZONTAL).

from_xrtAnchor(xrtANCHOR_NORTH,		16'10).
from_xrtAnchor(xrtANCHOR_SOUTH,		16'20).
from_xrtAnchor(xrtANCHOR_EAST,		16'01).
from_xrtAnchor(xrtANCHOR_WEST,		16'02).
from_xrtAnchor(xrtANCHOR_NORTHEAST,	16'11).
from_xrtAnchor(xrtANCHOR_NORTHWEST,	16'12).
from_xrtAnchor(xrtANCHOR_SOUTHEAST,	16'21).
from_xrtAnchor(xrtANCHOR_SOUTHWEST,	16'22).
from_xrtAnchor(xrtANCHOR_HOME,		16'00).
from_xrtAnchor(xrtANCHOR_BEST,		16'100).

to_xrtAnchor(16'10,  xrtANCHOR_NORTH).
to_xrtAnchor(16'20,  xrtANCHOR_SOUTH).
to_xrtAnchor(16'01,  xrtANCHOR_EAST).
to_xrtAnchor(16'02,  xrtANCHOR_WEST).
to_xrtAnchor(16'11,  xrtANCHOR_NORTHEAST).
to_xrtAnchor(16'12,  xrtANCHOR_NORTHWEST).
to_xrtAnchor(16'21,  xrtANCHOR_SOUTHEAST).
to_xrtAnchor(16'22,  xrtANCHOR_SOUTHWEST).
to_xrtAnchor(16'00,  xrtANCHOR_HOME).
to_xrtAnchor(16'100, xrtANCHOR_BEST).

from_xrtBorder(xrtBORDER_NONE,		0).
from_xrtBorder(xrtBORDER_3D_OUT,	1).
from_xrtBorder(xrtBORDER_3D_IN,		2).
from_xrtBorder(xrtBORDER_SHADOW,	3).
from_xrtBorder(xrtBORDER_PLAIN,		4).

to_xrtBorder(0, xrtBORDER_NONE).
to_xrtBorder(1, xrtBORDER_3D_OUT).
to_xrtBorder(2, xrtBORDER_3D_IN).
to_xrtBorder(3, xrtBORDER_SHADOW).
to_xrtBorder(4, xrtBORDER_PLAIN).

from_xrtPieOrder(xrtPIEORDER_ASCENDING,	1).
from_xrtPieOrder(xrtPIEORDER_DESCENDING,2).
from_xrtPieOrder(xrtPIEORDER_DATA_ORDER,3).

to_xrtPieOrder(1, xrtPIEORDER_ASCENDING).
to_xrtPieOrder(2, xrtPIEORDER_DESCENDING).
to_xrtPieOrder(3, xrtPIEORDER_DATA_ORDER).

from_xrtPieThresholdMethod(xrtPIE_SLICE_CUTOFF,	1).
from_xrtPieThresholdMethod(xrtPIE_PERCENTILE,	2).

to_xrtPieThresholdMethod(1, xrtPIE_SLICE_CUTOFF).
to_xrtPieThresholdMethod(2, xrtPIE_PERCENTILE).

from_xrtRotate(xrtROTATE_NONE,	1).
from_xrtRotate(xrtROTATE_90,	2).
from_xrtRotate(xrtROTATE_270,	3).

to_xrtRotate(1, xrtROTATE_NONE).
to_xrtRotate(2, xrtROTATE_90).
to_xrtRotate(3, xrtROTATE_270).

from_xrtTimeUnit(xrtTMUNIT_SECONDS,	1).
from_xrtTimeUnit(xrtTMUNIT_MINUTES,	2).
from_xrtTimeUnit(xrtTMUNIT_HOURS,	3).
from_xrtTimeUnit(xrtTMUNIT_DAYS,	4).
from_xrtTimeUnit(xrtTMUNIT_WEEKS,	5).
from_xrtTimeUnit(xrtTMUNIT_MONTHS,	6).
from_xrtTimeUnit(xrtTMUNIT_YEARS,	7).

to_xrtTimeUnit(1, xrtTMUNIT_SECONDS).
to_xrtTimeUnit(2, xrtTMUNIT_MINUTES).
to_xrtTimeUnit(3, xrtTMUNIT_HOURS).
to_xrtTimeUnit(4, xrtTMUNIT_DAYS).
to_xrtTimeUnit(5, xrtTMUNIT_WEEKS).
to_xrtTimeUnit(6, xrtTMUNIT_MONTHS).
to_xrtTimeUnit(7, xrtTMUNIT_YEARS).

from_xrtType(xrtTYPE_PLOT,	1).
from_xrtType(xrtTYPE_BAR,	2).
from_xrtType(xrtTYPE_PIE,	3).
from_xrtType(xrtTYPE_STACKING_BAR, 4).
from_xrtType(xrtTYPE_AREA,	5).

to_xrtType(1, xrtTYPE_PLOT).
to_xrtType(2, xrtTYPE_BAR).
to_xrtType(3, xrtTYPE_PIE).
to_xrtType(4, xrtTYPE_STACKING_BAR).
to_xrtType(5, xrtTYPE_AREA).

from_xrtXMethod(xrtXMETHOD_XVALUES,	0).
from_xrtXMethod(xrtXMETHOD_POINT_LABELS,1).
from_xrtXMethod(xrtXMETHOD_XLABELS,	2).
from_xrtXMethod(xrtXMETHOD_TIME_LABELS,	3).

to_xrtXMethod(0, xrtXMETHOD_XVALUES).
to_xrtXMethod(1, xrtXMETHOD_POINT_LABELS).
to_xrtXMethod(2, xrtXMETHOD_XLABELS).
to_xrtXMethod(3, xrtXMETHOD_TIME_LABELS).

%  the following are only used by the functions below
from_xrtDataType(xrtDATA_ARRAY,		1).
from_xrtDataType(xrtDATA_GENERAL,	2).

from_xrtFillPattern(xrtFPAT_NONE,	   1).
from_xrtFillPattern(xrtFPAT_SOLID,	   2).
from_xrtFillPattern(xrtFPAT_25_PERCENT,	   3).
from_xrtFillPattern(xrtFPAT_50_PERCENT,	   4).
from_xrtFillPattern(xrtFPAT_75_PERCENT,	   5).
from_xrtFillPattern(xrtFPAT_HORIZ_STRIPE,  6).
from_xrtFillPattern(xrtFPAT_VERT_STRIPE,   7).
from_xrtFillPattern(xrtFPAT_45_STRIPE,	   8).
from_xrtFillPattern(xrtFPAT_135_STRIPE,	   9).
from_xrtFillPattern(xrtFPAT_DIAG_HATCHED,  10).
from_xrtFillPattern(xrtFPAT_CROSS_HATCHED, 11).

from_xrtLinePattern(xrtLPAT_NONE,	1).
from_xrtLinePattern(xrtLPAT_SOLID,	2).
from_xrtLinePattern(xrtLPAT_LONG_DASH,	3).
from_xrtLinePattern(xrtLPAT_DOTTED,	4).
from_xrtLinePattern(xrtLPAT_SHORT_DASH,	5).
from_xrtLinePattern(xrtLPAT_LSL_DASH,	6).
from_xrtLinePattern(xrtLPAT_DASH_DOT,	7).

from_xrtPoint(xrtPOINT_NONE,		1).
from_xrtPoint(xrtPOINT_DOT,		2).
from_xrtPoint(xrtPOINT_BOX,		3).
from_xrtPoint(xrtPOINT_TRI,		4).
from_xrtPoint(xrtPOINT_DIAMOND,		5).
from_xrtPoint(xrtPOINT_STAR,		6).
from_xrtPoint(xrtPOINT_VERT_LINE,	7).
from_xrtPoint(xrtPOINT_HORIZ_LINE,	8).
from_xrtPoint(xrtPOINT_CROSS,		9).
from_xrtPoint(xrtPOINT_CIRCLE,		10).
from_xrtPoint(xrtPOINT_SQUARE,		11).

%
%  FUNCTIONS
%

%  this is a minimal set of xrt functions

xrtMakeData(DataStyle, Nsets, Npoints, Bool, Data) :-
	from_xrtDataType(DataStyle, DS),
	boolean(Bool, B),
	xrt_make_data(DS, Nsets, Npoints, B, Data).

xrtMakeDataFromFile(Filename, Data) :-
	xrt_make_data_from_file(Filename, 0, Data),
	\+ null_foreign_term(Data, _).

xrtDestroyData(Data, Bool) :-
	boolean(Bool, B),
	xrt_destroy_data(Data, B).

%
% Often a toolkit provides a convenience function which we simply interface to
% to allocate and fill data structures, (e.g. xrtMakeDataFromFile for xrtData)
% but none exist for xrtDataStyle and xrtXLabel data types, so we provide
% the following predicates to generate (pointers to) xrtDataStyle and xrtXLabel
% structures.
%
% The terms returned by these predicates can be used as elements in a list
% for resources that take arrays of pointers to these data structures, e.g.
%	proxrtMakeXLabel(1.0, one, A),
%	proxrtMakeXLabel(2.0, two, B),
%	proxrtMakeXLabel(6.0, six, C),
%	xtSetValues(Widget, [xtNxrtXLabels([A,B,C])]),
%	...
%
proxrtMakeDataStyle(Lpat, Fpat, Color, Width, Point, PColor, PSize, Style) :-
	from_xrtLinePattern(Lpat, L),
	from_xrtFillPattern(Fpat, F),
	resources:from_representation_type(xmRString, Color, CS),
	from_xrtPoint(Point, P),
	resources:from_representation_type(xmRString, PColor, PCS),
	new(xrtdatastyle, Style),
	put_contents(Style, lpat, L),
	put_contents(Style, fpat, F),
	put_contents(Style, color, CS),
	put_contents(Style, width, Width),
	put_contents(Style, point, P),
	put_contents(Style, pcolor, PCS),
	put_contents(Style, psize, PSize).

proxrtMakeXLabel(Float, String, XLabel) :-
	resources:from_representation_type(xmRString, String, S),
	new(xrtxlabel, XLabel),
	put_contents(XLabel, xvalue, Float),
	put_contents(XLabel, string, S).


boolean(true, 1).
boolean(false, 0).


%
%  FOREIGN TYPE DECLARATIONS
%

:- foreign_type
	xrtdata			= opaque,
	xrtdatastyle		= struct([
					lpat:	integer,
					fpat:	integer,
					color:	pointer(char_ptr),
					width:	integer,
					point:	integer,
					pcolor:	pointer(char_ptr),
					psize:	integer
				  ]),
	xrtxlabel		= struct([
					xvalue:	float,
					string:	pointer(char_ptr)
				  ]),
	xrtCallbackStruct	= struct([
					reason:	integer,
					event_ptr: pointer(xtevent),
					window:	'Window'
				  ]).

% xrt representation types
:- foreign_type
	xtRxrtAdjust		= integer,
	xtRxrtAlign		= integer,
	xtRxrtAnchor		= integer,
	xtRxrtBorder		= integer,
	xtRxrtData		= pointer(xrtdata),
	xtRxrtDataStyle		= pointer(xrtdatastyle),
	xtRxrtFloat		= long,			% actually XtArgVal
	xtRxrtPieOrder		= integer,
	xtRxrtPieThresholdMethod= integer,
	xtRxrtRotate		= integer,
	xtRxrtTimeUnit		= integer,
	xtRxrtType		= integer,
	xtRxrtXLabel		= pointer(xrtxlabel),
	xtRxrtXMethod		= integer.

%
% array types - the element type must a representation type as
% 		array<->list conversions use the from/to_representation_type
%		predicates to convert the array elements from/to user values.
%
:- foreign_type
	xtRxrtDataStyles	= array(xtRxrtDataStyle),
	xtRxrtStrings		= array(xmRString),
	xtRxrtXLabels		= array(xtRxrtXLabel).


%
%  FOREIGN INTERFACE
%
foreign('XrtFloatToArgVal', c, xrtFloatToArgVal(+double, [-integer])).
foreign('XrtArgValToFloat', c, xrtArgValToFloat(+integer, [-single])).
foreign('XrtMakeData', c,
	xrt_make_data(+integer,+integer,+integer,+integer,[-pointer(xrtdata)])).
foreign('XrtMakeDataFromFile', c,
	xrt_make_data_from_file(+string, +address, [-pointer(xrtdata)])).
foreign('XrtDestroyData', c, xrt_destroy_data(+pointer(xrtdata), +integer)).
foreign(xrt_get_widget_class_addr, c,
	xrt_get_widget_class_addr([-pointer(widget_class)])).

foreign_file(system(proxrt), [
	'XrtFloatToArgVal',
	'XrtArgValToFloat',
	'XrtMakeData',
	'XrtMakeDataFromFile',
	'XrtDestroyData',
	xrt_get_widget_class_addr
]).

:- load_foreign_files(system(proxrt), ['-lxrtm -lXm -lXt -lX11 -lm']).
