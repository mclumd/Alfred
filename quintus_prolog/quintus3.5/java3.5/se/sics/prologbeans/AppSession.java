/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;
import javax.servlet.http.HttpSessionBindingEvent;
import javax.servlet.http.HttpSessionBindingListener;

/**
 * <code>AppSession</code>
 */
public class AppSession implements HttpSessionBindingListener {

  private PrologSession session;

  public AppSession(PrologSession session) {
    this.session = session;
  } // AppSession constructor

  public PrologSession getPrologSession() {
    return session;
  }

  public void valueBound(HttpSessionBindingEvent event) {
//     System.out.println("Value bound:" + event.getName() + " = " +
// 		       event.getValue());
  }

  public void valueUnbound(HttpSessionBindingEvent event) {
//     System.out.println("Value unbound:" + event.getName() + " = " +
// 		       event.getValue());
    if ("prologbeans.session".equals(event.getName())) {
      session.endSession();
    }
  }

} // AppSession
