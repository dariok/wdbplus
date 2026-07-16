xquery version "3.1";

module namespace r2r = "https://github.com/dariok/wdbplus/rest2/resources";

import module namespace r2       = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"          at "../modules/app.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"        at "../modules/wdb-files.xqm";
import module namespace wdbProc  = "https://github.com/dariok/wdbplus/Process"      at "../modules/wdb-process.xqm";
import module namespace router   = "http://e-editiones.org/roaster/router";

declare namespace index   = "https://github.com/dariok/wdbplus/index";
declare namespace meta    = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace sm      = "http://exist-db.org/xquery/securitymanager";
declare namespace tei     = "http://www.tei-c.org/ns/1.0";
declare namespace util    = "http://exist-db.org/xquery/util";
declare namespace wdbErr  = "https://github.com/dariok/wdbplus/errors";
declare namespace xmldb   = "http://exist-db.org/xquery/xmldb";

declare variable $r2r:allow := "GET, PUT, PATCH, HEAD, OPTIONS, DELETE";

declare %private function r2r:headersWithAllow () as map(*) {
  map:merge((
    $r2:allOrigins,
    map {
      "Allow": $r2r:allow,
      "Access-Control-Allow-Methods": $r2r:allow
    }
  ))
};

declare %private function r2r:getResourceInfo ( $id as xs:string ) as map(*)? {
  let $resource := wdbFiles:getFullPath($id)
  
  return
    if ( $resource?type != "file" ) then
      ()
    else
      let $meta := doc($resource?projectPath || "/wdbmeta.xml")
        , $entry := $meta/id($id)[self::meta:file][1]
      return
        if ( empty($entry) ) then
          ()
        else
          map:merge((
            $resource,
            map {
              "meta": $meta,
              "entry": $entry,
              "path": $resource?collectionPath || "/" || $resource?fileName
            }
          ))
};

declare %private function r2r:getMimeType ( $path as xs:string, $content as item()? ) as xs:string {
  let $mimeType := xmldb:get-mime-type($path)
  return
    if ( $mimeType = "application/xml"
          and $content instance of document-node()
          and $content/*[1]/namespace-uri() = "http://www.tei-c.org/ns/1.0" ) then
      "application/tei+xml"
    else
      $mimeType
};

declare %private function r2r:getStoredContent ( $path as xs:string ) as item()? {
  if ( doc-available($path) ) then
    doc($path)
  else if ( util:binary-doc-available($path) ) then
    util:binary-doc($path)
  else
    ()
};

declare %private function r2r:requireWritableResource ( $request as map(*) ) as map(*) {
  let $resource := try {
          r2r:getResourceInfo($request?parameters?id)
        } catch * { () }
  
  return
    if ( not(exists($request?user)) or $request?user?fullName = "guest" ) then
      error(xs:QName("wdbErr:wdb9201"), "Unauthorized", map { "responseCode": 401 })
    else if ( not(r2:writeAllowed($request?user)) or not(sm:has-access($resource?path, "w"))) then
      error(xs:QName("wdbErr:wdb9202"), "Forbidden" , map { "responseCode": 403 })
    else if ( empty($resource) ) then
      error(xs:QName("wdbErr:wdb9203"), "not found", map { "responseCode": 404, "description": "File " || $request?parameters?id || " not found" })
    else
      $resource
};

declare %private function r2r:getViewsXml ( $resource as map(*) ) as element(list) {
  let $processes := r2r:allViews($resource)
    , $list := for $process in $processes
          let $viewName := string(($process/@view, 'default')[1])
          group by $name := $process/@target || '-' || $viewName
          return
            <view xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
                id="{ $r2:base }{ $r2:urls?resources }{ $resource?entry/@xml:id }/views/{ $viewName[1] }"
                view="{ $viewName[1] }"
                target="{ ($process/@target)[1] }"
            />

  return
    <list xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
        level="resource"
        for="{ $r2:base }{ $r2:urls?resources }{ $resource?entry/@xml:id }"
        type="views"
        start="1"
        total="{ count($list) }">
      {
        $list
      }
    </list>
};

declare %private function r2r:allViews ( $resource as map(*) ) as element()* {
  (: this lists all processes – which is not a problem because detailed selection will happen based on the attributes
     of any command(s) in the process :)
  let $current := base-uri($resource?meta)
    , $parent := if ( $resource?meta/* instance of element(meta:projectMD) )
        then substring-before($current, 'wdbmeta') || '../wdbmeta.xml'
        else $resource?projectPath || '/../wdbmeta.xml'
    , $parentMeta := if ( doc-available($parent) )
        then doc($parent)
        else ()

  return (
    $resource?meta//meta:process,
    if ( $current = '/db/apps/edoc/data/wdbmeta.xml' ) then ()
    else if ( exists($parentMeta) )
      then r2r:allViews(map{ "meta": $parentMeta, "projectPath": substring-before(base-uri($parentMeta), '/wdbmeta.xml') })
      else r2r:allViews(map{ "projectPath": substring-before($current, 'wdbmeta') || '..' })
  )
};

declare %private function r2r:resolveProcess ( $resource as map(*), $view as xs:string, $target as xs:string ) as element(meta:process)? {
  try {
    wdb:getXslFromWdbMeta(
      $resource?projectPath || "/wdbmeta.xml",
      $resource?entry/@xml:id,
      substring-after($target, '/'), (: target is now evaluated from the Accept header which will be a full MIME type :)
      if ( $view = 'default' ) then () else $view (: process in wdbmeta may not have @view, which means it is default :)
    )
  } catch * {
    ()
  }
};

declare function r2r:headResource ( $request as map(*) ) as item() {
  r2r:returnResource($request, "HEAD")
};
declare function r2r:getResource ( $request as map(*) ) as item() {
  r2r:returnResource($request, "GET")
};

declare %private function r2r:returnResource ( $request as map(*), $method as xs:string ) as item() {
  let $resource := try {
          r2r:getResourceInfo($request?parameters?id)
        } catch * { () }

  return if ( empty($resource) ) then
    r2:response(404, "text/plain", "No resource found by this ID", $r2:allOrigins)
  else
    let $content := r2r:getStoredContent($resource?path)
      , $lastModified := wdbFiles:ietfDate(wdbFiles:getModificationDate($resource?collectionPath, $resource?fileName))
      , $mimeType := r2r:getMimeType($resource?path, $content)
      , $modified := request:get-header("If-Modified-Since")
      , $status := if ( exists($modified) and $modified != "" )
                      then wdbFiles:evaluateIfModifiedSince($resource?collectionPath, $resource?fileName, $modified)
                      else 200
    
    return if ( empty($content) ) then
      r2:response(204, "", "", $r2:allOrigins)
    else
      router:response(
        $status,
        $mimeType,
        if ( $method = "GET" ) then $content else (),
        map:merge(($r2:allOrigins, map { "Last-Modified": $lastModified }))
      )
};

declare function r2r:putResource ( $request as map(*) ) as map(*) {
  try {
    if ( empty(r2r:requireWritableResource($request)) )
      then error(xs:QName("wdbErr:wdb9204"), "strange error")
      else r2:checkAndStore($request, r2:parseUpload($request), $request?parameters?id)
  } catch err:FODC0006 {
    r2:response(422, 'text/plain', 'Content could not be parsed as XML', $r2:allOrigins)
  } catch * {
    r2:response($err:additional?responseCode, 'text/plain', $err:description, $r2:allOrigins)
  }
};

declare function r2r:patchResource ( $request as map(*) ) as item() {
  let $resource := r2r:requireWritableResource($request)
  return if ( exists($resource?error) ) then
    $resource?error
  else
    let $content := try { doc($resource?path) } catch * { () }
      , $patch := if ( $request?body instance of document-node() ) then $request?body else try { parse-xml($request?body) } catch * { () }
    return if ( empty($content) ) then
      r2:response(404, "text/plain", "File " || $request?parameters?id || " not found", $r2:allOrigins)
    else if ( empty($patch) or empty($patch/*[1]/@xml:id) ) then
      r2:response(400, "text/plain", "Patch body must be a well-formed XML fragment with xml:id.", $r2:allOrigins)
    else
      let $target := $content/id($patch/*[1]/@xml:id)
      return if ( empty($target) ) then
        r2:response(400, "text/plain", "No fragment with xml:id " || $patch/*[1]/@xml:id || " found in resource " || $request?parameters?id, $r2:allOrigins)
      else (
          update replace $target with $patch/*[1],
          xmldb:store($resource?collectionPath, $resource?fileName, $content, xmldb:get-mime-type($resource?path)),
          
          r2:response(204, "text/plain", "", $r2:allOrigins)
        )[last()]
};

declare function r2r:optionsResource ( $request as map(*) ) as item() {
  let $resource := r2r:getResourceInfo($request?parameters?id)
    , $t := util:log("info", "OPTIONS request for resource with ID " || $request?parameters?id || ". Resource found: " || empty($resource))
  return if ( empty($resource) ) then
    r2:response(404, "text/plain", "File " || $request?parameters?id || " not found", $r2:allOrigins)
  else
    r2:response(204, "text/plain", "", r2r:headersWithAllow())
};

declare function r2r:deleteResource ( $request as map(*) ) as item() {
  let $resource := r2r:requireWritableResource($request)
  return if ( exists($resource?error) ) then
    $resource?error
  else
    r2:response(
      204,
      "text/plain",
      (
        xmldb:remove($resource?collectionPath, $resource?fileName),
        update delete $resource?meta//meta:file[@xml:id = $request?parameters?id],
        update delete $resource?meta//meta:view[@file = $request?parameters?id],
        update delete doc("/db/apps/edoc/index/file-index.xml")/index:index/id($request?parameters?id),
        ""
      )[last()],
      $r2:allOrigins
    )
};

declare function r2r:listResourceViews ( $request as map(*) ) as item() {
  let $resource := try {
          r2r:getResourceInfo($request?parameters?id)
        } catch * { () }
  
  return if ( empty($resource) ) then
    r2:response(404, "text/plain", "File " || $request?parameters?id || " not found", $r2:allOrigins)
  else
    r2:returnXmlOrJson(r2r:getViewsXml($resource))
};

declare function r2r:getResourceView ( $request as map(*) ) as item() {
  let $resource := try {
          r2r:getResourceInfo($request?parameters?id)
        } catch * { () }
  
  return if ( empty($resource) ) then
    r2:response(404, "text/plain", "The resource was not found", $r2:allOrigins)
  else
    let $type := if ( exists($request?headers?Accept) )
            then $request?headers?Accept
            else "text/html"
        , $process := try {
              r2r:resolveProcess($resource, $request?parameters?view, $type)
            } catch wdbErr:wdb0002 { () }

    let $modified := request:get-header("If-Modified-Since")
      , $status := if ( exists($modified) and $modified != "" )
            then wdbFiles:evaluateIfModifiedSince($resource?collectionPath, $resource?fileName, $modified)
            else 200

    return if ( empty($process) ) then
      r2:response(406, "application/xml", r2r:getViewsXml($resource), $r2:allOrigins)
    else if ( $status = 304 ) then
      r2:response(304, "text/plain", "", $r2:allOrigins)
    else
      let $result := wdbProc:getContent(map {
              "id": $request?parameters?id,
              "process": $process,
              "view": $request?parameters?view,
              "fileLoc": $resource?path,
              "pathToEd": $resource?projectPath,
              "ed": tokenize(normalize-space($resource?projectPath), "/")[last()]
          })
        , $body := $result?content
        , $namespace := if ( $body instance of document-node() or $body instance of element() )
                          then namespace-uri(($body/*[1], $body)[1])
                          else ()
        , $mimeType := wdb:getContentTypeFromExt(string($process/@target), $namespace)
      return router:response($result?status, $mimeType, $body, $r2:allOrigins)
};

declare function r2r:getResourceByPid ( $request as map(*) ) as item() {
  (: TODO: range index based on white space separated values – or, introduce a child element to meta:file :)
  (: TODO: add a unit test for this; use the documentation :)
  (: TODO: handle the case that multiple representations exist for a PID :)
  let $matches := collection("/db/apps/edoc/data")//meta:file[@pid = $request?parameters?pid]
  return if ( count($matches) = 1 ) then
    r2:response(303, "text/plain", "", map:merge((
        $r2:allOrigins,
        map { "Location": $r2:base || $r2:urls?resources || string($matches[1]/@xml:id) }
    )))
  else
    r2:response(404, "text/plain", "This external PID was not found", $r2:allOrigins)
};
