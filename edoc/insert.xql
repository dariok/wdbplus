xquery version "3.1";

declare namespace anno = "annotate";

let $from := request:get-parameter('from', '')
let $to := request:get-parameter('to', '')
let $cat := request:get-parameter('cat', '')
let $file := request:get-parameter('file', '')

let $anno :=
    <entry xmlns="annotate">
        <file>{$file}</file>
        <range from="{$from}" to="{$to}" />
        <cat>{$cat}</cat>
    </entry>

let $u := update insert $anno into doc('/db/apps/edoc/anno.xml')/anno:anno

return $u