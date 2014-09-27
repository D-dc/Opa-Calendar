//
// src/model/placeparser.opa
// @date: 04/2013
// @author: Diel Caroes
//
//	This module contains the parser for google geocode.
//


module PlaceParser{
	`xmlns:` = "" //BUG; see http://forum.opalang.org/0_257
		
	//components which are ignored
	unused_comp = 
		xml_parser {
			case 
				<address_component>_*</address_component>: void
			case 
				<type>_*</type>: void
			case 
				<status>_*</status>: void	
		}

	//the geometry component which will create a geo.loc type
	geometry_comp = 
		xml_parser {
			case 
				<geometry>
					<location>
						<lat>lat={Xml.Rule.float}</lat>
						<lng>lon={Xml.Rule.float}</lng>
					</location>
					<location_type>_*</location_type>
					<viewport>_*</viewport>
				</geometry>: ~{lat, lon}
		}
		
	//we also take the formatted address, which gives a nice representation of the typed query
	formatted_comp = 
		xml_parser { 
			case 
				<formatted_address>addr={Xml.Rule.string}</formatted_address>: addr
		}
	
	//the result component	
	result_comp = 
		xml_parser {
			case 
				<result>
					t={unused_comp}+ 
					addr={formatted_comp} 
					a_comp={unused_comp}+ 
					geo={geometry_comp}
				</result>: {loc:geo, formatted_address:addr}
		}	
		
	//the actual parser
	m_parser = 
		xml_parser {
			case 
				<GeocodeResponse>
					status={unused_comp}
					result={result_comp}
				</GeocodeResponse>: result
		}

	//given a string containing xml, this function will do the parsing
	function Parse(string test_xml){
		match(Xmlns.try_parse_document(test_xml)){
			case ~{some: s}:

				Logging.print("{s.element}")

				match(XmlParser.try_parse(m_parser, s.element)){
					case {none}: 

						Logging.print("parse fail");
						{failure}//parsing failed

					case ~{some: res}: 

						Logging.print("parse succeed: {res.formatted_address}");
						{success: res}
				};

			default: {failure}//parsing failed

		}
	}
}