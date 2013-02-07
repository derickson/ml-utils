xquery version "1.0-ml";

(:~
	Utility library for controlling sonos internet base station
:)

module namespace ls = "http://derickson/lib/l-sonos";

declare variable $hostPort := "10.0.1.2:1400";
declare variable $SONOS := fn:concat("http://",$hostPort);

declare function ls:headers($host as xs:string,$endpoint as xs:string){
	<headers xmlns="xdmp:http">{
		element CONNECTION {"close"},
		element ACCEPT-ENCODING {"gzip"},
		element HOST {$host},
		element CONTENT-TYPE {'text/xml; charset="utf-8"'},
		element SOAPACTION {fn:concat('"urn:schemas-upnp-org:service:AVTransport:1#',$endpoint,'"')}
	}</headers>
};

declare function ls:funk() {

	xdmp:http-post( fn:concat($SONOS,"/MediaRenderer/AVTransport/Control"),
	    <options xmlns="xdmp:http">{ls:headers($hostPort,"RemoveAllTracksFromQueue")}</options>,
		text{xdmp:quote(<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:RemoveAllTracksFromQueue xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:RemoveAllTracksFromQueue></s:Body></s:Envelope>)}
	),
	
	xdmp:sleep(1000),
	
	xdmp:http-post( fn:concat($SONOS,"/MediaRenderer/AVTransport/Control"),
	    <options xmlns="xdmp:http">{ls:headers($hostPort,"AddURIToQueue")}</options>,
		text{xdmp:quote(<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:AddURIToQueue xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><EnqueuedURI>x-rincon-cpcontainer:1006006cspotify%3auser%3adavejunk1%3aplaylist%3a1OzDDLJ98nincl2cbREWiT</EnqueuedURI><EnqueuedURIMetaData>&lt;DIDL-Lite xmlns:dc=&quot;http://purl.org/dc/elements/1.1/&quot; xmlns:upnp=&quot;urn:schemas-upnp-org:metadata-1-0/upnp/&quot; xmlns:r=&quot;urn:schemas-rinconnetworks-com:metadata-1-0/&quot; xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/&quot;&gt;&lt;item id=&quot;1006006cspotify%3auser%3adavejunk1%3aplaylist%3a1OzDDLJ98nincl2cbREWiT&quot; parentID=&quot;100a0064playlists&quot; restricted=&quot;true&quot;&gt;&lt;dc:title&gt;Electrofunkish Soul&lt;/dc:title&gt;&lt;upnp:class&gt;object.container.playlistContainer&lt;/upnp:class&gt;&lt;desc id=&quot;cdudn&quot; nameSpace=&quot;urn:schemas-rinconnetworks-com:metadata-1-0/&quot;&gt;SA_RINCON3079_davejunk1&lt;/desc&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;</EnqueuedURIMetaData><DesiredFirstTrackNumberEnqueued>0</DesiredFirstTrackNumberEnqueued><EnqueueAsNext>0</EnqueueAsNext></u:AddURIToQueue></s:Body></s:Envelope>)}
	),
	
	xdmp:sleep(1000),
	
	xdmp:http-post( fn:concat($SONOS,"/MediaRenderer/AVTransport/Control"),
	    <options xmlns="xdmp:http">{ls:headers($hostPort,"Play")}</options>,
		text{xdmp:quote(<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><Speed>1</Speed></u:Play></s:Body></s:Envelope>)})
	
};

