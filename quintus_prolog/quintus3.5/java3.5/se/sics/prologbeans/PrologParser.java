package se.sics.prologbeans;
import java.util.ArrayList;


/**
 * PrologParser.java
 *
 *
 * Created: Tue May 13 11:14:03 2003
 *
 * @Author  :
 * @version 1.0
 */

public class PrologParser {

  private String prolog;
  private int pos;
  private Term term;

  public PrologParser(String prolog) {
    this.prolog = prolog;
    pos = 0;
  } // PrologParser constructor

  // yes/no/[['='(X,___),'='(Y,___)]]
  //
  //
  public Term getTerm() {
    if (term == null) {
      // System.out.println("Parsing: " + prolog);
      term = parseTerm();
    }
    return term;
  }

  private Term parseTerm() {
    String name = getNameAtom();

    if (name.equals("[")) {
      Term[] args = getAllArgs(']');
      return new PBCompound(name, args);
    }

    if (pos < prolog.length()) {
      char c = prolog.charAt(pos);
      switch(c) {
      case '(':
	pos++;
	Term[] args = getAllArgs(')');
	return new PBCompound(name, args);
      }
    }
    // System.out.println("Creating atom: " + name);
    name = name.trim();
    return new PBAtomic(name, getType(name));
  }

  private int getType(String value) {
    int len = value.length();
    if (len == 0) {
      return PBAtomic.ATOM;
    }

    char c = value.charAt(0);
    if ((c >= 'A' && c <= 'Z') || c == '_') {
      return PBAtomic.VARIABLE;
    }

    // Check for numbers and set the value...
    int minLen = 1;

    // Should have a much better check for this later...
    if (c == '-' && len > 1) {
      c = value.charAt(1);
      minLen++;
    }
    if (Character.isDigit(c)) {
      int okType = PBAtomic.INTEGER;
      int i = minLen;
      if (len > minLen) {
	boolean exp = false;
	// MUST BE FIXED TO HANDLE END for example "3443e-"
	do {
	  c = value.charAt(i++);
	  if (c == '.' && okType == PBAtomic.INTEGER && (i < len)) {
	    okType = PBAtomic.FLOAT;
	    c = value.charAt(i++);
	  } else if (c == 'e' && !exp && (i < len)) {
	    okType = PBAtomic.FLOAT;
	    exp = true;
	    c = value.charAt(i++);
	    if (c == '-' && i < len) {
	      c = value.charAt(i++);
	    }
	  }
	} while(Character.isDigit(c) && i < len);
      }
      if (i == len && i >= minLen) {
	return okType;
      }
    }
    return PBAtomic.ATOM;
  }

  private Term[] getAllArgs(char endChar) {
    // Do nothing if end already found!
    if (pos < prolog.length() && prolog.charAt(pos) == endChar) {
      return null;
    }
    boolean exit = false;
    ArrayList terms = new ArrayList();
    while (!exit) {
      // Get the term
      Term term = parseTerm();
      terms.add(term);

      if (pos < prolog.length()) {
	char c = prolog.charAt(pos);

	// End of args?
	if (c == endChar) {
	  pos++;
	  return (Term[]) terms.toArray(new Term[terms.size()]);
	} else if (c == ',') {
	  pos++;
	} else {
	  System.out.println("Syntax error " + pos + " -> " + c);
	  exit = true;
	}
      } else {
	System.out.println("Nothing more to read after " + term);
	return null;
      }
    }
    return null;
  }


  // get a name atom
  private String getNameAtom() {
    int endPos = pos;
    char c = prolog.charAt(endPos++);
    char endChar = '\0';
    boolean string = false;
    switch(c) {
    case '\'':
      endChar = '\'';
      string = true;
      break;
    case '\"':
      endChar = '\"';
      string = true;
      break;
    case '[':
      // A list!!!
      pos++;
      return "[";
    }
    StringBuffer sb = new StringBuffer();
    if (!string) sb.append(c);
    int len = prolog.length();
    boolean exit = false;
    while(endPos < len) {
      c = prolog.charAt(endPos++);
      if (c == '\\') {
	if (endPos < len) {
	  c = prolog.charAt(endPos++);
	} else {
	  System.out.println("Error parsing " + prolog);
	  return null;
	}
      } else if (string)  {
	if (c == endChar) {
	  pos = endPos;
	  return sb.toString();
	}
      } else if (c == '(' || c == ')' || c == ',' || c == ']') {
	endPos--;
	break;
      }
      sb.append(c);
    }
    pos = endPos;
    return sb.toString();
  }



  public static void main(String[] args) {
    String[] tests = new String[]  { "'a b'(41,23)",
				     "[a,b,c,d]",
				     "[['='(X,hej(42))]]" };

    Term t1 = null;
    if (args.length > 0) {
      t1 = new PrologParser(args[0]).getTerm();
    } else {
      for (int i = 0, n = tests.length; i < n; i++) {
      t1 = new PrologParser(tests[i]).getTerm();
      }
    }
    if (t1 != null) {
      System.out.println(t1);
      // Traverse the terms...

      print("", t1);
    }
  }

  private static void print(String tab, Term term) {
    String type = term.isAtom() ? "A " : term.isVariable() ? "V " : term.isList() ? "L " : term.isCompound() ? "C " : "? ";
    System.out.println(tab + type + term.getName());
    tab = tab + "   ";
    if (term.isCompound()) {
      PBCompound comp = (PBCompound) term;
      for (int i = 0, n = comp.getArity(); i < n; i++) {
	System.out.print(tab + "" + (i + 1) + " ");
	print(tab, comp.getArgument(i));
      }
    }
  }

} // PrologParser
