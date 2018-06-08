xquery version "3.1";

module namespace wdbRf = "https://github.com/dariok/wdbplus/RestFiles";

import module namespace json = "http://www.json.org";

declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare variable $wdbRf:collection := collection('/db/apps/edoc/data');

(: export a complete file, cradle and all :)
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
    %rest:produces("application/xml")
function wdbRf:getFile($fileID as xs:string) {
    $wdbRf:collection/id($fileID)
};
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
    %rest:produces("application/json")
    %output:method("json")
function wdbRf:getFileJSON($fileID as xs:string) {
    json:xml-to-json($wdbRf:collection/id($fileID))
};

(: export a fragment from a file :)
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}/{$fragment}")
    %rest:produces("application/xml")
function wdbRf:getFileFragmentXML ($fileID as xs:string, $fragment as xs:string) {
    $wdbRf:collection/id($fileID)/id($fragment)
};
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}/{$fragment}")
    %rest:produces("application/json")
    %output:method("json")
function wdbRf:getFileFragmentJSON ($fileID as xs:string, $fragment as xs:string) {
    let $f := $wdbRf:collection/id($fileID)/id($fragment)
    return json:xml-to-json($f)
};

(: export options for ingest into (No)SkE :)
declare
    %rest:GET
    %rest:path("/edoc/file/tok/ske/{$fileID}")
    %rest:produces("application/xml")
function wdbRf:getFileSke ($fileID as xs:string) {
    let $file := $wdbRf:collection/id($fileID)
    let $t := $file//tei:text
    return
    <xml>
        <doc author="Digitarium" title="{$file//tei:title[@type='num']}">{
            for $s in $t//tei:p | $t//tei:titlePart | $t//tei:list | $t//tei:table
                return <p>{normalize-space($s)}</p>
        }</doc>
    </xml>
};

(: produce ACDH tokenization :)
declare
    %rest:GET
    %rest:path("/edoc/file/tok/acdh/{$fileID}")
    %rest:produces("application/json")
    %output:method("json")
function wdbRf:getFileACDHJSON ($fileID as xs:string) {
    let $file := $wdbRf:collection/id($fileID)
    let $t := $file//tei:text
    let $arr := for $f in $t//*[@xml:id and (self::tei:w or (self::tei:pc and not(parent::tei:w)))] (:($t//tei:w, $t//tei:pc[not(parent::tei:w)]):)
        return map {"tokenId": normalize-space($f/@xml:id), "value": normalize-space($f)}
    
    return map {
        "tokenArray": [
            $arr
        ],
        "language": "german"
    }
};