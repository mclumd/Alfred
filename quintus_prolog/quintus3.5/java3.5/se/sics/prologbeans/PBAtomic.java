/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;
import java.io.IOException;

/**
 * <code>PBAtomic</code> is the Java representation of Prolog constants
 * and variables.
 */

public class PBAtomic extends Term {

  final static int ATOM = 1;
  final static int INTEGER = 2;
  final static int FLOAT = 3;
  final static int VARIABLE = 4;

  private final int type;

  /**
   * Creates a new <code>PBAtomic</code> instance with the specified name
   * and of the specified Prolog type (integer, floating-point number,
   * atom, or variable).
   */
  PBAtomic(String name, int type) {
    super(name);
    this.type = type;
  }

  int getType() {
    return type;
  }

  public boolean isAtom() {
    return type == ATOM;
  }

  public boolean isInteger() {
    return type == INTEGER;
  }

  public boolean isFloat() {
    return type == FLOAT;
  }

  public boolean isAtomic() {
    return type != VARIABLE;
  }

  public boolean isVariable() {
    return type == VARIABLE;
  }

  public int intValue() {
    if (type == INTEGER) {
      return Integer.parseInt(name);
    } else {
      throw new IllegalStateException("not an integer: " + name);
    }
  }

  public long longValue() {
    if (type == INTEGER) {
      return Long.parseLong(name);
    } else {
      throw new IllegalStateException("not an integer: " + name);
    }
  }

  public float floatValue() {
    if (type == FLOAT || type == INTEGER) {
      return Float.parseFloat(name);
    } else {
      throw new IllegalStateException("not a number: " + name);
    }
  }

  public double doubleValue() {
    if (type == FLOAT || type == INTEGER) {
      return Double.parseDouble(name);
    } else {
      throw new IllegalStateException("not a number: " + name);
    }
  }

  String toPrologString() {
    if (type != ATOM) {
      return name;
    }
    return stuffAtom(name);
  }

  public String toString() {
    return name;
  }

  void fastWrite(FastWriter writer) throws IOException {
    writer.writeAtomic(this);
  }

} // PBAtomic
