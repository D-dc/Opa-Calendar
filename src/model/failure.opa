//
// src/model/failure.opa
// @date: 09/2014
// @author: Diel Caroes
//
// temporarily failure handling
//


module Failure {
	//TODO: make use of mutable Mutable.make(0); to be able to retry without

	function retry_on_failure((-> outcome(void, string)) my_func, times){

		match(my_func()){
			case {success}:
				{success};
				
			case {failure: msg}: 
				if(times==0){
					graceful_inform(msg);
					{failure: msg}
				}else{
					Log.info("retrying!!", "r");
					retry_on_failure(my_func, times-1);
				}
		}	
	}

	function graceful_inform(msg){
		//https://github.com/MLstate/opalang/blob/c9358f8f5648164515f1fe0e651ce0c1aa1e7a2e/lib/stdlib/core/rpc/core/log.opa
		Log.warning("graceful", msg);
	}

	function direct_inform(msg){
		alertMsg(msg, "error");
	}

	private function alertMsg(msg, error_type){
	    
	    #msgInform =
	        <div class="alert alert-{error_type}">
	            <button type="button" class="close" data-dismiss="alert">x</button>
	            {msg}
	        </div>;
	}
}