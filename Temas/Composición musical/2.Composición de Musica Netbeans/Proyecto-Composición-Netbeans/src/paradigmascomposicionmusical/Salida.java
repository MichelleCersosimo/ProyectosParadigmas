/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package paradigmascomposicionmusical;

import java.io.File;
import java.io.IOException;
import javax.sound.midi.InvalidMidiDataException;

import javax.sound.midi.MidiEvent;
import javax.sound.midi.MidiMessage;
import javax.sound.midi.MidiSystem;
import javax.sound.midi.Sequence;
import javax.sound.midi.ShortMessage;
import javax.sound.midi.Track;
import javax.swing.table.DefaultTableModel;
import org.jfugue.pattern.Pattern;
import org.jfugue.player.Player;

/**
 *
 * @author Rafael
 */
public class Salida extends javax.swing.JFrame {

    //Atributos de la clase.
    public static final int NOTE_ON = 0x90;
    public static final int NOTE_OFF = 0x80;
    public static final String[] NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
    Reglas R;
    String partitura;
    /**
     * Creates new form Salida
     * @param selectFile
     * @throws javax.sound.midi.InvalidMidiDataException
     * @throws java.io.IOException
     */
    public Salida(File selectFile) throws InvalidMidiDataException, IOException {
        initComponents();
        // TODO code application logic here
        R = new Reglas();
        int[] cf = new int[3];
        int compas = 0;
        partitura = "";
        int tonalidad = 0;
        
        ///////////////////////////////////////////////////////////////////////////
        
        Sequence sequence = MidiSystem.getSequence(selectFile);

        int trackNumber = 0;
        for (Track track :  sequence.getTracks()) {
            trackNumber++;
            //System.out.println("Track " + trackNumber + ": size = " + track.size());
            //System.out.println();
            for (int i=0; i < track.size(); i++) { 
                MidiEvent event = track.get(i);
                //System.out.print("@" + event.getTick() + " ");
                MidiMessage message = event.getMessage();
                if (message instanceof ShortMessage) {
                    ShortMessage sm = (ShortMessage) message;
                    //System.out.print("Channel: " + sm.getChannel() + " ");
                    if (sm.getCommand() == NOTE_ON) {
                        int key = sm.getData1();
                        int octave = (key / 12)-1;
                        int note = key % 12;
                        String noteName = NOTE_NAMES[note];
                        int velocity = sm.getData2();
                        //System.out.println("Note on, " + noteName + octave + " key=" + key + " velocity: " + velocity);
                        compas = compas + 1;
                        cf[0] = compas;
                        cf[1] = R.tonalidades.get(0).indexOf(noteName);
                        cf[2] = octave;
                        Nota n = new Nota(cf[0],cf[1],cf[2]);
                        partitura = partitura + noteName + cf[2] +"w | ";
                        R.composicionMatriz[compas-1][0] = n;
                    } else if (sm.getCommand() == NOTE_OFF) {
                        int key = sm.getData1();
                        int octave = (key / 12)-1;
                        int note = key % 12;
                        String noteName = NOTE_NAMES[note];
                        int velocity = sm.getData2();
                        //System.out.println("Note off, " + noteName + octave + " key=" + key + " velocity: " + velocity);
                    } else {
                        //System.out.println("Command:" + sm.getCommand());
                    }
                } else {
                    //System.out.println("Other message: " + message.getClass());
                }
            }
            
            System.out.println();
        }
        R.Construir(compas, tonalidad);
        R.imprimirComMatriz();
        //////////////////////////////////////////////////////////////////////////
        
       
        
//        Player player = new Player();
//        player.play(partitura);
        
    R.componer(0);
    this.jLabel3.setText(R.quitarDuracion(R.composicion()) + " -> COMPOSICION");
    this.jLabel4.setText(R.quitarDuracion(partitura) + " -> CANTUS FIRMUS");
    
    
    //JTABLE
        Object fila[] = new Object[4];
        DefaultTableModel modelo;
        modelo = new DefaultTableModel();
        modelo.addColumn("Hechos-CF");
        modelo.addColumn("Hechos-Derivados");
        
        for(int z=0; z < R.numeroCompases; z++){
           for(int j = 1; j < 3; j++ ){ 
               fila[j-1] = R.listing(z,j);
           }
           modelo.addRow(fila);
        }
        
        jTable1.setModel(modelo);
        
  //Fin Jtable
        
        //Fin logica
    }

    Salida() {
       initComponents();
       
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jScrollPane1 = new javax.swing.JScrollPane();
        jTable1 = new javax.swing.JTable();
        jLabel1 = new javax.swing.JLabel();
        jButton1 = new javax.swing.JButton();
        jLabel2 = new javax.swing.JLabel();
        jLabel3 = new javax.swing.JLabel();
        jButton2 = new javax.swing.JButton();
        jLabel4 = new javax.swing.JLabel();
        jButton3 = new javax.swing.JButton();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setTitle("Composicion - Proyecto Paradigmas");
        setResizable(false);
        getContentPane().setLayout(null);

        jTable1.setModel(new javax.swing.table.DefaultTableModel(
            new Object [][] {
                {null, null},
                {null, null}
            },
            new String [] {
                "Hechos-CF", "Hechos-Comp"
            }
        ) {
            boolean[] canEdit = new boolean [] {
                false, false
            };

            public boolean isCellEditable(int rowIndex, int columnIndex) {
                return canEdit [columnIndex];
            }
        });
        jScrollPane1.setViewportView(jTable1);

        getContentPane().add(jScrollPane1);
        jScrollPane1.setBounds(50, 70, 430, 120);

        jLabel1.setText("Memoria de Trabajo");
        getContentPane().add(jLabel1);
        jLabel1.setBounds(210, 30, 130, 20);

        jButton1.setText("Play Cantus Firmus");
        jButton1.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton1ActionPerformed(evt);
            }
        });
        getContentPane().add(jButton1);
        jButton1.setBounds(60, 320, 170, 23);

        jLabel2.setText("Composicion:");
        getContentPane().add(jLabel2);
        jLabel2.setBounds(70, 210, 80, 20);

        jLabel3.setText("jLabel3");
        getContentPane().add(jLabel3);
        jLabel3.setBounds(100, 230, 280, 30);

        jButton2.setText("Play Composicion");
        jButton2.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton2ActionPerformed(evt);
            }
        });
        getContentPane().add(jButton2);
        jButton2.setBounds(330, 320, 140, 23);

        jLabel4.setText("jLabel4");
        getContentPane().add(jLabel4);
        jLabel4.setBounds(100, 260, 350, 30);

        jButton3.setText("Volver al inicio");
        jButton3.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton3ActionPerformed(evt);
            }
        });
        getContentPane().add(jButton3);
        jButton3.setBounds(190, 370, 160, 23);

        setSize(new java.awt.Dimension(543, 459));
        setLocationRelativeTo(null);
    }// </editor-fold>//GEN-END:initComponents

    private void jButton1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton1ActionPerformed
        // TODO add your handling code here:
        Pattern p1 = new Pattern("V0 I[Piano] " + partitura);
        Pattern p2 = new Pattern("V1 I[Piano] " + R.composicion());
        Player player = new Player();
        player.play(p1);
    }//GEN-LAST:event_jButton1ActionPerformed

    private void jButton2ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton2ActionPerformed
        // TODO add your handling code here:
        Pattern p1 = new Pattern("V0 I[Piano] " + partitura);
        Pattern p2 = new Pattern("V1 I[Piano] " + R.composicion());
        Player player = new Player();
        player.play(p1,p2);
    }//GEN-LAST:event_jButton2ActionPerformed

    private void jButton3ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton3ActionPerformed
        // TODO add your handling code here:
        new Composicion().setVisible(true);
        this.setVisible(false);
    }//GEN-LAST:event_jButton3ActionPerformed

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /* Set the Nimbus look and feel */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(Salida.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(Salida.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(Salida.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(Salida.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new Salida().setVisible(true);
            }
        });
    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton jButton1;
    private javax.swing.JButton jButton2;
    private javax.swing.JButton jButton3;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JTable jTable1;
    // End of variables declaration//GEN-END:variables
}
