

import java.io.*;
import java.net.*;
import java.util.*;

/**
 * Has a Director.
 * <p>
 * Creates a connection with Alfred.  Once connection is established, CommandParser will start to receive
 * commands from Alfred.  Each command is parsed, grouped by action, and sent to {@link Director} so that 
 * the appropriate domain receives it.  Messages from the domains go through here back to 
 * Alfred.
 * @author mayo
 * @version October 20, 2006
 * 
 */
public class CommandParser {
    Director universe = null;
	String fromDomain = null;    
	
	CommandParser(String[] args){


		// command from Alfred
		String clientCommand;
		// used to connect to Alfred
		ServerSocket serverSocket = null;

		universe = new Director(args[1]);

		FileWriter fw = null;
		
		try {
			
			// try to connect...
			serverSocket = getSS();
				
			//System.out.println("Server.getLocalPort(): "+serverSocket.getLocalPort());
			
			// print the local port number to a file so that the client knows
			// what to connect to
			File f = null;
			if ((args.length != 0) && (!(args[0] == null)))
				f = new File(args[0]);
			else
				f = new File("connectioninfo");
			f.delete();
			fw = new FileWriter(f);

			Integer port = new Integer(serverSocket.getLocalPort());
			// write the port number
			fw.write("port " + port.toString() + "\n");
			// write the local host address
			String host = InetAddress.getLocalHost().getCanonicalHostName();
			fw.write("host " + host + "\n");
			// write the process ID
			fw.write("process " + getProcess() + "\n");
			fw.flush();
			fw.close();
			
			System.out.println("Waiting for connection with Alfred...");
			//the socket through which server and client will communicate
			Socket client = serverSocket.accept();

			System.out.println("Connection established. You may start entering commands.");
			
			// used to get commands from and to Alfred
			BufferedInputStream input = new BufferedInputStream(client.getInputStream());
			PrintWriter pw = new PrintWriter(client.getOutputStream(), true);

			try {
			     while (client.isConnected()) {
				 //  while(true){
				   byte[] bt = new byte[1000];
					input.read(bt);
					clientCommand = new String(bt);

					//System.out.println("ClientCommand: "+clientCommand);					

					//check to see if byte array has any characters
					if(clientCommand.codePointAt(0) == 0)
					{
						System.out.println("Something got disconnected.");
						universe.closeAll();
						System.exit(1);
					}
				
					fromDomain = parse(clientCommand);
					
					if(fromDomain != null){
			//		    System.out.println("sending to Alfred: "+fromDomain);
			//		    System.out.println("local port for client is : "+client.getLocalPort());
					    pw.println(fromDomain);
					    pw.flush();
					    fromDomain = null;
					}

			     }
			} catch (IOException e) {
				System.out.println("Exception: " + e);
				e.printStackTrace();
			} catch (NullPointerException e) {
				System.out.println("Exception: " + e);
				e.printStackTrace();
			}
		} catch (IOException e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		} catch (Exception e) {
			System.out.println("Exception: " + e);
			e.printStackTrace();
		}
	}
	
	/*
	 * 
	 * @not used

	public void quit(){
		universe.closeAll();
	}
     */	
	
	/** 
	 * Precondition: Director is instantiated and connection with Alfred has been established.
	 * <p>
	 * Postcondition: Command is parsed and sent to the Director.
	 * @param cmd command from Alfred that is going to be parsed, grouped by action, 
	 * and sent to Director so that the appropriate domain receives it.
	 * @return returns a string representing an utterance from a domain
	 */
	public String parse(String cmd){
		
		cmd.trim().toLowerCase();
		StringTokenizer tok = new StringTokenizer(cmd, " [],");
		
		String first = tok.nextToken();
			
		//System.out.println("Parsing this command "+cmd);
		if(cmd == null){
			System.out.println("No command was given!");
			System.out.println("Please try again...");
		} 
		else if(cmd.trim().toLowerCase().equals("quit")){
			System.out.println("Exitting...Goodbye!");
			universe.closeAll();
			System.exit(1);
		}
		else if(first.equals("run")){
		    String second = tok.nextToken();
			if(second.equals("house")){
				//run the House domain
			    universe.startDomain("house");
				System.out.println("OK.");
			}
			else if (second.equals("draughts")){
				//run checkers domain
			    universe.startDomain("draughts");
				System.out.println("OK.");
			} 
			else if(second.equals("trains")){
			    universe.startDomain("trains");
				System.out.println("OK.");
			} 
			else if(second.equals("planes")){
			    universe.startDomain("planes");
				System.out.println("OK.");
			}
			else if(second.equals("chess")){
			    universe.startDomain("chess");
				System.out.println("OK.");
			}
			else if(second.equals("restaurant")){
			    universe.startDomain("restaurant");
				System.out.println("OK.");
			}
			else if(second.equals("popkorn")){
			    universe.startDomain("email");
				System.out.println("OK.");
			}
			else if(second.equals("movies")){
			    universe.startDomain("movies");
				System.out.println("OK.");
			}
			else {
				System.out.println("Run: Invalid domain name!");
			} 
		} 
		else if(first.equals("quit")){
			String second = tok.nextToken();
			if(second.equals("house")){
			    universe.quitDomain("house");
				System.out.println("OK.");
			}
			else if (second.equals("draughts")){
			    universe.quitDomain("draughts");
				System.out.println("OK.");
			} 
			else if(second.equals("trains")){
			    universe.quitDomain("trains");
				System.out.println("OK.");
			}
			else if(second.equals("planes")){
			    universe.quitDomain("planes");
				System.out.println("OK.");
			}
			else if(second.equals("chess")){
			    universe.quitDomain("chess");
				System.out.println("OK.");
			}
			else if(second.equals("restaurant")){
			    universe.quitDomain("restaurant");
				System.out.println("OK.");
			}
			else if(second.equals("popkorn")){
			    universe.quitDomain("email");
				System.out.println("OK.");
			}
			else if(second.equals("movies")){
			    universe.quitDomain("movies");
				System.out.println("OK.");
			}
			else {
				System.out.println("Quit: Invalid domain name!");
			} 
		}
		else if(first.equals("show")){
			System.out.println("Displaying universal panel.");
			universe.show();
			System.out.println("OK.");
		}
		else if(first.equals("hide")){
			System.out.println("Hiding universal panel.");
			universe.hide();
			System.out.println("OK.");
		}
		else{
			//System.out.println("Running: "+cmd);
			fromDomain = universe.runline(cmd);
			System.out.println("OK.");
		}
		return fromDomain;
	}
	

	private ServerSocket getSS() {
		int port = 0;
	    ServerSocket ss = null;
	    
		Random rand = new Random();
		 
		while (port < 100) {
			try {
				port = rand.nextInt(6000);
				ss = new ServerSocket(port);
			}
			catch (Exception e) {
				port= 0;
			}
		}
		
		return ss;
	}
	
	 // getProcess
	 // written by Paolo del Mundo
	 private String getProcess() throws Exception {
		 Runtime r= Runtime.getRuntime();
		 
		 String[] cmmds= {"ps"};
		 
		 Process p= r.exec(cmmds);
		 p.waitFor();
		 BufferedReader br= new BufferedReader(new InputStreamReader(p.getInputStream()));
		 
		 String str;
		 String result= new String();
		 
		 while ((str = br.readLine()) != null) {
			 if (str.indexOf("java") != -1) {
				 result= new String(str);
			 }	
		 }		

		 StringTokenizer strtok= new StringTokenizer(result, " ", false);

		 return strtok.nextToken();
	 }

}
