//
// src/view/view_login.opa
// @date: 04/2013
// @author: Diel Caroes
//
//	This module contains all the HTML code for logging in and registering users. 
//	It also takes the input values and passes it along to the model.
//


module ViewLogin {
	/*
		Perform an asynchronous login request
	*/
	client @async function do_login(){
		Helper.required(#username, "Please make sure username is not empty.", function(username){
			pwd = Dom.get_value(#pwd);
			match(User.loginUser(username, pwd)){
				case {success}:
					
					View.alert("You are now logged in.", "success", true)
					#userDisplay = username;
					View.UserOptions();
					ViewCalendar.open_calendar();
					
				case {failure: msg}: 
					
					View.alert("No login: {msg}", "error", false)
			}
		});
	}

	/*
		Perform an asynchronous registration request
	*/
	client @async function do_registration(){
		Helper.required(#username, "Please make sure username is not empty.", function(username){
			pwd = Dom.get_value(#pwd);
			match(User.registerUser(username, pwd)){
				case {success}:
					
					View.alert("Account created, you can now log-in with he provided information.", "success", false)

				case {failure: msg}:
					
					View.alert("No registration: {msg}", "error", false)
			}
		});
	}

	/*
		The login screen
	*/
	function login_screen(){
		html = 
			<div>
				<h2>Calendar <small>Login to continue</small></h2>
				
				<form class="form-horizontal">
					<div class="control-group">
						<label class="control-label" for="username">Username</label>
						<div class="controls">
							<input id=username
			               		type=text
			               		placeholder="Username"
			               		onready={function(_){Dom.give_focus(#username)}}
			                />
			            </div>
			        </div>    
		            <div class="control-group">
						<label class="control-label" for="pwd">Password</label>
						<div class="controls">
			            	<input id=pwd
			            		type=password
			            		placeholder="Password"
			            	/>
			            </div>	
		            </div>
		            <div class="control-group">
    					<div class="form-actions">
		            		<a class="btn btn-success" onclick={function(_){do_login()}}>Login <i class="icon-check icon-white" /></a>
		            		<a class="btn btn-primary" onclick={function(_){do_registration()}}>Register <i class="icon-edit icon-white" /></a>
		            	</div>
		            </div>		
		        </form>    
			</div>
		View.page_template("Calendar application", html);
	}
}

