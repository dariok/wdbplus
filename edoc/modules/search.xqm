xquery version "3.1";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace tei  = "http://www.tei-c.org/ns/1.0";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace wdb  = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

(:~
 : return the header
 :)
declare function wdbSearch:getHeader ( $node as node(), $model as map(*) ) {
  <header>
    <h1>{
      if ($model("title") = "")
        then ""
        else $model("title")
    }</h1>
    <h2>Suche</h2>
    <span class="dispOpts"><a id="showNavLink" href="javascript:toggleNavigation();">Navigation einblenden</a></span>
    <span class="dispOpts"><a id="searchLink" href="search.html?id={$model('id')}">Suche</a></span>
    <hr/>
    <nav style="display:none;" />
  </header>
};

declare function wdbSearch:getLeft($node as node(), $model as map(*)) {
<aside>
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
  </div>
  <hr />
  <div>
    <h1>Registersuche</h1>
    <form action="search.html">
      {local:selectEd($model)}
      {local:listEnt("search")}
      <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
      <input type="submit" />
    </form>
  </div>
  <hr />
  <div>
    <h1>Registerliste</h1>
    <form action="search.html">
      {local:selectEd($model)}
      {local:listEnt("list")}
      <select name="q">{
        for $c in (1 to 26)
          let $b := codepoints-to-string($c + 64)
          return <option value="{$b}">{$b}</option>
      }</select>
      <input type="submit" />
    </form>
  </div>
</aside>
};

declare function wdbSearch:search($node as node(), $model as map(*)) {
  let $start := if ($model("p") instance of map(*) and map:contains($model("p"), "start"))
    then '&amp;start=' || $model("p")("start")
    else ''
  
  let $job := if ($model("p") instance of map(*))
    then $model?p?job
    else "fts"
  
  let $ln := switch ($job)
    case "fts" return $wdb:restURL || "search/collection/" || $model?id || ".html?q=" || encode-for-uri($model?q) || $start
    (:case "list" return $wdb:restURL || "entities/scan/" || $model?p?type || "/" || $model?id || ".html?q=" || encode-for-uri($model?q):)
    default return $wdb:restURL || "entities/scan/" || $model?p?type || '/' || $model?id || ".html?q=" || encode-for-uri($model?q)
  
  return
<main>
  {
  if (map:contains($model, "q") and $model("q") != "") then
    let $url := xs:anyURI($ln)
      
    return try {
      let $request-headers := <headers>
        <header name="cache-control" value="no-cache" />
      </headers>
    
      return httpclient:get($url, false(), $request-headers)//httpclient:body/*
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
  else ()
}</main>
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