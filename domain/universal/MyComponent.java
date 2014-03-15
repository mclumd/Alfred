import javax.swing.*;


/**
 * Creates a Swing component with icons that represent each domain.
 * Each icon is located in /universal/images.
 * @author mayo
 * @version October 20, 2006
 */
public class MyComponent extends JComponent {

	private static final long serialVersionUID = 1L;
	private JFrame frame = new JFrame("Universal Domain");
	private JPanel jp1 = new JPanel();
	private ImageIcon chess = createImageIcon("~/Alfred/domain/universal/images/chess.gif", "Chess Board");
	private ImageIcon checkers = createImageIcon("~/Alfred/domain/universal/images/checkers.gif", "Checkers Board");
	private ImageIcon email = createImageIcon("~/Alfred/domain/universal/images/email.gif", "Email envelope");
	private ImageIcon train = createImageIcon("~/Alfred/domain/universal/images/trains.gif", "Train");
	private ImageIcon plane = createImageIcon("~/Alfred/domain/universal/images/trains.gif", "Plane");
	private ImageIcon lightSwitch = createImageIcon("~/Alfred/domain/universal/images/lightswitch.gif", "Light Switch");
	private ImageIcon sceneMarker = createImageIcon("~/Alfred/domain/universal/images/scenemarker.gif", "Scene Marker");
	private ImageIcon silverWare = createImageIcon("~/Alfred/domain/universal/images/silverware.gif", "Silverware");
	
	protected JLabel icon1 = new JLabel(chess);
	protected JLabel icon2 = new JLabel(checkers);
	protected JLabel icon3 = new JLabel(email);
	protected JLabel icon4 = new JLabel(train);
	protected JLabel iconplane = new JLabel(plane);
	protected JLabel icon5 = new JLabel(lightSwitch);
	protected JLabel icon6 = new JLabel(sceneMarker);
	protected JLabel icon7 = new JLabel(silverWare);
	
	MyComponent(){
		frame.getContentPane().add(this);
	
		icon1.setBorder(BorderFactory.createLoweredBevelBorder());
		icon2.setBorder(BorderFactory.createLoweredBevelBorder());
		icon3.setBorder(BorderFactory.createLoweredBevelBorder());
		icon4.setBorder(BorderFactory.createLoweredBevelBorder());
		iconplane.setBorder(BorderFactory.createLoweredBevelBorder());
		icon5.setBorder(BorderFactory.createLoweredBevelBorder());
		icon6.setBorder(BorderFactory.createLoweredBevelBorder());
		icon7.setBorder(BorderFactory.createLoweredBevelBorder());
	}

	/**
	 * Precondition:  There is a frame created, but nothing is on it.
	 * <p>
	 * Postcondition: Adds the icons to a panel, which is then added to a frame and
	 * 				  displays the frame.
	 */
	public void init(){
	
		icon1.setSize(chess.getIconWidth(),chess.getIconHeight());
        int width = icon1.getWidth() * 10;
		int height = icon1.getHeight() * 3;
			
		jp1.add(icon1);
		jp1.add(icon2);
		jp1.add(icon3);
		jp1.add(icon4);
		jp1.add(iconplane);
		jp1.add(icon5);
		jp1.add(icon6);
		jp1.add(icon7);
		
		jp1.setSize(width, height);
		
		frame.add(jp1);
		frame.setSize(jp1.getWidth(), jp1.getHeight());
		frame.setVisible(true);
	}
	
	/**
	 * Precondition: There is a frame. 
	 * <p>
	 * Postcondition: Hides the frame from view.
	 *
	 */
	public void hideFrame(){
		frame.setVisible(false);
	}
	
	/**Returns an ImageIcon, or null if the path was invalid. */
	protected static ImageIcon createImageIcon(String path,
	                                           String description) {
		ImageIcon img = new ImageIcon(path, description);
		
	    if (img != null) {
	        return img;
	    } else {
	        System.err.println("Couldn't find file: " + path);
	        return null;
	    }
	}
}
