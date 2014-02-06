package pparser;

/**
   Given a ParseMe object, parse as pred(list of terms)

*/

import java.util.*;
//import Global;
import java.lang.*;
//import Constant;

public class Cterm extends Term{

    Constant thePred;
    Term theList[];
    int arity;

    public Cterm(Constant pred, Vector sc){
	thePred = pred;
	if(sc != null){
	    //	    theList = (Term[])sc.toArray(new Term[1]);
	    //	    arity = theList.length;
	    theList = new Term[sc.size()];
	    sc.copyInto(theList);
	    arity = theList.length;
	    return;
	}
	arity = 0;
	theList = null;
	return;
    }
    
    public static Cterm parseCterm(ParseMe toParse){
	int originalIndex = toParse.theIndex;
	Global.eatWhite(toParse);
	int begin = 0; 
	int end = 0;
	int cntr= 0;
	Term nextTerm = null;

	// not run off the end of the string.
	if(toParse.theIndex >= toParse.stringLength){
	    toParse.theIndex = originalIndex;
	    return null;
	}

	Constant pred = Constant.parseConstant(toParse);
	if(pred == null){
	    toParse.theIndex = originalIndex;
	    return null;
	}
	

	Vector parsedList = new Vector();
	//	System.out.println(toParse);

	if(toParse.theString.length() <= toParse.theIndex + 1){
	    //	    return new Cterm(pred, null);
		toParse.theIndex = originalIndex;
		return null;
	}
	
	if((toParse.theString).charAt(toParse.theIndex) != '('){
	    if((toParse.theString).charAt(toParse.theIndex) != '.'){
		toParse.theIndex = originalIndex;
		return null;
	    }
	    else{		// a prposition
		return new Cterm(pred, null);
	    }
	}
	toParse.theIndex++;

	//	System.out.println("List got (");

	nextTerm = Term.parseTerm(toParse);
	if(nextTerm != null){	// first element
	    parsedList.addElement(nextTerm);
	    //	    System.out.println("List got term " + nextTerm.toString());
	    //	    System.out.println("In List " + toParse.toString());

	}
	else{			// empty list
	    Global.eatWhite(toParse);
	    if((toParse.theString).charAt(toParse.theIndex) == ')'){
		toParse.theIndex++; //###
		Global.eatWhite(toParse);
		if((toParse.theString).charAt(toParse.theIndex) == '.'){
		    toParse.theIndex++;
		}
		return new Cterm(pred, parsedList);
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

	    //	    System.out.println("In list loop " + toParse.toString());
	    Global.eatWhite(toParse);
	    if((toParse.theString).charAt(toParse.theIndex) == ')'){
		toParse.theIndex++;
		//		System.out.println("List got )");
		return new Cterm(pred, parsedList);
	    }

	    if((toParse.theString).charAt(toParse.theIndex) == ','){
		(toParse.theIndex)++;
		nextTerm = Term.parseTerm(toParse);
		if(nextTerm == null){
		    toParse.theIndex = originalIndex;
		    return null;
		}
		else{
		    //		    System.out.println("List got term " + nextTerm.toString());

		    parsedList.addElement(nextTerm);
		} // else		
	    }
	    //	    toParse.theIndex = originalIndex;
	    //	    return null;
	} // while

	toParse.theIndex = originalIndex;
	return null;

    } // parseCterm


    public String toString(){
	StringBuffer sB = new StringBuffer();
	if(theList == null){
	    return thePred.toString();
	}
	sB.append(thePred + "(");
	int cntr = 0;

	if(theList.length == 0 || theList[cntr] == null){
	    sB.append(")");
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

	sB.append(")");
	return sB.toString();

    } // toString


    public Constant getPred(){
	return thePred;
    }

    // counnt from 0!!
    public Term getArg(int i){
	if(i >= arity) return null;
	return theList[i];
    }

    public int getNumArgs(){
	return arity;
    }


} // class
