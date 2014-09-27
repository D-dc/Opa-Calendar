//
// src/model/utilities.opa
// @date: 03/2013
// @author: Diel Caroes
//
//  Some frequently used functions absent in the Opa standard library
//

     
module Util{
    //absolute value of an integer
    function int abs(int i){
        if(i<0){
            -i;
        }else{
            i
        }  
    }

    //check if a number is negative
    function bool negative(int i){
        if(i<0)
            true
        else
            false
    }

    //check if a number is positive
    function bool positive(int i){
        if (i>=0)
            true
        else
            false
    }

    //check if a number is equal to zero
    function bool zero(int i){
        if (i==0)
            true
        else
            false
    }
}    