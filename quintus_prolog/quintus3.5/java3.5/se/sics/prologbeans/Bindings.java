/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;
import java.io.IOException;
import java.util.Enumeration;
import java.util.Hashtable;

/**
 * <code>Bindings</code> handles the variable bindings in the
 * communication with the prolog server. Using variable bindings
 * ensures that the values are properly quoted when sent to the
 * prolog server.
 */
public class Bindings {

  private Hashtable bindings;

  /**
   * Creates a new <code>Bindings</code> instance with no variable bindings.
   */
  public Bindings() {
  }

  /**
   * Creates a new <code>Bindings</code> instance and copies all existing
   * variable bindings from the specified bindings.
   *
   * @param binds the variable bindings to copy
   */
  public Bindings(Bindings binds) {
    if (binds != null && binds.bindings != null) {
      bindings = (Hashtable) binds.bindings.clone();
    }
  }

  /**
   * Adds the specified variable binding. The variable name must start
   * with an upper case letter or '_'.
   *
   * @param name a prolog variable name
   * @param value the value to bind to the variable
   * @return a reference to this <code>Bindings</code> object
   * @throws java.lang.IllegalArgumentException if the name is not a
   * valid prolog variable name
   */
  public Bindings bind(String name, int value) {
    checkVar(name);
    bindings.put(name, new PBAtomic("" + value, PBAtomic.INTEGER));
    return this;
  }

  /**
   * Adds the specified variable binding. The variable name must start
   * with an upper case letter or '_'.
   *
   * @param name a prolog variable name
   * @param value the value to bind to the variable
   * @return a reference to this <code>Bindings</code> object
   * @throws java.lang.IllegalArgumentException if the name is not a
   * valid prolog variable name
   */
  public Bindings bind(String name, long value) {
    checkVar(name);
    bindings.put(name, new PBAtomic("" + value, PBAtomic.INTEGER));
    return this;
  }

  /**
   * Adds the specified variable binding. The variable name must start
   * with an upper case letter or '_'.
   *
   * @param name a prolog variable name
   * @param value the value to bind to the variable
   * @return a reference to this <code>Bindings</code> object
   * @throws java.lang.IllegalArgumentException if the name is not a
   * valid prolog variable name
   */
  public Bindings bind(String name, float value) {
    checkVar(name);
    bindings.put(name, new PBAtomic("" + value, PBAtomic.FLOAT));
    return this;
  }

  /**
   * Adds the specified variable binding. The variable name must start
   * with an upper case letter or '_'.
   *
   * @param name a prolog variable name
   * @param value the value to bind to the variable
   * @return a reference to this <code>Bindings</code> object
   * @throws java.lang.IllegalArgumentException if the name is not a
   * valid prolog variable name
   */
  public Bindings bind(String name, double value) {
    checkVar(name);
    bindings.put(name, new PBAtomic("" + value, PBAtomic.FLOAT));
    return this;
  }

  /**
   * Adds the specified variable binding. The variable name must start
   * with an upper case letter or '_'.
   *
   * @param name a prolog variable name
   * @param value the value to bind to the variable
   * @return a reference to this <code>Bindings</code> object
   * @throws java.lang.IllegalArgumentException if the name is not a
   * valid prolog variable name
   */
  public Bindings bind(String name, String value) {
    checkVar(name);
    bindings.put(name, new PBString(value));
    return this;
  }

  /**
   * Adds the specified variable binding. The variable name must start
   * with an upper case letter or '_'.
   *
   * @param name a prolog variable name
   * @param value the value to bind to the variable
   * @return a reference to this <code>Bindings</code> object
   * @throws java.lang.IllegalArgumentException if the name is not a
   * valid prolog variable name
   */
  public Bindings bind(String name, Term value) {
    checkVar(name);
    bindings.put(name, value);
    return this;
  }

  /**
   * Adds the specified variable binding. The variable name must start
   * with an upper case letter or '_'. The value will be bound as an
   * atom.
   *
   * @param name a prolog variable name
   * @param value the value to bind to the variable as an atom
   * @return a reference to this <code>Bindings</code> object
   * @throws java.lang.IllegalArgumentException if the name is not a
   * valid prolog variable name
   */
  public Bindings bindAtom(String name, String value) {
    checkVar(name);
    bindings.put(name, new PBAtomic(value, PBAtomic.ATOM));
    return this;
  }

  private void checkVar(String name) {
    char c = name.charAt(0);
    if (!Character.isUpperCase(c) && c != '_' || "_".equals(name)) {
      throw new IllegalArgumentException("Variable names must start with uppercase letter or '_' : " + name);
    }
    if (bindings == null) {
      bindings = new Hashtable();
    }
  }

  /**
   * Returns the value for the specified variable or <code>null</code>
   * if the variable is not bound.
   *
   * @param name the name of the variable
   * @return the value of the variable as a <code>Term</code> or
   * <code>null</code> if the variable is not bound
   */
  public Term getValue(String name) {
    if (bindings != null) {
      return (Term) bindings.get(name);
    }
    return null;
  }

  public String toString() {
    Enumeration keys = bindings.keys();
    StringBuffer buffer = new StringBuffer();
    buffer.append('[');
    String key = null;
    while (keys.hasMoreElements()) {
      if (key != null) {
	buffer.append(',');
      }
      key = (String) keys.nextElement();
      Term value = (Term) bindings.get(key);
      buffer.append(key).append('=').append(value.toPrologString());
    }
    buffer.append(']');
    return buffer.toString();
  }

  void fastWrite(FastWriter writer) throws IOException {
    Enumeration keys = bindings.keys();
    StringBuffer buffer = new StringBuffer();
    String key = null;
    while (keys.hasMoreElements()) {
      key = (String) keys.nextElement();
      Term value = (Term) bindings.get(key);
      writer.writeList();
      writer.writeCompound("=", 2);
//       stream.write(FastParser.LIST);
//       stream.write(FastParser.COMPOUND);
//       stream.write('=');
//       stream.write(0);
//       stream.write(2);
      // Arg 1
      writer.writeAtom(key);
//       stream.write(FastParser.ATOM);
//       stream.write(key.getBytes());
//       stream.write(0);
      // Arg 2
      value.fastWrite(writer);
    }
    writer.writeNIL();
//     stream.write(FastParser.NIL);
  }

//   public static void main(String[] args) {
//     try {
//       Bindings b = new Bindings().bind("T", "pest");
//       b.bind("Int",4711);
//       b.bind("List", new PBList(new Term[] {new Atom("e1",Atom.ATOM)}));
//       java.io.OutputStream out =
// 	new java.io.FileOutputStream("testbind.txt");
//       out.write(FastParser.VERSION);
//       b.fastrwWrite(out);
//       System.out.flush();
//     } catch (IOException e) {
//       e.printStackTrace();
//     }
//   }
}
