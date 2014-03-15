

/**
 * Creates a {@link CommandParser} and passes args in its constructor.
 * @author mayo
 * @version October 20, 2006
 */
public class Main {

	/**
	 * @param args args[0] is the path to the host file
	 * 				<p>
	 *                  args[1] is the path to Alfred 
	 */
	public static void main(String[] args) {
		
		System.out.println("Welcome!");
		System.out.flush();
	
		new CommandParser(args);
	
		
	}
}
