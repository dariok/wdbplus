xquery version "3.1";

module namespace wdbRMi = "https://github.com/dariok/wdbplus/RestMIngest";

import module namespace console = "http://exist-db.org/xquery/console"         at "java:org.exist.console.xquery.ConsoleModule";
import module namespace xstring = "https://github.com/dariok/XStringUtils"     at "/db/apps/edoc/include/xstring/string-pack.xql";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"      at "/db/apps/edoc/modules/app.xqm";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace sm   = "http://exist-db.org/xquery/securitymanager";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";
declare namespace util = "http://exist-db.org/xquery/util";

(: uploaded a single non-XML file with the intent to create/update entry :)
declare function wdbRMi:enterMeta ($path as xs:anyURI) {
    (: non-XML files have no internally defined ID and in general no view :)
    let $project := wdb:getEdFromPath($path, true())
    let $meta := doc($project || '/wdbmeta.xml')
    let $collectionID := $meta/meta:projectMD/@xml:id
    let $doc := doc($path)
    let $uuid := util:uuid($doc)
    let $metaFile := $meta//meta:file[@path = $path]
    let $id := wdbRMi:getID(<void />, $collectionID, $path)
    
    let $errorNum := count($metaFile) > 2
    
    return if ($errorNum)
    then 
      let $err := if ($errorNum) then "More than 2 entries found for path " || $path
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
      let $pid := $metaFile/@pid
      let $file :=
        <file xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
          attribute xml:id { $fid },
          attribute path { $path },
          attribute date { current-dateTime() },
          attribute uuid { $uuid },
          if ($pid != "") then attribute pid { $pid } else ()
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
declare function wdbRMi:enterMetaXML ($path as xs:anyURI) {
    let $project := wdb:getEdFromPath($path, true())
    let $meta := doc($project || '/wdbmeta.xml')
    let $doc := doc($path)
    let $uuid := util:uuid($doc)
    let $relPath := substring-after($path, $project || "/")
    let $id := wdbRMi:getID($doc, string($meta/meta:projectMD/@xml:id), $relPath)
    
    let $metaFile := ( 
      $meta/id($id),
      $meta//meta:file[@path = $relPath]
    )
    let $errorNonMatch := if (count($metaFile) eq 0)
      then false()
      else not($metaFile[1] is $metaFile[2])
    let $errorNum := count($metaFile) > 2
    
    return if ($errorNonMatch or $errorNum)
      then
        let $err := 
          if ($errorNonMatch) then "Conflicting entries for ID " || $id || " and path " || $path || " in " || base-uri($meta)
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
              attribute label { normalize-space(($doc//tei:titleStmt/tei:title[@level eq 'a'], $doc//tei:titleStmt/tei:title[1])[1]) },
              if ( $doc//tei:titleStmt/tei:title[@type eq 'num'] )
                then attribute order { normalize-space($doc//tei:titleStmt/tei:title[@type eq 'num']) }
                else ()
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
        <error>Error creating new entry: {$err:code}: {$err:description}
        {$err:module || '@' || $err:line-number ||':'||$err:column-number}</error>
      )}
    else
      (: file entry is present – update file (and struct if necessary) :)
      try {
        let $pid := $metaFile[1]/@pid
        let $file :=
          <file xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
            attribute xml:id { $id },
            attribute path { $relPath },
            attribute date { current-dateTime() },
            attribute uuid { $uuid },
            if ($pid != "") then attribute pid { $pid } else ()
          )}</file>
        let $updf := update replace $metaFile[1] with $file
        
        let $view := if (wdb:findProjectFunction(map{"pathToEd": $project}, "getRestView", 1))
          then wdb:eval("wdbPF:getRestView($fileID)", false(), (xs:QName("fileID"), $id))
          else
            <view xmlns="https://github.com/dariok/wdbplus/wdbmeta">{( 
              attribute file { $id },
              attribute label { normalize-space(($doc//tei:titleStmt/tei:title[@level eq 'a'], $doc//tei:titleStmt/tei:title[1])[1]) },
              if ( $doc//tei:titleStmt/tei:title[@type eq 'num'] )
                then attribute order { normalize-space($doc//tei:titleStmt/tei:title[@type eq 'num']) }
                else ()
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
        )
      } catch * {( 
        <rest:response>
          <http:response status="500">
            <http:header name="Content-Type" value="text/plain" />
            <http:header name="rest-status" value="REST:ERROR" />
          <http:header name="Access-Control-Allow-Origin" value="*"/></http:response>
        </rest:response>,
        <error>Error updating entry for ID {$id}: {$err:code}: {$err:description}</error>
      )}
};
  
declare function wdbRMi:store($collection as xs:string, $resource-name as xs:string, $contents as item()) {
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
    
  return wdbRMi:store($collection, $resource-name, $contents, $mime-type)
};

declare function wdbRMi:store($collection as xs:string, $resource-name as xs:string, $contents as item(), $mime-type as xs:string) {
  let $coll := if (not(xmldb:collection-available($collection)))
    then wdbRMi:createCollection($collection)
    else ()
  let $hasAccess := sm:has-access(xs:anyURI($collection), 'w')
  
  return if ($coll = () or not($hasAccess))
  then
      let $status := if (not($coll)) then "404" else "403"
      let $reason := if (not($coll))
        then "Collection " || $collection || " not found"
        else "user " || sm:id()//sm:username || " does not have sufficient rights to create or write to " || $collection
        
      return (
        <rest:response>
          <http:response status="{$status}" />
        </rest:response>,
        $reason
      )
  else
    let $path := try {
      xmldb:store($collection, $resource-name, $contents, $mime-type)
    } catch * {
      ( 
        <rest:response>
          <http:response status="500" />
        </rest:response>,
        "error storing " || $mime-type || " to " || $collection || '/' || $resource-name || ":
" || $err:code || ": " || $err:description
      )
    }
    
    return if ( count($path) gt 1 ) then
      $path
    else
      try {
        let $mode := if (ends-with($resource-name, 'xql')) then "rwxrwxr-x" else "rw-rw-r--"
          , $ch := (
            sm:chmod($path, $mode),
            sm:chown($path, "wdb"),
            sm:chgrp($path, "wdbusers"),
            util:log("info", "storing " || $mime-type || " to " || $path)
          )

        return (
          <rest:response>
            <http:response status="200" />
          </rest:response>,
          $path
        )
      } catch * {
        ( 
          <rest:response>
            <http:response status="200" />
          </rest:response>,
          $path,
          util:log("info", "when storing " || $path || ": unable to change permissions")
        )
      }
};

declare function wdbRMi:createCollection ($coll as xs:string) {
  let $target-collection := xstring:substring-before-last($coll, '/')
  let $new-collection := xstring:substring-after-last($coll, '/')
  
  return if (xmldb:collection-available($target-collection))
  then ( 
    let $path := xmldb:create-collection($target-collection, $new-collection)
(:    let $chown := sm:chown($path, "wdb"):)
    let $chgrp := sm:chgrp($path, "wdbusers")
    let $chmod := sm:chmod($path, "rwxrwxr-x")
    
    return console:log("creating " || $new-collection || " in " || $target-collection)
  )
  else ( 
    wdbRMi:createCollection($target-collection),
    xmldb:create-collection($target-collection, $new-collection)
  )
};

declare function wdbRMi:getID ($element as item(), $collection as xs:string, $path) as xs:string {
  if ($element instance of document-node() and $element/*/@xml:id)
  then string($element/*/@xml:id)
  else if  ( $element instance of element() )
  then string($element/@xml:id)
  else $collection || '-' || translate(xstring:substring-before-last($path, '\.'), '/', '_')
};

declare function wdbRMi:replaceWs($string) {
  if (matches($string, "^\s+<"))
  then replace($string, "^\s+<", "<")
  else replace($string,
      ".*<\?xml ([^>]+)\?>\s+<",
      "<?xml $1?><"
    )
};
