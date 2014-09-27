//
// plugin/html5.opa
// @date: 02/2013
// @author: Diel Caroes
//
//  This files contains the mapping to the javascript functions defined in html5_functions.js
//


package html5

client module HTML5 {
  
  //get an integer as value from corresponding string key
  function int getStorageInt(string name) {
      %%html5_functions.getStorageInt%%(name)
  }

  //get a string as value from corresponding string key
  function string getStorageString(string name) {
      %%html5_functions.getStorageString%%(name)
  }

  //save a key-value pair (both strings)
  function setStorageString(name, value) {
      %%html5_functions.setStorageString%%(name, value)
  }  

  //save a key-value pair (key:int, value:string)
  function setStorageInt(name, value){
      %%html5_functions.setStorageInt%%(name, value)
  }

  //clears the entire localstorage
  function clearStorage(){
      %%html5_functions.clearStorage%%();
  }

  //removes a key-value pair, given the key
  function removeStorageKey(string key){
      %%html5_functions.removeStorageKey%%(key);
  }

  //check if a specific key-value pair exists
  function bool localStorageExists(string name){ 
    if("{HTML5.getStorageInt(name)}"=="null"){//only proper way to check existance
        false;
    }else{
        true;
    }
  }

  //------------------------------------------

  //check if user is online
  function checkOnline() {
      %%html5_functions.checkOnline%%()
  }
}