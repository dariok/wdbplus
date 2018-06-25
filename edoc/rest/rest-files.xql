xquery version "3.1";

module namespace wdbRf = "https://github.com/dariok/wdbplus/RestFiles";

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
declare variable $wdbRf:collection := collection($wdb:data);

(: export a complete file, cradle and all :)
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
    %rest:produces("text/plain")
    %output:method("text")
function wdbRf:getFileText ($fileID as xs:string) {
    let $file := $wdbRf:collection/id($fileID)[self::tei:TEI]
    let $title := $file//tei:title[@type = 'main']
    let $t := $file//tei:text
    
    return (
    	$title || "
",
    	for $s in $t//tei:p | $t//tei:titlePart | $t//tei:list | $t//tei:table
	        (:let $text := $p/*[@xml:id and (self::tei:w or (self::tei:pc and not(parent::tei:w)))]:)
	        let $text := normalize-space($s)
	        
	        return "
" || $text)
};
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
    %rest:produces("application/xml")
function wdbRf:getFile($fileID as xs:string) {
    $wdbRf:collection/id($fileID)[self::tei:TEI]
};
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
    %rest:produces("application/json")
    %output:method("json")
function wdbRf:getFileJSON($fileID as xs:string) {
    json:xml-to-json($wdbRf:collection/id($fileID)[self::tei:TEI])
};
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
function wdbRf:getFileDefault ($fileID as xs:string) {
    wdbRf:getFile($fileID)
};

(: export a fragment from a file :)
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}/{$fragment}")
    %rest:produces("application/xml")
function wdbRf:getFileFragmentXML ($fileID as xs:string, $fragment as xs:string) {
    $wdbRf:collection/id($fileID)/id($fragment)
};
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}/{$fragment}")
    %rest:produces("application/json")
    %output:method("json")
function wdbRf:getFileFragmentJSON ($fileID as xs:string, $fragment as xs:string) {
    let $f := $wdbRf:collection/id($fileID)/id($fragment)
    return json:xml-to-json($f)
};

(: export options for ingest into (No)SkE :)
declare
    %rest:GET
    %rest:path("/edoc/file/tok/ske/{$fileID}")
    %rest:produces("application/xml")
function wdbRf:getFileSke ($fileID as xs:string) {
    let $file := $wdbRf:collection/id($fileID)
    let $t := $file//tei:text
    return
    <xml>
        <doc author="Digitarium" title="{$file//tei:title[@type='num']}">{
            for $s in $t//tei:p | $t//tei:titlePart | $t//tei:list | $t//tei:table
                return <p>{normalize-space($s)}</p>
        }</doc>
    </xml>
};
declare
    %rest:GET
    %rest:path("/edoc/file/tok/ske/{$fileID}")
    %rest:produces("text/plain")
    %output:method("text")
function wdbRf:getFileSkeText ($fileID as xs:string) {
    let $file := $wdbRf:collection/id($fileID)
    let $t := $file//tei:text
    return for $f in $t//*[@xml:id and (self::tei:w or (self::tei:pc and not(parent::tei:w)))]
        return normalize-space($f) || "
"
};

(: produce ACDH tokenization :)
declare
    %rest:GET
    %rest:path("/edoc/file/tok/acdh/{$fileID}")
    %rest:produces("application/json")
    %output:method("json")
function wdbRf:getFileACDHJSON ($fileID as xs:string) {
    let $file := $wdbRf:collection/id($fileID)
    let $t := $file//tei:text
    let $arr := for $f in $t//*[@xml:id and (self::tei:w or (self::tei:pc and not(parent::tei:w)))] (:($t//tei:w, $t//tei:pc[not(parent::tei:w)]):)
        return map {"tokenId": normalize-space($f/@xml:id), "value": normalize-space($f)}
    
    return map {
        "tokenArray": [
            $arr
        ],
        "language": "german"
    }
};

(:~
	: produce verticalised XML with minimal structure
:)
declare
	%rest:GET
	%rest:path("/edoc/file/tok/acdh/{$fileID}")
	%rest:produces("application/xml")
	%output:method("xml")
function wdbRf:getFileACDH ($fileID as xs:string) {
	let $file := $wdbRf:collection/id($fileID)
    let $t := $file//tei:text
    
    return
    	<doc id="{$fileID}">{
    		for $s in $t//tei:p | $t//tei:titlePart | $t//tei:list | $t//tei:table
                return
<p>{
                	for $w in $s//*[@xml:id and (self::tei:w or (self::tei:pc and not(parent::tei:w)))]
                		return "
" || normalize-space($w) || "	" || $w/@xml:id}
</p>
    	}</doc>
};

(: produce a IIIF manifest :)
declare
    %rest:GET
    %rest:path("/edoc/file/iiif/{$fileID}/manifest")
    %rest:produces("application/json")
    %output:method("json")
function wdbRf:getFileManifest ($fileID as xs:string) {
    let $file := $wdbRf:collection/id($fileID)
    let $title := normalize-space($file//tei:title[@type='main'])
    let $num := normalize-space($file//tei:title[@type='num'])
    let $map := wdb:populateModel($fileID)
    let $meta := doc($map("infoFileLoc"))
    
    let $location := $map('ed')||'/project.xqm'
    let $projectFileAvailable := util:binary-doc-available($location)
    let $functionAvailable := if ($projectFileAvailable = true())
    	then
    		let $module := util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/projectFiles"), 'wdbPF', $location)
    		return system:function-available(xs:QName("wdbPF:getImages"), 2)
    	else false()
    
    let $canv:= for $fa in $file//tei:facsimile
        let $page := substring-after($fa/@xml:id, '_')
        let $resource := if ($functionAvailable)
            	then util:eval("wdbPF:getImages($fileID, $page)", false(), ($fileID, $page))
            	else $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/resource/" || substring-after($fa//tei:graphic/@url, ':')
        let $sid := if ($projectFileAvailable = true())
    	then substring-before($resource, '/full')
    	else $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/images/" || $page
        
        return map {
            "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/canvas/p" || $page,
            "@type": "sc:Canvas",
            "label": "S. " || $page,
            "height": xs:int($fa/tei:surface/@lry),
            "width": xs:int($fa/tei:surface/@lrx),
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
    
    let $md := (
    	map { "label": "ID", "value": $fileID },
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
        "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/manifest",
        "@type": "sc:Manifest",
        "label": $num,
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
				"@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/sequence/normal",
				"@type": "sc:Sequence",
				"startCanvas": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/canvas/p1",
				"canvases": $canv
			}
		]
    })
};