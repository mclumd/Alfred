/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;
import java.io.IOException;

/**
 * <code>PBCompound</code> is the Java representation of Prolog compound
 * terms and atoms (such as the empty list).
 */
public class PBCompound extends Term {

  protected final Term[] arguments;

  PBCompound(String name, Term[] args) {
    super(name);
    this.arguments = args;
  } // PBCompound constructor

  public boolean isAtom() {
    return getArity() == 0;
  }

  public boolean isAtomic() {
    return getArity() == 0;
  }

  public Term getArgument(int index) {
    if (arguments == null) {
	throw new IllegalStateException("not a compound term: " + toString());
    }
    if (index < 1 || index > arguments.length) {
	throw new IndexOutOfBoundsException("Index: " + index
					    + ", needs to be between 1 and "
					    + getArity());
    }
    return arguments[index - 1];
  }

  public int getArity() {
    return arguments == null ? 0 : arguments.length;
  }

  String toPrologString() {
    StringBuffer sb = new StringBuffer()
      .append(stuffAtom(name));
    if (arguments != null) {
      sb.append('(');
      for (int i = 0, n = arguments.length; i < n; i++) {
	if (i > 0) {
	  sb.append(',');
	}
	sb.append(arguments[i].toPrologString());
      }
      sb.append(')');
    }
    return sb.toString();
  }

  public String toString() {
    StringBuffer sb = new StringBuffer()
      .append(name);
    if (arguments != null) {
      sb.append('(');
      for (int i = 0, n = arguments.length; i < n; i++) {
	if (i > 0) {
	  sb.append(',');
	}
	sb.append(arguments[i].toString());
      }
      sb.append(')');
    }
    return sb.toString();
  }

  void fastWrite(FastWriter writer) throws IOException {
    if (arguments != null) {
      writer.writeCompound(name, arguments.length);
      for (int i = 0, n = arguments.length; i < n; i++) {
	arguments[i].fastWrite(writer);
      }
    } else {
      throw new IllegalStateException("not a compound term: " + toString());
    }
  }

} // PBCompound
