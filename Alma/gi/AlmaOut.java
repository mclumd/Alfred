
import java.awt.*;
import java.io.*;

/** This class updates the output of the alma process to the IO panel.
 * 
 * @author K. Purang
 * @version October 2000
 */


public class AlmaOut extends Thread{

    BufferedReader almaReader;
    TextArea outputDisplay;
    
    public AlmaOut(BufferedReader br, TextArea ta){
	almaReader = br;
	outputDisplay = ta;
    } // constructor

    public void run(){
	
	outputDisplay.append("Starting...\n");

	String instring = null;
	char inchar;
	for(;;){
	    try{
		instring = almaReader.readLine() + "\n";
	    }catch(Exception e3){
		Globals.theGui.showStatus("Problems reading from alma\n");
		System.err.println("Problems reading from alma\n");
	    }
	    if(Globals.verbose)
		System.out.println("Read from alma: " + instring);
	    outputDisplay.append(instring);
	} // forever

    } // run


} // class


