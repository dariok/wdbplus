xquery version "3.0";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace wdbpq = "https://github.com/dariok/wdbplus/pquery";
declare namespace meta	= "https://github.com/dariok/wdbplus/wdbmeta";

import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";
import module namespace xstring   = "https://github.com/dariok/XStringUtils" at "../includes/xstring/string-pack.xql";
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
    	<span class="dispOpts">[<a id="showNavLink" href="javascript:toggleNavigation();">Navigation
				einblenden</a>]</span>
    	<hr/>
    	<nav style="display:none;" />
    </header>
};

declare function wdbSearch:search($node as node(), $model as map(*)) {
    <div id="wdbSearch">{
        if ($model("query") = '')
            then (
                <form action="search.html">
                    <input type="hidden" name="edition" value="{$model('ed')}" />
                    <input type="text" name="query" />
                    <input type="submit" />
                </form>,
                <p>Wildcard: * (<i>nicht</i> an erster Stelle!)<br/>Suche mit RegEx ist möglich mit Delimiter '/': <pre>/[k|K][e|a].+/</pre></p>
                )
            else if ($model('q') = 'rs') then (
                <h3>Ergebnisse in {$model("ed")}</h3>,
                <table class="search">{
                  for $hit in collection($model("ed"))//tei:rs[@ref='#'||$model("query")]
                    group by $file := base-uri($hit)
                    order by $file
                    let $fileID := $hit[1]/ancestor::tei:TEI/@xml:id
                    let $title := normalize-space($hit[1]/ancestor::tei:TEI//tei:titleStmt/tei:title[@type='short'])
                    
                    return
                    <tr>
                        <td class="file">{$file}<br/>{$title}</td>
                        <td><ul>{for $h in $hit
                                let $idt := ($h/ancestor-or-self::*[@xml:id])[last()]/@xml:id
                                let $id := if ($idt = $fileID) then '' else '#'||$idt
                                
                                return <li><a href="view.html?id={$fileID}{$id}">{normalize-space($h)}</a></li>
                        }</ul></td>
                    </tr>
                }</table>)
            else (
                <h3>Ergebnisse in {$model("ed")}</h3>,
                <table class="search">{
                    for $hit in (collection($model("ed"))//tei:p[ft:query(., $model("query"))]
                            | collection($model("ed"))//tei:table[ft:query(., $model("query"))]
                            | collection($model("ed"))//tei:list[ft:query(., $model("query"))])
                        group by $file := base-uri($hit)
                        order by $file
                        
                        let $fileID := $hit[1]/ancestor::tei:TEI/@xml:id
                        let $title := normalize-space($hit[1]/ancestor::tei:TEI//tei:titleStmt/tei:title[@type='short'])
                        
                        return
                            <tr>
                                <td class="file">{$file}<br/>{$title}</td>
                                <td><ul>{for $h in $hit
                                        let $idt := ($h/ancestor-or-self::*[@xml:id])[last()]/@xml:id
                                        let $id := if ($idt = $fileID) then '' else '#'||$idt
                                        
                                        return <li><a href="view.html?id={$fileID}{$id}">{kwic:summarize($h, <config width="100"/>)}</a></li>
                                }</ul></td>
                            </tr>
                }</table>)
    }</div>
};