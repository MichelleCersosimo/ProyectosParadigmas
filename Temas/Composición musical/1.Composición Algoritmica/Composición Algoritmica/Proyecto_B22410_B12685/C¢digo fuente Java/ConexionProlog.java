
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.util.Hashtable;
//import jpl.*;
//import jpl.Query;

/**
 *
 * @author Esquivel Oscar
 * @author Garbanzo Diana
 */
public class ConexionProlog {
   /**
     * Constructor de la clase
     */
    public ConexionProlog() {
    }
   
    /**
     * @param conMelodia que determina el tipo string para el llamado a la regla
     * correspondiente
     * @param lista para el caso en que se recibe la melodia como un string
     * Metodo encargado de compilar el archivo, hacer el llamado a la regla y de
     * leer los datos del archivo generado
     */
    protected String[] ejecutarConsulta(String nombreArchivo, boolean conMelodia) {
        String[] resultado = null;
        if(("").equals(nombreArchivo))
            nombreArchivo = "prueba.txt";
        try {
            // Se abre el archivo
            FileInputStream fstream = new FileInputStream(nombreArchivo);
            // Se crea el objeto de entrada
            DataInputStream entrada = new DataInputStream(fstream);
            // Se crea el Buffer de Lectura
            BufferedReader buffer = new BufferedReader(new InputStreamReader(entrada));
            String strLinea;
            String[] sinCorchetes;
            // Leer el archivo linea por linea, en caso sin melodia
            while (!conMelodia && (strLinea = buffer.readLine()) != null)   {
                // Variables para aplicar split
                String division = " ";
                String bufferLocal = null;
                sinCorchetes = strLinea.split(division);
                //Convierte en un solo string, el resultado del split
                bufferLocal = concatenarArrayDeStrings(sinCorchetes);
                // Asignacion de variables para aplicar otro split
                division = "\\[";
                sinCorchetes = bufferLocal.split(division);
                //Convierte en un solo string, el resultado del split
                bufferLocal = concatenarArrayDeStrings(sinCorchetes);
                //Convierte en un solo string, el resultado del split
                division = "\\]";
                sinCorchetes = bufferLocal.split(division);
                //Convierte en un solo string, el resultado del split
                bufferLocal = concatenarArrayDeStrings(sinCorchetes);
                // Variables para separar los numeros de las comas
                resultado = new String[sinCorchetes.length * 3];
                // Int para manejar el indice del vector de string resultado
                int indiceDeResultado = 0;
                // Ciclo para separar los numeros del vector
                for(int i = 0; i < sinCorchetes.length; i++) {
                    // Indice en donde se encuentra la coma
                    int indice = sinCorchetes[i].indexOf(',');
                    resultado[indiceDeResultado] = sinCorchetes[i].substring(0, indice);
                    resultado[indiceDeResultado + 1] = sinCorchetes[i].substring(indice+1, sinCorchetes[i].length());
                    indiceDeResultado += 2;
                }
                // Impresion del arreglo para comprobacion
                //imprimirArregloDeString(resultado);
            }
            // Caso con melodia
            while(conMelodia && (strLinea = buffer.readLine()) != null) {
                // Variables para aplicar split
                String division = " ";
                String[] sinEspacios = strLinea.split(division);
                // For de impresion temporal
                //for(int i = 0; i < sinEspacios.length; i++)
                //    System.out.println(sinEspacios[i]);
            }
            // Se cierra el archivo
            entrada.close();
        }
        catch (Exception e){ //Catch de excepciones
            System.err.println("Ocurrio un error: " + e.getMessage());
        }
        return resultado;
    }
    
    /**
     * @param strinPorImprimir, el cual se recorre para imprimir
     * Metodo encargado de imprimir el arreglo de String, recibido
     */
    private void imprimirArregloDeString(String[] stringPorImprimir)
    {
        // Ciclo para imprimir el vector de String
        for( int i = 0; i < stringPorImprimir.length; i++)
        {
            if(stringPorImprimir[i] != null)
                System.out.println(stringPorImprimir[i]);
        }
    }
   
    /**
     * @param stringConSplit, el cual se recorre para concatenarlo
     * Metodo encargado de conformar un String con lo que recibe
     */
    private String concatenarArrayDeStrings(String[] stringConSplit)
    {
        String bufferLocal = "";
        // Ciclo para contatenar
        for( int i = 0; i < stringConSplit.length; i++)
        {
            bufferLocal += stringConSplit[i];
        }
        return bufferLocal;
    }
}
