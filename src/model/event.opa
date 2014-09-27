//
// src/model/event.opa
// @date: 03/2013
// @author: Diel Caroes
//
//  THIS MODULE IS USED TO add, edit, remove from localstorage or database depending on whether the client is online or not.
//


module Event{

    private Network.network(actionEvent) room = Network.cloud("room")

    /*
        Function which takes an (updated) event and an action (= {new}, {update}, {remove}) and forms an actionEvent which is broadcasted to everyone
    */
    exposed function broadcast(evt event, action action){
        actionEvent actev ={~action, ~event}
        Network.broadcast(actev, room);
    }

    /*
        Adapt calendar to changes by other clients (changes to an event are broadcasted and handled here).
        Since an actionEvent contains the action (=update,new,remove...) and the new information including the id which is
        the same over all clients we know which event we need to update.
    */
    client function broadcast_calendar_handler(actionEvent actEvnt){
        Logging.print("BROADCAST - RECEIVED {actEvnt}")
        res = match(actEvnt){
            case {action: {update}, ~event}:

                //some client UPDATEd an event (can be a reschedule)
                Logging.print("UPDATE")
                ClientEvents.updateEvent(event, false);
          
            case {action: {new}, ~event}:

                //some client created a NEW event 
                Logging.print("NEW")
                ClientEvents.addEvent(event);//add new event to local storage

            case {action: {remove}, ~event}:

                //some client REMOVED an event
                Logging.print("REMOVE")
                ClientEvents.deleteEvent(event);//delete the event from local storage

        }

        match(res){
            case {failure: msg}: 
                //temporarily failure handling
                Failure.graceful_inform(msg);
            case {success}: void;
        }        
             
    }

    /*
        The callback
    */
    function register_evt_callback(){
        Network.add_callback(broadcast_calendar_handler, room);
    }

    /*
        This function (which resides on the server) takes an action from the higher order function 'func'. 
        This usually is an add, edit, delete for an event on the server (for the database).
        If the server confirms it, its new state is broadcasted to everyone.
        If it is not confirmed the failmsg is passed along.

    */
    server function serverConfirmAndBroadcast(func, event, action, failmsg){
        closure = function(){
            match(func(event)){
                case ~{success: DBevt}: 
                    //perform broadcast to inform other clients -> will invoke for example for 'update' 
                    //the function  ClientEvents.updateEvent(event); on all clients (including ourselfs)
                    broadcast(DBevt, action);
                    {success}
                case {failure: _}: 
                    {failure: failmsg}
            }
        } 

        //temporarily failure handling
        Failure.retry_on_failure(closure, 1); //retry once
    }

    /*
        ADD A MEETING
    */
    function addMeeting(evt eventOld){
    
        if(HTML5.checkOnline()==false){
            //we are offline => update local only
            event = {eventOld with user:{offline}}
            evt updatedEvent= {event with event_id:ClientEvents.NewLocalId()}//we use a temporarily local id.
            ClientEvents.addEvent(updatedEvent);
            {success}

        }else{
            match(User.loginType()){
                case {guest}: 

                    {failure: "Cannot create event as guest."}

                case ~{userType}:
                
                    event = {eventOld with user:userType}
                    serverConfirmAndBroadcast(ServerEvents.addEvent, event, {new}, "unable to create event on the server");
                    
            }
        }    
    }


    /**
        EDIT AN EXISTING MEETING
        local event is updated either in offline or online mode, the server event is only updated when online
    */
    function outcome editMeeting(evt evnt){    
          
        if(HTML5.checkOnline()){
            //we perform an update when connected with server => clock+1
            evt event={evnt with clock:evnt.clock+1}
            serverConfirmAndBroadcast(ServerEvents.editEvent, event, {update}, "Unable to modify meeting");

        }else{
            //we perform an update when in offline mode => use negative current clock to indicate
            evt event={evnt with clock:-Util.abs(evnt.clock)}
            ClientEvents.updateEvent(event, false);//save local since we are offline
            {success}

        }
    }

    /**
      Getter for the meeting data. We could here decide to give the localdata (much faster) or the serverdata (results in multiple xhr)
      In this implementation we decide to always use the events stored on the client resulting in no xhr's to the server.
    */
    client function dataMeeting(){
        /*if(HTML5.checkOnline())
           ServerEvents.all_event;//we are online so we can use server-side data
        else
          //we are offline so use client-side persistent data*/
          
        ClientEvents.localEvents;

    }
  
    /**
        DELETE A MEETING
    */
    client function outcome deleteMeeting(evt event){
        if(HTML5.checkOnline()){
            //we are online, send request for deletion to the server
            serverConfirmAndBroadcast(ServerEvents.removeEvent, event, {remove}, "Unable to remove meeting");

        }else{
            // for simplicity we do not allow events to be deleted by the client when it is offline.
            {failure: "cannot delete event in offline mode"}
        }  
    }

  
}