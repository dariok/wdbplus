xquery version "3.0";

module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace wdbpq = "https://github.com/dariok/wdbplus/pquery";
declare namespace meta	= "https://github.com/dariok/wdbplus/wdbmeta";

import module namespace templates	= "http://exist-db.org/xquery/templates";
import module namespace wdb        = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";
import module namespace xstring    = "https://github.com/dariok/XStringUtils" at "../includes/xstring/string-pack.xql";
import module namespace console    = "http://exist-db.org/xquery/console";
import module namespace kwic="http://exist-db.org/xquery/kwic";

(:~
 : return the header
 :)
declare function wdbSearch:getHeader ( $node as node(), $model as map(*) ) {
    <header>
    	<h1>{$model("title")}</h1>
    	<span class="dispOpts">[<a id="showNavLink" href="javascript:toggleNavigation();">Navigation
				einblenden</a>]</span>
    	<hr/>
    	<nav style="display:none;" />
    </header>
};

declare %templates:default("query", "") %templates:default("edition", "")
    function wdbSearch:search($node as node(), $model as map(*)) {
    <div id="wdbSearch">{
        if ($model("query") = '')
            then
                <form action="search.html">
                    <input type="hidden" name="ed" value="{$model('ed')}" />
                    <input type="text" name="query" />
                    <input type="submit" />
                </form>
            else 
                (:for $hit in collection($model("ed"))//tei:div[ft:query(., $model("query"))]
                return kwic:summarize($hit, <config width="50" />):)
                <p>{$model("query")}</p>
    }</div>
};