xquery version "3.1";

module namespace r2s = "https://github.com/dariok/wdbplus/rest2/search";

import module namespace kwic     = "http://exist-db.org/xquery/kwic";
import module namespace r2       = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"          at "../modules/app.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"        at "../modules/wdb-files.xqm";

declare namespace api   = "https://github.com/dariok/wdbplus/api/schema/v1";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace tei   = "http://www.tei-c.org/ns/1.0";

(:~
 : Search projects – first step before searching within files.
 : GET api/v2/search/ft/project/{ed}
 :)
declare function r2s:searchProjects ( $request as map(*) ) as map(*) {
  if ( not(request:get-header("Accept") = $r2:acceptable) ) then
    r2:response(406, 'text/plain', 'Available representations are: ' || string-join($r2:acceptable, ', '), $r2:allOrigins)
  else
    (: ?q is never empty as it is required and its presence is thus enforced by Roaster :)
    let $start := if ( exists($request?parameters?start) ) then xs:integer($request?parameters?start) else 1
      , $responseLength := if ( exists($request?parameters?max) ) then xs:integer($request?parameters?max) else 10
    
    (: If a session exists and the query matches the cached query and project ID, use the cached results :)
    return if ( session:exists() and $request?parameters?q = session:get-attribute('query')
                                and $request?parameters?ed = session:get-attribute('ed') )
    then (
      r2:response(
        200,
        'application/xml',
        r2s:projectResults(
            session:get-attribute("searchResult"),
            $request?parameters?q,
            $start,
            $responseLength,
            $request?parameters?ed
          ),
        map:merge((
            $r2:allOrigins,
            map { "X-Session-Cache": "HIT, length: " || session:get-attribute("searchResult") => count() || ', start: ' || $start }
          ))
      )
    )
    else
      let $start := if ( exists($request?parameters?start) ) then xs:integer($request?parameters?start) else 1
        , $max := if ( exists($request?parameters?max) ) then xs:integer($request?parameters?max) else 10
        , $coll := (wdbFiles:getFullPath($request?parameters?ed))?projectPath
        , $query := xmldb:decode($request?parameters?q)
        , $result := collection($coll)//tei:text[ft:query(., $query)]
        , $response := r2s:projectResults($result, $query, $start, $max, $request?parameters?ed)
      
      return if ( count($result) = 0 )
        then r2:response(204, 'text/plain', "No results found.", $r2:allOrigins)
        else if ( $request?headers?Accept = 'text/html' )
        then (
          session:set-attribute("searchResult", $result),
          session:set-attribute("query", $query),
          session:set-attribute("ed", $request?parameters?ed),
          r2:response(200, 'text/html',
            wdb:applySpecificXsl($response, "/db/apps/edoc/data", "search.xsl"),
            $r2:allOrigins
          )
        )
        else (
          session:set-attribute("searchResult", $result),
          session:set-attribute("query", $query),
          session:set-attribute("ed", $request?parameters?ed),
          r2:returnXmlOrJson($response)
        )
};

declare %private function r2s:projectResults ( $hits as element()*, $q as xs:string, $start as xs:integer, $responseLength as xs:integer, $ed as xs:string ) as element() {
  r2:resultsWrapper(
    map {
      "self": concat($r2:base, 'search/ft/project/', $ed, '?q=', $q),
      "total": count($hits),
      "start": $start,
      "length": $responseLength,
      "query": $q,
      "job": "fts"
    },
    subsequence($hits, $start, $responseLength) !
      <file xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
        id="{ $r2:base }resources/{ string(./ancestor::tei:TEI/@xml:id) }"
        details="{ $r2:base }search/ft/file/{ string(./ancestor::tei:TEI/@xml:id) }?q={ $q }"
        label="{ string(./ancestor::tei:TEI//tei:titleStmt/*[1]) }"
      />
  )
};

(:~
 : Search within a file.
 : GET api/v2/search/ft/resource/{id}?q={query}&start={start}&max={max}
 :)
declare function r2s:searchFile ( $request as map(*) ) as map(*) {
  (: ?q is never empty as it is required and its presence is thus enforces by Roaster :)
  (: If there is a result in the session cache and the queries match, return it. :)
  if ( session:exists() and $request?parameters?q = session:get-attribute("query")
                        and session:get-attribute("searchResult")[ancestor::tei:TEI/@xml:id = $request?parameters?id ] ) then
    (: return the cached results :)
    r2:response(200, 'application/xml',
      r2s:fileResults(
          kwic:expand(session:get-attribute("searchResult")[ancestor::tei:TEI/@xml:id = $request?parameters?id ]),
          xmldb:decode($request?parameters?q),
          $request?parameters?id
        ),
      map:merge(($r2:allOrigins, map { "X-Session-Cache": "HIT" }))
    )
  else
    let $query := xmldb:decode($request?parameters?q)
      , $pathInfo := wdbFiles:getFullPath($request?parameters?id)
      , $result := doc($pathInfo?collectionPath || '/' || $pathInfo?fileName)//tei:text[ft:query(., $query)]
      , $response := r2s:fileResults(kwic:expand($result), $query, $request?parameters?id)
    
    return if ( count($result) = 0 )
      then r2:response(204, 'text/plain', "No results found.", $r2:allOrigins)
      else if ( $request?headers?Accept = 'text/html' )
      then r2:response(200, 'text/html',
          wdb:applySpecificXsl($response, "/db/apps/edoc/data", "search.xsl"),
          $r2:allOrigins
        )
      else r2:returnXmlOrJson($response)
};

declare %private function r2s:fileResults ( $hits as element()*, $q as xs:string, $id as xs:string ) as element() {
  r2:resultsWrapper(
    map {
      "self": concat($r2:base, 'search/ft/resource/', $id, '?q=', $q),
      "total": count($hits//exist:match),
      "start": 1,
      "query": $q,
      "job": "fts"
    },
    $hits
  )
};
