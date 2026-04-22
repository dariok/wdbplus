xquery version "3.1";

module namespace r2s = "https://github.com/dariok/wdbplus/rest2/search";

import module namespace r2       = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"          at "../modules/app.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"        at "../modules/wdb-files.xqm";

declare namespace tei    = "http://www.tei-c.org/ns/1.0";

(:~
 : Search projects – first step before searching within files.
 : GET api/v2/search/ft/project/{ed}
 :)
declare function r2s:searchProjects ( $request as map(*) ) as map(*) {
  let $ed := $request?parameters?ed
    , $q := $request?parameters?q
    , $start := if ( exists($request?parameters?start) ) then xs:integer($request?parameters?start) else 1
    , $max := if ( exists($request?parameters?max) ) then xs:integer($request?parameters?max) else 10

  return if ( empty($q) ) then (
    r2:response(
      400,
      'text/plain',
      "Error: no query content!",
      $r2:allOrigins
    )
  )
  else
    let $coll := (wdbFiles:getFullPath($ed))?projectPath
      , $query := xmldb:decode($q)
      , $result := collection($coll)//tei:text[ft:query(., $query)]
      , $maxHits := count($result)
      , $hits := subsequence($result, $start, $max)
      , $response :=
          <results xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
              count="{ $maxHits }" from="{ $start }" id="{ $ed }" q="{ $q }" job="fts"
          >{
            for $hit in $hits
              return
                <file xml:id="{ string($hit/ancestor::tei:TEI/@xml:id) }"
                    href="{ $r2:base }search/ft/file/{ string($hit/ancestor::tei:TEI/@xml:id) }?q={ $q }&amp;start=1&amp;max=10"
                    title="{ string($hit/ancestor::tei:TEI//tei:titleStmt/*[1]) }"
                />
          }</results>
    
    return if ( $maxHits = 0 )
      then r2:response(204, 'text/plain', "No results found.", $r2:allOrigins)
      else if ( $request?headers?Accept = 'text/html' )
      then r2:response(200, 'text/html',
          wdb:applySpecificXsl($response, "/db/apps/edoc/data", "search.xsl"),
          $r2:allOrigins
        )
      else r2:returnXmlOrJson($response)
};
