/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package paradigmascomposicionmusical;

import java.util.ArrayList;
import java.util.Random;
import java.util.Iterator;

/**
 *
 * @author Rafael
 */
public class Reglas {
    /**
     * @param args the command line arguments
     */
    
    
    public static ArrayList<Integer> intervalosPermitidos;
                                                        
    public static Nota composicionMatriz [][]; 
    
    public static ArrayList<ArrayList<Nota>> composicion;
    
    public static int compasActual;
    
    public static int numeroCompases;
    
    public static int noIntervalos = -1;
    
    public static int idxIntervaloPermitido;
    
    public static boolean continuar;
    
    public static int TONALIDAD = 0;
    
    private static boolean SOLUCION;
    
    public static ArrayList<ArrayList<String>> tonalidades;
    
    
    public Reglas(){
    
        intervalosPermitidos = new ArrayList<Integer>();
        composicion = new ArrayList<ArrayList<Nota>>();
        SOLUCION = false;
        tonalidades = new ArrayList<ArrayList<String>>();
        
        //establacer tonalidad C mayor
        tonalidades.add(0,new ArrayList<String>());
        tonalidades.get(0).add(0,"C");tonalidades.get(0).add(1,"D");tonalidades.get(0).add(2,"E");
        tonalidades.get(0).add(3,"F");tonalidades.get(0).add(4,"G");tonalidades.get(0).add(5,"A");
        tonalidades.get(0).add(6,"B");
        
        
        //this.intervalosPermitidos.add(3);//3->3era menor
        this.intervalosPermitidos.add(3);//4->3era mayor
        this.intervalosPermitidos.add(4);//5->4 justa
        this.intervalosPermitidos.add(5);//7->5 justa
        this.intervalosPermitidos.add(6);//6->6ta mayor
        this.intervalosPermitidos.add(8);//12-> 8 justa
        this.intervalosPermitidos.add(10);//16->10 decima
        composicionMatriz = new Nota[50][2];
        compasActual = idxIntervaloPermitido = 0;      
        numeroCompases = 6;
        
        
        
        continuar = true;
        
        
    }//fin de constructor.
    
     public Reglas(int compases,int tonalidad){
    
         SOLUCION = false;
         
         TONALIDAD = tonalidad;
         
        intervalosPermitidos = new ArrayList<Integer>();
        composicion = new ArrayList<ArrayList<Nota>>();
        
        for(int i = 0; i < compases; i++){
        
            composicion.add(i,new ArrayList<Nota>());
        }
        
        System.out.println(composicion.size());
        
        //establacer tonalidad C mayor
        tonalidades.add(0,new ArrayList<String>());
        tonalidades.get(0).add(0,"C");tonalidades.get(0).add(1,"D");tonalidades.get(0).add(2,"E");
        tonalidades.get(0).add(3,"F");tonalidades.get(0).add(4,"G");tonalidades.get(0).add(5,"A");
        tonalidades.get(0).add(6,"B");
        
        
        
        this.intervalosPermitidos.add(3);//4->3era mayor
        this.intervalosPermitidos.add(4);//5->4 justa
        this.intervalosPermitidos.add(5);//7->5 justa
        this.intervalosPermitidos.add(6);//6->6ta mayor
        this.intervalosPermitidos.add(8);//12-> 8 justa
        this.intervalosPermitidos.add(10);//16->10 decima
        
        compasActual = idxIntervaloPermitido = 0;      
        numeroCompases = 6;
        
        numeroCompases = compases;
        
        continuar = true;
        
        Nota notaP = new Nota();
        
       
        
        
        for(int i = 0; i < compases; i ++){
        
           composicionMatriz[i][0] = composicionMatriz[i][1] = notaP;
           
        }//fin de for
        
        
    }//fin de constructor.
     
     
     public void Construir(int compases,int tonalidad){
         SOLUCION = false;
         
         TONALIDAD = tonalidad;
        
        for(int i = 0; i < compases; i++){
        
            composicion.add(i,new ArrayList<Nota>());
        }
        
        System.out.println(composicion.size());
        
        
        
        
        
        compasActual = idxIntervaloPermitido = 0;   
        
        numeroCompases = compases;
        
        continuar = true;
        
        Nota notaP = new Nota();
        
        
        for(int i = 0; i < compases; i ++){
        
           composicionMatriz[i][1] = notaP;
           
        }//fin de for
        
     }
 
    public boolean movPermitido1(int compasAct, Nota nota){

        
        boolean salida = false;
        
        if(compasAct == 0){//caso primer compas.
            //System.out.println("ENTRA");
        
            if((composicionMatriz[compasAct][0].nota - nota.nota) == 0 && 
                    composicionMatriz[compasAct][0].altura < nota.altura){
            
                salida = true;
            }
             
            if((nota.nota - composicionMatriz[compasAct][0].nota) == 4 && 
                    nota.altura == composicionMatriz[compasAct][0].altura){
            
                salida = true;
            
            }
                
          
        }//fin de if
        
        //aqui va caso intermedio
        if( compasAct > 0 && compasAct < numeroCompases ){
            
            
            //caso donde la nota inferior sube. la nota actual sube.
            if(composicionMatriz[compasAct - 1][0].altura < composicionMatriz[compasAct][0].altura){
            
                
                if(composicionMatriz[compasAct - 1][1].altura > nota.altura){
                
                    salida = true;
                }
                else if(nota.altura == composicionMatriz[compasAct - 1][1].altura){
                    
                    
                
                    if(composicionMatriz[compasAct - 1][1].nota > nota.nota){
                    
                        salida = true;
                    
                    }//fin de if
                    
                }//fin de else.
            }else if(composicionMatriz[compasAct - 1][0].altura == composicionMatriz[compasAct][0].altura){
                
                
                if(composicionMatriz[compasAct - 1][0].nota < composicionMatriz[compasAct][0].nota){
                
                    if(composicionMatriz[compasAct - 1][1].altura > nota.altura){
                
                        salida = true;
                
                    }//fin de if
                
                    else if(nota.altura == composicionMatriz[compasAct - 1][1].altura){
                
                        
                        if(composicionMatriz[compasAct - 1][1].nota > nota.nota){
                    
                            salida = true;
                    
                        }//fin de if
                
                    }//fin de else
                
                }//fin de if
                
            }//fin de if
            
            
            
            //caso donde la nota inferior baja. la nota actual baja.
            if(composicionMatriz[compasAct - 1][0].altura > composicionMatriz[compasAct][0].altura){

                if(composicionMatriz[compasAct - 1][1].altura < nota.altura){

                    salida = true;
                
                }//fin de if
                
                else if(nota.altura == composicionMatriz[compasAct - 1][1].altura){

                    if(composicionMatriz[compasAct - 1][1].nota < nota.nota){

                        salida = true;

                    }//fin de if

                
                }//fin de else.
            
            }else if(composicionMatriz[compasAct - 1][0].altura == composicionMatriz[compasAct][0].altura){

                if(composicionMatriz[compasAct - 1][0].nota > composicionMatriz[compasAct][0].nota){

                    if(composicionMatriz[compasAct - 1][1].altura < nota.altura){

                        salida = true;

                    }//fin de if

                    else if(nota.altura == composicionMatriz[compasAct - 1][1].altura){

                        if(composicionMatriz[compasAct - 1][1].nota < nota.nota){

                            salida = true;

                        }//fin de if

                    }//fin de else

                }//fin de if

            }//fin de if          
            
        }//fin de caso 2.
        
        
        if( compasAct == (numeroCompases - 1) ){//caso ultimo compas
            
            //System.out.println("\nENTRA ULTIMO COMPAS");
            //System.out.print("compara: ");
            //composicionMatriz[compasAct][0].imprimirNota();
            //nota.imprimirNota();
            
             if((composicionMatriz[compasAct][0].nota - nota.nota) == 0 && 
                    composicionMatriz[compasAct][0].altura < nota.altura){
            
                 //System.out.println("ENTRA!!!!");
                salida = true;
                
            }//fin de if       
            
        }//fin de if
        
        return salida;
    } 
    
    public void assertNota(int compas, Nota nota){
    
        composicionMatriz[compas][1] = nota;
        
    }
    
    public void retractNota(int compas){
        
        Nota nota = new Nota();
    
        composicionMatriz[compas][1] = nota; 
    }
    
    
    public void imprimirComposicion(){
    
        if(SOLUCION){
            
        for(int i = 0; i < numeroCompases; i++){
        
            composicion.get(i).get(0).imprimirNota();         
            composicion.get(i).get(1).imprimirNota();
            
            System.out.println("");
            
        }//fin de for
        
        System.out.println("");
        }
        else{
        
            System.out.println("SOLUCION = {}");
        }
        
    }
    
//    public Nota ajustarNota(Nota nota, int tonalidad){
//        
//        ArrayList<String> alteraciones = tonalidades.get(tonalidad);
//        
//        //for(int i = 0; i < numeroCompases; i++){
//        
//        //int i = nota.compas;
//        
//            //Nota get1 = composicion.get(i).get(1);
//            
//                
//                if(alteraciones.contains(NOTE_NAMES[nota.nota].substring(0,1))){
//                 
//                    int tam = alteraciones.size();
//                    String alteracion = null;
//                    
//                    for(int j = 0; j < tam; j++){
//                    
//                        if(NOTE_NAMES[nota.nota].substring(0,1).equals(alteraciones.get(j))){
//                        
//                             alteracion = alteraciones.get(j);
//                        
//                        }//fin de if
//                        
//                    }//fin de for
//                    
//                    //System.out.println("ESTA ES LA ALTERACION: "+NOTE_NAMES[nota.nota]);
//                    
//                    if(NOTE_NAMES[nota.nota].length() > alteracion.length()){
//                    
//                        //composicion.get(i).get(1).nota--;
//                        nota.nota--;
//                        nota.imprimirNota();
//                    }
//                    
//                    if(NOTE_NAMES[nota.nota].length() < alteracion.length()){
//                    
//                        //composicion.get(i).get(1).nota++;
//                        nota.nota++;
//                    }
//                    
//                }//fin de if
//                
//            //}//fin de if
//            
//        //}//fin de for
//        return nota;
//    
//    }//fin de metodo()
    
    public Nota calcularNota2(int compasActual, int altura){
        
        
        ArrayList<String> get = this.tonalidades.get(TONALIDAD);
        

        int alt = intervalosPermitidos.get(altura);
        //System.out.print("\nESTA ES LA ALTURA: "+alt+"");
        Nota nota = new Nota();
        
        nota.compas = composicionMatriz[compasActual][0].compas;
        
        int alturaNotaNueva = composicionMatriz[compasActual][0].altura, indice = 
                composicionMatriz[compasActual][0].nota;
        
        for(int i = 1; i <alt; i++){
            
            indice++;
            if(indice == 7){
                
                indice = 0;
                alturaNotaNueva++;
            }
                    
                    
        }//fin de for
        
        nota.nota = indice;
        
        nota.altura = alturaNotaNueva;
        //nota.nota = (composicionMatriz[compasActual][0].nota + (altura - 1)) %7;
        //nota.altura =(composicionMatriz[compasActual][0].nota + (altura - 1)) /7;
        
        return nota;
    
    }
    
//    public Nota calcularNota(int compasActual,int altura){
//    
//        Nota nota = new Nota();
//        
//        int alt = this.intervalosPermitidos.get(altura);
//
//            nota.compas = (compasActual + 1);
//            
//            nota.nota = (composicionMatriz[compasActual][0].nota + alt)%12;
//            
//            nota.altura = ((composicionMatriz[compasActual][0].nota + alt)/12) 
//                    + composicionMatriz[compasActual][0].altura;// sube la altura.
//
//        return nota;
//        
//    }//calcularNota().
    
    private void guardarComposicion(){
    
        for(int i = 0; i < numeroCompases; i++ ){

            composicion.get(i).add(0, composicionMatriz[i][0]);
            
            composicion.get(i).add(1,composicionMatriz[i][1]);
        
        }//fin de for
        
        //this.corregirTonalidad(0);
        
    }//fin de metodo
    
    public void imprimirComMatriz(){
    
        for(int i = 0; i < numeroCompases; i++){
        
            composicionMatriz[i][0].imprimirNota();
            composicionMatriz[i][1].imprimirNota();
            
            System.out.println("");
        }
        System.out.println("");
    }
    
    public String composicion(){
        String comp = "";
        Nota n ;
        for(int i = 0; i < numeroCompases; i++){
            n = composicion.get(i).get(1);
            comp = comp + tonalidades.get(TONALIDAD).get(n.nota) + n.altura +"w | ";
        }
        return comp;
    }
    
    
    public String listing(int n,int tipo){
        String part = "";
        if(tipo == 1){//Imprime el CF
            part = part.concat("fact([");
            
                    part = part.concat(this.composicion.get(n).get(0).getTripleta());
            part = part.concat("])");
        }
        if(tipo == 2){//Imprime la comp
            part = part.concat("fact([");
            
                    part = part.concat(this.composicion.get(n).get(1).getTripleta());
            part = part.concat("])");
        }
        
        return part;
    }
    
    public String quitarDuracion(String str){
        String melodia = str;
        
        melodia = melodia.replace('w', ' ');
        melodia = melodia.replace('2', ' ');
        melodia = melodia.replace('3', ' ');
        melodia = melodia.replace('4', ' ');
        melodia = melodia.replace('5', ' ');
        melodia = melodia.replace('6', ' ');
        melodia = melodia.replace('7', ' ');
        return melodia;
    }
//    private void corregirTonalidad(int tonalidad){
//        
//        //System.out.println("ENTRA A CORREGIR NOTAS");
//    
//        ArrayList<String> alteraciones = tonalidades.get(tonalidad);
//        
//        for(int i = 0; i < numeroCompases; i++){
//        
//            Nota get1 = composicion.get(i).get(1);
//            
//                
//                if(alteraciones.contains(NOTE_NAMES[get1.nota].substring(0,1))){
//                 
//                    int tam = alteraciones.size();
//                    String alteracion = null;
//                    
//                    for(int j = 0; j < tam; j++){
//                    
//                        if(NOTE_NAMES[get1.nota].substring(0,1).equals(alteraciones.get(j))){
//                        
//                             alteracion = alteraciones.get(j);
//                        
//                        }//fin de if
//                        
//                    }//fin de for
//                    
//                    System.out.println("ESTA ES LA ALTERACION: "+alteracion);
//                    
//                    if(NOTE_NAMES[get1.nota].length() > alteracion.length()){
//                    
//                        composicion.get(i).get(1).nota--;
//                    }
//                    
//                    if(NOTE_NAMES[get1.nota].length() < alteracion.length()){
//                    
//                        composicion.get(i).get(1).nota++;
//                    }
//                    
//                }//fin de if
//                
//            //}//fin de if
//            
//            
//        }//fin de for
//        
//    }//fin de corregirTonalidad
    
    
    public void componer(int compas){
    
        int idxIntervaloPermitido = 0;
        boolean continuar = true;
        
        for(idxIntervaloPermitido = 0; idxIntervaloPermitido < 6 && continuar; 
                idxIntervaloPermitido++){

            Nota nota = calcularNota2(compas,idxIntervaloPermitido);
            
            System.out.print("\nNOTA A PROBAR ");
            nota.imprimirNota();
            //idxIntervaloPermitido++;
            
            if( movPermitido1(compas,nota) ){ //existen intervalos aun?

                System.out.print("MOVIMIENTO POSIBLE\n");
                //nota.imprimirNota();
                
                assertNota(compas,nota);
                System.out.println("\n\nCOMPOSICION A ESTE MOMENTO");
                this.imprimirComMatriz();
                
                if((compas + 1) == numeroCompases){
                
                    System.out.println("TERMINO COMPOSICION");
                    this.guardarComposicion();
                    SOLUCION = true;
                    continuar = false;
                }
                else{
                
                    //System.out.println("\nva a llamar con compas: "+(compas + 1));
                    componer(compas + 1);
                }
                System.out.println("\n\nse retracta de compas: "+(compas + 1));
                
                retractNota(compas);
                this.imprimirComMatriz();
                
            }//fin de if.
            
        }//fin de for
        
    }//fin de metodo componer().
}
