xquery version "3.1";

module namespace wdbRe = "https://github.com/dariok/wdbplus/RestEntities";

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
  let $coll := try { wdb:getEdPath($collection, true()) } catch * { "" }
  let $query := xmldb:decode($q) || '*'

  let $errNoColl := if ($coll eq "")
    then (404, "Project " || $collection || " not found")
    else ()
  let $errWrongType := if($type = ("bib", "per", "pla", "org", "evt"))
    then ()
    else (400, "Error: no or wrong type")
  let $errors := ($errNoColl, $errWrongType)

  return
  if (count($errors) gt 0)
  then 
    (
    <rest:response>
      <http:response status="{$errors[1]}">
        <http:header name="X-Rest-Status" value="REST:ERR, {$errors[2]}" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    string-join($errors, "&#x0A;")
    )  
  else
    let $res := switch ($type)
      case "bib" return collection($coll)//tei:title[ft:query(., $query)][ancestor::tei:listBibl]
      case "per" return collection($coll)//tei:persName[ft:query(., $query)][ancestor::tei:listPerson]
      case "pla" return collection($coll)//tei:placeName[ft:query(., $query)][ancestor::tei:listPlace]
      case "org" return collection($coll)//tei:orgName[ft:query(., $query)][ancestor::tei:listOrg]
      case "evt" return collection($coll)//tei:event[ft:query(., $query)][ancestor::tei:listEvent]
      default return ()
    
    return (
    <rest:response>
      <http:response status="200">
        <http:header name="X-Rest-Status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <results q="{$query}" type="{$type}" collection="{$collection}" n="{count($res)}">{
      for $r in $res
        let $id := $r/ancestor::*[@xml:id][1]/@xml:id
        return
          <result id="{$id}">{
            normalize-space($r)
            (:switch ($type)
              case "per" return
                let $name := $r/tei:surname
                let $fo := if ($r/tei:forename) then ", " || $r/tei:forename else ()
                let $nl := if ($r/tei:nameLink) then " " || $r/tei:nameLink else ()
                let $da := if($r/parent::*/tei:birth or $r/parent::*/tei:death)
                  then " (" || $r/parent::*/tei:birth || "–" || $r/parent::*/tei:death || ")"
                  else ()
                return concat($name, $fo, $nl, $da)
              case "pla" return normalize-space($r)
              default return "":)
          }</result>
    }</results>)
};
declare
    %rest:GET
    %rest:path("/edoc/entities/scan/{$type}/{$collection}.html")
    %rest:query-param("q", "{$q}")
    %output:method("html")
function wdbRe:scanHtml ($collection as xs:string, $type as xs:string, $q as xs:string*) {
  let $md := collection($wdb:data)//id($collection)[self::meta:projectMD]
  let $coll := substring-before(wdb:findProjectXQM(wdb:getEdPath($collection, true())), 'project.xqm')
  
  let $xsl := if (wdb:findProjectFunction(map { "pathToEd": $coll}, "getSearchXSLT", 0))
    then wdb:eval("wdbPF:getEntityXSLT()")
    else if (doc-available($wdb:data || '/resources/entity.xsl'))
    then xs:anyURI($wdb:data || '/resources/entity.xsl')
    else xs:anyURI($wdb:edocBaseDB || '/resources/entity.xsl')
  
  let $params := <parameters>
    <param name="title" value="{$md//meta:title[1]}" />
    <param name="rest" value="{$wdb:restURL}" />
  </parameters>
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    transform:transform(wdbRe:scan($collection, $type, $q), doc($xsl), $params)
  )
};

declare
    %rest:GET
    %rest:path("/edoc/entities/collection/{$collection}/{$type}/{$ref}.xml")
    %rest:query-param("start", "{$start}", 1)
function wdbRe:collectionEntity ($collection as xs:string*, $type as xs:string*, $ref as xs:string*, $start as xs:int*) {
  let $coll := wdb:getEdPath($collection, true())
  let $query := xmldb:decode($ref)
  
  let $res := collection($coll)//tei:TEI[descendant::tei:rs[@ref=$query or @ref='#'||$query or @ref = $type || ':' || $ref]]
  let $max := count($res)
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <results count="{$max}" from="{$start}" id="{$collection}" ref="{$ref}">{
      for $f in subsequence($res, $start, 25)
      group by $file := $f/@xml:id
      return
        <file id="{$file}">
          {$f//tei:titleStmt}
        </file>
    }</results>
  )
};
declare
    %rest:GET
    %rest:path("/edoc/entities/collection/{$collection}/{$type}/{$ref}.html")
    %rest:query-param("start", "{$start}", 1)
    %output:method("html")
function wdbRe:collectionEntityHtml ($collection as xs:string*, $type as xs:string*, $ref as xs:string*, $start as xs:int*) {
  let $md := collection($wdb:data)//id($collection)[self::meta:projectMD]
  let $coll := substring-before(wdb:findProjectXQM(wdb:getEdPath($collection, true())), 'project.xqm')
  
  let $xsl := if (wdb:findProjectFunction(map { "pathToEd" : $coll}, "getSearchXSLT", 0))
    then wdb:eval("wdbPF:getEntityXSLT()")
    else if (doc-available($wdb:data || '/resources/entity.xsl'))
    then xs:anyURI($wdb:data || '/resources/entity.xsl')
    else xs:anyURI($wdb:edocBaseDB || '/resources/entity.xsl')
    
  let $params := <parameters>
    <param name="title" value="{$md//meta:title[1]}" />
    <param name="rest" value="{$wdb:restURL}" />
  </parameters>
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    transform:transform(wdbRe:collectionEntity($collection, $type, $ref, $start), doc($xsl), $params)
  )
};

declare
    %rest:GET
    %rest:path("/edoc/entities/file/{$id}/{$type}/{$ref}.xml")
    %rest:query-param("start", "{$start}", 1)
function wdbRe:fileEntity ( $id as xs:string*, $ref as xs:string*, $start as xs:int*, $type as xs:string* ) {
  let $file := (collection($wdb:data)/id($id))[self::tei:TEI][1]
  let $query := lower-case(xmldb:decode($ref))
  
  let $res := $file//tei:rs[@ref=$query or @ref='#' || $query or @ref = $type || ':' || $ref]
  let $max := count($res)
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <results count="{$max}" from="{$start}" id="{$id}" ref="{$ref}">{
      for $h in subsequence($res, $start, 25)
      group by $a := ($h/ancestor-or-self::*[@xml:id])[last()]
      return
        <result fragment="{$a/@xml:id}"/>
    }</results>
  )
};
declare
    %rest:GET
    %rest:path("/edoc/entities/file/{$id}/{$type}/{$ref}.html")
    %rest:query-param("start", "{$start}", 1)
    %output:method("html")
function wdbRe:fileEntityHtml ( $id as xs:string*, $ref as xs:string*, $start as xs:int*, $type as xs:string* ) {
  let $coll := wdb:getEdPath($id, true())
  
  let $xsl := if (wdb:findProjectFunction(map { "pathToEd" : $coll}, "getSearchXSLT", 0))
    then wdb:eval("wdbPF:getEntityXSLT()")
    else if (doc-available($wdb:data || '/resources/entity.xsl'))
    then xs:anyURI($wdb:data || '/resources/entity.xsl')
    else xs:anyURI($wdb:edocBaseDB || '/resources/entity.xsl')
    
  let $params := <parameters>
    <param name="rest" value="{$wdb:restURL}" />
  </parameters>
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    transform:transform(wdbRe:fileEntity($id, $ref, $start, $type), doc($xsl), $params)
  )
};

declare
    %rest:GET
    %rest:path("/edoc/entities/list/collection/{$id}/{$q}.xml")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("p", "{$p}")
function wdbRe:listCollectionEntities ($id as xs:string*, $q as xs:string*, $start as xs:int*, $p as xs:string*) {
  let $coll := wdb:getEdPath($id, true())
    , $query := xmldb:decode($q) => lower-case()
    , $params := parse-json($p)
  
  let $res := switch ( $params?type )
      case "bib"
         return collection($coll)//tei:title[ft:query(., $query)][ancestor::tei:listBibl]
      case "per"
         return collection($coll)//tei:persName[ft:query(., $query)][ancestor::tei:listPerson]
      case "pla"
         return collection($coll)//tei:placeName[ft:query(., $query)][ancestor::tei:listPlace]
      case "org"
         return collection($coll)//tei:orgName[ft:query(., $query)][ancestor::tei:listOrg]
      case "evt"
         return collection($coll)//tei:event[ft:query(., $query)][ancestor::tei:listEvent]
      default
         return ()
  
   return (
    <rest:response>
      <http:response status="200">
        <http:header name="X-Rest-Status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <results q="{$query}" type="{ $params?type }" collection="{$coll}" n="{count($res)}">{
      for $r in $res
        let $id := $r/ancestor::*[@xml:id][1]/@xml:id
        return
          <result id="{$id}">{
            normalize-space($r)
          }</result>
    }</results>)
};
