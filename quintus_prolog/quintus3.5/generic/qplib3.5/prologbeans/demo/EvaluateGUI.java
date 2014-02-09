/**
 * EvaluateGUI.java
 * A simple example showing how to connect a Java GUI to a running
 * prolog server.
 *
 * Created: Tue Aug 19 13:59:06 2003
 *
 * @Author  : Joakim Eriksson
 */
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import se.sics.prologbeans.*;

public class EvaluateGUI implements ActionListener {

  private JTextArea text = new JTextArea(20, 40);
  private JTextField input = new JTextField(36);
  private JButton evaluate = new JButton("Evaluate");
  private PrologSession session = new PrologSession();

  public EvaluateGUI() {
    if ((Integer.getInteger("se.sics.prologbeans.debug", 0)).intValue() != 0) {
	  session.setTimeout(0);
      }
    JFrame frame = new JFrame("Prolog Evaluator");
    Container panel = frame.getContentPane();
    panel.add(new JScrollPane(text), BorderLayout.CENTER);
    JPanel inputPanel = new JPanel(new BorderLayout());
    inputPanel.add(input, BorderLayout.CENTER);
    inputPanel.add(evaluate, BorderLayout.EAST);
    panel.add(inputPanel, BorderLayout. SOUTH);
    text.setEditable(false);
    evaluate.addActionListener(this);
    input.addActionListener(this);

    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    frame.pack();
    frame.setVisible(true);
  }

  public void actionPerformed(ActionEvent event) {
    try {
      Bindings bindings = new Bindings().bind("E", input.getText() + '.');
      QueryAnswer answer =
	session.executeQuery("evaluate(E,R)", bindings);
      Term result = answer.getValue("R");
      if (result != null) {
	text.append(input.getText() + " = " + result + '\n');
	input.setText("");
      } else {
	text.append("Error: " + answer.getError() + '\n');
      }
    } catch (Exception e) {
      text.append("Error when querying Prolog Server: " +
		  e.getMessage() + '\n');
      e.printStackTrace();
    }
  }

  public static void main(String[] args) {
    new EvaluateGUI();
  }
}
