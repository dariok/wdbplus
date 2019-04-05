xquery version "3.1";

module namespace wdbRs = "https://github.com/dariok/wdbplus/RestSearch";

import module namespace console = "http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace kwic    = "http://exist-db.org/xquery/kwic";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xqm";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare
    %rest:GET
    %rest:path("/edoc/search/collection/{$id}.xml")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
function wdbRs:collectionText ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  let $coll := wdb:getEdPath($id, true())
  
  let $query := xmldb:decode($q)
  
  (: going through several thousand hits is too costly (base-uri for 10,000 hits alone would take about one second);
     subsequence here and then looping through grouped results leads to problems with IDs of ancestors and KWIC.
     Hence, only look for matching files and then do the search in subsequences of files. This way, KWIC works and IDs
     can be retrieved. The cost of the extra searches should not be as high as before :)
  let $res := collection($coll)//tei:text[ft:query(., $query)]
  let $max := count($res)
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <results count="{$max}" from="{$start}" id="{$id}" q="{$q}">{
      for $f in subsequence($res, $start, 25)
      return
        <file id="{$f/ancestor::tei:TEI/@xml:id}">{$f/ancestor::tei:TEI//tei:titleStmt//tei:title}</file>
    }</results>
  )
};

declare
    %rest:GET
    %rest:path("/edoc/search/collection/{$id}.html")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
    %output:method("html")
function wdbRs:collectionHtml ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  let $md := collection($wdb:data)//id($id)[self::meta:projectMD]
  let $coll := substring-before(wdb:findProjectXQM(wdb:getEdPath($id, true())), 'project.xqm')
  
  let $xsl := if (wdb:findProjectFunction(map { "pathToEd" := $coll}, "getSearchXSLT", 0))
      then wdb:eval("wdbPF:getSearchXSLT()")
      else if (doc-available($coll || '/resources/search.xsl'))
      then xs:anyURI($coll || '/resources/search.xsl')
      else xs:anyURI($wdb:edocBaseDB || '/resources/search.xsl')
    
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
    transform:transform(wdbRs:collectionText($id, $q, $start), doc($xsl), $params)
  )
};

declare
    %rest:GET
    %rest:path("/edoc/search/file/{$id}.xml")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
function wdbRs:fileText ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  let $file := (collection($wdb:data)/id($id))[self::tei:TEI][1]
  let $query := lower-case(xmldb:decode($q))
  (: querying for tei:w only will return no context :)
  let $res := $file//tei:p[ft:query(., $query)]
        | $file//tei:table[ft:query(., $query)]
        | $file//tei:item[ft:query(., $query)]
  let $max := count($res)
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <results count="{$max}" from="{$start}" id="{$id}" q="{$q}">{
      for $h in subsequence($res, $start, 25) return
        <result fragment="{($h/ancestor-or-self::*[@xml:id])[last()]/@xml:id}">{
          kwic:summarize($h, <config width="80"/>)
        }</result>
    }</results>
  )
};

declare
    %rest:GET
    %rest:path("/edoc/search/file/{$id}.html")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
    %output:method("html")
function wdbRs:fileHtml ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  let $file := (collection($wdb:data)/id($id))[self::tei:TEI][1]
  let $coll := substring-before(wdb:findProjectXQM(wdb:getEdPath($id, true())), 'project.xqm')
  
  let $xsl := if (wdb:findProjectFunction(map { "pathToEd" := $coll}, "getSearchXSLT", 0))
      then wdb:eval("wdbPF:getSearchXSLT()")
      else if (doc-available($coll || '/resources/search.xsl'))
      then xs:anyURI($coll || '/resources/search.xsl')
      else xs:anyURI($wdb:edocBaseDB || '/resources/search.xsl')
    
  let $params := <parameters>
    <param name="title" value="{$file//tei:titleStmt/tei:title[1]}" />
    <param name="rest" value="{$wdb:restURL}" />
  </parameters>
  
    return (
    <rest:response>
      <http:response status="200">
          <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    transform:transform(wdbRs:fileText($id, $q, $start), doc($xsl), $params)
  )
};