xquery version "3.1";

module namespace wdbRa = "https://github.com/dariok/wdbplus/RestAnnotations";

declare namespace anno = "https://github.com/dariok/wdbplus/annotations";

import module namespace json		= "http://www.json.org";
import module namespace wdb			= "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";
import module namespace wdbanno	= "https://github.com/dariok/wdbplus/anno" at "../modules/annotations.xqm";
import module namespace console	="http://exist-db.org/xquery/console";

declare namespace output	= "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei			= "http://www.tei-c.org/ns/1.0";
declare namespace rest		= "http://exquery.org/ns/restxq";
declare namespace http		= "http://expath.org/ns/http-client";
declare namespace sm			= "http://exist-db.org/xquery/securitymanager";
declare namespace session	= "http://exist-db.org/xquery/session";

declare variable $wdbRa:server			:= $wdb:server;
declare variable $wdbRa:collection	:= collection($wdb:data);

(:~
	:return all public full text annotations and those of the current user for $fileID
	:)
declare
	%rest:GET
	%rest:path("/edoc/anno/{$fileID}")
	%rest:produces("application/json")
	%output:method("json")
function wdbRa:getFileAnno ($fileID as xs:string) {
	(: get the username; use sm:real to avoid setuid conflicts :)
	let $username := xs:string(sm:id()//sm:real/sm:username)
	let $fileURI := xs:anyURI(wdb:getFilePath($fileID))
	
	let $public := wdbanno:getAnnoFile($fileURI, "")
	let $private := wdbanno:getAnnoFile($fileURI, $username)
	
	return
		<anno:anno>
			<anno:entry><anno:collection>{$public}</anno:collection><anno:user>{$username}</anno:user></anno:entry>
			{for $entry in ($public//anno:entry, $private//anno:entry)
			    return $entry
			}
		</anno:anno>
};

(:~
	: insert a new full text annotation
	:)
declare
	%rest:POST("{$body}")
	%rest:path("/edoc/anno/{$fileID}")
	%rest:consumes("application/json")
function wdbRa:insertAnno ($fileID as xs:string, $body as item()) {
	let $data := parse-json(util:base64-decode($body))
	
	(: check for minimum data before continuing :)
return if (not($data('from') or $data('text')))
	then (
		<rest:response>
			<http:response status="200">
				<http:header name="rest-status" value="REST:ERR" />
			</http:response>
		</rest:response>,
		"Missing content in message body: at least start and text must be supplied"
	)
	else
		let $username := xs:string(sm:id()//sm:real/sm:username)
		
		(: check whether the user may write :)
    return if ($username = 'guest')
    then
        (<rest:response>
            <http:response status="200">
                <http:header name="rest-status" value="REST:ERR" />
            </http:response>
        </rest:response>,
        "User guest is not allowed to create annotations")
    else
    let $ann := 
        <entry xmlns="https://github.com/dariok/wdbplus/annotations">
            <id>{util:uuid()}</id>
            <file>{$fileID}</file>
            <range from="{$data('from')}" to="{$data('to')}" />
            <cat>{$data('text')}</cat>
            <user>{$username}</user>
        </entry>
    let $file := $wdbRa:collection/id($fileID)[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]
    
    return if (count($file) = 0)
        then
    (<rest:response>
        <http:response status="200">
            <http:header name="rest-status" value="REST:ERR" />
        </http:response>
    </rest:response>,
    "no file found for ID " || $fileID)
        else 
        	let $annoFile := wdbanno:getAnnoFile(base-uri($file), $username)
        	return (
        		<rest:response>
        			<http:response status="200">
        				<http:header name="rest-status" value="REST:SUCCESS" />
        			</http:response>
        		</rest:response>,
    				update insert $ann into $annoFile/anno:anno
    			)
};