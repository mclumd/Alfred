
public class Domain {
	String name;
	int port;
	String host;
	
	Domain(String name_in, int port_in, String host_in){
		name = name_in;
		port = port_in;
		host = host_in;
	}
	
	public int getDomainPort(){
		return port;
	}
	
	public String getDomainHost(){
		return host;
	}
	
	public String getDomainName(){
		return name;
	}
}
