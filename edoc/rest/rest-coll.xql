xquery version "3.1";

module namespace wdbRc = "https://github.com/dariok/wdbplus/RestCollections";

import module namespace json = "http://www.json.org";
import module namespace wdb  = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

(: list all collections :)
declare function local:getCollections() {
  <collections base="{$wdb:data}/">{
    for $p in collection($wdb:data)//meta:projectMD
      let $path := substring-before(substring-after(base-uri($p), $wdb:data || '/'), 'wdbmeta.xml')
      order by $path
      return <collection id="{$p/@xml:id}" path="{$path}" title="{$p//meta:title[1]}"/>
  }</collections>
};
declare
    %rest:GET
    %rest:path("/edoc/collection")
    %rest:header-param("Accept", "{$mt}")
function wdbRc:getCollections ($mt as xs:string*) {
  if ($mt = "application/json")
  then (
    <rest:response>
      <http:response status="200" message="OK">
        <http:header name="Content-Type" value="application/json; charset=UTF-8" />
      </http:response>
    </rest:response>,
    json:xml-to-json(local:getCollections())
  )
  else local:getCollections()
};
declare
    %rest:GET
    %rest:path("/edoc/collection.json")
    %rest:produces("application/json")
    %output:method("json")
function wdbRc:getCollectionsJSON () {
  wdbRc:getCollections("application/json")
};
declare
    %rest:GET
    %rest:path("/edoc/collection.xml")
    %rest:produces("application/xml")
function wdbRc:getCollectionsXML () {
  wdbRc:getCollections("application/xml")
};

(: resources within a collection :)
declare
    %rest:GET
    %rest:path("/edoc/collection/{$id}")
    %rest:header-param("Accept", "{$mt}")
function wdbRc:getResources ($id as xs:string, $mt as xs:string*) {
  let $md := collection($wdb:data)//meta:projectMD[@xml:id = $id]
  
  return if (count($md)  != 1)
  then
    <rest:response>
      <http:response status="500">
        <http:header name="REST-Status" value="404 – ID not found" />
      </http:response>
    </rest:response>
  else
    let $content := local:listCollection($md)
    return
    switch ($mt)
    case "application/json" return
      (<rest:response>
        <http:response status="200" message="OK">
          <http:header name="Content-Type" value="application/json; charset=UTF-8" />
        </http:response>
      </rest:response>,
      json:xml-to-json($content))
    default return $content
};
declare
  %rest:GET
  %rest:path("/edoc/collection/{$id}/resources.xml")
function wdbRc:getResourcesXML ($id) {
  wdbRc:getResources($id, "application/xml")
};
declare
  %rest:GET
  %rest:path("/edoc/collection/{$id}/resources.json")
  %output:method("json")
function wdbRc:getResourcesXML ($id) {
  wdbRc:getResources($id, "application/json")
};
declare function local:listCollection ($md as element()) {
  let $collection := substring-before(base-uri($md), '/wdbmeta.xml')
  return
  <collection id="{$md/@xml:id}" path="{$collection}" title="{$md//meta:title[1]}">{
    for $coll in xmldb:get-child-collections($collection)
      let $mfile := $collection || '/' || $coll || '/wdbmeta.xml'
      order by $coll
      return if (doc-available($mfile))
      then <collection id="{doc($mfile)/meta:projectMD/@xml:id}" />
      else <collection name="{$coll}">{
        local:listResources($md, $coll)
      }</collection>,
    local:listResources($md, "@")
	}</collection>
};
declare function local:listResources ($mfile, $subcollection) {
  for $file in $mfile//meta:file[starts-with(@path, $subcollection)]
  	order by $file/@path
    return <resource id="{$file/@xml:id}" path="{$file/@path}" />
};

(: navigation :)
declare
    %rest:GET
    %rest:path("/edoc/collection/{$id}/nav.xml")
function wdbRc:getCollectionNavXML ($id as xs:string) {
  let $md := collection($wdb:data)/id($id)[self::meta:projectMD]
  let $ed := substring-before(base-uri($md), '/wdbmeta.xml')
  let $st := local:pM($ed, ())
  
  let $m := $md/meta:struct[1]
  let $me := <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
    {$m/ancestor::meta:projectMD/@xml:id}
    {$m/@*}
    {(element user { sm:id()//sm:real/sm:username/text() })[1]}
    {local:eval($m, $ed)}
  </struct>
  
  return local:assemble($st, $me)
};

declare
    %rest:GET
    %rest:path("/edoc/collection/{$id}/nav.html")
function wdbRc:getCollectionNavHTML ($id as xs:string) {
  let $md := collection($wdb:data)/id($id)[self::meta:projectMD]
  let $ed := substring-before(base-uri($md), '/wdbmeta.xml')
  let $xsl := if (wdb:findProjectFunction(map {"pathToEd" := $ed}, "getNavXSLT", 0))
    then wdb:eval("wdbPF:getNavXSLT()")
    else if (doc-available($ed || '/nav.xsl'))
    then xs:anyURI($ed || '/nav.xsl')
    else xs:anyURI($wdb:edocBaseDB || '/resources/nav.xsl')
  let $struct := wdbRc:getCollectionNavXML($id)
  
  return transform:transform($struct, doc($xsl), ())
};

declare function local:pM($ed, $sequence) {
  let $d := doc($ed || '/wdbmeta.xml')/meta:projectMD/meta:struct[1]
  let $s := 
      <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">{$d/@*}
      {attribute file {$d/ancestor::meta:projectMD/@xml:id}}{
      (for $c in $d/*[not(self::meta:import)]
          return if ($c/self::meta:struct and $c/@file = $sequence/@xml:id)
          then $sequence
          else if ($c/self::meta:struct) then local:children($c, $d/preceding-sibling::meta:files)
          else (),
      local:eval($d, $ed))
      }</struct>
  
  return if ($d/meta:import)
  then 
    local:pM(string-join(tokenize($ed, '/')[not(position() = last())], '/'), $s)
  else $s
};

declare function local:children($struct, $files) {
  <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">{$struct/@*}{
    let $filePath := substring-before(base-uri($struct), 'wdbmeta') || $files/id($struct/@file)/@path
    let $file := doc($filePath)/meta:projectMD
    return for $s in $file/meta:struct[1]/meta:struct
      return if (not($s/meta:view) or $s/meta:view[not(@private)]
          or $s/meta:view/@private='false'
          or sm:has-access(xs:anyURI(substring-before($filePath, '/wdbmeta.xml')), 'w'))
      then local:children($s, $file/meta:files)
      else ()
  }</struct>
};

declare function local:eval($sequence, $targetCollection) {
for $child in $sequence/* return
  if ($child[self::meta:struct]) then
    <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
      {$child/@*}
      {local:eval($child, $targetCollection)}
    </struct>
  else if ($child/@private = 'true' and not(sm:has-access($targetCollection, 'w')))
      then ()
      else $child
};

declare function local:assemble($st, $me) {
<struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
  {$st/@*}
  {
  for $s in $st/* return
    if ($s/@file = $me/@xml:id)
    then $me
    else if ($s/*)
    then local:assemble($s, $me)
    else $s
  }
</struct>
};