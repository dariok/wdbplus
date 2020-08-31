xquery version "3.1";

module namespace wdbRc = "https://github.com/dariok/wdbplus/RestCollections";

import module namespace console = "http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace json    = "http://www.json.org";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xqm";
import module namespace wdbRCo  = "https://github.com/dariok/wdbplus/RestCommon" at "/db/apps/edoc/rest/common.xqm";
import module namespace wdbRi   = "https://github.com/dariok/wdbplus/RestMIngest" at "ingest.xqm";
import module namespace xstring = "https://github.com/dariok/XStringUtils" at "/db/apps/edoc/include/xstring/string-pack.xql";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace mets   = "http://www.loc.gov/METS/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";
declare namespace wdbErr = "https://github.com/dariok/wdbplus/errors";

(: create a (sub-)collection :)
declare
  %rest:POST("{$data}")
  %rest:path("/edoc/collection/{$collectionID}/subcollection")
  %rest:consumes("application/json")
function wdbRc:createSubcollection ( $data as xs:string*, $collectionID as xs:string ) {
  if (string-length($data) eq 0) then
    (
      <rest:response>
        <http:response status="400">
          <http:header name="Content-Type" value="text/plain" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      "no configuration data submitted"
    )
  else if (not(wdbRCo:sequenceEqual(("collectionName", "id", "name"), map:keys(parse-json(util:base64-decode($data)))))) then
    (
      <rest:response>
        <http:response status="400">
          <http:header name="Content-Type" value="text/plain" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      "missing data; needed information: collectionName, id, name"
    )
  else if (not (collection($wdb:data)/id($collectionID)[self::meta:projectMD])) then
    (
      <rest:response>
        <http:response status="404">
          <http:header name="Content-Type" value="text/plain" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      "no project with ID " || $collectionID || " or project not using wdbmeta.xml"
    )
  else
    let $collection := wdb:getEdPath($collectionID, true())
    
    let $parentMeta := doc($collection || "/wdbmeta.xml")
    let $errUser := not(sm:has-access(base-uri($parentMeta), "w"))
    
    let $collectionData := parse-json(util:base64-decode($data))
    let $errCollectionPresent := try {
        wdb:getEdPath($collectionData?id)
      } catch * {
        false()
      }
    
    return if ($errUser) then
      (
        <rest:response>
          <http:response status="403">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="Access-Control-Allow-Origin" value="*"/>
          </http:response>
        </rest:response>,
        "user " || sm:id()//sm:real/sm:username/string() || " does not have access to collection " || $collection
      )
    else if ($errCollectionPresent instance of xs:string) then
      <rest:response>
        <http:response status="409" />
      </rest:response>
    else 
      let $subCollection := xmldb:create-collection($collection, $collectionData?collectionName)
      
      let $co := xmldb:copy-resource($wdb:edocBaseDB || "/resources", "wdbmeta.xml", $subCollection, "wdbmeta.xml")
      let $newMetaPath := $subCollection || "/wdbmeta.xml"
      
      let $collectionPermissions := sm:get-permissions(xs:anyURI($collection))
      let $metaPermissions := sm:get-permissions(xs:anyURI($collection || "/wdbmeta.xml"))
      
      let $setSubcollPermissions := (
        sm:chown(xs:anyURI($subCollection), $collectionPermissions//@owner || ":" || $collectionPermissions//@group),
        sm:chmod(xs:anyURI($subCollection), $collectionPermissions//@mode)
      )
      let $setMetaPermissions := (
        sm:chown(xs:anyURI($newMetaPath), $metaPermissions//@owner || ":" || $metaPermissions//@group),
        sm:chmod(xs:anyURI($newMetaPath), $metaPermissions//@mode)
      )
      
      let $meta := doc ($newMetaPath)
      
      let $insID := update value $meta/meta:projectMD/@xml:id with $collectionData?id
      let $insTitle := update value $meta//meta:title[1] with $collectionData?name
      let $insParent := update insert <ptr path="../wdbmeta.xml" /> into $meta/meta:projectMD/meta:struct
      
      let $insPtr := update insert <ptr xmlns="https://github.com/dariok/wdbplus/wdbmeta" path="{$collectionData?collectionName}/wdbmeta.xml" xml:id="{$collectionData?id}" /> into $parentMeta//meta:files
      let $insStruct := update insert <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta" file="{$collectionData?id}" label="{$collectionData?name}" /> into $parentMeta/meta:projectMD/meta:struct
      
      return
        <rest:response>
          <http:response status="201">
            <http:header name="x-rest-status" value="{$subCollection}" />
          </http:response>
        </rest:response>
};

(: create a resource in a collection :)
(: create a single file for which no entry has been created in wdbmeta.
   - if a file with the same ID, MIME type and path is found, update it (if these are not a match, return 409)
   - if no target collection is given, return 500
   - if the specified target collection does not exist, return 404
   - if creation is successful, return 201 and the full path where the file was stored :)
declare
  %rest:POST("{$data}")
  %rest:path("/edoc/collection/{$collection}")
  %rest:header-param("Content-Type", "{$header}")
function wdbRc:createFile ($data as xs:string*, $collection as xs:string, $header as xs:string*) {
  let $user := sm:id()//sm:real/sm:username/string()
  
  return if ($user = "guest")
  then
    <rest:response>
      <http:response status="401">
        <http:header name="WWW-Authenticate" value="Basic"/>
      </http:response>
    </rest:response>
  else if (not($data) or string-length($data) = 0)
  then (
    <rest:response>
      <http:response status="400">
        <http:header name="Content-Type" value="text/plain" />
      </http:response>
    </rest:response>,
    "no data provided"
  )
  else
    let $parsed := wdb:parseMultipart($data, $header)
    let $path := normalize-space($parsed?filename?body)
    let $errNoPath := if (string-length($path) = 0)
      then "no filename provided in form data"
      else ()
    
    let $contentType := $parsed?file?header?Content-Type
    let $errNoContentType := if (string-length($contentType) = 0)
      then "no Content Type declared for file"
      else ()
      
    return if ($errNoPath or $errNoContentType)
    then (
      <rest:response>
        <http:response status="400">
          <http:header name="Content-Type" value="text/plain" />
        </http:response>
      </rest:response>,
      string-join(($errNoPath, $errNoContentType), "; ")
    )
    else
      let $collectionFile := collection($wdb:data)/id($collection)[self::meta:projectMD]
      let $errNoCollection := if (not($collectionFile))
        then "collection " || $collection || " not found"
        else ()
      
      let $collectionPath := if (not($errNoCollection))
        then replace($wdb:edocBaseDB  || '/' ||  wdb:getEdPath($collection), "//", "/")
        else ()
      
      let $errNoAccess := if (not($errNoCollection)
          and not(sm:has-access(xs:anyURI($collectionPath), "w")))
        then "user " || $user || " has no access to write to collection " || $collectionPath
        else ()
      
      let $resourceName := xstring:substring-after-last($path, '/')
      let $targetPath := normalize-space($parsed?targetCollection?body) || '/' || xstring:substring-before-last($path, '/')
      
      (: all this to make sure we really have an ID in the file :)
      let $prepped := wdbRi:replaceWs($parsed?file?body)
      let $contents := if ((contains($contentType, "text/xml") or contains($contentType, "application/xml"))
          and not($prepped instance of element() or $prepped instance of document-node()))
        then parse-xml($prepped)
        else $prepped
      
      let $id := if ($contents instance of document-node())
        then $contents/*[1]/@xml:id
        else ()
      let $errNoID := if ($contents instance of document-node() and not($id))
        then "no ID found in XML file"
        else ()
      
      let $errPresent := if (collection($wdb:data)/id($id))
        then "a file with the ID " || $id || " is already present"
        else ()
      
      let $status :=
        if ($errNoCollection) then 404
        else if ($errNoAccess) then 403
        else if ($errNoID) then 400
        else if ($errPresent) then 409
        else 200
      
      return if ($status != 200) then
        ( 
          <rest:response>
            <http:response status="{$status}">
              <http:header name="Content-Type" value="text/plain" />
              <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
          </rest:response>,
          string-join(($errNoCollection, $errNoAccess, $errNoID, $errPresent), "\n")
        )
      else
        (: store $prepped, not $contents as parse-xml() adds prefixes :)
        let $store := wdbRi:store($targetPath, $resourceName, $prepped, $contentType)
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
  let $acceptable := ("application/json", "application/xml")
  let $content := if ($mt = $acceptable)
    then wdbRc:listCollection($id)
    else (406, string-join($acceptable, '&#x0A;'))
  
  return (
    <rest:response>
      <http:response status="{$content[1]}">
        <http:header name="Content-Type" value="{if ($content[1] = 200) then $mt else 'text/plain'}" />
        {
          if ($content[1] != 200)
          then
            <http:header name="REST-Status" value="{$content[2]}" />
          else ()
        }
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    if ($content[1] = 200)
      then if ($mt = "application/json")
          then json:xml-to-json($content[2])
          else $content[2]
      else $content[2]
  )
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

declare
  %rest:GET
  %rest:path("/edoc/collection/{$id}/collections.json")
  %output:method("json")
  function wdbRc:getSubcollJson ($id) {
    wdbRc:getSubcollXML($id)
};
declare
  %rest:GET
  %rest:path("/edoc/collection/{$id}/collections.xml")
  function wdbRc:getSubcollXML ($id) {
    try {
      let $path := wdb:getEdPath($id, true())
      return
        <collection id="$id" path="{$path}">{
          for $s in xmldb:get-child-collections($path)
            return try {
              local:childCollections($path, $s)
            } catch * {
              console:log($s || " not readable")
            }
        }</collection>
    }
    catch *:wdb0200 {
      <rest:response>
        <http:response status="404" />
      </rest:response>
    }
    catch * {
      <rest:response>
        <http:response status="400" />
      </rest:response>
    }
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
  let $uri := base-uri($md)
  let $struct := $md/meta:struct
  
  let $content := <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta" ed="{$id}">{(
      $struct/@*,
      $struct/*
    )}</struct>
  
  return if ($struct/meta:import)
    then local:imported($struct/meta:import, $content)
    else $content
};

declare function local:imported ( $import, $child ) {
  let $uri := base-uri($import)
  let $path := substring-before($uri, "wdbmeta.xml") || $import/@path
  let $meta := doc($path)
  
  let $content := $meta/meta:projectMD/meta:struct
  let $struct := <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta" ed="{$meta/meta:projectMD/@xml:id}">{(
        $content/@*,
        for $st in $content/* return
          if ($st/@file = $child/@ed)
            then $child
            else $st
      )}</struct>
  
  return if ($content/meta:import)
    then local:imported ( $content/meta:import, $struct)
    else $struct
};

declare
    %rest:GET
    %rest:path("/edoc/collection/{$id}/nav.html")
function wdbRc:getCollectionNavHTML ($id as xs:string) {
  let $pathToEd := wdb:getProjectPathFromId($id)
  let $mf := wdb:getMetaFile($pathToEd)
  
  let $html := try {
    if(ends-with($mf, 'wdbmeta.xml'))
      then
        let $xsl := if (wdb:findProjectFunction(map {"pathToEd": $pathToEd}, "getNavXSLT", 0))
          then wdb:eval("wdbPF:getNavXSLT()")
          else if (doc-available($pathToEd || '/nav.xsl'))
          then xs:anyURI($pathToEd || '/nav.xsl')
          else xs:anyURI($wdb:edocBaseDB || '/resources/nav.xsl')
        let $struct := wdbRc:getCollectionNavXML($id)
        return transform:transform($struct, doc($xsl), ())
      else
        transform:transform(doc($mf), doc($pathToEd || '/mets.xsl'), ())
  } catch * {
    <p>Error transforming meta data file {$mf} to navigation using
      {$pathToEd || '/mets.xsl'}:<br/>{$err:description}</p>
  }
  
  let $status := if ($html[self::*:p]) then '500' else '200'
  
  return (
    <rest:response>
      <http:response status="{$status}">
        <http:header name="Access-Control-Allow-Origin" value="*" />
        <http:header name="Content-Type" value="text/html" />
        <http:header name="REST-Status" value="REST:SUCCESS" />
      </http:response>
    </rest:response>,
    $html
  )
};

(: helper functions :)
declare %private function wdbRc:listCollection ($id as xs:string) {
  let $md := collection($wdb:data)/id($id)[self::meta:projectMD or self::mets:mets]
  let $errNoProject := if (count($md) = 0)
    then (404, "No project found with this ID")
    else ()
  let $errMetsOnly := if (count($md) gt 0 and not($md[self::meta:projectMD]))
    then (500, "Requested project uses an unsupported meta data scheme")
    else ()
  
  return if (count($errNoProject) or count($errMetsOnly))
  then ($errNoProject, $errMetsOnly)
  else (
    200,
    <collection id="{$id}" title="{$md//meta:title[1]}">{
      for $resource in $md//meta:file return
        <resource id="{$resource/@xml:id}" timestamp="{$resource/@date}" hash="{$resource/@uuid}" />
    }</collection>
  )
};
