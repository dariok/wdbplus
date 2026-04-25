xquery version "3.1";

module namespace r2s = "https://github.com/dariok/wdbplus/rest2/search";

import module namespace kwic     = "http://exist-db.org/xquery/kwic";
import module namespace r2       = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"          at "../modules/app.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"        at "../modules/wdb-files.xqm";

declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace tei   = "http://www.tei-c.org/ns/1.0";

(:~
 : Search projects – first step before searching within files.
 : GET api/v2/search/ft/project/{ed}
 :)
declare function r2s:searchProjects ( $request as map(*) ) as map(*) {
  (: ?q is never empty as it is required and its presence is thus enforces by Roaster :)
  (: if ( $request?parameters?start = 0 ) then (
    r2:response(
      200,
      'text/plain',
      session:get-attribute($name),
      $r2:allOrigins
    )
  )
  else :)
    let $ed := $request?parameters?ed
      , $start := if ( exists($request?parameters?start) ) then xs:integer($request?parameters?start) else 1
      , $max := if ( exists($request?parameters?max) ) then xs:integer($request?parameters?max) else 10
      , $coll := (wdbFiles:getFullPath($ed))?projectPath
      , $query := xmldb:decode($request?parameters?q)
      , $result := collection($coll)//tei:text[ft:query(., $query)]
      , $maxHits := count($result)
      , $hits := subsequence($result, $start, $max)
      , $response :=
          <results xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
              count="{ $maxHits }" from="{ $start }" id="{ $ed }" query="{ $request?parameters?q }" job="fts"
          >{
            for $hit in $hits
              return
                <file id="{ string($hit/ancestor::tei:TEI/@xml:id) }"
                    details="{ $r2:base }search/ft/file/{ string($hit/ancestor::tei:TEI/@xml:id) }?q={ $request?parameters?q }"
                    label="{ string($hit/ancestor::tei:TEI//tei:titleStmt/*[1]) }"
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

(:~
 : Search within a file.
 : GET api/v2/search/ft/resource/{id}?q={query}&start={start}&max={max}
 :)
declare function r2s:searchFile ( $request as map(*) ) as map(*) {
  (: ?q is never empty as it is required and its presence is thus enforces by Roaster :)
  if ( $request?parameters?start = 0 and session:exists() ) then (
    r2:response(200, 'text/plain', session:get-attribute-names() => string-join(' - '), $r2:allOrigins)
  )
  else if ( session:exists() ) then
    (: return the cached results :)
    r2:response(200, 'text/plain', "to be implemented", $r2:allOrigins)
  else
    let $start := if ( exists($request?parameters?start) ) then xs:integer($request?parameters?start) else 1
      , $max := if ( exists($request?parameters?max) ) then xs:integer($request?parameters?max) else 10
      , $query := xmldb:decode($request?parameters?q)
      
      , $pathInfo := wdbFiles:getFullPath($request?parameters?id)
      , $textContent := doc($pathInfo?collectionPath || '/' || $pathInfo?fileName)//tei:text
      
      , $result := $textContent[ft:query(., $query)]
      , $maxHits := count($result)
      , $hits := subsequence($result, $start, $max)
      , $queryString := (
            $request?parameters?q,
            if ( $start != 1 ) then concat('start=', $start) else (),
            if ( $max != 10 ) then concat('max=', $max) else ()
          ) => string-join('&#38;')
      , $response :=
          <results xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
              count="{ $maxHits }" from="{ $start }" id="{ $request?parameters?id }" q="{ $request?parameters?q }" job="fts"
              self="{ $r2:base }search/ft/resource/{ $request?parameters?id }?q{ $queryString }"
          >{
            for $hit in $hits
              return
                <fragment xml:id="{ string($hit/ancestor::tei:TEI/@xml:id) }"
                    >
                </fragment>
          }</results>
    
    return if ( $maxHits = 0 )
      then r2:response(204, 'text/plain', "No results found.", $r2:allOrigins)
      else if ( $request?headers?Accept = 'text/html' )
      then (
        session:set-attribute("searchResult", $result),
        session:set-attribute("maxHits", $maxHits),
        session:set-attribute("query", $request?parameters?q),
        r2:response(200, 'text/html',
          wdb:applySpecificXsl($response, "/db/apps/edoc/data", "search.xsl"),
          $r2:allOrigins
        )
      )
      else (
        session:set-attribute("searchResult", $result),
        session:set-attribute("hits", $maxHits),
        r2:returnXmlOrJson($response)
      )
};

(: declare function r2s:searchFileFiltered ( $request as map(*) ) as map(*) {
  $hit ! map { "file": base-uri(.), "hits": kwic:expand(.) } ! <matches in="{.?file}" n="{count(.?hits//exist:match)}">{
    .?hits//exist:match ! <match path="{( ./ancestor::* ! (local-name(.)||'['||(@xml:id, generate-id())[1]||']') ) => string-join('/')}">{ kwic:summarize(../.., <config width="40"/>) }</match>
}</matches>
}; :)

