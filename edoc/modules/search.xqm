xquery version "3.0";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb" at "app.xql";
import module namespace console   = "http://exist-db.org/xquery/console";
import module namespace kwic      = "http://exist-db.org/xquery/kwic";

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
      <span class="dispOpts">[<a id="searchLink" href="search.html?ed={$model('ed')}">Suche</a>]</span>
      <hr/>
<nav style="display:none;" />
    </header>
};

declare function wdbSearch:search($node as node(), $model as map(*)) {
    <div id="wdbSearch">{
        if ($model("query") = '')
            then (
                <form action="search.html">
                    <input type="hidden" name="ed" value="{$model('ed')}" />
                    <label for="global">Über alle Projekte suchen? </label><input type="checkbox" name="global" /><br/>
                    <label for="query">Suchbegriff(e) / RegEx: </label><input type="text" name="query" />
                    <input type="submit" />
                </form>,
                <p>Wildcard: * (<i>nicht</i> an erster Stelle!)<br/>Suche mit RegEx ist möglich mit Delimiter '/': <span style="font-family: monospace; background-color: lightgray;">/[k|K][e|a].+/</span></p>
                )
            else if ($model('q') = 'rs')
                then let $coll := if ($model("global") = 'on')
                    then $wdb:edocBaseDB
                    else $model("ed")
                let $res := collection($model("ed"))//tei:rs[@ref='#'||$model("query")]
                return (
                <h3>{count($res)} Ergebnisse in {$coll}</h3>,
                <p>Suchstring: {$model("query")}</p>,
                <table class="search">{
                  for $hit in $res
                    group by $file := base-uri($hit)
                    order by $file
                    let $fileID := $hit[1]/ancestor::tei:TEI/@xml:id
                    let $title := normalize-space($hit[1]/ancestor::tei:TEI//tei:titleStmt/tei:title[@type='short'])
                    
                    return
                    <tr>
                        <td class="file">{$title}<br/>({$file})</td>
                        <td><ul>{for $h in $hit
                                let $idt := ($h/ancestor-or-self::*[@xml:id])[last()]/@xml:id
                                let $id := if ($idt = $fileID) then '' else '#'||$idt
                                
                                return <li><a href="view.html?id={$fileID}{$id}">{normalize-space($h)}</a></li>
                        }</ul></td>
                    </tr>
                }</table>)
            else
              let $coll := if ($model("global") = 'on')
                  then $wdb:edocBaseDB
                  else $wdb:edocBaseDB||'/'||$model("ed")
              let $start := xs:integer((request:get-parameter("from", ()), 1)[1])
              (: going through several thousand hits is too costly (base-uri for 10,000 hits alone would take about one second);
                 subsequence here and then looping through grouped results leads to problems with IDs of ancestors and KWIC.
                 Hence, only look for matching files and then do the search in subsequences of files. This way, KWIC works and IDs
                 can be retrieved. The cost of the extra searches should not be as high as before :)
              let $res := collection($coll)//tei:text[ft:query(., $model("query"))]
              let $max := count($res)
              let $searchLink := "search.html?ed=" || $model("ed") || "&amp;query=" || encode-for-uri($model("query")) || "&amp;global=" || $model("global")
              let $before := max((1, $start - 25))
              let $after := min(($start + 25, $max))
              
              return (
                <h3>Treffer in {$max} Texten aus {$coll}</h3>,
                <p>Suchstring: {$model("query")}; zeige Treffer in Text {$start} bis {min(($start + 24, $max))}</p>,
                <p>{if ($start > 1) then <a href="{$searchLink || '&amp;from=' || $before}">Treffer {$before} – {$start - 1}</a> else ()} |
                  {if ($after < $max) then <a href="{$searchLink || '&amp;from=' || $after}">Treffer {$after} – {min(($max, $start + 50))}</a> else()}
                </p>,
                <table class="search">{
                  for $fil in subsequence($res, $start, 10)
                    let $res := ($fil//tei:p[ft:query(., $model("query"))]
                               | $fil//tei:table[ft:query(., $model("query"))]
                               | $fil//tei:item[ft:query(., $model("query"))])
                    let $file := base-uri($fil)
                    let $fileID := $fil/ancestor::tei:TEI/@xml:id
                    let $title := normalize-space(string-join($fil/ancestor::tei:TEI//tei:titleStmt/tei:title[matches(@type, 'main|short|num')], ' – '))
                    
                    return
                      <tr>
                        <td class="file">{$title}<br/>({$file})<br/>{count($res)} Treffer</td>
                        <td><ul>{
                          for $h in $res
                            let $idt := ($h/ancestor-or-self::*[@xml:id])[last()]/@xml:id
                            let $id := if ($idt = $fileID) then '' else '#'||$idt
                            
                            return <li><a href="view.html?id={$fileID}{$id}">{kwic:summarize($h, <config width="100"/>)}</a></li>
                        }</ul></td>
                      </tr>
                }</table>)
    }</div>
};