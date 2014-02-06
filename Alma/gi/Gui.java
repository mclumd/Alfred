
import java.applet.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;



/**
 * A GUI for a running alma process or for alma history files.
 * The state of the alma kb is kept track of through the history output. 
 * There is also a connection to the stdio of alma through which all the
 * usual alma commands can be executed
 * <br>
 * There are three main windows: the KB display window, the alma control
 * window and the IO window. See details for these elsewhere.
 * <br>
 * There are two main modes of operation: as an interface to a running 
 * alma process or as a history reader. In the latter case only the KB 
 * display window is produced. Also, in the latter case, the applet is
 * viewable using netscape whereas in the former case, the applet will
 * run with the appletviewer.
 * <br>
 * Arguments: <br>
 * <ul>
 * <li>
 * almaArgs. The value of this should be the string that is to be used to
 * exec alma. The default is: "alma run false keyboard true histocket htcp 
 * prompt false". If you decide to change that, make sure that the histocket,
 * prompt, and keyboard values are as in the default.
 * <li>
 * autoExec. The value is true or false. The default is false. If it is true,
 * alma will be execed on start-up, otherwise it will be execed when the
 * 'Exec' button is clicked. 
 * <li>
 * historyFromFile. Value true or false. If true, the GUI will run in 
 * hostory reader mode. Default is false. The history file can be specified
 * in the GUI or through the next parameter.
 * <li>
 * historyInputURLName. The value of that is the URL for the history file
 * that is to be read. There is no default.
 * <li>
 * verbose. Value is true or false. Default is false. 
 * </ul>
 * @author K. Purang
 * @version October 2000
 */


public class Gui extends Applet implements AbGui {

    GuiCommon gC;


    /**
     * Here we start a history reader and if there is a need for it, an
     * io interface and a control interface to some alma process.
     */

    public void init() {

	gC = new GuiCommon(this);

	gC.alma = null;
	processArgs();
    
        this.setLayout(new GridBagLayout());
	Globals.theGui = this;

	//--------------------------------------------------
	// the history panel 

	//__________________________________________________
	// start the database
	
	gC.theDb = new Db(gC.historyFromFile, gC.historyInputURLName);
	gC.historyPanel = gC.theDb.getHistoryPanel();

        GridBagConstraints hpCon = new GridBagConstraints();	
	hpCon.gridy = GridBagConstraints.RELATIVE;
	hpCon.gridx = 0;
	hpCon.fill = GridBagConstraints.HORIZONTAL;
	this.add(gC.historyPanel, hpCon);

	gC.theDb.start();

	// return here if we are only doing a history file input
	if(gC.historyFromFile){
	    validate();
	    return;
	}
	//--------------------------------------------------
	// the control panel

	gC.theRunParms = new RunParms();
	gC.almaStepper = new RunAlma(gC.theRunParms);
	gC.almaStepper.start();

	Panel almaControl = new Panel(new GridBagLayout());
	almaControl.setBackground(ColorsFonts.controlPanelBackground);
	almaControl.setForeground(ColorsFonts.controlPanelForeground);
	gC.makeControlPanel(almaControl);

	GridBagConstraints aCCon = new GridBagConstraints();
	aCCon.gridx = 0;
	aCCon.gridy = GridBagConstraints.RELATIVE;
	aCCon.fill = GridBagConstraints.HORIZONTAL;
	this.add(almaControl, aCCon);

	//--------------------------------------------------
	// the io panel

	Panel toAlma = new Panel(new GridBagLayout());
	toAlma.setBackground(ColorsFonts.ioPanelBackground);
	gC.makeIOPanel(toAlma);

        GridBagConstraints tACon = new GridBagConstraints();	
	tACon.gridy = GridBagConstraints.RELATIVE;
	tACon.gridx = 0;
	this.add(toAlma, tACon);

	//--------------------------------------------------

        validate();
	
	//__________________________________________________
	// start alma if need be

	if(gC.autoStart) gC.startAlma();

    } // init()



    void processArgs(){
	// Name: almaArgs value: the command to be execed to start
	// alma.  
	// default is: alma run false keyboard true history h
	// histocket htcp prompt false The user had better know what
	// he is doing to modify this
	//
	// Name: autoExec value: true or false. 
	// if true will automatically start alma using the
	// almaargs. this may or may not cause alma to run. if false,
	// need to click on [start] to get the alma started
	//
	// Name: historyInputURLName value: a file name
	// if this is set, the heistory will be read from the file and
	// the control panel and the io panel will not be visible.
	// 
	// Name historyFromFile value: true or false
	// if this is true and the above is not available, then the
	// file name will be read from the kbd.
	//
	// Name verbose value: true or false
	//__________________________________________________
	// almaArgs

	String args = getParameter("almaArgs");
	if(args == null)
	    gC.almaExec = new String("alma run false keyboard true history h histocket htcp prompt false");
	else
	    gC.almaExec = args;

	//__________________________________________________
	// autoStart

	String start = getParameter("autoExec");
	gC.autoStart = false;
	if(start != null)
	    if(start.compareTo("true") == 0) gC.autoStart = true;

	//__________________________________________________
	// 
	gC.historyInputURLName = getParameter("historyInputURLName");
	if(gC.historyInputURLName != null) gC.historyFromFile = true;
	else gC.historyFromFile = false;
	//__________________________________________________
	//
	String trueString = "true";
	String hFF = getParameter("historyFromFile");
	if(hFF != null){
	    if(trueString.compareTo(hFF) == 0){
		gC.historyFromFile = true;
	    }
	    else
		gC.historyFromFile = false;
	} // hff != null
	//__________________________________________________
	// 
	String verboseString;
	verboseString = getParameter("verbose");
	if(verboseString != null && trueString.compareTo(verboseString) == 0) 
	    Globals.verbose = true;
	else Globals.verbose = false;
	//__________________________________________________

    } // process args

} // class
