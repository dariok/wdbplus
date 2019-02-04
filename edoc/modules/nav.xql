(:xquery version "3.0";
(\:  neu 2016-07-18 Dario Kampkaspar (DK) :\)

import module namespace wdbm	= "https://github.com/dariok/wdbplus/nav" at "nav.xqm";

let $model := map {"id": request:get-parameter('id', '')}

return
	wdbm:getLeft(<void />, $model):)
xquery version "3.1";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
import module namespace console="http://exist-db.org/xquery/console";
declare variable $base := "/db/apps/edoc/data";

declare function local:pM($coll) {
try {
    <ul>{
        let $d := doc($coll || '/wdbmeta.xml')
        return for $str in $d/meta:projectMD/meta:struct[1]/*[not(self::meta:import)]
            let $order := number($str/@order)
            order by $order ascending
            return
        <li><span>{normalize-space($str/@label)}</span>{
            if ($str[self::meta:struct and @file])
            then
                let $f := $d/id($str/@file)
                return local:pM($coll || '/' || substring-before($f/@path, '/'))
            else if ($str[self::meta:struct])
            then
                <ul>{
                    for $view in $str/meta:view
                        let $o := number($view/@order)
                        order by $o ascending
                        let $file := $d/id($view/@file)
                    return <li><a href="view.html?id={$file/@xml:id}">{normalize-space($view/@label)}</a></li>
                }</ul>
            else
                let $file := $d/id($str/@file)
                return <li><a href="view.html?id={$file/@xml:id}">{normalize-space($str/@label)}</a></li>
        }</li>
    }</ul>
} catch * {
    <i>coming soon</i>
}
};

local:pM($base)