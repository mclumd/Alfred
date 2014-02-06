
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

    //**************************************************
    //__________________________________________________
    // display variables

    public static TextArea tty;	// output from alma
    TextField ttyIn;		// input to alma
    Button addC;
    Button step;
    Button runAlma;
    Button stopAlma;
    Label delayLabel;
    TextField delayField;
    Button sdb;
    Db theDb;
    PopupMenu popUp;
    Button fileMenu;
    Label opLabel;
    Label ioLabel;
    Button resetAlma;
    Button startAlma;
    String historyInputURLName;
    boolean historyFromFile;

    Panel historyPanel;

    //__________________________________________________
    // process variables

    Process alma;
    InputStream almaInputStream;
    InputStream almaErrorStream;
    BufferedWriter almaWriter;
    OutputStream almaOutputStream;
    BufferedReader almaReader;
    BufferedReader almaErrorReader;
    InputStreamReader almaStreamReader;
    InputStreamReader almaErrorStreamReader;
    AlmaOut almaDisplay;
    AlmaOut almaError;
    String almaExec;

    RunParms theRunParms;
    RunAlma almaStepper;
    boolean verbose;

    //__________________________________________________
    // size parameters

    int ALMAHEIGHT = 5;
    int ALMAWIDTH = 50;
    int HISTORYHEIGHT = 35;
    int HISTORYWIDTH = 50;


    //__________________________________________________
    // control variables
    
    boolean autoStart = false;


    //**************************************************

    /**
     * Here we start a history reader and if there is a need for it, an
     * io interface and a control interface to some alma process.
     */

    public void init() {

	alma = null;
	processArgs();
    
        this.setLayout(new GridBagLayout());
	Globals.theGui = this;

	//--------------------------------------------------
	// the history panel 

	//__________________________________________________
	// start the database
	
	theDb = new Db(historyFromFile, historyInputURLName);
	historyPanel = theDb.getHistoryPanel();

        GridBagConstraints hpCon = new GridBagConstraints();	
	hpCon.gridy = GridBagConstraints.RELATIVE;
	hpCon.gridx = 0;
	hpCon.fill = GridBagConstraints.HORIZONTAL;
	this.add(historyPanel, hpCon);

	theDb.start();

	// return here if we are only doing a history file input
	if(historyFromFile){
	    validate();
	    return;
	}
	//--------------------------------------------------
	// the control panel

	theRunParms = new RunParms();
	almaStepper = new RunAlma(theRunParms);
	almaStepper.start();

	Panel almaControl = new Panel(new GridBagLayout());
	almaControl.setBackground(ColorsFonts.controlPanelBackground);
	almaControl.setForeground(ColorsFonts.controlPanelForeground);
	makeControlPanel(almaControl);

	GridBagConstraints aCCon = new GridBagConstraints();
	aCCon.gridx = 0;
	aCCon.gridy = GridBagConstraints.RELATIVE;
	aCCon.fill = GridBagConstraints.HORIZONTAL;
	this.add(almaControl, aCCon);

	//--------------------------------------------------
	// the io panel

	Panel toAlma = new Panel(new GridBagLayout());
	toAlma.setBackground(ColorsFonts.ioPanelBackground);
	makeIOPanel(toAlma);

        GridBagConstraints tACon = new GridBagConstraints();	
	tACon.gridy = GridBagConstraints.RELATIVE;
	tACon.gridx = 0;
	this.add(toAlma, tACon);

	//--------------------------------------------------

        validate();
	
	//__________________________________________________
	// start alma if need be

	if(autoStart) startAlma();

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
	    almaExec = new String("alma run false keyboard true history h histocket htcp prompt false");
	else
	    almaExec = args;

	//__________________________________________________
	// autoStart

	String start = getParameter("autoExec");
	autoStart = false;
	if(start != null)
	    if(start.compareTo("true") == 0) autoStart = true;

	//__________________________________________________
	// 
	historyInputURLName = getParameter("historyInputURLName");
	if(historyInputURLName != null) historyFromFile = true;
	else historyFromFile = false;
	//__________________________________________________
	//
	String trueString = "true";
	String hFF = getParameter("historyFromFile");
	if(hFF != null){
	    if(trueString.compareTo(hFF) == 0){
		historyFromFile = true;
	    }
	    else
		historyFromFile = false;
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



    //**************************************************
    // makeHistoryPanel was here!

    /**
     * This execs the alma according to the almaArgs.
     * We cannot exec alma if there is one already running and connected.
     */

    public void startAlma(){

	alma = null;
	Runtime thisProcess = Runtime.getRuntime();
	if(Globals.verbose)
	    System.out.println("\n\nExecing: " + almaExec);
	try{
	    alma = thisProcess.exec(almaExec);
	}catch(Exception e){
	    showStatus("Cannot exec alma" + e);
	    System.err.println("Cannot exec alma" + e);
	    System.exit(0);
	}

	if(Globals.verbose)
	    System.out.println("Done exec, going to get streams\n");
	
	almaInputStream = alma.getInputStream();
	almaOutputStream = alma.getOutputStream();
	almaErrorStream = alma.getErrorStream();

	almaStreamReader = new InputStreamReader(almaInputStream);
	almaErrorStreamReader = new InputStreamReader(almaErrorStream);
	almaReader = new BufferedReader(almaStreamReader);
	almaWriter = new BufferedWriter(new 
					OutputStreamWriter(almaOutputStream), 5);

	almaErrorReader = new BufferedReader(almaErrorStreamReader);

	if(Globals.verbose)
	    System.out.println("Going to loop\n");

	//--------------------------------------------------
	// start alma output monitor

	almaError = new AlmaOut(almaErrorReader, tty);
	almaDisplay = new AlmaOut(almaReader, tty);

	almaError.start();
	almaDisplay.start();
	
	almaStepper.setAlmaWriter(almaWriter);

    } // start alma

    //**************************************************

    /**
     * The control panel enables the user to control the running of alma.
     * <br>
     * <img src="execcontrol.gif">
     * <br>
     * The following controls are provided:
     * <ul>
     * <li>
     * Exec. If alma is not automatically started, clicking this will
     * start alma. This will not work if alma is already up.
     * <li>
     * Step. This causes alma to step once. If alma is automatically stepping,
     * the results might be unexepcted.
     * <li>
     * Run. This causes alma to step continuously with a delay between steps
     * as specified by the next control. If alma is run with "run true", this
     * might not have the expected results.
     * <li>
     * Delay. The delay can be specified in milliseconds. Making the delay
     * shorter than is possible for the alma executable does no good.
     * <li>
     * Stop. This stops alma from stepping if that was initiated by the Run
     * button. It has no effect on a "run true" alma process.
     * Reset. This resets alma. It is effective for both an automatically
     * stepping alma process and one controlled from the GUI.
     *</ul>
     */

    public void makeControlPanel(Panel almaControl){

	//start button
	startAlma = new Button("Exec");
	startAlma.addActionListener(new ActionListener(){
	    public void actionPerformed(ActionEvent sAE){
		if(alma == null)
		    startAlma();
		else showStatus("Alma has already been execed!");
	    } // actionPerformed
	} // actonListener
				    );
	
	GridBagConstraints startCon = new GridBagConstraints();
        startCon.gridx = 0;
        startCon.gridy = 0;
        almaControl.add(startAlma, startCon);
	

	//--------------------------------------------------
	// button for stepping
        step = new Button("Step");
        step.addActionListener(new ActionListener(){
            public void actionPerformed(ActionEvent e){
		if(alma == null)
		    showStatus("Alma has not been execed yet.");
		else{
		    char [] stepCA = {'s', 'r', '.'};
		    try{
			almaWriter.write(stepCA);
			almaWriter.newLine();
			almaWriter.flush();
		    }catch(Exception e3){
			showStatus("Problem writing to alma" + e3);
			System.err.println("Problem writing to alma" + e3);
		    }
		}
	    }
        }
                               );
        GridBagConstraints stepCon = new GridBagConstraints();
        stepCon.gridx = GridBagConstraints.RELATIVE;
        stepCon.gridy = 0;

        almaControl.add(step, stepCon);


	//--------------------------------------------------
	// button for stepping
        runAlma = new Button("Run");
        runAlma.addActionListener(new ActionListener(){
            public void actionPerformed(ActionEvent e){
		synchronized(theRunParms){
		    //		    theRunParms.delay = 1000;
		    String dtxt = delayField.getText();
		    try{
			theRunParms.delay = Integer.
			    parseInt(dtxt.trim(), 10);
		    }catch(Exception ie1){
			showStatus("Delay should be an int" + ie1);
			System.err.println("Delay should be an int" + ie1);
		    }
		    if(theRunParms.delay < 0){
			theRunParms.delay = 0;
		    } // if goto > 0

		    theRunParms.run = true;
		    if(Globals.verbose)
			System.out.println("Gui notifying run");
		    theRunParms.notify();
		}
            }
        }
                               );

        GridBagConstraints runCon = new GridBagConstraints();
        runCon.gridx = GridBagConstraints.RELATIVE;
        runCon.gridy = 0;

        almaControl.add(runAlma, runCon);


	//    Label delayLabel;
	//    TextField delayField;

	//--------------------------------------------------
	// label for delay

	delayLabel = new Label("Delay (ms)");
	GridBagConstraints delayCon = new GridBagConstraints();
	delayCon.gridx = GridBagConstraints.RELATIVE;
	delayCon.gridy = 0;
	
	almaControl.add(delayLabel, delayCon);

	//__________________________________________________
	// textfield for delay

        delayField = new TextField(5);
	delayField.setText("1000");
        GridBagConstraints delayFCon = new GridBagConstraints();
        delayFCon.gridy = 0;
        delayFCon.gridx = GridBagConstraints.RELATIVE;

	almaControl.add(delayField, delayFCon);



	//--------------------------------------------------
	// button for stopping
        stopAlma = new Button("Stop");
        stopAlma.addActionListener(new ActionListener(){
            public void actionPerformed(ActionEvent e){
		synchronized(theRunParms){
		    theRunParms.run = false;
		}
            }
        }
                               );

        GridBagConstraints stopCon = new GridBagConstraints();
        stopCon.gridx = GridBagConstraints.RELATIVE;
        stopCon.gridy = 0;

        almaControl.add(stopAlma, stopCon);





	//--------------------------------------------------
	// button for resetting alma

        resetAlma = new Button("Reset");
        resetAlma.addActionListener(new ActionListener(){
            public void actionPerformed(ActionEvent e){
		char [] resetIt = {'r', 'e', 's', 'e', 't', '_', 'a', 'l', 'm', 'a','.'};
		try{
		    almaWriter.write(resetIt);
		    almaWriter.newLine();
		    almaWriter.flush();
		}catch(Exception e3){
		    showStatus("Problem writing to alma" + e3);
		    System.err.println("Problem writing to alma" + e3);
		}
		theDb.resetDb();
            }
        }
                               );
        GridBagConstraints resetAlmaCon = new GridBagConstraints();
        resetAlmaCon.gridx = GridBagConstraints.RELATIVE;
        resetAlmaCon.gridy = 0;

        almaControl.add(resetAlma, resetAlmaCon);

} // makeControlPanel

    
    //**************************************************
    //**************************************************

    /**
     * The IO panel reads and writes to the alma process though stdio.
     * <br>
     * <img src="io.gif">
     * <br>
     * There are two windows: one for input and one for output.
     * <br>
     * The window for input expects the same syntax as one would type at
     * the alma keyboard. To send a command to alma, click on "Send".
     * <br>
     * The output window displays whatever alma outputs to stdout.
     */

    public void makeIOPanel(Panel toAlma){

	
	ioLabel = new Label("Alma IO");
	GridBagConstraints ioLCon = new GridBagConstraints();
	ioLCon.gridx = 0;
	ioLCon.gridy = 0;
	toAlma.add(ioLabel, ioLCon);


	//--------------------------------------------------
	// alma input field

        ttyIn = new TextField(50);
        GridBagConstraints ttyInCon = new GridBagConstraints();
	//        ttyInCon.gridy = sHBCon.gridy + 1;
        ttyInCon.gridx = 0;
        ttyInCon.gridy = GridBagConstraints.RELATIVE;
	ttyInCon.fill = GridBagConstraints.HORIZONTAL;
	//        ttyInCon.anchor = GridBagConstraints.SOUTH;


        toAlma.add(ttyIn, ttyInCon);

	//--------------------------------------------------
	// this when clicked sends the contents above to alma

        addC = new Button("Send");
        addC.addActionListener(new ActionListener(){
            public void actionPerformed(ActionEvent e){
                String s = ttyIn.getText();
		if(Globals.verbose)
		    System.out.println("sending to alma " + s);
		//		toAlma.
		try{
		    almaWriter.write(s.toCharArray());
		    almaWriter.newLine();
		    almaWriter.flush();
		}catch(Exception e2){
		    showStatus("Problem writing to alma" + e2);
		    System.err.println("Problem writing to alma" + e2);
		}
		ttyIn.setText("");
            }
        }

                               );
        GridBagConstraints acCon = new GridBagConstraints();
        acCon.gridy = ttyInCon.gridx + 1;
        acCon.gridx = GridBagConstraints.RELATIVE;
        toAlma.add(addC, acCon);

	//--------------------------------------------------
	// label for alma output
	// REMOVED

	opLabel = new Label("Alma output");
	GridBagConstraints opCon = new GridBagConstraints();
	opCon.gridx = 0;
	opCon.gridy = GridBagConstraints.RELATIVE;
	//	toAlma.add(opLabel, opCon);

	//--------------------------------------------------
	// this is to receive the output from alma

        tty = new TextArea(ALMAHEIGHT, ALMAWIDTH);
	tty.setBackground(ColorsFonts.ioPanelBackground);
        GridBagConstraints ttyCon = new GridBagConstraints();
        ttyCon.gridx = 0;
	//        ttyCon.gridy = opCon.gridy + 1;
	ttyCon.gridy = GridBagConstraints.RELATIVE;
        ttyCon.weightx = 0;
        ttyCon.weighty = 0;
        ttyCon.gridwidth = GridBagConstraints.REMAINDER;
        ttyCon.fill = GridBagConstraints.BOTH;

        toAlma.add(tty, ttyCon);

    } // makeIOPanel


    // maybe more needs to be done here, but this is the minimum i guess.
    // need to kill other threads, kill processes, close sockets and files.
    //
    public void stop(){
	if(verbose)System.err.println("Stop: Nulling Db thread");
	System.err.flush();
	theDb = null;
	/*
	synchronized(theDb.hBRW){
		    theDb.hBRW.notify();
	if(verbose) System.err.println("Stopping");
	System.err.flush();
	if(theDb != null){
	    if(verbose) System.err.println("Is the Db alive: " + theDb.isAlive());
	    System.err.flush();
	    if(theDb.isAlive()) theDb.destroy();
	}
	}	
	*/
    } // stop

    public void destroy(){
	/*
	if(verbose) System.err.println("Stopping");
	System.err.flush();
	if(theDb != null){
	    if(verbose) System.err.println("Is the Db alive: " + theDb.isAlive());
	    System.err.flush();
	    if(theDb.isAlive()) theDb.destroy();
	}
	*/
    } // destroy



} // class
