%  SCCS   : @(#)color_chooser.pl	20.2 09/29/94
%  File   : color_chooser.pl
%  Author : Georges Saab
%  Purpose: Class definitions for color_chooser
%  Origin : 8 Apr 1993
%
%			Abstract
%
% An application area that lends itself very naturally to using object-oriented 
% style is the graphical user interface (GUI).  This example builds the GUI for
% an application which allows us to change its color scheme by popping 
% up a color chooser.  In order to create and manipulate the interface this 
% example uses 'ProXT', an interface to OSF Motif and the X toolkit 
% (Xt). \footnote{For a detailed description of 'ProXT', please see the 
% Quintus Prolog reference manual, section XT}

/***************************************************************************

			Color Chooser

The color chooser is a non-modal dialog which has a frame displaying the 
currently selected color, three sliders which control the 
Red, Green, and Blue amounts in the selected color, and an OK button 
which allows us to accept the currently selected color.  Accepting the 
currently selected color in the color chooser should set the background 
of the application to that color.

Already from this description we can see that there are several pieces of
GUI that we will need to create, and several pieces of control.  There
appear to be places where we will be able to reuse components within the
application, most notably the three sliders, and possibly the 
color chooser unit itself, if we choose to allow multiple color choosers 
to come up at once.

We start by choosing the classes that we will need for the 
'color_chooser'. We know that we need three sliders to control 
the Red, Green, and Blue settings.  So we probably want to have a 
'slider' class, and we can make each of these sliders an instance 
of that class.  Through 'ProXT' we have access to the Motif Scale widget, 
so we only need to encapsulate the functionality that the 'XmScale' widget 
offers to have the 'slider' class.  

The next thing we need is a box which will display the current color.
Once again, we can use a Motif widget accessible through 'ProXT': the 
'XmFrame' widget. The final thing that we we will need for the 
basic 'color_chooser' is some kind of container which will hold 
the sliders and the frame.  The 'XmRowColumn' widget 
is a good candidate for this, because it will display the 
sliders and frame in an attractive manner while requiring a 
minimal amount of layout work on our part.  

Since we will now be creating at least three types of Motif widgets, 
and the interface for creating and manipulating these is very similar, 
we can start to abstract a bit, by adding the class 'graphical_object',
which will define the behavior for classes which are wrappers around 
Motif classes.  The basic operations that we need for 'graphical_objects'
are 'create', 'destroy', 'add_callback', and 'set_color',
and get and put methods for 'managed'.

****************************************************************************/

:- module(color_classes, []).

/** 
Include 'ProXT', an interface to Motif which will allow us to
create and manipulate Motif widgets from Prolog.  
**/

:- use_module(library(proxt)).

/**
Include the standard 'objects' files. 
**/

:- load_files(library(obj_decl), [when(compile_time), if(changed)]).
:- use_module(library(objects)).

/**
Include the file 'color.pl', which provides a Prolog interface 
to the C routine 'get_color/5'.  We will use this to add color
map entries as new colors are created.
**/

:- use_module(color, [get_color/5]).

/**
	The graphical_object Class
This is the root of the hierarchy of
graphical objects.  In its most basic form, this class will act as a 
wrapper around a 'ProXT' widget, handling creation, management, 
and destruction. Note that this is an abstract class, which is not 
intended to be instanced directly, and therefore it has no
'<- create' method of any arity. In order to be instanceable, 
subclasses must define a '<- create'/3 method, which will usually
send a '<- create_graphical_object'/4 message to itself to create
the widget and store it in the object.
There is one slot for this class, which is intended to store the widget 
that corresponds to the class instance.
**/

:- class graphical_object = [public widget:pointer(widget)].

%   <-create_graphical_object(+WidgetClass, +Parent, +Name, +Attribs)
%        Create the instance by calling the ProXT predicate xtCreateWidget/5.
% The list of widget attributes 'Attribs', is passed through to the 
% 'xtCreateWidget'/5 call.  Note that by default the widget is not managed.

Self <- create_graphical_object(WidgetClass, Parent, Name, Attribs) :-
        Parent >> widget(ParentWidget),
        xtCreateWidget(Name, WidgetClass, ParentWidget, Attribs, Widget),
        Self << widget(Widget).
/**
Define the put method for 'managed' to manage or unmanage the widget.
This makes it visible in its parent widget.
**/
%   << manage(+Bool)
%        Manages the instance widget. This makes it 'visible' in its Parent.

Self << managed(Bool) :-
        Self >> widget(Widget),
	( Bool == true ->
          xtManageChild(Widget)
	; Bool == false ->
	  xtUnmanageChild(Widget)
	; raise_exception(value_not_a_boolean(Bool))
	).
/**
Define the get method for 'managed' to succeed if it can unify 
'Bool' with the current management state of the widget.
**/
%   >>manage(?Bool)
%        Bool is true if the widget is managed, false if it is unmanaged.

Self << managed(Bool) :-
        Self >> widget(Widget),
	(xtIsManaged(Widget) ->
		Bool = true
	; Bool = false).

% In QP3.1x, xtIsManaged took a 2nd boolean argument and would have been
% called as
%
% 	xtIsManaged(Widget, Bool).
%
% replacing the ( -> ; ) expression.

/**
Add a method for adding callbacks to the widget.
**/
%   <-add_callback(+Callback, +Functor, +DestObject)
%        Sets a callback on the instance widget.  Functor is name of the 
% Prolog predicate (of arity 3) that will be called when a callback occurs.
% DestObject is the object to which a message should be sent saying that
% the callback has occurred.  By convention, the callback predicate sends
% the message Functor to DestObject.  DestObject is passed to Functor in 
% the client data slot (the second argument of the ProXT callback predicate).

Self <- add_callback(Callback, Functor, DestObject) :-
        Self >> widget(Widget),
        xtAddCallback(Widget, Callback, Functor, DestObject).

/**
Add a put method setting the widget's foreground and background color.  This
demonstrates using a put method which has more than one argument.
**/
%   << color(+FG, +BG)
%        Sets the foreground and background color of the instance widget to
% FG and BG.

Self << color(FG,BG) :-
        Self >> widget(Box),
        xtSetValues(Box, [xmNbackground(BG),
                          xmNforeground(FG)]).
/**
In a more general 'color_chooser' class, we would probably define
a '>> color' method as well, but in this example it is not
needed.

Define a method for cleaning up when the instance is destroyed using 
'destroy/1' from the 'objects' package. For 'graphical_object', this 
method destroys the instance widget.
**/
%   <-destroy
%         Destroys the instance widget.

Self <- destroy :-
        Self >> widget(Widget),
        xtDestroyWidget(Widget).

:- end_class.

/**
With this as a start, it is very simple for us to define the three 
subclasses of 'graphical_object' 'slider, 'frame', and 
'row_column').  We will inherit all of the methods from 
'graphical_object', and define a '<-create' method so that the 
class is instanceable.  The 'slider' class will also have 
additional methods added for getting the value of the 'slider'
**/

/**
	The frame Class
This subclass of 'graphical_object' encapsulates the 'XmFrame' widget class.
**/
:- class frame = graphical_object.

%   <-create(+Parent, +Name, +Attribs)
%        Create the graphical object using xmFrameWidgetClass as 
%        the widget class

Self <- create(Parent, Name, Attribs) :-
	Self <- create_graphical_object(xmFrameWidgetClass,
	                                Parent, Name, Attribs).

:- end_class.

/**
	The row_column Class
This subclass of 'graphical_object' encapsulates the 'XmRowColumn' widget class.
**/

:- class row_column = graphical_object.

%   <-create(+Parent, +Name, +Attribs)
%        Create the graphical object using xmRowColumnWidgetClass as 
%        the widget class

Self <- create(Parent, Name, Attribs) :-
	Self <- create_graphical_object(xmRowColumnWidgetClass,
	                                Parent, Name, Attribs).

:- end_class.

/**
	The slider Class
This is a sublcass of 'graphical_object' which 
encapsulates the 'XmScale' widget class.  In addition to the methods
inherited from 'graphical_object', this subclass adds the get method
'value/1', which returns the current integer value of the scale.
**/
:- class slider = graphical_object.

%   <-create(+Parent, +Name, +Attribs)
%        Create the graphical object using xmScaleWidgetClass as 
%        the widget class

Self <- create(Parent, Name, Attribs) :-
	Self <- create_graphical_object(xmScaleWidgetClass,
	                                Parent, Name, Attribs).

%   >> value(Value)
%        Unify Value with the slider value of the instance widget.

Self >> value(Value) :-
	Self >> widget(Widget),
	xmScaleGetValue(Widget, Value).
/**
	The color_chooser Class
This class defines the 'color_chooser', a 
complex class which contains three 'slider's and a 'frame' 
contained in a 'row_column'.  The behavior is that as the 
'slider's change, the color of the 'frame' is modified 
according to the new values of the 'slider's.
In the class definition we define the slots storing internal instances as 
private.  The color chooser should be accessed as a black box.  No messages 
should be send directly to internal instances.
**/

:- class color_chooser = row_column + [
                                       protected red_slider:slider,
                                       protected green_slider:slider,
                                       protected blue_slider:slider,
                                       protected colorbox:frame
                                      ].


/**
Create the 'color_chooser' by 'sending super' to create the
'row_column', and then creating the 'slider' and 'frame' 
instances.  Store the instances in the appropriate slot.
**/

%   <-create(+Parent)
%        Creates the color_chooser instance as a child of the instance 
% Parent.  The color_chooser consists of a row_column which contains
% three sliders (red, green, and blue), and a frame which changes color
% as the sliders are changed.

Self <- create(Parent) :-
        Self <- create(Parent, color_chooser, [xmNorientation(xmHORIZONTAL)]),
   % Create and store the slider instances:
        create(slider(Self, red, []), Red),
        store_slot(red_slider,Red),
        create(slider(Self, green, []), Green),
        store_slot(green_slider,Green),
        create(slider(Self, blue, []), Blue),
        store_slot(blue_slider,Blue),
   % Create and store the frame instance:
        create(frame(Self, colorbox, [xmNwidth(200),
                                             xmNheight(200)]), Colorbox),
        store_slot(colorbox,Colorbox),
   % Add value changed callbacks to the sliders so that we will be sent 
   % the message slider_changed/0 if the user moves one of the sliders.
        Red   <- add_callback(xmNvalueChangedCallback, slider_changed, Self),
        Green <- add_callback(xmNvalueChangedCallback, slider_changed, Self),
        Blue  <- add_callback(xmNvalueChangedCallback, slider_changed, Self),
   % Add drag callbacks to the sliders so that we will be sent 
   % the message <-slider_changed as the user drags the slider.
        Red   <- add_callback(xmNdragCallback, slider_changed, Self),
        Green <- add_callback(xmNdragCallback, slider_changed, Self),
        Blue  <- add_callback(xmNdragCallback, slider_changed, Self),
   % Manage the components of the color_chooser
        Red      << managed(true),
        Green    << managed(true),
        Blue     << managed(true),
        Colorbox << managed(true),
        Self     << managed(true),
   % Send the callback message to set the Frame to the appropriate color
        Self  <- slider_changed.

/**
Define what to do when one of the sliders changes.
**/

%   <-slider_changed
%        When the slider changes, we should get the color as calculated 
% from the slider values by the >>color method, and then set the internal
% colorbox to display that color:

Self <- slider_changed :-
        Self >> color(FG, BG),
        fetch_slot(colorbox,Colorbox),
        Colorbox << color(FG,BG).

/**
>> color(-FG,-BG)  returns the foreground(FG) and background(BG)
colors indicated by the present settings of the Red, Green, and 
Blue sliders. The background color is calculated by calling the 
foreign routine 'get_color/5', 
and the foreground is calculated based on the background color using 
simple the heuristic "If the background color is greater than half its 
maximum value, the Foreground is the 'minimum value', and if the background 
is less than half its maximum value then the foreground is the maximum value".
Note that the Foreground is also computed using 'get_color/5'. 
It is not possible to use the color returned by 'get_color/5' 
for comparison since it is merely a colormap entry. Its value says nothing 
about how light or dark the color is.
**/

Self >> color(FG,BG) :-
        fetch_slot(red_slider,Red),
        fetch_slot(green_slider,Green),
        fetch_slot(blue_slider,Blue),
   % Get slider values:
        Red   >> value(R),
        Green >> value(G),
        Blue  >> value(B),
   % Get or allocate the color in the Colormap:
        fetch_slot(widget, W),
        get_color(W, R,G,B, BG),
   % Determine the Foreground color by simple heuristic:
        Total is R + G + B,
        ( Total > 150 ->
          get_color(W,0,0,0,FG)
        ; get_color(W,100,100,100,FG)
        ).

:- end_class.

/**
	The toplevel Class
In order to use 'ProXT' to create the interface, 
the application will have to do a little bit of work to initialize the 
Motif toolkit.  For convenience and consistency, we will also wrap this 
in a class.  While it would be possible to make this a subclass of 
'graphical_object', the messages that it needs to be able to accept 
are different enough that this should stand on its own as a class.

Once again, the 'widget' slot will store the widget create by 'ProXT'.
**/

:- class toplevel = [public widget:pointer(widget)].

%   <-create
%        Create the toplevel XT widget by calling xtInitialize/3 and then
% storing the widget returned in the widget slot.

Self <- create :-
        xtInitialize(demo, color, Top),
        Self << widget(Top).

%   <-realize
%        Realize the toplevel XT widget by looking up the widget from 
% the widget slot and then calling xtRealizeWidget/1.

Self <- realize :-
        Self >> widget(Widget),
        xtRealizeWidget(Widget).

%   <-mainloop
%         Start the main event processing loop of the application by 
% calling xtMainLoop/0.  This is wrapped in an exception handler which
% recursively sends the message <-mainloop to the toplevel instance.

Self <- mainloop :-
        on_exception(_E, xtMainLoop, (Self <- mainloop)).

:- end_class.
/**

As mentioned earlier, it is necessary to have 'ProXT' callback predicates
defined which send a message to the (stored) Destination instance.  

This method has the disadvantage that because of the way that 'ProXT' 
expands meta predicates, all such callback stubs must be added in this module 
(the module making the actual 'xtAddCallbacks' call), rather than the 
module with the subclass calling '<-add_callback'. 

A closer integration of 'ProXT' and 'Classes' would provide a 
more seamless way of implementing callbacks as messages sent directly to 
the destination instance, but that is a task too involved for this example.

**/
slider_changed(_,Self,_) :-
        Self <- slider_changed.

button_pressed(_,Self,_) :-
        Self <- button_pressed.
/**

Now the basic 'color_chooser' is complete.  Loading 
'color_classes.pl' into Prolog, we can type:

++verbatim
| ?- use_module(library(objects)),
     create(toplevel, T),
     create(color_chooser(T), C),
     T <- realize,
     T <- mainloop.
--verbatim

A 'color_chooser' comes up in a Motif toplevel shell.   The 
'color_chooser' is internally consistent; when we move one of the 
'slider''s, the 'frame' changes color appropriately.  The 
'color_chooser' can be inserted into an application very easily, 
and can be used directly in a window such as a control panel, or put 
into a popup dialog as the programmer wishes.

Already several goals have been achieved.  Several useful classes have
been created, and more importantly, a model has been developed for 
building classes based on Motif widgets and 'ProXT' which can be easily 
extended to additional widgets with minimal work thanks to inheritance.
We have also found a way to call C code from our classes in a way which
comes naturally in Prolog using the foreign interface.

This first foray has demonstrated the use of inheritance to abstract 
the operations which were common among 'ProXT' widgets into the 
'graphical_object' class, providing a simple and consistent interface
to these objects.  

Even though we are starting to see some of the benefits of our approach, 
we still have more to do to complete the application!  The next task is 
to build a simple application that uses this 'color_chooser' to allow the
user to change its background color.  In order to keep things simple, the
application will be merely a window containing a pushbutton that pops up
the color chooser.  Since the basic color chooser includes no means of
accepting the color, we will add an OK button.

So the way we expect this application to be used is:
++enumerate
     o  App window created
     o  User presses button
     o  Color Chooser comes up
     o  User chooses color
     o  User Presses OK
     o  App button changes color
--enumerate
           
Steps 2-6 can be repeated, and it is not necessary for steps 4-5 to
be performed before step 2 is repeated (there can be multiple color
choosers up at once).

Now that we have an idea of what we want, we can look at the existing
pieces to see what can be reused.  The 'color_chooser' already does 
everything it should except that it doesn't come up in its own window 
and have an 'OK' button.  We can add these to the existing 
'color_chooser' by subclassing.

Clearly we will need a a pushbutton class (for the app button and the OK 
button) and a popup shell class (to put the 'color_chooser' in).  
Both of these will work well as subclasses of 'graphical_object'.

Finally, we might as well wrap the application in its own class, to make
creation and startup as simple as possible.
**/

/**
	The pushbutton Class
A subclass of 'graphical_object' which wraps the 'XmPushButton' widget class.
**/

:- class pushbutton = graphical_object.

%   <-create(+Parent, +Name, +Attribs)
%        Create the graphical object using xmPushButton as the widget class

Self <- create(Parent, Name, Attribs) :-
	Self <- create_graphical_object(xmPushButtonWidgetClass,
	                                Parent, Name, Attribs).

:- end_class.

/**
	The shell Class
Subclass of 'graphical_object' to wrap 'XmShell' classes.  
**/

:- class shell = graphical_object.

/** 
Note that this subclass replaces '<- create_graphical_object' with
its own creation method.  First we use the 'uninherit' directive to
prevent inheriting the '<-create_graphical_object/4' method.  Then we
define its replacement, '<-create_shell/4'.  
**/

%   <-create(+Parent, +Name, +Attribs)
%         Create the shell by sending the message <-create_shell/4 with
% the shell class toplevelShell.

Self <- create(Parent, Name, Attribs) :-
	Self <- create_shell(topLevelShellWidgetClass, Parent, Name, Attribs).

:- uninherit graphical_object<-create_graphical_object/4.

%   <- create_shell(+WidgetClass, +Parent, +Name, +Attribs)
%        Create the shell using xtCreatePopupShell/5.  Add a callback 
% to handle the Window Manager close operation. 

Self <- create_shell(ShellClass, Parent, Name, Attribs) :-
        Parent >> widget(ParentWidget),
        xtCreatePopupShell(Name, ShellClass, ParentWidget, Attribs, Widget),
        Self << widget(Widget),
        (   prolog_flag(version, '3.1') ->
                xtSetValues(Widget, [xmNdeleteResponse(2)]) % ProXT bug in 3.1
        ;   xtSetValues(Widget, [xmNdeleteResponse(xmDO_NOTHING)])
        ),
        xtDisplay(ParentWidget, Display),
        xmInternAtom(Display, 'WM_DELETE_WINDOW', false, Delete),
        xmAddWMProtocolCallback(Widget, Delete, wm_delete_window, Self).

%   <- wm_delete_window
%        By default this merely unmanages the shell (this can be overridden 
% in subclasses).

Self <- wm_delete_window :-
        Self << managed(false).

:- end_class.

/** 
	The popup_shell Class 
This subclass of shell wraps the Motif Shell class 'transientShell'.
Transient shells differ from toplevel shells in their client
decorations and in that they stay in front the parent shell, and
iconify along with the parent shell.  
**/

:- class popup_shell = shell.

%   <-create(+Parent, +Name, +Attribs)
%         Create the shell by sending the message <-create_shell/4 with
% the shell class transientShellWidgetClass

Self <- create(Parent, Name, Attribs) :-
	Self <- create_shell(transientShellWidgetClass, Parent, Name, Attribs).

:- end_class.

/**
	The popup_color_chooser Class
This subclass of 'color_chooser' lets the 'color_chooser' come up in its
own window.  The 'shell' slot stores the shell instance in which
the 'color_chooser' has been placed.
**/

:- class popup_color_chooser = color_chooser +[protected shell:shell].

/**
To create a 'popup_color_chooser', create a 'popup_shell' and send
super passing the 'popup_shell' instance as the parent.  Adds an OK
button, and set the button's callback to send the message
'button_pressed' to 'Self'.  Note that even though the slot type for
the 'shell' slot is ``shell'', we can store an instance of
'popup_shell' because 'objects' will allow us to store instances of
descendant classes in slots.  
**/ 

% <-create(+Parent) 
%   Creates the popup_color_chooser.

Self <- create(Parent) :-
        create(popup_shell(Parent,'Color Chooser', []), Shell),
        store_slot(shell,Shell),
        super  <- create(Shell),
        create(pushbutton(Self, 'OK', []), Button),
        Button <- add_callback(xmNactivateCallback, button_pressed, Self),
        Button << managed(true),
        Shell  << managed(true).

/**
By default, the 'popup_color_chooser' merely unmanages its shell when 
the OK button is pressed.
**/

Self <- button_pressed :-
        fetch_slot(shell,Shell),
        Shell << managed(false).

:- end_class.

/**
	The app Class
We define the application as a class.  This is a subclass of toplevel
so that we inherit all the creation and startup methods for the 'ProXT'
toplevel.  The application itself is simple -- just a pushbutton which 
creates a color chooser when pressed.
**/

:- class app = toplevel + [ protected pushbutton:pushbutton].

%  <-create
%     In order to create the application, we first send super to initialize
% ProXT from the <-create/0 method inherited from toplevel, and then create 
% a pushbutton.  We add a callback to the pushbutton to send us the message
% <-button_pressed when it is pressed.
        
Self <- create :-
        super <- create,
        create(pushbutton(Self, 'Press for Color Chooser', 
                                [xmNwidth(200), xmNheight(100)]), Button),
        store_slot(pushbutton, Button),
        Button <- add_callback(xmNactivateCallback, button_pressed, Self),
        Button << managed(true),
        Self   <- realize,
        Self   <- mainloop.

%   <-button_pressed
%        When the button is pressed, we simply create a new color_chooser.
        
Self <- button_pressed :-
        create(app_color_chooser(Self), _ColorChooser).

%   << color(FG, BG)
%        In order to set the color, we set the color of the pushbutton
% instance.
        
Self << color(FG,BG) :-
        fetch_slot(pushbutton, Button),
        Button << color(FG,BG).

:- end_class.

/**
	The app_color_chooser Class
This is the application specific class of 'color_chooser'. It is based 
off the more general 'popup_color_chooser' above, but this time it 
stores its parent in a slot, which it then uses when OK is pressed to 
send a message to its parent telling it to set the color calculated by
the 'color_chooser'.
**/

:- class app_color_chooser = popup_color_chooser + [protected parent:app].

%   <-create(+Parent)
%        First store the parent instance in the parent slot, then 
% send super to create the popup_color_chooser.

Self <- create(Parent) :-
        store_slot(parent,Parent),
        super <- create(Parent).

%   <-button_pressed
%        Override the popup_color_chooser's <-button_pressed method to
% look up the Parent and tell it to set its color to the color calculated
% by the color chooser's >>color/2 method.

Self <- button_pressed :-
        fetch_slot(parent,Parent),
        Self   >> color(FG, BG),
        Parent << color(FG, BG),
        super <- button_pressed.

:- end_class.

/**
As before, we define the callback procedure to send a message with the
same functor to the object stored in the client data slot (the second 
argument).
**/

wm_delete_window(_,Self,_) :-
        Self <- wm_delete_window.

/**
In order to begin the application, we merely create the instance of
class app.  It's creation method takes care of all the rest!
**/

user:runtime_entry(start) :-
        create(app, _C).

/**
This example shows how easy it is to begin writing object oriented 
programs in Prolog using the 'objects' package.  Writing in object oriented
style helped us make good decisions about how to divide responsibility
and encapsulate functionality in a way which led to more reusable code.
Writing in Prolog allowed us to take a high-level approach to the problem
at hand and resulted in fewer lines of code.  
**/
