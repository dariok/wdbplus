xquery version "3.1";

module namespace wdbRc = "https://github.com/dariok/wdbplus/RestCollections";

import module namespace console = "http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace json    = "http://www.json.org";
import module namespace wdbRi   = "https://github.com/dariok/wdbplus/RestMIngest" at "ingest.xqm";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xqm";
import module namespace xstring = "https://github.com/dariok/XStringUtils" at "/db/apps/edoc/include/xstring/string-pack.xql";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

(: create a resource in a collection :)
(: create a single file for which no entry has been created in wdbmeta.
   - if a file with the same ID, MIME type and path is found, update it (if these are not a match, return 409)
   - if no target collection is given, return 500
   - if the specified target collection does not exist, return 404
   - if creation is successful, return 201 and the full path where the file was stored :)
declare
  %rest:POST("{$data}")
  %rest:path("/edoc/collection/{$collection}")
  %rest:header-param("Content-Type", "{$ct}")
function wdbRc:createFile ($data as xs:string, $collection as xs:string, $ct as xs:string*) {
  if (sm:id()//sm:username = "guest")
  then
    <rest:response>
      <http:response status="401">
        <http:header name="WWW-Authenticate" value="Basic"/>
      </http:response>
    </rest:response>
  else
    let $collectionFile := collection($wdb:data)/id($collection)[self::meta:projectMD]
    let $parsed := wdb:parseMultipart($data, $ct)
    
    let $errNoCollection := if (not($collectionFile)) then "collection " || $collection || " not found" else ()
    
    let $path := normalize-space($parsed?filename?body)
    let $collectionPath := substring-before(base-uri($collectionFile), "/wdbmeta.xml")
    let $fullPath := $collectionPath || '/' || $path
    
    let $resourceName := xstring:substring-after-last($fullPath, '/')
    let $contentType := $parsed?file?header?Content-Type
    let $t := console:log($contentType)
    let $contents := if (contains($contentType, "xml"))
      then parse-xml($parsed?file?body)
      else $parsed?file?body
    let $id := wdbRi:getID($contents, $collection, $path)
    
    (: check for conflicts :)
    let $ids := collection($wdb:data)/id($id)
    let $numIds := count($ids[self::meta:file])
    let $errNumIds := if ($numIds > 1)
      then "more than one entry found for ID " || $id
      else ()
    let $conflict := if ($numIds = 1)
      then
        let $testPath := $ids[self::meta:file]/@path
        let $type := xmldb:get-mime-type($fullPath)
        return $testPath = $path and $type = $parsed?file?header?Content-Type
      else ()
    let $errConflict := if ($conflict)
      then "conflict for ID " || $id || " at " || $fullPath || " and type " || $parsed?file?header?Content-Type
      else ()
    
    let $user := sm:id()//sm:real/sm:username
    let $errNoAccess := if ($numIds = 1 and not(sm:has-access(xs:anyURI($fullPath), "w")))
      then "user " || $user || " has no access to write to resource " || $fullPath
      else
        let $highest := wdbRc:available($fullPath)
        return if ($numIds = 0 and not(sm:has-access(xs:anyURI($highest), "w")))
      then "user " || $user || " has no access to write to collection " || $highest
      else ()
    
    let $status :=
      if ($errNoCollection) then "404"
      else if ($errConflict) then "409"
      else if ($errNoAccess) then "401"
      else if ($errNumIds) then "500"
      else "200"
    
    return if ($status != "200") then
      (
        <rest:response>
          <http:response status="{$status}">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="Access-Control-Allow-Origin" value="*"/>
          </http:response>
        </rest:response>,
        string-join(($errNoCollection, $errNumIds, $errConflict, $errNoAccess), "\n")
      )
    else
      let $store := wdbRi:store($collectionPath, $resourceName, $contents, $contentType)
      let $meta := if (substring-after($resourceName, '.') = ("xml", "xsl"))
        then wdbRi:enterMetaXML($store[2])
        else wdbRi:enterMeta($store[2])
      return if ($store[1]//http:response/@status = "200"
          and $meta[1]//http:response/@status = "200")
      then
        (
          <rest:response>
            <http:response status="201">
              <http:header name="Content-Type" value="text/plain" />
              <http:header name="Access-Control-Allow-Origin" value="*" />
              <http:header name="Location" value="{$store[2]}" />
            </http:response>
          </rest:response>,
          $wdb:restURL || "/resource/" || $id
        )
      else if ($store[1]//http:response/@status != "200")
      then $store
      else $meta
};

declare %private function wdbRc:available ($path as xs:string) {
  if (xmldb:collection-available($path))
  then $path
  else wdbRc:available(xstring:substring-before-last($path, '/'))
};

(: list all collections :)
declare function local:getCollections() {
  <collections base="{$wdb:data}/">{
    for $p in collection($wdb:data)//meta:projectMD
      let $path := substring-before(substring-after(base-uri($p), $wdb:data || '/'), 'wdbmeta.xml')
      order by $path
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
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    json:xml-to-json(local:getCollections())
  )
  else local:getCollections()
};
declare
    %rest:GET
    %rest:path("/edoc/collection.json")
    %rest:produces("application/json")
function wdbRc:getCollectionsJSON () {
  wdbRc:getCollections("application/json")
};
declare
    %rest:GET
    %rest:path("/edoc/collection.xml")
    %rest:produces("application/xml")
function wdbRc:getCollectionsXML () {
  wdbRc:getCollections("application/xml")
};

(: resources within a collection :)
declare
    %rest:GET
    %rest:path("/edoc/collection/{$id}")
    %rest:header-param("Accept", "{$mt}")
function wdbRc:getResources ($id as xs:string, $mt as xs:string*) {
  let $md := collection($wdb:data)//meta:projectMD[@xml:id = $id]
  
  return if (count($md)  != 1)
  then
    <rest:response>
      <http:response status="500">
        <http:header name="REST-Status" value="REST:404 – ID not found" />
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
          <http:header name="REST-Status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      json:xml-to-json($content))
    default return $content
};
declare
  %rest:GET
  %rest:path("/edoc/collection/{$id}/resources.xml")
function wdbRc:getResourcesXML ($id) {
  wdbRc:getResources($id, "application/xml")
};
declare
  %rest:GET
  %rest:path("/edoc/collection/{$id}/resources.json")
  %rest:produces("application/json")
function wdbRc:getResourcesJSON ($id) {
  wdbRc:getResources($id, "application/json")
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
    local:listResources($md, "")
  }</collection>
};
declare function local:listResources ($mfile, $subcollection) {
  for $file in $mfile//meta:file[starts-with(@path, $subcollection)]
    order by $file/@path
    return <resource id="{$file/@xml:id}" path="{$file/@path}" />
};

declare
  %rest:GET
  %rest:path("/edoc/collection/{$id}/collections.json")
  %rest:produces("application/json")
  function wdbRc:getSubcollJson ($id) {
    json:xml-to-json(wdbRc:getSubcollXML($id))
};
declare
  %rest:GET
  %rest:path("/edoc/collection/{$id}/collections.xml")
  function wdbRc:getSubcollXML ($id) {
    let $md := collection($wdb:data)/id($id)[descendant::meta:*]
    let $path := xstring:substring-before-last(base-uri($md), '/')
    return
    <collection id="$id" path="{$path}">{
      for $s in xmldb:get-child-collections($path)
        return try {
          local:childCollections($path, $s)
        } catch * {
          console:log($s || " not readable")
        }
    }</collection>
};
declare function local:childCollections($path, $s) {
  let $p := $path || '/' || $s
  return
  <collection path="{$p}">{
    for $sc in xmldb:get-child-collections($p)
      return local:childCollections($p, $sc)
  }</collection>
};

(: navigation :)
declare
    %rest:GET
    %rest:path("/edoc/collection/{$id}/nav.xml")
function wdbRc:getCollectionNavXML ($id as xs:string) {
  let $md := collection($wdb:data)/id($id)[self::meta:projectMD]
  
  return local:pM(doc(local:findImporter(base-uri($md))))
};

declare
    %rest:GET
    %rest:path("/edoc/collection/{$id}/nav.html")
function wdbRc:getCollectionNavHTML ($id as xs:string) {
  let $md := collection($wdb:data)/id($id)[self::meta:projectMD]
  let $ed := substring-before(base-uri($md), '/wdbmeta.xml')
  let $xsl := if (wdb:findProjectFunction(map {"pathToEd": $ed}, "getNavXSLT", 0))
    then wdb:eval("wdbPF:getNavXSLT()")
    else if (doc-available($ed || '/nav.xsl'))
    then xs:anyURI($ed || '/nav.xsl')
    else xs:anyURI($wdb:edocBaseDB || '/resources/nav.xsl')
  let $struct := wdbRc:getCollectionNavXML($id)
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="Access-Control-Allow-Origin" value="*" />
        <http:header name="Content-Type" value="text/html" />
        <http:header name="REST-Status" value="REST:SUCCESS" />
      </http:response>
    </rest:response>,
    transform:transform($struct, doc($xsl), ())
  )
};

declare function local:findImporter($path) {
  let $f := doc($path)
  
  return if ($f//meta:import)
  then
    let $base := substring-before($path, "wdbmeta.xml")
    return local:findImporter($base || $f//meta:import/@path)
  else $path
};

declare function local:pM($meta) {
  let $uri := base-uri($meta)
  
  return for $s in $meta/meta:projectMD/meta:struct/*
    let $f := $meta//meta:files/*[@xml:id = $s/@file]
    return if ($f[self::meta:ptr])
    then
      let $base := substring-before($uri, 'wdbmeta.xml')
      return
        <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
          {$s/@*}
          {local:pM(doc($base || $f/@path))}
        </struct>
    else if ($s[self::meta:struct]/meta:view) then
      <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
          {$s/@*}
          {
            for $v in $s/* return
              if ($v[@private = 'true'] and not(sm:has-access($uri, 'w'))) then ()
              else $v
          }
        </struct>
    else $s
};
