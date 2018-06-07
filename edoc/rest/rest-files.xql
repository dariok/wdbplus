xquery version "3.1";

module namespace wdbRf = "https://github.com/dariok/wdbplus/RestFiles";

import module namespace json = "http://www.json.org";

declare namespace rest   ="http://exquery.org/ns/restxq";
declare namespace output ="http://www.w3.org/2010/xslt-xquery-serialization";

declare variable $wdbRf:collection := collection('/db/apps/edoc/data');

declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
    %output:media-type("application/xml")
function wdbRf:getFile($fileID as xs:string) {
    $wdbRf:collection/id($fileID)
};

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