xquery version "3.1";

import module namespace json    = "http://www.json.org";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:spacyExport($id, $fr) {
if ($id = "0" or $fr = "0")
    then "both a file ID and a fragment identifier have to be supplied"
    
    else
    let $doc := collection('/db/apps/edoc/data')//id($id)
    let $fra := $doc/id($fr)
    
    return if (not($fr))
    then "could not find fragment " || $fr || " in file " || $id
    else let $r := <r>{
        for $n in $fra//tei:w | $fra//tei:pc
            return <token>
                <tokenId>{normalize-space($n/@xml:id)}</tokenId>
                <whitespace>{if(normalize-space($n/following-sibling::node()[1]) = "") then true() else false()}</whitespace>
                <value>{$n/text()}</value>
            </token>
    }</r>
    
    return json:xml-to-json($r)
};

let $id := request:get-parameter("id", "0")
let $fr := request:get-parameter("fr", "0")

let $tokens := local:spacyExport($id, $fr)
return $tokens