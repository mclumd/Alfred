package pparser;


/**
   Given a ParseMe object, we try to aprse the fist var we find at
   the index and move the index to the char after the var

   How do we represent a list now?
   just a vector will do. put terms in it.

*/

import java.util.*;
//import Global;
import java.lang.*;

public class List extends Term{
    
    Term theList[];

    public List(Vector sc){
	//	theList = (Term[])sc.toArray(new Term[1]);
	if(sc != null){
	    theList = new Term[sc.size()];
	    sc.copyInto(theList);
	}
	else theList = null;
	return;
    }
    
    public static List parseList(ParseMe toParse){
	Global.eatWhite(toParse);
	int begin = 0; 
	int end = 0;
	int cntr= 0;
	Term nextTerm = null;

	int originalIndex = toParse.theIndex;

	Vector parsedList = new Vector();
	
	// not run off the end of the string.
	if(toParse.theIndex >= toParse.stringLength) return null;

	if((toParse.theString).charAt(toParse.theIndex) != '[')
	    return null;
	toParse.theIndex++;

	nextTerm = Term.parseTerm(toParse);
	if(nextTerm != null){	// first element
	    parsedList.addElement(nextTerm);
	}
	else{			// empty list
	    Global.eatWhite(toParse);
	    if((toParse.theString).charAt(toParse.theIndex) == ']'){
		toParse.theIndex++;
		return new List(parsedList);
	    }
	    else{
		toParse.theIndex = originalIndex;
		return null;
	    }
	} // else

	int oldIndex = -1;
	while(toParse.theIndex < toParse.stringLength && 
	      oldIndex != toParse.theIndex){
	    oldIndex = toParse.theIndex;
	    Global.eatWhite(toParse);
	    if((toParse.theString).charAt(toParse.theIndex) == ']'){
		toParse.theIndex++;
		return new List(parsedList);
	    }
	    if((toParse.theString).charAt(toParse.theIndex) == ','){
		(toParse.theIndex)++;
		nextTerm = Term.parseTerm(toParse);
		if(nextTerm == null){
		    toParse.theIndex = originalIndex;
		    return null;
		}
		else{
		    parsedList.addElement(nextTerm);
		} // else		
	    } // if we have a ','

	} // while

	toParse.theIndex = originalIndex;
	return null;
      
    } // parse



    public String toString(){
	StringBuffer sB = new StringBuffer();
	sB.append("[");
	int cntr = 0;

	if(theList.length == 0 || theList[cntr] == null){
	    sB.append("]");
	    return sB.toString();
	}
	else{
	    sB.append((theList[cntr]).toString());
	    cntr++;
	}

	while(cntr < theList.length && theList[cntr] != null){
	    sB.append(", " + (theList[cntr]).toString());
	    cntr++;
	} // while

	sB.append("]");
	return sB.toString();

    } // toString


    // counnt from 0!!
    public Term getElement(int i){
	if(i >= theList.length) return null;
	return theList[i];
    }

    public int getNumElements(){
	return theList.length;
    }

} // class
