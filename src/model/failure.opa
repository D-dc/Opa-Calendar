//
// src/model/failure.opa
// @date: 09/2014
// @author: Diel Caroes
//
// temporarily failure handling
//

//type Failure = {string msg}
//type Either('a, 'b) = {'a Left} or {'b Right}

	

module Failure {

	fail = {failure: ""};
	

	function outcome('a, string) prop( outcome('a, 'b) original, string msg){
		match(original){
			case ~{failure: s1}: 
				{failure: "{s1}, " + msg};
			case ~{success: s}: 
				{success: s};	
		}
	}

	function retry((-> outcome('a, string)) closure, times){

		match(closure()){
			case ~{success: s}:
				Log.notice("Succeeded", "");
				{success: s};
				
			case ~{failure: msg}: 
				if(times==0){
					graceful_inform(msg);
					{failure: msg}
				}else{
					Log.notice("Retry ", msg);
					retry(closure, times-1);
				}
		}	
	}

	function graceful_inform(msg){
		//https://github.com/MLstate/opalang/blob/c9358f8f5648164515f1fe0e651ce0c1aa1e7a2e/lib/stdlib/core/rpc/core/log.opa
		Log.error("failed", msg);
	}

	function direct_inform(msg){
		Client.alert(msg);
	}
}