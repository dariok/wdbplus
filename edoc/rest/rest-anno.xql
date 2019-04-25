xquery version "3.1";

module namespace wdbRa = "https://github.com/dariok/wdbplus/RestAnnotations";

declare namespace anno = "https://github.com/dariok/wdbplus/annotations";

import module namespace json    = "http://www.json.org";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"  at "../modules/app.xqm";
import module namespace wdbanno = "https://github.com/dariok/wdbplus/anno" at "../modules/annotations.xqm";
import module namespace console ="http://exist-db.org/xquery/console";

declare namespace output	= "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei			= "http://www.tei-c.org/ns/1.0";
declare namespace rest		= "http://exquery.org/ns/restxq";
declare namespace http		= "http://expath.org/ns/http-client";
declare namespace sm			= "http://exist-db.org/xquery/securitymanager";
declare namespace session	= "http://exist-db.org/xquery/session";

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
	
	return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <anno:anno>
      <anno:entry><anno:collection>{$public}</anno:collection><anno:user>{$username}</anno:user></anno:entry>
      {for $entry in ($public//anno:entry, $private//anno:entry)
        return $entry
      }
    </anno:anno>
  )
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
	(: TODO update these checks like in changeWords! :)
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
    let $file := $wdb:data/id($fileID)[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]
    
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
                <http:header name="Access-Control-Allow-Origin" value="*"/>
              </http:response>
            </rest:response>,
    				update insert $ann into $annoFile/anno:anno
    			)
};

(:~
	: surround w with rs and a given type
	:)
declare
	%rest:POST("{$body}")
	%rest:path("/edoc/anno/entity/{$fileID}")
	%rest:consumes("application/json")
function wdbRa:markEntity ($fileID as xs:string, $body as item()) {
	let $data := parse-json(util:base64-decode($body))
	(: TODO update these checks like in changeWords! :)
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
    let $file := $wdb:data/id($fileID)[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]
    return if (count($file) = 0)
        then
    (<rest:response>
        <http:response status="200">
            <http:header name="rest-status" value="REST:ERR" />
        </http:response>
    </rest:response>,
    "no file found for ID " || $fileID)
        else
            let $t := console:log($data)
            let $content := (
        		$file/id($data("from")), 
        		if ($data("from") != $data("to")) then ($file/id($data("from"))/following-sibling::tei:* intersect $file/id($data("to"))/preceding-sibling::tei:*, 
        			$file/id($data("to"))) else () 
        	)
        
        let $ins := element { QName("http://www.tei-c.org/ns/1.0", "rs") } {
        	attribute type { $data("type") },
        	attribute ref { 'per:' || translate($data("identity"), ' ,', '_') },
        	$content }
        	return (
            <rest:response>
              <http:response status="200">
                <http:header name="rest-status" value="REST:SUCCESS" />
                <http:header name="Access-Control-Allow-Origin" value="*"/>
              </http:response>
            </rest:response>,
    				update replace $content[1] with $ins,
    				update delete $content[position() > 1]
    			)
};

declare
	%rest:POST("{$body}")
	%rest:path("/edoc/anno/word/{$fileID}")
	%rest:consumes("application/json")
	%rest:produces("application/json")
	%output:method("json")
function wdbRa:changeWords ($fileID as xs:string, $body as item()) {
	let $data := parse-json(util:base64-decode($body))
	let $filePath := wdb:getFilePath(xs:anyURI($fileID))
	let $doc := doc($filePath)
	
	(: check whether all necessary data are present :)
	let $checkData := if (not($data("id") or $data("text") or $data("job")))
		then <error>Missing content in message body: at least start and text must be supplied</error>
		else ()
	
	(: check whether the user may write :)
	let $checkWrite := if (not(sm:has-access($filePath, 'w')))
		then <error>The current user ({xs:string(sm:id()//sm:real/sm:username)}) does not have sufficient rights to write to the requested file</error>
		else ()
	
	(: check whether the token ID exists :)
	let $token := $doc/id($data("id"))
	let $checkID := if ($token)
		then if (count($token) = 1 and not($data('job') = "combine"))
			then if ($token[self::tei:w or self::tei:pc])
				then ()
				else <error>The requested ID does not refer to a single token (tei:w or tei:pc)</error>
			else <error>The ID refers to more than one token</error>
		else <error>The requested token-ID could not be found in the file</error>
	
	(: check the job :)
	let $checkJob := if ($data("job") = ("edit"))
		then ()
		else <error>Unknown job description</error>
	
	return if ($checkData | $checkWrite | $checkID | $checkJob)
		then (
			<rest:response>
				<http:response status="200">
					<http:header name="rest-status" value="REST:ERR" />
				</http:response>
			</rest:response>,
			string-join(($checkData, $checkWrite, $checkID, $checkJob), ' – ')
		)
		else (
      <rest:response>
        <http:response status="200">
          <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
			switch ($data("job"))
			case "edit" return
				let $d := console:log($token)
				let $u := if ($token/tei:lb)
					then
						let $id := $token/@xml:id
						let $lb := $token/tei:lb
						let $text := tokenize($data("text"), '\|')
						let $pid := if ($token/tei:pc)
							then $token/tei:pc/@xml:id
							else ()
						let $pc := <pc>{$pid, substring($text[1], string-length($text[1]))}</pc>
						let $d1 := console:log($text)
						let $repl :=
							<w xmlns="http://www.tei-c.org/ns/1.0">{$id,
								substring($text[1], 1, string-length($text[1]) - 1),
								$pc,
								$lb,
								$text[2]
							}</w>
						return update replace $token with $repl
					else update value $token with $data("text")
				return $doc/id($data("id"))
			default return ""
		)
};