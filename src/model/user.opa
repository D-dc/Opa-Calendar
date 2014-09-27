//
// src/model/user.opa
// @date: 04/2013
// @author: Diel Caroes
//
//	This module contains the mechanisms to log in or register a user. 
//	The biggest part of the module will be on the server side since it is in strong relation with the database
//


import stdlib.crypto;

module User{
	private UserContext.t(User.logginType) logginType = UserContext.make({guest})

	/**
		Performs a registration for a new user
	*/
	exposed function outcome registerUser(string username, string userpwd){

		string user_name = String.to_lower(username);
		string user_pwd = Crypto.Hash.md5(userpwd);
		
		usr.n u = ~{user_name}
		usr user ={user:u, ~user_pwd}
		match(?/users/all[{user: u}]){
			case {none}:
				
				Logging.print("register attempt {user_name} {user_pwd}");
				/users/all[{user: u}] <- user;
				{success}

			case {some: _}:

				Logging.print("register failure: already taken");
				{failure: "username already taken."}

		}
		
	}

	/**
		Performs a user-login
	*/
	exposed function loginUser(string username, string userpwd){
		
		string user_name = String.to_lower(username);
		string user_pwd = Crypto.Hash.md5(userpwd);

		usr.n u = ~{user_name}
		match(?/users/all[{user:u}]){
			case {none}: 
				{failure: "username does not exists."}
			case {some: user}:
				if(user.user_pwd==user_pwd){
					usr.n usrCont = {user_name: user_name}
					UserContext.set(logginType, {userType:usrCont})
					{success}
				}else{
					{failure: "password incorrect."}
				}
				
		}
	}

	/**
		Current user type?
		returns {guest} or {usr.n user}
	*/
	client function loginType(){
		UserContext.get(logginType);		
	}

	/**
		Logout a user
	*/
	function logout(_){
		UserContext.set(logginType, {guest});
		Client.reload();
	}
}