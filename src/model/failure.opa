//
// src/model/failure.opa
// @date: 09/2014
// @author: Diel Caroes
//
// temporary failure handling
//

//type Failure = {string msg}
//type Either('a, 'b) = {'a Left} or {'b Right}
//	fail = {failure: ""};
	

module Failure {
	//https://github.com/MLstate/opalang/blob/c9358f8f5648164515f1fe0e651ce0c1aa1e7a2e/lib/stdlib/core/rpc/core/log.opa
	fail = {failure: ""};

	
	// Propagate a failure.
	function outcome('a, string) prop( outcome('a, 'b) original, string msg){
		match(original){
			case ~{failure: s1}: 
				{failure: "{s1}, " + msg};
			case {success: _} as s: 
				s;	
		}
	}

	// Take a closure which produces an outcome and retry the closure until it succeeds 
	// or until retry_count reaches zero.
	function retry((-> outcome('a, string)) closure, retry_count){

		match(closure()){
			case ~{success: _} as s:
				Log.notice("Succeeded", "");
				s;
				
			case ~{failure: msg} as f: 
				if(retry_count==0){
					graceful_inform(f);
					f;
				}else{
					Log.notice("Retry ", msg);
					retry(closure, retry_count-1);
				}
		}	
	}


	// Log the error gracefully
	function graceful_inform(result){
		match(result){	
			case ~{failure: msg}:
				Log.error("failure", msg); 
			default: void;	
		}
	}


	// Inform the client/server of an error
	function direct_inform(result){
		match(result){	
			case ~{failure: msg}:
				Client.alert(msg); 
			default: void;	
		}
	}
}