xquery version "3.1";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace response = "http://exist-db.org/xquery/response";
declare namespace tei      = "http://www.tei-c.org/ns/1.0";
declare namespace meta     = "https://github.com/dariok/wdbplus/wdbmeta";

import module namespace config = "https://github.com/dariok/wdbplus/config"       at "wdb-config.xqm";
import module namespace wdbRe  = "https://github.com/dariok/wdbplus/RestEntities" at "../rest/rest-entity.xql";
import module namespace wdbRs  = "https://github.com/dariok/wdbplus/RestSearch"   at "../rest/rest-search.xql";

declare function wdbSearch:getLeft ( $node as node(), $model as map(*) ) as element()+ {
  let $options := wdbSearch:selectEd($model)
  
  return (
    <div>
      <h1>Volltextsuche</h1>
      <form action="search.html">
        { $options }
        <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
        <input type="hidden" name="p">
          { attribute value {'{"job": "fts", "start": "1"}'} }
        </input>
        <input type="submit" />
      </form>
      <p>Wildcard: * (<i>nicht</i> an erster Stelle!)<br/>Suche mit RegEx ist möglich mit Delimiter '/': <span style="font-family: monospace; background-color: lightgray;">/[k|K][e|a].+/</span></p>
    </div>,
    <hr />,
    <div>
      <h1>Registersuche</h1>
      <form action="search.html">
        { $options }
        { wdbSearch:listEnt("search") }
        <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
        <input type="submit" />
      </form>
    </div>,
    <hr />,
    <div>
      <h1>Registerliste</h1>
      <form action="search.html">
        { $options }
        { wdbSearch:listEnt("entries") }
        <select name="q">{
          for $c in (1 to 26)
            let $b := codepoints-to-string($c + 64)
            return <option value="{$b}">{$b}</option>
        }</select>
        <input type="submit" />
      </form>
    </div>
  )
};

declare function wdbSearch:search ( $node as node(), $model as map(*) ) {
  let $job := if ( $model?p instance of map(*) )
    then $model?p?job
    else "err"
  
  return if ( $job != "err" ) then
    let $p := $model?p
      , $c := for $k in map:keys($p) return concat('&quot;', $k, '&quot;: &quot;', $p($k), '&quot;')
      , $json := "{" || string-join($c, ', ') || "}"
      , $start := if ( exists($model?p?start) ) then $model?p?start else 1
    
    return (
      response:set-header("Cache-Control", "no-cache"),
      switch ( $job )
        case "fts"
          return wdbRs:collectionHtml($model?ed, $model?q, $start)
        case "search"
          return wdbRe:scanHtml($model?ed, $model?p?type, $model?q)
        case "list"
          return wdbRe:collectionEntityHtml($model?ed, $model?p?type, $model?p?id, $start)
        case "entries"
          return wdbRe:scanHtml($model?ed, $model?p?type, lower-case($model?q))
        default
          return response:set-status-code(400)
    )
  else <div />
};

declare
  %private
function wdbSearch:selectEd ( $model as map(*) ) as element()+ {(
  <select name="ed">{
    let $md := doc($config:data || '/wdbmeta.xml')
    
    let $opts := for $file in $md//meta:ptr
      let $id := $file/@xml:id
      
      return
        <option value="{$id}">
          { if ( $id = $model?mainEd ) then attribute selected {"selected"} else () }
          { normalize-space($md//meta:struct[@file = $id]/@label) }
        </option>
    
    return (
      <option value="{$md/meta:projectMD/@xml:id}">global</option>,
      $opts
    )
  }</select>,
  <br />
)};

declare
  %private
function wdbSearch:listEnt ( $job as xs:string ) as element()+ {(
  <select name="p">
    <option>
      {attribute value {'{"job": "' || $job || '", "type": "per"}'}}Personen</option>
    <option>
      {attribute value {'{"job": "' || $job || '", "type": "pla"}'}}Orte</option>
    <option>
      {attribute value {'{"job": "' || $job || '", "type": "bib"}'}}Bücher</option>
    <option>
      {attribute value {'{"job": "' || $job || '", "type": "org"}'}}Körperschaften</option>
    <option>
      {attribute value {'{"job": "' || $job || '", "type": "evt"}'}}>Ereignisse</option>
  </select>,
  <br />
)};
