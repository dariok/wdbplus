xquery version "3.1";

module namespace r2 = "https://github.com/dariok/wdbplus/rest2/common";

import module namespace router     = "http://e-editiones.org/roaster/router";
import module namespace wdb        = "https://github.com/dariok/wdbplus/wdb"  at "../modules/app.xqm";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace sm   = "http://exist-db.org/xquery/securitymanager";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";

(:~
 : list of allowed operations
 :)
declare variable $r2:allow := "GET, PUT, PATCH, HEAD, OPTIONS, DELETE";

(:~
 : Base URL for the REST API
 :)
declare variable $r2:base := doc('../config.xml')//*:rest[@version = "2"];

(:~
 : Paths for endpoint groups 
 :)
declare variable $r2:urls := map {
  "projects": "/api/v2/projects/",
  "resources": "/api/v2/resources/",
  "search": "/api/v2/search/"
};

(:~
 : list of allowed origins
 :)
declare variable $r2:origins := doc('../config.xml')//*:origins/*;

declare variable $r2:allOrigins := if ( request:get-header('origin') != '' )
  then map { 
    "Access-Control-Allow-Origin"      : request:get-header('origin'),
    "Access-Control-Allow-Credentials" : "true"
  }
  else map {
    "Access-Control-Allow-Origin" : "*"
  };

declare function r2:headersWithAllow ( ) as map(*) {
  map:merge((
    $r2:allOrigins,
    map {
      "Allow": $r2:allow,
      "Access-Control-Allow-Methods": $r2:allow
    }
  ))
};

declare variable $r2:defaultResponseLength := 25;

declare function r2:returnResponse ( $data as item(), $mediaType as xs:string, $pathInfo as map(*), $function as xs:string ) as map(*) {
  try {
    switch ( $mediaType )
      case "application/json"
        return router:response(200, "application/json", parse-json(xml-to-json(transform:transform($data, doc('api.xsl'), ()))), $r2:allOrigins)
      case "text/html"
        return router:response(200, "text/html", wdb:applySpecificXsl($data, $pathInfo, $function || ".xsl"), $r2:allOrigins)
      case "application/xml"
      case "application/tei+xml"
        return router:response(200, $mediaType, $data, $r2:allOrigins)
      default
        return router:response(406, "text/plain", "Type " || $mediaType || " cannot be served", $r2:allOrigins)
  } catch * {
    util:log("info", map{
      "location":  $err:module || '@' || $err:line-number
    }),
    util:log("info", trace($err:description)),
    r2:response(500, 'text/plain', "an unknown error occurred when preparing response", $r2:allOrigins)
  }
};

declare function r2:returnXmlOrJson ( $data as item() ) as item() {
  let $mediaType := request:get-header("Accept")
  return
    if ( $mediaType = "application/json" ) then
      router:response(200, "application/json", parse-json(xml-to-json(transform:transform($data, doc('api.xsl'), ()))), $r2:allOrigins)
    else if ( $mediaType = "application/xml" ) then
      router:response(200, "application/xml", $data, $r2:allOrigins)
    else
      router:response(406, "text/plain", "Not acceptable", $r2:allOrigins)
};

declare function r2:response ( $status as xs:integer, $mediaType as xs:string, $body as item(), $headers as map(*) ) as item() {
  router:response($status, $mediaType, $body, $headers)
};

declare function r2:parseBody ( $request as map(*) ) as item() {
  let $mediaType := $request?media-type

  return
    (: Roaster should handle unsupported media types and return 415 :)
     if ( $mediaType = "application/json" and $request?body instance of map(*) ) then
      $request?body?title
    else if ( $mediaType = "application/xml" ) then
      $request?body
    else
      "I don’t know what to do…!"
};

declare function r2:writeAllowed ( $user as map(*) ) as xs:boolean {
  $user?groups = ('dba', 'wdbadmin')
};

declare function r2:mapKeysAllowed( $m as map(*), $required as xs:string*, $optional as xs:string* ) as xs:boolean {
  let $keys := map:keys($m)
  let $allowed := ($required, $optional)
  return
    (every $r in $required  satisfies $r = $keys)
    and
    (every $k in $keys      satisfies $k = $allowed)
};

(:~
 : Function to create a new XML resource or update an existing XML, used for POST and PUT requests.
 : XML files are always entered into a wdbmeta file
 :)
declare function r2:createXmlResource ( $request as map(*) ) as map(*) {
  (: functions in r2p parse the XML to check for valid data type and ID, and thus pass on a parsed XML.
     all checks should have been carried out in r2p and r2f functions; hence, we don’t catch :)
  let $namespace := namespace-uri($request?body?xml/*[1])
    , $extension := tokenize($request?body?file?name, '\.')[last()]
    , $tryType := wdb:getContentTypeFromExt($extension, $namespace)
    , $mimeType := if ( $tryType != 'application/octet-stream' )
        then $tryType
        else if ( exists($request?body?file?type) )
        then $request?body?file?type
        else error()
    
    , $meta := doc($request?project?collectionPath || "/wdbmeta.xml")
      (: checks for conflicts have been done in projects.xqm; this should either be exactly one meta:file or empty :)
    , $existing := $meta//id($request?parameters?id)
    
    , $relPath := substring-before($request?body?path, $request?body?file?name)
    , $targetPath := $request?project?collectionPath || $relPath
    , $fileNameBase := if ( contains($request?body?file?name, '/') ) then substring-after($request?body?file?name, '/') else $request?body?file?name
    , $fileNameMod := $fileNameBase => replace(',', '') => replace(' ', '_') => replace('&amp;', '-')
                 => replace('ä', 'ae') => replace('Ä', 'Ae') => replace('ö', 'oe') => replace('Ö', 'Oe')
                 => replace('ü', 'ue') => replace('Ü', 'Ue') => replace('ß', 'ss')
    
    , $store := (
        if ( not(xmldb:collection-available($targetPath)) )
          then (
            xmldb:create-collection($request?project?collectionPath, $relPath),
            sm:chown(xs:anyURI($targetPath), "wdb"),
            sm:chgrp(xs:anyURI($targetPath), "wdbusers")
          )
          else (),
        r2:store($targetPath, $fileNameMod, $request?body?xml, $mimeType),
        r2:enterMetaForXml(map{
          "collectionPath": $request?project?collectionPath,
          "targetPath": $relPath,
          "filename": $fileNameMod,
          "hash": $request?body?hash,
          "id": $request?parameters?id,
          "numberingTitle": $request?body?xml//tei:titleStmt/tei:title[@type = 'num'],
          "mainTitle": normalize-space(($request?body?xml//tei:titleStmt/tei:title[@level eq 'a'], $request?body?xml//tei:titleStmt/tei:title[1])[1])
        })
      )
      (: note: we do not need to update the file index here as this is done automatically by the update trigger :)

    , $status := if ( exists($existing) ) then 204 else 201

  return router:response($status, $mimeType, $store, $r2:allOrigins)
};

declare function r2:store ( $collection as xs:string, $resource-name as xs:string, $contents as item(), $mime-type as xs:string ) as xs:string {
  (: all checks should have been carried out by the higher API functions in r2p and r2f.
     Hence, we assume everything’s okay and do not catch errors :)
  (
    xmldb:store($collection, $resource-name, $contents, $mime-type),
    sm:chmod(xs:anyURI(string-join(($collection, $resource-name), '/')), if ( ends-with($resource-name, 'xql') ) then "rwxrwxr-x" else "rw-rw-r--"),
    sm:chown(xs:anyURI(string-join(($collection, $resource-name), '/')), "wdb"),
    sm:chgrp(xs:anyURI(string-join(($collection, $resource-name), '/')), "wdbusers")
  )
};

declare function r2:enterMetaForXml ( $info as map(*) ) as empty-sequence() {
  let $meta := doc($info?collectionPath || '/wdbmeta.xml')
    , $uuid := $info?hash
    , $delimiter := if ( ends-with($info?targetPath, '/') ) then '' else '/'
    , $relPath := $info?targetPath || $delimiter || $info?filename
    , $id := $info?id
    , $metaFileById := $meta/id($id)[self::meta:file]
    , $metaFileByPath := $meta//meta:file[@path = $relPath]
    , $metaFile := if ( empty($metaFileById) ) then
        $metaFileByPath
      else if ( empty($metaFileByPath) ) then
        $metaFileById
      else if ( $metaFileById[1] is $metaFileByPath[1] ) then
        $metaFileById[1]
      else
        ($metaFileById, $metaFileByPath)
    , $errorNonMatch := count($metaFile) = 2
    , $errorNum := count($metaFileById) > 1 or count($metaFileByPath) > 1
    , $errors := if ( $errorNonMatch or $errorNum ) 
        then
          if ( $errorNonMatch ) then error("Conflicting entries for ID " || $id || " and path " || $info?project?collectionPath || $info?body?path || '/' || $info?body?file?name || " in " || base-uri($meta))
          else if ( $errorNum ) then error("More than 2 entries found for ID " || $id || " and path " || $info?project?collectionPath || $info?body?path || '/' || $info?body?file?name || " in " || base-uri($meta))
          else error("unknown error")
        else ()
      
    , $file :=
        <file xmlns="https://github.com/dariok/wdbplus/wdbmeta"
            xml:id="{ $id }"
            path="{ $relPath }"
            date="{ current-dateTime() }"
            uuid="{ $uuid }"
        >{
          if ( count($metaFile) = 1 ) then
            for $attr in $metaFile[1]/@*
            return if (
                (namespace-uri($attr) = "http://www.w3.org/XML/1998/namespace" and local-name($attr) = "id")
                or (namespace-uri($attr) = "" and local-name($attr) = ("path", "date", "uuid"))
              ) then ()
              else $attr
          else ()
        }</file>
    , $view := if ( wdb:findProjectFunction(map{"pathToEd": $info?collectionPath}, "getRestView", 1) )
        then wdb:eval("wdbPF:getRestView($fileID)", false(), (xs:QName("fileID"), $id))
        else
          <view xmlns="https://github.com/dariok/wdbplus/wdbmeta"
              file="{ $id }"
              label="{ $info?mainTitle }">
            {
              if ( $info?body?xml//tei:titleStmt/tei:title[@type eq 'num'] )
                then attribute order { normalize-space($info?numberingTitle) }
                else ()
            }
          </view>

    return if ( not($errors) and count($metaFile) = 0 ) then
      (
        update insert $file into $meta//meta:files,
        update insert $view into $meta/meta:projectMD/meta:struct
      )
    else if ( not($errors) and count($metaFile) = 1 ) then
      (
        update replace $metaFile[1] with $file,
        update replace $meta//meta:view[@file = $id] with $view
      )
    else
      let $errorContent := map { "errors": $errors, "file": $file, "view": $view }
      return (
        r2:logMap($errorContent, 0),
        error(xs:QName("wdb:wdb4711"), "Error processing metadata for file ID " || $id, $errorContent)
      )
};

declare function r2:resultsWrapper ( $values as map(*), $contents as element()* ) as element(results) {
  <results xmlns="https://github.com/dariok/wdbplus/api/schema/v1">
    { map:keys($values) ! attribute { . } { $values(.) } }
    { $contents }
  </results>
};

declare function r2:logMap ( $request as map(*), $depth as xs:integer ) as item()* {
  let $c := for $key in map:keys($request) return
      let $ind := string-join((string-join((1 to $depth) ! '  ', '') || $key, ': '), '')
      return if( $request($key) instance of map(*) ) then
         ( $ind, r2:logMap($request($key), $depth + 1))
      else if ( $request($key) instance of array(*) ) then
        $ind || 'Array[' || array:size($request($key)) || ']'
      else if ( $request($key) instance of document-node() or $request($key) instance of element() ) then
        $ind || 'XML[' || string-length($request($key)) || ']'
      else if ( $request($key) instance of xs:string ) then
        $ind || 'String[' || string-length($request($key)) || ']'
      else if ( $request($key) castable as xs:double ) then
        $ind || 'number = ' || string($request($key))
      else if ( $request($key) instance of xs:boolean ) then
        $ind || 'boolean = ' || string($request($key))
      else
        $ind || ($request($key))
        
  return if ( $depth = 0 ) then
    util:log("info", "Request content:
" || string-join($c, '
'))
  else
    string-join($c, '
')
};
