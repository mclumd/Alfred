package pparser;

/**
   This has the string to be parsed and an index into the string.

*/

public class ParseMe{

    public String theString;
    public int theIndex;
    public int stringLength;

    public ParseMe(String inString){
	theString = inString;
	theIndex = 0;
	stringLength = theString.length();
    } // constructor

    public String toString(){
	return ("**" + theString + "**\n" + 
		"Length: " + stringLength + "\n" +
		"Index: " + theIndex);
    }

} // class ParseMe
