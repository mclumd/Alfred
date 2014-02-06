package pparser;

public class Global{

    static boolean legalChar(char x){
	return (Character.isLetterOrDigit(x) || x == '_');
    }

    static void eatWhite(ParseMe in){
	int i = in.theIndex;
	while(i < in.stringLength && 
	      Character.isWhitespace((in.theString).charAt(i))){
	    i++;
	}
				// this is weird.

	if(i == in.stringLength && ! 
	   Character.isWhitespace((in.theString).charAt(i - 1))) in.theIndex = i - 1;

	else  in.theIndex = i;
    } // eatWhite


}
