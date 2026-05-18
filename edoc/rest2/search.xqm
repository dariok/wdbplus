xquery version "3.1";

module namespace r2s = "https://github.com/dariok/wdbplus/rest2/search";

import module namespace kwic     = "http://exist-db.org/xquery/kwic";
import module namespace r2       = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"          at "../modules/app.xqm";
import module namespace wdbErr   = "https://github.com/dariok/wdbplus/errors"       at "error.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"        at "../modules/wdb-files.xqm";

declare namespace api   = "https://github.com/dariok/wdbplus/api/schema/v1";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace tei   = "http://www.tei-c.org/ns/1.0";

(:~
 : Search projects – first step before searching within files.
 : GET api/v2/search/ft/project/{ed}
 :)
declare function r2s:searchProjects ( $request as map(*) ) as map(*) {
  (: ?q is never empty as it is required and its presence is thus enforced by Roaster;
     Accept header is checked by r2:returnResponse :)
  try {
    let $start := if ( exists($request?parameters?start) ) then xs:integer($request?parameters?start) else 1
      , $max := if ( exists($request?parameters?max) ) then xs:integer($request?parameters?max) else $r2:defaultResponseLength
      , $pathInfo := wdbFiles:getFullPath($request?parameters?ed)
      , $query := xmldb:decode($request?parameters?q)
      , $continued := session:exists()
                      and session:get-attribute('query') = $query
                      and $request?parameters?ed = session:get-attribute('ed')
      
      (: If a session exists and the query matches the cached query and project ID, use the cached results :)
      , $result := if ( $continued )
          then session:get-attribute("searchResult")
          else collection($pathInfo?projectPath)//tei:text[ft:query(., $query)]
      , $subsequence := subsequence($result, $start, $max)
      
      , $response :=  r2:resultsWrapper(
          map {
            "self": concat($r2:base, $request?path, '?q=', $query),
            "from": $r2:base || 'project/' || $request?parameters?ed,
            "total": count($result),
            "start": $start,
            "length": min(($max, count($subsequence))),
            "query": $query,
            "job": "fts"
          },
          $subsequence !
            <file xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
              id="{ $r2:base }{ $r2:urls?resources }{ string(./ancestor::tei:TEI/@xml:id) }"
              details="{ $r2:base }{ $r2:urls?search }ft/resource/{ string(./ancestor::tei:TEI/@xml:id) }?q={ $query }"
              label="{ string(./ancestor::tei:TEI//tei:titleStmt/*[1]) }"
            />
        )
      
      return if ( $pathInfo instance of xs:QName )
        then r2:response(404, 'text/plain', 'Project ' || $request?parameters?parent || ' not found', $r2:allOrigins)
        else if ( count($result) = 0 )
        then r2:response(204, 'text/plain', "No results found.", $r2:allOrigins)
        else (
          if ( not($continued) ) then (
            session:set-attribute("searchResult", $result),
            session:set-attribute("query", $query),
            session:set-attribute("ed", $request?parameters?ed)
          ) else (),
          r2:returnResponse($response, $request?headers?Accept, $pathInfo, "search")
        )
  } catch wdbErr:wdb0000 | wdb0000 {
    util:log("error", $err:description),
    util:log("info", $err:code),
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
  } catch * {
    util:log("info", map{
      "location":  $err:module || '@' || $err:line-number,
      "description": $err:description
    }),
    r2:response(500, 'text/plain', "an unknown error occurred when searching within projects", $r2:allOrigins)
  }
};

(:~
 : Search within a file.
 : GET api/v2/search/ft/resource/{id}?q={query}&start={start}&max={max}
 :)
declare function r2s:searchFile ( $request as map(*) ) as map(*) {
  (: ?q is never empty as it is required and its presence is thus enforces by Roaster
     Accept header is checked by r2:returnResponse :)
  try {
    let $query := xmldb:decode($request?parameters?q)
      , $pathInfo := wdbFiles:getFullPath($request?parameters?id)
      
      (: Check if a result exists for this file and query and reuse it. :)
      , $continued := session:exists() and session:get-attribute('query') = $query
      , $candidate := if ( $continued ) then session:get-attribute("searchResult")[ancestor::tei:TEI/@xml:id = $request?parameters?id ] else false()
      
      , $result := if ( $candidate )
          then ($candidate, util:log("info", "cached result used for file " || $request?parameters?id))
          else (doc($pathInfo?collectionPath || '/' || $pathInfo?fileName)//tei:text[ft:query(., $query)], util:log("info", $pathInfo?collectionPath || '/' || $pathInfo?fileName))
      , $expanded := kwic:expand($result)
      
      , $response := r2:resultsWrapper(
          map {
            "self": concat($r2:base, 'search/ft/resource/', $request?parameters?id, '?q=', $query),
            "from": $r2:base || 'resources/' || $request?parameters?id,
            "total": count($expanded//exist:match),
            "query": $query,
            "job": "fts"
          },
          for $match in $expanded//exist:match
            group by $structure := $match/ancestor::*
              ! (if ( local-name(.) = ('text', 'w') ) then () else local-name(.) || (if ( ./@xml:id ) then '#'||@xml:id else ()))
              => string-join('/')
            return <fragment xmlns="https://github.com/dariok/wdbplus/api/schema/v1" path="{$structure}" n="{count($match)}">{
              if ( $match[1]/..[self::tei:w] )
                then kwic:summarize($match[1]/../.., <config xmlns="" width="40"/>)
                else kwic:summarize($match[1]/.., <config xmlns="" width="40"/>)
            }</fragment>
        )
      
      return if ( count($result) = 0 )
        then r2:response(204, 'text/plain', "No results found.", $r2:allOrigins)
        else r2:returnResponse($response, $request?headers?Accept, $pathInfo, "search")
  } catch *:wdb0000 {
    r2:response(404, 'text/plain', 'File ' || $request?parameters?id || ' not found', $r2:allOrigins)
  }
};
