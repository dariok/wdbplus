xquery version "3.1";

module namespace wdbRc = "https://github.com/dariok/wdbplus/RestCollections";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";

declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare variable $wdbRc:server := $wdb:server;
declare variable $wdbRc:collection := $wdb:data;

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

(: make a zip :)
declare
    %rest:GET
    %rest:path("/edoc/collection/{$collection}/zip")
    %output:method("binary")
    %output:media-type("application/zip")
function wdbRc:getCollectionZip ($collection as xs:string) {
	compression:zip(xs:anyURI($wdbRc:collection||'/'||$collection), true())
};
declare
    %rest:GET
    %rest:path("/edoc/collection/{$collection}/{$subcoll1}/zip")
    %output:method("binary")
    %output:media-type("application/zip")
function wdbRc:getCollectionZip ($collection as xs:string, $subcoll1 as xs:string) {
	compression:zip(xs:anyURI($wdbRc:collection||'/'||$collection||'/'||$subcoll1), true())
};
declare
    %rest:GET
    %rest:path("/edoc/collection/{$collection}/{$subcoll1}/{$subcoll2}/zip")
    %output:method("binary")
    %output:media-type("application/zip")
function wdbRc:getCollectionZip ($collection as xs:string, $subcoll1 as xs:string, $subcoll2 as xs:string) {
	xs:base64Binary(compression:zip(xs:anyURI($wdbRc:collection||'/'||$collection||'/'||$subcoll1||'/'||$subcoll2), true()))
};

declare %private function wdbRc:formatCollection ($collection as xs:string) {
	<collection name="{$collection}">{
		for $coll in  xmldb:get-child-collections($wdbRc:collection||'/'||$collection)
			return <collection name="{$coll}" />,
		for $file in xmldb:get-child-resources($wdbRc:collection||'/'||$collection)
			return <resource name="{$file}" />
	}</collection>
};

declare
    %rest:GET
    %rest:path("/edoc/collection/{$collection}/nav.html")
    %output:method