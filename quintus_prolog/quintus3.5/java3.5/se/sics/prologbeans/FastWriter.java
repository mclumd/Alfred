/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */

package se.sics.prologbeans;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Hashtable;

/**
 * <code>FastWriter</code>
 */
class FastWriter {

  private OutputStream output;
  private boolean isWritingTerm = false;
  private Hashtable variableTable = null;

  public FastWriter(OutputStream output) {
    this.output = output;
  } // FastWriter constructor

  private void initOutput() throws IOException {
    if (!isWritingTerm) {
      isWritingTerm = true;
      output.write(FastParser.VERSION);
    }
  }

  public void writeCompound(String name, int arguments) throws IOException {
    initOutput();
    output.write(FastParser.COMPOUND);
    output.write(name.getBytes());
    output.write(0);
    output.write(arguments);
  }

  public void writeList() throws IOException {
    initOutput();
    output.write(FastParser.LIST);
  }

  public void writeNIL() throws IOException {
    initOutput();
    output.write(FastParser.NIL);
  }

  public void writeString(String value) throws IOException {
    initOutput();
    output.write(FastParser.STRING);
    output.write(value.getBytes());
    output.write(0);
    output.write(FastParser.NIL);
  }

  public void writeString(String value, Term nextTerm) throws IOException {
    initOutput();
    output.write(FastParser.STRING);
    output.write(value.getBytes());
    output.write(0);
    if (nextTerm != PBList.NIL) {
      nextTerm.fastWrite(this);
    } else {
      output.write(FastParser.NIL);
    }
  }

  public void writeAtom(String value) throws IOException {
    initOutput();
    output.write(FastParser.ATOM);
    output.write(value.getBytes());
    output.write(0);
  }

  public void writeAtomic(PBAtomic atomic) throws IOException {
    initOutput();

    int type = atomic.getType();
    switch(type) {
    case PBAtomic.ATOM:
      output.write(FastParser.ATOM);
      break;
    case PBAtomic.FLOAT:
      output.write(FastParser.FLOAT);
      break;
    case PBAtomic.INTEGER:
      output.write(FastParser.INTEGER);
      break;
    case PBAtomic.VARIABLE:
      output.write(FastParser.VARIABLE);
      break;
    }
    if (type != PBAtomic.VARIABLE) {
      output.write(atomic.getName().getBytes());
      output.write(0);
    } else {
      if (variableTable == null) {
	variableTable = new Hashtable();
      }

      String variableName = (String) variableTable.get(atomic);
      if (variableName == null) {
	variableName = "" + '_' + variableTable.size();
	variableTable.put(atomic, variableName);
      }
      output.write(variableName.getBytes());
      output.write(0);
    }
  }

  public void commit() throws IOException {
    output.flush();
    isWritingTerm = false;
    if (variableTable != null) {
      variableTable.clear();
    }
  }

  public void close() throws IOException {
    commit();
    this.output.close();
  }

} // FastWriter
