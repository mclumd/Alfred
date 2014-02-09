/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;
import java.io.IOException;

/**
 * <code>Term</code> is the base for Java representations of Prolog terms.
 */
public abstract class Term {

  protected final String name;

  /**
   * Creates a new <code>Term</code> instance with the specified name.
   */
    // [PM] FIXME: Should there not be any (static) methods for creating instances of (classes derived from) Term??
    // [JE] Possibly (even probably) in later versions.
  Term(String name) {
    if (name == null) {
      throw new NullPointerException();
    }
    this.name = name;
  } // Term constructor

  /**
   * Returns <code>true</code> if this term is an atom and
   * <code>false</code> otherwise.
   */
  public boolean isAtom() {
    return false;
  }

  /**
   * Returns <code>true</code> if this term is an integer and
   * <code>false</code> otherwise.
   */
  public boolean isInteger() {
    return false;
  }

  /**
   * Returns <code>true</code> if this term is a floating-point number
   * and <code>false</code> otherwise.
   */
  public boolean isFloat() {
    return false;
  }

  /**
   * Returns <code>true</code> if this term is a compund term and
   * <code>false</code> otherwise.
   */
  public boolean isCompound() {
    return getArity() > 0;
  }

  /**
   * Returns <code>true</code> if this term is a list and
   * <code>false</code> otherwise.
   */
  public boolean isList() {
    return getArity() == 2 && ".".equals(getName());
  }

  /**
   * Returns <code>true</code> if this term is an instance
   * of <code>PBString</code> (which can be used for fast string access) and
   * <code>false</code> otherwise.
   */

   // [PM] FIXME: this is not true. For Terms received from
   // library(fastrw) it is true only if the character codes are
   // [1..255], i.e., not for NUL nor for non-Latin-1 UNICODE but for
   // Terms created with Bindings.bind(String,String) it is true for
   // all characters. Arguably the documentation is right and the code
   // is wrong but it may be too expensive to implement isString to
   // work not only for PBString but also for PBList and Compund (and
   // perhaps Atom if the atom "[]" can ever result in an Atom instead
   // of PBList.NIL. On the other hand, the common case is likely to
   // be when it is a PBString so the extra cost for other classes may
   // not be an issue.
   // [PM] FIXME: This also affects prologbeans.texi
   // [JE] Documentation updated. Should probably try to find another
   //      solution to this.
   //
  public boolean isString() {
    return false;
  }

  /**
   * Returns <code>true</code> if this term is a constant
   * (e.g. integer, floating-point number, or atom) and
   * <code>false</code> if this term is a compound term or variable.
   */
  public boolean isAtomic() {
    return false;
  }

  /**
   * Returns <code>true</code> if this term is a variable and
   * <code>false</code> otherwise.
   */
  public boolean isVariable() {
    return false;
  }

  /**
   * Returns the name of this constant or compound term.
   */
  public String getName() {
    return name;
  }

  /**
   * Returns the argument at the specified index. Only compound terms
   * have arguments. Note: the arguments are indexed from 1 to arity.
   *
   * @param index the (one based) index of the argument
   * @return the argument as a Term
   * @throws java.lang.IllegalStateException if this term is not compound
   */
  public Term getArgument(int index) {
    throw new IllegalStateException("not a compound term: " + toString());
  }

  /**
   * Returns the number of arguments of this compound term or 0 if this
   * term is not a compound term.
   */
  public int getArity() {
    return 0;
  }

  /**
   * Returns the integer value of this term.
   *
   * @throws java.lang.IllegalStateException if this term is not an integer
   */
  public int intValue() {
    throw new IllegalStateException("not an integer: " + toString());
  }

  /**
   * Returns the integer value of this term.
   *
   * @throws java.lang.IllegalStateException if this term is not an integer
   */
  public long longValue() {
    throw new IllegalStateException("not an integer: " + toString());
  }

  /**
   * Returns the floating-point value of this term.
   *
   * @throws java.lang.IllegalStateException if this term is not a number
   */
  public float floatValue() {
    throw new IllegalStateException("not a number: " + toString());
  }

  /**
   * Returns the floating-point value of this term.
   *
   * @throws java.lang.IllegalStateException if this term is not a number
   */
  public double doubleValue() {
    throw new IllegalStateException("not a number: " + toString());
  }

  /**
   * For internal use by PrologBeans.
   *
   * Returns a string representation of this term in a format that can be
   * parsed by a Prolog parser.
   */

   // [PM] FIXME: Should use fastrw-format to send data to Prolog as
   // well. It will be a nightmare trying to produce properly quoted
   // terms in a way that can be read correctly by Prolog. If that is
   // not hard enough try making it work with non-8-bit characters and
   // then start flipping the prolog-flags 'language' (ISO have
   // different quoting rules than SICStus), 'double_quotes' and
   // 'character_escapes'. (Did I mention that I think relying on the
   // prolog reader is a bad idea for the release version :-).
   // [JE] Fixed using writeFast() (toPrologString() not used anymore)

  abstract String toPrologString();

  abstract void fastWrite(FastWriter writer) throws IOException;

  /**
   * Returns a string description of this term.
   */
  public abstract String toString();


  // -------------------------------------------------------------------
  // Internal utilities
  // -------------------------------------------------------------------

  private int getFirstStuffing(String atom) {
    int len = atom.length();
    if (len == 0) {
      return 0;
    }
    char c = atom.charAt(0);
    if (c < 'a' || c > 'z') {
      return 0;
    }

    for (int i = 1; i < len; i++) {
      c = atom.charAt(i);
      if (!((c >= 'a' && c <= 'z')
	    || (c >= 'A' && c <= 'Z')
	    || (c >= '0' && c <= '9')
	    || (c == '_'))) {
	return i;
      }
    }
    return -1;
  }

  protected String stuffAtom(String atom) {
    int start = getFirstStuffing(atom);
    if (start < 0) {
      // No stuffing needed
      return atom;
    }

    int len = atom.length();
    char[] buf = new char[start + (len - start) * 2 + 2];
    int index = 1;
    buf[0] = '\'';
    if (start > 0) {
      atom.getChars(0, start, buf, 1);
      index += start;
    }
    for (int i = start; i < len; i++) {
      char c = atom.charAt(i);
      if (c == '\'') {
	buf[index++] = '\\';
      }
      buf[index++] = c;
    }
    buf[index++] = '\'';
    return new String(buf, 0, index);
  }

} // Term
