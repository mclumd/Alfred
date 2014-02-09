/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;
import java.io.IOException;

/**
 * <code>PBList</code> is the Java representation of Prolog lists.
 */
public class PBList extends PBCompound {

  final static Term NIL = new PBList();

  protected final Term nextTerm;

  private PBList() {
    super("[]", null);
    nextTerm = this;
  }

  PBList(Term[] terms) {
    this(terms, null);
  }

  PBList(Term[] terms, Term nextTerm) {
    this(terms == null ? "[]" : ".", terms, nextTerm);
  }

  PBList(String name, Term[] terms, Term nextTerm) {
    super(name, terms);
    this.nextTerm = nextTerm == null ? NIL : nextTerm;
  }

  public boolean isList() {
    return true;
  }

  /**
   * Returns the first or second argument of this list node. Only
   * non-empty lists have arguments. Note: the arguments are indexed
   * from 1 to 2.<p>
   *
   * Due to performance reasons this should be avoided if not 100%
   * necessary. Please use <code>getTermAt(int index)</code> for
   * accessing the elements of lists.
   *
   * @param index the (one based) index of the argument
   * @return the argument as a Term
   * @throws java.lang.IllegalStateException if this term is not compound
   * @see se.sics.prologbeans.PBList#getTermAt(int)
   */
  public Term getArgument(int index) {
    if (arguments == null) {
      throw new IllegalStateException("not a compound term: " + toString());
    }

    if (index == 1) {
      return arguments[0];
    }

    if (index == 2) {
      if (arguments.length > 1) {
	Term[] newTerms = new Term[arguments.length - 1];
	System.arraycopy(arguments, 1, newTerms, 0, newTerms.length);
	return new PBList(newTerms, nextTerm);
      } else {
	return nextTerm;
      }
    }
    throw new IndexOutOfBoundsException("Index: " + index
					+ ", needs to be between 1 and "
					+ getArity());
  }

  public int getArity() {
    return arguments == null ? 0 : 2;
  }

  /**
   * Returns the length of this list.
   */
  public int getLength() {
    return arguments == null ? 0 : arguments.length;
  }

  /**
   * Returns the element at the specified index in this list. Note:
   * the elements are indexed from 1 to length.
   *
   * @param index the (one based) index of the element in this list
   * @return the element as a Term
   * @see se.sics.prologbeans.PBList#getLength
   */
  // [PM] should document as one-based
  public Term getTermAt(int index) {
    if (arguments == null) {
      throw new IllegalStateException("not a compound term: " + toString());
    }

    if (0 < index && index <= arguments.length) {
      return arguments[index-1];
    } else {
      throw new IndexOutOfBoundsException("Index: " + index
					  + ", needs to be between 1 and "
					  + arguments.length);
    }
  }

  /**
   * Returns the end of this list. For closed lists this element is
   * the empty list.
   */
  public Term getEnd() {
    return nextTerm;
  }

  String toPrologString() {
    StringBuffer sb = new StringBuffer().append('[');
    if (arguments != null) {
      for (int i = 0, n = arguments.length; i < n; i++) {
	if (i > 0) sb.append(',');
	sb.append(arguments[i].toPrologString());
      }
    }
    // Only show last term if not nil!
    if (nextTerm != NIL) {
      sb.append('|').append(nextTerm.toPrologString());
    }
    sb.append(']');
    return sb.toString();
  }

  public String toString() {
    StringBuffer sb = new StringBuffer().append('[');
    if (arguments != null) {
      for (int i = 0, n = arguments.length; i < n; i++) {
	if (i > 0) sb.append(',');
	sb.append(arguments[i].toString());
      }
    }
    // Only show last term if not nil!
    if (nextTerm != NIL) {
      sb.append('|').append(nextTerm.toString());
    }
    sb.append(']');
    return sb.toString();
  }

  void fastWrite(FastWriter writer) throws IOException {
    if (arguments != null) {
      for (int i = 0, n = arguments.length; i < n; i++) {
	writer.writeList();
	arguments[i].fastWrite(writer);
      }
    }
    if (nextTerm != NIL) {
      nextTerm.fastWrite(writer);
    } else {
      writer.writeNIL();
    }
  }

} // PBList
