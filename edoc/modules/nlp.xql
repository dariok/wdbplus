xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace anno = "https://github.com/dariok/wdbplus/annotations";

import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"  at "../modules/app.xql";

declare function local:spacyExport($doc, $fr) {
if ($fr = "0")
	then "both a file ID and a fragment identifier have to be supplied"
	
	else
		let $fra := $doc/id($fr)
		
		return if (not($fra))
		then "could not find fragment " || $fr || " in file " || base-uri($doc)
		
		else 
			let $r := for $n in $fra//tei:w | $fra//tei:pc
				let $w := if(normalize-space($n/following-sibling::node()[1]) = "") then true() else false()
				return map {
					"tokenId": normalize-space($n/@xml:id),
					"whitespace": $w,
					"value": if ($n//tei:corr) then $n//tei:corr
						else if ($n/tei:reg) then $n//tei:reg
						else normalize-space($n)
				}
			
			return serialize($r,
				<output:serialization-parameters>
					<output:method>json</output:method>
				</output:serialization-parameters>
			)
};

declare function local:getAnnoFile($file, $username) {
    let $annCollName := substring-before(substring-after(base-uri($file), 'data/'), '.xml')
    let $annColl := if (xmldb:collection-available($wdb:edocBaseDB || '/annotations/' || $annCollName))
        then $wdb:edocBaseDB || '/annotations/' || $annCollName
        else xmldb:create-collection($wdb:edocBaseDB || '/annotations', $annCollName)
            
    let $fileName := if ($username = "")
        then "anno.xml"
        else $username || '.xml'
        
    let $cr := if (doc-available($annColl || '/' || $fileName))
        then $annColl || '/' || $fileName
        else
            let $annContent := <anno xmlns="https://github.com/dariok/wdbplus/annotations"/>
            let $ps := xmldb:store($annColl, $fileName, $annContent)
            let $ch := if ($fileName = 'anno.xml')
                then (sm:chgrp($ps, 'wdbusers'), sm:chmod($ps, 'rw-rw-r--'))
                else (sm:chmod($ps, 'rw-rw----'), sm:chgrp($ps, 'wdb'), sm:chown($ps, $username))
                return $ps

    return doc($cr)
};

let $id := request:get-parameter("id", "0")
let $fr := request:get-parameter("fr", "0")

let $doc := collection('/db/apps/edoc/data')//id($id)[self::tei:TEI]

let $tokens := local:spacyExport($doc, $fr)

let $request-headers := <headers>
	<header name="Content-Type" value="application/json" />
	<header name="cache-control" value="no-cache" />
</headers>

let $response := httpclient:post(xs:anyURI("https://spacyapp.acdh-dev.oeaw.ac.at/query/enrich-simple-json/"),
	$tokens,
	false(),
	$request-headers)

let $code := $response//httpclient:body/@encoding

let $ann := if ($response//httpclient:header[@name = 'Content-Type']/@value = "application/json; charset=utf-8")
    then util:base64-decode($response//httpclient:body)
    else ""

let $annoFile := local:getAnnoFile($doc, "nlp")

return if($ann = "") then "no answer"
	else for $e in parse-json($ann)?*
		let $es := <entry xmlns="https://github.com/dariok/wdbplus/annotations">{for $k in map:keys($e) return element {xs:QName($k)} {$e($k)}}</entry>
		let $target := $annoFile/anno:entry[anno:tokenId = $es/anno:tokenId]
        return if($target)
            then update replace $target with $es
            else update insert $es into $annoFile/anno:anno