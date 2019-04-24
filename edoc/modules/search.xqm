xquery version "3.0";

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
    <span class="dispOpts">[<a id="showNavLink" href="javascript:toggleNavigation();">Navigation einblenden</a>]</span>
    <span class="dispOpts">[<a id="searchLink" href="search.html?id={$model('id')}">Suche</a>]</span>
    <hr/>
    <nav style="display:none;" />
  </header>
};

declare function wdbSearch:getLeft($node as node(), $model as map(*)) {
<aside>
  <div>
    <h1>Volltextsuche</h1>
    <form action="search.html">
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
      }</select><br />
      <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
      <input type="submit" />
    </form>
    <p>Wildcard: * (<i>nicht</i> an erster Stelle!)<br/>Suche mit RegEx ist möglich mit Delimiter '/': <span style="font-family: monospace; background-color: lightgray;">/[k|K][e|a].+/</span></p>
  </div>
  <hr />
  <div>
    <h1>Registersuche</h1>
    <form action="search.html">
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
      }</select><br />
      <select name="p">
        <option value="person">Personen</option>
        <option value="place">Orte</option>
        <option value="bibl">Bücher</option>
        <option value="org">Körperschaften</option>
        <option value="event">Ereignisse</option>
      </select><br />
      <label for="q">Suchbegriff(e) / RegEx: </label><input type="text" name="q" />
      <input type="submit" />
    </form>
  </div>
  <hr />
  <div>
    <h1>Registerliste</h1>
    <div>
      <a href="search.html?p=reg&amp;q=A">A</a> 
      <a href="search.html?p=reg&amp;q=B">B</a> 
      <a href="search.html?p=reg&amp;q=C">C</a> 
      <a href="search.html?p=reg&amp;q=D">D</a> 
      <a href="search.html?p=reg&amp;q=E">E</a> 
      <a href="search.html?p=reg&amp;q=F">F</a> 
      <a href="search.html?p=reg&amp;q=G">G</a> 
      <a href="search.html?p=reg&amp;q=H">H</a> 
      <a href="search.html?p=reg&amp;q=I">I</a> 
      <a href="search.html?p=reg&amp;q=J">J</a> 
      <a href="search.html?p=reg&amp;q=K">K</a> 
      <a href="search.html?p=reg&amp;q=L">L</a> 
      <a href="search.html?p=reg&amp;q=M">M</a> 
      <a href="search.html?p=reg&amp;q=N">N</a> 
      <a href="search.html?p=reg&amp;q=O">O</a> 
      <a href="search.html?p=reg&amp;q=P">P</a> 
      <a href="search.html?p=reg&amp;q=Q">Q</a> 
      <a href="search.html?p=reg&amp;q=R">R</a> 
      <a href="search.html?p=reg&amp;q=S">S</a> 
      <a href="search.html?p=reg&amp;q=T">T</a> 
      <a href="search.html?p=reg&amp;q=U">U</a> 
      <a href="search.html?p=reg&amp;q=V">V</a> 
      <a href="search.html?p=reg&amp;q=W">W</a> 
      <a href="search.html?p=reg&amp;q=X">X</a> 
      <a href="search.html?p=reg&amp;q=Y">Y</a> 
      <a href="search.html?p=reg&amp;q=Z">Z</a> 
    </div>
  </div>
</aside>
};

declare function wdbSearch:search($node as node(), $model as map(*)) {
  let $start := if ($model("p") instance of map(*) and map:contains($model("p"), "start"))
    then '&amp;start=' || $model("p")("start")
    else ''
  
  return
<main>{
  if (map:contains($model, "q") and $model("q") != "") then
    let $url := xs:anyURI($wdb:restURL || "search/collection/" || $model("id") || ".html?q="
        || encode-for-uri($model("q")) || $start)
      
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