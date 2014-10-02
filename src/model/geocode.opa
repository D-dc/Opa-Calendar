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
			domain:"caroes.be", // "maps.googleapis.com",
			path: ["unreliable_server.php"], //["maps", "api", "geocode", "xml"],
			is_directory: false
		} 

	/**
		Function takes a placename and returns an outcome containing either 'geo.return' or failure msg
		(NON BLOCKING)
	*/
	/*function to_GeoCode_async(string place, ( outcome -> void ) f){
		location = Uri.of_absolute({URL with query:[("sensor", "true") , ("address", place)]}); //add the query parameters
		Logging.print(Uri.to_string(location))
		WebClient.Get.try_get_async(location, function(result){
			f(callback(result));
		});
	}*/

	/**
		the synchronous equivalent of to_GeoCode_async (BLOCKING),
		function is executed on server, so blocking is less of a problem
	*/
	function to_GeoCode_sync(place place){
            
        match(place){
            case ~{unverified_string: place_name}:

            	closure = function(){
                    location = Uri.of_absolute({URL with query:[("sensor", "true") , ("address", place_name)]}); //add the query parameters
					options = {WebClient.Get.default_options with timeout_sec: {some: 30.}}//set timeout to 30seconds instead of default 36seconds
					
					Log.notice("HTTP REQ: ", Uri.to_string(location));
					callback(WebClient.Get.try_get_with_options(location, options));
				};
				Failure.retry(closure, 5);	
            default: Failure.fail
        }  
	}
			
	/**
		Callback function for async request
	*/
	function outcome('a, string) callback(request_result){
		match(request_result){

			case ~{success: s}: 
				match (WebClient.Result.get_class(s)) {
    				case {success}:
    					PlaceParser.Parse(s.content);
       				default: 
       					Failure.prop(Failure.fail, "failcode {s.code}");
        	}

        	case ~{failure: f}: 
				Failure.prop({failure: f}, "request failed");	
		}
	}
}