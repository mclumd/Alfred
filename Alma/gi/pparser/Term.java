package pparser;


public abstract class Term{

    public abstract String toString();
    
    
    public static Term parseTerm(ParseMe pm){
	Term theOne = null;

	//	System.out.println("Before Cterm \n" + pm.toString());

	theOne = Cterm.parseCterm(pm);
	if(theOne != null) return theOne;

	//	System.out.println("After Cterm \n" + pm.toString());

	theOne = Constant.parseConstant(pm);
	if(theOne != null) return theOne;

	//	System.out.println("After Constatn \n" + pm.toString());

	theOne = Var.parseVar(pm);
	if(theOne != null) return theOne;

	//	System.out.println("After var \n" + pm.toString());

	theOne = List.parseList(pm);
	if(theOne != null) return theOne;

	//	System.out.println("After list \n" + pm.toString());

	return null;

    } // parseTerm
    
} // class term
