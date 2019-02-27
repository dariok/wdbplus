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

(: resources within a collection :)
(: TODO make a zip? :)
declare
    %rest:GET
    %rest:path("/edoc/collection/{$id}")
    %rest:header-param("Accept", "{$mt}")
function wdbRc:getResources ($id as xs:string, $mt as xs:string*) {
  let $md := try {
    collection($wdb:data)//meta:projectMD[@xml:id = $id]
  } catch * {
    "ERROR"
  }
  
  return if ($md = "ERROR")
  then
    <rest:response>
      <http:response status="500">
        <http:header name="REST-Status" value="404 – ID not found" />
      </http:response>
    </rest:response>
  else
    let $content := local:listCollection($md)
    return
    switch ($mt)
    case "application/json" return
      (<rest:response>
        <http:response status="200" message="OK">
          <http:header name="Content-Type" value="application/json; charset=UTF-8" />
        </http:response>
      </rest:response>,
      json:xml-to-json($content))
    default return $content
};
declare function local:listCollection ($md as element()) {
  let $collection := substring-before(base-uri($md), '/wdbmeta.xml')
  return
  <collection id="{$md/@xml:id}" path="{$collection}" title="{$md//meta:title[1]}">{
    for $coll in xmldb:get-child-collections($collection)
      let $mfile := $collection || '/' || $coll || '/wdbmeta.xml'
      order by $coll
      return if (doc-available($mfile))
      then <collection id="{doc($mfile)/meta:projectMD/@xml:id}" />
      else <collection name="{$coll}">{
        local:listResources($md, $coll)
      }</collection>,
    local:listResources($md, "@")
	}</collection>
};
declare function local:listResources ($mfile, $subcollection) {
  for $file in $mfile//meta:file[starts-with(@path, $subcollection)]
    return <resource id="{$file/@xml:id}" path="{$file/@path}" />
};

(:
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