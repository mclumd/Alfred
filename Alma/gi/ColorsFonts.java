import java.awt.*;

/**
 * This class centralizes all the color and font definitions and assignments.
 * @author K. Purang
 * @version October 2000
 */


public class ColorsFonts{

    // Color parameters

    static public Color lightSaffron = new Color(255, 230, 150);
    //    static public Color lightSaffron = new Color(255, 225, 150);
    //    static public Color lightTurquoise = new Color(208, 240, 255);
    static public Color lightTurquoise = new Color(184, 212, 224);
        static public Color turquoise = new Color(170, 240, 255);
    static public Color purple = new Color(208, 100, 240);
    //    static public Color darkRed = new Color(220, 80, 50);
    static public Color darkRed = new Color(156, 31, 31);
    //    static public Color lightGreen = new Color(220, 255, 110);
    static public Color lightGreen = new Color(205, 255, 112);

    // font parameters

    static public Font helvetica18Bold = new Font("Helvetica", Font.BOLD, 18);
    static public Font helvetica14Bold = new Font("Helvetica", Font.BOLD, 14);

    // constants

    static public Color controlPanelBackground = darkRed;
    static public Color controlPanelForeground = lightSaffron;
    static public Color ioPanelBackground = lightTurquoise;
    static public Color historyPanelBackground = lightSaffron;
    static public Color ioTextField = lightGreen;
    static public Color statusTextAreaBg = lightGreen;
    static public Color statusTextAreaFg = darkRed;
    static public Font ioInputFont = helvetica14Bold;
    static public Font gotoTextFont = helvetica14Bold;
    static public Color gotoTextBackground = lightGreen;
    static public Font delayFieldFont = helvetica14Bold;
    static public Color delayFieldBackground = lightGreen;



} // class ColorsFonts
