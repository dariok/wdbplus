xquery version "3.1";

module namespace wdbRf = "https://github.com/dariok/wdbplus/RestFiles";

import module namespace console = "http://exist-db.org/xquery/console"            at "java:org.exist.console.xquery.ConsoleModule";
import module namespace json    = "http://www.json.org";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"         at "/db/apps/edoc/modules/app.xqm";
import module namespace wdbRi   = "https://github.com/dariok/wdbplus/RestMIngest" at "/db/apps/edoc/rest/ingest.xqm";
import module namespace xstring = "https://github.com/dariok/XStringUtils"        at "/db/apps/edoc/include/xstring/string-pack.xql";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace sm     = "http://exist-db.org/xquery/securitymanager";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";
declare namespace util   = "http://exist-db.org/xquery/util";
declare namespace wdbPF  = "https://github.com/dariok/wdbplus/projectFiles";
declare namespace xmldb  = "http://exist-db.org/xquery/xmldb";

(:
 : Get a resource’s ID by its persistent identifier
 :)
declare
  %rest:GET
  %rest:path("/edoc/resource/pid/{$pid}")
  function wdbRf:getIdfromPid ( $pid as xs:anyURI ) as item()+ {
    let $files := collection($wdb:data)//meta:file[@pid = $pid]
    return if ( count($files) = 0 ) then 
        <rest:response>
          <http:response status="404">
            <http:header name="Access-Control-Allow-Origin" value="*"/>
          </http:response>
        </rest:response>
      else if ( count($files) gt 1 ) then (
        <rest:response>
          <http:response status="400">
            <http:header name="Access-Control-Allow-Origin" value="*"/>
          </http:response>
        </rest:response>,
        count($files)
      )
      else (
        <rest:response>
          <http:response status="200">
            <http:header name="Access-Control-Allow-Origin" value="*"/>
            <http:header name="Content-Type" value="text/plain" />
          </http:response>
        </rest:response>,
        $files/@xml:id/string()
      )
};

(: upload a single file with known ID (i.e. one that is already present)
   - if the ID is not found, return an error
   - replace the file and update its meta:file
   - unless the new path already is in use, in which case we return an error :)
declare
    %rest:PUT("{$data}")
    %rest:path("/edoc/resource/{$id}")
    %rest:header-param("Content-Type", "{$header}")
function wdbRf:storeFile ($id as xs:string, $data as xs:string, $header as xs:string*) {
  if (sm:id()//sm:username = "guest")
  then
    <rest:response>
      <http:response status="401">
        <http:header name="WWW-Authenticate" value="Basic"/>
      </http:response>
    </rest:response>
  else
    (: get entries from metaFile :)
    let $fileEntry := (collection($wdb:data)/id($id))[self::meta:file],
        $errNumID := (count($fileEntry) > 1),
        $errNoID := count($fileEntry) = 0
    
    (: parse data an try to get the intended path :)
    let $parsed := wdb:parseMultipart($data, $header)
      , $path := normalize-space($parsed?filename?body)
      , $pathEntry := collection($wdb:data)//meta:file[@path = $path]
      , $errNonMatch := count($pathEntry) = 1 and not($pathEntry/@xml:id = $id)
    
    let $fullPath := substring-before(base-uri($fileEntry), "wdbmeta.xml") || $path
    let $errNoAccess := not(sm:has-access(xs:anyURI($fullPath), "w"))
    let $user := sm:id()//sm:real/sm:username
    
    let $resourceName := xstring:substring-after-last($fullPath, '/')
    let $contentType := $parsed?file?header?Content-Type
    let $contents := $parsed?file?body
    let $errWrongID := $contents instance of node() and not($contents//tei:TEI/@xml:id = $id)
    
    return if ( $errNonMatch or $errNumID or $errNoAccess or $errNoID ) then
      let $reason := (
          if ($errNoID) then
            "no file found with ID " || $id
          else
            ()
        , if ($errNumID) then
            "illegal number of file entries: " || count($fileEntry)
              || " for ID " || $id
          else
            ()
        , if ($errNonMatch) then
            "path " || $path || " is already in use for ID "
              || $pathEntry[1]/@xml:id
          else
            ()
        , if ($errNoAccess) then
            "user " || $user || " has no access to resource " || $fullPath
          else
            ()
      )
      
      let $status :=
            if ( $errNoID ) then
              404
            else if ( $errNoAccess ) then
              403
            else
              500

      return (
          <rest:response>
            <http:response status="{$status}">
              <http:header name="Content-Type" value="text/plain" />
              <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
          </rest:response>
        , $reason
      )

    else
      let $collectionID := $fileEntry/ancestor::meta:projectMD/@xml:id
      let $collectionPath := xstring:substring-before-last($fullPath, '/')
      
      let $store := wdbRi:store($collectionPath, $resourceName, $contents, $contentType),
          $meta := 
            if ( $contentType = ("text/xml", "application/xml", "application/xslt+xml") ) then
              wdbRi:enterMetaXML($store[2])
            else
              wdbRi:enterMeta($store[2])
    return if ($store[1]//http:response/@status = "200"
        and $meta[1]//http:response/@status = "200")
    then
      (
        <rest:response>
          <http:response status="200">
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

(: get a resource by its ID – whatever type it might be :)
declare
    %rest:GET
    %output:indent("no")
    %rest:path("/edoc/resource/{$id}")
function wdbRf:getResource ($id as xs:string) {
  (: Admins are advised by the documentation they REALLY SHOULD NOT have more than one entry for every ID
   : To be on the safe side, we go for the first one anyway :)
  let $files := collection($wdb:data)//id($id)[self::meta:file]
    , $collectionPath := wdb:getEdPath($id, true())
    , $f := $files[1]
    , $path := $collectionPath || '/' || $f/@path
    , $readable := sm:has-access($path, "r")

  let $doc := if ( not($readable) ) then
      ()
    else if ( doc-available($path) ) then
      doc($path)
    else if ( util:binary-doc-available($path) ) then
      util:binary-doc($path)
    else ()
  
  let $mtype := if ( count($doc) = 1 )
    then xmldb:get-mime-type($path)
    else ()
  let $type := if ( $mtype = 'application/xml' and $doc//tei:TEI )
    then "application/tei+xml"
    else $mtype
  
  let $method := if ( contains($type, 'xml') ) then
      "xml"
    else if ( contains($type, 'html') ) then
      "html"
    else
      "binary"
  
  let $respCode := if ( count($files) = 0 ) then
      404
    else if ( not($readable) ) then
      401
    else if ( count($doc) = 1 ) then
      200
    else
      500
  
  return (
    <rest:response>
      <output:serialization-parameters>
        <output:method value="{$method}"/>
      </output:serialization-parameters>
      <http:response status="{$respCode}">
        {
          if ( string-length($type) = 0 )
            then ()
            else <http:header name="Content-Type" value="{$type}" />
          ,
          if ( $respCode = 401 )
            then <http:header name="WWW-Authenticate" value="Basic"/>
            else ()
          ,
          if (  $respCode = 200 )
            then <http:header name="rest-status" value="REST:SUCCESS" />
            else <http:header name="rest-status" value="REST:ERROR" />
        }
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    if ($respCode = 200)
      then $doc
      else ()
  )
};

(: get a resource as plain text
   – string value of tei:text for TEI files
   – error otherwise :)
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}.txt")
  function wdbRf:getResourceTxt ($id as xs:string) {
  (: Admins are advised by the documentation they REALLY SHOULD NOT have more than one entry for every ID
   : To be on the safe side, we go for the first one anyway :)
  let $files := (collection($wdb:data)//id($id)[self::meta:file])
  let $f := $files[1]
  let $path := substring-before(base-uri($f), 'wdbmeta.xml') || $f/@path
  
  let $doc := doc($path)
  
  let $respCode := if (count($files) = 0)
    then "404"
    else if (count($files) = 1 and $doc/tei:TEI)
    then "200"
    else "500"
  let $status := if ($respCode = "200")
    then "REST:SUCCESS"
    else "REST:ERR"
  
  return (
    <rest:response>
      <http:response status="{$respCode}">
        <http:header name="Content-Type" value="text/plain" />
        <http:header name="rest-status" value="{$status}" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    if ($respCode = "200")
    then normalize-space($doc//tei:text)
    else "ERROR: no TEI file by the ID of " || $id
  )
};

(:  return a fragment from a file :)
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}/f/{$fragment}")
function wdbRf:getResourceFragment ($id as xs:string, $fragment as xs:string) {
  let $files := (collection($wdb:data)//id($id)[self::meta:file])
  let $f := $files[1]
  let $path := substring-before(base-uri($f), 'wdbmeta.xml') || $f/@path
  
  let $doc := doc($path)
  
  let $mtype := xmldb:get-mime-type($path)
  let $type := if ($mtype = 'application/xml' and $doc//tei:TEI)
    then "application/tei+xml"
    else $mtype
  
  let $frag := $doc/id($fragment)
  
  let $respCode := if (count($files) = 0 or count($frag) = 0)
  then "404"
  else if (count($files) = 1 or count($frag) = 1)
  then "200"
  else "500"
  
  return (
    <rest:response>
      <http:response status="{$respCode}">{
        if (string-length($type) = 0) then () else
        <http:header name="Content-Type" value="{$type}" />
        }
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    $frag
  )
};

(: list all views available for this resource :)
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}/view.xml")
function wdbRf:getResourceViewsXML ($id) {
  wdbRf:getResourceViews($id, "application/xml")
};
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}/view.json")
function wdbRf:getResourceViewsJSON ($id) {
  wdbRf:getResourceViews($id,"application/json")
};
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}/views")
    %rest:header-param("Accept", "{$mt}")
function wdbRf:getResourceViews ($id as xs:string, $mt as xs:string*) {
  (: Admins are advised by the documentation they REALLY SHOULD NOT have more than one entry for every ID
   : To be on the safe side, we go for the first one anyway :)
  let $files := (collection($wdb:data)//id($id)[self::meta:file])
  let $f := $files[1]
  
  let $respCode := if (count($files) = 0)
  then 404
  else if (count($files) = 1)
  then 200
  else 500
  
  let $content := if ($respCode != 200) then () else
    <views>{
      for $process in $f/ancestor::meta:projectMD//meta:process[@target] return
        <view>
          {$process/@*}
          /edoc/resource/view/{$id}.{string($process/@target)}{if($process/@view) then "?view=" || string($process/@view) else ()}
        </view>
    }</views>
  
  return (
    <rest:response>
      <http:response status="{$respCode}">{
        if (string-length($mt) = 0) then () else <http:header name="Content-Type" value="{$mt}" />
        }
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
  if ($respCode != 200) then () else
    if ($mt = "application/json")
      then json:xml-to-json($content)
      else $content
  )
};

declare
    %rest:GET
    %rest:path("/edoc/resource/view/{$id}.{$type}")
    %rest:query-param("view", "{$view}", "")
function wdbRf:getResourceView ($id as xs:string, $type as xs:string, $view as xs:string*)  {
  let $model := wdb:populateModel($id, $view, map {})
  
  (: This mechanism can only be used with wdbmeta. A METS-only project will return an error :)
  let $wdbmeta := if (ends-with($model?infoFileLoc, "wdbmeta.xml"))
      then doc($model?infoFileLoc)
      else ()
  
  (: by definition in wdbmeta.rng and in analogy to the behaviour of view.html: $type maps to process/@target,
     $view is used as a parameter. If there is only one process for $type, $view will be handed over as a parameter;
     if there are multiple processes for $type, $view will be used to select via process/@view. If the are multiple
     processes but none with the given $view, this is an error :)
  let $processes := $wdbmeta//meta:process[@target = $type]
  let $process := if (count($processes) = 1)
    then ($processes[1])
    else ($processes[@view = $view])
  
  let $status := if ($wdbmeta = ())
      then (500, "no wdbmeta found for " || $id || " (project with mets.xml?)")
      else if (not($processes))
      then (404, "no process found for target type " || $type)
      else if (not($process))
      then (400, "no process found for target type " || $type || " that has a view " || $view)
      else wdbRf:getContent($id, $process, $view, $model)
  
  let $namespace := if ($status[2] instance of element())
    then $status[2]/*[1]/namespace-uri()
    else ""
  
  return ( 
    <rest:response>
      <http:response status="{$status[1]}">
        <http:header name="Access-Control-Allow-Origin" value="*" />
        <http:header name="Content-Type" value="{wdb:getContentTypeFromExt($type, $namespace)}" />
      </http:response>
    </rest:response>,
    $status[2]
  )
};

declare function wdbRf:getContent($id as xs:string, $process as element(), $view as xs:string, $model as map(*)) as item()* {
  (: TODO if multiple commands are defined, check that one is actually applicable – #395 :)
  (: TODO pass the position of this command on to the processing function or pass target and view on :)
  (: TODO once dev on wdbmeta, -- steps -- is done, implement these here – #394:)
  let $type := $process[1]/meta:command/@type
  return if ($type = "xsl")
    then wdbRf:processXSL($id, $process, $model)
    else if ($type = "xquery")
    then wdbRf:processXQuery($id, $process, $model)
    else (500, "Invalid command type " || $type)
};

declare function wdbRf:processXSL( $id as xs:string, $process as element(), $model as map(*) ) as item()* {
  let $content := try {
    let $attr :=
          <attributes>
            <attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" />
          </attributes>,
        $params :=
          <parameters>
            <param name="view" value="{$model?view}" />
          </parameters>
      
      return transform:transform(doc($model?fileLoc),
          doc($model?pathToEd || '/' || normalize-space($process/meta:command)),
          $params,
          $attr,
          "expand-xincludes=no"
        )
    } catch * {
      ("error",
        $err:description,
        console:log("Processing " || $id || ": " || $err:description))
    }
  
  return if ($content[1] = "error")
    then (500, $content[2])
    else (200, $content)
};

declare function wdbRf:processXQuery($id as xs:string, $process as element(), $model as map(*)) as item()* {
  let $function := $process/meta:command/text()
  return if (starts-with($function, 'http') or starts-with($function, '/'))
  then () (: TODO :)
  else
    let $fn := wdb:findProjectFunction($model, $function, 2)
    return if ($fn) then try {
      (200, wdb:eval($function || "($id, $process)", false(), (xs:QName("id"), $id, xs:QName("process"), $process)))
    } catch * {
      (500, $err:description)
    }
    else (500, "function " || $function || " not found")
};

declare
    %private
  function wdbRf:image ($fileID as xs:string, $image as xs:string, $map as map(*)) {
  let $retrFile := wdbRf:getResource($fileID)
  let $errorFile := if ($retrFile//http:response/@status != 200)
    then "File not found or other error: " || $retrFile//http:response/@status
    else ()
  let $file := $retrFile/tei:TEI
  
  let $fa := $file//tei:surface[@xml:id = $image]
  let $page := substring-after($fa/@xml:id, '_')
    
    let $projectFileAvailable := wdb:findProjectFunction($map, "getImages", 2)
    let $resource := if ($projectFileAvailable)
      then wdb:eval("wdbPF:getImages($fileID, $page)", false(), (xs:QName("fileID"), $fileID, xs:QName("page"), $page))
      else $wdb:restURL || "file/iiif/" || $fileID || "/resource/" || substring-after($fa/tei:graphic/@url, ':')
    
    let $sid := if ($projectFileAvailable = true())
      then substring-before($resource, '/full')
      else $wdb:restURL || "file/iiif/" || $fileID || "/images/" || $page
    
    let $tiles := map {
          "scaleFactors": [1, 2, 4, 8, 16],
          "width": 512,
          "height": 512
        }
    
    let $errors := string-join($errorFile, ' - ')
    return if (string-length($errors) > 0)
      then "ERROR: " || $errors
      else map {
        "@context" : "http://iiif.io/api/image/2/context.json",
        "profile" : "http://iiif.io/api/image/2/level2.json",
        "@id" : $sid,
        "height": xs:int($fa/@lry),
        "width": xs:int($fa/@lrx),
        "protocol": "http://iiif.io/api/image",
        "tiles": [$tiles]
      }
      
      (:map {
        "@id": $wdb:restURL || "file/iiif/" || $fileID || "/canvas/p" || $page,
        "@type": "sc:Canvas",
        "label": "S. " || $page,
        "height": xs:int($fa/@lry),
        "width": xs:int($fa/@lrx),
        "images": [map{
            "@id": $wdb:restURL || "file/iiif/" || $fileID || "/annotation/p" || $page || "-image",
            "@type": "oa:Annotation",
            "motivation": "sc:painting",
            "resource": map {
                "@id": $resource,
                "@type": "dctypes:Image",
                "service": map{
                     "@context" : "http://iiif.io/api/image/2/context.json",
                     "@id" : $sid,
                     "profile" : "http://iiif.io/api/image/2/level2.json"
                }
            },
            "on": $wdb:restURL || "file/iiif/" || $fileID || "/canvas/p" || $page
        }],
        "otherContent": [
            map {
                "@id": $wdb:restURL || "file/iiif/" || $fileID || "/list/" || $page,
                "@type": "sc:AnnotationList",
                "resources": [
                    map {
                        "@type": "oa:Annotation",
                        "motivation": "sc:painting",
                        "resource": map {
                            "@id": $wdb:restURL || "file/iiif/" || $fileID || "/resource/p" || $page || ".xml",
                            "@type": "dctypes:text",
                            "format": "application/xml"
                        },
                        "on": $wdb:restURL || "file/iiif/" || $fileID || "/canvas/p" || $page
                    }
                ]
            }
        ]
    }:)
};

declare
    %rest:GET
    %rest:path("/edoc/resource/iiif/{$id}/images")
    %output:method("json")
function wdbRf:getImages($id as xs:string) {
  let $retrFile := wdbRf:getResource($id)
  let $errorFile := if ($retrFile//http:response/@status != 200)
    then "File not found or other error: " || $retrFile//http:response/@status
    else ()
  let $file := $retrFile/tei:TEI
  let $map := wdb:populateModel($id, '', map{})
  
  let $canv := for $fa in $file//tei:surface
    return wdbRf:image($id, $fa/@xml:id, $map)
  
  return (
    <rest:response>
      <http:response>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
          <http:header name="status" value="200" />
      </http:response>
    </rest:response>,
    $canv
  )
};

(: IIIF image desriptor :)
declare
    %rest:GET
    %rest:path("/edoc/resource/iiif/{$id}/{$image}.json")
    %output:method("json")
function wdbRf:getImageDesc($id as xs:string, $image as xs:string) {
  let $retrFile := wdbRf:getResource($id)
  let $errorFile := if ($retrFile//http:response/@status != 200)
    then "File not found or other error: " || $retrFile//http:response/@status
    else ()
  let $file := $retrFile/tei:TEI
  
  let $map := wdb:populateModel($id, '', map{})
  let $meta := doc($map("infoFileLoc"))
  
  let $errors := string-join($errorFile, ' - ')
  let $respCode := if (string-length($errors) = 0)
  then 200
  else 500
  
  return (
    <rest:response>
      <http:response>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
          <http:header name="status" value="{$respCode}" />
      </http:response>
    </rest:response>,
    if ($respCode != 200)
    then $errors
    else wdbRf:image($id, $image, $map)
  )
};

(: produce a IIIF manifest :)
declare
    %rest:GET
    %rest:path("/edoc/resource/iiif/{$id}/manifest.json")
    %output:method("json")
function wdbRf:getFileManifest ($id as xs:string) {
  let $retrFile := wdbRf:getResource($id)
  let $errorFile := if ($retrFile//http:response/@status != 200)
    then "File not found or other error: " || $retrFile//http:response/@status
    else ()
  let $file := $retrFile/tei:TEI
  
  let $map := wdb:populateModel($id, '', map{})
  let $meta := doc($map("infoFileLoc"))
  
  let $title := normalize-space($meta//meta:view[@file = $id]/@label)
  
  let $canv := for $fa in $file//tei:surface
    return wdbRf:image($id, $fa/@xml:id, $map)
    
  let $md := (
  	map { "label": "ID", "value": $id },
      map { "label": [
      		map {"@value": "Title", "@language": "en" },
      		map {"@value": "Titel", "@language": "de" }
      	],
      	"value": $title },
      if ($meta//meta:type) then map {
            "label": [ map {"@value": "Type", "@language": "en"}, map {"@value": "Typ", "@language": "de"}],
            "value": [ map {"@value": normalize-space($meta//meta:type), "@language": "en"}]
        } else (),
      if ($file//tei:teiHeader//tei:sourceDesc/tei:place) then
        map {
            "label": [ map {"@value": "Place of Publication", "@language": "en"}, map {"@value": "Erscheinungsort", "@language": "de"}],
            "value": "<a href='" || $file//tei:teiHeader//tei:place/@ref || "'>" || $file//tei:teiHeader//tei:place || "</a>"
        } else if ($meta//meta:place) then
        map {
            "label": [ map {"@value": "Place of Publication", "@language": "en"}, map {"@value": "Erscheinungsort", "@language": "de"}],
            "value": "<a href='" || $meta//meta:place/@ref || "'>" || $meta//meta:place || "</a>"
        } else (),
      if ($file//tei:teiHeader//tei:sourceDesc/tei:date) then
        map {
            "label": [ map {"@value": "Date", "@language": "en"}, map {"@value": "Datum", "@language": "de"}],
            "value": normalize-space($file//tei:teiHeader//tei:sourceDesc/tei:date[1]/@when)
        } else if ($meta//meta:titleData/meta:date) then
        map {
            "label": [ map {"@value": "Date", "@language": "en"}, map {"@value": "Datum", "@language": "de"}],
            "value": normalize-space($meta//meta:titleData/meta:date[1])
        } else (),
      if ($meta//meta:metaData/*[contains(@role, 'disseminator')]) then
        map {
            "label": [ map {"@value": "Disseminator", "@language": "en"}, map {"@value": "Anbieter", "@language": "de"}],
            "value": "<a href='" || $wdb:restURL || "'>" || $meta//meta:metaData/*[contains(@role, 'disseminator')] || "</a>"
        } else (),
      if ($meta//meta:language) then 
        map {
            "label": [ map {"@value": "Languages", "@language": "en"}, map {"@value": "Sprachen", "@language": "de"}],
            "value": for $l in $meta//meta:language return xs:string($l)
        } else ()
  )
  
  let $errors := string-join($errorFile, ' - ')
  let $respCode := if (string-length($errors) = 0)
  then 200
  else 500
  
  return (
    <rest:response>
      <http:response>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
          <http:header name="status" value="{$respCode}" />
      </http:response>
  </rest:response>,
  if ($respCode != 200)
  then $errors
  else map {
    "@context": "http://iiif.io/api/presentation/2/context.json",
    "@id": $wdb:restURL || "file/iiif/" || $id || "/manifest",
    "@type": "sc:Manifest",
    "label": $title,
    "description": [map{
      "@value": $title,
      "@language": xstring:substring-before($meta//meta:language[1], '-')
    }],
    "viewingDirection": "left-to-right",
    "viewingHint": "paged",
    "license": "https://creativecommons.org/licenses/by-sa/4.0/legalcode",
    "attribution": map {
      "@value" : "Austrian Academy of Sciences, Austrian Centre for Digital Humanities",
      "@language" : "en"
    },
    "metadata": $md,
    "sequences": [
      map {
        "@id": $wdb:restURL || "file/iiif/" || $id || "/sequence/normal",
        "@type": "sc:Sequence",
        "startCanvas": $wdb:restURL || "file/iiif/" || $id || "/canvas/p1",
        "canvases": $canv
      }
    ]
  })
};
