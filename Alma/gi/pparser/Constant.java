package pparser;

/**
   Given a ParseMe object, we try to aprse the fist constant we find at
   the index and move the index to the char after the constant
*/

//import Global;

public class Constant extends Term{
    
    String theConstant = null;

    public Constant(String sc){
	theConstant = sc;
	return;
    }
    
    public static Constant parseConstant(ParseMe toParse){
	Global.eatWhite(toParse);
	int begin = 0; 
	int end = 0;
	int cntr= 0;
	int originalIndex = toParse.theIndex;

	//	System.out.println(toParse);
	
	// not run off the end of the string.
	if(toParse.theIndex >= toParse.stringLength) return null;

	// Quoted term
	if((toParse.theString).charAt(toParse.theIndex) == '\'' ){	    
	    // get a quoted term and return
	    begin = toParse.theIndex;
	    cntr = begin + 1;
	    while(cntr < toParse.stringLength && 
		  (toParse.theString).charAt(cntr) != '\'' ){
		cntr ++;
	    }
	    if((toParse.theString).charAt(cntr) == '\'' ){
		toParse.theIndex = cntr + 1;
		return new Constant((toParse.theString).
				    substring(begin, cntr + 1));
	    }
	    else return null;
	}
				// String


	if((toParse.theString).charAt(toParse.theIndex) == '\"'){
	    // get a string and return
	    begin = toParse.theIndex;
	    cntr = begin + 1;
	    while(cntr < toParse.stringLength && 
		  (toParse.theString).charAt(cntr) != '\"'){
		cntr ++;
	    }
	    if((toParse.theString).charAt(cntr) == '\"'){
		toParse.theIndex = cntr + 1;
		return new Constant((toParse.theString).
				    substring(begin, cntr + 1));
	    }
	    else return null;
	}

	
	// Integer
	if(Character.isDigit((toParse.theString).charAt(toParse.theIndex))){
	    begin = toParse.theIndex;
	    cntr = begin + 1;
	    while(cntr < toParse.stringLength && 
		  Character.isDigit((toParse.theString).charAt(cntr))){
		cntr ++;
	    }
	    /*
	    if(Character.isDigit((toParse.theString).charAt(cntr))){
		toParse.theIndex = cntr + 1;
		return new Constant((toParse.theString).
				    substring(begin, cntr));
	    }
	    else return null;
	    */
	    toParse.theIndex = cntr;
	    return new Constant((toParse.theString).
				substring(begin, cntr));

	}
	// regular thing
	if(Character.isLowerCase((toParse.theString).charAt(toParse.theIndex))){
	    begin = toParse.theIndex;
	    cntr = begin + 1;
	    while(cntr < toParse.stringLength && 
		  Global.legalChar((toParse.theString).charAt(cntr))){
		cntr ++;
	    }
	    /*
	    if(Global.legalChar((toParse.theString).charAt(cntr))){
		toParse.theIndex = cntr + 1;
		return new Constant((toParse.theString).
				    substring(begin, cntr));
	    }
	    else return null;
	    */
	    toParse.theIndex = cntr;

	    //	    System.out.println("In Consatn " + toParse.toString());

	    return new Constant((toParse.theString).
				substring(begin, cntr));
	}
	
	toParse.theIndex = originalIndex;
	return null;

    } // parseConstant




    public String toString(){
	return theConstant;
    }
    
} // class Constant
