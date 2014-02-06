package pparser;

//import Global;
//import Constant;
//import ParseMe;
//import Var;
//import List;

public class Test{
    public static void main(String args[]){
	if(args.length == 0) System.out.println("Test input as args!");
	int cntr= 0;
	Term nc = null;
	ParseMe pm = null;
	while(cntr < args.length){
	    pm = new ParseMe(args[cntr]);
	    System.out.println("Parsing " + pm.toString());
	    nc = Term.parseTerm(pm);
	    if(nc != null) {
		System.out.println("Parsed as " + nc.getClass() 
					      + " " + nc.toString()); 
	    }
	    else {
		System.out.println("Not Parsed!!!!");
	    }
	    cntr++;
	} // while
	
	
    } // main


} // class test
