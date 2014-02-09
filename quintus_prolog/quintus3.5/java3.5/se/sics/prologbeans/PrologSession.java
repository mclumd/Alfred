/**
 * Copyright (c) 2003 SICS AB. All rights reserved.
 */
package se.sics.prologbeans;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.Socket;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.http.HttpSession;

/**
 * <code>PrologSession</code> handles the connection with the Prolog
 * Server. Currently only synchronous connections with the server are
 * supported.
 */
// [PM] FIXME: when Java is closed it should do whatever it takes to
// prevent the Prolog side from blocking forever. Presumably it would
// be enough to close the Java-side socket.
// [JE] Java always close sockets and streams when it closes down.
// * What exactly does "Java is closed" mean?
// [PM] When I close the window for the evaluate demo SICStus will
//      hang (in WriteFile() !!). At this point the Java process has
//      exited so this appears to be more of an OS bug.


public class PrologSession {

//   private static int debugLevel = 0;

//   static {
//     try {
//       debugLevel =
// 	Integer.getInteger("se.sics.prologbeans.debugLevel", 0).intValue();
//     } catch (Exception e) {
//       // Ignore security exceptions in app-servers, etc.
//     }
//   }

//   static boolean debugging() {
//     return debugLevel >= 1;
//   }

//   static boolean debugging(int level) {
//     return debugLevel >= level;
//   }

  private static final int ALWAYS_CLOSE = 1;
  private static final int AUTO_CONNECT = 2;

  private long sendTime = -1L;
  private int timeout = 2000; // Wait for an answer max 2000 millis

  private FastParser parser;
  private String query;

  private InputStream input;
  private FastWriter output;
  private Socket connection;

  private int port = 8066;
  private String host = "localhost";
  private int flags = AUTO_CONNECT; // ALWAYS_CLOSE;

  private PrologSession parentSession;
  private String prologSessionID;
  private static InitialContext initCtx;

  private boolean isAddedToMonitor = false;

  /**
   * Creates a new <code>PrologSession</code> instance with default
   * Prolog server settings.
   */
  public PrologSession() {
    parser = new FastParser();
//      new Monitor(this);
  } // PrologSession constructor

  private PrologSession(PrologSession parent, String sessionID) {
    this.parentSession = parent;
    this.prologSessionID = sessionID;
  } // PrologSession constructor


  /**
   * Sets the session id for this prolog session. If the id is set
   * each query sent to the prolog will include this session id. Note:
   * the session id can only be set once per session and can not be
   * changed.
   *
   * @param id the id of this session
   */
//    public void setSessionID(String id) {
//      if (this.id == null) {
//        this.id = id;
//      } else {
//        throw new IllegalStateException("Can not set session id more than once");
//      }
//    }

  /**
   * Returns the timeout in milliseconds before the connection to the
   * Prolog server is reset (when a query is not answered).
   */
  public int getTimeout() {
    if (parentSession != null) {
      return parentSession.getTimeout();
    }
    return timeout;
  }

  /**
   * Sets the timeout in milliseconds before the connection to the
   * Prolog server is reset (when a query is not answered). Setting
   * the timeout to <code>0</code> will disable timeouts for this
   * prolog session. Default is 2000 milliseconds.
   *
   * @param timeout <code>int</code> timeout in milliseconds or
   * <code>0</code> to disable timeouts
   */
  public void setTimeout(int timeout) {
    if (parentSession != null) {
      parentSession.setTimeout(timeout);
    } else {
      this.timeout = timeout;
    }
  }

  /**
   * Returns the <code>PrologSession</code> registered in JNDI with
   * the given name. Use this method in application servers where
   * services are registered using JNDI. Please note: the application
   * server must be configured to register the
   * <code>PrologSession</code> with the given name for this method to
   * work.
   *
   * @param name the name of the prolog session
   * @return the named prolog session or <code>null</code> if no such
   * session could be found
   */
  public static PrologSession getPrologSession(String name) {
    try {
      if (initCtx == null) {
	initCtx = new InitialContext();
      }
      Context envCtx = (Context) initCtx.lookup("java:comp/env");
//        System.out.println("Looking up session: " + name +  " in " + envCtx);
      return (PrologSession) envCtx.lookup(name);
    } catch (Exception e) {
      e.printStackTrace();
    }
    return null;
  }

  /**
   * Returns the <code>PrologSession</code> registered in JNDI with
   * the given name. The <code>PrologSession</code> will make use of
   * sessions and the session id will be the same as in the
   * <code>HTTPSession</code>. Use this method in web application
   * servers with support for servlets and <code>HTTPSession</code>
   * (and when support for sessions is desired).
   * Note: This will cause the <code>PrologSession</code> to include
   * the session id in its queries.
   *
   * @param name the name of the prolog session
   * @param httpSession the http session
   * @return the named prolog session
   */
  public static PrologSession getPrologSession(String name,
					       HttpSession httpSession) {
    Object object = httpSession.getAttribute("prologbeans.session");
    if (object == null) {
      //System.out.println("Creating new session!!!");
      PrologSession session = new PrologSession(getPrologSession(name),
						httpSession.getId());
      httpSession.setAttribute("prologbeans.session", new AppSession(session));
      return session;
    } else {
      //System.out.println("Reusing old session:" + object);
      return ((AppSession) object).getPrologSession();
    }
  }

  void endSession() {
    if (prologSessionID != null) {
      sendAtom("end_session", prologSessionID);
    }
  }

  /**
   * Returns the port of the Prolog server.
   */
  public int getPort() {
    if (parentSession != null) {
      return parentSession.getPort();
    }
    return port;
  }

  /**
   * Sets the port of the Prolog server (default <code>8066</code>).
   *
   * @param prologServerPort the port of the Prolog server
   */
  public void setPort(int prologServerPort) {
    if (parentSession != null) {
      parentSession.setPort(prologServerPort);
    } else {
      this.port = prologServerPort;
    }
  }

  /**
   * Returns the host of the Prolog server (exactly as registered in
   * <code>setHost</code>).
   */
  public String getHost() {
    if (parentSession != null) {
      return parentSession.getHost();
    }
    return host;
  }

  /**
   * Sets the host of the Prolog server (default is
   * <code>localhost</code>). The host can be specified as either
   * IP-address or host name.
   *
   * @param prologServerHost the host as an IP-address or host name
   */
  public void setHost(String prologServerHost) {
    if (parentSession != null) {
      parentSession.setHost(prologServerHost);
    } else {
      this.host = prologServerHost;
    }
  }

  public boolean isAlwaysClosing() {
    if (parentSession != null) {
      return parentSession.isAlwaysClosing();
    }
    return (flags & ALWAYS_CLOSE) != 0;
  }

  public void setAlwaysClose(boolean close) {
    if (parentSession != null) {
      parentSession.setAlwaysClose(close);
    } else if (close) {
      flags = flags | ALWAYS_CLOSE;
    } else {
      flags = flags & ~ALWAYS_CLOSE;
    }
  }

  /**
   * Sets the connection mode of this <code>PrologSession</code>. If
   * set to <code>true</code> it will ensure that it is connected to
   * the Prolog server as soon as a call to <code>executeQuery</code>
   * or anything else causing a need for communication happens. This
   * is by default set to <code>true</code>.
   */
  public void setAutoConnect(boolean autoConnect) {
    if (parentSession != null) {
      parentSession.setAutoConnect(autoConnect);
    } else if (autoConnect) {
      flags = flags | AUTO_CONNECT;
    } else {
      flags = flags & ~AUTO_CONNECT;
    }
  }

  /**
   * Returns the state of the auto connect mode.
   * @see se.sics.prologbeans.PrologSession#setAutoConnect
   */
  public boolean isAutoConnecting() {
    if (parentSession != null) {
      return parentSession.isAutoConnecting();
    }
    return (flags & AUTO_CONNECT) != 0;
  }

  /**
   * Sends a query to the Prolog server and waits for the answer
   * before returning the <code>QueryAnswer</code>. Anonymous
   * variables (underscore, <code>_</code>), will be ignored, and thus
   * not accessible in the <code>QueryAnswer</code>.
   * <code>executeQuery</code> throws <code>IOException</code> if
   * communication problems with the server occurs. Please note:
   * <code>executeQuery</code> will only return one answer.
   *
   * @param query the query to send to the prolog server
   * @return the answer from the prolog server
   * @throws IOException if an error occurs
   */
  public QueryAnswer executeQuery(String query) throws IOException {
    return new QueryAnswer(send(query, null, prologSessionID), null);
  }

  /**
   * Sends a query to the Prolog server and waits for the answer
   * before returning the
   * <code>QueryAnswer</code>. <code>Bindings</code> are variable
   * bindings for the given query and will ensure that the values are
   * stuffed correctly.<p>
   *
   * An example:<br>
   * <code>QueryAnswer answer = executeQuery("evaluate(In,Out)",
   *                                  new Bindings().bind("In","4*9."));
   * </code>
   *
   * @param query the query to send to the prolog server
   * @param bindings the variable bindings to use in the query
   * @return the answer from the prolog server
   * @throws IOException if an error occurs
   */
  public QueryAnswer executeQuery(String query, Bindings bindings)
    throws IOException
  {
    return new QueryAnswer(send(query, bindings, prologSessionID), bindings);
  }

  /**
   * Sends a query to the Prolog server and waits for the answer
   * before returning the
   * <code>QueryAnswer</code>. <code>Bindings</code> are variable
   * bindings for the given query and will ensure that the values are
   * stuffed correctly.
   *
   * @param query the query to send to the prolog server
   * @param bindings the variable bindings to use in the query
   * @param sessionID the session id to give to the prolog server
   * @return the answer from the prolog server
   * @throws IOException if an error occurs
   */
  public QueryAnswer executeQuery(String query, Bindings bindings,
				  String sessionID) throws IOException {
    return new QueryAnswer(send(query, bindings, sessionID), bindings);
  }


  private synchronized Term send(String query, Bindings bindings,
				 String sessionID) throws IOException {
    if (parentSession != null) {
      return parentSession.send(query, bindings, sessionID);
    }
    try {
      initSend();

      int len = sessionID == null ? 2 : 3;

      // Write a fastrw term
//       output.write(FastParser.VERSION);
//       output.write(FastParser.COMPOUND);
//       output.write("query".getBytes());
//       output.write(0);
//       output.write(len);
      output.writeCompound("query", len);
//       PBString.fastWrite(output, query + ".");
      // [PD] Quintus 3.5; read in Quintus can be confused unless there
      //                   is whitespace after the full stop.
      //output.writeString(query + ".");
      output.writeString(query + ". ");
      if (bindings == null) {
	PBList.NIL.fastWrite(output);
      } else {
	bindings.fastWrite(output);
      }
      if (sessionID != null) {
// 	PBAtomic.fastrwWrite(output, PBAtomic.ATOM, sessionID);
	output.writeAtom(sessionID);
      }
      output.commit();
      return parser.parseProlog(input);

    } catch (IOException e) {
      close();
      throw e;

    } finally {
      finishSend();
    }
  }

  private synchronized Term sendAtom(String commandName, String argument) {
    if (parentSession != null) {
      return parentSession.sendAtom(commandName, argument);
    }

    try {
      initSend();

      // Write a fastrw term
//       output.write(FastParser.VERSION);
//       output.write(FastParser.COMPOUND);
//       output.write(commandName.getBytes());
//       output.write(0);
//       output.write(1);
//       PBAtomic.fastrwWrite(output, PBAtomic.ATOM, argument);
//       output.flush();
      output.writeCompound(commandName, 1);
      output.writeAtom(argument);
      output.commit();
      return parser.parseProlog(input);

    } catch (IOException e) {
      e.printStackTrace();
      close();
      return null;

    } finally {
      finishSend();
    }
  }

  private void initSend() throws IOException {
    if ((flags & AUTO_CONNECT) != 0) {
      connectToServer();
    }
    if (output == null) {
      throw new IOException("no connection to Prolog Server");
    }

    sendTime = System.currentTimeMillis();
    if (timeout > 0) {
      PBMonitor.getDefault().queryStarted(this);
      isAddedToMonitor = true;
    }
  }

  private void finishSend() {
    sendTime = -1L;
    if (isAddedToMonitor) {
      PBMonitor.getDefault().queryFinished(this);
      isAddedToMonitor = false;
    }
    if ((flags & ALWAYS_CLOSE) > 0) {
      close();
    }
  }

  /**
   * Connects to the Prolog server. By default
   * <code>executeQuery</code> will automatically connect to the
   * server when called.
   */
  public void connect() throws IOException {
    if (parentSession != null) {
      parentSession.connect();
    } else {
      connectToServer();
    }
  }

  private void connectToServer() throws IOException {
    if (connection == null) {
      Socket connection = new Socket(host, port);
      output = new FastWriter(connection.getOutputStream());
      input = new BufferedInputStream(connection.getInputStream());
      this.connection = connection;
    }
  }

  /**
   * Returns <code>true</code> if a connection with the Prolog server
   * is open and <code>false</code> otherwise.
   */
  public boolean isConnected() {
    if (parentSession != null) {
      return parentSession.isConnected();
    }
    return connection != null;
  }

  /**
   * Closes the connection with the Prolog server. The connection can
   * be opened again with <code>connect</code>.
   */
  public void disconnect() {
    if (parentSession != null) {
      parentSession.close();
    } else {
      close();
    }
  }

  // Close connection when things have gone wrong...
  private void close() {
    // System.out.println("Closing Connection...");
    try {
      sendTime = -1L;
      if (output != null) {
	output.close();
	output = null;
      }
      if (input != null) {
	input.close();
	input = null;
      }
      if (connection != null) {
	connection.close();
	connection = null;
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }


  // -------------------------------------------------------------------
  // API towards PBMonitor.
  // The monitor is used to supervise and cancel prolog queries that
  // takes too long time.
  // -------------------------------------------------------------------

  long getQueryStartTime() {
    return sendTime;
  }

  void cancelQuery() {
    isAddedToMonitor = false;
    if (sendTime != -1L) {
      close();
    }
  }

} // PrologSession
