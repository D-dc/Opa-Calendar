//
// src/model/server_event.opa
// @date: 03/2013
// @author: Diel Caroes
//
//  This is the server-side code for managing events. 
//  Mainly for adding, updating or deleting events from and to the database.


module ServerEvents {

    /*
        Look up the exact place
    */
    private function place PlaceTransformer(string place){
        //Remember: type place = {string unverified_string} or {geo.code geo_place} or {none}
        if(String.is_empty(place)){
            //no place information was given
            {none}
        }else{

            match(GeoCode.to_GeoCode_sync(place)){
                case {failure}: //geocode not found

                    Logging.print("geo failed")
                    {unverified_string: place};
                case ~{success}: //geocode found

                    Logging.print("geo succeed")
                    {geo_place: success} //is of the type 'geo.code'
            }
        }    
    }

    /*
        Count the tuples from a database path
    */
    private function countTuples(path){
        int number = Iter.count(DbSet.iterator(path))
        number
    }

    /*
        Ask for a new primary key
    */
    private function newPrimaryKey(){
        dbset(evt, _) event1 = /events/all[ order +event_id]
        iter it = DbSet.iterator(event1);
        newId = Mutable.make(0);//trick

        Iter.iter(function(e){
            Logging.print("ID {e.event_id}")
            newId.set(e.event_id);
            void
        }, it);
        newId.get()+1;
    }

    /*
        Loop over all tuples in a database path, using function f
    */
    private function allRecords((_ -> void) f, path){
        iter it = DbSet.iterator(path)
        if(Iter.is_empty(it)==false){
            Logging.print("nonempty db")
            Iter.iter(f, it)
        }else{
            Logging.print("empty db")
        }  
        void
    }
    
    /*
        Entry point for looping over all events
    */
    exposed function all_event((_ -> void) f){
        allRecords(f, /events/all);
    }

    /*
        Entry point for adding an event tot the database
    */
    exposed function outcome(evt, string) addEvent(evt Event){
        //we make some improvements to the existing object
        event_id = newPrimaryKey();

        event_place = 
            match(Event.event_place){
                case ~{unverified_string: pl_st}:
                    PlaceTransformer(pl_st);
                default: {none}
            } 

        evt e = {Event with ~event_id, ~event_place}
    
        match (?/events/all[{~event_id}]) {
            case {none}: 
                /events/all[{~event_id}] <- e; //the actual save
                {success: e}//return the improved object
            case {some: _}: 
                {failure: "no primary key found"}
        }
    }

    /*
        Checks if a specific event exists in the database, if it exists it is returned in the success outcome
    */
    private function outcome(evt, string) eventExists(evt e){
        match (?/events/all[{event_id: e.event_id}]) {
            case {none}: 
                {failure: "not found"}
            case {some: evnt}:  
                {success: evnt}
        }
    }

    /*
        Entry point for editing or updating an event from the database
    */
    exposed function outcome editEvent(evt e){
        //we make some improvements to the existing object

        event_place = 
            match(e.event_place){
                case ~{unverified_string: pl_st}:
                    PlaceTransformer(pl_st);
                default: {none}
            }

        evt e = {e with ~event_place} 

        match(eventExists(e)){
            case {success: _}: 
                /events/all[{event_id:e.event_id}] <- e;
                {success: e}  //return the improved event
            case {failure: msg}: 
                {failure: msg};
        }
    }

    /*
        Entry point for removing an event from the database
    */
    exposed function removeEvent(evt e){
        match(eventExists(e)){
            case {success: _}: 
                Db.remove(@/events/all[{event_id:e.event_id}]);
                {success: e};
            case {failure: msg}: 
                {failure: msg};
        }
    }

    /*
        Entry point to get the server equivalent of a given event
    */
    exposed function get_event(evt e){
        match(eventExists(e)){
            case {success: _}:
                evt a = /events/all[{event_id: e.event_id}] 
                {success: a};
            case {failure: msg}: 
                {failure: msg};
        }
    }

    /*
        Check if there is an event on a specific date.
    */
    function bool eventOnDate(Date.date d){
        dbset(evt, _) e= /events/all[event_date >= Date.round_to_day(d) and event_date < Date.advance_by_days(Date.round_to_day(d), 1)]
        iter it = DbSet.iterator(e)

        (Iter.count(it)==0);

    }

}