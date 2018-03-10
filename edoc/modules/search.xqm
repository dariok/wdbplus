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

declare
    function wdbSearch:search($node as node(), $model as map(*)) {
    <div id="wdbSearch">{
        if ($model("query") = '')
            then
                <form action="search.html">
                    <input type="hidden" name="edition" value="{$model('ed')}" />
                    <input type="text" name="query" />
                    <input type="submit" />
                </form>
            else (
                <h3>Ergebnisse in {$model("ed")}</h3>,
                <table>{
                    for $hit in collection($model("ed"))//tei:div[ft:query(., $model("query"))]
                        let $res := kwic:summarize($hit, <config width="200" />)[1]
                        let $file := base-uri($hit)
                        order by $file
                        group by $file
                        let $fileID := normalize-space(doc($file)/tei:TEI/@xml:id)
                        return
                            <tr>
                                <td><a href="view.html?id={$fileID}">{$file}</a></td>
                                <td><ul>{for $r in distinct-values($res)
                                    let $id := normalize-space($hit/ancestor-or-self::*[@xml:id][1]/@xml:id)
                                    return <li><a href="view.html?id={$fileID}#{$id}">{$r}</a></li>
                                }</ul></td>
                            </tr>
                }</table>)
    }</div>
};