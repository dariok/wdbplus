xquery version "3.1";

declare namespace anno = "annotate";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "modules/app.xql";

let $from := request:get-parameter('from', '')
let $to := request:get-parameter('to', '')
let $cat := request:get-parameter('cat', '')
let $file := request:get-parameter('file', '')

let $anno :=
    <entry xmlns="annotate">
        <id>{util:uuid($file||$from)}</id>
        <file>{$file}</file>
        <range from="{$from}" to="{$to}" />
        <cat>{$cat}</cat>
    </entry>

let $u := update insert $anno into doc($wdb:edocBaseDB || '/anno.xml')/anno:anno

return $u