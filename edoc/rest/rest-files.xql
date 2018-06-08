xquery version "3.1";

module namespace wdbRf = "https://github.com/dariok/wdbplus/RestFiles";

import module namespace json = "http://www.json.org";

declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare variable $wdbRf:server := "https://diarium-reporting-exist.eos.arz.oeaw.ac.at";
declare variable $wdbRf:collection := collection('/db/apps/edoc/data');

(: export a complete file, cradle and all :)
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
    %rest:produces("application/xml")
function wdbRf:getFile($fileID as xs:string) {
    $wdbRf:collection/id($fileID)
};
declare
    %rest:GET
    %rest:path("/edoc/file/{$fileID}")
    %rest:produces("application/json")
    %output:method("json")
function wdbRf:getFileJSON($fileID as xs:string) {
    json:xml-to-json($wdbRf:collection/id($fileID))
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
function wdbRf:getFileText ($fileID as xs:string) {
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
    
    let $canv:= for $fa in $file//tei:facsimile
        let $page := substring-after($fa/@xml:id, '_')
        
        return map {
            "@context": "http://iiif.io/api/presentation/2/context.json",
            "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/canvas/p" || $page,
            "@type": "sc:canvas",
            "label": "S. " || $page,
            "height": xs:int($fa/tei:surface/@lry),
            "width": xs:int($fa/tei:surface/@lrx),
            "images": [
                map{
                    "@context": "http://iiif.io/api/presentation/2/context.json",
                    "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/annotation/p" || $page || "-image",
                    "@type": "oa:annotation",
                    "motivation": "sc:painting",
                    "resource": map {
                        "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/resource/" || substring-after($fa//tei:graphic/@url, ':'),
                        "@type": "dctypes:Image",
                        "service": map{
                             "@context" : "http://iiif.io/api/image/2/context.json",
                             "@id" : $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/images/" || $page,
                             "profile" : "http://iiif.io/api/image/2/level2.json"
                        }
                    },
                    "on": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/canvas/p" || $page
                }
            ],
            "otherContent": [
                map {
                    "@context" : "http://iiif.io/api/presentation/2/context.json",
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
    
    let $seq := map {
        "@context": "http://iiif.io/api/presentation/2/context.json",
        "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/sequence/normal",
        "@type": "sc:sequence",
        "startCanvas": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/canvas/p1",
        "canvases": [$canv]
    }
    
    return map {
        "@context": "http://iiif.io/api/presentation/2/context.json",
        "@id": $wdbRf:server || "/exist/restxq/edoc/file/iiif/" || $fileID || "/manifest",
        "@type": "sc:manifest",
        "label": $num,
        "description": $title,
        "viewingDirection": "left-to-right",
        "viewingHint": "paged",
        "license": "http://creativecommons.org/publicdomain/mark/4.0/",
        "license": "https://creativecommons.org/licenses/by-sa/4.0/legalcode",
        "attribution": [
            map {
                "@value" : "Austrian National Library",
                "@language" : "en"
            },
            map {
                "@value" : "Österreichische Nationalbibliothek",
                "@language" : "de"
            }
        ],
        "attribution": [
            map {
                "@value" : "Austrian Academy of Sciences, Austrian Centre for Digital Humanities",
                "@language" : "en"
            },
            map {
                "@value" : "Österreichische Akademie der Wissenschaften, Austrian Centre for Digital Humanities",
                "@language" : "de"
            }
        ],
        "metadata": [
            map {
                "label": [ map {"@value": "Id", "@language": "en"}, map {"@value": "Id", "@language": "de"}],
                "value": $fileID
            },
            map {
                "label": [ map {"@value": "Title", "@language": "en"}, map {"@value": "Titel", "@language": "de"}],
                "value": $title
            },
            map {
                "label": [ map {"@value": "Type", "@language": "en"}, map {"@value": "Typ", "@language": "de"}],
                "value": [ map {"@value": "newspaper", "@language": "en"}, map {"@value": "Zeitung", "@language": "de"}]
            },
            map {
                "label": [ map {"@value": "Place of Publication", "@language": "en"}, map {"@value": "Erscheinungsort", "@language": "de"}],
                "value": "<a href='http://d-nb.info/gnd/4066009-6'>Wien</a>"
            },
            map {
                "label": [ map {"@value": "Date", "@language": "en"}, map {"@value": "Datum", "@language": "de"}],
                "value": substring-after($fileID, 'wd_')
            },
            map {
                "label": [ map {"@value": "Disseminator", "@language": "en"}, map {"@value": "Anbieter", "@language": "de"}],
                "value": "<a href='" || $wdbRf:server || "'>Wien[n]erisches Diarium digital</a>"
            },
            map {
                "label": [ map {"@value": "Languages", "@language": "en"}, map {"@value": "Sprachen", "@language": "de"}],
                "value": [ "de-Goth-AT", "la", "fr", "it" ]
            }
        ],
        "sequences": $seq
    } 
};