/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;

/**
 * <code>QueryAnswer</code> is the Java representation of an answer
 * from the Prolog server. The <code>QueryAnswer</code> is returned by
 * {@link se.sics.prologbeans.PrologSession} in response to a query
 * and contains variable bindings, errors, and success/failure
 * information. It also contains the variable bindings specified in
 * the query.
 */
public class QueryAnswer extends Bindings {

  // This term is on one of these forms:
  // - A list of the form "['='(VariableNameAsAtom,Value), ...]" (variable bindings)
  // - The atom "no" (the prolog responded with 'no')
  // - The functor "error(ErrorReason)" (an error occurred)
  private Term answer;
  private boolean hasValues = false;
  private boolean bound = false;

  /**
   * Creates a new <code>QueryAnswer</code> instance with the
   * specified information.
   *
   * @param answer a <code>Term</code> value representing the Prolog response
   * @param bindings the variable bindings for the query to which this
   * is an answer
   */
  public QueryAnswer(Term answer, Bindings bindings) {
    super(bindings);
    this.answer = answer;
    hasValues = answer.isList() && answer instanceof PBList;
  } // QueryAnswer constructor

  /**
   * Returns the value of the specified variable or <code>null</code>
   * if the variable is not bound.
   *
   * @param variable the name of the variable
   * @return the value of the variable as a <code>Term</code> or
   * <code>null</code> if the variable is not bound
   */
  public Term getValue(String variable) {
    if (!bound) {
      if (hasValues) {
	// copy all the new bindings into Bindings
	PBList list = (PBList) answer;
	for (int i = 1, n = list.getLength(); i <= n; i++) {
	  Term bind = list.getTermAt(i);
	  if (bind.getName().equals("=")) {
	    bind(bind.getArgument(1).getName(), bind.getArgument(2));
	  }
	}
      }

      bound = true;
    }
    return super.getValue(variable);
  }

  /**
   * Returns <code>true</code> if the query failed (i.e. the Prolog
   * responded with 'no') and <code>false</code> otherwise.
   */
  public boolean queryFailed() {
    return !hasValues && answer.getName().equals("no");
  }

  /**
   * Returns <code>true</code> if an error occurred while processing
   * the query and <code>false</code> otherwise.
   */
  public boolean isError() {
    return !hasValues && answer.getName().equals("error");
  }

  /**
   * Returns the error reason or <code>null</code> if an error has not
   * occurred or if no error reason is known.
   */
  public String getError() {
    if (answer.getName().equals("error")) {
      return answer.getArgument(1).toString();
    }
    return null;
  }

  /**
   * Returns a string description of this answer.
   */
  public String toString() {
    return answer.toString();
  }

} // QueryAnswer
