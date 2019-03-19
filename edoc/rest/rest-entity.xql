xquery version "3.1";

module namespace wdbRe = "https://github.com/dariok/wdbplus/RestEntities";

import module namespace console ="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xqm";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare
    %rest:GET
    %rest:path("/edoc/entities/scan/{$type}/{$collection}.xml")
    %rest:query-param("q", "{$q}")
function wdbRe:scan ($collection as xs:string, $type as xs:string*, $q as xs:string*) {
  let $query := xmldb:decode($q)
  let $coll := wdb:getEdPath($collection, true())
  
  let $res := switch ($type)
    case "bibl" return collection($coll)//tei:title[ft:query(., $query)][ancestor::tei:listBibl]
    case "person" return collection($coll)//tei:persName[ft:query(., $query)][ancestor::tei:listPerson]
    case "place" return collection($coll)//tei:placeName[ft:query(., $query)][ancestor::tei:listPlace]
    case "org" return collection($coll)//tei:orgName[ft:query(., $query)][ancestor::tei:listOrg]
    default return ()
    
  return if ($res = ())
  then "Error: no or wrong type"
  else <results q="{$query}" type="{$type}" collection="{$collection}">{
    for $r in $res
    group by $id := $r/ancestor::*[@xml:id][1]/@xml:id
    return
      <result id="{$id}" />
  }</results>
};

declare
    %rest:GET
    %rest:path("/edoc/entities/scan/{$type}/{$collection}.html")
    %rest:query-param("q", "{$q}")
    %output:method("html")
function wdbRe:scanHtml ($collection as xs:string, $type as xs:string, $q as xs:string*) {
  let $md := collection($wdb:data)//id($collection)[self::meta:projectMD]
  let $coll := wdb:getEdPath($collection, true())
  
  let $xsl := if (wdb:findProjectFunction(map { "pathToEd" := $coll}, "getSearchXSLT", 0))
      then wdb:eval("wdbPF:getEntityXSLT()")
      else if (doc-available($coll || '/resources/entity.xsl'))
      then xs:anyURI($coll || '/resources/entity.xsl')
      else xs:anyURI($wdb:edocBaseDB || '/resources/entity.xsl')
    
  let $params := <parameters>
    <param name="title" value="{$md//meta:title[1]}" />
    <param name="rest" value="{$wdb:restURL}" />
  </parameters>
  
  return transform:transform(wdbRe:scan($collection, $type, $q), doc($xsl), $params)
};

declare
    %rest:GET
    %rest:path("/edoc/entities/collection/{$collection}/{$ref}")
    %rest:query-param("start", "{$start}", 1)
function wdbRe:collectionEntity ($collection as xs:string*, $ref as xs:string*, $start as xs:int*) {
  let $coll := wdb:getEdPath($collection, true())
  let $query := xmldb:decode($ref)
  
  let $res := collection($coll)//tei:rs[@ref=$query or @ref='#'||$query]
  let $max := count($res)
  
  return
    <results count="{$max}" from="{$start}" id="{$collection}" ref="{$ref}">{
      for $f in subsequence($res, $start, 25)
      group by $file := $f/ancestor::tei:TEI/@xml:id
      return
        <file id="{$file}" />
    }</results>
};

declare
    %rest:GET
    %rest:path("/edoc/entities/file/{$id}/{$ref}")
    %rest:query-param("start", "{$start}", 1)
function wdbRe:fileEntity ($id as xs:string*, $ref as xs:string*, $start as xs:int*) {
  let $file := (collection($wdb:data)/id($id))[self::tei:TEI][1]
  let $query := lower-case(xmldb:decode($ref))
  
  let $res := $file//tei:rs[@ref=$query or @ref = '#'||$query]
  let $max := count($res)
  
  return
    <results count="{$max}" from="{$start}" id="{$id}" ref="{$ref}">{
      for $h in subsequence($res, $start, 25)
      group by $a := ($h/ancestor-or-self::*[@xml:id])[last()]
      return
        <result fragment="{$a/@xml:id}">{
          $h
        }</result>
    }</results>
};

declare
    %rest:GET
    %rest:path("/edoc/entities/list/collection/{$id}/{$q}")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("p", "{$p}")
function wdbRe:listCollectionEntities ($id as xs:string*, $q as xs:string*, $start as xs:int*, $p as xs:string*) {
  let $md := collection($wdb:data)//id($id)[self::meta:projectMD]
  
  let $coll := wdb:getEdPath(base-uri($md), true())
  let $query := xmldb:decode($q)
  
  let $params := parse-json($p)
  
  let $r := if ($p != "" and $params("type") != "")
    then collection($coll)//tei:rs[starts-with(@ref, $query) and @type = $params("type")]
    else collection($coll)//tei:rs[starts-with(@ref, $query)]
  let $res := for $f in $r
    group by $ref := $f/@ref
    return
      <result ref="{$ref}" count="{count($f)}">
        {for $id in distinct-values($f/ancestor::tei:TEI/@xml:id)
          return <file id="{$id}" />
        }
      </result>
  let $max := count($res)
  
  return
    <results count="{$max}" from="{$start}" id="{$id}" q="{$q}" p="{$p}">{
      for $f in subsequence($res, $start, 25)
      return $f
    }</results>
};

declare
    %rest:GET
    %rest:path("/edoc/entities/list/file/{$id}/{$q}")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("p", "{$p}")
function wdbRe:listFileEntities ($id as xs:string*, $q as xs:string*, $start as xs:int*, $p as xs:string*) {
  let $file := (collection($wdb:data)/id($id))[self::tei:TEI][1]
  let $query := lower-case(xmldb:decode($q))
  
  let $params := parse-json($p)
  
  let $r := if ($p != "" and $params("type") != "")
    then $file//tei:rs[starts-with(@ref, $query) and @type = $params("type")]
    else $file//tei:rs[starts-with(@ref, $query)]
  let $res := for $f in $r
    group by $ref := $f/@ref
    return
      <result ref="{$ref}">
        {for $i in $f
          group by $id := $i/ancestor::tei:*[@xml:id][1]/@xml:id
          return <fragment id="{$id}" />
        }
      </result>
  let $max := count($res)
  
  return
    <results count="{$max}" from="{$start}" id="{$id}" q="{$q}">{
      for $h in subsequence($res, $start, 25) return
        <result ref="{$h/@ref}" count="{count($h/*)}">
          {$h/*}
        </result>
    }</results>
};