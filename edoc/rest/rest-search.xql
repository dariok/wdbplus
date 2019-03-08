xquery version "3.1";

module namespace wdbRs = "https://github.com/dariok/wdbplus/RestSearch";

import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace wdb  = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare
    %rest:GET
    %rest:path("/edoc/search/collection/{$id}")
    %rest:query-param("q", "{$q}")
    %rest:query-param("start", "{$start}", 1)
function wdbRs:collectionText ($id as xs:string*, $q as xs:string*, $start as xs:int*) {
  let $md := collection($wdb:data)//id($id)[self::meta:projectMD]
  let $coll := wdb:getEdPath(base-uri($md), true())
  
  let $query := xmldb:decode($q)
  
  (: going through several thousand hits is too costly (base-uri for 10,000 hits alone would take about one second);
     subsequence here and then looping through grouped results leads to problems with IDs of ancestors and KWIC.
     Hence, only look for matching files and then do the search in subsequences of files. This way, KWIC works and IDs
     can be retrieved. The cost of the extra searches should not be as high as before :)
  let $res := collection($coll)//tei:text[ft:query(., $query)]
  let $max := count($res)
  
  return
    <results count="{$max}" from="{$start}" id="{$id}" q="{$q}">{
      for $f in subsequence($res, $start, 25) return
        <file id="{$f/ancestor::tei:TEI/@xml:id}" />
    }</results>
};