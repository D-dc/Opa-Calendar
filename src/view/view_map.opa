//
// src/view/view_map.opa
// @date: 04/2013
// @author: Diel Caroes
//
// 	Displays a Google map, centered on given geolocation. It uses stdlib.apis.gmaps; to do this.
//


import stdlib.apis.gmaps;

module ViewMap{
	private apiKey="AIzaSyB40792kegbCHIERreFI-l46xyPcvj2vBA";

	function centered_map(geo.loc centerPos){
		config = Gmaps.default_map;
		my_config = {config with center:{lat:centerPos.lat, lng:centerPos.lon}}
		map(my_config)
	}

	function default_map(){
		map(Gmaps.default_map);
	}

	function map(a){
		Gmaps.single_map_elt(apiKey, "map", a);
	}

	function ShowCenteredMap(geo.loc Pos){
		centered_map(Pos);
	}

	function map_screen(geo.loc Pos){
		html =	
				<>
					<div id="map"></>
					{ShowCenteredMap(Pos)}
				</>
		View.page_template("Map", html);
	}
		
}