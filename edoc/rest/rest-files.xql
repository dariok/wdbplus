xquery version "3.1";

module namespace wdbRf = "https://github.com/dariok/wdbplus/RestFiles";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace json    = "http://www.json.org";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"  at "../modules/app.xql";
import module namespace xstring = "https://github.com/dariok/XStringUtils" at "../include/xstring/string-pack.xql";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace wdbPF  = "https://github.com/dariok/wdbplus/projectFiles";

declare variable $wdbRf:server := $wdb:server;

(: get a resource by its ID – whatever type it might be :)
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}")
function wdbRf:getResource ($id as xs:string) {
  (: Admins are advised by the documentation they REALLY SHOULD NOT have more than one entry for every ID
   : To be on the safe side, we go for the first one anyway :)
  let $files := (collection($wdb:data)//id($id)[self::meta:file])
  let $f := $files[1]
  let $path := substring-before(base-uri($f), 'wdbmeta.xml') || $f/@path
  let $type := xmldb:get-mime-type($path)
  
  let $respCode := if (count($files) = 0)
  then "404"
  else if (count($files) = 1)
  then "200"
  else "500"
  
  return (
    <rest:response>
      <http:response status="{$respCode}">{
        if (string-length($type) = 0) then () else
        <http:header name="Content-Type" value="{$type}" />
      }</http:response>
    </rest:response>,
    if ($type = "application/xml")
    then doc($path)
    else util:binary-to-string(util:binary-doc($path))
  )
};

(: list all views available for this resource :)
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}/views.xml")
function wdbRf:getResourceViewsXML ($id) {
  wdbRf:getResourceViews($id, "application/xml")
};
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}/views.json")
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
    for $process in $f/ancestor::meta:projectMD//meta:process
      return <view process="{$process/@target}" />
    }</views>
  
  return (
    <rest:response>
      <http:response status="{$respCode}">{
        if (string-length($mt) = 0) then () else <http:header name="Content-Type" value="{$mt}" />
      }
      </http:response>
    </rest:response>,
  if ($respCode != 200) then () else
    if ($mt = "application/json")
    then json:xml-to-json($content)
    else $content
  )
};

(:  return a fragment from a file :)
declare
    %rest:GET
    %rest:path("/edoc/resource/{$id}/{$fragment}")
function wdbRf:getResourceFragment ($id as xs:string, $fragment as xs:string) {
  let $files := (collection($wdb:data)//id($id)[self::meta:file])
  let $f := $files[1]
  let $path := substring-before(base-uri($f), 'wdbmeta.xml') || $f/@path
  let $type := xmldb:get-mime-type($path)
  
  let $frag := doc($path)/id($fragment)
  
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
      }</http:response>
    </rest:response>,
    $frag
  )
};

declare function local:image ($fileID as xs:string, $image as xs:string, $map as map(*)) {
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
      else $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/resource/" || substring-after($fa/tei:graphic/@url, ':')
    
    let $sid := if ($projectFileAvailable = true())
      then substring-before($resource, '/full')
      else $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/images/" || $page
    
    let $errors := string-join($errorFile, ' - ')
    return if (string-length($errors) > 0)
      then "ERROR: " || $errors
      else  map {
        "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/canvas/p" || $page,
        "@type": "sc:Canvas",
        "label": "S. " || $page,
        "height": xs:int($fa/@lry),
        "width": xs:int($fa/@lrx),
        "images": [map{
            "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/annotation/p" || $page || "-image",
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
            "on": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/canvas/p" || $page
        }],
        "otherContent": [
            map {
                "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/list/" || $page,
                "@type": "sc:AnnotationList",
                "resources": [
                    map {
                        "@type": "oa:Annotation",
                        "motivation": "sc:painting",
                        "resource": map {
                            "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/resource/p" || $page || ".xml",
                            "@type": "dctypes:text",
                            "format": "application/xml"
                        },
                        "on": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/canvas/p" || $page
                    }
                ]
            }
        ]
    }
};


(: produce a IIIF manifest :)
declare
    %rest:GET
    %rest:path("/edoc/resource/iiif/{$id}.json")
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
    return local:image($id, $fa/@xml:id, $map)
    
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
	            "value": "<a href='" || $wdbRf:server || "'>" || $meta//meta:metaData/*[contains(@role, 'disseminator')] || "</a>"
	        } else (),
        if ($meta//meta:language) then 
	        map {
	            "label": [ map {"@value": "Languages", "@language": "en"}, map {"@value": "Sprachen", "@language": "de"}],
	            "value": for $l in $meta//meta:language return xs:string($l)
	        } else ()
    )
    
    return (
    <rest:response>
	    <http:response>
	        <http:header name="Access-Control-Allow-Origin" value="*"/>
	    </http:response>
	</rest:response>,
  map {
    "@context": "http://iiif.io/api/presentation/2/context.json",
    "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $id || "/manifest",
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
        "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $id || "/sequence/normal",
        "@type": "sc:Sequence",
        "startCanvas": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $id || "/canvas/p1",
        "canvases": $canv
      }
    ]
  })
};