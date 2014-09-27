//
// src/model/geocode.opa
// @date: 04/2013
// @author: Diel Caroes
//
//	This module contains the code to perform a synchronous or asynchronous (currently not used) request to google geocode.
//	http://maps.googleapis.com/maps/api/geocode/xml?sensor=true&?address=
//


module GeoCode{
	//important this module uses WebClient.Get which performs a server-side request, use XHR module for client-side request
	URL = { 
			Uri.default_absolute with
			schema : {some: "http"},
			domain:"maps.googleapis.com",
			path: ["maps", "api", "geocode", "xml"],
			is_directory: false
		} 

	/**
		Function takes a placename and returns an outcome containing either 'geo.return' or failure msg
		(NON BLOCKING)
	*/
	function to_GeoCode_async(string place, ( outcome -> void ) f){
		location = Uri.of_absolute({URL with query:[("sensor", "true") , ("address", place)]}); //add the query parameters
		Logging.print(Uri.to_string(location))
		WebClient.Get.try_get_async(location, function(result){
			f(PlaceParser.Parse(callback(result)));
		});
	}

	/**
		the synchronous equivalent of to_GeoCode_async (BLOCKING)
	*/
	function to_GeoCode_sync(string place){
		location = Uri.of_absolute({URL with query:[("sensor", "true") , ("address", place)]}); //add the query parameters
		Logging.print(Uri.to_string(location))
		options = {WebClient.Get.default_options with timeout_sec: {some: 5.}}//set timeout to 5seconds instead of default 36seconds
		PlaceParser.Parse(callback(WebClient.Get.try_get_with_options(location, options)));
	}
			
	/**
		Callback function for async request
	*/
	function string callback(request_result){
		match(request_result){
			case {failure: _}: 
				Logging.print("no internet")
				"no internet"
			case {success: s}: 
				match (WebClient.Result.get_class(s)) {
    				case {success}: s.content;
       				default: 
       					Logging.print("failcode {s.content}")
    	   				"fail code:{s.code}";
        	}	
		}
	}
}