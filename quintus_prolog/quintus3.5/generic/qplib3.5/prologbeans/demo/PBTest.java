/**
 * PBTest.java
 *
 *
 * Created: Tue Oct 07 17:39:39 2003
 *
 * @Author  : Joakim Eriksson & Niclas Finne
 * @version 1.0
 */
import se.sics.prologbeans.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;

public class PBTest implements Runnable {
  private static int error = 0;
  private int port = -1;
  private Process process;
  private boolean isShutdown = false;

  public void run() {
    try {
      String prolog = System.getProperty("se.sics.prologbeans.prolog",
					  "prolog");
      // [PD] This is portable (i.e. works both for SICStus and Quintus)
      // [PD] Correction: not quite portabel. SICStus does not have +l.
      //      SICStus has -l instead. Sigh.
      /* if QUINTUS */
      String command = prolog + " +l pbtest_run";
      /* endif QUINTUS */
      /* if SICSTUS
      String command = prolog + " -l pbtest_run";
      /* endif SICSTUS */
      System.err.println("DBG: Launching Prolog with \"" + command + "\"");
      // Load and start the SICStus Prolog example
      process = Runtime.getRuntime().exec(command);

      // Write all the error output that has no % in the start of the line
      BufferedReader err =
	new BufferedReader(new InputStreamReader(process.getErrorStream()));
      String line;
      while((line = err.readLine()) != null) {
	if (line.length() > 0 && line.charAt(0) != '%') {
	  System.err.println(line);

	  // When port is found, set it and notify that SICStus is running!
	  if (line.startsWith("port:")) {
	    port = Integer.parseInt(line.substring(5)); // e.g, port:4711
	    synchronized(this) {
	      notify();
	    }
	  }
	}
      }
    } catch (Exception e) {
      e.printStackTrace();
      port = -2;
    } finally {
      synchronized(this) {
	isShutdown = true;
	notify();
      }
    }
  }

  public synchronized int getPort() throws InterruptedException {
    // Get the port from the running PBtest server (if not received within
    // 10 seconds, -1 will be returned.
    if (port == -1) {
      wait(10000);
    }
    return port;
  }

  public synchronized boolean waitForShutdown() throws InterruptedException {
    // Wait at most 10 seconds for the Prolog Server to shutdown
    if (!isShutdown) {
      wait(10000);
    }
    return isShutdown;
  }

  public void shutdown() {
    process.destroy();
  }

  public static void main(String[] args) throws Exception {
    // Startup the prolog and show its err output!
    int test = 1;
    PrologSession session = null;
    PBTest evalTest = new PBTest();
    try {
      Thread t = new Thread(evalTest);
      t.setDaemon(true);
      t.start();

      // Get the port from the SICStus process (and fail if port is an error value)
      int port = evalTest.getPort();
      if (port <= 0) {
	fail("could not start prolog", test);
      }

      session = new PrologSession();
      session.setPort(port);
      if ((Integer.getInteger("se.sics.prologbeans.debug", 0)).intValue() != 0) {
	  session.setTimeout(0);
      }

      // Test 1. - evaluation!
      Bindings bindings = new Bindings().bind("E", "10+20.");
      QueryAnswer answer =
	session.executeQuery("evaluate(E,R)", bindings);
      Term result = answer.getValue("R");
      if (result != null) {
	if (result.intValue() == 30) {
	  success("10+20=" + result, test++);
	} else {
	  fail("Execution failed: " + result, test);
	}
      } else {
	fail("Error " + answer.getError(), test);
      }

      // Test 2 - list reverse!
      bindings = new Bindings().bind("E", "reverse");
      answer = session.executeQuery("reverse(E,R)", bindings);
      result = answer.getValue("R");
      if (result != null) {
	if ("esrever".equals(result.toString())) {
	  success("rev(reverse) -> " + result, test++);
	} else {
	  fail("Execution failed: " + result, test);
	}
      } else {
	fail("Error " + answer.getError(), test);
      }

      // Test 3 - show developers
      answer = session.executeQuery("developers(Dev)");
      result = answer.getValue("Dev");
      if (result != null) {
	if (result.isList() && result instanceof PBList) {
	  // Fast access to lists via PBList!!!
	  PBList list = (PBList) result;
	  if (list.getLength() == 3 &&
	      "Joakim".equals(list.getTermAt(1).toString()) &&
	      "Niclas".equals(list.getTermAt(2).toString()) &&
	      "Per".equals(list.getTermAt(3).toString())) {
	    success("developers -> " + result, test++);
	  } else {
	    fail("Execution failed: " + result, test);
	  }
	} else {
	  fail("Execution failed: " + result, test);
	}
      } else {
	fail("Error " + answer.getError(), test);
      }

      // Test 4. shutdown server...
      session.executeQuery("shutdown");
      if (!evalTest.waitForShutdown()) {
	fail("shutdown", test++);
      } else {
	success("shutdown", test++);
      }
    } catch (Throwable e) {
      if (error == 0) {
	e.printStackTrace();
	fail("Error " + e.getMessage(), test);
      }
    } finally {
      if (session != null) {
	session.disconnect();
      }
      evalTest.shutdown();
      System.exit(error);
    }
  }

  private static void fail(String msg, int test) {
    System.err.println("Execution failed: " + msg + " for test " + test);
    error = 1;
    throw new RuntimeException("");
  }

  private static void success(String msg, int test) {
    System.out.println("Test " + test + " succeded: " + msg);
  }

} // PBTest
