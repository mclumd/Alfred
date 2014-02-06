
import java.applet.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;



/**
 * This is the new java application version.
 *
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


public class GuiApp extends Frame implements AbGui{

    GuiCommon gC;
    Frame statusFrame;
    TextArea statusTextArea;
    int ERROR_ROWS = 10;
    int ERROR_COLUMNS = 50;

    /**
     * Here we start a history reader and if there is a need for it, an
     * io interface and a control interface to some alma process.
     */

    public GuiApp(String args[]) {

	this.setResizable(true);
	gC = new GuiCommon(this);
	gC.alma = null;
	processArgs(args);
    
        this.setLayout(new GridBagLayout());
	Globals.theGui = this;
	makeStatusWindow();

	//--------------------------------------------------
	// the history panel 

	//__________________________________________________
	// start the database
	
	gC.theDb = new Db(gC.historyFromFile, gC.historyInputURLName);
	gC.historyPanel = gC.theDb.getHistoryPanel();

        GridBagConstraints hpCon = new GridBagConstraints();	
	hpCon.gridy = GridBagConstraints.RELATIVE;
	hpCon.gridx = 0;
	hpCon.weightx = 1.0;
	hpCon.gridwidth = GridBagConstraints.REMAINDER;
	hpCon.fill = GridBagConstraints.HORIZONTAL;
	this.add(gC.historyPanel, hpCon);

	if(Globals.verbose)
	    showStatus("Started database...");

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

	if(Globals.verbose)
	    showStatus("Done control panel...");


	//--------------------------------------------------
	// the io panel

	Panel toAlma = new Panel(new GridBagLayout());
	toAlma.setBackground(ColorsFonts.ioPanelBackground);
	gC.makeIOPanel(toAlma);

        GridBagConstraints tACon = new GridBagConstraints();	
	tACon.gridy = GridBagConstraints.RELATIVE;
	tACon.gridx = 0;
	tACon.weightx = 1.0;
	tACon.weighty = 1.0;
	tACon.gridwidth = GridBagConstraints.REMAINDER;
	tACon.gridheight = GridBagConstraints.REMAINDER;
	tACon.fill = GridBagConstraints.BOTH;

	this.add(toAlma, tACon);

	if(Globals.verbose)
	    showStatus("Done IO panel...");


	//--------------------------------------------------

        validate();
	
	//__________________________________________________
	// start alma if need be

	if(gC.autoStart) gC.startAlma();

	if(Globals.verbose)
	    showStatus("Started Alma...");

	this.pack();
	this.show();

    } // init()


    //**************************************************

    void processArgs(String args[]){
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

	//Default Values
	
	gC.almaExec = new String("alma run false keyboard true history h histocket htcp prompt false");
	gC.autoStart = false;
	gC.historyFromFile = false;
	Globals.verbose = false;
	if(args.length == 0) return;

	int index = 0;
	while(index < args.length){

	    String argName = args[index];

	    // almaArgs
	    if(argName.compareTo("almaArgs") == 0){
		gC.almaExec = args[index + 1];
		index = index + 2;
		continue;
	    } // almaArgs

	    // autoExec
	    if(argName.compareTo("autoExec") == 0){
		if(args[index + 1].compareTo("true")==0) gC.autoStart = true;
		index = index + 2;
		continue;
	    } // almaArgs

	    // historyInputURLName
	    if(argName.compareTo("historyInputUrlName") == 0){
		gC.historyFromFile = true;
		gC.historyInputURLName = args[index + 1];
		index = index + 2;
		continue;
	    } // almaArgs

	    // historyFromFile
	    if(argName.compareTo("historyFromFile") == 0){
		if(args[index + 1].compareTo("true") == 0)
		    gC.historyFromFile = true;
		index = index + 2;
		continue;
	    } // almaArgs

	    // verbose
	    if(argName.compareTo("verbose") == 0){
		if(args[index + 1].compareTo("true") == 0)
		    Globals.verbose = true;
		index = index + 2;
		continue;
	    }
	    
	    // no match, skip the input
	    showStatus("Argument " + argName + " is unknown. Ignored");
	    index = index + 1;
	} // while

    } // process args


    public void makeStatusWindow(){

	statusFrame = new Frame("Errors");
	statusTextArea = new TextArea("Errors", ERROR_ROWS, ERROR_COLUMNS);
	statusTextArea.setEditable(false);
	statusTextArea.setBackground(ColorsFonts.statusTextAreaBg);
	statusTextArea.setForeground(ColorsFonts.statusTextAreaFg);
	statusFrame.add(statusTextArea);
	statusFrame.pack();
	statusFrame.show();
    }

    // these two are dummy methods
    
    public void showStatus(String s){
	System.err.println(s);
	System.err.flush();
	
	statusTextArea.append(s + "\n");
    }

    public String getParameter(String s){
	return s;
    }


} // class
