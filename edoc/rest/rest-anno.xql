xquery version "3.1";

module namespace wdbRa = "https://github.com/dariok/wdbplus/RestAnnotations";

declare namespace anno = "https://github.com/dariok/wdbplus/annotations";

import module namespace json    = "http://www.json.org";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"  at "../modules/app.xql";
(:import module namespace xstring = "https://github.com/dariok/XStringUtils" at "../include/xstring/string-pack.xql";:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";
declare namespace rest   = "http://exquery.org/ns/restxq";
(:declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace wdbPF  = "https://github.com/dariok/wdbplus/projectFiles";:)

declare variable $wdbRa:server := $wdb:server;
declare variable $wdbRa:collection := collection($wdb:data);

(: return all public annotations and those of the current user for $fileID :)
declare
    %rest:GET
    %rest:path("/edoc/anno/{$fileID}")
    %rest:produces("application/json")
    %output:method("json")
function wdbRa:getFileAnno ($fileID as xs:string) {
    <anno:anno>
		<anno:entry><anno:range from="" to=""/></anno:entry>
		{doc($wdb:edocBaseDB || '/anno.xml')//anno:file[. = $fileID]/parent::anno:entry}
	</anno:anno>
};

(: insert a new annotation :)
declare
    %rest:POST("{$body}")
    %rest:path("/edoc/anno/{$fileID}")
    %rest:consumes("application/json")
function wdbRa:insertAnno ($fileID as xs:string, $body as item()) {
    let $data := parse-json(util:base64-decode($body))
    return $data('text')
};