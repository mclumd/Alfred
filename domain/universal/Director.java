import java.io.*;
import java.util.*;
import java.net.*;
import javax.swing.*;

/**
 * For each domain, there is a socket for it.
 * Receives commands from the {@link CommandParser} and sends them to the appropriate domain via TCP sockets.
 * Messages from the domains are sent back to the {@link CommandParser}.
 * <p>
 * Creates a {@link MyComponent}.
 * @author mayo
 * @version October 20, 2006
 */

public class Director extends Thread{
	private String alfredBase = null;
	private Socket hseSocket = null;
	private Socket trainSocket = null;
	private Socket planeSocket = null;
	private Socket draSocket = null;
	private Socket restSocket = null;
	private Socket emailSocket = null;
	private Socket chessSocket = null;
	private Socket movieSocket = null;
	private MyComponent comp = new MyComponent();
	
	Director(String in){
	    alfredBase = in;
		
	}
	
	/**
	 * Precondition: Universal GUI is not visible.
	 * <p>
	 * Postcondition: Universal GUI is visible.
	 */
	public void show(){
		comp.init();
	}
	
	/**
	 * Precondition: Universal GUI is visible.
	 * <p>
	 * Postcondition: Universal GUI is not visible.
	 *
	 */
	public void hide(){
		comp.hideFrame();
	}
	
	/**
	 * Precondition: 0 or more domains are open.
	 * <p>
	 * Postcondition: Closes all open sockets and terminates those domains.
	 * If no domain is open, no sockets are closed.
	 */
	public void closeAll(){

		String s = "";
		try{
			if(hseSocket != null){
				hseSocket.close();
				s = "House";
			}
			if(trainSocket != null){
				trainSocket.close();
				s = "Train";
			}
			if(planeSocket != null){
				planeSocket.close();
				s = "Plane";
			}
			if(draSocket != null){
				draSocket.close();
				s = "Draughts";
			}
			if(restSocket != null){
				restSocket.close();
				s = "Restaurant";
			}
			if(emailSocket != null){
				emailSocket.close();
				s = "Email";
			}
			if(chessSocket != null){
				chessSocket.close();
				s = "Chess";
			}
			if(movieSocket != null){
				movieSocket.close();
				s = "Movies";
			}
		}
		catch(Exception e){
			System.out.println("Could not close the socket: "+s);
			e.printStackTrace();
		}
	}
	
	/**
	 * Precondition: Socket is open to the intended domain.
	 * <p>
	 * Postcondition: Command is sent to the intended domain.  
	 * Domain executes the command that is receives.
	 * @param cmd command from the CommandParser which is then sent to the domain that it is
	 * intended for.
	 * @return returns a string representing an utterance from a domain.
	 */
	public String runline(String cmd){
	    String fromDomain = null;
		StringTokenizer tok = new StringTokenizer(cmd, " [],");

		String first = tok.nextToken();

		//System.out.println("Domain: " + cmd);
		

		if(first.equals("house")){
		
		    if(hseSocket == null || hseSocket.isClosed())
			{
			    System.out.println("House domain is not open");
			    return null;
			}
			try {
				PrintWriter hOut = new PrintWriter(hseSocket.getOutputStream(),
						true);
				String thecmd = new String(cmd.substring(8, (cmd.length())));

				thecmd.trim();
				thecmd = "["+thecmd;

				hOut.println(thecmd);

			//	System.out.println("ran: " + thecmd);
				hOut.flush();

				readFromSocket(hseSocket);
			} catch (IOException e) {
				System.out.println("Socket output stream error.");
				e.printStackTrace();
			}
			catch(Exception e){
				System.out.println("something stupid happened.");
				e.printStackTrace();
			}
		}
		else if(first.equals("trains")){
			
		    if(trainSocket == null || trainSocket.isClosed())
			{
			    System.out.println("Trains domain is not open");
			    return null;
			}
			try{
				PrintWriter pw = new PrintWriter(trainSocket.getOutputStream(), true);
				String theCmd = new String(cmd.substring(9, (cmd.length())));
			
				theCmd.trim();
				theCmd = "["+theCmd;
				
				pw.println(theCmd);
				pw.flush();

				try {
				    sleep(10000);
				} catch (Exception e) {
				    System.out.println("Interupted Exception: " + e);
				    e.printStackTrace();
				}

				fromDomain = readFromSocket(trainSocket);
				System.out.println("ran in trains: "+theCmd);
				System.out.println("fromDomain: "+fromDomain);
			} catch (Exception e){
				System.out.println("something stupid happened.");
				e.printStackTrace();
			}
		}
		else if(first.equals("planes")){
			
		    if(planeSocket == null || planeSocket.isClosed())
			{
			    System.out.println("Planes domain is not open");
			    return null;
			}
			try{
				PrintWriter pw = new PrintWriter(planeSocket.getOutputStream(), true);
				String theCmd = new String(cmd.substring(9, (cmd.length()-1)));

				theCmd.trim();
				theCmd = "["+theCmd;

				pw.println(theCmd);
				pw.flush();
//PrintWriter writer = new PrintWriter("thecommand.txt", "UTF-8");
//writer.println(theCmd);
//writer.close();
				try {
				    sleep(10000);
				} catch (Exception e) {
				    System.out.println("Interrupted Exception: " + e);
				    e.printStackTrace();
				}

				fromDomain = readFromSocket(planeSocket);
				System.out.println("ran in planes: "+theCmd);
				System.out.println("fromDomain: "+fromDomain);
			} catch (Exception e){
				System.out.println("something stupid happened.");
				e.printStackTrace();
			}
		}
		else if(first.equals("draughts")){
			//System.out.println("in draughts commandline");
			
			if(draSocket == null || draSocket.isClosed())
			    {
				System.out.println("Draughts domain is not open");
				return null;  //should return the string above
			    }
			try{
				PrintWriter pw = new PrintWriter(draSocket.getOutputStream(), true);
				String theCmd = new String(cmd.substring(11, (cmd.length())));
			
				theCmd.trim();
				theCmd = "["+theCmd;
			//	System.out.println("sent "+theCmd+" to the draughts socket");
			
				pw.println(theCmd);
				pw.flush();
				
				readFromSocket(draSocket);
			//	System.out.println("ran in draughts: "+theCmd);
			
			} catch (Exception e){
				System.out.println("something stupid happened.");
				e.printStackTrace();
			}
		}
		else if(first.equals("chess")){	

		    if(chessSocket == null || chessSocket.isClosed())
			{
			    System.out.println("Chess domain is not open");
			    return null;
			}
			try{
				PrintWriter pw = new PrintWriter(chessSocket.getOutputStream(), true);
				String theCmd = new String(cmd.substring(8, (cmd.length())));
				
				theCmd.trim();
				theCmd = "["+theCmd;
				
				pw.println(theCmd);
				pw.flush();

				readFromSocket(chessSocket);
			//	System.out.println("ran in chess: "+theCmd);
				
			} catch (Exception e){
				System.out.println("something stupid happened.");
				e.printStackTrace();
			}
		}
		else if(first.equals("restaurant")){
		    
		    if(restSocket == null || restSocket.isClosed())
			{
			    System.out.println("Restaurant domain is not open");
			    return null;
			}
			
			try{
				PrintWriter pw = new PrintWriter(restSocket.getOutputStream(), true);
				String theCmd = new String(cmd.substring(13, (cmd.length())));
				
				theCmd.trim();
				theCmd = "["+theCmd;

				pw.println(theCmd);
				pw.flush();

				readFromSocket(restSocket);
			//	System.out.println("ran in restaurant: "+theCmd);
				
			} catch (Exception e){
				System.out.println("something stupid happened.");
				e.printStackTrace();
			}

		}
		else if(first.equals("popkorn")){
		    if(emailSocket == null || emailSocket.isClosed())
			{
			    System.out.println("Email domain is not open");
			    return null;
			}
			try{
				PrintWriter pw = new PrintWriter(emailSocket.getOutputStream(), true);
				String theCmd = new String(cmd.substring(10, (cmd.length())));
				
				theCmd.trim();
				theCmd = "["+theCmd;
				
				pw.println(theCmd);
				pw.flush();

				readFromSocket(emailSocket);
			//	System.out.println("ran in email: "+theCmd);
				
			} catch (Exception e){
				System.out.println("something stupid happened.");
				e.printStackTrace();
			}
		}
		else if(first.equals("movies")){
		    if(movieSocket == null || movieSocket.isClosed())
			{
			    System.out.println("Movie socket is not open");
			    return null;
			}
			try{
				PrintWriter pw = new PrintWriter(movieSocket.getOutputStream(), true);
				String theCmd = new String(cmd.substring(9, (cmd.length())));
				
				theCmd.trim();
				theCmd = "["+theCmd;
				
				pw.println(theCmd);
				pw.flush();
				
				readFromSocket(movieSocket);
			//	System.out.println("ran in movie: "+theCmd);
				
			} catch (Exception e){
				System.out.println("something stupid happened.");
				e.printStackTrace();
			}
		}
		else {
			System.out.println("Invalid command..Try again.");
			return null;
		}
		return fromDomain;
	}
	
	/**
	 * Precondition: 0 or more domains are running, and the socket of the desired domain
	 * to start is created.
	 * <p>
	 * Postcondition: The domain is started and its socket is opened, if it is not already running.
	 * @param name name of the domain to start
	 */
	public void startDomain(String name){
		if(name.equals("house")){
		    if(hseSocket != null){
		    	System.out.println("House is already running.");
		    	return;
		    }
			System.out.println("Starting the house domain.");
		    runHouse();
		}
		else if(name.equals("trains")){
		    if(trainSocket != null){
		    	System.out.println("Trains is already running.");
		    	return;
		    }
		    System.out.println("Starting the trains domain.");
			runTrains();
		}
		else if(name.equals("planes")){
		    if(planeSocket != null){
		    	System.out.println("Planes is already running.");
		    	return;
		    }
		    System.out.println("Starting the planes domain.");
			runPlanes();
		}
		else if(name.equals("draughts")){
		    if(draSocket != null){
		    	System.out.println("Draughts is already running.");
		    	return;
		    }
		    System.out.println("Starting the draughts domain.");
			runChkers();
		}
		else if(name.equals("restaurant")){
			if(restSocket != null){
				System.out.println("Restaurant is already running.");
				return;
			}
		    System.out.println("Starting the restaurant domain.");
			runRest();
		}
		else if(name.equals("movies")){
		    if(movieSocket != null){
		    	System.out.println("Movie domain is already running.");
		    	return;
		    }
		    System.out.println("Starting the movies domain.");
		    runMovie();
		}
		else if(name.equals("email")){
			if(emailSocket != null){
				System.out.println("Email is already running.");
				return;
			}
		    System.out.println("Starting the email domain.");
		    runEmail();
		}
		else if(name.equals("chess")){
			if(chessSocket != null){
				System.out.println("Chess is already running.");
				return;
			}
		    System.out.println("Starting the chess domain.");
		    runChess();
		} 
		else {
			System.out.println(name + " is not currently valid domain name.");
		}
	}
	
	/**
	 * Precondition: 1 or more domains are running, and the socket of the desired domain
	 * is open.
	 * <p>
	 * Postcondition: The domain is ended and associated socket is closed. 
	 * @param domain domain name to close
	 */
	public void quitDomain(String domain){
		if(domain.equals("house")){
			comp.icon5.setBorder(BorderFactory.createLoweredBevelBorder());
			closeSockets(hseSocket, "House");
			return;
		} 
		else if(domain.equals("trains")){
			comp.icon4.setBorder(BorderFactory.createLoweredBevelBorder());
			closeSockets(trainSocket, "Trains");
			return;
		}
		else if(domain.equals("planes")){
			comp.iconplane.setBorder(BorderFactory.createLoweredBevelBorder());
			closeSockets(planeSocket, "Planes");
			return;
		}
		else if(domain.equals("draughts")){
			comp.icon2.setBorder(BorderFactory.createLoweredBevelBorder());
			closeSockets(draSocket, "Draughts");
			return;
			
		}
		else if(domain.equals("chess")){
			comp.icon1.setBorder(BorderFactory.createLoweredBevelBorder());
			closeSockets(chessSocket, "Chess");
			return;
			
		}
		else if(domain.equals("restaurant")){
			comp.icon7.setBorder(BorderFactory.createLoweredBevelBorder());
			closeSockets(restSocket, "Restaurant");
			return;
			
		}
		else if(domain.equals("email")){
			
			comp.icon3.setBorder(BorderFactory.createLoweredBevelBorder());
			closeSockets(emailSocket, "Email");
			return;
		}
		else if(domain.equals("movies")){
			comp.icon6.setBorder(BorderFactory.createLoweredBevelBorder());
			closeSockets(movieSocket, "Movies");
			return;
			
		}
	}

	private void runChess(){
		String domain = "/domain/chess/rd.chess";

		runProg(alfredBase+domain);

		try {
			BufferedReader in = new BufferedReader(new FileReader(alfredBase+"/etc/domainhost." + getLogName()));
		
			String connectInfo = null;
			Integer port = new Integer(0);
			String host = "";

			while ((connectInfo = in.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(connectInfo, " [],",
						false);
				String first = tok.nextToken();
				first.toLowerCase();
				if (first.equals("port")) {
					port = new Integer(tok.nextToken());
				} else if (first.equals("host")) {
					host = new String(tok.nextToken());

				}
			}

			//System.out.println("port is: " + port + "  host is: " + host);

			chessSocket = new Socket(host, port.intValue());
			
			readFromSocket(chessSocket);
			in.close();
			chessSocket.setKeepAlive(true);
		} catch (Exception e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		}
    	
		comp.icon1.setBorder(BorderFactory.createRaisedBevelBorder());
	}

	private void runChkers(){	
		String domain = "/domain/draughts/rd.draughts";
		runProg(alfredBase+domain);
		
		try {
			BufferedReader in = new BufferedReader(new FileReader(alfredBase+ "/etc/domainhost." + getLogName()));
			String connectInfo = null;
			Integer port = new Integer(0);
			String host = "";

			while ((connectInfo = in.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(connectInfo, " [],",
						false);
				String first = tok.nextToken();
				first.toLowerCase();
				if (first.equals("port")) {
					port = new Integer(tok.nextToken());
				} else if (first.equals("host")) {
					host = new String(tok.nextToken());

				}
			}

			//System.out.println("port is: " + port + "  host is: " + host);

			draSocket = new Socket(host, port.intValue());
			
			readFromSocket(draSocket);
			in.close();
			draSocket.setKeepAlive(true);
		} catch (Exception e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		}
		
		comp.icon2.setBorder(BorderFactory.createRaisedBevelBorder());
	}

	private void runEmail(){
		String domain = "/domain/email/rd.email";
    	
		//runProg("java -cp " + alfredBase+domain + " PopKorn " + 
		//			alfredBase+hostfile);
		runProg(alfredBase+domain);
		
		try {
			BufferedReader in = new BufferedReader(new FileReader(alfredBase + "/etc/domainhost." + getLogName()));
			String connectInfo = null;
			Integer port = new Integer(0);
			String host = "";

			while ((connectInfo = in.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(connectInfo, " [],",
						false);
				String first = tok.nextToken();
				first.toLowerCase();
				if (first.equals("port")) {
					port = new Integer(tok.nextToken());
				} else if (first.equals("host")) {
					host = new String(tok.nextToken());

				}
			}

		//	System.out.println("port is: " + port + "  host is: " + host);

			emailSocket = new Socket(host, port.intValue());
			
			readFromSocket(emailSocket);
			in.close();
			emailSocket.setKeepAlive(true);
		} catch (Exception e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		}
		
		comp.icon3.setBorder(BorderFactory.createRaisedBevelBorder());
	}
	
	private void runTrains() {
		String domain = "/domain/trains/rd.trains";
		
		runProg(alfredBase+domain);
	
		try {
			BufferedReader in = new BufferedReader(new FileReader(alfredBase
					+ "/etc/domainhost." + getLogName()));
			String connectInfo = null;
			Integer port = new Integer(0);
			String host = "";

			while ((connectInfo = in.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(connectInfo, " [],",
						false);
				String first = tok.nextToken();
				first.toLowerCase();
				if (first.equals("port")) {
					port = new Integer(tok.nextToken());
				} else if (first.equals("host")) {
					host = new String(tok.nextToken());
				}
	
			}

		//	System.out.println("port is: " + port + "  host is: " + host);

			trainSocket = new Socket(host, port.intValue());
			
			//new Domain("trains", port.intValue(), host);
			
			readFromSocket(trainSocket);
			in.close();
			trainSocket.setKeepAlive(true);
		} catch (Exception e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		}
		
		comp.icon4.setBorder(BorderFactory.createRaisedBevelBorder());
	}

	private void runPlanes() {
		String domain = "/domain/planes/rd.planes";
		
		runProg(alfredBase+domain);
	
		try {
			BufferedReader in = new BufferedReader(new FileReader(alfredBase
					+ "/etc/domainhost." + getLogName()));
			String connectInfo = null;
			Integer port = new Integer(0);
			String host = "";

			while ((connectInfo = in.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(connectInfo, " [],",
						false);
				String first = tok.nextToken();
				first.toLowerCase();
				if (first.equals("port")) {
					port = new Integer(tok.nextToken());
				} else if (first.equals("host")) {
					host = new String(tok.nextToken());
				}
	
			}

		//	System.out.println("port is: " + port + "  host is: " + host);

			planeSocket = new Socket(host, port.intValue());
			
			//new Domain("planes", port.intValue(), host);
			
			readFromSocket(planeSocket);
			in.close();
			planeSocket.setKeepAlive(true);
		} catch (Exception e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		}
		
		comp.iconplane.setBorder(BorderFactory.createRaisedBevelBorder());
	}

	private void runHouse() {

		String domain = "/domain/house/rd.house";

  		//runProg(alfredBase+domain);

		try {
		    runProg(alfredBase+domain);
			BufferedReader in = new BufferedReader(new FileReader(alfredBase
					+ "/etc/domainhost." + getLogName()));
			String connectInfo = null;
			Integer port = new Integer(0);
			String host = "";

			while ((connectInfo = in.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(connectInfo, " [],",
						false);
				String first = tok.nextToken();
				first.toLowerCase();
				if (first.equals("port")) {
					port = new Integer(tok.nextToken());
				} else if (first.equals("host")) {
					host = new String(tok.nextToken());

				}
			}

		//	System.out.println("port is: " + port + "host is: " + host);

			hseSocket = new Socket(host, port.intValue());
			
			readFromSocket(hseSocket);
			in.close();
			hseSocket.setKeepAlive(true);
		} catch (Exception e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		}
		
		comp.icon5.setBorder(BorderFactory.createRaisedBevelBorder());
	}
	
	private void runMovie(){
		String domain = "/domain/movies/rd.movies";
		
		runProg(alfredBase+domain);
		
		try {
			BufferedReader in = new BufferedReader(new FileReader(alfredBase
					+ "/etc/domainhost." + getLogName()));
			String connectInfo = null;
			Integer port = new Integer(0);
			String host = "";

			while ((connectInfo = in.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(connectInfo, " [],",
						false);
				String first = tok.nextToken();
				first.toLowerCase();
				if (first.equals("port")) {
					port = new Integer(tok.nextToken());
				} else if (first.equals("host")) {
					host = new String(tok.nextToken());

				}
			}

		//	System.out.println("port is: " + port + "host is: " + host);

			movieSocket = new Socket(host, port.intValue());
			
			readFromSocket(movieSocket);
		
			in.close();
			movieSocket.setKeepAlive(true);
		} catch (Exception e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		}
		
		comp.icon6.setBorder(BorderFactory.createRaisedBevelBorder());
	}
	
	private void runRest(){
		String domain = "/domain/restaurant/rd.restaurant";
		
		runProg(alfredBase+domain);

		try {
			BufferedReader in = new BufferedReader(new FileReader(alfredBase
					+ "/etc/domainhost." + getLogName()));
			String connectInfo = null;
			Integer port = new Integer(0);
			String host = "";

			while ((connectInfo = in.readLine()) != null) {
				StringTokenizer tok = new StringTokenizer(connectInfo, " [],",
						false);
				String first = tok.nextToken();
				first.toLowerCase();
				if (first.equals("port") || first.equals("port:")) {
					port = new Integer(tok.nextToken());
				} else if (first.equals("host") || first.equals("host:")) {
					host = new String(tok.nextToken());

				}
			}

		//	System.out.println("port is: " + port + "host is: " + host);

			restSocket = new Socket(host, port.intValue());
			
			readFromSocket(restSocket);
			
			in.close();
			restSocket.setKeepAlive(true);
		} catch (Exception e) {
			System.out.println("Exception: SOCKET PROBLEM " + e);
			e.printStackTrace();
		}
		
		comp.icon7.setBorder(BorderFactory.createRaisedBevelBorder());
	}
	
	private void closeSockets(Socket socket, String domain){

	    if(socket == null){
	    	System.out.println(domain+" is not open");
	    	return;
	    }

	    if(socket.isClosed())
		{
		    System.out.println(domain+" is already closed");
		    return;  //send this to alfred too
		}

		try{
		    System.out.println("Closing the "+domain+" domain.");

		    PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
			
			out.println("quit");
			out.flush();
			out.close();
			socket.close();
			socket = null;
		}
		catch(IOException e){
			System.out.println("Problem closing a socket.");
			e.printStackTrace();
		}
	}
	
	private void runProg(String s){
	
		try {
			// start up the program
			Runtime.getRuntime().exec(s);
			
		} catch (IOException e) {
			System.out.println("IOException: EXEC " + e);
			e.printStackTrace();
		}

		try {
			sleep(15000);
		} catch (Exception e) {
			System.out.println("Interupted Exception: " + e);
			e.printStackTrace();
		}
	}
	
	private String readFromSocket(Socket socket){
		try {
			BufferedReader input = new BufferedReader(new InputStreamReader(socket.getInputStream()));
			//System.out.println("reading from port number "+socket.getLocalPort());
			String cmdline = null;
			while(input.ready()) {
				//System.out.println("input is ready");		
			    cmdline = new String(input.readLine());
			 //   System.out.println("line from domain: " + cmdline);
			    return cmdline;
			}    
			
		//	System.out.println("after read loop");
					
		} catch (Exception e) {
			System.out.println("Problem reading from socket");
			e.printStackTrace();
		}
		return null;
	}
	
	private String getLogName()
	{	
		String logName = System.getProperty("user.name");
		if(logName == null)
		{
			System.out.println("log name does not exist");
			System.exit(1);
		}

		return logName;
	}
}






