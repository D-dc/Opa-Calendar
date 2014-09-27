//
// plugin/html5_functions.js
// @date: 02/2013
// @author: Diel Caroes
//
//
//

/**
* @register {string -> int}
*/
function getStorageInt(itemName){
	return localStorage.getItem(itemName);
}

/**
* @register {string -> string}
*/
function getStorageString(itemName){
	return localStorage.getItem(itemName);
}

/**
* @register {string, int -> void}
*/
function setStorageInt(itemName, value){
	localStorage.setItem(itemName, value);
}

/**
* @register {string, string -> void}
*/
function setStorageString(itemName, value){
	localStorage.setItem(itemName, value);
}

/**
* @register {string -> void}
*/
function removeStorageKey(itemname){
	localStorage.removeItem(itemname);
}

/**
* @register {-> void}
*/
function clearStorage(){
	localStorage.clear();
}

/**
* @register {-> bool}
*/
function checkOnline(){
	var x=navigator.onLine;
	if (navigator.onLine) {
		return true;	
	}else{
		return false;	
	}
}


