xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare function local:spacyExport($id, $fr) {
if ($id = "0" or $fr = "0")
	then "both a file ID and a fragment identifier have to be supplied"
	
	else
		let $doc := collection('/db/apps/edoc/data')//id($id)
		let $fra := $doc/id($fr)
		
		return if (not($fra))
		then "could not find fragment " || $fr || " in file " || $id
		
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

let $id := request:get-parameter("id", "0")
let $fr := request:get-parameter("fr", "0")

let $tokens := local:spacyExport($id, $fr)

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

return for $e in parse-json($ann)?*
	return <entry>{for $k in map:keys($e) return element {xs:QName($k)} {$e($k)}}</entry>