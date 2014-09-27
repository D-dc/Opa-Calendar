//
// src/controller/controller.opa
// @date: 04/2013
// @author: Diel Caroes
//
//  This module calls the specific functions of the View part. 
//  It has two entry points: either the default calendar or the Google map.
//


module Controller {
    
    function dispatcher(Uri.relative url) {
        match (url) {//http entry points
            case {path: ["map", lat, lon] ...}: //to show place on map

                ViewMap.map_screen({lat:Float.of_string(lat), lon:Float.of_string(lon)});

            default: //default entry point

                ViewLogin.login_screen()
        }
    }

}

resources = @static_resource_directory("resources")

Server.start(Server.http, [
    { register:
        [ 
            { doctype: { html5 } },                     //HTML5 needed for localstorage etc
            { js: [ ] },                                //no external javascript (only compiled)
            { css: [ "/resources/css/style.css"] }      //some style adaptations
        ]
    },
    { ~resources },                                     //some other ressources
    { dispatch: Controller.dispatcher }                 //call the Controller dispatcher
])
