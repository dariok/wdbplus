xquery version "3.1";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace tei  = "http://www.tei-c.org/ns/1.0";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

import module namespace http  = "http://expath.org/ns/http-client";
import module namespace wdbRe = "https://github.com/dariok/wdbplus/RestEntities" at "../rest/rest-entity.xql";
import module namespace wdbRs = "https://github.com/dariok/wdbplus/RestSearch"   at "../rest/rest-search.xql";
import module namespace wdb   = "https://github.com/dariok/wdbplus/wdb"          at "app.xqm";

declare function wdbSearch:getLeft ( $node as node(), $model as map(*) ) {(
  <div>
    <h1>Volltextsuche</h1>
    <form action="search.html">
      { local:selectEd($model) }
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
      { local:selectEd($model) }
      { local:listEnt("search") }
      <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
      <input type="submit" />
    </form>
  </div>,
  <hr />,
  <div>
    <h1>Registerliste</h1>
    <form action="search.html">
      { local:selectEd($model) }
      { local:listEnt("entries") }
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
    
    return (
      response:set-header("Cache-Control", "no-cache"),
      switch ( $job )
        case "fts"
          return wdbRs:collectionHtml($model?ed, $model?q, $model?p?start)
        case "search"
          return wdbRe:scanHtml($model?ed, $model?p?type, $model?q)
        case "list"
          return wdbRe:collectionEntityHtml($model?ed, $model?p?type, $model?p?id, $model?p?start)
        case "entries"
          return wdbRe:scanHtml($model?ed, $model?p?type, lower-case($model?q))
        default
          return response:set-status-code(400)
    )
  else <div />
};

declare function local:selectEd ($model) {(
  <select name="ed">{
    let $md := doc($wdb:data || '/wdbmeta.xml')
    let $opts := for $file in $md//meta:ptr
      let $id := $file/@xml:id
      let $label := $md//meta:struct[@file = $id]/@label
      return
        <option value="{$id}">
          { if ( $id = $model?mainEd ) then attribute selected {"selected"} else () }
          { normalize-space($label) }
        </option>
    return (
      if ( count($opts) gt 1 ) then <option value="{$md/meta:projectMD/@xml:id}">global</option> else (),
      $opts
    )
  }</select>,
  <br />
)};

declare function local:listEnt ($job) {(
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
