xquery version "1.0-ml";

(:~
	XQuery library for controlling Phillips Hue light
	For MarkLogic 6.0 +
	
	@author derickson
:)

module namespace lh = "http://derickson/lib/l-mlhue";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
declare namespace jb ="http://marklogic.com/xdmp/json/basic";

declare variable $SETTINGS_URI := "/mlhue/hash.xml";
declare variable $HOST := "nibenay";

declare variable $key := lh:get-key();

(: 1.) set the ip of your hub :)
declare variable $ip := "10.0.1.20";


(:~
	Register this app.  Must be explicitly called after the hub link button has been pushed
:)
declare function lh:register() as xs:string {
	xdmp:http-post( fn:concat("http://",$ip,"/api"),
	    <options xmlns="xdmp:http">
	       <data>{json:transform-to-json( 
		<json type="object" xmlns="http://marklogic.com/xdmp/json/basic">
		  <username type="string">{$key}</username>
		  <devicetype type="string">mlhue</devicetype>
		</json>)}</data>
	       <headers>
	         <content-type>application/json</content-type>
	       </headers>
	     </options>
	)[2]
};

(:~
	get json status from the hub 
:)
declare function lh:status-j() as xs:string {
	xdmp:http-get(
		fn:concat("http://",$ip,"/api/",$key)
	)[2]
};

(:~
	Get the light ids
	@param status - json string of hub status from lh:status-j
	@return sequence of light ids
:)
declare function lh:light-ids-from-status($status as xs:string) as xs:int* {
	for $e in 
		<x>{xdmp:from-json( $status ) }</x>/node()
		//json:entry[@key eq "lights"]/json:value/json:object/json:entry
	return
		xs:int($e/@key)
};


(:~
	light state for HSB color
	@param h - hue degree between 0 and 360
	@param s - saturation between 0 and 100
	@param b - brightness between 0 and 100
	@return state map for use in light setters
:)
declare function lh:hsb($h as xs:int, $s as xs:int, $b as xs:int) as map:map {
	let $_ := if($h lt 0 or $h gt 360) then 
		fn:error(xs:QName("ERROR"), "$h must be between 0 and 360") else ()
	let $_ := if($s lt 0 or $s gt 100) then 
		fn:error(xs:QName("ERROR"), "$s must be between 0 and 100") else ()
	let $_ := if($b lt 0 or $b gt 100) then 
		fn:error(xs:QName("ERROR"), "$b must be between 0 and 100") else ()
	
	let $m := map:map()
	let $_ :=
	  (
	    map:put($m, "hue", $h * 182),
	    map:put($m, "sat", fn:ceiling($s div 100 * 254)),
		map:put($m, "bri", fn:ceiling($b div 100 * 254))
	  )
	return
		$m
};

(:~
	state for turning on and off lights
	@param on - Light on or off?
	@return state map for use in light setters
:)
declare function lh:on($on as xs:boolean) as map:map {
	let $m := map:map()
	let $_ :=
	  (
	    map:put($m, "on", $on)
	  )
	return
		$m
};

(:~
	Light setter by light id
	@param light - the light id
	@param m - light state map
:)
declare function lh:put-light-state( $light as xs:int, $m as map:map) {
	let $uri := fn:concat("http://",$ip,"/api/",$key,"/lights/",fn:string($light),"/state")
	let $state := lh:map-to-state($m)
	return
		xdmp:http-put($uri,(),text{$state})
};

(:~
	Light setter for all lights (group 0)
	@param light - the light id
	@param m - light state map
:)
declare function lh:put-all-state( $m as map:map ) {
	let $uri := fn:concat("http://",$ip,"/api/",$key,"/groups/0/action")
	let $state := lh:map-to-state($m)
	return
		xdmp:http-put($uri,(),text{$state})
};


(: ########## PRIVATE FUNCTIONS ##############:)


(:~
	Creates and saves settings db entry
:)
declare private function lh:create-settings() as xs:string {
	let $hash := xdmp:md5($HOST)
	let $time := fn:current-dateTime()
	let $uri := $SETTINGS_URI
	let $doc := 
	  element mlhue-settings { 
	    element lastModified { $time },
	    element apikey { $hash },
	    element host { $HOST }
	  }
	return
	  (xdmp:document-insert($uri, $doc, (), "mlhue"), $hash)
};

(:~
	Get the key if settings exist.  
	If the settings db entry does not exist, create it
:)
declare private function lh:get-key() as xs:string {
	if(fn:doc-available($SETTINGS_URI)) 
	then fn:doc($SETTINGS_URI)//*:apikey/fn:string()
	else lh:create-settings()
};


(:~
	Convert $m map to json state
	@param m - map of input keys/value pairs
	@return json state
:)
declare private function lh:map-to-state($m as map:map) as xs:string {
	xdmp:to-json(($m))
};