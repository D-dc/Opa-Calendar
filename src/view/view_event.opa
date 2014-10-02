//
// src/view/view_calendar.opa
// @date: 03/2013
// @author: Diel Caroes
//
//  This module contains the HTML code for the screens used for adding, removing or updating events. 
//  It also takes the input values and passes it along to the model.
//

client module ViewEvent{
    
    /*
        We take the form input information, call Event.addMeeting and inform the user of the result
    */
	function addMeeting(_){
		//gather form data, perform action & inform
		Helper.required(#meeting_date, "Please make sure the date is filled in", function(meetingDate){
      		
            //gather form data
            string event_name = Dom.get_value(#meeting_name);
      		string event_description = Dom.get_value(#meeting_description);
            string meetingPlace= Dom.get_value(#meeting_place);

            match(Date.of_formatted_string(Date.generate_scanner("%d/%m/%Y %R"), meetingDate)){//%A %B %d %Y %R
                case {none}: 
                    
                    //temporarily failure handling
                    Failure.direct_inform("Unable to interpret date");

                case {some: event_date}:
                    evt event = {event_id: 0, ~event_name, ~event_description, ~event_date, 
                                user:{user_name:"dummy"}, event_place: {unverified_string: meetingPlace}, clock:1};
      		        match(Event.addMeeting(event)){
                        case {success}: 
                            Dom.clear_value(#meeting_name);
                            Dom.clear_value(#meeting_description);
                            Dom.clear_value(#meeting_date);
                            Dom.clear_value(#meeting_place);
                            
                            View.alert("Meeting '{event_name}' has been created!", "success", true);
                            
                        case {failure: msg}:
                            //temporarily failure handling
                            Failure.direct_inform("Meeting '{event_name}' could not be created: {msg}"); 
                    }
                    hideMeetingViews();
            }
                        
      	});	
	}


    /*
        We take the form data, perfom the action and inform the client of the result.
    */
	function editMeeting(int event_id, int clock, user){
        
		//gather form data, perform action & inform
		Helper.required(#meeting_edit_date, "Please make sure the date is filled in", function(meetingDate){

            //gather form data
      		string event_name = Dom.get_value(#meeting_edit_name);
      		string event_description = Dom.get_value(#meeting_edit_description);
            string meetingPlace= Dom.get_value(#meeting_edit_place);

            match(Date.of_formatted_string(Date.generate_scanner("%d/%m/%Y %R"), meetingDate)){
                case {none}: 
                    
                    //temporarily failure handling
                    Failure.direct_inform("Unable to interpret date");
                case {some: event_date}:
                    evt event={~event_id, ~event_name, ~event_description, ~event_date, ~user, event_place: {unverified_string: meetingPlace}, ~clock}
                    match(Event.editMeeting(event)){
                        case {success}: 
                            View.alert("Meeting '{event_name}' has been modified.", "success", true);
                            
                        case {failure: msg}: 
                           
                            //temporarily failure handling
                            Failure.direct_inform("Unable to modify meeting: {msg}");
                            
                    }
                    hideMeetingViews();
            } 
      	});	
	}


    /*
        Given a specific date, show the meetings on that date
    */
	function showMeetings(Date.date selectedDate){

        displayMeeting(function(date){ (Date.round_to_day(date)==selectedDate)}, Event.dataMeeting());  

	}



    /*
        Delete a selected event and inform the user of the result
    */
    function deleteEvent(evt event){
        match(Event.deleteMeeting(event)){
            case {success: _}: 
                hideMeetingViews();
                View.alert("Event '{event.event_name}' has been deleted.", "success", true);
                
            case {failure: msg}:
                //temporarily failure handling
                Failure.direct_inform("Unable to delete event: {msg}");
        }
    }

    /*
        Functions loads the meeting data and fills in the forms used for editting an existing meeting
    */
    client function LoadMeetingData(evnt){
        Dom.unbind_event(#meeting_edit_submit, {click}) //remove previous binding when editing multiple events
        Dom.hide(#meeting_scheduler);
        Modal.show(#meeting_edit);
        Dom.set_value(#meeting_edit_date, {Date.to_formatted_string(Date.generate_printer("%d/%m/%Y %R"), evnt.event_date)});
        Dom.set_value(#meeting_edit_name, evnt.event_name);
        placeStr=
            match(evnt.event_place){
                case ~{unverified_string: a}: a;
                case ~{geo_place: a}: a.formatted_address;
                default: ""
            }
        Dom.set_value(#meeting_edit_place, placeStr)
        Dom.set_value(#meeting_edit_description, evnt.event_description);
        Dom.bind(#meeting_edit_submit, {click}, function(_){
            ViewEvent.editMeeting(evnt.event_id, evnt.clock, evnt.user);
            void
        });
        void
    }

    /*
        The actual display meeting, it will loop using 'loopFunc' and select requested events using 'selectFunc'
    */
	function displayMeeting((Date.date -> bool) selectFunc, ((evt ->void) -> void) loopFunc){
		#meetings="";

	    loopFunc(function(evnt){
	      	if(selectFunc(evnt.event_date)){
                //some filters for username and place information
                userN = 
                    match(evnt.user){
                        case ~{user_name}: user_name;
                        default: "";
                    }

                place =
                    match(evnt.event_place){
                        case ~{geo_place: g}: <a href="/map/{g.loc.lat}/{g.loc.lon}/" target="_blank">{g.formatted_address}</>;
                        case ~{unverified_string: g}: <>{g}</>;
                        default: <>/</>;
                    }

	        	#meetings =+ 
	              <div class="row line">
	                <div class="span4 muted"><i class="icon-list-alt" /> {Date.to_formatted_string(Date.generate_printer("%A %B %d %Y %R"), evnt.event_date)}</div>
	                <div class="span2">
	                  
                        <a href="#" class="btn btn-mini pull-right" id=remove_button onclick={function(_){
                               ViewEvent.deleteEvent(evnt);
                               Dom.unbind_event(#remove_button, {click}) //remove previous binding when editing multiple events
                            }}>
                            DELETE<i class="icon-remove" />
                        </a>
                        <a href="#" class="btn btn-mini pull-right" onclick={function(_){
                            LoadMeetingData(evnt);
                          }}>   
	                       EDIT<i class="icon-pencil" />
                        </a>
	                </div>
	             </div>
	             <div class="row line">
	                <div class="span6">
	                   <span class="label label-info">{evnt.event_name}</span> 
	                   {evnt.event_description}
	                </div>
	            </div>
                <div class="row line breadcrumb">
                    <div class="span6">
                        <div class="span3 text-info">
                            <small>
                                <i class="icon-user" /> {userN}
                            </>
                        </div>
                        <div class="span3 muted">
                            <small>
                                <i class="icon-globe" /> {place}
                            </>
                        </div>
                    </div>  
                </div>
              <hr />;
	      	}
	    });
	    
	    //show a message when no meetings were scheduled on the requested date
	    if(Dom.get_content(#meetings)==""){
	      	WBootstrap.Alert.content t={title:"No meetings", description: <>there are no meetings on the selected date.</>};
	      	#meetings=WBootstrap.Alert.make_alert(true, t);
	    }

        #meetings =+ <button class="btn btn-primary pull-right" onclick={function(_){
                            Modal.show(#meeting_scheduler);
                        }}>
                        <i class="icon-edit icon-white"></i> New Event
                    </button>;
	}


    /*
        Function to hide all the views of a selected date
    */
    private function hideMeetingViews(){
        Dom.hide(#meeting_viewer);
        Modal.hide(#meeting_edit);
        Modal.hide(#meeting_scheduler);
    }

	
    /*
        The event scheduler screen
    */
	function EventSchedulerScreen(){
        Modal.make("meeting_scheduler", <>Schedule a meeting</>,
            <>
                <input id=meeting_name type="text" class="input-block-level" placeholder="Meeting name">
                <textarea id=meeting_description class="input-block-level" placeholder="Meeting description"></textarea>
                <div class="input-prepend">
                    <span class="add-on"><i class="icon-globe"></i></span>
                    <input id=meeting_place type="text" class="input-large" placeholder="Meeting Location">
                </>
                <div class="input-prepend">
                    <span class="add-on"><i class="icon-calendar"></i></span>
                    <input id=meeting_date type="text" class="input-large" placeholder="Date">
                </div>
            </>,
            <button id=meeting_submit class="btn btn-primary" type="submit" onclick={addMeeting(_)}>Add new meeting</button>
            <button class="btn btn-danger" onclick={function(_){
                    Modal.hide(#meeting_scheduler)
                  }}>Cancel</button>, 
            Modal.default_options);
    }


    /*
        The edit event screen
    */
    function EventEditScreen(){
        Modal.make("meeting_edit", <>Edit a meeting</>,
            <>
                <input id=meeting_edit_name type="text" class="input-block-level" placeholder="Meeting name">
                <textarea id=meeting_edit_description class="input-block-level" placeholder="Meeting description"></textarea>
                <div class="input-prepend">
                    <span class="add-on"><i class="icon-globe"></i></span>
                    <input id=meeting_edit_place type="text" class="input-large" placeholder="Meeting Location">
                </div>
                <div class="input-prepend">
                    <span class="add-on"><i class="icon-calendar"></i></span>
                    <input id=meeting_edit_date type="text" class="input-large" placeholder="Date">
                </div>
            </>,
            <button id=meeting_edit_submit class="btn btn-primary" type="submit">Edit meeting</button>
            <button class="btn btn-danger" onclick={function(_){
                Modal.hide(#meeting_edit)
              }}>Cancel</button>,
            Modal.default_options);
    }


    /*
        The event viewer screen, hidden at first
    */
    function EventViewerScreen(){
        <div id=meeting_viewer onready={function(_){hideMeetingViews();}}>
            <h2>Meetings</h2>
            <div id=meetings></div>
        </div>
    }

}