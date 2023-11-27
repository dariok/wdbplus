xquery version "3.1";

module namespace wdbRs = "https://github.com/dariok/wdbplus/RestSearch";

import module namespace kwic   = "http://exist-db.org/xquery/kwic";
import module namespace wdbRCo = "https://github.com/dariok/wdbplus/RestCommon" at "common.xqm";
import module namespace wdb    = "https://github.com/dariok/wdbplus/wdb"        at "/db/apps/edoc/modules/app.xqm";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare variable $wdbRs:callback := function ( $node, $direction ) {
    if ( $node/ancestor::tei:note ) then () else $node
};

declare
    %rest:GET
    %rest:path("/edoc/search/collection/{$id}.xml")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
function wdbRs:collectionText ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  if (0 = (count($q), string-length($q))) then (
    <rest:response>
      <output:serialization-parameters>
        <output:method value="text" />
      </output:serialization-parameters>
      <http:response status="400">
        <http:header name="rest-status" value="REST:Client-Error" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Cache-Control" value="no-cache" />
        <http:header name="Content-Type" value="text/plain" />
      </http:response>
    </rest:response>,
    "Error: no query content!"
  )
  else 
    let $coll := wdb:getEdPath($id, true())
    
    let $query := xmldb:decode($q)
    
    (: going through several thousand hits is too costly (base-uri for 10,000 hits alone would take about one second);
       subsequence here and then looping through grouped results leads to problems with IDs of ancestors and KWIC.
       Hence, only look for matching files and then do the search in subsequences of files. This way, KWIC works and IDs
       can be retrieved. The cost of the extra searches should not be as high as before :)
    let $res := collection($coll)//tei:text[ft:query(., $query)]
    let $max := count($res)
    let $result := for $r in $res
      order by $r/ancestor::tei:TEI//tei:date[@type = 'published']/@when
      return $r
    
    return ( 
      <rest:response>
        <http:response status="200">
          <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
          <http:header name="Cache-Control" value="no-cache" />
        </http:response>
      </rest:response>,
      <results count="{$max}" from="{$start}" id="{$id}" q="{$q}" job="fts">{
        for $f in subsequence($result, $start, 25)
        return
          <file id="{$f/ancestor::tei:TEI/@xml:id}">{$f/ancestor::tei:TEI//tei:titleStmt}</file>
      }</results>
    )
};

declare
    %rest:GET
    %rest:path("/edoc/search/collection/{$id}.html")
    %rest:produces("text/html")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
    %output:method("html")
function wdbRs:collectionHtml ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  if ( 0 = (count($q), string-length($q)) ) then (
    <rest:response>
      <output:serialization-parameters>
        <output:method value="text" />
      </output:serialization-parameters>
      <http:response status="400">
        <http:header name="rest-status" value="REST:Client-Error" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Cache-Control" value="no-cache" />
        <http:header name="Content-Type" value="text/plain" />
      </http:response>
    </rest:response>,
    "Error: no query content!"
  )
  else 
    let $md := collection($wdb:data)//id($id)[self::meta:projectMD]
      , $coll := substring-before(wdb:findProjectXQM(wdb:getEdPath($id, true())), 'project.xqm')
      , $xsl := wdbRCo:getXSLT($coll, 'search.xsl')
    
    let $params := 
      <parameters>
        <param name="title" value="{$md//meta:title[1]}" />
        <param name="rest" value="{$wdb:restURL}" />
      </parameters>
    
    let $searchResult := wdbRs:collectionText($id, $q, $start)
    
    return if ( count($searchResult) gt 0 ) then (
      <rest:response>
        <http:response status="200">
          <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
          <http:header name="Cache-Controle" value="no-cache" />
        </http:response>
      </rest:response>,
      transform:transform($searchResult, doc($xsl), $params)
    )
    else
      <rest:response>
        <http:response status="204" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Cache-Controle" value="no-cache" />
      </rest:response>
};

declare
    %rest:GET
    %rest:path("/edoc/search/file/{$id}.xml")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
function wdbRs:fileText ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  if (0 = (count($q), string-length($q))) then (
    <rest:response>
      <output:serialization-parameters>
        <output:method value="text" />
      </output:serialization-parameters>
      <http:response status="400">
        <http:header name="rest-status" value="REST:Client-Error" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Cache-Control" value="no-cache" />
        <http:header name="Content-Type" value="text/plain" />
      </http:response>
    </rest:response>,
    "Error: no query content!"
  )
  else
    let $file := (collection($wdb:data)/id($id))[self::tei:TEI][1]/tei:text
    let $query := lower-case(xmldb:decode($q))
    (: querying for tei:w only will return no context :)
    let $res := $file//tei:p[ft:query(., $query)]
          | $file//tei:ab[ft:query(., $query)]
          | $file//tei:cell[ft:query(., $query)]
          | $file//tei:item[ft:query(., $query)]
          | $file//tei:head[ft:query(., $query)]
          | $file//tei:l[ft:query(., $query)]
    let $max := count($res)
    
    return
      <results count="{$max}" from="{$start}" id="{$id}" q="{$q}" job="fts">{
        for $h in subsequence($res, $start, 25) return
          let $id := if ( exists($h/@xml:id) )
            then $h/@xml:id
            else
              let $element := local-name($h)
                , $n := count($h/preceding::*[local-name() = $element]) + 1
              return $element || $n
          return
            <result fragment="{$id}">{
              kwic:summarize($h, <config width="40" />, $wdbRs:callback)
          }</result>
      }</results>
};

declare
    %rest:GET
    %rest:path("/edoc/search/file/{$id}.html")
    %rest:produces("text/html")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
    %output:method("html")
function wdbRs:fileHtml ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  if (0 = (count($q), string-length($q))) then (
    <rest:response>
      <output:serialization-parameters>
        <output:method value="text" />
      </output:serialization-parameters>
      <http:response status="400">
        <http:header name="rest-status" value="REST:Client-Error" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Cache-Control" value="no-cache" />
        <http:header name="Content-Type" value="text/plain" />
      </http:response>
    </rest:response>,
    "Error: no query content!"
  )
  else
    let $file := (collection($wdb:data)/id($id))[self::tei:TEI][1]
      , $coll := substring-before(wdb:findProjectXQM(wdb:getEdPath($id, true())), 'project.xqm')
      , $xsl := wdbRCo:getXSLT($coll, 'search.xsl')
      
    let $params := <parameters>
      <param name="title" value="{$file//tei:titleStmt/tei:title[1]}" />
      <param name="rest" value="{$wdb:restURL}" />
    </parameters>
    
    let $searchResult := wdbRs:fileText($id, $q, $start)
    return if (count($searchResult) gt 0) then (
      <rest:response>
        <http:response status="200">
            <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      transform:transform($searchResult, doc($xsl), $params)
    )
    else
      <rest:response>
        <http:response status="204" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Cache-Controle" value="no-cache" />
      </rest:response>
};
