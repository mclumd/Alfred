
import java.applet.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import pparser.*;

/**
 * This class is the representation of the formulas.
 * @author K. Purang
 * @version October 2000
 */

public class Formula{
    String theFormula;
    String name;
    int beginPos; 
    int endPos;
    int timeAdded;
    int timeDeleted;		// if -1, not deleted
    boolean deleted;		// whether it is deleted in the kb
    // might need other properties too
    // parent later.
    Term node;

    public Label theLabel;		// label that holds this formula
    boolean displayed;		// is the label on the screen?
    //**************************************************
    public Formula(String form, String myname, Term nodeIn){
	theFormula = form;
	name = myname;
	node = nodeIn;
	deleted = false;
	timeAdded = 0;
	timeDeleted = -1;
	theLabel = new Label(myname + ": " + form.substring(1, form.length() - 1));
	//	theLabel.setBackground(Color.cyan);
	theLabel.setSize(theLabel.getMinimumSize());
    } // constructor

    //**************************************************
    public void setTimeAdded(int time){
	timeAdded = time;
    }

    public void setTimeDeleted(int time){
	timeDeleted = time;
    }

    public int getTimeAdded(){
	return timeAdded;
    }

    public int getTimeDeleted(){
	return timeDeleted;
    }


    public boolean inDbTime(int time){
	if(time < timeAdded) return false;
	else if(timeDeleted > 0 && time >= timeDeleted) return false;
	else return true;
    }


    //**************************************************
    public void setBeginPos(int pos){
	beginPos = pos;
    }

    public int getBeginPos(){
	return beginPos;
    }
    
    //**************************************************
    public void setEndPos(int pos){
	endPos = pos;
    }

    public int getEndPos(){
	return endPos;
    }
    

    //**************************************************



    public String getName(){
	return name;
    }

    public void delete(){
	deleted = true;
    }

    public String toString(){
	return(name + ": " + theFormula);
    }

    public boolean deleted(){
	return deleted;
    }


    // is this formula visible in this step?
    public boolean isAlive(int theStep){
	//	if(theStep == currentStep) return !deleted;
	//else 
	if(theStep >= timeAdded &&
	   theStep < timeDeleted) return true;
	else return false;
    } // isAlive


    public boolean isDisplayed(){
	return displayed;
    }

    // more things later for derivations etc.


} // Formula
