xquery version "3.1";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace response = "http://exist-db.org/xquery/response";
declare namespace tei      = "http://www.tei-c.org/ns/1.0";
declare namespace meta     = "https://github.com/dariok/wdbplus/wdbmeta";

import module namespace config = "https://github.com/dariok/wdbplus/config"          at "wdb-config.xqm";
import module namespace wdbrh  = "https://github.com/dariok/wdbplus/renderer-helper" at "renderer-helper.xqm";

declare function wdbSearch:getAside ( $node as node(), $model as map(*) ) as element()+ {
  if ( wdbrh:findProjectFunction($model, 'wdbPF:getSearchLeft', 1) ) then
    (wdbrh:getProjectFunction($model, 'wdbPF:getSearchLeft', 1))($model)
  else
    let $md := doc($config:data || '/wdbmeta.xml')
      , $options := wdbSearch:selectEd($model?mainEd, $md/*)
    
    return (
      <div>
        <h1>Volltextsuche</h1>
        <form id="fts">
          <label>diesen Bestand durchsuchen: </label>
          { $options }
          <br />
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
        <form action="search.html" id="searchEntities">
          { $options }
          <br />
          { wdbSearch:listEnt("search") }
          <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
          <input type="submit" />
        </form>
      </div>,
      <hr />,
      <div>
        <h1>Registerliste</h1>
        <form action="search.html" id="listEntities">
          { $options }
          <br />
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

declare %private function wdbSearch:selectEd ( $mainEd as xs:string, $md as element(meta:projectMD) ) as element(select) {
  <select name="ed">
    <option value="data">global</option>
    {
      for $file in $md//meta:ptr return
        <option value="{ $file/@xml:id }">
          { if ( $file/@xml:id = $mainEd ) then attribute selected { "selected" } else () }
          { normalize-space($md//meta:struct[@file = $file/@xml:id]/@label) }
        </option>
    }
  </select>
};

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
