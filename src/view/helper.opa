//
// src/view/helper.opa
// @date: 02/2013
// @author: Diel Caroes
//
//	Helper function for evaluation of some of the required fields.
//


import stdlib.widgets.grid
import stdlib.{themes.bootstrap, widgets.bootstrap}
import stdlib.widgets.datepicker
import stdlib.core
import stdlib.tests
import stdlib.widgets.core;
import stdlib.widgets.sidepanel
import stdlib.widgets.grid
import stdlib.web.client


module Helper{
	/*
		checks if a field defined by 'el' is empty 
		if it is empty 'alterMsg' will be displayed
		otherwise func will be called on the value of the el.
	*/
	function required(dom el, string alertMsg, func){
		el_contents = Dom.get_value(el);
		if(String.is_empty(el_contents)){
			View.alert(alertMsg, "error", false);
		}else{
			func(el_contents)
		}
	}
}