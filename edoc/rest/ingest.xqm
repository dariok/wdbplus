xquery version "3.1";

module namespace wdbRi = "https://github.com/dariok/wdbplus/RestMIngest";

import module namespace console = "http://exist-db.org/xquery/console"         at "java:org.exist.console.xquery.ConsoleModule";
import module namespace xstring = "https://github.com/dariok/XStringUtils"     at "../include/xstring/string-pack.xql";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"      at "../modules/app.xqm";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace sm   = "http://exist-db.org/xquery/securitymanager";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";
declare namespace util = "http://exist-db.org/xquery/util";

(: uploaded a single non-XML file with the intent to create/update entry :)
declare function wdbRi:enterMeta ($path as xs:anyURI) {
    (: non-XML files have no internally defined ID and in general no view :)
    let $project := wdb:getEdFromPath($path, true())
    let $meta := doc($project || '/wdbmeta.xml')
    let $collectionID := $meta/meta:projectMD/@xml:id
    let $doc := doc($path)
    let $uuid := util:uuid($doc)
    let $metaFile := $meta//meta:file[@path = $path]
    let $id := wdbRi:getID(<void />, $collectionID, $path)
    
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
          attribute xml:id { $id },
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
declare function wdbRi:enterMetaXML ($path as xs:anyURI) {
    let $project := wdb:getEdFromPath($path, true())
    let $meta := doc($project || '/wdbmeta.xml')
    let $doc := doc($path)
    let $uuid := util:uuid($doc)
    let $relPath := substring-after($path, $project || "/")
    let $id := wdbRi:getID($doc, string($meta/meta:projectMD/@xml:id), $relPath)
    
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
  
declare function wdbRi:store($collection as xs:string, $resource-name as xs:string, $contents as item()) {
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
    then wdbRi:createCollection($collection)
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
      "error storing XML " || $mime-type || " to " || $path,
      console:log("error storing XML " || $mime-type || " to " || $path)
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

declare function wdbRi:createCollection ($coll as xs:string) {
  let $target-collection := xstring:substring-before-last($coll, '/')
  let $new-collection := xstring:substring-after-last($coll, '/')
  
  return if (xmldb:collection-available($target-collection))
  then ( 
    let $path := xmldb:create-collection($target-collection, $new-collection)
    let $chown := sm:chown($path, "wdb")
    let $chgrp := sm:chgrp($path, "wdbusers")
    let $chmod := sm:chmod($path, "rwxrwxr-x")
    
    return console:log("creating " || $new-collection || " in " || $target-collection)
  )
  else ( 
    wdbRi:createCollection($target-collection),
    xmldb:create-collection($target-collection, $new-collection)
  )
};

declare function wdbRi:getID ($element as item(), $collection as xs:string, $path) as xs:string {
  if ($element instance of document-node() and $element/*/@xml:id)
  then string($element/*/@xml:id)
  else $collection || '-' || translate(xstring:substring-before-last($path, '\.'), '/', '_')
};
