/*
 * Proyecto de composición musical algorítmica.
 * Paradigmas computacionales, Escuela de Ciencias de la Computación e Informática, UCR.
 * 
 * Este código de Java contiene la interfaz que interactúa con el usuario para
 * reproducir la música generada desde Prolog. Sin un archivo musical válido 
 * generado por Prolog esta interfaz no debería poder funcionar.
 *
 * Julio, 2015.
 */
import javax.swing.JFrame;
//import org.jvnet.substance.SubstanceLookAndFeel;

/**
 *
 * @author Esquivel Oscar
 * @author Garbanzo Diana
 */
public class Main {

    /**
     * @param args the command line arguments
     */
     public static void main(String[] args) {
        //JFrame.setDefaultLookAndFeelDecorated(true);
        //SubstanceLookAndFeel.setSkin("org.jvnet.substance.skin.BusinessBlackSteelSkin");
        // Instancia de JFrame
        JFNotas interfaz = new JFNotas();
    }   
}
