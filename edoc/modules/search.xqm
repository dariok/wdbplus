xquery version "3.1";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace tei  = "http://www.tei-c.org/ns/1.0";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

import module namespace console = "http://exist-db.org/xquery/console";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

declare function wdbSearch:getLeft($node as node(), $model as map(*)) {(
  <div>
    <h1>Volltextsuche</h1>
    <form action="search.html">
      {local:selectEd($model)}
      <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
      <input type="hidden" name="p">
        {attribute value {'{"job": "fts"}'}}
      </input>
      <input type="submit" />
    </form>
    <p>Wildcard: * (<i>nicht</i> an erster Stelle!)<br/>Suche mit RegEx ist möglich mit Delimiter '/': <span style="font-family: monospace; background-color: lightgray;">/[k|K][e|a].+/</span></p>
  </div>,
  <hr />,
  <div>
    <h1>Registersuche</h1>
    <form action="search.html">
      {local:selectEd($model)}
      {local:listEnt("search")}
      <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
      <input type="submit" />
    </form>
  </div>,
  <hr />,
  <div>
    <h1>Registerliste</h1>
    <form action="search.html">
      {local:selectEd($model)}
      {local:listEnt("entries")}
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

declare function wdbSearch:search($node as node(), $model as map(*)) {
  let $start := if ($model("p") instance of map(*) and map:contains($model("p"), "start"))
    then '&amp;start=' || $model?p?start
    else ''
  
  let $job := if ($model("p") instance of map(*))
    then $model?p?job
    else "err"
  
  return if ($job != "err") then
    let $p := $model?p
    let $c := for $k in map:keys($p) return concat('&quot;', $k, '&quot;: &quot;', $p($k), '&quot;')
    let $json := "{" || string-join($c, ', ') || "}"
    
    let $ln := switch ($job)
      case "fts"      return $wdb:restURL || "search/collection/" || $model?id || ".html?q=" || encode-for-uri($model?q) || "&amp;p=" || encode-for-uri($json)
      case "search"   return $wdb:restURL || "entities/scan/" || $model?p?type || '/' || $model?id || ".html?q=" || encode-for-uri($model?q) || "&amp;p=" || encode-for-uri($json)
      case "list"     return $wdb:restURL || "entities/collection/" || $model?id || "/" || $model?p?type || "/" || $model?p?id || ".html?p=" || encode-for-uri($json)
      case "entries"  return $wdb:restURL || "entities/list/collection/" || $model?id || "/" || $model?q || ".html?p=" || encode-for-uri($json)
      default return ""
    let $url := xs:anyURI($ln || $start)
      
    return try {
      let $request-headers := <headers>
        <header name="cache-control" value="no-cache" />
      </headers>
    
      return http:send-request(
        <http:request href="{$url}">
          {$request-headers}
        </http:request>)//httpclient:body/*
    } catch * {
      <div>
        <a href="{$url}">klick</a>
        <ul>
          <li>{$err:code}</li>
          <li>{$err:description}</li>
          <li>{$err:module || '@' || $err:line-number ||':'||$err:column-number}</li>
          <li>{$err:additional}</li>
        </ul>
      </div>
    }
  else <div />
};

declare function local:selectEd ($model) {(
  <select name="id">{
    let $md := doc($wdb:data || '/wdbmeta.xml')
    let $opts := for $file in $md//meta:ptr
      let $id := $file/@xml:id
      let $label := $md//meta:struct[@file = $id]/@label
      return
        <option value="{$id}">
          {if ($id = $model?id) then attribute selected {"selected"} else ()}
          {normalize-space($label)}
        </option>
    return (
      <option value="{$md/meta:projectMD/@xml:id}">global</option>,
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