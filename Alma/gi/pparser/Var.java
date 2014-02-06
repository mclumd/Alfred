package pparser;

/**
   Given a ParseMe object, we try to aprse the fist var we find at
   the index and move the index to the char after the var
*/

//import Global;

public class Var extends Term{
    
    String theVar = null;

    public Var(String sc){
	theVar = sc;
	return;
    }
    
    public static Var parseVar(ParseMe toParse){
	Global.eatWhite(toParse);
	int begin = 0; 
	int end = 0;
	int cntr= 0;

	//	System.out.println(toParse);
	
	// not run off the end of the string.
	if(toParse.theIndex >= toParse.stringLength) return null;

	// Vars starting with uppercase
	if(Character.isUpperCase((toParse.theString).charAt(toParse.theIndex))){
	    begin = toParse.theIndex;
	    cntr = begin + 1;
	    while(cntr < toParse.stringLength && 
		  Global.legalChar((toParse.theString).charAt(cntr))){
		cntr ++;
	    }
	    toParse.theIndex = cntr;
	    return new Var((toParse.theString).
			   substring(begin, cntr));
	}


	// Vars starting with underscore
	if((toParse.theString).charAt(toParse.theIndex) == '_'){
	    begin = toParse.theIndex;
	    cntr = begin + 1;
	    while(cntr < toParse.stringLength && 
		  Global.legalChar((toParse.theString).charAt(cntr))){
		cntr ++;
	    }
	    toParse.theIndex = cntr;
	    return new Var((toParse.theString).
			   substring(begin, cntr));
	}

	return null;
    } // parsevar



    public String toString(){
	return theVar;
    }



} // class Var
