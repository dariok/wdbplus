xquery version "3.0";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace tei  = "http://www.tei-c.org/ns/1.0";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

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
          return <option value="{$id}">{normalize-space($label)}</option>
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
          return <option value="{$id}">{normalize-space($label)}</option>
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
</aside>
};

declare function wdbSearch:search($node as node(), $model as map(*)) {
<main>{
  let $url := xs:anyURI($wdb:restURL || "search/collection/" || $model("id") || ".html?q=" || encode-for-uri($model("q")))
  
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
}</main>
};