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

(: uploaded a single non-XML file with the intent to create/update entry :)
declare
  %private
  function wdbRAd:enterMeta ($path as xs:anyURI) {
    (: non-XML files have no internally defined ID and in general no view :)
    let $project := wdb:getEdFromPath($path, true())
    let $meta := doc($project || '/wdbmeta.xml')
    let $doc := doc($path)
    let $uuid := util:uuid($doc)
    let $metaFile := $meta//meta:file[@path = $path]
    
    let $errorUUID := if ($meta//meta:file[@uuid = $uuid])
      then true() else false()
    let $errorNum := count($metaFile) > 2
    
    return if ($errorNum)
    then 
      let $err := if ($errorUUID) then "A file with UUID " || $uuid || " is already present in the database"
        else if ($errorNum) then "More than 2 entries found for path " || $path
        else "unknown error"
    return( 
      <rest:response>
        <http:response status="500">
          <http:header name="Content-Type" value="text/plain" />
          <http:header name="rest-status" value="REST:ERROR" />
          <http:header name="rest-reason" value="{$err}" />
        </http:response>
      </rest:response>,
      <error>{$err}</error>
    )
    else if (count($metaFile) = 0)
      (: new entry :)
    then try {
      (: create file entry :)
      let $file := 
        <file xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
          attribute path { $path },
          attribute date { current-dateTime() },
          attribute uuid { $uuid }
        )}</file>
      let $fins := update insert $file into $meta//meta:files
      
      return ( 
        <rest:response>
          <http:response status="200">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/><http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
        </rest:response>,
        $path
      )
    } catch * {( 
      <rest:response>
        <http:response status="500">
          <http:header name="Content-Type" value="text/plain" />
          <http:header name="rest-status" value="REST:ERROR" />
        <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
      </rest:response>,
      <error>Error creating new entry: {$err:code}: {$err:description}</error>
    )}
    else
      (: Update :)
      try {
      (: create file entry :)
      let $fid := $metaFile/@xml:id
      let $file :=
        <file xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
          attribute xml:id { $fid },
          attribute path { $path },
          attribute date { current-dateTime() },
          attribute uuid { $uuid }
        )}</file>
      let $fins := update replace $metaFile with $file
      
      return ( 
        <rest:response>
          <http:response status="200">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
        </rest:response>,
        $path
      )
    } catch * {( 
      <rest:response>
        <http:response status="500">
          <http:header name="Content-Type" value="text/plain" />
          <http:header name="rest-status" value="REST:ERROR" />
        <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
      </rest:response>,
      <error>Error creating new entry: {$err:code}: {$err:description}</error>
    )}
};
(: uploaded a single XML file with intent to create/update entry :)
declare
  %private
  function wdbRAd:enterMetaXML ($path as xs:anyURI) {
    let $project := wdb:getEdFromPath($path, true())
    let $meta := doc($project || '/wdbmeta.xml')
    let $doc := doc($path)
    let $id := $doc/*[1]/@xml:id
    let $uuid := util:uuid($doc)
    let $relPath := substring-after($path, $project || "/")
    
    let $metaFile := ( 
      $meta/id($id),
      $meta//meta:file[@path = $path]
    )
    let $errorNonMatch := if (count($metaFile) eq 0)
      then false()
      else not($metaFile[1] is $metaFile[2])
    let $errorUUID := if ($meta//meta:file[@uuid = $uuid])
      then true() else false()
    let $errorNum := count($metaFile) > 2
    
    return if ($errorUUID or $errorNonMatch or $errorNum)
      then
        let $err := if ($errorUUID) then "A file with UUID " || $uuid || " is already present in the database (see " || base-uri($meta) || ")"
            else if ($errorNonMatch) then "Conflicting entries for ID " || $id || " and path " || $path || " in " || base-uri($meta)
            else if ($errorNum) then "More than 2 entries found for ID " || $id || " and path " || $path || " in " || base-uri($meta)
            else "unknown error"
        return ( 
        <rest:response>
          <http:response status="500">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="rest-status" value="REST:ERROR" />
            <http:header name="rest-reason" value="{$err}"/></http:response>
        </rest:response>,
        <error>{$err}</error>
      )
      else if (count($metaFile) = 0) then
      (: no entry in wdbmeta: create file and view entries :)
      try {
        (: create file entry :)
        let $file :=
          <file xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
            attribute xml:id { $id },
            attribute path { $relPath },
            attribute date { current-dateTime() },
            attribute uuid { $uuid }
          )}</file>
        let $fins := update insert $file into $meta//meta:files
        
        let $view := if (wdb:findProjectFunction(map{"pathToEd": $project}, "getRestView", 1))
          then wdb:eval("wdbPF:getRestView($fileID)", false(), (xs:QName("fileID"), $id))
          else
            <view xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
              attribute file { $id },
              attribute label { $doc//tei:titleStmt/tei:title[1] }
            )}</view>
        let $updv := update insert $view into $meta/meta:projectMD/meta:struct
        
        return ( 
          <rest:response>
            <http:response status="200">
              <http:header name="Content-Type" value="text/plain" />
              <http:header name="rest-status" value="REST:SUCCESS" />
            <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
          </rest:response>,
          $path
        )
      } catch * {( 
        <rest:response>
          <http:response status="500">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="rest-status" value="REST:ERROR" />
            <http:header name="rest-reason" value="{$err:code}: {$err:description}" />
          <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
        </rest:response>,
        <error>Error creating new entry: {$err:code}: {$err:description}</error>
      )}
    else
      (: file entry is present – update file (and struct if necessary) :)
      try {
      let $file :=
          <file xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
            attribute xml:id { $id },
            attribute path { $relPath },
            attribute date { current-dateTime() },
            attribute uuid { $uuid }
          )}</file>
      let $updf := update replace $metaFile[1] with $file
      
      let $view := if (wdb:findProjectFunction(map{"pathToEd": $project}, "getRestView", 1))
      then wdb:eval("wdbPF:getRestView($fileID)", false(), (xs:QName("fileID"), $id))
      else
          <view xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
            attribute file { $id },
            attribute label { $doc//tei:titleStmt/tei:title[1] }
          )}</view>
      let $updv := update replace $meta//meta:view[@file = $id] with $view
      return ( 
        <rest:response>
          <http:response status="200">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
        </rest:response>,
        $path
      )} catch * {( 
        <rest:response>
          <http:response status="500">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="rest-status" value="REST:ERROR" />
          <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
        </rest:response>,
        <error>Error updating entry for ID {$id}: {$err:code}: {$err:description}</error>
      )}
};
  
declare
 %private
 function wdbRAd:store($collection, $resource-name, $contents) {
  let $mime-type := switch (substring-after($resource-name, '.'))
    case "css" return "text/css"
    case "js" return "application/javascript"
    case "xql"
    case "xqm" return "application/xquery"
    case "html" return "text/html"
    case "gif" return "image/gif"
    case "png" return "image/png"
    case "json" return "application/json"
    case "xml" return
      if ($contents/tei:TEI) then "application/tei+xml" else "application/xml"
    case "xsl" return "application/xslt+xml"
    default return "application/octet-stream"
    
  let $mode := if (ends-with($resource-name, 'xql')) then "rwxrwxr-x" else "rw-rw-r--"
  let $coll := if (not(xmldb:collection-available($collection)))
    then wdbRAd:createCollection($collection)
    else ()
  let $path := try {
    xmldb:store($collection, $resource-name, $contents, $mime-type)
  } catch * {
    <error>{$err:code}: {$err:description}</error>
  }
  
  return if ($path[1] instance of node())
    then ( 
      <rest:response>
        <http:response status="500">
          <http:header name="Content-Type" value="application/xml" />
          <http:header name="rest-status" value="REST:ERROR" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      $path,
      console:log("error storing XML " || $mime-type || " to " || $path),
      console:log($path)
    )
    else ( 
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Type" value="text/plain" />
          <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      $path,
      sm:chown($path, "wdb"),
      sm:chgrp($path, "wdbusers"),
      sm:chmod($path, $mode),
      console:log("storing " || $mime-type || " to " || $path)
    )
};

declare
 %private
 function wdbRAd:createCollection ($coll as xs:string) {
    let $target-collection := xstring:substring-before-last($coll, '/')
    let $new-collection := xstring:substring-after-last($coll, '/')
    
    return if (xmldb:collection-available($target-collection))
      then 
        ( 
          let $path := xmldb:create-collection($target-collection, $new-collection)
          let $chown := sm:chown($path, "wdb")
          let $chgrp := sm:chgrp($path, "wdbusers")
          let $chmod := sm:chmod($path, "rwxrwxr-x")
          
          return console:log("creating " || $new-collection || " in " || $target-collection)
        )
      else ( 
          wdbRAd:createCollection($target-collection),
          xmldb:create-collection($target-collection, $new-collection)
      )
};

