
/*

  thread that steps through alma
  mayeb get it to do ore later.
  
  hmm.. this needs to know the delay. should it own the control panel too?
  not for now.

*/

import java.util.*;
import java.applet.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;

/**
 * This class implements the "run" function of the alma control panel.
 * @author K. Purang
 * @version October 2000
 */


public class RunAlma extends Thread{

    RunParms theParms;
    BufferedWriter almaWriter;

    public RunAlma(RunParms parms){

	theParms = parms;

    } // constructor

    public void setAlmaWriter(BufferedWriter riter){
	almaWriter = riter;
    }

    public void run(){

	while(true){	
	    if(theParms.run){
		char [] stepCA = {'s', 'r', '.'};
		try{
		    almaWriter.write(stepCA);
		    almaWriter.newLine();
		    almaWriter.flush();
		}catch(Exception e){
		    Globals.theGui.showStatus("Problem writing to alma" + e);
		    System.err.println("Problem writing to alma" + e);
		}
		try{
		    sleep(theParms.delay);
		}
		catch(Exception e2){
		    Globals.theGui.showStatus("RunAlma sleep interrupted" + e2);
		    System.err.println("RunAlma sleep interrupted" + e2);
		}
	    } // if run
	    else
		synchronized (theParms){
		    try{
			theParms.wait();
		    }catch(Exception e3){
			Globals.theGui.showStatus("RunAlma wait interrupted" + e3);
			System.err.println("RunAlma wait interrupted" + e3);
		    }
		}
	} // while true

    } // run()

} // class


