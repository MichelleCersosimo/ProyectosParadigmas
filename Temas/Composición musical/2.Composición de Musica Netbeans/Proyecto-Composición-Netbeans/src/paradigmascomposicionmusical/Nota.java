/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package paradigmascomposicionmusical;

/**
 *
 * @author estebannoguerapenaranda
 */
public class Nota {
   
    public int compas;
    public int nota;
    public int altura;
    
    public Nota(){
    
        compas = nota = altura = 0;
    }
    
    
    public Nota(int compas, int nota, int altura){
    
        this.compas = compas; 
                
        this.nota = nota;
        
        this.altura = altura;
    }
    
    public void imprimirNota(){
    
        System.out.print(this.compas+","+this.nota+","+this.altura+"  ");
    }
    
    public String getTripleta(){
    
        return (this.compas+","+this.nota+","+this.altura);
    }
}
