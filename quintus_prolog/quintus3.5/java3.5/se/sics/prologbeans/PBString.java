/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;
import java.io.IOException;

/**
 * <code>PBString</code> is the Java representation of Prolog strings
 * (e.g. lists of integers that are interpretable as characters).
 */
public class PBString extends PBList {
    // [PM] FIXME: Is the case where (value.length()==0 && nextTerm != NIL) treated correctly?
    // 1. Can this happen, and if not, why?
    //    - currently this can only happen if fastrw write...
    // 2. If it can happen then 'this' should behave as an alias for
    //    nextTerm so *all* Term-methods, not just those redefined
    //    here, should be passed to nextTerm.

  private final String value;

  PBString(String value) {
    this(value, NIL);
  }

  PBString(String value, Term nextTerm) {
    super(value.length() == 0 ? "[]" : ".", null, nextTerm);
    if (value.length() == 0 && nextTerm != null) {
      throw new IllegalArgumentException("illegal string: [|" +
					 nextTerm + "]");
    }
    this.value = value;
  }

  public boolean isString() {
    return nextTerm == NIL;
  }

  /**
   * Returns the first or second argument of this list node. Only
   * non-empty lists have arguments. Note: the arguments are indexed
   * from 1 to 2.<p>
   *
   * Due to performance reasons this should be avoided if not 100%
   * necessary. Please use <code>getCharAt(int index)</code> or
   * <string>getString()</code> for accessing the value of strings.
   *
   * @param index the (one based) index of the argument
   * @return the argument as a Term
   * @throws java.lang.IllegalStateException if this term is not compound
   */
  public Term getArgument(int index) {
    if (value.length() == 0) {
      throw new IllegalStateException("not a compound term: " + toString());
    }

    if (index == 1) {
      return new PBAtomic("" + value.charAt(0), PBAtomic.INTEGER);
    }
    if (index == 2) {
      if (value.length() > 1) {
	return new PBString(value.substring(1), nextTerm);
      } else {
	return nextTerm;
      }
    }
    throw new IndexOutOfBoundsException("Index: " + index
					+ ", needs to be between 1 and "
					+ getArity());
  }

  public int getArity() {
    return value.length() == 0 ? 0 : 2;
  }

  /**
   * Returns the string value of this term.
   */
  public String getString() {
    return value;
  }

  /**
   * Returns the number of characters in this string.
   */
  public int getLength() {
    return value.length();
  }

  /**
   * Returns the element at the specified index in this list. Note:
   * the elements are indexed from 1 to length.<p>
   *
   * Due to performance reasons this should be avoided if not 100%
   * necessary. Please use <code>getCharAt(int index)</code> or
   * <string>getString()</code> for accessing the value of strings.
   *
   * @param index the (one based) index of the element in this list
   * @return the element as a Term
   * @see se.sics.prologbeans.PBString#getLength
   * @see se.sics.prologbeans.PBString#getCharAt
   * @see se.sics.prologbeans.PBString#getString
   */
  public Term getTermAt(int index) {
    return new PBAtomic("" + (int) getCharAt(index), PBAtomic.INTEGER);
  }

  /**
   * Returns the character at the specified index in this
   * string. Note: characters are indexed from 1 to length
   *
   * @param index the (one based) index of the character in this string
   * @return the character
   * @see se.sics.prologbeans.PBString#getLength
   */
  public char getCharAt(int index) {
    int len = value.length();
    if (0 < index && index <= len) {
      return value.charAt(index-1);
    } else if (len == 0) {
      throw new IllegalStateException("not a compound term: " + toString());
    } else {
      throw new IndexOutOfBoundsException("Index: " + index
					  + ", needs to be between 1 and "
					  + len);
    }
  }

  String toPrologString() {
    StringBuffer stuffed = new StringBuffer();
    if (nextTerm == NIL) {
      stuffed.append('\"');
      for (int i = 0, n = value.length(); i < n; i++) {
	char c = value.charAt(i);
	if (c == '\"') {
	  stuffed.append('\\');
	}
	stuffed.append(c);
      }
      stuffed.append('\"');
    } else {
      stuffed.append('[');
      for (int i = 0, n = value.length(); i < n; i++) {
	if (i > 0) stuffed.append(',');
	stuffed.append((int) value.charAt(i));
      }
      stuffed.append('|');
      stuffed.append(nextTerm.toPrologString());
      stuffed.append(']');
    }
    return stuffed.toString();
  }

  public String toString() {
    if (nextTerm == NIL) {
      return value;
    }

    StringBuffer stuffed = new StringBuffer();
    stuffed.append('[');
    for (int i = 0, n = value.length(); i < n; i++) {
      if (i > 0) stuffed.append(',');
      stuffed.append((int) value.charAt(i));
    }
    stuffed.append('|');
    stuffed.append(nextTerm.toString());
    stuffed.append(']');
    return stuffed.toString();
  }

  void fastWrite(FastWriter writer) throws IOException {
    writer.writeString(value, nextTerm);
  }

}
