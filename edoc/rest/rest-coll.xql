xquery version "3.1";

module namespace wdbRc = "https://github.com/dariok/wdbplus/RestCollections";

import module namespace json = "http://www.json.org";

declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare variable $wdbRc:server := "https://diarium-reporting-exist.eos.arz.oeaw.ac.at";
declare variable $wdbRc:collection := '/db/apps/edoc/data';

(: List collection contents :)
declare
    %rest:GET
    %rest:path("/edoc/collection/{$collection}")
function wdbRc:getCollection ($collection as xs:string) {
	wdbRc:formatCollection($collection)
};
declare
    %rest:GET
    %rest:path("/edoc/collection/{$collection}/{$subcoll1}")
function wdbRc:getCollection ($collection as xs:string, $subcoll1 as xs:string) {
	wdbRc:formatCollection($collection||'/'||$subcoll1)
};
declare
    %rest:GET
    %rest:path("/edoc/collection/{$collection}/{$subcoll1}/{$subcoll2}")
function wdbRc:getCollection ($collection as xs:string, $subcoll1 as xs:string, $subcoll2 as xs:string) {
	wdbRc:formatCollection($collection||'/'||$subcoll1||'/'||$subcoll2)
};

(: global list :)
declare
	%rest:GET
	%rest:path("/edoc/collections")
function wdbRc:getCollection() {
	wdbRc:formatCollection('')
};

declare %private function wdbRc:formatCollection ($collection as xs:string) {
	<collection name="{$collection}">{
		for $coll in  xmldb:get-child-collections($wdbRc:collection||'/'||$collection)
			return <collection name="{$coll}" />,
		for $file in xmldb:get-child-resources($wdbRc:collection||'/'||$collection)
			return <resource name="{$file}" />
	}</collection>
};