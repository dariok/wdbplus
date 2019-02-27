xquery version "3.1";

module namespace wdbRc = "https://github.com/dariok/wdbplus/RestCollections";

import module namespace json = "http://www.json.org";
import module namespace wdb  = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare
    %rest:GET
    %rest:path("/edoc/collection.json")
    %rest:produces("application/json")
    %output:method("json")
function wdbRc:getCollectionsJSON () {
  json:xml-to-json(wdbRc:getCollectionsXML())
};
declare
    %rest:GET
    %rest:path("/edoc/collection.xml")
    %rest:produces("application/xml")
function wdbRc:getCollectionsXML () {
  <collections base="{$wdb:data}/">{
    for $p in collection($wdb:data)//meta:projectMD
      let $path := substring-after(base-uri($p), $wdb:data || '/')
      let $pat := substring-before($path, '/wdbmeta.xml')
      order by $pat
      return <collection id="{$p/@xml:id}" path="{$path}" title="{$p//meta:title[1]}"/>
  }</collections>
};
declare
    %rest:GET
    %rest:path("/edoc/collection")
    %rest:header-param("Accept", "{$mt}")
function wdbRc:getCollections ($mt as xs:string*) {
  if ($mt = "application/json")
  then (
    <rest:response>
      <http:response status="200" message="OK">
        <http:header name="Content-Type" value="application/json; charset=UTF-8" />
      </http:response>
    </rest:response>,
    wdbRc:getCollectionsJSON()
  )
  else wdbRc:getCollectionsXML()
};

(: list a certain collection :)

(:declare
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

(\: global list :\)
declare
	%rest:GET
	%rest:path("/edoc/collection")
function wdbRc:getCollection() {
	wdbRc:formatCollection('')
};

(\: make a zip :\)
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
    %rest:path("/edoc/collection/{$collection}/nav.xml")
function wdbRc:getCollectionNavXML ($collection as xs:string) {
  ()
};

declare
    %rest:GET
    %rest:path("/edoc/collection/{$collection}/nav.html")
function wdbRc:getCollectionNavHTML ($collection as xs:string) {
	(\: get content via XML function :\)
	(\: select either project or generic XSLT :\)
	()
};:)