//
// src/model/client_event.opa
// @date: 03/2013
// @author: Diel Caroes
//
//  This module handles the client side of the event logic. Hence it is a client-side only module. It is used to handle the CRUD-operations on events.
//  IMPORTANT: the addEvent, deleteEvent and updateEvent will be called on every client!
//  - immediately if a client performs an action offline
//  - lateron if a broadcast is received
//  - on synchronization


client module ClientEvents{
    /*
       Add an event local
    */
    function addEvent(evt Event){
        Local.addNew(Event, Event.event_id);//save using on position 'event_id'
        highlightOnCalendar(Event.event_date)
    }

    /*
        Delete an event local
    */
    function deleteEvent(evt Event){
        //get the local data
        match(Local.getStorageDataById(Event.event_id)){
            case ~{success: oldData}:
                //since we delete the evend there is no point at keeping it highlighted on the calendar 
                unHighlightOnCalendar(oldData.event_date);
            case {failure}: 
                void    
        }
        
        //do the actual delete
        Local.deleteById(Event.event_id)//delete on position 'event_id'
        //maybe rehighlight the event date since there could be another event on that date
        meetingOnDay(Event.event_date)
    }

    /*
        Update/edit an event local 
    */
    function updateEvent(evt updatedEvent, viaConflict){
        //get local data
        match(Local.getStorageDataById(updatedEvent.event_id)){
            case ~{success: localData}: 
                
                //conflict->show alert
                if(Util.negative(localData.clock) && viaConflict==true){
                    Client.alert("The changes made in {localData.event_name} (local) are undone because of conflict.")
                    Logging.print("event in client is updated, but client local modififications are neglected")
                }                
                
                if((Util.positive(localData.clock) && viaConflict==false) || viaConflict==true){
                    //update on position 'event_id'
                    Local.updateById(updatedEvent, updatedEvent.event_id)
                    //maybe there is another event on the date we rescheduled the event
                    meetingOnDay(localData.event_date)
                    //highlight the new date of the event after the reschedule
                    highlightOnCalendar(updatedEvent.event_date);
                }
               
            case {failure}:
                //we got an update for an event that does not exists locally, cornercase which can occur between two syncs -> ignore
                void    
        } 
    }

    /*
        This function will highlight a specific day on the calendar if there is any meeting
        It is needed because when meetings are rescheduled their date is unhighlighted on the calendar but
        their could be another meeting on that day.
    */
    function meetingOnDay(Date.date selectedDate){
        //only local
        OnDate = Mutable.make(false);
        localEvents(function(evt event){
            if(Date.round_to_day(event.event_date)==Date.round_to_day(selectedDate)){
                OnDate.set(true);
            }
        });

        if(OnDate.get()){
            highlightOnCalendar(selectedDate);
        }else{
            unHighlightOnCalendar(selectedDate);
        }
    }

    /*
        Highlight a given date on the calendar
    */
    function highlightOnCalendar(Date.date d){
        Dom.set_class(Dom.select_id("{Date.in_milliseconds(Date.round_to_day(d))}"), "badge badge-success");
    }

    /*
        Make sure the given date is not highlighted on the calendar
    */
    function unHighlightOnCalendar(Date.date d){
        Dom.void_class(Dom.select_id("{Date.in_milliseconds(Date.round_to_day(d))}"));
    }


    /*
        Loop over the localdata with a function 
    */
    function localEvents((evt -> void) func){
        Local.loopLocal(func);
    }


    /*
        new local id
        returns a negative new local id.
    */
    function int NewLocalId(){
        newId = Mutable.make(0);
        Local.loopLocal(function(evt e){
            if(newId.get() < Util.abs(e.event_id))
                newId.set(Util.abs(e.event_id))
        })
        

        if(Util.negative(newId.get())){
            newId.get()-1;
        }else{
            -newId.get()-1;
        }    
    }


    /*
        Get data from localstorage
    */
    function outcome(evt, string) localEventData(evt Event){
        match(Local.getStorageDataById(Event.event_id)){
            case ~{success: oldData}: 

                {success: oldData}

            case {failure}:
                //There is no local storage for the given id
                {failure: "local storage does not exists."}   

        }
    }
}  