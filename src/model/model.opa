//
// src/model/model.opa
// @date: 02/2013
// @author: Diel Caroes
//
// This module contains all the types used as well as the synchronization algorithm.
//

import stdlib.{themes.bootstrap, widgets.bootstrap}
import stdlib.core.date
import stdlib.widgets.datepicker
import stdlib.core.rpc.core
import stdlib.core
import stdlib.tests
import stdlib.widgets.core;
import stdlib.widgets.sidepanel
import stdlib.widgets.grid
import stdlib.web.client

//a user is either a guest of logged in
type User.logginType = {guest} or {usr.n userType}

type usr.n={
  string user_name
} or {offline}


//user type
type usr = {
	usr.n user, 
	string user_pwd
}

//the geolocation (Latitude + Longitude)
type geo.loc = {
    float lat,
    float lon
}

//
type geo.code = {
    geo.loc loc,
    string formatted_address
}

//
type place = {
    string unverified_string
} or {geo.code geo_place} or {none}

//event type: contains all event information (type stays the same in client-side or server-side database)
type evt = {
	int event_id, 
	string event_name, 
	string event_description, 
	Date.date event_date, 
	usr.n user,
    place event_place,
	int clock
}

//local storagedata building block (some extra information is added to event)
type localData = { 
  evt data,  
  int next
} 

//points to the start of the local storage data list
type startPointer = {
	int first_element
}

//action for an event
type action = {new} or {update} or {remove}

//used when broadcasting an event. 
//Using actionEvent pair, we know what action is performed on what event
type actionEvent = {
    action action, 
    evt event
}

//the database to store the users
database users {
    usr /all[{user}]
}

//the database to store the events
database events {
    evt /all[{event_id}]
}


//lamport clock comparable algo
client module combine{

    @async function combine(){
        Logging.print("Start sync");
        //only relevant when online
        if(HTML5.checkOnline()){
            Logging.print("Phase 1")

                //function called to add events from db to local storage
                function maybeAdd(evt serverEvent){
                    match(ClientEvents.localEventData(serverEvent)){
                        case {success: _}:
                            Logging.print("Already there");
                            void;
                        case {failure: _}:
                            Logging.print("ADDED")
                            ClientEvents.addEvent(serverEvent);
                            
                            void;
                    }
                }

            // FROM server TO client    
            ServerEvents.all_event(function(evt serverEvent){
                
                Logging.print("serverEvent Sync: {serverEvent.event_id}");
                maybeAdd(serverEvent);

            });

            // FROM client TO server
            ClientEvents.localEvents(function(evt localEvnt){
                if(Util.negative(localEvnt.event_id)){
                    Logging.print("offline created event {localEvnt.event_id}")

                    e = match(User.loginType()){
                        case {guest}: 
                            Logging.print("local")
                            localEvnt
                        case ~{userType}: 
                            Logging.print("user")
                            {localEvnt with user:userType}
                    }

                    //offline created events
                    match(ServerEvents.addEvent(e)){
                        case ~{success: updEvt}:
                            Logging.print("local event in db")
                            ClientEvents.deleteEvent(localEvnt);//we delete local
                            Event.broadcast(updEvt, {new});//since broadcast will add it again to all clients including ourselfs
                        case {failure: _}: 
                            Logging.print("could not add local event to db");
                            void
                    }
                }

                match(ServerEvents.get_event(localEvnt)){
                    case ~{success: dbEvent}:
                        if(dbEvent.event_id==localEvnt.event_id){
                            if(localEvnt.clock==dbEvent.clock){
                                //clocks are equal => no different version on server or client
                            }else if(dbEvent.clock > Util.abs(localEvnt.clock) && Util.positive(localEvnt.clock)){//server higher than local
                        
                                //server has a newer version of a particular event => update local version
                                ClientEvents.updateEvent(dbEvent, false)//update DB event in local memory
                                void;
                            }else if(dbEvent.clock == Util.abs(localEvnt.clock)){ 

                                //client has a newer version & server version is still untouched => update server
                                //we make a new event from the old
                                evt updatedEvent={localEvnt with clock:dbEvent.clock+1};
                                
                                match(ServerEvents.editEvent(updatedEvent)){
                                    case ~{success: updEvt}:
                                        Event.broadcast(updEvt, {update});//since broadcast will add it again to all clients including ourselfs
                                    case {failure: _}: 
                                        
                                        void
                                }

                            }else{

                                ClientEvents.updateEvent(dbEvent, true)
                                void;

                            }
                        }else{

                          Logging.print("New offline created event")

                        }
                    case {failure: _}: 
                        //the event was deleted while we were offline -> delete in local
                        ClientEvents.deleteEvent(localEvnt);
                        Logging.print("deleted")
                }

                void
            }); 
            void
        }  
    }
}

module Logging{
    private logging=false;//true: all debug messages are printed, false: none are printed

    function print(string m){
        if(logging)
            jlog(m);
    }
}