xquery version "3.1";

module namespace wdbRAd = "https://github.com/dariok/wdbplus/RestAdmin";

import module namespace console = "http://exist-db.org/xquery/console"         at "java:org.exist.console.xquery.ConsoleModule";
import module namespace sm      = "http://exist-db.org/xquery/securitymanager" at "java:org.exist.xquery.functions.securitymanager.SecurityManagerModule";
import module namespace xstring = "https://github.com/dariok/XStringUtils"     at "/db/apps/edoc/include/xstring/string-pack.xql";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"      at "/db/apps/edoc/modules/app.xqm";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";

(: endpoints to ingest a file into the database
 : if query param plain is set to true, create/update entries in wdbmeta.xml :)
declare
  %rest:POST("{$data}")
  %rest:path("/edoc/admin/ingest/{$collection-id}/{$name}")
  %rest:consumes("application/octet-stream")
  %rest:query-param("meta", "{$meta}", 0)
  function wdbRAd:ingest($data as xs:string*, $collection-id as xs:string*, $name as xs:string*, $meta as xs:int*) {
    let $contents := util:base64-decode($data)
    let $resource-path := xmldb:decode($name)
    let $collection-path := wdb:getEdPath($collection-id, true())
    let $fullpath := $collection-path || '/' || $resource-path
    let $collection-uri := xstring:substring-before-last($fullpath, '/')
    let $resource-name := xstring:substring-after-last($fullpath, '/')
    
    let $store := wdbRAd:store($collection-uri, $resource-name, $contents)
    return 
      if ($store instance of element() or $meta != 1)
      then $store
      else wdbRAd:enterMeta($store[2])
};

declare
  %rest:POST("{$contents}")
  %rest:path("/edoc/admin/ingest/{$collection-id}/{$name}")
  %rest:consumes("application/xml")
  %rest:query-param("meta", "{$meta}", 0)
  function wdbRAd:ingestXML($contents as document-node()*, $collection-id as xs:string*, $name as xs:string*, $meta as xs:int*) {
    let $resource-path := xmldb:decode($name)
    let $collection-path := wdb:getEdPath($collection-id, true())
    let $fullpath := $collection-path || '/' || $resource-path
    let $collection-uri := xstring:substring-before-last($fullpath, '/')
    let $resource-name := xstring:substring-after-last($fullpath, '/')
    
    (: when uploading programatically, we enforce the use of IDs for XML (but
       not XSLT!) files – trying to replace a file entry in wdbmeta that has no
       @xml:id with a file that has an ID will result in errorNoMatch :)
    let $errorNoID := not($contents/*[1]/@xml:id or $contents/*[1]/@id)
        and not(ends-with($name, 'xsl'))
    
    return if ($errorNoID)
    then ( 
      <rest:response>
        <http:response status="500">
          <http:header name="Content-Type" value="application/xml" />
          <http:header name="rest-status" value="REST:ERROR" />
          <http:header name="rest-reason" value="No ID supplied in XML file!" />
        <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
      </rest:response>,
      console:log("error storing XML to " || $fullpath || ": no ID supplied in XML file!")
    )
    else
      let $store := wdbRAd:store($collection-uri, $resource-name, $contents)
      return 
        if ($store[1]//http:response/@status = 500 or $meta != 1)
        then $store
        else wdbRAd:enterMetaXML($store[2])
};

declare
  %rest:GET
  %rest:path("/edoc/admin/check/{$collection-id}")
function wdbRAd:eval-meta ( $collection-id as xs:string ) as item()+ {
  let $collection-path := wdb:getEdPath($collection-id, true())
    , $meta := doc($collection-path || "/wdbmeta.xml")
  
  return (
      for $children in $meta//meta:ptr
        return meta:eval-meta($collection-path || "/" || $children/@path)
    , for $file in $meta//meta:file
        let $path := $collection-path || "/" || $file/@path
        return if ( ends-with($path, 'xml') and doc-available($path) )
          then ()
          else if ( unparsed-text-available($path) )
          then ()
          else (
            $path-to-meta || " → " || $path,
            $file
          )
  )
};

