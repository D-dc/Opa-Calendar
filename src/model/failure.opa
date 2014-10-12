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
	
type RetryOptions = {
	int retry_count,
	option(int) retry_timeout
	//TODO add increasing timeout option
}

module Retry{
	RetryOptions once = {
		retry_count: 1,
		retry_timeout: {none}
	}

	RetryOptions immediate = {
		retry_count: 3,
		retry_timeout: {none}
	}

	RetryOptions later = {
		retry_count: 10,
		retry_timeout: {some: 5000}
	}

	function RetryOptions custom(retry_count, int retry_timeout){
		{
			~retry_count,
			retry_timeout: {some: retry_timeout}
		}
	}
}	

module Failure {
	// https://github.com/MLstate/opalang/blob/master/lib/stdlib/core/rpc/core/log.opa
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
	// or until retry_count reaches zero. Possibly wait before retrying.
	function retry((-> outcome('a, string)) closure, RetryOptions options){
		retry_count = options.retry_count;
		retry_timeout = options.retry_timeout;

		match(closure()){
			case ~{success: _} as s:
				Log.notice("{Date.now()} Succeeded {s}", "");
				s;
			case ~{failure: _} as f: 
				if(options.retry_count==0){
					graceful_inform(f);
					f;
				}else{
					Log.notice("Retrying {options.retry_count} times", "");
					match(options.retry_timeout){
						case ~{some: timeout}:
							Log.notice("waiting {timeout}ms", "");
							Scheduler.wait(timeout); // suspends the thread
							
						default: void;
					}
					retry(closure, {options with retry_count:retry_count-1});
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