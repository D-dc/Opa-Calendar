//
// src/view/view.opa
// @date: 03/2013
// @author: Diel Caroes
//
//  Contains HTML for some of the views GUI.
//


import stdlib.widgets.bootstrap.{modal, alert, dropdown}

module View {
    /*
        Function which will display user online/offline
    */
    client function checkOnline(){

        if(HTML5.checkOnline()){
      
            Dom.set_class(#service, "label label-success");
            #service= <><i class="icon-user icon-white" /> online</>;
      
        }else{

          Dom.set_class(#service, "label label-warning");
          Dom.set_text(#service, "offline");
      
        }
    }

    /*
        Function which enables us to call a function every interval
    */
    client function create_timer(interval) {
        timer = Scheduler.make_timer(interval, function() {
            checkOnline()
        })
        timer.start()
        void
    }

    /*
        Display user action possibilities
    */
    function UserOptions(){
    
        #userDisplay = 
            match(User.loginType()){

                case {guest}: 
                  
                  <>Guest</>
                  
                case ~{userType}:
                    userN = 
                        match(userType){
                            case ~{user_name}: user_name;
                            case {offline}: "";
                        }
                    Dom.set_class(#dropLinks, "dropdown-menu"); 
                    #dropLinks= <li id=#sync onclick={function(_){Modal.show(#syncScreen);}}>
                                    <a href="#">
                                        <i class="icon-refresh" /> Synchronize
                                    </>
                                </>
                                <li class="divider"></li>
                                <li onclick={User.logout(_)}>
                                    <a tabindex="-1" href="#">Logout</>
                                </li>;

                    <>{userN} <b class=caret></b></>
            }
    }

    /*
        Function to be called when initial pageload is finished
    */
    function onLoaded(_){
        //use session for calendar user interactions
        Event.register_evt_callback();
    
        //perform a sync (between client and server)
        combine.combine();
            
        //create the online / offline timer 
        create_timer(2000);

        //show appropriate action possibilities
        UserOptions();
    }

    /*
        Function to show an information message
        error_type=  "success" | "error"
        hideAfter= hide the messsage after a couple of seconds
    */
    function void alert(msg, error_type, bool hideAfter){
        Dom.transition(#msgInform, Dom.Effect.with_duration({slow}, Dom.Effect.fade_in()))
        #msgInform =
            <div class="alert alert-{error_type}">
                <button type="button" class="close" data-dismiss="alert">x</button>
                {msg}
            </div>;

        if(hideAfter){
            Dom.transition(#msgInform, Dom.Effect.with_duration({millisec: 1500}, Dom.Effect.fade_out()));
            void
        }
        void
    }

    /*
        The default page
     */
    function page_template(title, content) {//the default template
    
       
        //popup synchronize screen
        syncScreen=Modal.make("syncScreen",

            <>Synchronize</>,

            <p>Synchronize the local storage with the database.</p>,

            <button class="btn" onclick={function(_){
                Modal.hide(#syncScreen);
            }}>Close</>
            
            <button class="btn btn-danger" onclick={function(_){
                  HTML5.clearStorage();
                  ViewCalendar.unhighlightMeetings();
                }}>Reset local storage</button>

            <button class="btn btn-primary" onclick={function(_){
                Modal.hide(#syncScreen); 
                combine.combine();
                View.alert("Synchronization completed", "success", true)
              }}>Start Synchronizing</button>,

            Modal.default_options);

        //default page HTML
        html =
            <div class="navbar navbar-fixed-top" onready={onLoaded(_)}>
                <div class=navbar-inner>
                    <div class=container>
                        <div class="row">
                            <div class="span7">
                                <a class=brand href="./index.html">calendar</>
                            </div>
                            <div class="span3">
                                <ul class="nav pull-right">
                                    <li id=#service></>
                                    <li class="divider-vertical"></li>
                                    <li class="dropdown">
                                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" id=#userDisplay></a>
                                        <ul id=#dropLinks></ul>
                                    </li>
                                </ul>
                            </div>  
                        </div>  
                    </div>
                </div>
            </div>
            <div class=hero-unit>
                {syncScreen}
                <div class="container" id=#msgInform></div>
                <div class="container" id=#main>{content}</div>
            </div>;
        Resource.page(title, html)
    }
}